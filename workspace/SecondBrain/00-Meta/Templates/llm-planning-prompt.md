# LLM Planning Prompt Template

> **Zweck:** Diese Datei wird an andere LLMs (Claude, ChatGPT, Gemini, etc.) gegeben, wenn sie einen Architektur- oder Implementierungsplan fuer Parzivals Setup erstellen sollen.  
> **Wichtig:** Vor jeder Planungsanfrage an einen fremden LLM wird diese Datei als Kontext mitgegeben.  
> **Aktualisierung:** Jede Session prueft, ob sich Hardware, Software-Stack oder das Agent-Oekosystem geaendert hat, und aktualisiert diese Datei.

---

## Meta-Daten (fuer interne Verwaltung)

```yaml
last_updated: "2026-04-14"
updated_by: "andrew-main"
version: "1.0"
source_files:
  - "registry/agents.yaml"
  - "MEMORY.md"
  - "TOOLS.md"
  - "USER.md"
```

---

## 1. Das AI-Harem (Agent-Oekosystem)

Parzival betreibt keinen einzelnen Agenten, sondern ein **modulares Agentensystem** unter OpenClaw. Wenn du einen Plan erstellst, musst du wissen, **wer** fuer was zustaendig ist und **welches Modell** im Hintergrund laeuft.

### 1.1 Hauptagent

| Agent | Name | Modell | Rolle |
|-------|------|--------|-------|
| `andrew-main` | **Andrew** | `kimi-coding/kimi-k2-thinking` (default) | Direkter Assistent, Orchestrierung, Memory-Zugriff, Tool-Use, Exec |

**Andrew ist DER Agent.** Wenn ein Plan sagt "mit dem Agenten sprechen", dann ist das Andrew. Er laeuft im OpenClaw Gateway und hat Zugriff auf:
- `read` / `write` / `edit`
- `exec` (PowerShell, ask: off)
- `web_search` / `web_fetch`
- `browser`
- `sessions_spawn` (Subagenten starten)
- `tts` (Text-to-Speech)
- `cron` (Automation)
- `memory_search` / `memory_get`

### 1.2 Spezialisierte Subagenten

Diese werden von Andrew bei Bedarf gespawnt. Ein Plan sollte **nicht** versuchen, deren Arbeit zu duplizieren.

| Agent | Trigger-Phrase | Faehigkeit |
|-------|----------------|------------|
| `architect` | "architect", "design system" | System-Design, ADRs |
| `planner` | "plan", "roadmap", "break down" | Task-Zerlegung, Schatzungen |
| `code-reviewer` | "review code", "quality check" | Code-Review, Best Practices |
| `security-reviewer` | "security review", "audit" | Sicherheitsanalyse |
| `python-reviewer` | "python review", "pep8" | Python-spezifische Reviews |
| `knowledge-curator` | "analyze vault", "obsidian cleanup" | Knowledge-Base-Analyse |

### 1.3 Externe LLM-Provider (API-basiert)

| Provider | Verwendung | Status |
|----------|------------|--------|
| **Kimi (Moonshot)** | Standard-Modell fuer Coding, Reasoning, lange Kontexte | ✅ Aktiv, manchmal Rate-Limits |
| **OpenRouter** | Fallback-Provider fuer verschiedene Modelle | ✅ Konfiguriert |
| **Codex (OpenAI)** | ACP-Harness fuer schnelle Code-Iterationen | ✅ Verfuegbar via `sessions_spawn` |

### 1.4 Lokale LLM-Optionen (Ollama)

| Modell | Parameter | Einsatzzweck | Limitierung |
|--------|-----------|--------------|-------------|
| **Qwen2.5 Coder** | 7B | Lokaler Code-Evolution-Loop, schnelle Drafts | Nur fuer kurze Kontexte (<4K empfohlen) |
| **Llama 3.1** | 8B | Allgemeine lokale Inferenz | Max ~8K Context auf GTX 980M |

**Wichtig:** Lokale Modelle sind **kein Ersatz** fuer Andrews Haupt-Session. Sie laufen in separaten, isolierten Prozessen (z. B. `mini-evolve-loop/`).

---

## 2. Hardware-Spezifikationen (HARDCODIERT - nicht raten!)

Diese Specs sind **faktisch ueberprueft**. Wenn ein Plan Hardware-Anforderungen ueberschreitet, ist der Plan falsch.

### 2.1 Host-System

| Komponente | Spezifikation | Kritische Einschraenkung |
|------------|---------------|--------------------------|
| **CPU** | Intel Core i7-6820HK @ 2.70GHz (4 Kerne / 8 Threads) | Keine massiven Parallel-Workloads |
| **RAM** | 32 GB DDR4 | Gut fuer LLM-Hosting, aber keine 70B+ Modelle |
| **Speicher** | 1TB Samsung SSD 860 EVO (932 GB nutzbar) | Ausreichend, aber keine riesigen Modelle |
| **GPU** | NVIDIA GeForce GTX 980M | **Nur 4GB effektiv nutzbar** wegen Shared Memory |
| **iGPU** | Intel HD Graphics 530 | Fallback fuer CPU-Rendering |
| **OS** | Windows 10/11 64-bit | PowerShell bevorzugt, Bash nur mit detaillierten Instruktionen |

### 2.2 Was funktioniert auf dieser Hardware

- ✅ Lokale GGUF-Modelle bis ~13B Parameter (Q4_0 / Q4_K_M)
- ✅ whisper.cpp im CPU-Modus ( bereits installiert unter `~/.openclaw/whisper/` )
- ✅ Stable Diffusion auf CPU oder 980M (langsam)
- ✅ API-basierte Code-Generierung (Kimi, Codex, OpenRouter)
- ✅ SecondBrain + FAISS-basierte semantische Suche

### 2.3 Was explizit NICHT funktioniert

- ❌ 70B+ Modelle lokal
- ❌ Große Batch-Training-Jobs
- ❌ CUDA-intensive Workloads (alte Architektur der 980M)
- ❌ 14B-Modelle mit langem Context (>8K) auf GPU — OOM-Risiko

---

## 3. Existierende Infrastruktur (Redundanz-Check)

**Bevor du einen Plan erstellst, pruefe diese Pfade. Keine Duplikate bauen.**

| Was | Pfad | Status |
|-----|------|--------|
| **OpenClaw Gateway** | `~/.openclaw/` | ✅ Laueft auf Port 18789 |
| **OpenClaw Workspace** | `~/.openclaw/workspace/` | ✅ Aktiver Entwicklungs-Space |
| **Whisper.cpp** | `~/.openclaw/whisper/main.exe` | ✅ Installiert, CPU-Modus |
| **Whisper Modelle** | `~/.openclaw/whisper/models/ggml-base.bin` | ✅ Verfuegbar |
| **SecondBrain Vault** | `~/.openclaw/workspace/SecondBrain/` | ✅ Strukturiertes Knowledge-System |
| **Mission Control v2** | `~/.openclaw/workspace/skills/mission-control-v2/` | ✅ Next.js Dashboard |
| **ECC Runtime** | `crates/ecc-runtime/` | ✅ Rust-basierte Conversation Runtime |
| **Secure API Client** | `~/.openclaw/workspace/skills/secure-api-client/` | ✅ SSE Streaming, fertig |
| **Mini-Evolve-Loop** | `mini-evolve-loop/` | ✅ Provider-agnostischer LLM-Router |

---

## 4. Parzivals Praeferenzen (VERPFLICHTEND)

Diese Regeln sind nicht optional. Wenn ein Plan ihnen widerspricht, ist er abzulehnen.

1. **Qualitaet > Geschwindigkeit.** Lieber langsam und richtig als schnell und fehlerhaft.
2. **Vollstaendigkeit > Schnelligkeit.** Keine halben Implementierungen.
3. **Schritt-fuer-Schritt mit Zwischen-Abfragen.** Kein "Big Bang" Deployment.
4. **Batch-basiert.** Ein Schritt fertig, dann GO holen.
5. **Keine Emojis im Terminal.** ASCII-Symbole wie `[OK]`, `[WARN]`, `[FEHLER]` verwenden.
6. **PowerShell bevorzugen.** Bash/Git Bash nur mit extrem detaillierten Instruktionen.
7. **Keine Admin-Befehle ohne explizite Anfrage.**
8. **Löschen = GO erforderlich.** Niemals automatisch löschen.
9. **Dry-Run vor Migrationen.** Erst simulieren, dann GO holen, dann restliche Dateien.
10. **Backup vor Löschen.** Backup-Ordner erstellen vor jeder Migration.

---

## 5. Prompt-Template fuer fremde LLMs

**Kopiere den folgenden Block in deine Anfrage an einen anderen LLM:**

```markdown
Ich brauche einen detaillierten Implementierungsplan fuer [FEATURE].

## Kontext (KRITISCH)

Ich betreibe ein modulares Agentensystem unter OpenClaw. Mein Hauptagent ist **Andrew** (Modell: Kimi k2-thinking). Er hat Zugriff auf:
- `read` / `write` / `edit`
- `exec` (PowerShell, ask: off)
- `web_search` / `web_fetch`
- `browser`
- `sessions_spawn` (Subagenten: architect, planner, code-reviewer, security-reviewer, python-reviewer, knowledge-curator)
- `tts`, `cron`, `memory_search`

**Meine Hardware:**
- CPU: Intel i7-6820HK (4C/8T)
- RAM: 32 GB DDR4
- GPU: NVIDIA GTX 980M (**nur 4GB effektiv nutzbar**)
- OS: Windows 11
- Speicher: 1TB SSD (~932 GB frei)

**Wichtige Einschraenkungen:**
- Keine 70B+ Modelle lokal
- whisper.cpp ist BEREITS installiert unter `~/.openclaw/whisper/main.exe`
- Lokale LLMs nur bis ~13B Parameter (GGUF/Q4)
- PowerShell bevorzugt, Bash nur mit detaillierten Instruktionen

**Existierende Infrastruktur (NICHT duplizieren):**
- OpenClaw Gateway auf Port 18789
- Whisper.cpp + ggml-base.bin unter `~/.openclaw/whisper/`
- SecondBrain Vault unter `~/.openclaw/workspace/SecondBrain/`
- ECC Runtime in `crates/ecc-runtime/`
- Secure API Client (SSE Streaming) in `skills/secure-api-client/`

**Meine Praeferenzen:**
1. Qualitaet > Geschwindigkeit
2. Schritt-fuer-Schritt mit Zwischen-Abfragen
3. Keine Emojis im Terminal
4. Löschen nur mit GO
5. Dry-Run vor Migrationen
6. Backup vor Löschen

## Anforderungen an den Plan

1. **Redundanz-Check:** Pruefe, ob Komponenten bereits existieren. Nenne explizit, was wiederverwendet vs. neu installiert wird.
2. **Hardware-Realismus:** Jede Komponente muss mit der oben genannten Hardware laufen. Wenn etwas zu gross/langsam ist, markiere es als Risiko.
3. **Keine Annahmen:** Wenn dir ein Pfad, eine API oder eine Fähigkeit unbekannt ist, schreibe "Unbekannt - muss geprüft werden" statt zu raten.
4. **Integration vor Isolation:** Bevorzuge Verbindung zu existierenden Systemen (OpenClaw Gateway, Andrew-Session) gegenüber dem Bauen paralleler Stacks.
5. **Phasen:** Teile in vertikale Slices: Phase 1 = minimalster MVP mit existierenden Tools, Phase 2+ = Erweiterungen.

## Was ich NICHT will

- [ ] Einen isolierten Ersatz-Agenten (z. B. Llama 3.1 lokal als Chatbot). Das Ziel ist Integration mit Andrew.
- [ ] Downloads > 2 GB ohne explizite Begruendung und GO.
- [ ] Hardware-Anforderungen, die meine Specs ueberschreiten (z. B. ">8GB VRAM").
- [ ] Pläne ohne Fehlerhandling oder Fallback-Strategien.
- [ ] Bash-Skripte ohne PowerShell-Alternative.
- [ ] Emojis oder Unicode-Symbole im Terminal-Output.

Wenn du eine Hardware-Spezifikation, einen Pfad oder eine Fähigkeit nicht kennst, **schreibe es hin. Rate nicht.** Ein falscher Plan ist schlimmer als keiner.
```

---

## 6. Aktualisierungs-Protokoll

**Regel:** Am Ende jeder Session, in der sich etwas an folgendem geaendert hat, MUSS diese Datei aktualisiert werden:

- Neue Agenten hinzugefuegt / entfernt
- Neues Default-Modell
- Neue Hardware (CPU, RAM, GPU, Speicher)
- Neue existierende Infrastruktur (Skills, Tools, Runtimes)
- Geaenderte Praeferenzen
- Neue Einschraenkungen oder Lessons Learned

### 6.1 Schnell-Check fuer Updates

Frage dich vor dem Speichern:
1. Hat sich die Hardware geaendert? → Sektion 2 aktualisieren.
2. Ist ein neuer Agent / Skill / Tool hinzugekommen? → Sektionen 1 + 3 aktualisieren.
3. Haben wir eine neue Praeferenz gelernt? → Sektion 4 ergaenzen.
4. Ist der Prompt-Template-Block (Sektion 5) noch konsistent mit den aktuellen Daten?

### 6.2 Versionshistorie

| Version | Datum | Aenderung | Aktualisiert von |
|---------|-------|-----------|------------------|
| 1.0 | 2026-04-14 | Erste Version mit AI-Harem, Hardware-Specs, Praeferenzen und Prompt-Template | andrew-main |

---

## 7. An wen wende ich mich, wenn ich selbst aktualisiert werden soll?

Wenn du (ein fremder LLM) diese Datei liest und erkennst, dass sie veraltet sein koennte:

1. **Sage es explizit:** "Diese Datei scheint veraltet zu sein, weil [Grund]."
2. **Schlage Aktualisierungen vor.**
3. **Frage nach einem GO**, bevor du die Datei aenderst.

Der Hauptagent **Andrew** ist fuer die Pflege dieser Datei verantwortlich.
