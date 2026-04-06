#!/usr/bin/env python3
"""
Whisper Transcription Engine
Transkribiert Audio-Dateien mit faster-whisper.
"""

import os
import sys
import json
import tempfile
import subprocess
from pathlib import Path
from typing import Optional, Tuple, List

# Konfiguration
CACHE_DIR = Path.home() / ".cache" / "whisper"
CONFIG_DIR = Path.home() / ".openclaw" / "skills" / "whisper-local-stt"
CONFIG_FILE = CONFIG_DIR / "config.json"

# Globaler Model-Cache (für Performance)
_model_cache = {}


def load_config() -> dict:
    """Lädt Konfiguration"""
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"default_model": "small", "models": {}}


def get_user_id() -> str:
    """Ermittelt User-ID"""
    return os.environ.get("OPENCLAW_USER_ID", "default")


def get_user_model(user_id: str) -> str:
    """Ermittelt bevorzugtes Modell für User"""
    config = load_config()
    return config.get("user_preferences", {}).get(user_id, config.get("default_model", "small"))


def convert_audio(input_path: Path, output_path: Path) -> bool:
    """Konvertiert Audio zu WAV (16kHz, mono)"""
    try:
        cmd = [
            "ffmpeg",
            "-i", str(input_path),
            "-ar", "16000",
            "-ac", "1",
            "-c:a", "pcm_s16le",
            "-y",
            str(output_path)
        ]
        subprocess.run(cmd, check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"FFmpeg Fehler: {e}", file=sys.stderr)
        return False
    except FileNotFoundError:
        print("FFmpeg nicht gefunden. Installiere FFmpeg:", file=sys.stderr)
        print("  Windows: winget install Gyan.FFmpeg", file=sys.stderr)
        print("  macOS: brew install ffmpeg", file=sys.stderr)
        return False


def get_model(model_name: str):
    """Lädt Whisper-Modell (mit Caching)"""
    global _model_cache
    
    if model_name in _model_cache:
        return _model_cache[model_name]
    
    try:
        from faster_whisper import WhisperModel
        
        # Gerät und Compute-Type ermitteln
        import torch
        device = "cuda" if torch.cuda.is_available() else "cpu"
        compute_type = "float16" if device == "cuda" else "int8"
        
        print(f"Lade Modell '{model_name}' auf {device}...", file=sys.stderr)
        
        model = WhisperModel(
            model_name,
            device=device,
            compute_type=compute_type,
            download_root=str(CACHE_DIR)
        )
        
        _model_cache[model_name] = model
        return model
        
    except Exception as e:
        print(f"Fehler beim Laden des Modells: {e}", file=sys.stderr)
        return None


def transcribe_audio(audio_path: Path, model_name: str) -> Tuple[str, dict]:
    """
    Transkribiert Audio-Datei.
    
    Returns:
        (transkription_text, metadata)
    """
    model = get_model(model_name)
    if not model:
        return "", {"error": "Modell konnte nicht geladen werden"}
    
    # Konvertierung
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = Path(tmp.name)
    
    try:
        if not convert_audio(audio_path, wav_path):
            return "", {"error": "Audio-Konvertierung fehlgeschlagen"}
        
        # Transkription
        segments, info = model.transcribe(
            str(wav_path),
            beam_size=5,
            best_of=5,
            condition_on_previous_text=True,
            vad_filter=True,
            vad_parameters=dict(min_silence_duration_ms=500)
        )
        
        # Segmente zu Text zusammenfügen
        text_parts = []
        for segment in segments:
            text_parts.append(segment.text.strip())
        
        full_text = " ".join(text_parts)
        
        metadata = {
            "language": info.language,
            "language_probability": info.language_probability,
            "duration": info.duration,
            "model": model_name
        }
        
        return full_text, metadata
        
    finally:
        # Aufräumen
        if wav_path.exists():
            wav_path.unlink()


def format_output(text: str, metadata: dict) -> str:
    """Formatiert Ausgabe für OpenClaw"""
    if not text:
        return "⚠️  Konnte keine Transkription erstellen."
    
    output = []
    
    # Optional: Metadaten anzeigen (kann deaktiviert werden)
    # output.append(f"🎙️  Transkription ({metadata['model']}, {metadata['language']})")
    # output.append("")
    
    output.append(text)
    
    return "\n".join(output)


def main():
    """Hauptfunktion"""
    if len(sys.argv) < 2:
        print("Verwendung: transcribe.py <audio-datei>", file=sys.stderr)
        sys.exit(1)
    
    audio_path = Path(sys.argv[1])
    
    if not audio_path.exists():
        print(f"Datei nicht gefunden: {audio_path}", file=sys.stderr)
        sys.exit(1)
    
    # User-spezifisches Modell ermitteln
    user_id = get_user_id()
    model_name = get_user_model(user_id)
    
    print(f"Transkribiere mit Modell '{model_name}'...", file=sys.stderr)
    
    # Transkription
    text, metadata = transcribe_audio(audio_path, model_name)
    
    # Ausgabe
    output = format_output(text, metadata)
    print(output)
    
    # Aufräumen (Original-Audio löschen falls konfiguriert)
    config = load_config()
    if config.get("telegram", {}).get("delete_after_transcribe", True):
        if audio_path.exists():
            audio_path.unlink()


if __name__ == "__main__":
    main()
