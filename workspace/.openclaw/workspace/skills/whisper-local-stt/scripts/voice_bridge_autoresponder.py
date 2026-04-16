#!/usr/bin/env python3
"""
Voice Bridge Auto-Responder

STARTEN:
    python voice_bridge_autoresponder.py

Ueberwacht Requests und antwortet automatisch.
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
    text_lower = text.lower()
    
    if "hallo" in text_lower or "hi" in text_lower:
        if "wie geht" in text_lower:
            return "Hallo! Mir geht's gut, ich bin ja ein Computer. Was kann ich fuer dich tun?"
        return "Hallo! Was kann ich fuer dich tun?"
    
    if "uhrzeit" in text_lower or "wie spaet" in text_lower:
        now = datetime.now()
        return f"Es ist {now.strftime('%H:%M')}. Zeit fuer Kaffee?"
    
    if "projekt" in text_lower:
        return "Wir haben 12 aktive Projekte. Soll ich den Status zeigen?"
    
    if "code" in text_lower or "python" in text_lower:
        return "Ah, Code! Meine Muttersprache. Was schreibst du gerade?"
    
    if "sinn" in text_lower or "glueck" in text_lower:
        return "Grosse Fragen! Sinn entsteht durch Tun. Was denkst du?"
    
    return f"Verstanden: '{text}'. Was moechtest du damit tun?"

def process(file_path, data):
    req_id = data.get("id", "unknown")
    text = data.get("text", "")
    
    print(f"\n{'='*50}")
    log(f"NEUER REQUEST: {req_id}")
    log(f"TEXT: {text[:60]}..." if len(text) > 60 else f"TEXT: {text}")
    
    antwort = andrew_antwort(text)
    
    response_data = {
        "id": req_id,
        "timestamp": data.get("timestamp"),
        "request_text": text,
        "response": antwort,
        "response_timestamp": time.time()
    }
    
    response_file = RESPONSES_DIR / f"{req_id}.json"
    with open(response_file, 'w', encoding='utf-8') as f:
        json.dump(response_data, f, indent=2, ensure_ascii=False)
    
    data["status"] = "completed"
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    
    log(f"ANTWORT: {antwort[:60]}..." if len(antwort) > 60 else f"ANTWORT: {antwort}")
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
        print("\n[Beendet. Bis bald!]")

if __name__ == "__main__":
    main()
