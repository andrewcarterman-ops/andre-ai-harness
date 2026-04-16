#!/usr/bin/env python3
"""
Voice Bridge Phase 4 - TTS Rückkanal mit direktem Abspielen

Workflow:
    1. ENTER drücken → Sprechen
    2. ENTER loslassen → Transkription
    3. Andrew antwortet (Text)
    4. TTS generiert Audio
    5. Audio wird direkt auf PC abgespielt!

Usage:
    python voice_bridge_phase4.py
"""

import sys
import time
import tempfile
import wave
import subprocess
import shutil
from pathlib import Path
from datetime import datetime

import numpy as np
import sounddevice as sd

# Pfade
TRANSCRIBE_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "transcribe.py"
PIPER_EXE = Path.home() / ".openclaw" / "piper" / "piper" / "piper.exe"
PIPER_MODEL = Path.home() / ".openclaw" / "piper" / "models" / "de_DE-thorsten-high.onnx"

def record_audio():
    """Nimmt Audio auf bis ENTER gedrückt wird"""
    print("\n[AUFNAHME LÄUFT...]")
    print("Sprich jetzt! (Drücke ENTER zum Beenden)")
    
    recording = []
    
    def callback(indata, frames, time_info, status):
        recording.append(indata.copy())
    
    stream = sd.InputStream(samplerate=16000, channels=1, dtype=np.int16, callback=callback)
    stream.start()
    
    input()
    
    stream.stop()
    stream.close()
    
    if not recording:
        return None
    
    audio = np.concatenate(recording, axis=0)
    wav_path = Path(tempfile.gettempdir()) / f"ptt_{int(time.time())}.wav"
    
    with wave.open(str(wav_path), 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(audio.tobytes())
    
    duration = len(audio) / 16000
    print(f"[OK] Aufnahme: {duration:.1f}s")
    
    return wav_path

def transcribe(wav_path):
    """Nutzt transcribe.py für Transkription"""
    print("[...] Transkribiere...")
    
    result = subprocess.run(
        [sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)],
        capture_output=True,
        text=True,
        timeout=120
    )
    
    return result.stdout.strip() if result.stdout.strip() else "[Kein Text erkannt]"

def generate_tts(text, output_path):
    """Generiert TTS mit Piper"""
    print(f"[...] Generiere TTS...")
    
    result = subprocess.run(
        [str(PIPER_EXE), "--model", str(PIPER_MODEL), "--output_file", str(output_path)],
        input=text,
        capture_output=True,
        text=True,
        timeout=60
    )
    
    return result.returncode == 0 and output_path.exists()

def play_audio(wav_path):
    """Spielt Audio direkt auf dem PC ab"""
    print(f"[...] Spiele Audio ab...")
    
    try:
        # Lade WAV Datei
        import wave
        import sounddevice as sd
        import numpy as np
        
        with wave.open(str(wav_path), 'rb') as wf:
            frames = wf.readframes(wf.getnframes())
            rate = wf.getframerate()
            channels = wf.getnchannels()
            
            # Konvertiere zu numpy array
            audio = np.frombuffer(frames, dtype=np.int16)
            
            # Abspielen
            sd.play(audio, rate)
            sd.wait()  # Warte bis fertig
            
        print("[OK] Audio abgespielt!")
        return True
        
    except Exception as e:
        print(f"[FEHLER] Abspielen fehlgeschlagen: {e}")
        return False

def main():
    """Hauptfunktion"""
    print("\n" + "="*60)
    print("VOICE BRIDGE PHASE 4 - TTS + DIREKTES ABPSIELEN")
    print("="*60)
    print("\nWorkflow:")
    print("  1. ENTER drücken → Sprechen")
    print("  2. ENTER loslassen → Transkription")
    print("  3. Andrew antwortet (Text)")
    print("  4. TTS generiert Audio")
    print("  5. Audio wird direkt auf PC abgespielt!")
    print("\nDrücke Ctrl+C zum Beenden")
    print("="*60)
    
    while True:
        try:
            print("\n" + "-"*60)
            print("Bereit. ENTER drücken und sprechen...")
            input()
            
            # 1. Aufnahme
            wav_path = record_audio()
            
            if not wav_path or not wav_path.exists():
                continue
            
            # 2. Transkription
            user_text = transcribe(wav_path)
            print(f"\n[DU]: {user_text}")
            
            # Cleanup (ignoriere Fehler falls Datei bereits gelöscht)
            try:
                if wav_path.exists():
                    wav_path.unlink()
            except:
                pass
            
            # 3. Andrew antwortet (für Demo: Echo + Erweiterung)
            # In Zukunft: Hier würde OpenClaw/LLM antworten
            if user_text != "[Kein Text erkannt]":
                andrew_response = f"Du hast gesagt: {user_text}. Das habe ich verstanden!"
            else:
                andrew_response = "Entschuldigung, ich habe dich nicht verstanden."
            
            print(f"[ANDREW]: {andrew_response}")
            
            # 4. TTS generieren
            tts_path = Path(tempfile.gettempdir()) / f"tts_response_{int(time.time())}.wav"
            
            if generate_tts(andrew_response, tts_path):
                print(f"[OK] TTS erzeugt: {tts_path}")
                
                # 5. Audio direkt abspielen!
                play_audio(tts_path)
                
                # Cleanup
                tts_path.unlink()
            else:
                print("[FEHLER] TTS Generierung fehlgeschlagen")
            
        except KeyboardInterrupt:
            print("\n\nBeendet.")
            break
        except Exception as e:
            print(f"\n[FEHLER]: {e}")

if __name__ == "__main__":
    main()
