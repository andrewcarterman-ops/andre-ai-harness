#!/usr/bin/env python3
"""
Voice Bridge Responder - Für Andrew/LLM

Dieses Script läuft im Hintergrund und:
1. Prüft auf neue Voice Requests in ~/.openclaw/voice_bridge/requests/
2. Zeigt sie an (oder sendet an LLM)
3. Schreibt die Antwort zurück nach responses/

Usage:
    python voice_bridge_responder.py [--auto]
    
Ohne --auto: Zeigt Request an, wartet auf manuelle Antwort
Mit --auto: Nutzt OpenClaw CLI um Antwort zu generieren
"""

import sys
import time
import json
import subprocess
import argparse
from pathlib import Path

# Verzeichnisse
BRIDGE_DIR = Path.home() / ".openclaw" / "voice_bridge"
REQUESTS_DIR = BRIDGE_DIR / "requests"
RESPONSES_DIR = BRIDGE_DIR / "responses"

def setup_dirs():
    """Erstelle Verzeichnisse"""
    for d in [BRIDGE_DIR, REQUESTS_DIR, RESPONSES_DIR]:
        d.mkdir(parents=True, exist_ok=True)

def find_pending_requests():
    """Finde alle pending Requests"""
    if not REQUESTS_DIR.exists():
        return []
    
    requests = []
    for f in REQUESTS_DIR.glob("*.json"):
        try:
            with open(f, 'r', encoding='utf-8') as fp:
                data = json.load(fp)
            if data.get("status") == "pending":
                requests.append((f, data))
        except:
            pass
    
    # Sortiere nach Zeitstempel
    requests.sort(key=lambda x: x[1].get("timestamp", ""))
    return requests

def get_llm_response(text):
    """
    Hole Antwort vom LLM via OpenClaw CLI.
    Dies funktioniert nur, wenn das Script in einer OpenClaw-Umgebung läuft.
    """
    try:
        result = subprocess.run(
            ["openclaw", "ask", text, "--timeout", "30"],
            capture_output=True,
            text=True,
            timeout=35
        )
        
        if result.returncode == 0:
            return result.stdout.strip()
        else:
            return None
    except:
        return None

def process_request(request_file, request_data, auto_mode=False):
    """Verarbeite einen Request"""
    request_id = request_data.get("id", "unknown")
    text = request_data.get("text", "")
    
    print("\n" + "="*60)
    print(f"🎙️  NEUE VOICE REQUEST: {request_id}")
    print("="*60)
    print(f"\n📝 Text: {text}")
    print("-"*60)
    
    if auto_mode:
        # Automatisch via LLM
        print("\n🤖 Frage LLM...")
        response = get_llm_response(text)
        
        if not response:
            print("⚠️  Keine LLM-Antwort erhalten")
            response = "Entschuldigung, ich konnte keine Antwort generieren."
    else:
        # Manuell - warte auf Eingabe
        print("\n✏️  Gib deine Antwort ein (Enter für leere Antwort):")
        try:
            response = input("> ")
        except EOFError:
            return False
    
    if not response:
        print("⚠️  Leere Antwort, überspringe...")
        return False
    
    # Schreibe Response
    response_data = {
        "id": request_id,
        "timestamp": request_data.get("timestamp"),
        "request_text": text,
        "response": response,
        "response_timestamp": time.time()
    }
    
    response_file = RESPONSES_DIR / f"{request_id}.json"
    with open(response_file, 'w', encoding='utf-8') as f:
        json.dump(response_data, f, indent=2)
    
    # Markiere Request als erledigt
    request_data["status"] = "completed"
    with open(request_file, 'w', encoding='utf-8') as f:
        json.dump(request_data, f, indent=2)
    
    print(f"\n✅ Antwort geschrieben: {response_file}")
    print(f"💬 Antwort: {response[:80]}..." if len(response) > 80 else f"💬 Antwort: {response}")
    
    return True

def main():
    parser = argparse.ArgumentParser(description="Voice Bridge Responder")
    parser.add_argument("--auto", action="store_true", help="Automatischer Modus (LLM)")
    parser.add_argument("--once", action="store_true", help="Nur einen Request verarbeiten")
    args = parser.parse_args()
    
    setup_dirs()
    
    print("="*60)
    print("🎙️  VOICE BRIDGE RESPONDER")
    print("="*60)
    print(f"\n📁 Requests: {REQUESTS_DIR}")
    print(f"📁 Responses: {RESPONSES_DIR}")
    
    if args.auto:
        print("\n🤖 Modus: AUTOMATISCH (LLM)")
    else:
        print("\n✏️  Modus: MANUELL (du schreibst die Antwort)")
    
    print("\n[Drücke Ctrl+C zum Beenden]")
    print("="*60)
    
    try:
        while True:
            requests = find_pending_requests()
            
            if requests:
                for request_file, request_data in requests:
                    process_request(request_file, request_data, args.auto)
                    
                    if args.once:
                        print("\n👋 Einmal-Modus beendet.")
                        return
            else:
                # Zeige nur alle 5 Sekunden "Warte..."
                pass
            
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n\n👋 Beendet.")

if __name__ == "__main__":
    main()
