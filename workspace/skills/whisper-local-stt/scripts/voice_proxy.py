#!/usr/bin/env python3
"""
Voice Proxy - OpenClaw Integration
==================================
Laeuft IN einer OpenClaw-Session und wartet auf Voice-Anfragen.

Workflow:
1. Du startest diesen Proxy in OpenClaw (er laeuft im Hintergrund)
2. Du nutzt voice_bridge_client.py (standalone) fuer Spracheingabe
3. Client schreibt Frage in Datei
4. Proxy liest Frage, nutzt sessions_spawn fuer Antwort
5. Proxy schreibt Antwort in Datei
6. Client liest Antwort und macht TTS

STARTEN IN OPENCAAW:
    python skills/whisper-local-stt/scripts/voice_proxy.py
"""

import sys
import time
import json
from pathlib import Path
from datetime import datetime

# Kommunikations-Dateien
COMM_DIR = Path.home() / ".openclaw" / "voice_comm"
REQUEST_FILE = COMM_DIR / "request.json"
RESPONSE_FILE = COMM_DIR / "response.json"

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)

def ensure_comm_dir():
    COMM_DIR.mkdir(parents=True, exist_ok=True)

def check_request():
    """Pruefe ob eine neue Anfrage da ist"""
    if not REQUEST_FILE.exists():
        return None
    
    try:
        with open(REQUEST_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Loesche Request nach Lesen
        REQUEST_FILE.unlink()
        return data
    except Exception as e:
        log(f"Fehler beim Lesen: {e}")
        return None

def save_response(question, answer):
    """Speichere Antwort"""
    data = {
        "timestamp": int(time.time()),
        "question": question,
        "answer": answer
    }
    
    with open(RESPONSE_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

def main():
    ensure_comm_dir()
    
    print("\n" + "="*70)
    print("  VOICE PROXY - OpenClaw Sprach-Assistent")
    print("="*70)
    print("\n  Status: Warte auf Sprachanfragen...")
    print(f"  Kommunikations-Ordner: {COMM_DIR}")
    print("\n  Dieser Proxy laeuft in OpenClaw und beantwortet Fragen.")
    print("  Starte parallel: voice_bridge_client.py (standalone)")
    print("\n  Strg+C zum Beenden")
    print("="*70 + "\n")
    
    log("Voice Proxy gestartet. Warte auf Anfragen...")
    
    while True:
        try:
            # Pruefe auf neue Anfrage
            request = check_request()
            
            if request:
                question = request.get("question", "")
                timestamp = request.get("timestamp", 0)
                
                log(f"🎙️  Neue Frage erhalten: {question}")
                
                # WICHTIG: Wir sind IN einer OpenClaw-Session!
                # Wir koennen nicht direkt sessions_spawn aufrufen (Python != Node)
                # Stattdessen: Wir nutzen einen Trick...
                
                print("\n" + ">>>VOICE_INPUT<<<")
                print(question)
                print(">>>END_VOICE_INPUT<<<")
                
                # Jetzt MUSS der Mensch in der TUI antworten!
                log("📝 Bitte antworte in der OpenClaw TUI!")
                log("   (Die Frage wurde oben als Marker ausgegeben)")
                log("   Warte auf deine Antwort...")
                
                # Lese Antwort vom Benutzer
                print("\nGib deine Antwort ein (mehrzeilig, 'ENDE' fuer Ende):")
                
                lines = []
                while True:
                    try:
                        line = input()
                        if line.strip() == "ENDE":
                            break
                        lines.append(line)
                    except EOFError:
                        break
                
                answer = "\n".join(lines).strip()
                
                if answer:
                    save_response(question, answer)
                    log(f"💾 Antwort gespeichert ({len(answer)} Zeichen)")
                else:
                    log("⚠️  Keine Antwort erhalten")
                    save_response(question, "Keine Antwort erhalten.")
            
            # Kurze Pause
            time.sleep(0.5)
            
        except KeyboardInterrupt:
            log("\n👋 Voice Proxy beendet.")
            break
        except Exception as e:
            log(f"❌ Fehler: {e}")
            time.sleep(1)
            continue

if __name__ == "__main__":
    main()
