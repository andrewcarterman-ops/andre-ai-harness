---
title: "Whisper Faster-Whisper (Python) Setup"
status: paused
priority: low
created: 13-04-2026
tags:
  - project
  - whisper
  - stt
  - python
---

# Whisper Faster-Whisper (Python) Setup

## Ziel
Alternative Python-basierte Whisper-Implementierung als Backup oder für spezifische Use-Cases einrichten.

## Hintergrund
whisper.cpp (C++) läuft bereits produktiv. Dies ist eine alternative Implementierung mit faster-whisper (Python), die evtl. bessere GPU-Nutzung bietet.

## Status

### Bereits erledigt:
- [x] FFmpeg installiert (v8.1)
- [x] Python-Pakete installiert (faster-whisper 1.2.1, pydub 0.25.1)
- [x] Skill-Dateien erstellt
- [ ] Modelle gedownloaded

### Offen:
- [ ] Modelle manuell downloaden (siehe unten)
- [ ] In OpenClaw registrieren
- [ ] Testen

## Manueller Download (WICHTIG!)

Automatische Downloads über `exec` fehlschlagen bei großen Dateien (>100MB).

### Option 1: HuggingFace CLI (empfohlen)
```bash
# HuggingFace CLI installieren
pip install huggingface-hub

# Modelle downloaden
huggingface-cli download Systran/faster-whisper-base
huggingface-cli download Systran/faster-whisper-small
huggingface-cli download Systran/faster-whisper-medium
```

### Option 2: Browser + manuelles Kopieren
1. https://huggingface.co/Systran/faster-whisper-base/tree/main
2. Modelle herunterladen
3. Nach `~/.cache/huggingface/hub/` kopieren

### Option 3: Git LFS
```bash
git lfs install
git clone https://huggingface.co/Systran/faster-whisper-base
```

## Modelle

| Modell | Größe | Use-Case |
|--------|-------|----------|
| base | ~150MB | Schnelle Tests |
| small | ~500MB | Standard |
| medium | ~1.5GB | Hohe Qualität |

## Vergleich whisper.cpp vs faster-whisper

| Feature | whisper.cpp (C++) | faster-whisper (Python) |
|---------|-------------------|------------------------|
| Geschwindigkeit | Sehr schnell | Schnell |
| GPU-Nutzung | Gut | Besser (CUDA) |
| Dateigröße | Klein | Größer |
| Setup | Einfacher | Komplexer |
| Status | Produktiv | Paused |

## Entscheidung

**Aktuell:** whisper.cpp läuft gut → Dieses Projekt hat niedrige Priorität.

**Aktivieren wenn:**
- whisper.cpp Probleme macht
- Bessere GPU-Nutzung nötig
- Spezifische Python-Integration gewünscht

## Referenzen
- Skill: `skills/whisper-local-stt/`
- Config: `skills/whisper-local-stt/config.json`
- Original: `~/.openclaw/workspace/skills/whisper-local-stt/`
