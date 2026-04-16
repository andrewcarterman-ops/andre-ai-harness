#!/usr/bin/env python3
"""
Einfacher Mikrofon Test - 3 Sekunden Aufnahme
"""

import numpy as np
import sounddevice as sd
import wave
import tempfile
from pathlib import Path
import subprocess

WHISPER_DIR = Path.home() / ".openclaw" / "whisper"
WHISPER_EXE = WHISPER_DIR / "main.exe"
MODELS_DIR = WHISPER_DIR / "models"
DEFAULT_MODEL = MODELS_DIR / "ggml-base.bin"

print("="*60)
print("MIKROFON TEST - 3 SEKUNDEN")
print("="*60)
print("\nDu wirst gleich 3 Sekunden aufgenommen.")
print("Sprich LAUT und DEUTLICH!")
print("\nDrücke ENTER zum Starten...")
input()

print("\n[AUFNAHME STARTET...]")
print("Sprech jetzt! (z.B.: Hallo Test Eins Zwei Drei)")

# Aufnahme
recording = sd.rec(int(3 * 16000), samplerate=16000, channels=1, dtype=np.int16)
sd.wait()

print("[AUFNAHME BEENDET]")

# Analyse
max_amp = np.max(np.abs(recording))
mean_amp = np.mean(np.abs(recording))
print(f"\n[ANALYSE]")
print(f"  Lautstaerke (max): {max_amp}")
print(f"  Lautstaerke (avg): {mean_amp:.1f}")

if max_amp < 500:
    print("\n[!!] WARNUNG: Sehr leise!")
    print("     Mikrofon-Lautstaerke in Windows auf 100% setzen!")
    print("     Oder naeher ans Mikrofon sprechen!")
elif max_amp < 2000:
    print("\n[OK] Lautstaerke okay, aber koennte lauter sein")
else:
    print("\n[OK] Gute Lautstaerke!")

# Speichern
wav_path = Path(tempfile.gettempdir()) / "test_recording.wav"
with wave.open(str(wav_path), 'wb') as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(16000)
    wf.writeframes(recording.tobytes())

print(f"\n[TRANSKRIBTION STARTET...]")
print("Warte... (erstmalig dauert das laenger)")

result = subprocess.run(
    [str(WHISPER_EXE), "-m", str(DEFAULT_MODEL), "-f", str(wav_path),
     "-l", "de", "--no-timestamps", "-t", "4"],
    capture_output=True, text=True, timeout=60
)

# Text extrahieren
lines = result.stderr.split('\n')
text_lines = []
capture = False
for line in lines:
    if "main: processing" in line:
        capture = True
        continue
    if capture and line.strip() and not line.startswith('whisper_'):
        if not any(line.startswith(p) for p in ['system_info:', 'main:', 'size=', 'load time=']):
            text_lines.append(line.strip())

text = ' '.join(text_lines).strip()

print(f"\n{'='*60}")
if text and text != "":
    print(f"[ERKANNT]: {text}")
else:
    print("[KEIN TEXT ERKANNT]")
    print("\nTipps:")
    print("- Lauter sprechen")
    print("- Mikrofon in Windows auf 100% setzen")
    print("- Deutlicher sprechen")
print("="*60)

input("\nDruecke ENTER zum Beenden...")
