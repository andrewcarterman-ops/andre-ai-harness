---
date: 14-04-2026
type: project
status: active
priority: medium
tags: [project, ai-research, asi-evolve, mcp, architecture, analysis, mini-evolve-loop]
---

# Projekt: ASI-Evolve Analyse & Integration

## Ziel

Analyse des [[asi-evolve|ASI-Evolve]] Frameworks (GAIR-NLP) auf Anwendbarkeit für unser OpenClaw AI Harness. Entscheidung: Direkte Integration vs. konzeptionelle Übernahme vs. Ablehnung.

**Aktueller Status (14-04-2026):** Prototyp gebaut, erste Proposal-Datei erzeugt. Projekt bleibt aktiv bis Validierung und Produktionsreife erreicht sind.

---

## Was ist ASI-Evolve?

**Repository:** <https://github.com/GAIR-NLP/ASI-Evolve.git>

Ein generalisiertes agentisches Framework für autonome Forschung mit einem geschlossenen Loop:

1. **LEARN** → Wissen aus Cognition Store + Experiment Database abrufen
2. **DESIGN** → Researcher-Agent schlägt nächsten Kandidaten vor
3. **EXPERIMENT** → Engineer-Agent führt Code aus, sammelt Metriken
4. **ANALYZE** → Analyzer-Agent destilliert Lessons Learned

**Bekannte Ergebnisse:**
- Neural Architecture Design: +0.97 pts über DeltaNet
- Pretraining Data Curation: +3.96 pts avg, +18 pts MMLU
- RL Algorithm Design: +12.5 pts auf AMC32 vs GRPO

---

## Was wir gemacht haben

### Phase 1: Analyse (14-04-2026)
- [x] README.md analysiert
- [x] `config.yaml`, `main.py` und `pipeline/main.py` gelesen
- [x] `circle_packing_demo` als Referenz-Experiment untersucht
- [x] Compute-Anforderungen gegen unsere Hardware (GTX 980M, 32GB RAM) geprüft
- [x] Konfigurationsstruktur verstanden (API, Pipeline, Cognition, Database)

### Phase 2: Prototyp "Mini-Evolve-Loop" (14-04-2026)
- [x] `05-Research/` Staging-Area mit `pending/`, `validated/`, `rejected/` erstellt
- [x] **Semantic Memory PoC** gebaut (`semantic-memory-poc.py`) — 329 Dokumente indexiert via FAISS + `all-MiniLM-L6-v2`
- [x] **Auto-Retrospective** Skript gebaut (`auto-retrospective.py`)
- [x] **Mini-Evolve-Loop** implementiert:
  - `config.yaml` (provider-agnostisch)
  - `llm_router.py` (unterstützt Ollama, Kimi, Codex, OpenRouter)
  - `evolve.py` (sequentieller Diff-Loop)
  - `prompts/researcher_diff.jinja2` + `prompts/analyzer.jinja2`
  - `run-evolve.ps1` (PowerShell-Launcher)
- [x] **Ollama + Qwen2.5 Coder 7B** installiert, getestet und vollständig geladen (4.7 GB)
- [x] **Erste Proposal-Datei** erfolgreich erzeugt: `20260414-084714-semantic-memory-iteration-2.md`

**Hardware-Assessment:**
- FAISS + Embeddings (`all-MiniLM-L6-v2`) → ✅ Läuft auf CPU
- Engineer-Phase (Python-Skripte) → ✅ Läuft auf CPU
- API-LLM (Researcher/Analyzer) → ✅ Keine lokale Compute nötig
- Ollama Qwen2.5 Coder 7B → ✅ Läuft lokal (~60-70s pro Diff)

---

## Was wir übernehmen sollten

### 1. Das 4-Schritt-Loop-Konzept (adaptiert)
Unser System nutzt bereits ähnliche Muster (`sessions_spawn`, Subagents). Wir sollten dies **formalisieren** für komplexe Skill-/MCP-Entwicklung:

| ASI-Evolve | Unsere Version |
|------------|----------------|
| LEARN | Vault + MEMORY.md lesen |
| DESIGN | Subagent entwirft Lösung |
| EXPERIMENT | PowerShell/Python Test ausführen |
| ANALYZE | Ergebnis in Vault dokumentieren |

### 2. Cognition Store als Vault-Bridge
Die Idee eines semantischen Wissens-Speichers mit Embedding-Suche passt perfekt zu unserem geplanten **eigenen MCP Server**. ASI-Evolve nutzt FAISS — wir könnten ähnliche Technik für Vault-Suche implementieren.

### 3. Experiment-Tracking im Vault
Jede Iteration dokumentieren mit:
- Hypothese
- Code-Änderung
- Test-Ergebnis
- Lesson Learned

Das ist für unsere **Retrospektiven** und **ADRs** wertvoll.

### 4. Parent Selection (UCB1 / Island Sampling)
Für rein **theoretische Inspiration** interessant, wenn wir jemals automatisches Prompt-Tuning oder Hyperparameter-Optimierung machen wollen.

---

## Was wir NICHT übernehmen sollten (Hypothesen)

### Hypothese 1: Direkte Integration ist Overengineering
> ASI-Evolve ist ein Forschungs-Ferrari. Wir brauchen einen zuverlässigen Daily Driver.

- Domänen-Mismatch: SOTA-Forschung vs. persönliche Produktivität
- Unsere Evaluationen sind subjektiv (User-Präferenz), nicht numerisch (Accuracy)
- Integration würde mehr Wartung kosten als Nutzen bringen

### Hypothese 2: Lokaler LLM-Server ist auf unserer Hardware nicht praktikabel
> Die Autoren nutzen `sglang` auf `localhost:30032`. Ein 7B+ Modell braucht ~6-8GB VRAM.

- GTX 980M hat nur 4GB effektiven VRAM
- Q4-Quantisierung wäre nötig, kostet aber Qualität und Geschwindigkeit
- Frustrierend langsame Researcher-Outputs

### Hypothese 3: Der volle 40-Schritt-Evolutions-Loop ist für uns zu ressourcenintensiv
> Sinnvoll für ML-Forschung, aber nicht für gelegentliche Skill-Entwicklung.

- API-Kosten (außer bei Kimi aktuell gratis)
- Zeit-Overhead bei jedem Task
- Kein skalierbares Evaluationskriterium für Vault-Management

### Hypothese 4: Wir haben das Wichtigste bereits implizit
> SecondBrain + Active Memory + Subagents decken 80% der ASI-Evolve-Funktionalität ab.

- Cognition Store = SecondBrain Vault
- Experiment Database = Daily Notes + Projects
- Researcher/Engineer/Analyzer = `sessions_spawn` + Retrospektiven
- Was fehlt: Systematisierung, nicht Technologie

---

## Referenzen

- **GitHub Repository:** <https://github.com/GAIR-NLP/ASI-Evolve.git>
- **Paper (PDF):** <https://github.com/GAIR-NLP/ASI-Evolve/blob/main/assets/paper.pdf>
- **arXiv:** <https://arxiv.org/abs/2603.29640>

---

## Geklärt / Entscheidungen

1. **Keine direkte Integration von ASI-Evolve als Ganzes.**
2. **Stattdessen:** Eigener, vereinfachter "Mini-Evolve-Loop" als PowerShell/Python-Hybrid.
3. **LLM-Strategie:** Ollama (Qwen 7B) für lokale, kostenfreie Over-Night-Runs; API-Backends (Kimi, Codex) für schnelle Validierung.
4. **Output-Workflow:** Alle Vorschläge landen in `05-Research/pending/` und werden **nie** automatisch implementiert — immer GO von Parzival nötig.
5. **Shell-Präferenz:** PowerShell wird für alle Skripte bevorzugt (dokumentiert in `TOOLS.md` und `MEMORY.md`).

---

## Offene TODOs (Projekt bleibt aktiv)

### Validierung & Stabilität
- [ ] Mehrere Proposal-Dateien mit echtem Target (`semantic-memory-poc.py`) erzeugen und Qualität prüfen
- [ ] Diff-Extraktion verbessern (Qwen 7B wickelt manchmal XML in Markdown-Blöcke ein)
- [ ] SEARCH/REPLACE-Match-Rate erhöhen (evtl. mit Fuzzy-Matching oder AST-basiertem Diff)

### Agent-Config & Backend
- [ ] Prompt-Templates für Ollama feintunen (mehr deterministische Diffs)
- [ ] Optionales API-Backend (Kimi/Codex) in Config einrichten und testen
- [ ] LLM-Router erweitern für Modell-Fallbacks (Coding → Reasoning → Fast)

### Manuelle Aktivierung
- [ ] `run-evolve.ps1` vervollständigen:
  - Automatische Ollama-Verfügbarkeitsprüfung
  - Log-Datei schreiben
  - E-Mail/Notification bei Fertigstellung (optional)
- [ ] One-Click-Start für "5 Steps" vs "10 Steps" vs "Overnight"

### Automatischer Über-Nacht-Loop
- [ ] Cron-Job oder Windows Task Scheduler für nächtliche Runs (z.B. 23:00 Uhr)
- [ ] Automatisches Ziel-Rotations-System (welcher Skill/Script als nächstes optimiert wird)
- [ ] Morning-Report generieren (Zusammenfassung der neuen Proposals)

### Dokumentation & Integration
- [ ] [[mini-evolve-loop]] Knowledge-Base fortlaufend aktualisieren
- [ ] Verknüpfung mit [[openclaw-renovation|OpenClaw Renovierung]] herstellen

---

**Erstellt:** 14-04-2026
**Analyst:** Andrew (OpenClaw Agent)
