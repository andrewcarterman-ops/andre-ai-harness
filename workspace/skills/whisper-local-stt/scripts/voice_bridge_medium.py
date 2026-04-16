#!/usr/bin/env python3
"""
Voice Bridge - MEDIUM Modell (bessere Qualitaet)
Langsamer aber genauer

Usage:
    python voice_bridge_medium.py
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
print("VOICE BRIDGE - MEDIUM Modell")
print("="*60)
print("\n🎙️  ENTER druecken -> Sprich etwas -> ENTER druecken")
print("\n⚠️  WARNUNG: MEDIUM ist langsam (30-60s auf deiner CPU)")
print("   Aber die Erkennung ist viel besser!")
print("\n   Ctrl+C zum Beenden")
print("="*60 + "\n")

# WICHTIG: Aendere transcribe.py Config auf medium
CONFIG_FILE = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "config.json"

# Setze medium als default
if CONFIG_FILE.exists():
    import json
    with open(CONFIG_FILE, 'r') as f:
        config = json.load(f)
    config['default_model'] = 'medium'
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)
    print("[OK] Config auf MEDIUM gesetzt\n")

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
        
        wav_path = Path(tempfile.gettempdir()) / f"medium_{int(time.time())}.wav"
        with wave.open(str(wav_path), 'wb') as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(16000)
            wf.writeframes(audio.tobytes())
        
        print(f"\n✅ Aufnahme: {duration:.1f}s")
        
        # Transkription mit MEDIUM
        print("🔄 Transkribiere mit MEDIUM... (das dauert!)")
        print("   Bitte warten...")
        
        result = subprocess.run(
            [sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)],
            capture_output=True,
            text=True,
            timeout=300  # 5 Minuten Timeout für medium
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
            response = "Entschuldigung, ich habe dich nicht verstanden."
        
        print(f"\n💬 ANDREW: {response}")
        
        # TTS
        print("\n🎵 Generiere Sprache...")
        tts_path = Path(tempfile.gettempdir()) / f"tts_{int(time.time())}.wav"
        
        result = subprocess.run(
            [str(PIPER_EXE), "--model", str(PIPER_MODEL), "--output_file", str(tts_path)],
            input=response.encode('utf-8'),
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
                print(f"⚠️  Fehler: {e}")
            
            try:
                tts_path.unlink()
            except:
                pass
        else:
            print("❌ TTS Fehler")
        
    except KeyboardInterrupt:
        print("\n\nBeendet.")
        # Reset auf base
        if CONFIG_FILE.exists():
            import json
            with open(CONFIG_FILE, 'r') as f:
                config = json.load(f)
            config['default_model'] = 'base'
            with open(CONFIG_FILE, 'w') as f:
                json.dump(config, f, indent=2)
        break
    except Exception as e:
        print(f"\n❌ Fehler: {e}")
        continue
