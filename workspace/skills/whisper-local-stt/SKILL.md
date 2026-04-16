---
name: whisper-local-stt
description: Lokale Speech-to-Text Transkription mit whisper.cpp (offline, privacy-first). Use when receiving voice messages, audio transcription needed, or user mentions "transcribe", "voice to text".
triggers: ["voice message", "transcribe", "audio", "sprachnachricht", "voice"]
---

# Whisper Local STT

Lokale Spracherkennung mit **whisper.cpp** (C++ Implementation). Schnell, offline, CPU-basiert.

## Quick Start

```bash
# Audio transkribieren (automatisch bei Voice Messages)
python scripts/transcribe.py audio.wav
```

## Setup-Status

| Komponente | Status | Pfad |
|------------|--------|------|
| whisper.cpp (main.exe) | ✅ | `~/.openclaw/whisper/main.exe` |
| ggml-base.bin | ✅ | `~/.openclaw/whisper/models/ggml-base.bin` |
| FFmpeg | ✅ | Systemweit installiert |
| transcribe.py | ✅ | `~/.openclaw/skills/whisper-local-stt/scripts/transcribe.py` |
| config.json | ✅ | `~/.openclaw/skills/whisper-local-stt/config.json` |

## Workflow

### Automatisch (Voice Messages)

1. Voice Message wird empfangen (.ogg)
2. FFmpeg konvertiert zu WAV (16kHz, mono)
3. whisper.cpp transkribiert
4. Transkript wird ausgegeben
5. Temp-Dateien werden gelöscht

### Manuell

```bash
# Mit base Modell (schnell, ~147MB)
python scripts/transcribe.py audio.wav

# Mit small Modell (bessere Qualität, ~466MB)
python scripts/command_handler.py small
python scripts/transcribe.py audio.wav

# Mit medium Modell (beste Qualität, ~1.5GB)
python scripts/command_handler.py langsam
python scripts/transcribe.py audio.wav
```

## Befehle

```
/whisper schnell   → base Modell
/whisper mittel    → small Modell
/whisper langsam   → medium Modell
/whisper status    → Aktuelles Modell anzeigen
/whisper help      → Hilfe
```

## Technische Details

### Konvertierung
```bash
ffmpeg -i input.ogg -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```

### whisper.cpp Parameter
| Parameter | Bedeutung |
|-----------|-----------|
| `-m` | Modell-Pfad |
| `-f` | Audio-Datei |
| `-l de` | Sprache (de=Deutsch) |
| `-t 8` | Threads (8 für i7-6820HK) |
| `-nt` | Keine Timestamps |

## Fehlerbehebung

| Fehler | Lösung |
|--------|--------|
| "Modell nicht gefunden" | `python scripts/install.py` ausführen |
| "FFmpeg not found" | `winget install Gyan.FFmpeg` |
| "main.exe fehlt" | whisper.cpp Binary neu herunterladen |

## Performance

| Modell | Größe | i7-6820HK | Qualität |
|--------|-------|-----------|----------|
| base | 147MB | ~2x Echtzeit | Gut |
| small | 466MB | ~5x Echtzeit | Sehr gut |
| medium | 1.5GB | ~15x Echtzeit | Ausgezeichnet |

## Integration mit OpenClaw

Bei Voice Messages:
```
User: [Voice Message]
Agent: → Convert OGG → WAV
       → Run whisper.cpp via transcribe.py
       → Return transcript
```

## Datenschutz

- 100% lokale Verarbeitung
- Keine Daten verlassen den PC
- Keine Cloud-APIs
- Offline-fähig

## Modell-Download

```bash
cd ~/.openclaw/workspace/skills/whisper-local-stt
python scripts/install.py
```

Dies lädt `ggml-base.bin`, `ggml-small.bin` und `ggml-medium.bin` aus dem HuggingFace-Repo von ggerganov.
