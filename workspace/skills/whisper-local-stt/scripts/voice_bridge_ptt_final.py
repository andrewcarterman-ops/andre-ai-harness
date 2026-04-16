#!/usr/bin/env python3
"""
Voice Bridge Phase 3 - PTT mit transcribe.py
Einfach und zuverlässig

Usage:
    python voice_bridge_ptt_final.py
    ENTER drücken → Sprechen → ENTER loslassen → Transkription
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
INBOX_DIR = Path.home() / ".openclaw" / "voice" / "inbox"
OUTBOX_DIR = Path.home() / ".openclaw" / "voice" / "outbox" / "responses"

def record_audio():
    """Nimmt Audio auf bis ENTER gedrückt wird"""
    print("\n[AUFNAHME LÄUFT...]")
    print("Sprich jetzt! (Drücke ENTER zum Beenden)")
    
    # Starte Aufnahme im Hintergrund
    recording = []
    
    def callback(indata, frames, time_info, status):
        recording.append(indata.copy())
    
    stream = sd.InputStream(samplerate=16000, channels=1, dtype=np.int16, callback=callback)
    stream.start()
    
    # Warte auf ENTER
    input()
    
    stream.stop()
    stream.close()
    
    if not recording:
        return None
    
    # Speichere als WAV
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

def transcribe_with_script(wav_path):
    """Nutzt transcribe.py für Transkription"""
    print("[...] Transkribiere...")
    
    result = subprocess.run(
        [sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)],
        capture_output=True,
        text=True,
        timeout=120
    )
    
    # transcribe.py gibt Text auf stdout aus
    text = result.stdout.strip()
    
    return text if text else "[Kein Text erkannt]"

def main():
    """Hauptfunktion"""
    print("\n" + "="*60)
    print("PTT RECORDER FINAL - Phase 3")
    print("ENTER = Push to Talk")
    print("="*60)
    print("\nVerzeichnisse:")
    print(f"  Inbox: {INBOX_DIR}")
    print(f"  Antworten: {OUTBOX_DIR}")
    print("\nDrücke Ctrl+C zum Beenden")
    print("="*60)
    
    while True:
        try:
            print("\n" + "-"*60)
            print("Bereit. ENTER drücken und sprechen...")
            input()
            
            # Aufnahme
            wav_path = record_audio()
            
            if wav_path and wav_path.exists():
                # Transkription
                text = transcribe_with_script(wav_path)
                
                # Zeige Ergebnis
                print(f"\n{'='*60}")
                print(f"[TRANSKRIBIERT]: {text}")
                print(f"{'='*60}")
                
                # Speichere in Inbox
                msg_id = f"msg_{int(time.time())}"
                inbox_file = INBOX_DIR / "new_messages.jsonl"
                inbox_file.parent.mkdir(parents=True, exist_ok=True)
                
                import json
                entry = {
                    "id": msg_id,
                    "timestamp": datetime.now().isoformat(),
                    "text": text,
                    "source": "ptt",
                    "status": "pending_response"
                }
                with open(inbox_file, 'a', encoding='utf-8') as f:
                    f.write(json.dumps(entry) + "\n")
                
                print(f"\nGespeichert als: {msg_id}")
                print(f"Antwort schreiben in: {OUTBOX_DIR / (msg_id + '.txt')}")
                
                # Cleanup
                wav_path.unlink()
            
        except KeyboardInterrupt:
            print("\n\nBeendet.")
            break
        except Exception as e:
            print(f"\n[FEHLER]: {e}")

if __name__ == "__main__":
    main()
