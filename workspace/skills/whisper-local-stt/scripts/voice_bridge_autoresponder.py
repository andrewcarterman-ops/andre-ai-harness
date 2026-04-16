#!/usr/bin/env python3
"""
Voice Bridge Auto-Responder - Automatische Antworten

STARTEN in separatem Terminal:
    python voice_bridge_autoresponder.py
"""

import sys
import time
import json
from pathlib import Path
from datetime import datetime

BRIDGE_DIR = Path.home() / ".openclaw" / "voice_bridge"
REQUESTS_DIR = BRIDGE_DIR / "requests"
RESPONSES_DIR = BRIDGE_DIR / "responses"

def log(msg):
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}")

def find_pending():
    if not REQUESTS_DIR.exists():
        return []
    pending = []
    for f in REQUESTS_DIR.glob("*.json"):
        try:
            with open(f, 'r', encoding='utf-8') as fp:
                data = json.load(fp)
            if data.get("status") == "pending":
                pending.append((f, data))
        except:
            pass
    return pending

def andrew_antwort(text):
    t = text.lower()
    if "hallo" in t or "hi" in t or "moin" in t:
        if "wie geht" in t:
            return "Hallo! Mir geht's gut, ich bin ja ein Computer. Was kann ich fuer dich tun?"
        return "Hallo! Was kann ich fuer dich tun?"
    if "uhrzeit" in t or "wie spaet" in t:
        return f"Es ist {datetime.now().strftime('%H:%M')}. Zeit fuer Kaffee?"
    if "projekt" in t or "was machen wir" in t:
        return "Wir haben 12 aktive Projekte. Soll ich den Status zeigen?"
    if "code" in t or "python" in t or "programm" in t:
        return "Ah, Code! Meine Muttersprache. Was schreibst du gerade?"
    if "sinn" in t or "glueck" in t or "unglueck" in t:
        return "Grosse Fragen! Sinn entsteht durch Tun. Was denkst du?"
    return f"Verstanden: '{text}'. Was moechtest du damit tun?"

def process(file_path, data):
    req_id = data.get("id", "unknown")
    text = data.get("text", "")
    
    print(f"\n{'='*50}")
    log(f"NEUER REQUEST: {req_id}")
    log(f"TEXT: {text[:50]}..." if len(text) > 50 else f"TEXT: {text}")
    
    antwort = andrew_antwort(text)
    
    response_file = RESPONSES_DIR / f"{req_id}.json"
    RESPONSES_DIR.mkdir(parents=True, exist_ok=True)
    
    with open(response_file, 'w', encoding='utf-8') as f:
        json.dump({"id": req_id, "timestamp": data.get("timestamp"), "request_text": text, "response": antwort, "response_timestamp": time.time()}, f, indent=2, ensure_ascii=False)
    
    data["status"] = "completed"
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    
    log(f"ANTWORT: {antwort[:50]}..." if len(antwort) > 50 else f"ANTWORT: {antwort}")
    print(f"{'='*50}\n")

def main():
    print("="*50)
    print("VOICE BRIDGE AUTO-RESPONDER")
    print("="*50)
    print("\nStarte die Voice Bridge und sprich los!")
    print("Druecke Ctrl+C zum Beenden\n")
    
    for d in [BRIDGE_DIR, REQUESTS_DIR, RESPONSES_DIR]:
        d.mkdir(parents=True, exist_ok=True)
    
    try:
        while True:
            for file_path, data in find_pending():
                process(file_path, data)
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n[Beendet!]")

if __name__ == "__main__":
    main()
