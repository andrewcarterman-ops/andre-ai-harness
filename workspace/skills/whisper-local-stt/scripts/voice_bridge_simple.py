#!/usr/bin/env python3
"""
Voice Bridge Simple - Halb-automatischer Voice Loop
Phase 1 Pragmatische Lösung

Workflow:
1. Voice Message (.ogg) wird erkannt
2. Automatische Transkription mit whisper.cpp
3. Text wird in inbox/new_messages.jsonl geschrieben
4. ANDREW sieht die Nachricht und antwortet
5. Antwort wird in outbox/responses/{id}.txt geschrieben
6. Automatische TTS-Generierung mit Piper
7. Voice-Note wird in ready_to_send/ bereitgestellt

Usage:
  python voice_bridge_simple.py              # Dauerhaft laufen lassen
  python voice_bridge_simple.py --status     # Zeigt aktuelle Nachrichten
"""

import os
import sys
import time
import json
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Optional
import shutil

# Pfade
MEDIA_DIR = Path.home() / ".openclaw" / "media" / "inbound"
INBOX_DIR = Path.home() / ".openclaw" / "voice" / "inbox"
OUTBOX_DIR = Path.home() / ".openclaw" / "voice" / "outbox"
RESPONSE_DIR = OUTBOX_DIR / "responses"
READY_DIR = Path.home() / ".openclaw" / "voice" / "ready_to_send"
LOG_FILE = Path.home() / ".openclaw" / "voice" / "bridge.log"

# Tools
WHISPER_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "transcribe.py"
PIPER_EXE = Path.home() / ".openclaw" / "piper" / "piper" / "piper.exe"
PIPER_MODEL = Path.home() / ".openclaw" / "piper" / "models" / "de_DE-thorsten-high.onnx"

# Einstellungen
POLL_INTERVAL = 2.0


class SimpleVoiceBridge:
    def __init__(self):
        self.processed = self._load_processed()
        self._ensure_dirs()
        
    def _ensure_dirs(self):
        """Stelle sicher, dass alle Verzeichnisse existieren"""
        for d in [INBOX_DIR, OUTBOX_DIR, RESPONSE_DIR, READY_DIR]:
            d.mkdir(parents=True, exist_ok=True)
    
    def _load_processed(self) -> set:
        """Lade bereits verarbeitete Dateien"""
        processed = set()
        log_file = INBOX_DIR / "processed.txt"
        if log_file.exists():
            with open(log_file, 'r') as f:
                processed = {line.strip() for line in f if line.strip()}
        return processed
    
    def _save_processed(self, filename: str):
        """Speichere verarbeitete Datei"""
        log_file = INBOX_DIR / "processed.txt"
        with open(log_file, 'a') as f:
            f.write(f"{filename}\n")
        self.processed.add(filename)
    
    def _log(self, message: str, level="INFO"):
        """Logge Nachricht"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_line = f"[{timestamp}] [{level}] {message}"
        print(log_line)
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(log_line + "\n")
    
    def _find_new_ogg(self) -> Optional[Path]:
        """Finde neue .ogg Dateien"""
        if not MEDIA_DIR.exists():
            return None
        
        ogg_files = [f for f in MEDIA_DIR.glob("*.ogg") if f.name not in self.processed]
        if not ogg_files:
            return None
        
        # Neueste zuerst
        ogg_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
        return ogg_files[0]
    
    def _transcribe(self, ogg_path: Path) -> Optional[str]:
        """Transkribiere mit whisper.cpp"""
        self._log(f"Transkribiere: {ogg_path.name}")
        
        try:
            result = subprocess.run(
                [sys.executable, str(WHISPER_SCRIPT), str(ogg_path)],
                capture_output=True,
                text=True,
                timeout=120  # whisper.cpp braucht Zeit fuer erstes Laden
            )
            
            if result.returncode == 0:
                # Extrahiere Text (letzte Zeile ohne stderr)
                lines = result.stdout.strip().split('\n')
                for line in reversed(lines):
                    line = line.strip()
                    if line and not line.startswith('Transkribiere'):
                        return line
            else:
                self._log(f"Transkription fehlgeschlagen: {result.stderr}", "ERROR")
                
        except Exception as e:
            self._log(f"Transkription Fehler: {e}", "ERROR")
        
        return None
    
    def _save_inbox(self, msg_id: str, filename: str, text: str):
        """Speichere Nachricht in Inbox"""
        inbox_file = INBOX_DIR / "new_messages.jsonl"
        
        entry = {
            "id": msg_id,
            "timestamp": datetime.now().isoformat(),
            "original_file": filename,
            "text": text,
            "status": "pending_response"
        }
        
        with open(inbox_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(entry) + "\n")
        
        self._log(f"Nachricht gespeichert in inbox: {msg_id}")
        print(f"\n{'='*60}")
        print(f"[NEUE NACHRICHT] ID: {msg_id}")
        print(f"[TEXT] {text}")
        print(f"{'='*60}")
        print(f"\nAntwort schreiben in:")
        print(f"  {RESPONSE_DIR / (msg_id + '.txt')}")
        print(f"{'='*60}\n")
    
    def _check_responses(self):
        """Prüfe auf neue Antworten und generiere TTS"""
        if not RESPONSE_DIR.exists():
            return
        
        for response_file in RESPONSE_DIR.glob("*.txt"):
            msg_id = response_file.stem
            
            try:
                with open(response_file, 'r', encoding='utf-8') as f:
                    response_text = f.read().strip()
                
                if not response_text:
                    continue
                
                self._log(f"Antwort gefunden für {msg_id}: {response_text[:50]}...")
                
                # Generiere TTS
                audio_path = self._generate_tts(msg_id, response_text)
                
                if audio_path:
                    # Verschiebe in ready_to_send
                    target = READY_DIR / f"{msg_id}_response.wav"
                    shutil.move(str(audio_path), str(target))
                    self._log(f"Voice-Note bereit: {target}")
                    
                    # Lösche Response-Datei
                    response_file.unlink()
                    
                    # Aktualisiere Inbox-Status
                    self._mark_responded(msg_id)
                    
                    print(f"\n{'='*60}")
                    print(f"[VOICE-NOTE BEREIT] {target}")
                    print(f"{'='*60}\n")
                
            except Exception as e:
                self._log(f"Fehler bei Antwort-Verarbeitung: {e}", "ERROR")
    
    def _generate_tts(self, msg_id: str, text: str) -> Optional[Path]:
        """Generiere TTS mit Piper"""
        self._log(f"Generiere TTS für {msg_id}")
        
        output_path = OUTBOX_DIR / f"{msg_id}.wav"
        
        try:
            result = subprocess.run(
                [str(PIPER_EXE), "--model", str(PIPER_MODEL), "--output_file", str(output_path)],
                input=text,
                capture_output=True,
                text=True,
                timeout=60  # Piper ist schneller
            )
            
            if result.returncode == 0 and output_path.exists():
                return output_path
            else:
                self._log(f"TTS fehlgeschlagen: {result.stderr}", "ERROR")
                
        except Exception as e:
            self._log(f"TTS Fehler: {e}", "ERROR")
        
        return None
    
    def _mark_responded(self, msg_id: str):
        """Markiere Nachricht als beantwortet"""
        inbox_file = INBOX_DIR / "new_messages.jsonl"
        if not inbox_file.exists():
            return
        
        # Lese alle Einträge
        entries = []
        with open(inbox_file, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    try:
                        entry = json.loads(line)
                        if entry.get("id") == msg_id:
                            entry["status"] = "completed"
                            entry["responded_at"] = datetime.now().isoformat()
                        entries.append(entry)
                    except:
                        pass
        
        # Schreibe zurück
        with open(inbox_file, 'w', encoding='utf-8') as f:
            for entry in entries:
                f.write(json.dumps(entry) + "\n")
    
    def show_status(self):
        """Zeige aktuellen Status"""
        print("\n" + "="*60)
        print("VOICE BRIDGE STATUS")
        print("="*60)
        
        # Neue Nachrichten
        inbox_file = INBOX_DIR / "new_messages.jsonl"
        if inbox_file.exists():
            pending = 0
            with open(inbox_file, 'r') as f:
                for line in f:
                    if line.strip():
                        try:
                            entry = json.loads(line)
                            if entry.get("status") == "pending_response":
                                pending += 1
                                print(f"\n[OFFEN] ID: {entry['id']}")
                                print(f"  Text: {entry['text'][:80]}...")
                                print(f"  Zeit: {entry['timestamp']}")
                        except:
                            pass
            
            if pending == 0:
                print("\nKeine offenen Nachrichten.")
        
        # Bereite Voice-Notes
        if READY_DIR.exists() and list(READY_DIR.glob("*.wav")):
            print(f"\n[BEREIT ZUM SENDEN]")
            for f in READY_DIR.glob("*.wav"):
                print(f"  - {f.name}")
        
        print("\n" + "="*60)
        print(f"Inbox:    {INBOX_DIR}")
        print(f"Antworten: {RESPONSE_DIR}")
        print(f"Bereit:   {READY_DIR}")
        print("="*60 + "\n")
    
    def run(self):
        """Hauptschleife"""
        print("\n" + "="*60)
        print("VOICE BRIDGE SIMPLE")
        print("Phase 1 - Halb-automatischer Loop")
        print("="*60)
        print(f"\nÜberwache: {MEDIA_DIR}")
        print(f"Inbox:     {INBOX_DIR}")
        print(f"Antworten: {RESPONSE_DIR}")
        print(f"\nDrücke Ctrl+C zum Beenden")
        print("="*60 + "\n")
        
        self._log("Voice Bridge gestartet")
        
        try:
            while True:
                # 1. Prüfe auf neue Voice Messages
                new_ogg = self._find_new_ogg()
                
                if new_ogg:
                    msg_id = f"msg_{int(time.time())}"
                    text = self._transcribe(new_ogg)
                    
                    if text:
                        self._save_inbox(msg_id, new_ogg.name, text)
                    
                    self._save_processed(new_ogg.name)
                
                # 2. Prüfe auf Antworten
                self._check_responses()
                
                time.sleep(POLL_INTERVAL)
                
        except KeyboardInterrupt:
            print("\n\nBeendet.")
            self._log("Voice Bridge beendet")


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--status", action="store_true", help="Zeige aktuellen Status")
    args = parser.parse_args()
    
    bridge = SimpleVoiceBridge()
    
    if args.status:
        bridge.show_status()
    else:
        bridge.run()


if __name__ == "__main__":
    main()
