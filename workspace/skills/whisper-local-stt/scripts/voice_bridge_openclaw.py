#!/usr/bin/env python3
"""
Voice Bridge - OpenClaw Integration
Laeuft als Sub-Agent und kommuniziert mit Haupt-Session

Usage:
    In OpenClaw ausfuehren:
    python skills/whisper-local-stt/scripts/voice_bridge_openclaw.py
"""

import sys
import time
import tempfile
import wave
import subprocess
import json
from pathlib import Path
from datetime import datetime

import numpy as np
import sounddevice as sd

# Pfade
TRANSCRIBE_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "transcribe.py"
PIPER_EXE = Path.home() / ".openclaw" / "piper" / "piper" / "piper.exe"
PIPER_MODEL = Path.home() / ".openclaw" / "piper" / "models" / "de_DE-thorsten-high.onnx"

# Temp-Datei fuer Kommunikation
RESPONSE_FILE = Path(tempfile.gettempdir()) / "voice_bridge_response.txt"

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")

def play_tts(text):
    """Text mit Piper TTS ausgeben"""
    try:
        tts_path = Path(tempfile.gettempdir()) / f"tts_{int(time.time())}.wav"
        
        result = subprocess.run(
            [str(PIPER_EXE), "--model", str(PIPER_MODEL), "--output_file", str(tts_path)],
            input=text.encode('utf-8'),
            capture_output=True,
            timeout=60
        )
        
        if result.returncode == 0 and tts_path.exists():
            with wave.open(str(tts_path), 'rb') as wf:
                frames = wf.readframes(wf.getnframes())
                audio_data = np.frombuffer(frames, dtype=np.int16)
                sd.play(audio_data, wf.getframerate())
                sd.wait()
            
            try:
                tts_path.unlink()
            except:
                pass
            return True
    except Exception as e:
        log(f"TTS Fehler: {e}")
    return False

def record_audio():
    """Audio aufnehmen bis ENTER gedrueckt wird"""
    log("🔴 NIMMT AUF... (sprich jetzt!)")
    log("   [Druecke ENTER zum Beenden...]")
    
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
        return None, 0
    
    # Speichern
    audio = np.concatenate(recording, axis=0)
    duration = len(audio) / 16000
    
    wav_path = Path(tempfile.gettempdir()) / f"voice_{int(time.time())}.wav"
    with wave.open(str(wav_path), 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(audio.tobytes())
    
    return wav_path, duration

def transcribe(wav_path):
    """Whisper Transkription"""
    log("🔄 Transkribiere...")
    
    result = subprocess.run(
        [sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)],
        capture_output=True,
        text=True,
        timeout=300
    )
    
    text = result.stdout.strip()
    
    # Cleanup
    try:
        wav_path.unlink()
    except:
        pass
    
    return text

def ask_openclaw(question):
    """
    Fragt OpenClaw via sessions_spawn
    Schreibt Ergebnis in eine Datei, die die Haupt-Session lesen kann
    """
    log("📤 Sende an OpenClaw...")
    
    # Erstelle eine Payload-Datei fuer die Inter-Prozess-Kommunikation
    request_file = Path(tempfile.gettempdir()) / "voice_bridge_request.json"
    
    payload = {
        "timestamp": int(time.time()),
        "question": question,
        "response_file": str(RESPONSE_FILE)
    }
    
    with open(request_file, 'w', encoding='utf-8') as f:
        json.dump(payload, f, indent=2)
    
    log(f"💾 Frage gespeichert in: {request_file}")
    log("⏳ Warte auf Antwort von OpenClaw...")
    log("   (Hauptagent muss die Frage beantworten)")
    
    return request_file

def main():
    print("\n" + "="*60)
    print("VOICE BRIDGE - OpenClaw Integration")
    print("="*60)
    print("\n🎙️  ENTER druecken -> Sprich -> ENTER -> OpenClaw beantwortet")
    print("\n⚠️  WICHTIG: Dieses Script muss IN einer OpenClaw-Session laufen!")
    print("   Starte es mit: python skills/whisper-local-stt/scripts/voice_bridge_openclaw.py")
    print("\n   Ctrl+C zum Beenden")
    print("="*60 + "\n")
    
    while True:
        try:
            # Warte auf ENTER
            log("[Druecke ENTER zum Sprechen...]")
            input()
            
            # Aufnahme
            wav_path, duration = record_audio()
            
            if not wav_path or duration < 0.5:
                log("⚠️  Aufnahme zu kurz oder leer")
                continue
            
            log(f"✅ Aufnahme: {duration:.1f}s")
            
            # Transkription
            text = transcribe(wav_path)
            
            if not text or text == "[Kein Text erkannt]":
                log("❌ Nichts verstanden")
                play_tts("Entschuldigung, ich habe dich nicht verstanden.")
                continue
            
            log(f"📝 DU: {text}")
            print(f"\n{'='*60}")
            print(f"FRAGE: {text}")
            print(f"{'='*60}\n")
            
            # Frage speichern fuer OpenClaw
            request_file = ask_openclaw(text)
            
            log("🔄 Wechsle zur Haupt-Session und gib die Antwort ein...")
            log("   (Dieses Script pausiert jetzt)")
            
            # TTS Hinweis
            play_tts("Frage erhalten. Bitte in der Haupt-Session antworten.")
            
            # Pausiere und warte auf manuelle Eingabe in Haupt-Session
            log("\n📝 INSTRUKTION fuer Haupt-Session:")
            log(f"   Lese: {request_file}")
            log(f"   Antworte auf: '{text}'")
            log(f"   Schreibe Antwort nach: {RESPONSE_FILE}")
            log("\n   [Druecke hier ENTER wenn Antwort bereit...]")
            input()
            
            # Lese Antwort
            if RESPONSE_FILE.exists():
                with open(RESPONSE_FILE, 'r', encoding='utf-8') as f:
                    response = f.read().strip()
                
                log(f"💬 OpenClaw: {response}")
                print(f"\n{'='*60}")
                print(f"ANTWORT: {response}")
                print(f"{'='*60}\n")
                
                # TTS
                log("🔊 Spiele Antwort...")
                play_tts(response)
                
                # Cleanup
                try:
                    RESPONSE_FILE.unlink()
                except:
                    pass
            else:
                log("⚠️  Keine Antwort-Datei gefunden")
                play_tts("Keine Antwort erhalten.")
            
            # Cleanup Request
            try:
                request_file.unlink()
            except:
                pass
                
        except KeyboardInterrupt:
            log("\nBeendet.")
            break
        except Exception as e:
            log(f"❌ Fehler: {e}")
            import traceback
            traceback.print_exc()
            continue

if __name__ == "__main__":
    main()
