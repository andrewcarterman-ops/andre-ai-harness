# How-To: Mini-Evolve-Loop verwenden

**Zuletzt aktualisiert:** 14-04-2026
**Status:** Prototyp funktionsfähig
**Ort:** `C:\Users\andre\.openclaw\workspace\mini-evolve-loop\`

---

## Was ist das?

Ein **provider-agnostischer, diffuser Evolution-Loop** für gezielte Code-Verbesserungen. Inspiriert von ASI-Evolve, aber stark vereinfacht und für unser OpenClaw-System angepasst.

**Kernprinzip:**
- Der Loop schlägt Code-Verbesserungen vor
- Speichert sie in `05-Research/pending/`
- **Nie automatisch implementieren** — immer auf GO von Parzival warten

---

## Architektur

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Researcher │────▶│   Engineer  │────▶│   Analyzer  │
│   (LLM)     │     │  (Code-Exec)│     │   (LLM)     │
└─────────────┘     └─────────────┘     └─────────────┘
       │                                           │
       └───────────────────────────────────────────┘
                          ▼
              ┌─────────────────────┐
              │ 05-Research/pending/│
              └─────────────────────┘
```

### Agenten

| Rolle | Modell (aktuell) | Aufgabe |
|-------|------------------|---------|
| **Researcher** | `qwen2.5-coder:7b` via Ollama | Generiert SEARCH/REPLACE-Diffs |
| **Engineer** | Kein LLM (nur Python exec) | Wendet Diff an, führt Tests aus |
| **Analyzer** | `qwen2.5-coder:7b` via Ollama | Bewertet Ergebnis, gibt Verdict |

---

## Dateistruktur

```
mini-evolve-loop/
├── config.yaml              # LLM-Backends, Target, Output-Pfade
├── evolve.py                # Haupt-Loop
├── llm_router.py            # Provider-agnostischer LLM-Client
├── prompts/
│   ├── researcher_diff.jinja2
│   └── analyzer.jinja2
└── run-evolve.ps1           # PowerShell-Launcher
```

---

## Konfiguration (`config.yaml`)

### Aktuelle Ollama-Config
```yaml
models:
  coding:
    provider: "ollama"
    base_url: "http://localhost:11434/v1"
    api_key: "EMPTY"
    model: "qwen2.5-coder:7b"
    timeout: 900
    max_tokens: 8192
    temperature: 0.4
    extra_body:
      num_ctx: 8192
```

### Wechsel zu API-Backend (z.B. Kimi)
Einfach `provider`, `base_url`, `api_key`, `model` ändern. Der Loop bleibt identisch.

---

## Wichtige Pfade

| Pfad | Zweck |
|------|-------|
| `C:\Users\andre\.openclaw\workspace\mini-evolve-loop\` | Loop-Code |
| `SecondBrain/05-Research/pending/` | Neue Vorschläge |
| `SecondBrain/05-Research/validated/` | Bestätigte Vorschläge |
| `SecondBrain/05-Research/rejected/` | Abgelehnte Vorschläge (negatives Wissen) |

---

## Verwendung

### 1. Ollama starten (falls nicht läuft)
Ollama läuft meist als Windows-Dienst im Hintergrund. Prüfen:
```powershell
Test-NetConnection -ComputerName localhost -Port 11434
```

### 2. Loop starten
```powershell
cd C:\Users\andre\.openclaw\workspace\mini-evolve-loop
python evolve.py
```

Oder über PowerShell-Launcher:
```powershell
.\run-evolve.ps1
```

### 3. Ergebnisse prüfen
```powershell
Get-ChildItem ..\SecondBrain\05-Research\pending\ | Sort-Object LastWriteTime -Descending
```

---

## Bekannte Limitierungen

1. **Qwen 7B liefert nicht immer Diffs** — manchmal nur Name + Motivation
2. **Diff-Match-Fehler** — SEARCH-Text muss exakt matchen (Whitespace-sensitiv)
3. **Geschwindigkeit** — ~60-70 Sekunden pro Researcher-Call auf lokaler CPU
4. **Max Context** — `num_ctx: 8192` gesetzt, größere Codebases erfordern Aufteilung

---

## Historie

- **14-04-2026:** Prototyp gebaut, Ollama + Qwen2.5 Coder 7B getestet, erste Proposal-Datei erfolgreich erzeugt (`20260414-084714-semantic-memory-iteration-2.md`)

---

## Verwandt

- [[asi-evolve-deep-architecture-analysis]]
- [[_MOC-Research]]
- [[semantic-memory-poc]]
