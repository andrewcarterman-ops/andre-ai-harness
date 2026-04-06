#!/usr/bin/env python3
"""
Telegram Voice Message Handler
Empfängt und verarbeitet Sprachnachrichten aus Telegram.
"""

import os
import sys
import json
import tempfile
from pathlib import Path
from typing import Optional

# Konfiguration
CONFIG_DIR = Path.home() / ".openclaw" / "skills" / "whisper-local-stt"
CONFIG_FILE = CONFIG_DIR / "config.json"


def load_config() -> dict:
    """Lädt Konfiguration"""
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"telegram": {"max_duration": 600, "delete_after_transcribe": True}}


def get_user_id() -> str:
    """Ermittelt User-ID aus Telegram-Context"""
    # OpenClaw übergibt User-ID als Env-Variable
    return os.environ.get("TELEGRAM_USER_ID") or os.environ.get("OPENCLAW_USER_ID", "default")


def get_audio_from_telegram() -> Optional[Path]:
    """
    Empfängt Audio-Datei von Telegram.
    In OpenClaw wird die Datei als Argument oder Env-Variable übergeben.
    """
    # Methode 1: Datei-Pfad als Argument
    if len(sys.argv) >= 2:
        audio_path = Path(sys.argv[1])
        if audio_path.exists():
            return audio_path
    
    # Methode 2: Datei-Pfad als Env-Variable
    audio_path_env = os.environ.get("TELEGRAM_AUDIO_FILE")
    if audio_path_env:
        audio_path = Path(audio_path_env)
        if audio_path.exists():
            return audio_path
    
    # Methode 3: Datei aus OpenClaw-Media-Ordner
    media_dir = Path.home() / ".openclaw" / "media" / "inbound"
    if media_dir.exists():
        # Neueste Audio-Datei finden
        audio_files = list(media_dir.glob("*.ogg")) + list(media_dir.glob("*.mp3")) + list(media_dir.glob("*.wav"))
        if audio_files:
            return max(audio_files, key=lambda p: p.stat().st_mtime)
    
    return None


def check_duration(audio_path: Path) -> bool:
    """Prüft ob Audio nicht zu lang ist"""
    config = load_config()
    max_duration = config.get("telegram", {}).get("max_duration", 600)
    
    try:
        import subprocess
        result = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "default=noprint_wrappers=1:nokey=1", str(audio_path)],
            capture_output=True,
            text=True
        )
        duration = float(result.stdout.strip())
        
        if duration > max_duration:
            print(f"⚠️  Audio zu lang: {duration:.0f}s (Maximum: {max_duration}s)")
            return False
        
        return True
    except Exception:
        # Wenn FFprobe nicht verfügbar, trotzdem fortfahren
        return True


def process_voice_message(audio_path: Path, user_id: str):
    """Verarbeitet eine Sprachnachricht"""
    import subprocess
    
    # Skript-Verzeichnis ermitteln
    script_dir = Path(__file__).parent
    transcribe_script = script_dir / "transcribe.py"
    
    if not transcribe_script.exists():
        print(f"❌ Transkriptions-Skript nicht gefunden: {transcribe_script}")
        return
    
    # Umgebungsvariablen setzen
    env = os.environ.copy()
    env["OPENCLAW_USER_ID"] = user_id
    
    # Transkription ausführen
    try:
        result = subprocess.run(
            [sys.executable, str(transcribe_script), str(audio_path)],
            capture_output=True,
            text=True,
            env=env
        )
        
        if result.returncode == 0:
            # Erfolg - Transkription ausgeben
            print(result.stdout)
        else:
            # Fehler
            print(f"❌ Transkription fehlgeschlagen:")
            print(result.stderr)
            
    except Exception as e:
        print(f"❌ Fehler bei der Verarbeitung: {e}")


def main():
    """Hauptfunktion"""
    # Audio-Datei ermitteln
    audio_path = get_audio_from_telegram()
    
    if not audio_path:
        print("❌ Keine Audio-Datei gefunden.")
        print("Verwendung: telegram_handler.py <audio-datei.ogg>")
        sys.exit(1)
    
    print(f"🎙️  Verarbeite Audio: {audio_path.name}", file=sys.stderr)
    
    # Dauer prüfen
    if not check_duration(audio_path):
        sys.exit(1)
    
    # User-ID ermitteln
    user_id = get_user_id()
    
    # Verarbeiten
    process_voice_message(audio_path, user_id)


if __name__ == "__main__":
    main()
