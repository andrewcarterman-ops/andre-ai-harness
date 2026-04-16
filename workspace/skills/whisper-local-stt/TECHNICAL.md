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
│  │  │command_han...│  │transcribe.py │  │telegram_..│ │   │
│  │  └──────────────┘  └──────────────┘  └───────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────────┘
                            │ WAV file
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   whisper.cpp (main.exe)                    │
│                      CPU-based STT                          │
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
2. Lädt aktuelle Konfiguration aus `config.json`
3. Aktualisiert User-Preference
4. Gibt Bestätigung aus

**Datenstruktur:**
```json
{
  "default_model": "base",
  "user_preferences": {
    "user_123": "small"
  }
}
```

### 2. Transcription Engine (`transcribe.py`)

Kernkomponente für Speech-to-Text.

**Features:**
- Automatische Audio-Konvertierung (FFmpeg)
- Whisper.cpp Integration via Subprocess
- Keine Python-ML-Dependencies nötig
- Temp-Datei Cleanup nach jeder Transkription

**Ablauf:**
1. Ermittelt User-Modell aus `config.json`
2. Prüft ob `ggml-{model}.bin` existiert
3. Konvertiert Input zu WAV (16kHz, mono) via FFmpeg
4. Ruft `~/.openclaw/whisper/main.exe` mit passenden Argumenten
5. Parsed den stderr-Output von whisper.cpp
6. Gibt reinen Text zurück
7. Löscht temporäre WAV-Datei

**whisper.cpp Aufruf:**
```bash
main.exe -m models/ggml-base.bin -f temp.wav -l de -nt -t 8
```

### 3. Telegram Handler (`telegram_handler.py`)

Interface zwischen Telegram und Transcription Engine.

**Input-Methoden:**
1. Datei als Kommandozeilen-Argument
2. Env-Variable `TELEGRAM_AUDIO_FILE`
3. Automatische Suche in `~/.openclaw/media/inbound`

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
transcribe_audio() → main.exe → Text
  ↓
Cleanup → Ausgabe an Agent
```

## Konfiguration

### Datei: `config.json`

```json
{
  "default_model": "base",
  "models": {
    "base": {"size": "base"},
    "small": {"size": "small"},
    "medium": {"size": "medium"}
  },
  "telegram": {
    "delete_after_transcribe": true,
    "max_duration": 600
  }
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
~/.openclaw/whisper/
├── main.exe
├── whisper.dll
├── SDL2.dll
└── models/
    ├── ggml-base.bin      (~147 MB)
    ├── ggml-small.bin     (~466 MB)
    └── ggml-medium.bin    (~1.5 GB)
```

## Fehlerbehandlung

### Häufige Fehler

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `FFmpeg not found` | Nicht installiert | `winget install Gyan.FFmpeg` |
| `Model not found` | Download fehlgeschlagen | `python scripts/install.py` |
| `main.exe fehlt` | Binary verschoben/gelöscht | whisper.zip extrahieren |
| `Audio too long` | >10 Minuten | Audio kürzen oder Limit erhöhen |

### Fallback-Strategien

1. **Modell fehlt** → Klare Fehlermeldung mit Hinweis auf `install.py`
2. **FFmpeg fehlt** → Klare Fehlermeldung mit Installationsanweisung
3. **Transkription fehlgeschlagen** → whisper.cpp stderr wird weitergegeben

## Performance

### CPU-Modus
- Keine GPU-Dependencies
- whisper.cpp ist hochoptimiert für CPU (AVX, AVX2, FMA)
- Base-Modell läuft in Echtzeit auf i7-6820HK

### Threads
- Standard: 8 Threads (entsprechend i7-6820HK)
- whisper.cpp skaliert gut mit mehr Threads

## Sicherheit & Privacy

1. **Lokale Verarbeitung**: Keine Daten verlassen den PC
2. **Temp-Dateien**: Sofortiges Löschen nach Transkription
3. **No Logging**: Audio-Inhalte werden nicht geloggt
4. **User-Isolation**: Pro-User Model-Preferences

## Erweiterungen

### Mögliche Verbesserungen

1. **Speaker Diarization**: "Wer hat was gesagt?"
2. **Realtime-Streaming**: Live-Transkription via stream.exe
3. **Batch-Processing**: Mehrere Audios parallel
4. **Custom Vocabulary**: Domänenspezifische Begriffe via Prompt
5. **Post-Processing**: Autokorrektur, Formatierung

## Testing

### Manuelle Tests

```bash
# 1. Installation testen
python scripts/install.py

# 2. Modell-Wechsel testen
python scripts/command_handler.py langsam
python scripts/command_handler.py status

# 3. Transkription testen
python scripts/transcribe.py test-audio.wav

# 4. Telegram-Flow testen
python scripts/telegram_handler.py test-audio.ogg
```

### Automatisierte Tests

```python
def test_model_switching():
    set_user_model("test_user", "base")
    assert get_user_model("test_user") == "base"

def test_transcription():
    text, meta = transcribe_audio("test.wav", "base")
    assert len(text) > 0
```

## Troubleshooting

### Debug-Modus aktivieren

```bash
set WHISPER_DEBUG=1
python scripts/transcribe.py audio.wav
```

### whisper.cpp direkt testen

```bash
cd ~/.openclaw/whisper
main.exe -m models/ggml-base.bin -f test.wav -l de -nt
```

## Lizenz & Credits

- **whisper.cpp**: MIT License (https://github.com/ggerganov/whisper.cpp)
- **OpenAI Whisper**: MIT License
- **Dieser Skill**: MIT License
