#!/usr/bin/env python3
"""
Piper TTS Helper fuer lokale Sprachsynthese.
Generiert WAV-Dateien mit Piper (deutsche Stimme).
"""

import os
import sys
import subprocess
from pathlib import Path

# Pfade
PIPER_DIR = Path.home() / ".openclaw" / "piper" / "piper"
PIPER_EXE = PIPER_DIR / "piper.exe"
DEFAULT_MODEL = Path.home() / ".openclaw" / "piper" / "models" / "de_DE-thorsten-high.onnx"
OUTBOX_DIR = Path.home() / ".openclaw" / "voice" / "outbox"


def speak(text: str, output_path: Path = None, play: bool = False) -> Path:
    """
    Synthetisiere Text mit Piper.
    
    Args:
        text: Zu sprechender Text
        output_path: Ziel-Pfad fuer WAV-Datei (default: outbox/tts_TIMESTAMP.wav)
        play: Ob die Datei sofort abgespielt werden soll
    
    Returns:
        Pfad zur generierten WAV-Datei
    """
    if not PIPER_EXE.exists():
        print(f"[FEHLER] Piper nicht gefunden: {PIPER_EXE}", file=sys.stderr)
        sys.exit(1)
    
    if not DEFAULT_MODEL.exists():
        print(f"[FEHLER] Piper-Modell nicht gefunden: {DEFAULT_MODEL}", file=sys.stderr)
        sys.exit(1)
    
    OUTBOX_DIR.mkdir(parents=True, exist_ok=True)
    
    if output_path is None:
        import time
        timestamp = int(time.time())
        output_path = OUTBOX_DIR / f"tts_{timestamp}.wav"
    
    cmd = [
        str(PIPER_EXE),
        "--model", str(DEFAULT_MODEL),
        "--output_file", str(output_path)
    ]
    
    try:
        result = subprocess.run(
            cmd,
            input=text,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode != 0:
            print(f"[FEHLER] Piper Fehler: {result.stderr}", file=sys.stderr)
            sys.exit(1)
        
        if not output_path.exists():
            print("[FEHLER] Piper hat keine Audio-Datei erzeugt", file=sys.stderr)
            sys.exit(1)
        
        print(f"[OK] TTS generiert: {output_path}")
        
        if play:
            play_audio(output_path)
        
        return output_path
        
    except subprocess.TimeoutExpired:
        print("[FEHLER] Piper Timeout", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"[FEHLER] {e}", file=sys.stderr)
        sys.exit(1)


def play_audio(audio_path: Path):
    """Spiele WAV-Datei ab (Windows: winsound, Fallback: ffplay)."""
    try:
        import winsound
        winsound.PlaySound(str(audio_path), winsound.SND_FILENAME)
        print(f"[OK] Audio abgespielt: {audio_path.name}")
        return
    except Exception:
        pass
    
    try:
        subprocess.run(
            ["ffplay", "-nodisp", "-autoexit", str(audio_path)],
            capture_output=True,
            timeout=60,
            check=True
        )
        print(f"[OK] Audio abgespielt via ffplay: {audio_path.name}")
    except Exception as e:
        print(f"[WARNUNG] Konnte Audio nicht abspielen: {e}", file=sys.stderr)


def main():
    if len(sys.argv) < 2:
        print("Verwendung: piper_tts.py <text> [--play]", file=sys.stderr)
        sys.exit(1)
    
    text = sys.argv[1]
    play = "--play" in sys.argv
    speak(text, play=play)


if __name__ == "__main__":
    main()
