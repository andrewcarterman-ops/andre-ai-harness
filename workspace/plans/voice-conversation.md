# Plan: Voice Conversation mit Andrew

> **Quelle:** Parzivals Wunsch nach verbaler Kommunikation mit Andrew  
> **Strategie:** Vertikale Slices (Telegram zuerst, dann lokale PTT-Bridge)  
> **Erstellt:** 14-04-2026  
> **Projekt-Tracking:** `SecondBrain/02-Projects/Active/voice-conversation.md`

---

## Durable Architectural Decisions

| Decision | Choice |
|----------|--------|
| **STT Engine** | `whisper.cpp` (`main.exe`, CPU-Modus, 8 Threads) |
| **STT Modelle** | `base` (default), `small`, `medium` — lokal gespeichert |
| **TTS Phase 1 (Telegram)** | OpenClaw `tts`-Tool (cloud-basiert, z. B. ElevenLabs) |
| **TTS Phase 2 (PTT)** | Hybrid: `pyttsx3` (lokaler Fallback) + Datei-Polling fuer Premium-TTS |
| **Input Phase 1** | Telegram Voice Messages (`.ogg`) |
| **Input Phase 2** | Lokales Python-Script mit Push-to-Talk (`F12`) |
| **Sprache** | Deutsch (`de`) fuer STT, TTS-Stimme konfigurierbar |
| **PTT Aktivierung** | Manueller Start/Stop via PowerShell/Terminal |
| **Config** | `~/.openclaw/workspace/skills/whisper-local-stt/config.json` |
| **Projekt-Root** | `~/.openclaw/workspace/skills/whisper-local-stt/` |

---

## Phase 1: Telegram Voice-Loop MVP

**User Stories:**
- Als Parzival moechte ich in Telegram eine Voice Message aufnehmen, damit Andrew sie versteht.
- Als Parzival moechte ich Andrews Antwort als Voice-Note zurueck erhalten, damit ich nicht lesen muss.

### Was zu bauen ist

Eine vollstaendige End-to-End-Verbindung zwischen Telegram und Andrew:

1. **Empfang:** Telegram sendet eine `.ogg`-Voice-Message an OpenClaw.
2. **Transkription:** `telegram_handler.py` ermittelt die Datei, konvertiert sie mit FFmpeg zu WAV, und ruft `transcribe.py` mit `whisper.cpp` auf.
3. **Verarbeitung:** Der transkribierte Text wird als reguläre Nachricht an die aktuelle Session gesendet.
4. **Antwort:** Andrew generiert eine textuelle Antwort.
5. **TTS:** Die Antwort wird mit dem OpenClaw `tts`-Tool in Audio umgewandelt.
6. **Ruecksendung:** Die Audio-Datei wird als Voice-Note an Telegram zurueckgeschickt.
7. **Cleanup:** Temporaere Dateien werden geloescht.

### Akzeptanzkriterien

- [ ] Voice Message in Telegram wird zu >90% korrekt transkribiert (bei klarem Deutsch).
- [ ] Die Antwort erscheint innerhalb von 15 Sekunden nach Senden der Voice Message.
- [ ] Die Antwort wird als **Voice-Note** (nicht als Audio-Attachment) zurueckgesendet.
- [ ] Temporaere `.wav` und `.ogg` Dateien werden nach der Verarbeitung geloescht.
- [ ] Bei Transkriptions-Fehlern wird eine freundliche Fehlermeldung zurueckgesendet.

### Technische Notizen

- `telegram_handler.py` existiert bereits, muss aber in den OpenClaw Skill-Hook integriert werden.
- `transcribe.py` wurde bereits auf `whisper.cpp` umgeschrieben und getestet.
- Das `tts`-Tool ist nativ in OpenClaw verfuegbar.
- Voice-Note-Versand in Telegram erfordert `message` Tool mit `asVoice: true`.
- Die aktuelle `telegram_handler.py` gibt Text auf stdout aus. Fuer den Loop muss es entweder:
  - a) Von OpenClaw automatisch bei eingehenden Voice Messages getriggert werden, ODER
  - b) Ein dedizierter Hook in `registry/hooks.yaml` eingetragen werden.

### Risiken & Mitigationen

| Risiko | Mitigation |
|--------|------------|
| `message` Tool sendet keine Voice-Notes | `asDocument: false` + `asVoice: true` testen |
| whisper.cpp laedt langsam fuer kurze Nachrichten | Base-Modell als Default beibehalten |
| TTS-Generierung dauert zu lange | Text-Antwort als Zwischenmeldung senden |

### Deliverables

- Aktualisierte `telegram_handler.py` mit Loop-Integration
- Test-Protokoll mit 5 Voice Messages (verschiedene Laengen)
- Konfigurations-Dokumentation in `SKILL.md`

---

## Phase 2: Voice-Loop Hardening

**User Stories:**
- Als Parzival moechte ich eine neue Voice Message senden, waehrend Andrew noch spricht, damit ich ihn unterbrechen kann.
- Als Parzival moechte ich das STT-Modell on-the-fly wechseln, damit ich Qualitaet vs. Geschwindigkeit steuern kann.

### Was zu bauen ist

Das Voice-System wird produktionsreif:

1. **Session-State-Tracking:** Eine kleine State-Machine trackt, ob gerade eine Antwort generiert wird.
2. **Unterbrechungen:** Eine neue Voice Message bricht die laufende TTS-Ausgabe ab und startet eine neue Anfrage.
3. **Voice-Befehle:** `/voice schnell`, `/voice mittel`, `/voice langsam`, `/voice status` — analog zu `/whisper`.
4. **Retry-Logik:** Wenn whisper.cpp fehlschlaegt (z. B. Audio korrupt), wird automatisch ein Retry mit kleinerem Modell versucht.
5. **Logging:** Jede Transkription wird in einer Log-Datei erfasst (Dauer, Modell, Erfolg/Misserfolg).
6. **Max-Dauer-Enforcement:** Audios >10 Min werden abgelehnt mit klarer Fehlermeldung.

### Akzeptanzkriterien

- [ ] Neue Voice Message unterbricht laufende Antwort-Generierung zuverlaessig.
- [ ] `/voice schnell/mittel/langsam` funktionieren und beeinflussen die naechste Transkription.
- [ ] Bei 3 aufeinanderfolgenden Fehlern wird der Loop automatisch pausiert und ein Admin-Alert gesendet.
- [ ] Log-Datei enthaelt letzte 100 Transkriptionen mit Metadaten.
- [ ] Das System laeuft 24h stabil ohne manuellen Eingriff.

### Technische Notizen

- State-File: `~/.openclaw/workspace/skills/whisper-local-stt/state.json`
  - Felder: `is_processing`, `current_job_id`, `last_interaction`, `consecutive_errors`
- Unterbrechung kann implementiert werden durch:
  - Prozess-Kill der laufenden TTS-Generierung
  - Oder durch Ignorieren der alten Antwort, wenn eine neuere Voice Message eintrifft
- Retry-Strategie:
  1. Versuch: User-Modell
  2. Versuch: `base`
  3. Versuch: `base` mit reduzierten Beam-Size (weniger qualitativ, schneller)

### Deliverables

- `state.json` Schema und Management-Code
- `voice_command_handler.py` (neu, basierend auf `command_handler.py`)
- `voice_logger.py` fuer strukturiertes Logging
- Unterbrechungs-Implementierung in `telegram_handler.py`

---

## Phase 3: Lokale PTT-Bridge — Aufnahme

**User Stories:**
- Als Parzival moechte ich am PC `F12` druecken und sprechen, damit Andrew mich hoert, ohne eine App zu oeffnen.
- Als Parzival moechte ich das Aufnahme-Fenster sehen, damit ich weiss, wann das System lauscht.

### Was zu bauen ist

Ein eigenstaendiges Python-Script `voice-bridge.py`, das lokal laeuft:

1. **Mikrofon-Initialisierung:** `pyaudio` oeffnet den Default-Audio-Input.
2. **PTT-Hotkey:** `keyboard` lauscht auf `F12`.
3. **Aufnahme:** Solange `F12` gedrueckt ist, wird Audio in einen Ring-Buffer geschrieben.
4. **Silence-Detection:** Optional: Nach Loslassen von `F12` wird noch 500ms aufgezeichnet (Anti-Cutoff).
5. **Konvertierung:** Der Audio-Buffer wird zu WAV (16kHz, mono) konvertiert — entweder direkt in `pyaudio` oder via FFmpeg.
6. **Transkription:** `transcribe.py` wird aufgerufen.
7. **Session-Injection:** Der transkribierte Text wird in die aktuelle OpenClaw-Session injiziert.

### Akzeptanzkriterien

- [ ] `F12`-Druck startet Aufnahme innerhalb von 200ms.
- [ ] `F12`-Loslassen beendet Aufnahme und startet Transkription.
- [ ] Die Transkription erscheint in der aktuellen OpenClaw-Session (z. B. TUI oder Webchat).
- [ ] Audio-Qualitaet ist fuer Spracherkennung ausreichend (kein Clipping, minimales Rauschen).
- [ ] Das Script kann mit `Ctrl+C` sauber beendet werden.

### Code-Referenzen aus fremdem Plan

Der fremde `voice_bridge.py` enthaelt wiederverwendbare Snippets fuer diese Phase:

#### A. `AudioRecorder` — Pyaudio mit Callback
```python
import pyaudio
import wave

class AudioRecorder:
    def __init__(self, sample_rate=16000, channels=1, chunk_size=1024):
        self.audio = pyaudio.PyAudio()
        self.stream = None
        self.frames = []
        self.is_recording = False
        self.sample_rate = sample_rate
        self.channels = channels
        self.chunk_size = chunk_size

    def start_recording(self):
        self.frames = []
        self.is_recording = True
        self.stream = self.audio.open(
            format=pyaudio.paInt16,
            channels=self.channels,
            rate=self.sample_rate,
            input=True,
            frames_per_buffer=self.chunk_size,
            stream_callback=self._callback
        )

    def _callback(self, in_data, frame_count, time_info, status):
        if self.is_recording:
            self.frames.append(in_data)
        return (in_data, pyaudio.paContinue)

    def stop_recording(self, wav_path: str):
        self.is_recording = False
        if self.stream:
            self.stream.stop_stream()
            self.stream.close()
        with wave.open(wav_path, 'wb') as wf:
            wf.setnchannels(self.channels)
            wf.setsampwidth(self.audio.get_sample_size(pyaudio.paInt16))
            wf.setframerate(self.sample_rate)
            wf.writeframes(b''.join(self.frames))

    def cleanup(self):
        if self.stream:
            self.stream.close()
        self.audio.terminate()
```

#### B. Hotkey-Handling mit `keyboard` (Toggle + Hold)
```python
import keyboard

is_listening = False

keyboard.on_press_key("f12", _on_ptt_press)
keyboard.on_release_key("f12", _on_ptt_release)
keyboard.on_press_key("esc", _on_exit)

def _on_ptt_press(event):
    if toggle_mode:
        if is_listening:
            _stop_listening()
        else:
            _start_listening()
    else:
        _start_listening()

def _on_ptt_release(event):
    if not toggle_mode and is_listening:
        _stop_listening()
```

#### C. `StatusOverlay` — Tkinter Threading
```python
import tkinter as tk
import threading

class StatusOverlay:
    def __init__(self):
        self.root = None
        self.status_var = None
        self.running = False

    def start(self):
        self.thread = threading.Thread(target=self._run, daemon=True)
        self.thread.start()

    def _run(self):
        self.root = tk.Tk()
        self.root.title("Andrew Voice")
        self.root.geometry("300x100")
        self.root.attributes('-topmost', True)
        self.root.configure(bg='#1e1e1e')
        self.status_var = tk.StringVar(value="[INFO] Bereit (F12)")
        self.label = tk.Label(
            self.root, textvariable=self.status_var,
            font=('Segoe UI', 14, 'bold'),
            bg='#1e1e1e', fg='#00ff00', pady=20
        )
        self.label.pack(expand=True)
        self.running = True
        self.root.mainloop()

    def set_status(self, status: str, color: str = "gray"):
        if self.root and self.running:
            self.root.after(0, lambda: self._update_ui(status, color))

    def _update_ui(self, status: str, color: str):
        if self.status_var:
            self.status_var.set(status)
```

### Technische Notizen

- **Python-Dependencies:**
  - `pyaudio` (Audio-Input)
  - `keyboard` (Global Hotkeys — kann unter Windows Admin-Rechte brauchen)
  - `wave` (Built-in, WAV-Datei schreiben)
  - `numpy` (Audio-Buffer-Verarbeitung)
- **Alternative zu `keyboard`:**
  - `pynput` — weniger Rechte-intensiv, aber komplexer
  - Oder: Das Script bekommt Fokus und lauscht auf `F12` via `msvcrt` (keine Admin-Rechte, aber Fenster muss fokussiert sein)
- **Session-Injection:** Das ist die haerteste Huerde. Optionen:
  - **A)** `sessions_send` via OpenClaw CLI oder internes API
  - **B)** Eine Named Pipe oder lokaler HTTP-Endpunkt, den OpenClaw pollt
  - **C)** Text in eine bekannte Datei schreiben, die von einem OpenClaw-Hook gelesen wird
  - **D)** Am einfachsten: Das Script ruft `openclaw message send --channel exec-event --message "..."` auf (falls unterstuetzt)

### Risiken & Mitigationen

| Risiko | Mitigation |
|--------|------------|
| `pyaudio` installiert nicht unter Windows | `python -m pip install pipwin && pipwin install pyaudio` |
| Kein Mikrofon erkannt | Default-Device erkennen und Fallback auf ersten verfuegbaren Input |
| `keyboard` braucht Admin | `pynput` als Fallback implementieren |
| Session-Injection unklar | Prototyp mit Datei-basiertem Polling bauen |

### Deliverables

- `voice-bridge.py` (Aufnahme + Transkription)
- PowerShell-Installations-Script `install-voice-bridge.ps1`
- Dokumentation der Dependencies und Setup-Schritte

---

## Phase 4: Lokale PTT-Bridge — Antwort-Rückkanal

**User Stories:**
- Als Parzival moechte ich Andrews Antwort als Audio hoeren, damit ich nicht auf den Bildschirm schauen muss.
- Als Parzival moechte ich schnelle Antworten sofort hoeren und lange Antworten in besserer Qualitaet, damit das System flexibel bleibt.

### Was zu bauen ist

Die Bruecke muss nicht nur senden, sondern auch empfangen:

1. **Lokale TTS-Fallback (`pyttsx3`):**
   - Wenn Andrews Antwort kurz ist (<150 Zeichen), wird sie sofort mit `pyttsx3` vorgelesen.
   - Das ist schnell (kein Netzwerk-Request) und funktioniert offline.

2. **Hochwertige TTS ueber Datei-Polling:**
   - Wenn Andrews Antwort laenger ist, generiert der Agent eine Audio-Datei via `tts`-Tool.
   - Die Audio-Datei wird in einen bekannten Ordner geschrieben: `~/.openclaw/voice/outbox/`
   - `voice-bridge.py` pollt diesen Ordner alle 500ms.
   - Wenn eine neue `.mp3` oder `.wav` erscheint, wird sie abgespielt.
   - Nach dem Abspielen wird die Datei geloescht.

3. **Audio-Wiedergabe:**
   - Windows: `playsound` oder `pygame.mixer` oder `winsound` (eingeschraenkt)
   - Beste Wahl: `playsound` fuer `.mp3` und `.wav`

4. **Unterbrechungen:**
   - Wenn Parzival waehrend der Wiedergabe erneut `F12` drueckt, wird die aktuelle Wiedergabe abgebrochen.

### Akzeptanzkriterien

- [ ] Kurze Antworten (<150 Zeichen) werden innerhalb von 2 Sekunden als Audio ausgegeben.
- [ ] Lange Antworten landen im `outbox/`-Ordner und werden innerhalb von 10 Sekunden abgespielt.
- [ ] Wiedergabe kann durch erneutes Druecken von `F12` unterbrochen werden.
- [ ] Wenn keine Antwort generiert wird, passiert nichts (kein Polling-Spam).
- [ ] Das System funktioniert zuverlaessig ohne Internet, solange `pyttsx3` als Fallback greift.

### Code-Referenzen aus fremdem Plan

#### A. `PiperTTS` — Lokale TTS mit subprocess
```python
import subprocess
import os

class PiperTTS:
    def __init__(self, piper_exe: str, piper_model: str):
        self.piper_exe = piper_exe
        self.piper_model = piper_model

    def speak(self, text: str, wav_path: str) -> bool:
        cmd = [
            self.piper_exe,
            "--model", self.piper_model,
            "--output_file", wav_path
        ]
        try:
            proc = subprocess.Popen(
                cmd, stdin=subprocess.PIPE,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )
            proc.stdin.write(text)
            proc.stdin.close()
            proc.wait(timeout=30)
            if os.path.exists(wav_path):
                self._play_audio(wav_path)
                return True
        except subprocess.TimeoutExpired:
            print("[FEHLER] Piper Timeout")
        return False

    def _play_audio(self, wav_path: str):
        try:
            os.system(f'start /min "" "{wav_path}"')
        except:
            subprocess.run(
                ["ffplay", "-nodisp", "-autoexit", wav_path],
                capture_output=True, timeout=60
            )
```
**Anmerkung:** `_play_audio` via `os.system('start ...')` oeffnet Windows Media Player — fuer unsere Zwecke besser durch `playsound` oder `pygame.mixer` ersetzen.

#### B. `pyttsx3` Fallback
```python
import pyttsx3

engine = pyttsx3.init()
engine.setProperty('rate', 180)
engine.setProperty('voice', voice_id)  # Deutsche Stimme
engine.say(text)
engine.runAndWait()
```

### Technische Notizen

- **pyttsx3:**
  - `pip install pyttsx3`
  - Windows nutzt SAPI5
  - Deutsche Stimmen sind verfuegbar, wenn im Windows-System installiert
  - Stimme kann konfiguriert werden (`engine.setProperty('voice', voice_id)`)
- **Datei-Polling-Mechanismus:**
  ```python
  import time
  from pathlib import Path
  
  OUTBOX = Path.home() / ".openclaw" / "voice" / "outbox"
  
  while True:
      files = sorted(OUTBOX.glob("*.mp3"), key=lambda p: p.stat().st_mtime)
      if files:
          play_audio(files[0])
          files[0].unlink()
      time.sleep(0.5)
  ```
- **OpenClaw-Integration fuer hochwertige TTS:**
  - Ein dedizierter Skill-Hook oder eine Konvention: Wenn der Agent eine Nachricht an den Voice-Channel sendet, speichert er parallel eine TTS-Audio-Datei in `outbox/`.
  - Das `tts`-Tool in OpenClaw kann Audio-Dateien generieren. Wir muessen sicherstellen, dass die Datei am richtigen Ort landet.

### Risiken & Mitigationen

| Risiko | Mitigation |
|--------|------------|
| `pyttsx3` klingt schlecht | Premium-TTS ueber Polling als Standard fuer alles >50 Zeichen |
| `playsound` hat Lock-Probleme | `pygame.mixer` als Fallback |
| Keine deutsche Stimme auf Windows | Hinweis im Setup-Script, wie man Windows-Sprachpakete installiert |
| Datei-Polling verursacht Disk-Load | Polling-Intervall auf 500ms-1s setzen, kein Problem bei moderner SSD |

### Deliverables

- Erweitertes `voice-bridge.py` mit TTS-Fallback und Polling
- `voice-outbox/` Ordner-Setup
- Dokumentation der TTS-Stimmen-Konfiguration

---

## Phase 5: Unified Voice Control

**User Stories:**
- Als Parzival moechte ich Einstellungen fuer Telegram und PTT an einem Ort aendern, damit ich nichts doppelt pflegen muss.
- Als Parzival moechte ich sehen, wie oft ich heute mit Andrew gesprochen habe, damit ich meine Nutzung einschaetzen kann.

### Was zu bauen ist

1. **Gemeinsame Konfiguration:**
   - Alle Voice-Einstellungen werden in `config.json` zentralisiert.
   - Neue Sektionen: `voice_loop`, `ptt_bridge`, `tts`, `statistics`

2. **Status-Dashboard:**
   - Ein einfaches Terminal-Dashboard (z. B. mit `rich` oder `curses`):
     - Aktiver Modus (Telegram / PTT / Beide)
     - Aktuelles STT-Modell
     - Letzte Transkription
     - Heutige Statistik (Anzahl Gespraeche, Gesamtdauer)
     - System-Status (whisper.cpp erreichbar? Mikrofon verfuegbar?)

3. **Statistik-Tracking:**
   - JSON- oder SQLite-basierte Statistik-Datenbank
   - Metriken: Anzahl Transkriptionen, durchschnittliche Dauer, Fehlerrate, bevorzugtes Modell

4. **Dokumentation:**
   - `SKILL.md` wird auf den neuesten Stand gebracht.
   - `README.md` fuer Endnutzer (Parzival) mit Quick-Start.

### Akzeptanzkriterien

- [ ] Aenderungen in `config.json` wirken sich sofort auf Telegram und PTT aus.
- [ ] Das Dashboard zeigt in Echtzeit den Status der PTT-Bridge an.
- [ ] Statistiken sind ueber die letzten 30 Tage verfuegbar.
- [ ] Die Dokumentation ermoeglicht es, das System nach einem Monat wiederzubeleben, ohne raten zu muessen.

### Code-Referenzen aus fremdem Plan

#### Status-Overlay fuer Phase 5 (erweitert zu Dashboard)
Das Tkinter-Overlay aus Phase 3 kann zu einem einfachen Terminal-Dashboard migriert werden. `rich` ist die empfohlene Bibliothek fuer Python:
```python
from rich.live import Live
from rich.table import Table
from rich.panel import Panel

def build_dashboard():
    table = Table(title="Andrew Voice Bridge")
    table.add_column("Metrik", style="cyan")
    table.add_column("Wert", style="magenta")
    table.add_row("Modus", "PTT")
    table.add_row("STT-Modell", "base")
    table.add_row("Heute Gespraeche", "12")
    return Panel(table, title="[bold green]Voice Status[/]")

with Live(build_dashboard(), refresh_per_second=1) as live:
    while True:
        live.update(build_dashboard())
        time.sleep(1)
```

### Technische Notizen

- **Dashboard-Bibliothek:** `rich` (Python) ist empfohlen — schoene Tabellen, Panels, Live-Updates.
- **Statistik-Storage:** SQLite ist ueberfluessig fuer dieses Datenvolumen. JSON-Append-Log reicht:
  ```json
  {"timestamp": "2026-04-14T10:30:00Z", "channel": "telegram", "model": "base", "duration_sec": 3.2, "success": true}
  ```
- **Config-Schema (vorschlag):**
  ```json
  {
    "default_model": "base",
    "voice_loop": {
      "enabled": true,
      "interrupt_on_new_message": true,
      "max_duration": 600
    },
    "ptt_bridge": {
      "enabled": false,
      "hotkey": "f12",
      "silence_padding_ms": 500,
      "fallback_tts_max_chars": 150
    },
    "tts": {
      "premium_enabled": true,
      "outbox_dir": "~/.openclaw/voice/outbox",
      "local_voice_id": null
    },
    "statistics": {
      "enabled": true,
      "log_file": "~/.openclaw/voice/stats.jsonl"
    }
  }
  ```

### Deliverables

- Einheitliches `config.json` Schema
- `voice-dashboard.py` Terminal-UI
- `stats.py` fuer Logging und Reporting
- Vollstaendig aktualisierte Dokumentation

---

## Abhaengigkeiten & Voraussetzungen

### Software
- Python 3.12+ (verfuegbar)
- FFmpeg (verfuegbar)
- whisper.cpp `main.exe` (verfuegbar)
- `ggml-base.bin` (verfuegbar)
- `ggml-small.bin` + `ggml-medium.bin` (pending — `python scripts/install.py`)

### Python-Packages (Phase 3+)
- `pyaudio` oder `sounddevice`
- `keyboard` oder `pynput`
- `pyttsx3`
- `playsound`
- `rich` (Phase 5)

### OpenClaw Features
- `tts`-Tool (verfuegbar)
- `message` Tool mit Voice-Note-Support (verfuegbar seit 2026.4.12)
- Session-Injection-Mechanismus (needs Phase 3 R&D)

---

## Definition of Done (gesamtes Projekt)

- [ ] Parzival kann aus Telegram eine Voice Message senden und erhaelt eine Voice-Note zurueck.
- [ ] Parzival kann am PC `F12` druecken, sprechen, und Andrews Antwort wird als Audio ausgegeben.
- [ ] Beide Kanaele teilen sich Einstellungen und Statistiken.
- [ ] Das System ist dokumentiert, getestet und in SecondBrain getrackt.
- [ ] Parzival kann das System ohne Admin-Hilfe wiederstarten und konfigurieren.
