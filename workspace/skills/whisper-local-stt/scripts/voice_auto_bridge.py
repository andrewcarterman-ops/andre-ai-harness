#!/usr/bin/env python3
"""
Voice Auto-Bridge - Vollautomatisch
===================================
Nutzt OpenClaw Cron fuer automatische Antworten.

Workflow:
1. ENTER -> Sprich -> ENTER (Aufnahme)
2. Whisper transkribiert
3. Frage wird in Datei gespeichert
4. OpenClaw Cron erkennt Datei automatisch
5. Antwort wird generiert und in Datei gespeichert
6. Client liest Antwort und macht TTS
7. ALLES automatisch - keine manuelle Eingabe!

STARTEN:
    python skills/whisper-local-stt/scripts/voice_auto_bridge.py

OPENCAAW SETUP (einmalig):
    cron add --every 5s --command "python skills/whisper-local-stt/scripts/voice_auto_responder.py"
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

# Auto-Kommunikation
AUTO_DIR = Path.home() / ".openclaw" / "voice_auto"
REQUEST_FILE = AUTO_DIR / "request.json"
RESPONSE_FILE = AUTO_DIR / "response.json"
PROCESSING_FLAG = AUTO_DIR / "processing.flag"

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)

def play_tts(text):
    """Text mit Piper TTS ausgeben"""
    if not text or len(text) < 2:
        return False
    
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
    
    input()
    
    stream.stop()
    stream.close()
    
    if not recording:
        return None, 0
    
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
    result = subprocess.run(
        [sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)],
        capture_output=True,
        text=True,
        timeout=300
    )
    
    text = result.stdout.strip()
    
    try:
        wav_path.unlink()
    except:
        pass
    
    return text

def send_request(question):
    """Sende Frage an Auto-Responder"""
    AUTO_DIR.mkdir(parents=True, exist_ok=True)
    
    # Cleanup alte Dateien
    for f in [REQUEST_FILE, RESPONSE_FILE, PROCESSING_FLAG]:
        try:
            if f.exists():
                f.unlink()
        except:
            pass
    
    data = {
        "timestamp": int(time.time()),
        "question": question,
        "status": "pending"
    }
    
    with open(REQUEST_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    
    log("📤 Frage gesendet. Warte auf automatische Antwort...")
    log(f"   Gespeichert in: {REQUEST_FILE}")

def wait_for_response(timeout=120):
    """Warte auf automatische Antwort vom OpenClaw Cron"""
    log("⏳ Warte auf OpenClaw Antwort...")
    log("   (Dies kann 10-30 Sekunden dauern)")
    
    start = time.time()
    last_status = ""
    
    while time.time() - start < timeout:
        # Zeige Status
        if PROCESSING_FLAG.exists():
            if last_status != "processing":
                log("🤖 OpenClaw verarbeitet die Frage...")
                last_status = "processing"
        
        # Pruefe Antwort
        if RESPONSE_FILE.exists():
            try:
                with open(RESPONSE_FILE, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                # Cleanup
                try:
                    RESPONSE_FILE.unlink()
                    REQUEST_FILE.unlink()
                    if PROCESSING_FLAG.exists():
                        PROCESSING_FLAG.unlink()
                except:
                    pass
                
                return data.get("answer", ""), data.get("model", "unknown")
            except Exception as e:
                log(f"Fehler beim Lesen: {e}")
        
        time.sleep(1)
    
    log("⚠️  Timeout! Keine Antwort erhalten.")
    return None, None

def main():
    AUTO_DIR.mkdir(parents=True, exist_ok=True)
    
    print("\n" + "="*70)
    print("  VOICE AUTO-BRIDGE - Vollautomatisch")
    print("="*70)
    print("\n  🎙️  ENTER -> Sprich -> ENTER -> 🤖 -> 🔊")
    print("\n  ALLES automatisch! OpenClaw antwortet selbst.")
    print("\n  ⚠️  WICHTIG: Auto-Responder muss laufen!")
    print("     Setup: cron add --every 5s voice_auto_responder")
    print("\n  Strg+C zum Beenden")
    print("="*70 + "\n")
    
    # Check vorherige Requests
    if REQUEST_FILE.exists():
        log("⚠️  Alte Request-Datei gefunden, bereinige...")
        try:
            REQUEST_FILE.unlink()
        except:
            pass
    
    log("Voice Auto-Bridge bereit.")
    
    while True:
        try:
            print("\n" + "-"*70)
            log("[Druecke ENTER zum Sprechen...]")
            input()
            
            # Aufnahme
            wav_path, duration = record_audio()
            
            if not wav_path or duration < 0.5:
                log("⚠️  Aufnahme zu kurz")
                play_tts("Bitte noch einmal, das war zu kurz.")
                continue
            
            log(f"✅ Aufnahme: {duration:.1f}s")
            
            # Transkription
            log("🔄 Transkribiere...")
            question = transcribe(wav_path)
            
            if not question or question == "[Kein Text erkannt]":
                log("❌ Nichts verstanden")
                play_tts("Entschuldigung, ich habe dich nicht verstanden.")
                continue
            
            print("\n" + "="*70)
            log(f"📝 DU: {question}")
            print("="*70)
            
            # Sende an Auto-Responder
            send_request(question)
            
            # Warte auf automatische Antwort
            response, model = wait_for_response()
            
            if response:
                print("\n" + "="*70)
                log(f"🤖 OpenClaw ({model}): {response[:150]}...")
                print("="*70)
                
                # TTS
                log("🔊 Spiele Antwort...")
                play_tts(response)
                log("✅ Fertig!")
            else:
                log("⚠️  Keine Antwort - pruefe ob Auto-Responder laeuft!")
                play_tts("Keine Antwort erhalten. Bitte pruefen Sie den Auto-Responder.")
                
        except KeyboardInterrupt:
            log("\n👋 Voice Auto-Bridge beendet.")
            break
        except Exception as e:
            log(f"❌ Fehler: {e}")
            import traceback
            traceback.print_exc()
            continue

if __name__ == "__main__":
    main()
