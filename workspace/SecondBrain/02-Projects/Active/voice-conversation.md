# Voice Conversation mit Andrew

> **Ziel:** Mit Andrew verbal kommunizieren koennen — sowohl ueber Telegram als auch lokal per Push-to-Talk auf dem PC.

**Status:** Active — Planung abgeschlossen, Implementierung pending  
**Prioritaet:** Hoch  
**Erstellt:** 14-04-2026  
**Letzte Aktualisierung:** 14-04-2026  

---

## Vision

Statt jedes Mal zu tippen, kann Parzival mit Andrew sprechen. Das System funktioniert in zwei Modi:

1. **Telegram Voice-Loop** — Von unterwegs oder bequem vom Sofa aus. Voice Message aufnehmen, Andrews Antwort als Voice-Note zurueck erhalten.
2. **Lokale PTT-Bridge** — Am PC am Arbeiten. `F12` druecken, sprechen, loslassen. Andrew hoert zu und antwortet lokal als Audio.

---

## Architektur-Entscheidungen

| Entscheidung | Wahl | Begruendung |
|--------------|------|-------------|
| **STT-Engine** | `whisper.cpp` (`main.exe`, CPU) | Bereits installiert, 100% lokal, keine Cloud |
| **TTS Phase 1 (Telegram)** | OpenClaw `tts`-Tool | Integriert, hochwertig, funktioniert sofort |
| **TTS Phase 2 (PTT)** | Hybrid: `pyttsx3` (Fallback) + Datei-Polling (Premium) | Schnelle lokale Antworten + Option fuer bessere Qualitaet |
| **Sprache** | Deutsch (`de`) | Parzivals Praeferenz |
| **PTT-Taste** | `F12` | Leicht erreichbar, selten anderweitig belegt |
| **Aktivierung PTT** | Manuelles Starten/Beenden des Scripts | Respektiert Ressourcen, kein Hintergrund-Bloat |

---

## Phasen-Uebersicht

| Phase | Titel | Status | Ziel |
|-------|-------|--------|------|
| 1 | Telegram Voice-Loop MVP | Offen | Voice Messages in Telegram werden transkribiert und beantwortet |
| 2 | Voice-Loop Hardening | Offen | Unterbrechungen, Modell-Wechsel, Fehlerhandling, Logging |
| 3 | Lokale PTT-Bridge — Aufnahme | Offen | `F12` nimmt Audio auf, transkribiert und sendet Text an Session |
| 4 | Lokale PTT-Bridge — Antwort | Offen | Antwort kommt als lokales Audio zurueck |
| 5 | Unified Voice Control | Offen | Gemeinsame Einstellungen, Status-Dashboard, Statistiken |

---

## Detaillierte Phasen-Erklaerung

### Grundprinzip: Vertikale Slices (Anti-Stalling by Design)

Jede Phase ist ein duenner, aber kompletter Durchstich durch alle Schichten. Keine Phase endet mit "hier fehlt noch etwas". Wenn eine Phase fertig ist, funktioniert sie end-to-end und kann demonstriert werden. Das verhindert, dass wir in endlosen Vorbereitungen versinken.

---

### Phase 1: Telegram Voice-Loop MVP

**Wofuer sie ist:** Schneller, sichtbarer Erfolg. Wir nutzen die existierende Infrastruktur (Telegram, OpenClaw, whisper.cpp, `tts`-Tool), um den einfachsten Voice-Loop zu bauen. Parzival spricht in Telegram, Andrew antwortet als Voice-Note.

**Was sie konkret macht:**
1. Voice Message in Telegram wird empfangen.
2. `telegram_handler.py` konvertiert `.ogg` zu `.wav` und ruft `transcribe.py` auf.
3. Der transkribierte Text landet in Andrews Session.
4. Andrew generiert eine textuelle Antwort.
5. Die Antwort wird per `tts`-Tool in Audio umgewandelt.
6. Die Audio-Datei wird als Voice-Note zurueck an Telegram gesendet.
7. Temp-Dateien werden geloescht.

**Definition of Done:** Parzival sendet eine Voice Message in Telegram und erhaelt innerhalb von 15 Sekunden eine Audio-Antwort von Andrew.

---

### Phase 2: Voice-Loop Hardening

**Wofuer sie ist:** Produktionsreife. Der MVP aus Phase 1 ist bruechig — er crasht bei Fehlern, hat keinen State, laesst sich nicht unterbrechen. Phase 2 macht ihn robust.

**Was sie konkret macht:**
- `state.json` trackt, ob gerade eine Antwort generiert wird.
- Neue Voice Message bricht die laufende TTS-Ausgabe ab.
- `/voice schnell`, `/voice mittel`, `/voice langsam` fuer on-the-fly Modell-Wechsel.
- Retry-Logik bei Transkriptions-Fehlern (Fallback auf `base`).
- JSONL-Logging fuer Transkriptionen (Dauer, Modell, Erfolg).

**Definition of Done:** Parzival kann Andrew waehrend einer Antwort mit einer neuen Voice Message unterbrechen, den Modus wechseln, und das System laeuft 24h stabil.

---

### Phase 3: Lokale PTT-Bridge — Aufnahme

**Wofuer sie ist:** Das echte Ziel — PC-basiertes Sprechen ohne App zu oeffnen.

**Was sie konkret macht:**
- Python-Script `voice-bridge.py` laeuft im Terminal.
- Lauscht auf `F12` (via `keyboard` oder `pynput`).
- Nimmt Audio vom Mikrofon auf, solange `F12` gedrueckt ist.
- Konvertiert zu WAV, transkribiert mit whisper.cpp.
- Injiziert den Text in die laufende OpenClaw-Session (TUI oder Webchat).

**Definition of Done:** Parzival drueckt `F12`, spricht einen Satz, laesst los — und innerhalb von 5 Sekunden erscheint der transkribierte Text in Andrews aktueller Session.

---

### Phase 4: Lokale PTT-Bridge — Antwort-Rueckkanal

**Wofuer sie ist:** Die Antwort kommt nicht als Text, sondern als Audio zurueck — kein Blick auf den Bildschirm noetig.

**Was sie konkret macht:**
- Kurze Antworten (<150 Zeichen): Sofortige lokale TTS via `pyttsx3` (Windows SAPI5).
- Lange Antworten: Andrew generiert hochwertige Audio mit `tts`-Tool in `~/.openclaw/voice/outbox/`.
- `voice-bridge.py` pollt den Ordner alle 500ms und spielt neue Dateien ab.
- Wiedergabe kann durch erneutes `F12`-Druecken abgebrochen werden.

**Definition of Done:** Parzival drueckt `F12`, fragt etwas, und Andrews Antwort wird als Audio aus den Lautsprechern wiedergegeben — ohne Bildschirm-Kontakt.

---

### Phase 5: Unified Voice Control

**Wofuer sie ist:** Zusammenfuehren und Polieren. Telegram und PTT teilen sich Einstellungen, ein Dashboard zeigt den Status, und alles ist dokumentiert.

**Was sie konkret macht:**
- Einheitliche `config.json` mit Sektionen `voice_loop`, `ptt_bridge`, `tts`, `statistics`.
- Terminal-Dashboard (`rich`) mit Live-Status, aktuellem Modell, heutigen Statistiken.
- JSONL-Statistiken ueber 30 Tage.
- `README.md` + `SKILL.md` aktualisieren.

**Definition of Done:** Parzival kann sowohl Telegram als auch PTT nutzen, beide teilen sich die Einstellungen, und das Dashboard zeigt auf einen Blick den System-Status.

---

## Anti-Stalling-Regeln

| Regel | Umsetzung |
|-------|-----------|
| **Zeitboxen** | Jede technische Unbekannte bekommt max. 20-30 Minuten. Dann Workaround oder naechste Option. |
| **Fallback-Hierarchien** | Fuer jede kritische Komponente gibt es 2-3 Alternativen. |
| **GO nach jeder Phase** | Kein automatischer Uebergang. Parzival gibt explizit GO. |
| **Keine Perfektion vor Funktion** | "Haesslich aber funktioniert" schlaegt "elegant aber unfertig". |
| **Tägliche Check-ins** | Wenn eine Phase laenger dauert als erwartet, wird der Scope angepasst. |
| **Vermeide Vorbereitungen auf Vorbereitungen** | Direkt Prototyp bauen. Keine 50-seitigen Spezifikationen vorher. |

---

## Offene Tasks

### Phase 1
- [ ] `telegram_handler.py` mit OpenClaw Message-Loop verbinden
- [ ] Test-End-to-End: Voice Message -> Transkription -> Antwort -> Voice-Note
- [ ] `config.json` erweitern (Voice-Loop-spezifische Flags)

### Phase 2
- [ ] Unterbrechungs-Handling bauen (neue Voice Message bricht laufende Antwort ab)
- [ ] `/voice` Befehle fuer Modell-Wechsel
- [ ] Retry-Logik bei Transkriptions-Fehlern
- [ ] Statistik-Logging (Anzahl Transkriptionen, durchschnittliche Dauer)

### Phase 3
- [ ] `voice-bridge.py` erstellen (Mikrofon-Aufnahme, PTT mit `keyboard` + `pyaudio`)
- [ ] Audio-Buffering und Silence-Detection
- [ ] Verbindung zu laufender OpenClaw-Session herstellen

### Phase 4
- [ ] `pyttsx3` als schnellen TTS-Fallback integrieren
- [ ] Datei-Polling fuer hochwertige TTS-Antworten bauen
- [ ] Audio-Wiedergabe (Windows Media Player oder `playsound`)

### Phase 5
- [ ] Gemeinsame Config fuer Telegram + PTT
- [ ] Terminal-Dashboard fuer Voice-Status
- [ ] Dokumentation aktualisieren

---

## Bekannte Risiken

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| `pyaudio` laesst sich nicht unter Windows installieren | Mittel | Hoch | Fallback auf `sounddevice` oder `python-sounddevice` |
| `keyboard` erfordert Admin-Rechte fuer globale Hotkeys | Mittel | Mittel | `F12` als lokaler Hotkey im Fokus-Fenster nutzen |
| OpenClaw Session-ID ist schwer zu ermitteln fuer PTT | Mittel | Hoch | Session-File oder Named Pipe als Kommunikationskanal |
| Rate-Limits bei Kimi verzoegern Antworten | Hoch | Mittel | Lokale TTS gibt Bestaetigung, waehrend Cloud-Antwort generiert wird |

---

## Ressourcen

- **whisper.cpp Binary:** `~/.openclaw/whisper/main.exe`
- **Modelle:** `~/.openclaw/whisper/models/ggml-base.bin` (small + medium pending)
- **Skill-Code:** `~/.openclaw/workspace/skills/whisper-local-stt/`
- **Detaillierter Plan:** `~/.openclaw/workspace/plans/voice-conversation.md`

---

## Lessons Learned (laufend)

- 14-04-2026: Whisper.cpp ist CPU-only kompiliert (`CUDA = 0`), aber fuer Sprachnachrichten voellig ausreichend.
- 14-04-2026: Die urspruenglichen Python-Scripts waren fuer `faster-whisper` geschrieben, passten nicht zu den existierenden Binaries. Komplette Umschreibung auf whisper.cpp noetig.
