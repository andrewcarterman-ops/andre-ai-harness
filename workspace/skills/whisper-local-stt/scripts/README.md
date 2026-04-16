# Voice Bridge - Finale Dokumentation

> **Status:** ✅ Alle 4 Phasen funktionsfähig  
> **Empfohlenes Modell:** `medium` (beste Erkennung)  
> **Betriebszeit:** 14 Stunden (09:30 - 23:26)

---

## Was ist Voice Bridge?

**ENTER-to-Talk System:**
1. ENTER drücken → Sprich etwas
2. ENTER drücken → Aufnahme stoppt
3. Automatische Transkription (Whisper.cpp)
4. Andrew antwortet (TTS mit Piper)
5. Audio wird direkt auf dem PC abgespielt

---

## Verfügbare Scripts

| Script | Modell | Verwendung |
|--------|--------|------------|
| `voice_bridge.py` | **medium** ⭐ | **HAUPTSCRIPT** - Beste Qualität |
| `voice_bridge_small.py` | small | Balance (schneller) |
| `voice_bridge_clean.py` | base | Schnellste, aber mindere Qualität |
| `voice_bridge_medium.py` | medium | Identisch zu voice_bridge.py |

**Empfehlung:** Nutze immer `voice_bridge.py` (medium Modell)

---

## Installation (Voraussetzungen)

### 1. Whisper.cpp
```powershell
# Modelle vorhanden in:
~/.openclaw/whisper/models/
├── ggml-base.bin   (75 MB)
├── ggml-small.bin  (465 MB)
└── ggml-medium.bin (1463 MB) ⭐ empfohlen
```

### 2. Piper TTS
```powershell
# Installiert in:
~/.openclaw/piper/
# Stimme: de_DE-thorsten-high (~110 MB)
```

### 3. Python Dependencies
```powershell
pip install sounddevice numpy
```

---

## Verwendung

### Schnellstart (Empfohlen)
```powershell
python "C:\Users\andre\.openclaw\workspace\skills\whisper-local-stt\scripts\voice_bridge.py"
```

### Workflow
```
[Drücke ENTER zum Sprechen...]
🔴 NIMMT AUF... (sprich jetzt!)
[Drücke ENTER zum Beenden...]

✅ Aufnahme: 4.2s
🔄 Transkribiere... (ca. 20-30 Sekunden bei medium)

============================================================
📝 DU: Hallo Andrew, das ist ein Test
============================================================

💬 ANDREW: Ich habe verstanden: Hallo Andrew, das ist ein Test

🎵 Generiere Sprache...
🔊 Spiele ab...
✅ Fertig!
```

---

## Modell-Vergleich

| Modell | Größe | Geschwindigkeit (i7-6820HK) | Qualität | Wann nutzen? |
|--------|-------|----------------------------|----------|--------------|
| **medium** | 1.5 GB | 20-40s | ⭐⭐⭐⭐⭐ **BESTE** | **Immer** (empfohlen) |
| small | 465 MB | 10-20s | ⭐⭐⭐⭐ Gut | Wenn medium zu langsam |
| base | 75 MB | 3-5s | ⭐⭐⭐ Okay | Nur für Tests |

**Wichtig:** `medium` liefert deutlich bessere Ergebnisse bei komplexen Sätzen!

---

## Tipps für beste Erkennung

1. **Mikrofon-Lautstärke:** In Windows auf 80-100% setzen
2. **Sprechweise:** Laut, deutlich, etwas langsamer
3. **Hintergrund:** Leise Umgebung (kein Musiklautsprecher)
4. **Abstand:** 20-30cm vom Mikrofon entfernt
5. **Geduld:** Medium braucht Zeit (20-40s) - das ist normal!

---

## Troubleshooting

### "Mikrofon nicht verfügbar"
→ Windows Privacy Settings → Mikrofon → Apps erlauben
→ ODER: Programme schließen die das Mikrofon blockieren (Discord, etc.)

### "Kein Text erkannt"
→ Lauter sprechen
→ Deutlicher sprechen
→ Aufnahmezeit > 2 Sekunden

### "Transkription dauert ewig"
→ Das ist bei `medium` normal (20-40s)
→ Für schnellere Ergebnisse: `voice_bridge_small.py` nutzen

### TTS wird nicht abgespielt
→ `sounddevice` installiert? `pip install sounddevice`
→ Lautsprecher korrekt in Windows eingestellt?

---

## Architektur

```
┌─────────────────┐
│   ENTER Taste   │
└────────┬────────┘
         │
    ┌────▼────┐
    │ Aufnahme │ ← Mikrofon (16kHz, mono)
    └────┬────┘
         │
    ┌────▼────┐
    │   WAV    │
    └────┬────┘
         │
┌────────▼────────┐
│  Whisper.cpp    │ ← medium Modell
│  Transkription  │
└────────┬────────┘
         │
    ┌────▼────┐
    │  Text   │
    └────┬────┘
         │
┌────────▼────────┐
│  Piper TTS      │ ← de_DE-thorsten-high
│  Sprachsynthese │
└────────┬────────┘
         │
    ┌────▼────┐
    │  Audio  │ ← Lautsprecher
    └─────────┘
```

---

## Projekt-Phasen (Abgeschlossen)

- ✅ **Phase 1:** Telegram Voice Loop
- ✅ **Phase 2:** Intelligente Modell-Auswahl (base/small/medium)
- ✅ **Phase 3:** Lokale PTT (ENTER-to-Talk)
- ✅ **Phase 4:** TTS Rückkanal + Direktes Abspielen
- ⏸️ **Phase 5:** Unified Dashboard (optional, nicht benötigt)

---

## Nächste Schritte (für später)

1. **F12-Hotkey** (statt ENTER) - wenn gewünscht, aber komplexer
2. **Integration** mit OpenClaw Sessions (Session-Injection)
3. **Konfig-Datei** für persönliche Einstellungen

---

## Dateien

**Ort:** `~/.openclaw/workspace/skills/whisper-local-stt/scripts/`

| Datei | Zweck |
|-------|-------|
| `voice_bridge.py` | **HAUPTSCRIPT** (medium) |
| `voice_bridge_medium.py` | Medium-Version |
| `voice_bridge_small.py` | Small-Version (schneller) |
| `voice_bridge_clean.py` | Base-Version (schnellste) |
| `transcribe.py` | Whisper.cpp Wrapper |
| `piper_tts.py` | TTS Helper |
| `install.py` | Modell-Downloader |
| `check_mic.py` | Mikrofon-Test |

---

## Erfolgsquote

| Test | Ergebnis |
|------|----------|
| 4.2s Audio, "Hallo Test" | ✅ Perfekt erkannt |
| 6.4s Audio, komplexer Satz | ✅ Mit medium: "Hallo, das ist ein schwerer Test..." |
| TTS-Ausgabe | ✅ Wird direkt abgespielt |

**Fazit:** System funktionsfähig und einsatzbereit!

---

*Dokumentation erstellt: 14.04.2026, 23:26 Uhr*  
*Gesamtarbeitszeit: ~14 Stunden*
