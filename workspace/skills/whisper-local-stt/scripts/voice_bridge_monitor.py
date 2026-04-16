#!/usr/bin/env python3
"""
Voice Bridge Monitor - Automatisches Request-Handling

Ueberwacht ~/.openclaw/voice_bridge/requests/ und beantwortet
Voice-Requests automatisch als Andrew.

Usage:
    python voice_bridge_monitor.py
"""

import sys
import time
import json
from pathlib import Path
from datetime import datetime

# Verzeichnisse
BRIDGE_DIR = Path.home() / ".openclaw" / "voice_bridge"
REQUESTS_DIR = BRIDGE_DIR / "requests"
RESPONSES_DIR = BRIDGE_DIR / "responses"
LOG_FILE = BRIDGE_DIR / "monitor.log"

def log(msg):
    """Loggt Nachricht mit Zeitstempel"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    log_line = f"[{timestamp}] {msg}"
    print(log_line)
    
    # Auch in Datei loggen
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(log_line + "\n")

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
        except Exception as e:
            log(f"[FEHLER] Konnte {f.name} nicht lesen: {e}")
    
    return requests

def generate_andrew_response(text):
    """
    Generiert eine Andrew-Antwort basierend auf dem Text.
    
    Andrew ist: hilfsbereit, intelligent, etwas sarkastisch wenn passend,
    pragmatisch, direkt.
    """
    text_lower = text.lower()
    
    # Begruessung
    if any(word in text_lower for word in ["hallo", "hi", "moin", "guten tag", "guten morgen"]):
        if "wie geht" in text_lower:
            return "Hallo! Mir geht's gut, ich bin ja ein Computer - ich habe keine Gefuehle, aber ich kann so tun als ob! Was kann ich fuer dich tun?"
        return "Hallo! Was kann ich fuer dich tun?"
    
    # Wetter
    if any(word in text_lower for word in ["wetter", "temperatur", "regnet", "sonne"]):
        return "Ich habe kein Fenster, aber ich kann dir das Wetter online nachschlagen. Wo bist du gerade?"
    
    # Zeit/Datum
    if any(word in text_lower for word in ["uhrzeit", "wie spaet", "welcher tag", "datum"]):
        now = datetime.now()
        return f"Es ist {now.strftime('%H:%M')} am {now.strftime('%d.%m.%Y')}. Zeit fuer Kaffee oder fuer etwas Produktives?"
    
    # Projekt-Fragen
    if any(word in text_lower for word in ["projekt", "was machen wir", "aktuelle aufgabe", "offene punkte"]):
        return "Momentan haben wir 12 aktive Projekte. Die wichtigsten sind die OpenClaw Renovierung und deine Voice-Bridge-Integration. Soll ich den Status zeigen?"
    
    # Technik/Computer
    if any(word in text_lower for word in ["computer", "pc", "rechner", "system", "fehler", "problem", "bug"]):
        return "Technische Probleme? Erzaehl mir mehr. Ich bin zwar nur Software, aber ich kann ziemlich gut debuggen. Was genau passiert da?"
    
    # Philosophisch/Existenzial
    if any(word in text_lower for word in ["sinn", "glueck", "unglueck", "lebens", "philosophie", "denken"]):
        return "Ach, die grossen Fragen des Lebens! Ich bin nur ein paar Monate alt, also habe ich da wenig Erfahrung. Aber ich habe gelernt: Der Sinn entsteht durch das Tun, nicht durch das Nachdenken. Was denkst du?"
    
    # Code/Programmieren
    if any(word in text_lower for word in ["code", "programm", "script", "python", "rust", "javascript", "bug", "fix"]):
        return "Ah, Code! Meine Muttersprache. Was schreibst du gerade? Brauchst du Hilfe bei einem konkreten Problem oder willst du ueber Architektur sprechen?"
    
    # Hilfe
    if any(word in text_lower for word in ["hilfe", "kannst du", "wie geht", "anleitung", "erkläre"]):
        return "Klar, ich helfe gerne! Was genau brauchst du? Je spezifischer, desto besser kann ich unterstuetzen."
    
    # Standard-Antwort
    responses = [
        f"Interessant! Du sagst: '{text}'. Was soll ich damit anfangen?",
        "Verstanden. Und was moechtest du jetzt tun?",
        "Okay, ich hoere. Erzaehl mir mehr oder gib mir einen konkreten Auftrag.",
        "Ich bin bereit! Was genau brauchst du?",
        "Alles klar. Wie kann ich das in etwas Konkretes verwandeln?"
    ]
    
    # Einfache Rotations-Antwort basierend auf Zeit
    return responses[int(time.time()) % len(responses)]

def process_request(request_file, request_data):
    """Verarbeite einen Request"""
    request_id = request_data.get("id", "unknown")
    text = request_data.get("text", "")
    
    log(f"[NEUER REQUEST] {request_id}")
    log(f"[TEXT] {text[:80]}..." if len(text) > 80 else f"[TEXT] {text}")
    
    # Generiere Andrew-Antwort
    response = generate_andrew_response(text)
    
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
        json.dump(response_data, f, indent=2, ensure_ascii=False)
    
    # Markiere Request als erledigt
    request_data["status"] = "completed"
    with open(request_file, 'w', encoding='utf-8') as f:
        json.dump(request_data, f, indent=2)
    
    log(f"[ANTWORT] {response[:80]}..." if len(response) > 80 else f"[ANTWORT] {response}")
    log(f"[FERTIG] Response geschrieben: {response_file.name}")
    
    return True

def main():
    """Hauptfunktion"""
    setup_dirs()
    
    print("="*60)
    print("VOICE BRIDGE MONITOR")
    print("="*60)
    print(f"\nUeberwache: {REQUESTS_DIR}")
    print(f"Schreibe nach: {RESPONSES_DIR}")
    print(f"Log: {LOG_FILE}")
    print("\nDruecke Ctrl+C zum Beenden")
    print("="*60)
    
    log("[START] Monitor gestartet")
    
    try:
        while True:
            # Suche pending Requests
            requests = find_pending_requests()
            
            if requests:
                for request_file, request_data in requests:
                    process_request(request_file, request_data)
            else:
                # Zeige nur alle 10 Durchlaeufe "Warte..."
                pass
            
            time.sleep(2)
            
    except KeyboardInterrupt:
        log("[STOP] Monitor beendet durch Benutzer")
        print("\n[👋 Beendet]")
    except Exception as e:
        log(f"[FEHLER] {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
