#!/usr/bin/env python3
"""
Download Whisper models for local STT (whisper.cpp)
"""
import os
import sys
import urllib.request
from pathlib import Path

MODELS_DIR = Path.home() / ".openclaw" / "whisper" / "models"
BASE_URL = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

MODELS = {
    "base": {"file": "ggml-base.bin", "size": "~147 MB"},
    "small": {"file": "ggml-small.bin", "size": "~466 MB"},
    "medium": {"file": "ggml-medium.bin", "size": "~1.5 GB"}
}


def download_file(url: str, dest: Path):
    """Lädt eine Datei mit Fortschrittsanzeige herunter"""
    print(f"Downloading {dest.name}...")
    
    def report_progress(block_num, block_size, total_size):
        downloaded = block_num * block_size
        percent = min(downloaded * 100 / total_size, 100)
        mb = downloaded / 1024 / 1024
        total_mb = total_size / 1024 / 1024
        print(f"\r  {percent:.1f}% ({mb:.1f} / {total_mb:.1f} MB)", end="")
    
    try:
        urllib.request.urlretrieve(url, dest, reporthook=report_progress)
        print()  # newline after progress
        return True
    except Exception as e:
        print(f"\n  [ERROR] {e}")
        if dest.exists():
            dest.unlink()
        return False


def main():
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    
    print(f"Whisper.cpp Model Download")
    print(f"Zielverzeichnis: {MODELS_DIR}")
    print()
    
    for name, info in MODELS.items():
        dest = MODELS_DIR / info["file"]
        if dest.exists():
            size_mb = dest.stat().st_size / 1024 / 1024
            print(f"[SKIP] {info['file']} existiert bereits ({size_mb:.1f} MB)")
            continue
        
        url = f"{BASE_URL}/{info['file']}"
        success = download_file(url, dest)
        if success:
            print(f"  [OK] {info['file']} fertig")
        else:
            print(f"  [FAIL] {info['file']} konnte nicht heruntergeladen werden")
    
    print()
    print("Installation abgeschlossen.")
    print("Vorhandene Modelle:")
    for f in sorted(MODELS_DIR.glob("ggml-*.bin")):
        size_mb = f.stat().st_size / 1024 / 1024
        print(f"  - {f.name} ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()
