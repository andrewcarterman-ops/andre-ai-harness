#!/usr/bin/env python3
"""
Voice Bridge - Clean ENTER-to-Talk
Einfach, zuverlässig, gute Qualitaet

Usage:
    python voice_bridge_clean.py
    ENTER druecken -> Aufnahme startet
    ENTER druecken -> Aufnahme stoppt, Transkription, TTS-Antwort
    Ctrl+C -> Beenden
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

# Pfade
TRANSCRIBE_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "transcribe.py"
PIPER_EXE = Path.home() / ".openclaw" / "piper" / "piper" / "piper.exe"
PIPER_MODEL = Path.home() / ".openclaw" / "piper" / "models" / "de_DE-thorsten-high.onnx"

print("\n" + "="*60)
print("VOICE BRIDGE - Clean ENTER-to-Talk")
print("="*60)
print("\n🎙️  ENTER druecken -> Sprich etwas -> ENTER druecken -> Fertig!")
print("\n💡 Tipp: Sprich LAUT, DEUTLICH und etwas LANGSAMER")
print("\n   Ctrl+C zum Beenden")
print("="*60 + "\n")

while True:
    try:
        # Warte auf ENTER
        print("\n[Druecke ENTER zum Sprechen...]")
        input()
        
        # Aufnahme
        print("\n🔴 NIMMT AUF... (sprich jetzt!)")
        print("[Druecke ENTER zum Beenden...]")
        
        recording = []
        
        def callback(indata, frames, time_info, status):
            recording.append(indata.copy())
        
        stream = sd.InputStream(
            samplerate=16000, 
            channels=1, 
            dtype=np.int16, 
            callback=callback,
            blocksize=1024
        )
        stream.start()
        
        # Warte auf ENTER
        input()
        
        stream.stop()
        stream.close()
        
        if not recording:
            print("❌ Keine Aufnahme!")
            continue
        
        # Speichern
        audio = np.concatenate(recording, axis=0)
        duration = len(audio) / 16000
        
        wav_path = Path(tempfile.gettempdir()) / f"clean_{int(time.time())}.wav"
        with wave.open(str(wav_path), 'wb') as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(16000)
            wf.writeframes(audio.tobytes())
        
        print(f"\n✅ Aufnahme: {duration:.1f}s")
        
        # Transkription
        print("🔄 Transkribiere...")
        result = subprocess.run(
            [sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)],
            capture_output=True,
            text=True,
            timeout=120
        )
        
        text = result.stdout.strip()
        
        print(f"\n{'='*60}")
        print(f"📝 DU: {text}")
        print(f"{'='*60}")
        
        # Cleanup
        try:
            wav_path.unlink()
        except:
            pass
        
        # Andrew antwortet
        if text and text != "[Kein Text erkannt]":
            response = f"Ich habe verstanden: {text}"
        else:
            response = "Entschuldigung, ich habe dich nicht verstanden. Bitte sprich lauter und deutlicher."
        
        print(f"\n💬 ANDREW: {response}")
        
        # TTS - FIX: input als bytes
        print("\n🎵 Generiere Sprache...")
        tts_path = Path(tempfile.gettempdir()) / f"tts_{int(time.time())}.wav"
        
        # FIX: Piper erwartet bytes, nicht string
        result = subprocess.run(
            [str(PIPER_EXE), "--model", str(PIPER_MODEL), "--output_file", str(tts_path)],
            input=response.encode('utf-8'),  # <-- FIX: bytes statt string
            capture_output=True,
            timeout=60
        )
        
        if result.returncode == 0 and tts_path.exists():
            print("🔊 Spiele ab...")
            
            try:
                with wave.open(str(tts_path), 'rb') as wf:
                    frames = wf.readframes(wf.getnframes())
                    audio_data = np.frombuffer(frames, dtype=np.int16)
                    sd.play(audio_data, wf.getframerate())
                    sd.wait()
                
                print("✅ Fertig!")
            except Exception as e:
                print(f"⚠️  Fehler beim Abspielen: {e}")
            
            try:
                tts_path.unlink()
            except:
                pass
        else:
            print("❌ TTS Fehler")
            if result.stderr:
                print(f"   {result.stderr.decode('utf-8', errors='ignore')[:100]}")
        
    except KeyboardInterrupt:
        print("\n\nBeendet. Bis zum naechsten Mal!")
        break
    except Exception as e:
        print(f"\n❌ Fehler: {e}")
        continue
