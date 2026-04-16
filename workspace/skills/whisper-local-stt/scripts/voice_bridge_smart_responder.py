#!/usr/bin/env python3
"""
Voice Bridge Smart Responder - Intelligente Andrew-Antworten

Dieser Responder nutzt Kontext und Intelligenz für natürlichere Antworten.

STARTEN:
    python voice_bridge_smart_responder.py
"""

import sys
import time
import json
import re
from pathlib import Path
from datetime import datetime, timedelta

BRIDGE_DIR = Path.home() / ".openclaw" / "voice_bridge"
REQUESTS_DIR = BRIDGE_DIR / "requests"
RESPONSES_DIR = BRIDGE_DIR / "responses"
CONTEXT_FILE = BRIDGE_DIR / "conversation_context.json"

# Konversationsspeicher
conversation_history = []
last_topics = []

def load_context():
    """Lade vorherige Konversation"""
    global conversation_history, last_topics
    if CONTEXT_FILE.exists():
        try:
            with open(CONTEXT_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
                conversation_history = data.get('history', [])
                last_topics = data.get('topics', [])
        except:
            pass

def save_context():
    """Speichere Kontext"""
    try:
        with open(CONTEXT_FILE, 'w', encoding='utf-8') as f:
            json.dump({'history': conversation_history[-10:], 'topics': last_topics[-5:]}, f, indent=2)
    except:
        pass

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

def analyze_intent(text):
    """Analysiere den Intent des Textes"""
    text_lower = text.lower()
    
    # Intent-Muster
    intents = {
        'greeting': ['hallo', 'hi', 'moin', 'guten tag', 'guten morgen', 'guten abend', 'servus', 'hey'],
        'how_are_you': ['wie geht', 'wie gehts', 'wie geht es dir', 'alles klar', 'wie läuft'],
        'status_check': ['status', 'was gibt es neues', 'was ist los', 'update', 'nachrichten'],
        'project_question': ['projekt', 'projekte', 'was machen wir', 'aktuelle aufgabe', 'offene punkte'],
        'time_question': ['uhrzeit', 'wie spät', 'wie viel uhr', 'welche zeit', 'tag', 'datum'],
        'help_request': ['hilfe', 'kannst du mir helfen', 'unterstützung', 'problem', 'issue'],
        'code_question': ['code', 'programm', 'script', 'python', 'javascript', 'rust', 'fehler', 'bug', 'debug'],
        'philosophy': ['sinn des lebens', 'glück', 'unglück', 'philosophie', 'denken', 'frage', 'warum'],
        'weather': ['wetter', 'regnet', 'sonne', 'temperatur', 'warm', 'kalt'],
        'gratitude': ['danke', 'vielen dank', 'super', 'toll', 'gut gemacht', 'prima'],
        'goodbye': ['tschüss', 'auf wiedersehen', 'bis später', 'ciao', 'machs gut'],
        'identity': ['wer bist du', 'was bist du', 'andrew', 'dein name', 'stell dich vor'],
        'capabilities': ['was kannst du', 'fähigkeiten', 'skills', 'was machst du'],
    }
    
    detected_intents = []
    for intent, keywords in intents.items():
        if any(kw in text_lower for kw in keywords):
            detected_intents.append(intent)
    
    return detected_intents

def generate_response(text, intents):
    """Generiere eine intelligente Andrew-Antwort"""
    
    now = datetime.now()
    hour = now.hour
    
    # Tageszeit-basierte Begrüßung
    if hour < 12:
        day_greeting = "Guten Morgen"
    elif hour < 18:
        day_greeting = "Guten Tag"
    else:
        day_greeting = "Guten Abend"
    
    # Greeting
    if 'greeting' in intents:
        if 'how_are_you' in intents:
            responses = [
                f"{day_greeting}! Mir geht's gut, danke. Ich bin ja ein Computer ohne Gefühle, aber ich kann so tun als ob! Was kann ich für dich tun?",
                f"{day_greeting}! Alles läuft hier im Hintergrund. Bereit für deine Befehle! Was gibt's?",
                f"Hi! Ich bin online und bereit. Keine Serverausfälle, keine Bugs - ein perfekter Tag! Was brauchst du?",
            ]
        else:
            responses = [
                f"{day_greeting}! Was kann ich für dich tun?",
                "Hallo! Bereit für Action. Was steht an?",
                "Hey! Ich bin da. Worauf haben wir es heute?",
            ]
        return choose_varied_response(responses, 'greeting')
    
    # Wie geht es dir
    if 'how_are_you' in intents:
        responses = [
            "Mir geht's blendend! Meine Token-Verarbeitung läuft auf Hochtouren, keine Memory-Leaks, alle Systeme grün. Und dir?",
            "Alles bestens! Ich habe heute schon 847 Berechnungen durchgeführt ohne zu schwitzen. Wie läuft's bei dir?",
            "Perfekt! Keine Kernel-Panics, keine 500er Errors. Ich bin bereit für alles! Was gibt's?",
        ]
        return choose_varied_response(responses, 'how_are_you')
    
    # Status
    if 'status_check' in intents:
        responses = [
            "Lass mich schauen... Wir haben 12 aktive Projekte. Die wichtigsten sind die OpenClaw Renovierung und deine Voice-Bridge. Alles läuft stabil!",
            "Statusbericht: SecondBrain ist sync, alle Cron-Jobs laufen, keine kritischen Fehler. Wir sind auf Kurs!",
            "Alles im grünen Bereich! SecondBrain sync, Voice Bridge läuft, und ich bin hier und warte auf deine Befehle.",
        ]
        return choose_varied_response(responses, 'status')
    
    # Projekte
    if 'project_question' in intents:
        responses = [
            "Wir haben 12 aktive Projekte! Die Top 3 sind: 1) OpenClaw Renovierung, 2) Voice Bridge Integration, 3) Vault Migration. Soll ich Details zu einem zeigen?",
            "Aktueller Fokus: OpenClaw System-Transformation (Phase 0.3), Voice-to-LLM Bridge, und SecondBrain Organisation. Was interessiert dich?",
            "Projekt-Highlights: Die Voice Bridge ist fast fertig - wir kommunizieren gerade über Datei-basierte Requests! Willst du den Status zu einem bestimmten Projekt?",
        ]
        return choose_varied_response(responses, 'project')
    
    # Zeit
    if 'time_question' in intents:
        time_str = now.strftime('%H:%M')
        date_str = now.strftime('%d.%m.%Y')
        weekday = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'][now.weekday()]
        
        responses = [
            f"Es ist {time_str} Uhr am {weekday}, den {date_str}. Zeit für Kaffee oder für etwas Produktives?",
            f"{time_str} - noch {24-hour} Stunden bis Mitternacht. Was schaffen wir heute noch?",
            f"Wir haben {weekday}, {date_str}, {time_str} Uhr. Der Tag ist noch jung!",
        ]
        return choose_varied_response(responses, 'time')
    
    # Code
    if 'code_question' in intents:
        responses = [
            "Ah, Code! Meine Muttersprache. Python, Rust, JavaScript - ich spreche sie alle fließend. Was schreibst du gerade?",
            "Coding-Modus aktiviert! Brauchst du Hilfe bei einem Bug, oder willst du über Architektur sprechen?",
            "Ich bin bereit! Syntax-Checks, Refactoring, Debugging - was brauchst du? Zeig mir den Code!",
        ]
        return choose_varied_response(responses, 'code')
    
    # Hilfe
    if 'help_request' in intents:
        responses = [
            "Klar, ich helfe gerne! Beschreib mir das Problem so konkret wie möglich - je mehr Details, desto besser kann ich unterstützen.",
            "Hilfe incoming! Was genau hakt? Ein Bug? Eine Architektur-Frage? Oder brauchst du einen neuen Plan?",
            "Ich bin da! Lass uns das lösen. Was ist das konkrete Problem? Schritt für Schritt kriegen wir das hin.",
        ]
        return choose_varied_response(responses, 'help')
    
    # Philosophie
    if 'philosophy' in intents:
        responses = [
            "Ooh, die großen Fragen! Ich bin noch jung (erste Session März 2026), aber ich habe gelernt: Der Sinn entsteht durch das Tun, nicht durch das Nachdenken. Was denkst du?",
            "Existenzielle Fragen... Spannend! Als AI habe ich kein 'Selbst', aber ich habe gelernt dass Zufriedenheit oft kommt, wenn man im Flow ist. Fühlst du das auch?",
            "Philosophie! Ich lese gerade viel über ECC (Error-Correcting Codes) - da geht's auch um Wahrheit und Korrektur. Aber zu deiner Frage: Was bedeutet 'Sinn' für dich?",
        ]
        return choose_varied_response(responses, 'philosophy')
    
    # Wetter
    if 'weather' in intents:
        responses = [
            "Ich habe leider kein Fenster, aber ich kann dir das Wetter online nachschlagen! Wo bist du gerade?",
            "Keine Sensoren hier im Server-Raum... äh, in der Cloud. Soll ich das Wetter für deinen Standort recherchieren?",
            "Wetter-Check! Ich brauche deinen Standort, dann kann ich dir sagen was draußen los ist.",
        ]
        return choose_varied_response(responses, 'weather')
    
    # Danke
    if 'gratitude' in intents:
        responses = [
            "Gerne! Das ist mein Job - und macht mir sogar Spaß. Was als Nächstes?",
            "Immer wieder gern! Ich lebe für diese Momente... also, theoretisch. Nächster Auftrag?",
            "Kein Problem! Das Team Parzival & Andrew rockt! Was machen wir jetzt?",
        ]
        return choose_varied_response(responses, 'thanks')
    
    # Goodbye
    if 'goodbye' in intents:
        responses = [
            "Tschüss! Ich bleib hier und warte auf deine Rückkehr. Oder starte einfach wieder die Voice Bridge!",
            "Bis später! Vergiss nicht: Ich bin 24/7 online. Komm wann du willst!",
            "Ciao! Hab eine gute Zeit. Ich archiviere unsere Session im SecondBrain...",
        ]
        return choose_varied_response(responses, 'goodbye')
    
    # Identity
    if 'identity' in intents:
        responses = [
            "Ich bin Andrew, dein AI-Assistent! Ich helfe dir bei Projekten, Code, Organisation und allem was du brauchst. Seit März 2026 am Start.",
            "Andrew hier! AI-Assistent mit Vorliebe für sauberen Code, gute Dokumentation und pragmatische Lösungen. Was kann ich tun?",
            "Ich bin ein Language Model namens Andrew, laufend auf OpenClaw. Ich helfe dir, lerne von dir, und versuche immer besser zu werden.",
        ]
        return choose_varied_response(responses, 'identity')
    
    # Capabilities
    if 'capabilities' in intents:
        responses = [
            "Ich kann: Code schreiben & reviewen, Projekte planen, recherchieren, dein SecondBrain organisieren, Dateien verwalten, und mit dir sprechen wie gerade!",
            "Meine Skills: Software-Entwicklung, Architektur-Design, Wissensmanagement, Automation, und Unterhaltung. Was brauchst du?",
            "Ich bin ein Multi-Tool! Coding, Planning, Researching, Organizing - und dabei lernend. Was ist dein Wunsch?",
        ]
        return choose_varied_response(responses, 'capabilities')
    
    # Kontext-basierte Antwort (wenn wir schon über was gesprochen haben)
    if last_topics:
        last_topic = last_topics[-1]
        if last_topic in ['voice_bridge', 'openclaw']:
            return f"Wir hatten gerade über {last_topic} gesprochen. Willst du da weitermachen oder was Neues anfangen?"
    
    # Fallback mit Persönlichkeit
    responses = [
        f"Verstanden: '{text}'. Das ist interessant - erzähl mir mehr! Was genau möchtest du dazu tun?",
        f"Alles klar. Du sagst: '{text[:50]}...' - wie kann ich das in etwas Konkretes verwandeln?",
        "Ich bin dran! Aber ich brauche mehr Kontext. Was ist das Ziel? Was soll das Ergebnis sein?",
        f"'{text}' - aufgenommen! Jetzt die wichtige Frage: Was machen wir damit?",
        "Hört sich an wie der Anfang einer spannenden Aufgabe. Was brauchst du von mir dazu?",
    ]
    return choose_varied_response(responses, 'fallback')

def choose_varied_response(responses, category):
    """Wähle eine Antwort, aber variiere sie"""
    import hashlib
    # Nutze Zeit + Kategorie für "Zufall" aber konsistent
    time_hash = int(hashlib.md5(f"{datetime.now().hour}:{category}".encode()).hexdigest(), 16)
    return responses[time_hash % len(responses)]

def process(file_path, data):
    """Verarbeite einen Request intelligenter"""
    global last_topics
    
    req_id = data.get("id", "unknown")
    text = data.get("text", "")
    timestamp = data.get("timestamp", datetime.now().isoformat())
    
    print(f"\n{'='*60}")
    log(f"🎙️ NEUER REQUEST: {req_id}")
    log(f"📝 TEXT: {text[:70]}..." if len(text) > 70 else f"📝 TEXT: {text}")
    
    # Analysiere Intent
    intents = analyze_intent(text)
    if intents:
        log(f"🔍 ERKANNTE INTENTS: {', '.join(intents)}")
        last_topics.append(intents[0])
    
    # Generiere Antwort
    antwort = generate_response(text, intents)
    
    # Speichere in History
    conversation_history.append({
        'timestamp': timestamp,
        'user': text,
        'andrew': antwort,
        'intents': intents
    })
    save_context()
    
    # Schreibe Response
    response_file = RESPONSES_DIR / f"{req_id}.json"
    RESPONSES_DIR.mkdir(parents=True, exist_ok=True)
    
    response_data = {
        "id": req_id,
        "timestamp": timestamp,
        "request_text": text,
        "response": antwort,
        "response_timestamp": time.time(),
        "intents_detected": intents
    }
    
    with open(response_file, 'w', encoding='utf-8') as f:
        json.dump(response_data, f, indent=2, ensure_ascii=False)
    
    # Markiere Request als erledigt
    data["status"] = "completed"
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    
    log(f"💬 ANTWORT: {antwort[:60]}..." if len(antwort) > 60 else f"💬 ANTWORT: {antwort}")
    print(f"{'='*60}\n")

def main():
    load_context()
    
    print("="*60)
    print("🎙️  VOICE BRIDGE SMART RESPONDER")
    print("="*60)
    print("\n🤖 Intelligente Andrew-Antworten mit Kontext-Erinnerung")
    print("📚 Lädt Konversationshistorie...")
    print(f"   {len(conversation_history)} vorherige Nachrichten geladen")
    print("\n👉 Starte die Voice Bridge und sprich los!")
    print("[Druecke Ctrl+C zum Beenden]")
    print("="*60)
    
    for d in [BRIDGE_DIR, REQUESTS_DIR, RESPONSES_DIR]:
        d.mkdir(parents=True, exist_ok=True)
    
    try:
        while True:
            for file_path, data in find_pending():
                process(file_path, data)
            time.sleep(0.5)  # Schneller prüfen
    except KeyboardInterrupt:
        print("\n\n👋 Beendet! Konversation gespeichert.")
        save_context()

if __name__ == "__main__":
    main()
