#!/usr/bin/env python3
"""
Whisper Command Handler
Verarbeitet /whisper Befehle und verwaltet Modell-Einstellungen.
"""

import json
import sys
from pathlib import Path
from typing import Optional, Dict, Any

CONFIG_DIR = Path.home() / ".openclaw" / "skills" / "whisper-local-stt"
CONFIG_FILE = CONFIG_DIR / "config.json"

MODEL_ALIASES = {
    "schnell": "base",
    "fast": "base",
    "mittel": "small",
    "medium": "small",
    "langsam": "medium",
    "slow": "medium",
    "precise": "medium",
    "genau": "medium"
}

MODEL_INFO = {
    "base": {
        "name": "base",
        "size": "~150 MB",
        "speed": "Sehr schnell (~5s/Min)",
        "quality": "Gut",
        "vram": "~1 GB"
    },
    "small": {
        "name": "small",
        "size": "~500 MB",
        "speed": "Mittel (~15s/Min)",
        "quality": "Sehr gut",
        "vram": "~2 GB"
    },
    "medium": {
        "name": "medium",
        "size": "~1.5 GB",
        "speed": "Langsam (~30s/Min)",
        "quality": "Ausgezeichnet",
        "vram": "~5 GB"
    }
}


def load_config() -> Dict[str, Any]:
    """Lädt Konfiguration"""
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"default_model": "small", "user_preferences": {}}


def save_config(config: Dict[str, Any]):
    """Speichert Konfiguration"""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)


def get_user_id() -> str:
    """Ermittelt User-ID aus Umgebung oder Standard"""
    # In OpenClaw wird die User-ID normalerweise als Env-Variable übergeben
    return os.environ.get("OPENCLAW_USER_ID", "default")


def get_user_model(user_id: str) -> str:
    """Ermittelt bevorzugtes Modell für User"""
    config = load_config()
    return config.get("user_preferences", {}).get(user_id, config.get("default_model", "small"))


def set_user_model(user_id: str, model: str):
    """Setzt bevorzugtes Modell für User"""
    config = load_config()
    
    if "user_preferences" not in config:
        config["user_preferences"] = {}
    
    config["user_preferences"][user_id] = model
    save_config(config)


def normalize_model(model_name: str) -> Optional[str]:
    """Normalisiert Modell-Namen"""
    model_lower = model_name.lower().strip()
    
    # Direkte Übereinstimmung
    if model_lower in ["base", "small", "medium"]:
        return model_lower
    
    # Alias-Übersetzung
    if model_lower in MODEL_ALIASES:
        return MODEL_ALIASES[model_lower]
    
    return None


def handle_schnell(user_id: str):
    """Wechselt zu schnellem Modell"""
    set_user_model(user_id, "base")
    info = MODEL_INFO["base"]
    print(f"✅ Modell auf 'schnell' (base) gesetzt")
    print(f"   Geschwindigkeit: {info['speed']}")
    print(f"   Qualität: {info['quality']}")
    print(f"   Speicherbedarf: {info['vram']}")
    print(f"\n💡 Alle folgenden Sprachnachrichten nutzen dieses Modell.")


def handle_mittel(user_id: str):
    """Wechselt zu mittlerem Modell"""
    set_user_model(user_id, "small")
    info = MODEL_INFO["small"]
    print(f"✅ Modell auf 'mittel' (small) gesetzt")
    print(f"   Geschwindigkeit: {info['speed']}")
    print(f"   Qualität: {info['quality']}")
    print(f"   Speicherbedarf: {info['vram']}")
    print(f"\n💡 Alle folgenden Sprachnachrichten nutzen dieses Modell.")


def handle_langsam(user_id: str):
    """Wechselt zu langsamem/genauem Modell"""
    set_user_model(user_id, "medium")
    info = MODEL_INFO["medium"]
    print(f"✅ Modell auf 'langsam' (medium) gesetzt")
    print(f"   Geschwindigkeit: {info['speed']}")
    print(f"   Qualität: {info['quality']}")
    print(f"   Speicherbedarf: {info['vram']}")
    print(f"\n💡 Alle folgenden Sprachnachrichten nutzen dieses Modell.")


def handle_status(user_id: str):
    """Zeigt aktuelles Modell an"""
    current_model = get_user_model(user_id)
    info = MODEL_INFO.get(current_model, MODEL_INFO["small"])
    
    print(f"🎙️  Whisper Local STT Status")
    print(f"\nAktives Modell: {current_model}")
    print(f"   Geschwindigkeit: {info['speed']}")
    print(f"   Qualität: {info['quality']}")
    print(f"   Speicherbedarf: {info['vram']}")
    
    print(f"\n📊 Verfügbare Modelle:")
    for key, alias in [("base", "schnell"), ("small", "mittel"), ("medium", "langsam")]:
        marker = "▸" if key == current_model else " "
        print(f"   {marker} /whisper {alias:8} → {MODEL_INFO[key]['speed']}")


def handle_help():
    """Zeigt Hilfe an"""
    print("🎙️  Whisper Local STT - Hilfe")
    print("\nBefehle:")
    print("  /whisper schnell   → Schnelles Modell (base, ~150MB)")
    print("  /whisper mittel    → Mittleres Modell (small, ~500MB)")
    print("  /whisper langsam   → Genaues Modell (medium, ~1.5GB)")
    print("  /whisper status    → Aktuelles Modell anzeigen")
    print("  /whisper help      → Diese Hilfe")
    
    print("\nVerwendung:")
    print("  1. Wähle ein Modell mit einem der Befehle oben")
    print("  2. Sende eine Sprachnachricht in Telegram")
    print("  3. Die Transkription erfolgt automatisch mit dem gewählten Modell")
    
    print("\nEmpfehlungen:")
    print("  • /whisper schnell  → Kurze Nachrichten, schnelle Antworten")
    print("  • /whisper mittel   → Standard (Balance aus Speed/Qualität)")
    print("  • /whisper langsam  → Lange Nachrichten, wichtige Inhalte")


def main():
    """Hauptfunktion"""
    import os
    
    if len(sys.argv) < 2:
        handle_help()
        return
    
    command = sys.argv[1].lower().strip()
    user_id = get_user_id()
    
    handlers = {
        "schnell": handle_schnell,
        "fast": handle_schnell,
        "mittel": handle_mittel,
        "medium": handle_mittel,
        "langsam": handle_langsam,
        "slow": handle_langsam,
        "precise": handle_langsam,
        "genau": handle_langsam,
        "status": handle_status,
        "help": handle_help,
        "hilfe": handle_help,
    }
    
    if command in handlers:
        if command in ["status", "help", "hilfe"]:
            handlers[command](user_id if command == "status" else None)
        else:
            handlers[command](user_id)
    else:
        print(f"❌ Unbekannter Befehl: '{command}'")
        print(f"\nVerwende einen dieser Befehle:")
        print(f"  /whisper schnell | mittel | langsam | status | help")


if __name__ == "__main__":
    main()
