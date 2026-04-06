#!/usr/bin/env python3
"""
Installationsskript für Whisper Local STT Skill.
Lädt faster-whisper und alle Whisper-Modelle herunter.
"""

import os
import sys
import subprocess
from pathlib import Path

# Konfiguration
MODELS = {
    "base": {"size": "base", "url": "Systran/faster-whisper-base"},
    "small": {"size": "small", "url": "Systran/faster-whisper-small"},
    "medium": {"size": "medium", "url": "Systran/faster-whisper-medium"},
}

CACHE_DIR = Path.home() / ".cache" / "whisper"
CONFIG_DIR = Path.home() / ".openclaw" / "skills" / "whisper-local-stt"


def check_python_version():
    """Prüft Python Version >= 3.9"""
    if sys.version_info < (3, 9):
        print("❌ Python 3.9+ wird benötigt!")
        print(f"   Aktuell: Python {sys.version_info.major}.{sys.version_info.minor}")
        sys.exit(1)
    print(f"✅ Python {sys.version_info.major}.{sys.version_info.minor} gefunden")


def install_dependencies():
    """Installiert Python-Abhängigkeiten"""
    print("\n📦 Installiere Abhängigkeiten...")
    
    deps = ["faster-whisper", "pydub", "requests"]
    
    for dep in deps:
        print(f"   → {dep}...")
        try:
            subprocess.run(
                [sys.executable, "-m", "pip", "install", "-q", dep],
                check=True,
                capture_output=True
            )
        except subprocess.CalledProcessError as e:
            print(f"   ⚠️  Fehler bei {dep}: {e}")
            return False
    
    print("✅ Abhängigkeiten installiert")
    return True


def check_ffmpeg():
    """Prüft ob FFmpeg installiert ist"""
    print("\n🔍 Prüfe FFmpeg...")
    try:
        result = subprocess.run(
            ["ffmpeg", "-version"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            version = result.stdout.split('\n')[0]
            print(f"✅ FFmpeg gefunden: {version[:50]}...")
            return True
    except FileNotFoundError:
        pass
    
    print("⚠️  FFmpeg nicht gefunden!")
    print("   Installiere FFmpeg:")
    print("   Windows: winget install Gyan.FFmpeg")
    print("   macOS:   brew install ffmpeg")
    print("   Linux:   sudo apt install ffmpeg")
    return False


def check_cuda():
    """Prüft CUDA-Verfügbarkeit"""
    print("\n🔍 Prüfe CUDA...")
    try:
        import torch
        if torch.cuda.is_available():
            print(f"✅ CUDA verfügbar: {torch.cuda.get_device_name(0)}")
            return True
    except ImportError:
        pass
    
    print("ℹ️  CUDA nicht verfügbar (CPU-Modus wird verwendet)")
    print("   Für GPU-Beschleunigung: NVIDIA-Treiber und CUDA installieren")
    return False


def download_model(model_name: str, model_config: dict):
    """Lädt ein Whisper-Modell herunter"""
    print(f"\n📥 Lade Modell '{model_name}' herunter...")
    print(f"   Größe: ~{get_model_size(model_name)} MB")
    print("   (Dies kann einige Minuten dauern...)")
    
    try:
        from faster_whisper import WhisperModel
        
        # Modell laden (wird automatisch heruntergeladen)
        model = WhisperModel(
            model_config["size"],
            device="cpu",  # Download mit CPU
            compute_type="int8",
            download_root=str(CACHE_DIR)
        )
        
        print(f"✅ Modell '{model_name}' bereit")
        return True
        
    except Exception as e:
        print(f"❌ Fehler beim Download von '{model_name}': {e}")
        return False


def get_model_size(model_name: str) -> int:
    """Geschätzte Modellgröße in MB"""
    sizes = {"base": 150, "small": 500, "medium": 1500}
    return sizes.get(model_name, 0)


def create_config():
    """Erstellt Standard-Konfiguration"""
    print("\n⚙️  Erstelle Konfiguration...")
    
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    
    config = {
        "default_model": "small",
        "models": {
            "base": {"size": "base", "device": "auto", "compute_type": "int8"},
            "small": {"size": "small", "device": "auto", "compute_type": "int8"},
            "medium": {"size": "medium", "device": "auto", "compute_type": "int8"}
        },
        "telegram": {
            "delete_after_transcribe": True,
            "max_duration": 600
        },
        "user_preferences": {}
    }
    
    config_path = CONFIG_DIR / "config.json"
    import json
    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)
    
    print(f"✅ Konfiguration gespeichert: {config_path}")


def main():
    """Hauptinstallationsprozess"""
    print("=" * 60)
    print("🎙️  Whisper Local STT - Installation")
    print("=" * 60)
    
    # Checks
    check_python_version()
    
    if not install_dependencies():
        print("\n❌ Installation fehlgeschlagen (Abhängigkeiten)")
        sys.exit(1)
    
    check_ffmpeg()
    check_cuda()
    
    # Modelle herunterladen
    print("\n" + "=" * 60)
    print("📥 Modelle werden heruntergeladen...")
    print("=" * 60)
    
    total_size = sum(get_model_size(m) for m in MODELS.keys())
    print(f"\nGesamtgröße: ~{total_size} MB (~{total_size/1000:.1f} GB)\n")
    
    success_count = 0
    for model_name, model_config in MODELS.items():
        if download_model(model_name, model_config):
            success_count += 1
    
    # Konfiguration erstellen
    create_config()
    
    # Zusammenfassung
    print("\n" + "=" * 60)
    print("📊 Installations-Zusammenfassung")
    print("=" * 60)
    print(f"✅ {success_count}/{len(MODELS)} Modelle bereit")
    print(f"📁 Cache-Verzeichnis: {CACHE_DIR}")
    print(f"⚙️  Konfiguration: {CONFIG_DIR}/config.json")
    
    if success_count == len(MODELS):
        print("\n🎉 Installation erfolgreich!")
        print("\nVerwendung:")
        print("  /whisper schnell  → base-Modell")
        print("  /whisper mittel   → small-Modell")
        print("  /whisper langsam  → medium-Modell")
        print("  /whisper status   → Aktuelles Modell anzeigen")
    else:
        print(f"\n⚠️  {len(MODELS) - success_count} Modelle konnten nicht geladen werden")
        print("   Führen Sie das Skript erneut aus.")
        sys.exit(1)


if __name__ == "__main__":
    main()
