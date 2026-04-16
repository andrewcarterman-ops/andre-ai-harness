# OpenClaw Voice Bridge 🎙️

Lokales Sprachinterface für KI-Assistenten mit:
- **STT**: Whisper.cpp (Deutsch/Englisch)
- **LLM**: Llama 3.1 8B (lokal, offline)
- **TTS**: Piper (deutsche Stimme)

## Schnellstart

```powershell
# Als Administrator ausführen
.\install.ps1
```

Oder manuell:
```bash
pip install pyaudio keyboard numpy requests
python voice_bridge.py
```

## Bedienung

| Taste | Funktion |
|-------|----------|
| **F12** | Aufnahme starten/stoppen (Toggle) |
| **ESC** | Programm beenden |

## Features

✅ **100% Offline** - Kein Internet nötig  
✅ **Low Latency** - ~1-3 Sekunden Gesamtzeit  
✅ **Deutsch/Englisch** - Automatische Spracherkennung  
✅ **Visual Feedback** - Status-Overlay  
✅ **Toggle/PTT** - F12 als Toggle oder Hold-to-Talk  

## Systemanforderungen

- **CPU**: Intel i7-6820HK oder besser
- **RAM**: 16GB+ (32GB empfohlen)
- **GPU**: NVIDIA mit 8GB+ VRAM
- **Speicher**: ~10GB für Modelle
- **OS**: Windows 10/11

## Architektur

```
🎙️ Mikrofon → Whisper.cpp (STT) → Llama 3.1 (LLM) → Piper (TTS) → 🔊 Lautsprecher
```

## Konfiguration

Passe `voice_config.json` an:

```json
{
  "ptt_key": "f12",
  "toggle_mode": true,
  "language": "de",
  "max_tokens": 512
}
```

## Fehlerbehebung

**"CUDA out of memory"** → Reduziere GPU-Layer oder nutze CPU für Whisper

**"Kein Mikrofon"** → Prüfe Windows-Audioeinstellungen

**"Piper spielt nicht ab"** → Installiere FFmpeg

## Lizenz

MIT - Frei verwendbar und modifizierbar.

---

Entwickelt für OpenClaw mit Fokus auf Qualität und Datenschutz.
