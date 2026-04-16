#!/usr/bin/env python3
"""
PTT Recorder DEBUG Version
Zeigt detaillierte Informationen zur Fehlersuche
"""

import sys
import time
import tempfile
import wave
import subprocess
from pathlib import Path
from datetime import datetime

import numpy as np
import sounddevice as sd
from pynput import keyboard

WHISPER_DIR = Path.home() / ".openclaw" / "whisper"
WHISPER_EXE = WHISPER_DIR / "main.exe"
MODELS_DIR = WHISPER_DIR / "models"
DEFAULT_MODEL = MODELS_DIR / "ggml-base.bin"

recording_active = False
audio_buffer = []
audio_stream = None


def start_recording():
    global recording_active, audio_buffer, audio_stream
    audio_buffer = []
    recording_active = True
    
    try:
        audio_stream = sd.InputStream(
            samplerate=16000, channels=1, dtype=np.int16,
            callback=lambda indata, frames, time_info, status: audio_buffer.append(indata.copy()) if recording_active else None
        )
        audio_stream.start()
        print("[OK] Aufnahme läuft...")
    except Exception as e:
        print(f"[FEHLER] {e}")
        recording_active = False


def stop_recording():
    global recording_active, audio_stream
    recording_active = False
    
    if audio_stream:
        audio_stream.stop()
        audio_stream.close()
        audio_stream = None
    
    if not audio_buffer:
        print("[FEHLER] Keine Audio-Daten!")
        return None
    
    # Speichere WAV
    timestamp = int(time.time())
    wav_path = Path(tempfile.gettempdir()) / f"debug_recording_{timestamp}.wav"
    
    recording = np.concatenate(audio_buffer, axis=0)
    
    # DEBUG: Zeige Audio-Statistik
    max_amp = np.max(np.abs(recording))
    mean_amp = np.mean(np.abs(recording))
    print(f"[DEBUG] Audio-Statistik:")
    print(f"  Samples: {len(recording)}")
    print(f"  Dauer: {len(recording)/16000:.1f}s")
    print(f"  Max Lautstärke: {max_amp}")
    print(f"  Durchschnitt: {mean_amp:.1f}")
    
    if max_amp < 100:
        print("[WARNUNG] Audio sehr leise! Mikrofon-Lautstärke erhöhen!")
    
    with wave.open(str(wav_path), 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(recording.tobytes())
    
    print(f"[OK] Gespeichert: {wav_path}")
    return wav_path


def transcribe(wav_path):
    print(f"[DEBUG] Starte whisper.cpp...")
    
    result = subprocess.run(
        [str(WHISPER_EXE), "-m", str(DEFAULT_MODEL), "-f", str(wav_path),
         "-l", "de", "--no-timestamps", "-t", "4"],
        capture_output=True, text=True, timeout=60
    )
    
    print(f"[DEBUG] Return Code: {result.returncode}")
    print(f"[DEBUG] STDERR (letzte 20 Zeilen):")
    lines = result.stderr.split('\n')
    for line in lines[-20:]:
        if line.strip():
            print(f"    {line}")
    
    if result.stdout.strip():
        print(f"[DEBUG] STDOUT: {result.stdout[:200]}")


def on_press(key):
    if key == keyboard.Key.f12:
        print(f"\n[{datetime.now():%H:%M:%S}] F12 GEDRÜCKT")
        start_recording()


def on_release(key):
    if key == keyboard.Key.f12:
        print(f"[{datetime.now():%H:%M:%S}] F12 LOSGELASSEN")
        wav_path = stop_recording()
        if wav_path:
            transcribe(wav_path)
            print(f"\n{'='*60}\n")


print("\n" + "="*60)
print("PTT RECORDER - DEBUG VERSION")
print("="*60)
print("Drücke F12, sprich LAUT, lass los")
print("="*60 + "\n")

with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()
