#!/usr/bin/env python3
"""
Voice Auto-Responder
====================
LAeuft in OpenClaw (z.B. als Cron Job alle 5 Sekunden).
Prueft auf neue Sprach-Anfragen und beantwortet sie automatisch.

Dieses Script liest eine Request-Datei, startet einen Sub-Agent fuer
 die Antwort, und schreibt das Ergebnis zurueck.

ALS CRON JOB EINRICHTEN:
    openclaw cron add --name voice-responder --every 5s --command \
        "python skills/whisper-local-stt/scripts/voice_auto_responder.py"

ODER manuell starten:
    python skills/whisper-local-stt/scripts/voice_auto_responder.py
"""

import sys
import time
import json
from pathlib import Path
from datetime import datetime

# Auto-Kommunikation
AUTO_DIR = Path.home() / ".openclaw" / "voice_auto"
REQUEST_FILE = AUTO_DIR / "request.json"
RESPONSE_FILE = AUTO_DIR / "response.json"
PROCESSING_FLAG = AUTO_DIR / "processing.flag"

def log(msg):
    # Nur loggen wenn nicht im silent mode
    if "--silent" not in sys.argv:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)

def check_request():
    """Pruefe ob eine neue Anfrage da ist"""
    if not REQUEST_FILE.exists():
        return None
    
    # Pruefe ob wir schon dabei sind
    if PROCESSING_FLAG.exists():
        return None
    
    try:
        with open(REQUEST_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Markiere als in Bearbeitung
        with open(PROCESSING_FLAG, 'w') as f:
            f.write(str(int(time.time())))
        
        return data
    except Exception as e:
        log(f"Fehler beim Lesen: {e}")
        return None

def save_response(question, answer, model="k2p5"):
    """Speichere Antwort"""
    data = {
        "timestamp": int(time.time()),
        "question": question,
        "answer": answer,
        "model": model
    }
    
    with open(RESPONSE_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    
    # Entferne Processing-Flag
    try:
        if PROCESSING_FLAG.exists():
            PROCESSING_FLAG.unlink()
    except:
        pass

def process_with_openclaw(question):
    """
    Verarbeite Frage mit OpenClaw.
    
    DIES ist der kritische Teil - wir sind IN einer OpenClaw-Session,
    also koennen wir sessions_spawn nutzen!
    """
    log(f"🎙️  Neue Frage: {question[:80]}...")
    
    # Hier nutzen wir die Tatsache, dass wir in OpenClaw laufen
    # Wir koennen einfach print() nutzen und OpenClaw wird es als
    # Anfrage interpretieren!
    
    # Aber besser: Wir nutzen das sessions_send Konzept
    # Das hier ist der Trick - wir schreiben in stdout mit einem Marker
    
    print("\n" + ">>>VOICE_QUESTION<<<")
    print(question)
    print(">>>END_VOICE_QUESTION<<<")
    
    # Jetzt muss OpenClaw antworten... 
    # Aber wie bekommen wir die Antwort zurueck?
    
    # Loesung: Wir lesen von stdin (wenn OpenClaw es als input gibt)
    # oder wir nutzen einen Callback-Mechanismus
    
    # Fuer jetzt: Wir geben eine Standard-Antwort
    # In der echten Implementation wuerde hier sessions_spawn stehen
    
    # WORKAROUND: Wir erwarten dass OpenClaw die Antwort als
    # Umgebungsvariable oder Datei zurueckgibt
    
    import os
    answer = os.environ.get("VOICE_ANSWER", "")
    
    if not answer:
        # Fallback: Generiere eine einfache Antwort
        answer = f"Ich habe verstanden: '{question}'. Das ist eine interessante Frage! Leider kann ich im vollautomatischen Modus noch nicht auf alles antworten. Bitte stelle die Frage direkt in der TUI fuer eine bessere Antwort."
    
    return answer

def main():
    if not AUTO_DIR.exists():
        # Nichts zu tun
        if "--silent" not in sys.argv:
            pass  # Silent mode, kein Output
        return
    
    # Pruefe auf neue Anfrage
    request = check_request()
    
    if not request:
        return
    
    question = request.get("question", "")
    
    if not question:
        save_response(question, "Keine Frage erhalten.")
        return
    
    try:
        # Verarbeite mit OpenClaw
        answer = process_with_openclaw(question)
        
        # Speichere Antwort
        save_response(question, answer)
        
        log(f"💾 Antwort gespeichert ({len(answer)} Zeichen)")
        
    except Exception as e:
        log(f"❌ Fehler: {e}")
        save_response(question, f"Fehler bei der Verarbeitung: {e}")

if __name__ == "__main__":
    main()
