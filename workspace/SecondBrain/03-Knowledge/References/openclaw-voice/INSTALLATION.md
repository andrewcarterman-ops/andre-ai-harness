# OpenClaw Voice Bridge - Installationsanleitung

## Übersicht

Dieses Setup ermöglicht lokale Sprachinteraktion mit einem KI-Assistenten:
- **STT**: Whisper.cpp (Deutsch/Englisch)
- **LLM**: Llama 3.1 8B (lokal)
- **TTS**: Piper (deutsche Stimme)

**Hardware-Anforderungen**: Getestet auf i7-6820HK + GTX 980M (8GB VRAM)

---

## Schritt 1: Python-Umgebung einrichten

### 1.1 Python 3.10+ installieren
```bash
# Prüfe Version
python --version

# Falls < 3.10: Download von python.org
```

### 1.2 Virtuelle Umgebung erstellen
```bash
# Erstelle Ordner
mkdir C:\openclaw-voice
cd C:\openclaw-voice

# Virtuelle Umgebung
python -m venv venv

# Aktivieren
venv\Scripts\activate
```

### 1.3 Abhängigkeiten installieren
```bash
pip install pyaudio keyboard numpy requests
```

**Falls pyaudio Probleme macht:**
```bash
# Windows: Lade whl von https://www.lfd.uci.edu/~gohlke/pythonlibs/#pyaudio
pip install PyAudio-0.2.11-cp310-cp310-win_amd64.whl
```

---

## Schritt 2: Modelle und Binaries herunterladen

### 2.1 Ordnerstruktur erstellen
```
C:\openclaw-voice\
├── voice_bridge.py
├── voice_config.json
├── whisper\
│   └── main.exe
├── llama\
│   └── llama-server.exe
├── piper\
│   └── piper.exe
└── models\
    ├── ggml-medium.bin
    ├── Llama-3.1-8B-Instruct-Q4_K_M.gguf
    └── de_DE-thorsten-high.onnx
```

### 2.2 Whisper.cpp herunterladen
```bash
# 1. Gehe zu: https://github.com/ggerganov/whisper.cpp/releases
# 2. Lade "whisper-bin-x64.zip" herunter
# 3. Extrahiere main.exe nach C:\openclaw-voice\whisper\

# Modell herunterladen (1.5 GB)
curl -L -o models/ggml-medium.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin
```

### 2.3 llama.cpp herunterladen
```bash
# 1. Gehe zu: https://github.com/ggerganov/llama.cpp/releases
# 2. Lade "llama-bXXXX-bin-win-avx2-x64.zip" herunter
# 3. Extrahiere llama-server.exe nach C:\openclaw-voice\llama\

# Modell herunterladen (4.7 GB)
curl -L -o models/Llama-3.1-8B-Instruct-Q4_K_M.gguf https://huggingface.co/bartowski/Llama-3.1-8B-Instruct-GGUF/resolve/main/Llama-3.1-8B-Instruct-Q4_K_M.gguf
```

### 2.4 Piper TTS herunterladen
```bash
# 1. Gehe zu: https://github.com/rhasspy/piper/releases
# 2. Lade "piper_windows_amd64.zip" herunter
# 3. Extrahiere piper.exe nach C:\openclaw-voice\piper\

# Deutsche Stimme herunterladen
curl -L -o models/de_DE-thorsten-high.onnx https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/de/de_DE/thorsten/high/de_DE-thorsten-high.onnx
curl -L -o models/de_DE-thorsten-high.onnx.json https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/de/de_DE/thorsten/high/de_DE-thorsten-high.onnx.json
```

---

## Schritt 3: Konfiguration anpassen

Öffne `voice_config.json` und passe Pfade an:

```json
{
  "whisper_exe": "C:\\openclaw-voice\\whisper\\main.exe",
  "whisper_model": "C:\\openclaw-voice\\models\\ggml-medium.bin",
  "llama_server": "C:\\openclaw-voice\\llama\\llama-server.exe",
  "llama_model": "C:\\openclaw-voice\\models\\Llama-3.1-8B-Instruct-Q4_K_M.gguf",
  "piper_exe": "C:\\openclaw-voice\\piper\\piper.exe",
  "piper_model": "C:\\openclaw-voice\\models\\de_DE-thorsten-high.onnx",
  
  "ptt_key": "f12",
  "toggle_mode": true,
  "language": "de"
}
```

---

## Schritt 4: Starten

### 4.1 Voice Bridge starten
```bash
# Aktiviere Umgebung
cd C:\openclaw-voice
venv\Scripts\activate

# Starte
python voice_bridge.py
```

### 4.2 Bedienung
- **F12**: Starte/Stoppe Aufnahme (Toggle-Modus)
- **ESC**: Beende Programm
- **Overlay**: Zeigt aktuellen Status an

---

## Fehlerbehebung

### Problem: "CUDA out of memory"
**Lösung**: Reduziere GPU-Layer im llama-server:
```json
"llama_server_args": ["-ngl", "20"]  // Statt 99
```

### Problem: "Whisper nicht gefunden"
**Lösung**: Prüfe Pfade in `voice_config.json`, verwende doppelte Backslashes (`\\`)

### Problem: "Kein Mikrofon erkannt"
**Lösung**: 
```python
# Liste Geräte auf
import pyaudio
p = pyaudio.PyAudio()
for i in range(p.get_device_count()):
    print(f"{i}: {p.get_device_info_by_index(i)['name']}")
```

### Problem: "Piper spielt kein Audio ab"
**Lösung**: Installiere ffplay (Teil von FFmpeg) oder passe `_play_audio` Methode an

---

## Optimierung für GTX 980M

### VRAM-Nutzung minimieren
1. **Whisper auf CPU laufen lassen** (langsamer, aber spart VRAM):
   ```json
   "whisper_args": ["-ngl", "0"]
   ```

2. **Kleinere LLM-Alternative**:
   - Phi-3 mini (3.8B) statt Llama 3.1 8B
   - Mistral 7B mit Q3_K_M Quantisierung

3. **Sequentielle Verarbeitung** (Standard im Skript):
   - Whisper lädt → transkribiert → entlädt
   - Llama lädt → generiert → entlädt
   - Piper lädt → synthetisiert → entlädt

---

## Nächste Schritte

1. **Hybrid-Modus**: Verbinde mit OpenClaw Gateway (Port 18789)
2. **Wake Word**: Ersetze F12 durch "Hey Claw" (mit Porcupine)
3. **Mehr Sprachen**: Füge englische TTS-Stimme hinzu
4. **Kontext-Memory**: Speichere Konversationshistorie

---

## Ressourcen

- **Whisper.cpp**: https://github.com/ggerganov/whisper.cpp
- **llama.cpp**: https://github.com/ggerganov/llama.cpp
- **Piper TTS**: https://github.com/rhasspy/piper
- **Modelle**: https://huggingface.co
