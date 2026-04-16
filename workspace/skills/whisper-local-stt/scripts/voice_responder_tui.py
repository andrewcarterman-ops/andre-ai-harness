#!/usr/bin/env python3
"""
Voice Response Helper - Fuer OpenClaw TUI
=========================================
Dieses Script LAUFT IN DER OPENCAAW TUI!
Es liest Voice-Anfragen und schreibt die Antwort zurueck.

AUFRUF in OpenClaw:
    python skills/whisper-local-stt/scripts/voice_responder_tui.py

ODER einfacher - du siehst die Frage in request.json und
antwortest direkt hier in der TUI mit:
    python skills/whisper-local-stt/scripts/quick_answer.py "DEINE ANTWORT"
"""

import sys
import json
from pathlib import Path

COMM_DIR = Path.home() / ".openclaw" / "voice_comm"
REQUEST_FILE = COMM_DIR / "request.json"
RESPONSE_FILE = COMM_DIR / "response.json"

def main():
    if not REQUEST_FILE.exists():
        print("Keine Voice-Anfrage vorhanden.")
        print(f"Pruefe: {REQUEST_FILE}")
        return
    
    # Lese Frage
    try:
        with open(REQUEST_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        question = data.get("question", "")
        
        print("\n" + "="*70)
        print("🎙️  VOICE ANFRAGE ERHALTEN")
        print("="*70)
        print(f"\nFrage: {question}")
        print("\n" + "="*70)
        
        # Option 1: Automatisch antworten (wenn du willst)
        # Hier wuerde OpenClaw normalerweise antworten
        # Aber fuer jetzt: Wir schreiben eine einfache Antwort
        
        print("\nGib deine Antwort ein (dann Enter):")
        answer = input("> ")
        
        if answer:
            # Speichere Antwort
            response_data = {
                "timestamp": data.get("timestamp"),
                "question": question,
                "answer": answer,
                "source": "openclaw-tui"
            }
            
            with open(RESPONSE_FILE, 'w', encoding='utf-8') as f:
                json.dump(response_data, f, indent=2)
            
            # Loesche Request
            REQUEST_FILE.unlink()
            
            print(f"\n✅ Antwort gespeichert!")
            print(f"   Client wird die Antwort in Kuerze als TTS abspielen.")
        else:
            print("Keine Antwort eingegeben.")
            
    except Exception as e:
        print(f"Fehler: {e}")

if __name__ == "__main__":
    main()
