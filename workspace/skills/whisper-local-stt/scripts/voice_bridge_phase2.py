#!/usr/bin/env python3
"""
Voice Bridge Phase 2 - Intelligente Modell-Auswahl

Wählt Whisper-Modell basierend auf Audio-Länge:
- < 30s: base (schnell, wenig RAM)
- 30s - 2min: small (gute Balance)
- > 2min: medium (beste Qualität)

Usage:
    python voice_bridge_phase2.py
    python voice_bridge_phase2.py --status
"""

import os
import sys
import time
import json
import subprocess
import shutil
from pathlib import Path
from datetime import datetime
from typing import Optional, Tuple

# Pfade
MEDIA_DIR = Path.home() / ".openclaw" / "media" / "inbound"
INBOX_DIR = Path.home() / ".openclaw" / "voice" / "inbox"
OUTBOX_DIR = Path.home() / ".openclaw" / "voice" / "outbox"
RESPONSE_DIR = OUTBOX_DIR / "responses"
READY_DIR = Path.home() / ".openclaw" / "voice" / "ready_to_send"
LOG_FILE = Path.home() / ".openclaw" / "voice" / "bridge.log"

WHISPER_DIR = Path.home() / ".openclaw" / "whisper"
WHISPER_EXE = WHISPER_DIR / "main.exe"
MODELS_DIR = WHISPER_DIR / "models"

PIPER_EXE = Path.home() / ".openclaw" / "piper" / "piper" / "piper.exe"
PIPER_MODEL = Path.home() / ".openclaw" / "piper" / "models" / "de_DE-thorsten-high.onnx"

# Modell-Konfiguration
MODELS = {
    "base": {
        "file": MODELS_DIR / "ggml-base.bin",
        "max_duration": 30,  # Sekunden
        "description": "Schnell, für kurze Nachrichten"
    },
    "small": {
        "file": MODELS_DIR / "ggml-small.bin", 
        "max_duration": 120,  # 2 Minuten
        "description": "Gute Balance Qualität/Geschwindigkeit"
    },
    "medium": {
        "file": MODELS_DIR / "ggml-medium.bin",
        "max_duration": float('inf'),  # Kein Limit
        "description": "Beste Qualität für lange Audio"
    }
}

# Einstellungen
POLL_INTERVAL = 2.0
TIMEOUT_TRANSCRIBE = 300  # 5 Minuten für große Modelle


class VoiceBridgePhase2:
    def __init__(self):
        self.processed = self._load_processed()
        self._ensure_dirs()
        self._verify_models()
        
    def _ensure_dirs(self):
        """Stelle sicher, dass alle Verzeichnisse existieren"""
        for d in [INBOX_DIR, OUTBOX_DIR, RESPONSE_DIR, READY_DIR]:
            d.mkdir(parents=True, exist_ok=True)
    
    def _verify_models(self):
        """Prüfe welche Modelle verfügbar sind"""
        print("[OK] Verfuegbare Whisper-Modelle:")
        for name, config in MODELS.items():
            status = "[OK]" if config["file"].exists() else "[MISSING]"
            print(f"  {status} {name}: {config['description']}")
        print()
    
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
    
    def _get_audio_duration(self, ogg_path: Path) -> float:
        """Ermittle Audio-Länge in Sekunden via ffprobe oder whisper"""
        try:
            # Versuche ffprobe
            result = subprocess.run(
                ["ffprobe", "-v", "error", "-show_entries", "format=duration",
                 "-of", "default=noprint_wrappers=1:nokey=1", str(ogg_path)],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                return float(result.stdout.strip())
        except:
            pass
        
        # Fallback: Schätze basierend auf Dateigröße (ungefähr)
        # OGG ~160 kbps = 20KB pro Sekunde
        size_bytes = ogg_path.stat().st_size
        estimated_seconds = size_bytes / (20 * 1024)
        return estimated_seconds
    
    def _select_model(self, duration: float) -> Tuple[str, Path]:
        """Wähle passendes Modell basierend auf Dauer"""
        if duration <= MODELS["base"]["max_duration"]:
            return "base", MODELS["base"]["file"]
        elif duration <= MODELS["small"]["max_duration"]:
            return "small", MODELS["small"]["file"]
        else:
            return "medium", MODELS["medium"]["file"]
    
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
        """Transkribiere mit intelligenter Modell-Auswahl"""
        # Ermittle Audio-Länge
        duration = self._get_audio_duration(ogg_path)
        model_name, model_path = self._select_model(duration)
        
        self._log(f"Audio: {duration:.1f}s -> Modell: {model_name}")
        self._log(f"Transkribiere: {ogg_path.name}")
        
        # Fortschrittsanzeige
        print(f"[...] Lade Modell '{model_name}' und transkribiere...")
        
        # Erstelle temporäres WAV (whisper.cpp braucht WAV)
        import tempfile
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            wav_path = Path(tmp.name)
        
        try:
            # Konvertiere zu WAV
            conv_result = subprocess.run(
                ["ffmpeg", "-i", str(ogg_path), "-ar", "16000", "-ac", "1", 
                 "-c:a", "pcm_s16le", "-y", str(wav_path)],
                capture_output=True, timeout=30
            )
            if conv_result.returncode != 0:
                self._log("FFmpeg Konvertierung fehlgeschlagen", "ERROR")
                return None
            
            # whisper.cpp aufrufen
            result = subprocess.run(
                [str(WHISPER_EXE), "-m", str(model_path), "-f", str(wav_path), 
                 "-l", "de", "--no-timestamps", "-t", "4"],
                capture_output=True,
                text=True,
                timeout=TIMEOUT_TRANSCRIBE
            )
            
            if result.returncode == 0:
                # Extrahiere Text aus stderr (whisper.cpp gibt Text auf stderr aus)
                lines = result.stderr.split('\n')
                text_lines = []
                capture = False
                
                for line in lines:
                    if "main: processing" in line:
                        capture = True
                        continue
                    if capture and line.strip() and not line.startswith('whisper_'):
                        if not any(line.startswith(p) for p in ['system_info:', 'main:', 'size=', 'load time=', 'CUDA', 'AVX', 'F16C', 'ggml_']):
                            text_lines.append(line.strip())
                
                text = ' '.join(text_lines).strip()
                
                # Fallback: stdout
                if not text and result.stdout.strip():
                    text = result.stdout.strip()
                
                if text:
                    return text
                else:
                    return "[Kein Text erkannt]"
            else:
                self._log(f"Transkription fehlgeschlagen: {result.stderr[:200]}", "ERROR")
                
        except subprocess.TimeoutExpired:
            self._log(f"Timeout nach {TIMEOUT_TRANSCRIBE}s", "ERROR")
        except Exception as e:
            self._log(f"Transkription Fehler: {e}", "ERROR")
        finally:
            # Cleanup
            if wav_path.exists():
                wav_path.unlink()
        
        return None
    
    def _save_inbox(self, msg_id: str, filename: str, text: str, duration: float, model: str):
        """Speichere Nachricht in Inbox"""
        inbox_file = INBOX_DIR / "new_messages.jsonl"
        
        entry = {
            "id": msg_id,
            "timestamp": datetime.now().isoformat(),
            "original_file": filename,
            "text": text,
            "audio_duration": duration,
            "model_used": model,
            "status": "pending_response"
        }
        
        with open(inbox_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(entry) + "\n")
        
        # Terminal-Ausgabe
        print(f"\n{'='*60}")
        print(f"[NEUE NACHRICHT] ID: {msg_id}")
        print(f"[AUDIO] {duration:.1f}s | Modell: {model}")
        print(f"[TEXT] {text}")
        print(f"{'='*60}")
        print(f"\nAntwort schreiben in:")
        print(f"  {RESPONSE_DIR / (msg_id + '.txt')}")
        print(f"{'='*60}\n")
        
        self._log(f"Nachricht gespeichert: {msg_id} ({model})")
    
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
                timeout=60
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
        
        with open(inbox_file, 'w', encoding='utf-8') as f:
            for entry in entries:
                f.write(json.dumps(entry) + "\n")
    
    def show_status(self):
        """Zeige aktuellen Status"""
        print("\n" + "="*60)
        print("VOICE BRIDGE PHASE 2 - Intelligente Modell-Auswahl")
        print("="*60)
        
        # Verfügbare Modelle
        print("\n[MODELLE]")
        for name, config in MODELS.items():
            status = "[OK]" if config["file"].exists() else "[MISSING]"
            size_mb = config["file"].stat().st_size / (1024*1024) if config["file"].exists() else 0
            print(f"  {status} {name:8} ({size_mb:.0f} MB) - {config['description']}")
        
        # Neue Nachrichten
        print("\n[NACHRICHTEN]")
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
                                print(f"\n  [OFFEN] ID: {entry['id']}")
                                print(f"    Text: {entry['text'][:60]}...")
                                print(f"    Modell: {entry.get('model_used', 'unbekannt')}")
                        except:
                            pass
            
            if pending == 0:
                print("  Keine offenen Nachrichten.")
        
        # Bereite Voice-Notes
        print("\n[BEREIT ZUM SENDEN]")
        if READY_DIR.exists() and list(READY_DIR.glob("*.wav")):
            for f in READY_DIR.glob("*.wav"):
                print(f"  [FILE] {f.name}")
        else:
            print("  Keine Voice-Notes bereit.")
        
        print("\n" + "="*60)
        print(f"Inbox:    {INBOX_DIR}")
        print(f"Antworten: {RESPONSE_DIR}")
        print(f"Bereit:   {READY_DIR}")
        print("="*60 + "\n")
    
    def run(self):
        """Hauptschleife"""
        print("\n" + "="*60)
        print("VOICE BRIDGE PHASE 2")
        print("Intelligente Modell-Auswahl (base/small/medium)")
        print("="*60)
        print(f"\nUeberwache: {MEDIA_DIR}")
        print(f"Inbox:     {INBOX_DIR}")
        print(f"Antworten: {RESPONSE_DIR}")
        print(f"\nModell-Auswahl:")
        print(f"  < 30s  -> base (schnell)")
        print(f"  < 2min -> small (balance)")
        print(f"  > 2min -> medium (qualitaet)")
        print(f"\nDruecke Ctrl+C zum Beenden")
        print("="*60 + "\n")
        
        self._log("Voice Bridge Phase 2 gestartet")
        
        try:
            while True:
                # 1. Prüfe auf neue Voice Messages
                new_ogg = self._find_new_ogg()
                
                if new_ogg:
                    msg_id = f"msg_{int(time.time())}"
                    duration = self._get_audio_duration(new_ogg)
                    model_name, _ = self._select_model(duration)
                    
                    text = self._transcribe(new_ogg)
                    
                    if text:
                        self._save_inbox(msg_id, new_ogg.name, text, duration, model_name)
                    
                    self._save_processed(new_ogg.name)
                
                # 2. Prüfe auf Antworten
                self._check_responses()
                
                time.sleep(POLL_INTERVAL)
                
        except KeyboardInterrupt:
            print("\n\nBeendet.")
            self._log("Voice Bridge Phase 2 beendet")


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--status", action="store_true", help="Zeige aktuellen Status")
    args = parser.parse_args()
    
    bridge = VoiceBridgePhase2()
    
    if args.status:
        bridge.show_status()
    else:
        bridge.run()


if __name__ == "__main__":
    main()
