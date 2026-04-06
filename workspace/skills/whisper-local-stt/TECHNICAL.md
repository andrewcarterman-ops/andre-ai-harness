# Whisper Local STT - Technische Dokumentation

## Architektur

```
┌─────────────────────────────────────────────────────────────┐
│                      Telegram User                          │
└───────────────────────────┬─────────────────────────────────┘
                            │ Voice Message
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   OpenClaw Gateway                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Skill: whisper-local-stt                           │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │   │
│  │  │   Commands   │  │ Transcribe   │  │  Telegram │ │   │
│  │  │   Handler    │  │   Engine     │  │  Handler  │ │   │
│  │  └──────────────┘  └──────────────┘  └───────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────────┘
                            │ Text
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Kimi/Agent                               │
└─────────────────────────────────────────────────────────────┘
```

## Komponenten

### 1. Command Handler (`command_handler.py`)

Verarbeitet `/whisper` Befehle und verwaltet User-Preferences.

**Ablauf:**
1. Empfängt Befehl (`schnell`, `mittel`, `langsam`, `status`)
2. Lädt aktuelle Konfiguration
3. Aktualisiert User-Preference
4. Gibt Bestätigung aus

**Datenstruktur:**
```json
{
  "user_preferences": {
    "user_123": "base",
    "user_456": "medium"
  }
}
```

### 2. Transcription Engine (`transcribe.py`)

Kernkomponente für Speech-to-Text.

**Features:**
- Modell-Caching (Singleton-Pattern)
- Automatische Audio-Konvertierung (FFmpeg)
- VAD (Voice Activity Detection)
- GPU/CPU Auto-Detection

**Performance:**
- Modell wird einmal geladen und im RAM gehalten
- Audio-Konvertierung in temporäre WAV-Datei
- Cleanup nach jeder Transkription

### 3. Telegram Handler (`telegram_handler.py`)

Interface zwischen Telegram und Transcription Engine.

**Input-Methoden:**
1. Datei als Kommandozeilen-Argument
2. Env-Variable `TELEGRAM_AUDIO_FILE`
3. Automatische Suche in OpenClaw-Media-Ordner

**Output:**
- Reiner Text (stdout)
- Errors (stderr)

## Datenfluss

### Szenario 1: Modell-Wechsel

```
User: "/whisper langsam"
  ↓
OpenClaw → command_handler.py "langsam"
  ↓
Lade config.json → Update user_preferences → Speichere
  ↓
Ausgabe: "✅ Modell auf 'langsam' (medium) gesetzt"
```

### Szenario 2: Sprachnachricht

```
User: Sendet Voice Message
  ↓
Telegram → OpenClaw → telegram_handler.py
  ↓
Ermittelt User-ID → Lädt bevorzugtes Modell
  ↓
convert_audio() → FFmpeg → WAV (16kHz, mono)
  ↓
transcribe_audio() → faster-whisper → Text
  ↓
Cleanup → Ausgabe an Agent
```

## Konfiguration

### Datei: `config.json`

```json
{
  "default_model": "small",          // Fallback-Modell
  "models": {                         // Verfügbare Modelle
    "base": {...},
    "small": {...},
    "medium": {...}
  },
  "telegram": {                       // Telegram-spezifisch
    "delete_after_transcribe": true,  // Privacy
    "max_duration": 600               // 10 Min Limit
  },
  "user_preferences": {}              // Pro-User Einstellungen
}
```

### Umgebungsvariablen

| Variable | Beschreibung |
|----------|--------------|
| `OPENCLAW_USER_ID` | Aktueller User |
| `TELEGRAM_USER_ID` | Telegram User ID |
| `TELEGRAM_AUDIO_FILE` | Pfad zur Audio-Datei |

## Modell-Speicherung

```
~/.cache/whisper/
├── models--Systran/
│   └── faster-whisper-base/
│       └── snapshots/
│           └── .../
│               └── model.bin
├── faster-whisper-base/
├── faster-whisper-small/
└── faster-whisper-medium/
```

## Fehlerbehandlung

### Häufige Fehler

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `FFmpeg not found` | Nicht installiert | `winget install Gyan.FFmpeg` |
| `CUDA out of memory` | VRAM voll | `/whisper schnell` oder CPU-Modus |
| `Model not found` | Download fehlgeschlagen | `python scripts/install.py` |
| `Audio too long` | >10 Minuten | Audio kürzen oder Limit erhöhen |

### Fallback-Strategien

1. **GPU-OOM** → Automatischer Fallback auf CPU
2. **Modell fehlt** → Automatischer Download bei erstem Zugriff
3. **FFmpeg fehlt** → Klare Fehlermeldung mit Installationsanweisung
4. **Transkription fehlgeschlagen** → Retry mit kleinerem Modell

## Performance-Optimierung

### Modell-Caching
```python
_model_cache = {}

def get_model(name):
    if name in _model_cache:
        return _model_cache[name]
    model = WhisperModel(...)
    _model_cache[name] = model
    return model
```

### Quantisierung
- GPU: `float16` (schnell)
- CPU: `int8` (kompakt)

### VAD (Voice Activity Detection)
```python
vad_parameters = dict(
    min_silence_duration_ms=500
)
```
Überspringt Stille am Anfang/Ende.

## Sicherheit & Privacy

1. **Lokale Verarbeitung**: Keine Daten verlassen den PC
2. **Temp-Dateien**: Sofortiges Löschen nach Transkription
3. **No Logging**: Audio-Inhalte werden nicht geloggt
4. **User-Isolation**: Pro-User Model-Preferences

## Erweiterungen

### Mögliche Verbesserungen

1. **Speaker Diarization**: "Wer hat was gesagt?"
2. **Realtime-Streaming**: Live-Transkription
3. **Batch-Processing**: Mehrere Audios parallel
4. **Custom Vocabulary**: Domänenspezifische Begriffe
5. **Post-Processing**: Autokorrektur, Formatierung

### Integration mit Mission Control

```python
# Voice Command für Tasks
if text.startswith("Erstelle Task:"):
    task_name = text.replace("Erstelle Task:", "").strip()
    create_task(task_name)
```

## Testing

### Manuelle Tests

```bash
# 1. Installation testen
python scripts/install.py

# 2. Modell-Wechsel testen
python scripts/command_handler.py langsam

# 3. Transkription testen
python scripts/transcribe.py test-audio.ogg

# 4. Telegram-Flow testen
python scripts/telegram_handler.py test-audio.ogg
```

### Automatisierte Tests

```python
def test_model_switching():
    set_user_model("test_user", "base")
    assert get_user_model("test_user") == "base"

def test_transcription():
    text, meta = transcribe_audio("test.ogg", "base")
    assert len(text) > 0
    assert meta["language"] == "de"
```

## Troubleshooting

### Debug-Modus aktivieren

```bash
export WHISPER_DEBUG=1
python scripts/transcribe.py audio.ogg
```

### Log-Dateien

```
~/.openclaw/skills/whisper-local-stt/logs/
├── transcribe.log
├── telegram_handler.log
└── command_handler.log
```

## Lizenz & Credits

- **faster-whisper**: MIT License (https://github.com/SYSTRAN/faster-whisper)
- **OpenAI Whisper**: MIT License
- **Dieser Skill**: MIT License
