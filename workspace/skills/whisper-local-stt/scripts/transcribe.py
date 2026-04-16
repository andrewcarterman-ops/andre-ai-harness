#!/usr/bin/env python3
"""
Whisper Transcription Engine (whisper.cpp)
Transkribiert Audio-Dateien mit whisper.cpp main.exe.
"""

import os
import sys
import json
import tempfile
import subprocess
from pathlib import Path
from typing import Optional, Tuple

# Pfade
WHISPER_DIR = Path.home() / ".openclaw" / "whisper"
MAIN_EXE = WHISPER_DIR / "main.exe"
MODELS_DIR = WHISPER_DIR / "models"
CONFIG_DIR = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt"
CONFIG_FILE = CONFIG_DIR / "config.json"


def load_config() -> dict:
    """Lädt Konfiguration"""
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"default_model": "base", "models": {}}


def get_user_id() -> str:
    """Ermittelt User-ID"""
    return os.environ.get("OPENCLAW_USER_ID", "default")


def get_user_model(user_id: str) -> str:
    """Ermittelt bevorzugtes Modell für User"""
    config = load_config()
    return config.get("user_preferences", {}).get(user_id, config.get("default_model", "base"))


def get_model_path(model_name: str) -> Optional[Path]:
    """Ermittelt Pfad zum Modell-File"""
    model_file = MODELS_DIR / f"ggml-{model_name}.bin"
    if model_file.exists():
        return model_file
    return None


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
        return False


def transcribe_audio(audio_path: Path, model_name: str) -> Tuple[str, dict]:
    """
    Transkribiert Audio-Datei mit whisper.cpp main.exe.
    """
    model_path = get_model_path(model_name)
    if not model_path:
        return "", {"error": f"Modell '{model_name}' nicht gefunden. Führe install.py aus."}
    
    # Konvertierung
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = Path(tmp.name)
    
    try:
        if not convert_audio(audio_path, wav_path):
            return "", {"error": "Audio-Konvertierung fehlgeschlagen"}
        
        # whisper.cpp aufrufen
        cmd = [
            str(MAIN_EXE),
            "-m", str(model_path),
            "-f", str(wav_path),
            "-l", "de",
            "-nt",              # keine Timestamps
            "--no-timestamps",
            "-t", "8"           # 8 Threads
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"whisper.cpp stderr: {result.stderr}", file=sys.stderr)
            return "", {"error": f"Transkription fehlgeschlagen (Code {result.returncode})"}
        
        # whisper.cpp gibt viel Debug-Output + die Transkription
        # Wir extrahieren nur die letzten nicht-leeren Zeilen nach "main: processing ..."
        lines = result.stderr.splitlines()
        
        # Suche nach der Transkription im stderr (whisper.cpp gibt Text oft nach "main: processing" aus)
        text = ""
        capture = False
        text_lines = []
        
        for line in lines:
            if "main: processing" in line:
                capture = True
                continue
            if capture and line.strip() and not line.startswith("whisper_") and not line.startswith("system_info:"):
                text_lines.append(line.strip())
        
        text = " ".join(text_lines).strip()
        
        # Fallback: Manchmal ist der Text in stdout
        if not text and result.stdout.strip():
            text = result.stdout.strip()
        
        # Noch ein Fallback: Suche nach "[" Zeilen (Timestamps falls -nt nicht funktioniert hat)
        if not text:
            for line in lines:
                stripped = line.strip()
                if stripped and not stripped.startswith("[") and not any(stripped.startswith(p) for p in ["whisper_", "system_info:", "main:", "size=", "load time="]):
                    if "CUDA" not in stripped and "AVX" not in stripped and "F16C" not in stripped:
                        text = stripped
                        break
        
        metadata = {
            "model": model_name,
            "duration_sec": None  # Könnte man später aus FFmpeg ermitteln
        }
        
        return text, metadata
        
    finally:
        if wav_path.exists():
            wav_path.unlink()


def format_output(text: str, metadata: dict) -> str:
    """Formatiert Ausgabe für OpenClaw"""
    if not text:
        return "Konnte keine Transkription erstellen."
    
    return text


def main():
    """Hauptfunktion"""
    if len(sys.argv) < 2:
        print("Verwendung: transcribe.py <audio-datei>", file=sys.stderr)
        sys.exit(1)
    
    audio_path = Path(sys.argv[1]).expanduser()
    
    if not audio_path.exists():
        print(f"Datei nicht gefunden: {audio_path}", file=sys.stderr)
        sys.exit(1)
    
    user_id = get_user_id()
    model_name = get_user_model(user_id)
    
    print(f"Transkribiere mit Modell '{model_name}'...", file=sys.stderr)
    
    text, metadata = transcribe_audio(audio_path, model_name)
    output = format_output(text, metadata)
    print(output)
    
    # Aufräumen
    config = load_config()
    if config.get("telegram", {}).get("delete_after_transcribe", True):
        if audio_path.exists():
            audio_path.unlink()


if __name__ == "__main__":
    main()
