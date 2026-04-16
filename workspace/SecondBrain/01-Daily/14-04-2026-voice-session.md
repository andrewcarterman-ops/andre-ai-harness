# Voice Conversation Project - Session Log 14-04-2026

> **Projekt:** Voice Conversation mit Andrew  
> **Datum:** 14-04-2026  
> **Zeitraum:** ~09:30 - 16:30 (7 Stunden)  
> **Agent:** andrew-main  
> **Status:** Phase 1 MVP code-complete, 3 Extra-Schritte offen

---

## Was wir heute erreicht haben

### 1. Whisper.cpp Konsolidierung ✅
- **Problem:** Python-Scripts waren für `faster-whisper`, aber Binaries waren `whisper.cpp`
- **Lösung:** Alle Scripts auf whisper.cpp umgeschrieben
  - `transcribe.py` - ruft jetzt `main.exe` via subprocess
  - `install.py` - lädt GGUF-Modelle von HuggingFace
  - `command_handler.py` - Emoji-Bug gefixt, Config-Pfade korrigiert
  - `telegram_handler.py` - Emoji-Bug gefixt, `expanduser()` hinzugefügt
- **Test:** Erfolgreich, Voice Message transkribiert zu "Hallo, kannst du diese Sprachnachricht kennen?"

### 2. Piper TTS Installation ✅
- **Pfad:** `~/.openclaw/piper/`
- **Stimme:** `de_DE-thorsten-high` (110MB)
- **Performance:** 0.54x Echtzeit (schneller als Audio selbst)
- **Helper:** `piper_tts.py` gebaut - generiert WAV in `voice/outbox/`
- **Test:** Erfolgreich, "Hallo, das ist ein Test" generiert

### 3. Voice Bridge Simple ✅
- **Pfad:** `~/.openclaw/workspace/skills/whisper-local-stt/scripts/voice_bridge_simple.py`
- **Funktion:**
  1. Pollt `media/inbound/` auf neue .ogg Dateien
  2. Transkribiert automatisch mit whisper.cpp
  3. Zeigt Nachricht im Terminal: `[NEUE NACHRICHT] ID: ... [TEXT] ...`
  4. Wartet auf Antwort in `voice/outbox/responses/{id}.txt`
  5. Generiert automatisch TTS mit Piper
  6. Legt Voice-Note in `voice/ready_to_send/` ab
- **Timeout:** Korrigiert 30s → 120s für whisper.cpp erstes Laden

### 4. Projekt-Dokumentation ✅
- `SecondBrain/02-Projects/Active/voice-conversation.md` - Projekt-Overview
- `~/.openclaw/workspace/plans/voice-conversation.md` - Detaillierter 5-Phasen-Plan
- `SecondBrain/00-Meta/Templates/llm-planning-prompt.md` - Für zukünftige LLM-Anfragen
- `whisper-local-stt` in `registry/skills.yaml` eingetragen

### 5. Kritische Analyse Fremdplan ✅
- `SecondBrain/03-Knowledge/References/openclaw-voice/` analysiert
- **Urteil:** Falscher Ansatz - baut isolierten Llama-Chatbot statt Brücke zu Andrew
- **Wiederverwendbar:** AudioRecorder, StatusOverlay, PiperTTS-Code

---

## Phase 1 Status: Code-Complete

### Was funktioniert (100%)
- ✅ Whisper.cpp konsolidiert
- ✅ Piper TTS installiert & getestet
- ✅ Voice Bridge Simple Script gebaut
- ✅ Timeout auf 120s erhöht

### Was blockiert
- 🔴 Gateway-Instabilität (SIGKILL bei Status-Abfrage)
- 🔴 Telegram-Bot hat Polling-Stalls (automatischer Reconnect)

---

## Phase 1 - 3 Extra Schritte bis Fertigstellung

### Schritt 1: Gateway stabilisieren 🔴 KRITISCH

**Problem:**
- `openclaw gateway status` crasht mit SIGKILL
- Token-Mismatch Fehler in Logs
- Mehrere Node-Prozesse laufen gleichzeitig

**Lösungsoptionen:**

**Option A: Quick Reset (versuchen zuerst)**
```powershell
openclaw gateway stop
Get-Process -Name "node" | Stop-Process -Force
openclaw gateway start
```

**Option B: Config Reset (falls A nicht hilft)**
```powershell
# Backup
Copy-Item "$env:USERPROFILE\.openclaw\openclaw.json" "$env:USERPROFILE\.openclaw\openclaw.json.backup"

# Reset
openclaw gateway stop
Remove-Item "$env:USERPROFILE\.openclaw\openclaw.json" -Force
openclaw gateway start  # Generiert neue Config
```

**Option C: Full Reinstall (letzter Ausweg)**
```powershell
npm uninstall -g openclaw
npm install -g openclaw
```

**Erfolgskriterium:** `openclaw gateway status` läuft ohne SIGKILL

---

### Schritt 2: Live-Test durchführen 🔄

**Nach Gateway-Fix:**

```powershell
# 1. Voice Bridge starten
python "$env:USERPROFILE\.openclaw\workspace\skills\whisper-local-stt\scripts\voice_bridge_simple.py"

# 2. Voice Message in Telegram an OpenClaw-Bot schicken

# 3. Im Terminal sollte erscheinen:
#    [NEUE NACHRICHT] ID: msg_...
#    [TEXT] (was du gesagt hast)
#    Antwort schreiben in: C:\Users\...\responses\msg_....txt

# 4. Antwort schreiben:
notepad "$env:USERPROFILE\.openclaw\voice\outbox\responses\msg_....txt"
#    (Text eingeben, speichern, schließen)

# 5. Automatisch generiert:
#    [VOICE-NOTE BEREIT] C:\Users\...\ready_to_send\msg_..._response.wav
```

**Erfolgskriterium:** Voice Message → Text → Antwort-Datei → WAV-Datei in `ready_to_send/`

---

### Schritt 3: README.md erstellen 📝

**Ort:** `~/.openclaw/workspace/skills/whisper-local-stt/README.md`

**Template:**
```markdown
# Voice Bridge Simple

Halb-automatischer Voice Loop für OpenClaw + Telegram.

## Installation

1. Piper TTS installieren (siehe `docs/piper-setup.md`)
2. Whisper.cpp Modelle downloaden: `python scripts/install.py`

## Usage

```powershell
python scripts/voice_bridge_simple.py
```

## Workflow

1. Voice Message in Telegram schicken
2. Transkription erscheint im Terminal
3. Antwort in `voice/outbox/responses/{id}.txt` schreiben
4. TTS wird automatisch generiert
5. WAV-Datei in `voice/ready_to_send/` liegt bereit

## Troubleshooting

- Timeout-Fehler: Timeout ist auf 120s gesetzt für erstes Laden
- Gateway-Probleme: Siehe Phase 1 Schritt 1 in Session-Log
```

---

## Definition of Done (Phase 1 - aktualisiert)

Phase 1 ist **code-complete** - funktioniert technisch, nur Gateway-Blocker:

| Checkpoint | Status |
|------------|--------|
| Whisper.cpp konsolidiert | ✅ Fertig |
| Piper TTS installiert | ✅ Fertig |
| Voice Bridge Simple Script | ✅ Fertig |
| Timeout auf 120s erhöht | ✅ Fertig |
| Gateway stabilisieren | 🔴 Extra Schritt 1 |
| Live-Test durchführen | 🔄 Extra Schritt 2 |
| README.md erstellen | 📝 Extra Schritt 3 |

**Phase 1 ist 100% fertig wenn:**
1. Gateway läuft stabil (keine SIGKILLs)
2. Voice Message in Telegram → Text erscheint im Terminal
3. Antwort-Datei → TTS generiert → `ready_to_send/*.wav` liegt bereit
4. README.md existiert

---

## Blocker & Probleme

### 1. Gateway-Instabilität 🔴 KRITISCH
- **Symptom:** `openclaw gateway status` crasht mit SIGKILL
- **Frequenz:** Regelmäßig während der Session
- **Impact:** Telegram-Voice-Messages können nicht verarbeitet werden
- **Vermutung:** Memory-Problem oder Auth/Token-Issue

### 2. Telegram-Bot Polling-Stalls 🟡
- **Symptom:** `polling stall detected` → `Network request failed`
- **Status:** Automatischer Reconnect funktioniert
- **Impact:** Temporäre Unterbrechungen

---

## Architektur-Entscheidungen (heute getroffen)

| Entscheidung | Wahl | Begründung |
|--------------|------|------------|
| STT-Engine | whisper.cpp (CPU) | Bereits installiert, 100% lokal |
| TTS-Engine | Piper (lokal) | Kein API-Key nötig, deutsche Stimme |
| Loop-Modus | Halb-automatisch | Session-Injection zu komplex für MVP |
| PTT-Taste | F12 | Leicht erreichbar |
| Pfad-Konvention | `$env:USERPROFILE` statt `~` | PowerShell-Kompatibilität |

---

## Nächste Phasen Überblick

### Phase 2: Hardening & Unterbrechungen
- [ ] `small` + `medium` Whisper-Modelle downloaden
- [ ] Audio-Längen-Check → Modell-Wechsel
- [ ] Fortschrittsanzeige während Transkription
- [ ] Unterbrechungen ermöglichen

### Phase 3: Lokale PTT-Bridge (F12)
- [ ] F12-Hotkey Listener bauen
- [ ] Lokale Audio-Aufnahme
- [ ] Direkte Session-Integration

### Phase 4: TTS-Antwort-Rückkanal
- [ ] `message` Tool mit `asVoice=True` testen
- [ ] ODER: Telegram Bot API für Voice-Senden
- [ ] Automatisches Senden der Voice-Note

### Phase 5: Unified Dashboard
- [ ] GUI/Status-Anzeige
- [ ] Session-Liste
- [ ] Sprachauswahl

---

## Ressourcen

| Komponente | Pfad | Status |
|------------|------|--------|
| Whisper.cpp | `~/.openclaw/whisper/main.exe` | ✅ |
| Piper TTS | `~/.openclaw/piper/piper/piper.exe` | ✅ |
| Voice Bridge | `~/.openclaw/workspace/skills/whisper-local-stt/scripts/voice_bridge_simple.py` | ✅ |
| Piper Modelle | `~/.openclaw/piper/models/de_DE-thorsten-high.onnx` | ✅ |
| Bridge-Outbox | `~/.openclaw/voice/outbox/` | ✅ |
| Bridge-Ready | `~/.openclaw/voice/ready_to_send/` | ✅ |
| Bridge-Inbox | `~/.openclaw/voice/inbox/` | ✅ |

---

## Commands Cheat Sheet

```powershell
# Gateway
openclaw gateway status
openclaw gateway stop
openclaw gateway start

# Voice Bridge
python "$env:USERPROFILE\.openclaw\workspace\skills\whisper-local-stt\scripts\voice_bridge_simple.py"
python "$env:USERPROFILE\.openclaw\workspace\skills\whisper-local-stt\scripts\voice_bridge_simple.py" --status

# Piper TTS Test
python "$env:USERPROFILE\.openclaw\workspace\skills\whisper-local-stt\scripts\piper_tts.py" "Hallo Test"

# Whisper Transkription
python "$env:USERPROFILE\.openclaw\workspace\skills\whisper-local-stt\scripts\transcribe.py" "C:\pfad\zu\audio.ogg"

# Logs prüfen
Get-Content "$env:USERPROFILE\.openclaw\voice\bridge.log" -Tail 20
```

---

## Lessons Learned (für zukünftige Sessions)

1. **Pfad-Expansion in PowerShell:** `$env:USERPROFILE` statt `~` verwenden
2. **Timeout für whisper.cpp:** Auf 120s setzen für erstes Laden auf CPU
3. **Gateway-Abhängigkeit:** Voice-Features brauchen stabiles Gateway
4. **Lokale TTS:** Piper funktioniert gut als Cloud-Alternative
5. **Phasen-Planung:** MVP zuerst, Integration später

---

*Session beendet: 14-04-2026 ~16:50*  
*Nächste Session: Phase 1 Extra-Schritte abschließen (Gateway fixen + Live-Test + README)*
