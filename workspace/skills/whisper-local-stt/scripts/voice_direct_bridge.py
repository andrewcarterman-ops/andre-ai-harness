#!/usr/bin/env python3
"""
Voice Direct Bridge - Direkte OpenClaw Integration
===================================================
Dieses Script nimmt Sprache auf und nutzt direkt OpenClaw's
Datei-basierte Kommunikation fuer sofortige Antworten.

DIESES SCRIPT LAUFT AUSSERHALB VON OPENCAAW (z.B. in CMD/PowerShell).
Es kommuniziert mit der laufenden OpenClaw TUI ueber Dateien.

WORKFLOW:
1. ENTER -> Sprich -> ENTER (Aufnahme)
2. Whisper transkribiert
3. Frage wird in request.json gespeichert
4. Script zeigt: "Bitte in TUI antworten..."
5. DU siehst die Frage in der TUI und gibst kurz die Antwort ein
6. Script erkennt Antwort in response.json
7. Piper TTS spielt Antwort ab

VORTEIL: Kein Cron nötig, keine Timeouts, du hast Kontrolle!

STARTEN:
    python voice_direct_bridge.py
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

# Kommunikation
COMM_DIR = Path.home() / ".openclaw" / "voice_comm"
REQUEST_FILE = COMM_DIR / "request.json"
RESPONSE_FILE = COMM_DIR / "response.json"

def log(msg):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"[{timestamp}] {msg}", flush=True)

def play_tts(text):
    """Text mit Piper TTS ausgeben"""
    if not text or len(text) < 2:
        return False
    
    try:
        # Kurze Antworten bevorzugen (max 500 Zeichen fuer TTS)
        if len(text) > 500:
            text = text[:500] + "..."
        
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
    """Sende Frage an OpenClaw"""
    COMM_DIR.mkdir(parents=True, exist_ok=True)
    
    # Cleanup
    for f in [REQUEST_FILE, RESPONSE_FILE]:
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
    
    log("📤 Frage gespeichert")
    log(f"   Datei: {REQUEST_FILE}")

def wait_for_response(timeout=180):
    """Warte auf Antwort vom Benutzer in OpenClaw"""
    log("")
    log("="*70)
    log("⚠️  WICHTIG: Wechsle JETZT zur OpenClaw TUI!")
    log("="*70)
    log("")
    log("Schritte:")
    log("  1. Gehe zur OpenClaw TUI (dieses Fenster)")
    log("  2. Du wirst die Frage dort sehen")
    log("  3. Gib deine Antwort ein (kurz, max 2-3 Saetze)")
    log("  4. Die Antwort wird automatisch uebernommen")
    log("")
    log("Warte auf Antwort... (Timeout: 3 Minuten)")
    log("")
    
    start = time.time()
    dots = 0
    
    while time.time() - start < timeout:
        if RESPONSE_FILE.exists():
            try:
                time.sleep(0.5)  # Kurze Pause fuer File-Write
                with open(RESPONSE_FILE, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                # Cleanup
                try:
                    RESPONSE_FILE.unlink()
                    REQUEST_FILE.unlink()
                except:
                    pass
                
                log("✅ Antwort erhalten!")
                return data.get("answer", ""), data.get("source", "unknown")
            except Exception as e:
                log(f"Fehler beim Lesen: {e}")
        
        # Animierter Warte-Punkt
        dots = (dots + 1) % 4
        print(f"\r   Warte{' .' * dots}{' ' * (4-dots)}", end='', flush=True)
        time.sleep(1)
    
    print()
    log("⚠️  Timeout! Keine Antwort erhalten.")
    return None, None

def main():
    COMM_DIR.mkdir(parents=True, exist_ok=True)
    
    # Cleanup alte Dateien
    for f in [REQUEST_FILE, RESPONSE_FILE]:
        try:
            if f.exists():
                f.unlink()
        except:
            pass
    
    print("\n" + "="*70)
    print("  VOICE DIRECT BRIDGE - Manuelle OpenClaw Integration")
    print("="*70)
    print("\n  🎙️  ENTER -> Sprich -> ENTER -> 📤 -> 🤔 -> 🔊")
    print("\n  Dieses Script laeuft in deinem Terminal (CMD/PowerShell).")
    print("  Du musst zur OpenClaw TUI wechseln um die Antwort einzugeben!")
    print("\n  Strg+C zum Beenden")
    print("="*70 + "\n")
    
    log("Voice Direct Bridge bereit.")
    
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
            
            # Sende an OpenClaw
            send_request(question)
            
            # Warte auf Antwort (du musst in TUI antworten!)
            response, source = wait_for_response()
            
            if response:
                print("\n" + "="*70)
                log(f"💬 OpenClaw: {response[:100]}...")
                print("="*70)
                
                # TTS
                log("🔊 Spiele Antwort...")
                if play_tts(response):
                    log("✅ Fertig!")
                else:
                    log("⚠️  TTS Fehler, aber Antwort war:")
                    log(f"   {response}")
            else:
                log("⚠️  Keine Antwort erhalten")
                log("   Bitte stelle sicher, dass du in der TUI geantwortet hast!")
                play_tts("Keine Antwort erhalten. Bitte antworte in der TUI.")
                
        except KeyboardInterrupt:
            log("\n👋 Voice Direct Bridge beendet.")
            break
        except Exception as e:
            log(f"❌ Fehler: {e}")
            import traceback
            traceback.print_exc()
            continue

if __name__ == "__main__":
    main()
