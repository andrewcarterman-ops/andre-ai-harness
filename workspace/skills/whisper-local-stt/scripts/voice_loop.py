#!/usr/bin/env python3
"""
Voice Loop - Automatischer Telegram Voice-Message Handler
Phase 1 MVP: Voice Message -> Transkription -> Session -> Antwort -> TTS -> Voice-Note

Ablauf:
1. Pollt ~/.openclaw/media/inbound/ auf neue .ogg Dateien
2. Transkribiert mit whisper.cpp
3. Injiziert Text in OpenClaw Session
4. Wartet auf Antwort (via Datei-Polling)
5. Generiert TTS mit Piper
6. Sendet Voice-Note zurück an Telegram
"""

import os
import sys
import time
import json
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Optional

# Konfiguration
MEDIA_DIR = Path.home() / ".openclaw" / "media" / "inbound"
PROCESSED_LOG = Path.home() / ".openclaw" / "voice" / "processed.jsonl"
OUTBOX_DIR = Path.home() / ".openclaw" / "voice" / "outbox"
RESPONSE_POLL_DIR = Path.home() / ".openclaw" / "voice" / "responses"

# Pfade zu unseren Tools
WHISPER_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "transcribe.py"
PIPER_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "piper_tts.py"

# Polling-Einstellungen
POLL_INTERVAL = 2.0  # Sekunden
RESPONSE_TIMEOUT = 300  # Sekunden (5 Minuten)


class VoiceLoop:
    def __init__(self):
        self.processed_files = self._load_processed()
        self.running = False
        
        # Verzeichnisse erstellen
        OUTBOX_DIR.mkdir(parents=True, exist_ok=True)
        RESPONSE_POLL_DIR.mkdir(parents=True, exist_ok=True)
        PROCESSED_LOG.parent.mkdir(parents=True, exist_ok=True)
        
    def _load_processed(self) -> set:
        """Lade Liste bereits verarbeiteter Dateien"""
        processed = set()
        if PROCESSED_LOG.exists():
            with open(PROCESSED_LOG, 'r', encoding='utf-8') as f:
                for line in f:
                    try:
                        data = json.loads(line.strip())
                        processed.add(data.get('filename'))
                    except:
                        pass
        return processed
    
    def _log_processed(self, filename: str, text: str, success: bool):
        """Logge verarbeitete Datei"""
        entry = {
            "timestamp": datetime.now().isoformat(),
            "filename": filename,
            "text_preview": text[:100] if text else "",
            "success": success
        }
        with open(PROCESSED_LOG, 'a', encoding='utf-8') as f:
            f.write(json.dumps(entry) + "\n")
    
    def _find_new_ogg_files(self) -> list[Path]:
        """Finde neue .ogg Dateien, die noch nicht verarbeitet wurden"""
        if not MEDIA_DIR.exists():
            return []
        
        ogg_files = list(MEDIA_DIR.glob("*.ogg"))
        new_files = [f for f in ogg_files if f.name not in self.processed_files]
        
        # Sortiere nach Erstellungszeit (neueste zuerst)
        new_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
        return new_files
    
    def _transcribe(self, ogg_path: Path) -> Optional[str]:
        """Transkribiere .ogg Datei mit whisper.cpp"""
        print(f"[INFO] Transkribiere: {ogg_path.name}")
        
        try:
            result = subprocess.run(
                [sys.executable, str(WHISPER_SCRIPT), str(ogg_path)],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                text = result.stdout.strip()
                # Filtere stderr-Output raus (nimm nur letzte Zeile ohne "Transkribiere...")
                lines = [l for l in text.split('\n') if l.strip() and not l.startswith('Transkribiere')]
                if lines:
                    return lines[-1].strip()
            else:
                print(f"[FEHLER] Transkription fehlgeschlagen: {result.stderr}", file=sys.stderr)
                
        except subprocess.TimeoutExpired:
            print("[FEHLER] Transkription Timeout", file=sys.stderr)
        except Exception as e:
            print(f"[FEHLER] {e}", file=sys.stderr)
        
        return None
    
    def _inject_to_session(self, text: str, original_file: str) -> str:
        """
        Injiziere transkribierten Text in OpenClaw Session.
        Schreibe in eine Datei, die der Agent lesen kann.
        """
        request_id = f"voice_{int(time.time())}"
        request_file = RESPONSE_POLL_DIR / f"{request_id}.request"
        
        request_data = {
            "id": request_id,
            "timestamp": datetime.now().isoformat(),
            "original_file": original_file,
            "transcribed_text": text,
            "status": "pending_response"
        }
        
        with open(request_file, 'w', encoding='utf-8') as f:
            json.dump(request_data, f, indent=2)
        
        print(f"[INFO] Anfrage gespeichert: {request_id}")
        print(f"[INFO] Warte auf Antwort... (max {RESPONSE_TIMEOUT}s)")
        
        return request_id
    
    def _wait_for_response(self, request_id: str) -> Optional[str]:
        """
        Warte auf Antwort vom Agent.
        Der Agent schreibt seine Antwort in eine .response Datei.
        """
        response_file = RESPONSE_POLL_DIR / f"{request_id}.response"
        start_time = time.time()
        
        while time.time() - start_time < RESPONSE_TIMEOUT:
            if response_file.exists():
                try:
                    with open(response_file, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    
                    # Lösche Response-Datei nach dem Lesen
                    response_file.unlink()
                    
                    return data.get("response_text")
                    
                except Exception as e:
                    print(f"[FEHLER] Konnte Antwort nicht lesen: {e}", file=sys.stderr)
                    return None
            
            time.sleep(1.0)
        
        print("[WARNUNG] Timeout - keine Antwort erhalten")
        return None
    
    def _generate_tts(self, text: str) -> Optional[Path]:
        """Generiere TTS mit Piper"""
        print(f"[INFO] Generiere TTS...")
        
        try:
            result = subprocess.run(
                [sys.executable, str(PIPER_SCRIPT), text],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                # Extrahiere Pfad aus Output
                for line in result.stdout.split('\n'):
                    if '[OK] TTS generiert:' in line:
                        path_str = line.split('[OK] TTS generiert:')[1].strip()
                        return Path(path_str)
            else:
                print(f"[FEHLER] TTS fehlgeschlagen: {result.stderr}", file=sys.stderr)
                
        except Exception as e:
            print(f"[FEHLER] TTS Fehler: {e}", file=sys.stderr)
        
        return None
    
    def _send_voice_note(self, audio_path: Path, original_file: str):
        """
        Sende Voice-Note zurück an Telegram.
        Für Phase 1: Wir bewegen die Datei in einen Ordner, aus dem 
        sie manuell verschickt werden kann (oder via Tool).
        """
        print(f"[INFO] Voice-Note bereit: {audio_path}")
        
        # In Phase 1: Kopiere in einen "ready-to-send" Ordner
        ready_dir = Path.home() / ".openclaw" / "voice" / "ready_to_send"
        ready_dir.mkdir(parents=True, exist_ok=True)
        
        # Umbenennen mit Original-Referenz
        timestamp = int(time.time())
        target_path = ready_dir / f"response_{timestamp}_{original_file}.wav"
        
        try:
            import shutil
            shutil.copy2(audio_path, target_path)
            print(f"[OK] Voice-Note bereit zum Senden: {target_path}")
            print(f"[HINWEIS] Manuelles Senden an Telegram erforderlich (Phase 1 Limitation)")
        except Exception as e:
            print(f"[FEHLER] Konnte Voice-Note nicht kopieren: {e}", file=sys.stderr)
    
    def process_single_file(self, ogg_path: Path) -> bool:
        """Verarbeite eine einzelne Voice Message"""
        print(f"\n{'='*60}")
        print(f"[INFO] Neue Voice Message: {ogg_path.name}")
        print(f"{'='*60}")
        
        # 1. Transkribiere
        text = self._transcribe(ogg_path)
        if not text:
            print("[FEHLER] Transkription fehlgeschlagen")
            self._log_processed(ogg_path.name, "", False)
            return False
        
        print(f"[OK] Transkribiert: '{text[:100]}...' " if len(text) > 100 else f"[OK] Transkribiert: '{text}'")
        
        # 2. Injiziere in Session
        request_id = self._inject_to_session(text, ogg_path.name)
        
        # 3. Warte auf Antwort
        response = self._wait_for_response(request_id)
        
        if not response:
            print("[INFO] Keine Antwort erhalten (Timeout)")
            self._log_processed(ogg_path.name, text, False)
            return False
        
        print(f"[OK] Antwort empfangen: '{response[:100]}...' " if len(response) > 100 else f"[OK] Antwort empfangen: '{response}'")
        
        # 4. Generiere TTS
        audio_path = self._generate_tts(response)
        if not audio_path:
            print("[FEHLER] TTS Generierung fehlgeschlagen")
            self._log_processed(ogg_path.name, text, False)
            return False
        
        # 5. Bereite Voice-Note vor
        self._send_voice_note(audio_path, ogg_path.name)
        
        # 6. Logge Erfolg
        self._log_processed(ogg_path.name, text, True)
        self.processed_files.add(ogg_path.name)
        
        print(f"[OK] Verarbeitung abgeschlossen: {ogg_path.name}")
        return True
    
    def run(self):
        """Hauptschleife"""
        print("="*60)
        print("[INFO] Voice Loop gestartet")
        print("[INFO] Polling-Verzeichnis:", MEDIA_DIR)
        print("[INFO] Drücke Ctrl+C zum Beenden")
        print("="*60)
        
        self.running = True
        
        try:
            while self.running:
                # Suche neue Dateien
                new_files = self._find_new_ogg_files()
                
                for ogg_file in new_files:
                    self.process_single_file(ogg_file)
                
                # Warte vor nächstem Polling
                time.sleep(POLL_INTERVAL)
                
        except KeyboardInterrupt:
            print("\n[INFO] Beendet durch Benutzer")
            self.running = False
    
    def run_once(self, ogg_path: Path):
        """Verarbeite eine einzelne Datei (für manuellen Modus)"""
        return self.process_single_file(ogg_path)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Voice Loop für Telegram Voice Messages")
    parser.add_argument("--once", type=Path, help="Verarbeite einzelne Datei und beende")
    args = parser.parse_args()
    
    loop = VoiceLoop()
    
    if args.once:
        success = loop.run_once(args.once)
        sys.exit(0 if success else 1)
    else:
        loop.run()


if __name__ == "__main__":
    main()
