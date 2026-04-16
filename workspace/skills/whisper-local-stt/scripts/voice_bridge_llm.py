#!/usr/bin/env python3
"""
Voice Bridge - Direct LLM Integration

Workflow:
    1. ENTER -> Sprechen -> ENTER
    2. Transkription mit Whisper
    3. Text wird in Request-Datei geschrieben
    4. Wartet auf Response-Datei (vom LLM)
    5. TTS generieren und abspielen

Usage:
    python voice_bridge_llm.py
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

# Kommunikations-Verzeichnisse
BRIDGE_DIR = Path.home() / ".openclaw" / "voice_bridge"
REQUESTS_DIR = BRIDGE_DIR / "requests"
RESPONSES_DIR = BRIDGE_DIR / "responses"

def setup_dirs():
    """Erstelle Verzeichnisse"""
    BRIDGE_DIR.mkdir(parents=True, exist_ok=True)
    REQUESTS_DIR.mkdir(parents=True, exist_ok=True)
    RESPONSES_DIR.mkdir(parents=True, exist_ok=True)

def record_audio():
    """Nimmt Audio auf bis ENTER gedrueckt wird"""
    print("\n[DRUCKE ENTER UND SPRICH...]")
    input()
    
    print("\n[🔴 NIMMT AUF... sprich jetzt!]")
    print("[DRUCKE ENTER WENN DU FERTIG BIST...]")
    
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
    """Nutzt transcribe.py fuer Transkription"""
    print("[🔄 Transkribiere...]")
    
    result = subprocess.run(
        [sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)],
        capture_output=True,
        text=True,
        timeout=120
    )
    
    text = result.stdout.strip()
    # Filtere Debug-Output raus
    lines = [l for l in text.split('\n') if l.strip() and not l.startswith('🔧') and not l.startswith('⚙️')]
    if lines:
        return lines[-1].strip()
    return "[Kein Text erkannt]"

def send_request(text):
    """
    Schreibt Request-Datei und wartet auf Response.
    """
    request_id = f"req_{int(time.time())}"
    
    request_data = {
        "id": request_id,
        "timestamp": datetime.now().isoformat(),
        "text": text,
        "status": "pending"
    }
    
    request_file = REQUESTS_DIR / f"{request_id}.json"
    with open(request_file, 'w', encoding='utf-8') as f:
        json.dump(request_data, f, indent=2)
    
    print(f"\n[📤 Request gesendet: {request_id}]")
    print(f"   Warte auf Andrew's Antwort...")
    
    # Warte auf Response (max 60 Sekunden)
    response_file = RESPONSES_DIR / f"{request_id}.json"
    start_time = time.time()
    
    while time.time() - start_time < 60:
        if response_file.exists():
            try:
                with open(response_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                # Cleanup
                try:
                    response_file.unlink()
                    request_file.unlink()
                except:
                    pass
                
                return data.get("response")
            except Exception as e:
                print(f"[⚠️ Fehler beim Lesen: {e}]")
                return None
        
        time.sleep(0.5)
    
    print("[⚠️ Timeout - keine Antwort erhalten]")
    # Cleanup
    try:
        request_file.unlink()
    except:
        pass
    return None

def generate_tts(text, output_path):
    """Generiert TTS mit Piper"""
    print("[🎵 Generiere Sprache...]")
    
    result = subprocess.run(
        [str(PIPER_EXE), "--model", str(PIPER_MODEL), "--output_file", str(output_path)],
        input=text.encode('utf-8'),
        capture_output=True,
        timeout=60
    )
    
    return result.returncode == 0 and output_path.exists()

def play_audio(wav_path):
    """Spielt Audio direkt auf dem PC ab"""
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
        print(f"[⚠️ Fehler beim Abspielen: {e}]")
        return False

def main():
    """Hauptfunktion"""
    print("\n" + "="*60)
    print("🎙️  VOICE BRIDGE - Direct LLM Integration")
    print("="*60)
    print("\nWorkflow:")
    print("  1. ENTER → Sprechen → ENTER")
    print("  2. Transkription (Whisper)")
    print("  3. Text → Andrew (LLM)")
    print("  4. Antwort → TTS")
    print("  5. Audio wird abgespielt!")
    print("\n[Druecke Ctrl+C zum Beenden]")
    print("="*60)
    
    setup_dirs()
    
    # Pruefe Voraussetzungen
    if not PIPER_EXE.exists():
        print(f"\n[❌ Piper nicht gefunden: {PIPER_EXE}]")
        print("   Bitte installiere Piper TTS zuerst")
        return
    
    if not TRANSCRIBE_SCRIPT.exists():
        print(f"\n[❌ Transcribe Script nicht gefunden: {TRANSCRIBE_SCRIPT}]")
        return
    
    print("\n[✅ Alle Komponenten gefunden!]")
    print(f"[📁 Requests: {REQUESTS_DIR}]")
    print(f"[📁 Responses: {RESPONSES_DIR}]")
    
    while True:
        try:
            # 1. Aufnahme
            wav_path = record_audio()
            if not wav_path:
                continue
            
            # 2. Transkription
            user_text = transcribe(wav_path)
            
            # Cleanup
            try:
                wav_path.unlink()
            except:
                pass
            
            if user_text == "[Kein Text erkannt]":
                print("[❌ Nichts verstanden, versuch es nochmal]")
                continue
            
            print(f"\n[📝 Du]: {user_text}")
            
            # 3. An LLM senden und Antwort empfangen
            print("\n" + "-"*60)
            llm_response = send_request(user_text)
            
            if not llm_response:
                print("[❌ Keine Antwort vom LLM erhalten]")
                print("   Stelle sicher, dass Andrew die Requests verarbeitet!")
                continue
            
            print(f"\n[💬 Andrew]: {llm_response}")
            print("-"*60)
            
            # 4. TTS generieren
            tts_path = Path(tempfile.gettempdir()) / f"tts_{int(time.time())}.wav"
            
            if generate_tts(llm_response, tts_path):
                # 5. Abspielen
                play_audio(tts_path)
                
                # Cleanup
                try:
                    tts_path.unlink()
                except:
                    pass
            else:
                print("[❌ TTS Fehler]")
            
        except KeyboardInterrupt:
            print("\n\n[👋 Beendet. Bis bald!]")
            break
        except Exception as e:
            print(f"\n[❌ Fehler: {e}]")
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    main()
