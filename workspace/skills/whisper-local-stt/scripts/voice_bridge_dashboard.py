#!/usr/bin/env python3
"""
Voice Bridge Phase 5 - Unified Dashboard
GUI-Status-Anzeige für alle Voice-Funktionen

Usage:
    python voice_bridge_dashboard.py
"""

import os
import sys
import time
import json
import tempfile
import wave
import subprocess
import shutil
import threading
from pathlib import Path
from datetime import datetime
from typing import Optional

import numpy as np
import sounddevice as sd

# Pfade
WHISPER_DIR = Path.home() / ".openclaw" / "whisper"
WHISPER_EXE = WHISPER_DIR / "main.exe"
MODELS_DIR = WHISPER_DIR / "models"
DEFAULT_MODEL = MODELS_DIR / "ggml-base.bin"

PIPER_EXE = Path.home() / ".openclaw" / "piper" / "piper" / "piper.exe"
PIPER_MODEL = Path.home() / ".openclaw" / "piper" / "models" / "de_DE-thorsten-high.onnx"

TRANSCRIBE_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "transcribe.py"
INBOX_DIR = Path.home() / ".openclaw" / "voice" / "inbox"
OUTBOX_DIR = Path.home() / ".openclaw" / "voice" / "outbox" / "responses"
READY_DIR = Path.home() / ".openclaw" / "voice" / "ready_to_send"

# Global Status
status = {
    "state": "IDLE",  # IDLE, RECORDING, TRANSCRIBING, PLAYING
    "last_message": None,
    "last_response": None,
    "audio_duration": 0,
    "model_used": "base"
}

recording_active = False
audio_buffer = []
audio_stream = None
recording_thread = None

def clear_screen():
    """Löscht Terminal für Dashboard-Effekt"""
    os.system('cls' if os.name == 'nt' else 'clear')

def show_dashboard():
    """Zeigt das Dashboard"""
    clear_screen()
    
    print("="*70)
    print("           🎙️  VOICE BRIDGE DASHBOARD - Phase 5  🎙️")
    print("="*70)
    
    # Status Bereich
    print(f"\n  [STATUS]  {status['state']}")
    
    if status['state'] == "IDLE":
        print("           ⏳ Warte auf Eingabe...")
    elif status['state'] == "RECORDING":
        print("           🔴 NIMMT AUF...")
    elif status['state'] == "TRANSCRIBING":
        print("           🔄 Transkribiere...")
    elif status['state'] == "PLAYING":
        print("           🔊 Spiele Antwort ab...")
    
    # Letzte Nachricht
    print(f"\n  [LETZTE NACHRICHT]")
    if status['last_message']:
        print(f"           📝 {status['last_message'][:50]}...")
        print(f"           ⏱️  {status['audio_duration']:.1f}s | Modell: {status['model_used']}")
    else:
        print("           (keine)")
    
    # Letzte Antwort
    print(f"\n  [LETZTE ANTWORT]")
    if status['last_response']:
        print(f"           💬 {status['last_response'][:50]}...")
    else:
        print("           (keine)")
    
    # Verfügbare Modelle
    print(f"\n  [MODELLE]")
    for name in ["base", "small", "medium"]:
        model_file = MODELS_DIR / f"ggml-{name}.bin"
        if model_file.exists():
            size_mb = model_file.stat().st_size / (1024*1024)
            print(f"           ✅ {name:8} ({size_mb:.0f} MB)")
        else:
            print(f"           ❌ {name:8} (nicht installiert)")
    
    # Steuerung
    print(f"\n" + "="*70)
    print("  STEUERUNG:")
    print("     [R] - Aufnahme starten")
    print("     [S] - Aufnahme stoppen & Transkribieren")
    print("     [T] - Testnachricht (ohne Aufnahme)")
    print("     [Q] - Beenden")
    print("="*70)

def start_recording():
    """Startet Aufnahme im Hintergrund"""
    global recording_active, audio_buffer, audio_stream
    
    status['state'] = "RECORDING"
    audio_buffer = []
    recording_active = True
    
    def record():
        global audio_stream
        try:
            audio_stream = sd.InputStream(
                samplerate=16000, channels=1, dtype=np.int16,
                callback=lambda indata, frames, time_info, st: audio_buffer.append(indata.copy()) if recording_active else None
            )
            audio_stream.start()
        except Exception as e:
            print(f"Mikrofon-Fehler: {e}")
            recording_active = False
            status['state'] = "IDLE"
    
    thread = threading.Thread(target=record)
    thread.daemon = True
    thread.start()
    
    show_dashboard()
    print("\n  🔴 NIMMT AUF... Sprich jetzt!")

def stop_recording():
    """Stoppt Aufnahme und verarbeitet"""
    global recording_active, audio_stream
    
    recording_active = False
    status['state'] = "TRANSCRIBING"
    show_dashboard()
    
    if audio_stream:
        audio_stream.stop()
        audio_stream.close()
        audio_stream = None
    
    if not audio_buffer:
        print("\n  ❌ Keine Audio-Daten!")
        status['state'] = "IDLE"
        return
    
    # Speichere
    audio = np.concatenate(audio_buffer, axis=0)
    wav_path = Path(tempfile.gettempdir()) / f"dash_{int(time.time())}.wav"
    
    with wave.open(str(wav_path), 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(audio.tobytes())
    
    status['audio_duration'] = len(audio) / 16000
    
    # Transkribiere
    print("\n  🔄 Transkribiere...")
    result = subprocess.run(
        [sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)],
        capture_output=True, text=True, timeout=120
    )
    
    text = result.stdout.strip()
    status['last_message'] = text
    
    print(f"\n  📝 ERKANNT: {text[:60]}...")
    
    # Cleanup
    try:
        wav_path.unlink()
    except:
        pass
    
    # Andrew antwortet
    if text and text != "[Kein Text erkannt]":
        response = f"Verstanden: {text}"
    else:
        response = "Ich habe dich nicht verstanden."
    
    status['last_response'] = response
    
    # TTS generieren
    print("\n  🎵 Generiere TTS...")
    tts_path = Path(tempfile.gettempdir()) / f"dash_tts_{int(time.time())}.wav"
    
    subprocess.run(
        [str(PIPER_EXE), "--model", str(PIPER_MODEL), "--output_file", str(tts_path)],
        input=response, capture_output=True, timeout=60
    )
    
    if tts_path.exists():
        status['state'] = "PLAYING"
        show_dashboard()
        
        # Abspielen
        print("\n  🔊 Spiele Antwort ab...")
        try:
            import sounddevice as sd_play
            with wave.open(str(tts_path), 'rb') as wf:
                frames = wf.readframes(wf.getnframes())
                audio_data = np.frombuffer(frames, dtype=np.int16)
                sd_play.play(audio_data, wf.getframerate())
                sd_play.wait()
        except Exception as e:
            print(f"  Fehler beim Abspielen: {e}")
        
        tts_path.unlink()
    
    status['state'] = "IDLE"
    show_dashboard()

def test_mode():
    """Test-Modus ohne Aufnahme"""
    status['last_message'] = "Das ist eine Testnachricht"
    status['last_response'] = "Test erfolgreich! Das Dashboard funktioniert."
    status['audio_duration'] = 2.5
    
    show_dashboard()
    print("\n  ✅ Testnachricht eingefügt!")

def main():
    """Hauptloop"""
    show_dashboard()
    
    while True:
        try:
            if sys.platform == 'win32':
                import msvcrt
                if msvcrt.kbhit():
                    key = msvcrt.getch().decode('utf-8', errors='ignore').upper()
                else:
                    time.sleep(0.1)
                    continue
            else:
                import select
                if select.select([sys.stdin], [], [], 0.1)[0]:
                    key = sys.stdin.read(1).upper()
                else:
                    continue
            
            if key == 'R' and status['state'] == "IDLE":
                start_recording()
            
            elif key == 'S' and status['state'] == "RECORDING":
                stop_recording()
            
            elif key == 'T':
                test_mode()
            
            elif key == 'Q':
                print("\n  Beendet.")
                break
                
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"\n  Fehler: {e}")

if __name__ == "__main__":
    main()
