#!/usr/bin/env python3
"""
Voice Bridge v2 - Jetzt im richtigen Verzeichnis!
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

TRANSCRIBE_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "transcribe.py"
PIPER_EXE = Path.home() / ".openclaw" / "piper" / "piper" / "piper.exe"
PIPER_MODEL = Path.home() / ".openclaw" / "piper" / "models" / "de_DE-thorsten-high.onnx"

BRIDGE_DIR = Path.home() / ".openclaw" / "voice_bridge"
REQUESTS_DIR = BRIDGE_DIR / "requests"
RESPONSES_DIR = BRIDGE_DIR / "responses"

def record_audio():
    print("\n" + "="*60)
    print("[DRUCKE ENTER UND SPRICH...]")
    input()
    print("\n[🔴 NIMMT AUF... sprich jetzt!]")
    print("[DRUCKE ENTER WENN DU FERTIG BIST...]")
    
    recording = []
    def callback(indata, frames, time_info, status):
        recording.append(indata.copy())
    
    stream = sd.InputStream(samplerate=16000, channels=1, dtype=np.int16, callback=callback, blocksize=1024)
    stream.start()
    input()
    stream.stop()
    stream.close()
    
    if not recording:
        print("[❌ Keine Aufnahme!]")
        return None
    
    audio = np.concatenate(recording, axis=0)
    duration = len(audio) / 16000
    
    wav_path = Path(tempfile.gettempdir()) / f"voice_{int(time.time())}.wav"
    with wave.open(str(wav_path), 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(audio.tobytes())
    
    print(f"[✅ Aufnahme: {duration:.1f}s]")
    return wav_path

def transcribe(wav_path):
    print("[🔄 Transkribiere...]")
    result = subprocess.run([sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)], capture_output=True, text=True, timeout=120)
    text = result.stdout.strip()
    lines = [l for l in text.split('\n') if l.strip() and not l.startswith('🔧')]
    if lines:
        return lines[-1].strip()
    return "[Kein Text erkannt]"

def send_request(text):
    request_id = f"req_{int(time.time())}"
    request_data = {"id": request_id, "timestamp": datetime.now().isoformat(), "text": text, "status": "pending"}
    
    request_file = REQUESTS_DIR / f"{request_id}.json"
    REQUESTS_DIR.mkdir(parents=True, exist_ok=True)
    with open(request_file, 'w', encoding='utf-8') as f:
        json.dump(request_data, f, indent=2)
    
    print(f"\n[📤 Request gesendet: {request_id}]")
    print(f"   Text: {text[:50]}..." if len(text) > 50 else f"   Text: {text}")
    print(f"   Warte auf Antwort... (max 5 Minuten)")
    
    response_file = RESPONSES_DIR / f"{request_id}.json"
    RESPONSES_DIR.mkdir(parents=True, exist_ok=True)
    
    start_time = time.time()
    dots = 0
    while time.time() - start_time < 300:
        if response_file.exists():
            try:
                with open(response_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                print(f"\n[✅ Antwort empfangen!]")
                try:
                    response_file.unlink()
                    request_file.unlink()
                except:
                    pass
                return data.get("response")
            except:
                return None
        dots = (dots + 1) % 4
        print(f"\r   Warte{'.' * dots}{' ' * (3-dots)}", end='', flush=True)
        time.sleep(0.5)
    
    print("\n[⚠️ Timeout]")
    try:
        request_file.unlink()
    except:
        pass
    return None

def generate_tts(text, output_path):
    print("[🎵 Generiere Sprache...]")
    result = subprocess.run([str(PIPER_EXE), "--model", str(PIPER_MODEL), "--output_file", str(output_path)], input=text.encode('utf-8'), capture_output=True, timeout=60)
    return result.returncode == 0 and output_path.exists()

def play_audio(wav_path):
    print("[🔊 Spiele Antwort ab...]")
    try:
        with wave.open(str(wav_path), 'rb') as wf:
            frames = wf.readframes(wf.getnframes())
            rate = wf.getframerate()
            audio = np.frombuffer(frames, dtype=np.int16)
            sd.play(audio, rate)
            sd.wait()
        print("[✅ Fertig!]")
        return True
    except Exception as e:
        print(f"[⚠️ Fehler: {e}]")
        return False

def main():
    print("\n" + "="*60)
    print("🎙️  VOICE BRIDGE v2 - Direct LLM Integration")
    print("="*60)
    print("\n1. ENTER → Sprechen → ENTER")
    print("2. Transkription → Request → Antwort → TTS")
    print("\n👉 WICHTIG: Starte in einem ANDEREN Terminal:")
    print("   python voice_bridge_autoresponder.py")
    print("\n[Druecke Ctrl+C zum Beenden]")
    print("="*60)
    
    if not PIPER_EXE.exists():
        print(f"\n[❌ Piper nicht gefunden!]")
        return
    
    print("\n[✅ Bereit! Starte den Auto-Responder und sprich los!]")
    
    while True:
        try:
            wav_path = record_audio()
            if not wav_path:
                continue
            
            user_text = transcribe(wav_path)
            try:
                wav_path.unlink()
            except:
                pass
            
            if user_text == "[Kein Text erkannt]":
                print("[❌ Nichts verstanden]")
                continue
            
            print(f"\n[📝 Du]: {user_text}")
            llm_response = send_request(user_text)
            
            if not llm_response:
                print("[❌ Keine Antwort - starte den Auto-Responder!]")
                continue
            
            print(f"\n[💬 Andrew]: {llm_response}")
            
            tts_path = Path(tempfile.gettempdir()) / f"tts_{int(time.time())}.wav"
            if generate_tts(llm_response, tts_path):
                play_audio(tts_path)
                try:
                    tts_path.unlink()
                except:
                    pass
            else:
                print("[❌ TTS Fehler]")
            
        except KeyboardInterrupt:
            print("\n\n[👋 Beendet!]")
            break
        except Exception as e:
            print(f"\n[❌ Fehler: {e}]")

if __name__ == "__main__":
    main()
