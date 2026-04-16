#!/usr/bin/env python3
"""
Debug: Speichert Aufnahme und testet mit transcribe.py
"""

import numpy as np
import sounddevice as sd
import wave
from pathlib import Path
import subprocess
import sys

WHISPER_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "transcribe.py"
SAVE_PATH = Path.home() / ".openclaw" / "voice" / "test_debug.ogg"

print("="*60)
print("DEBUG TEST - Speichert für transcribe.py")
print("="*60)

print("\n[AUFNAHME 3 SEKUNDEN...]")
print("Sprich: HALL.OW.ORLD!")

recording = sd.rec(int(3 * 16000), samplerate=16000, channels=1, dtype=np.int16)
sd.wait()

# Speichere als WAV (transcribe.py konvertiert selbst zu OGG oder WAV)
SAVE_PATH.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(SAVE_PATH.with_suffix('.wav')), 'wb') as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(16000)
    wf.writeframes(recording.tobytes())

print(f"[OK] Gespeichert: {SAVE_PATH.with_suffix('.wav')}")
print(f"[OK] Größe: {SAVE_PATH.with_suffix('.wav').stat().st_size} bytes")

print("\n[STARTE transcribe.py...]")
result = subprocess.run(
    [sys.executable, str(WHISPER_SCRIPT), str(SAVE_PATH.with_suffix('.wav'))],
    capture_output=True,
    text=True,
    timeout=120
)

print(f"\n{'='*60}")
print("ERGEBNIS:")
print(result.stdout)
if result.stderr:
    print(f"\nSTDERR:")
    print(result.stderr[-500:])  # Nur letzte 500 Zeichen
print("="*60)

input("\nENTER...")
