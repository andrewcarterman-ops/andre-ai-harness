# Whisper Local STT Skill

Lokale Speech-to-Text Transkription mit OpenAI's Whisper (offline, privacy-first).

## Features

- **Lokale Verarbeitung**: Keine Daten verlassen deinen PC
- **Drei Modelle**: `schnell` (base), `mittel` (small), `langsam` (medium)
- **Persistente Einstellungen**: Modell-Wahl wird gespeichert
- **Telegram-Integration**: Sprachnachrichten direkt transkribieren

## Commands

| Befehl | Beschreibung |
|--------|--------------|
| `/whisper schnell` | Schnelles Modell (base, ~150MB) |
| `/whisper mittel` | Balanced Modell (small, ~500MB) |
| `/whisper langsam` | Genaues Modell (medium, ~1.5GB) |
| `/whisper status` | Aktuelles Modell anzeigen |
| `/whisper help` | Hilfe anzeigen |

## Verwendung

1. **Modell wählen**:
   ```
   /whisper langsam
   ```

2. **Sprachnachricht senden**:
   - Sende eine Voice Message in Telegram
   - Automatische Transkription mit gewähltem Modell

3. **Status prüfen**:
   ```
   /whisper status
   ```

## Modelle im Vergleich

| Modell | Größe | Geschwindigkeit* | Qualität |
|--------|-------|------------------|----------|
| base | 150 MB | ~5s pro Minute | Gut |
| small | 500 MB | ~15s pro Minute | Sehr gut |
| medium | 1.5 GB | ~30s pro Minute | Ausgezeichnet |

\* Mit NVIDIA GPU (RTX 3060). CPU ist 3-5x langsamer.

## Setup

### Automatische Installation

```bash
python scripts/install.py
```

Lädt automatisch alle Modelle herunter (~2GB).

### Manuelle Installation

1. Python-Abhängigkeiten installieren:
   ```bash
   pip install faster-whisper pydub
   ```

2. FFmpeg installieren (für Audio-Konvertierung):
   - Windows: `winget install Gyan.FFmpeg`
   - macOS: `brew install ffmpeg`
   - Linux: `sudo apt install ffmpeg`

3. Modelle herunterladen (erfolgt beim ersten Start automatisch).

## Konfiguration

Die Konfiguration wird in `~/.openclaw/skills/whisper-local-stt/config.json` gespeichert:

```json
{
  "default_model": "small",
  "models": {
    "base": {"size": "base", "device": "auto", "compute_type": "int8"},
    "small": {"size": "small", "device": "auto", "compute_type": "int8"},
    "medium": {"size": "medium", "device": "auto", "compute_type": "int8"}
  },
  "telegram": {
    "delete_after_transcribe": true,
    "max_duration": 600
  }
}
```

## Hardware-Anforderungen

### Minimum
- 4 GB RAM (8 GB empfohlen)
- 2 GB freier Speicherplatz
- CPU mit 4 Kernen

### Empfohlen (mit GPU)
- NVIDIA GPU mit 4 GB VRAM
- 8 GB RAM
- SSD für Modell-Dateien

## Datenschutz

- ✅ Alle Daten bleiben lokal
- ✅ Keine Verbindung zu OpenAI oder anderen APIs
- ✅ Temporäre Audio-Dateien werden sofort gelöscht
- ✅ Kein Logging von Audio-Inhalten

## Fehlerbehebung

### "CUDA out of memory"
→ Wechsle zu kleinerem Modell oder nutze CPU:
```
/whisper schnell
```

### "FFmpeg not found"
→ FFmpeg installieren:
```bash
winget install Gyan.FFmpeg  # Windows
```

### Langsame Transkription
- GPU wird empfohlen für medium-Modell
- Mit CPU: base-Modell verwenden (`/whisper schnell`)

## Lizenz

MIT - Siehe LICENSE
