#!/usr/bin/env python3
"""
Voice Bridge Phase 3 - PTT mit Audio Recorder
Global F12 Listener + Audio Aufnahme + Automatische Transkription

Usage:
    python voice_bridge_ptt_recorder.py
    Drücke F12 → Aufnahme startet
    Lass F12 los → Aufnahme stoppt + Transkription
    Ctrl+C → Beenden

Requirements:
    pip install pynput sounddevice numpy scipy
"""

import sys
import os
import time
import tempfile
import wave
import subprocess
import shutil
from pathlib import Path
from datetime import datetime
from typing import Optional

import numpy as np
import sounddevice as sd
from pynput import keyboard

# Pfade
WHISPER_DIR = Path.home() / ".openclaw" / "whisper"
WHISPER_EXE = WHISPER_DIR / "main.exe"
MODELS_DIR = WHISPER_DIR / "models"
DEFAULT_MODEL = MODELS_DIR / "ggml-base.bin"

# Global Status
recording_active = False
audio_buffer = []
audio_stream = None
recorded_filename = None


def get_model_path(model_name: str = "base") -> Path:
    """Ermittelt Pfad zum Modell-File"""
    model_file = MODELS_DIR / f"ggml-{model_name}.bin"
    if model_file.exists():
        return model_file
    return DEFAULT_MODEL


def start_recording():
    """Startet Audio-Aufnahme"""
    global recording_active, audio_buffer, audio_stream
    
    audio_buffer = []
    recording_active = True
    
    try:
        audio_stream = sd.InputStream(
            samplerate=16000,
            channels=1,
            dtype=np.int16,
            callback=_audio_callback
        )
        audio_stream.start()
        print("[...] Aufnahme läuft... (F12 halten)")
    except Exception as e:
        print(f"[FEHLER] Mikrofon nicht verfügbar: {e}")
        recording_active = False


def _audio_callback(indata, frames, time_info, status):
    """Callback für Audio-Stream"""
    global audio_buffer
    if recording_active:
        audio_buffer.append(indata.copy())


def stop_and_save_recording() -> Optional[Path]:
    """Stoppt Aufnahme und speichert WAV-Datei"""
    global recording_active, audio_stream, recorded_filename
    
    recording_active = False
    
    if audio_stream:
        audio_stream.stop()
        audio_stream.close()
        audio_stream = None
    
    if not audio_buffer:
        print("[WARNUNG] Keine Audio-Daten aufgenommen")
        return None
    
    # Erstelle WAV-Datei
    timestamp = int(time.time())
    recorded_filename = Path(tempfile.gettempdir()) / f"ptt_recording_{timestamp}.wav"
    
    try:
        recording = np.concatenate(audio_buffer, axis=0)
        
        with wave.open(str(recorded_filename), 'wb') as wf:
            wf.setnchannels(1)  # Mono
            wf.setsampwidth(2)  # 16-bit
            wf.setframerate(16000)
            wf.writeframes(recording.tobytes())
        
        duration = len(recording) / 16000
        print(f"[OK] Aufnahme gespeichert: {recorded_filename}")
        print(f"[OK] Dauer: {duration:.1f} Sekunden")
        
        return recorded_filename
        
    except Exception as e:
        print(f"[FEHLER] Speichern fehlgeschlagen: {e}")
        return None


def transcribe_audio(wav_path: Path) -> Optional[str]:
    """Transkribiert Audio mit whisper.cpp"""
    model_path = get_model_path("base")  # Für PTT immer base (schnell)
    
    print(f"[...] Transkribiere mit base-Modell...")
    
    try:
        result = subprocess.run(
            [str(WHISPER_EXE), "-m", str(model_path), "-f", str(wav_path),
             "-l", "de", "--no-timestamps", "-t", "4"],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode == 0:
            # Extrahiere Text aus stderr
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
            
            if text:
                return text
            else:
                return "[Kein Text erkannt]"
        else:
            print(f"[FEHLER] Transkription fehlgeschlagen")
            return None
            
    except Exception as e:
        print(f"[FEHLER] Transkription: {e}")
        return None


def on_press(key):
    """Wird aufgerufen wenn eine Taste gedrückt wird"""
    try:
        if key == keyboard.Key.f12:
            timestamp = datetime.now().strftime("%H:%M:%S")
            print(f"\n[{timestamp}] [PTT] F12 GEDRÜCKT")
            start_recording()
            
    except Exception as e:
        print(f"[FEHLER] {e}")


def on_release(key):
    """Wird aufgerufen wenn eine Taste losgelassen wird"""
    try:
        if key == keyboard.Key.f12:
            timestamp = datetime.now().strftime("%H:%M:%S")
            print(f"[{timestamp}] [PTT] F12 LOSGELASSEN")
            
            # Stoppe Aufnahme
            wav_path = stop_and_save_recording()
            
            if wav_path:
                # Transkribiere
                text = transcribe_audio(wav_path)
                
                if text:
                    print(f"\n{'='*60}")
                    print(f"[TRANSKRIBIERT] {text}")
                    print(f"{'='*60}\n")
                
                # Cleanup
                wav_path.unlink()
                
    except Exception as e:
        print(f"[FEHLER] {e}")


def main():
    """Hauptfunktion"""
    print("\n" + "="*60)
    print("PTT RECORDER - Phase 3")
    print("F12 = Aufnahme starten/stoppen")
    print("="*60)
    print("\nPrüfe Abhängigkeiten...")
    
    # Prüfe whisper.cpp
    if not WHISPER_EXE.exists():
        print(f"[FEHLER] whisper.cpp nicht gefunden: {WHISPER_EXE}")
        return
    
    # Prüfe Modell
    if not DEFAULT_MODEL.exists():
        print(f"[FEHLER] base-Modell nicht gefunden: {DEFAULT_MODEL}")
        return
    
    print("[OK] Alles bereit!")
    print("\nDrücke F12 für Push-to-Talk")
    print("Drücke Ctrl+C zum Beenden")
    print("="*60 + "\n")
    
    # Keyboard Listener starten
    with keyboard.Listener(
        on_press=on_press,
        on_release=on_release
    ) as listener:
        try:
            listener.join()
        except KeyboardInterrupt:
            print("\n\nBeendet.")
            sys.exit(0)


if __name__ == "__main__":
    main()
