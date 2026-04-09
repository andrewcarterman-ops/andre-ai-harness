# Second Brain fÃ¼r OpenClaw

Ein PARA-basiertes Second Brain System fÃ¼r OpenClaw Sessions.

## PARA-Struktur

```
second-brain/
â”œâ”€â”€ 00-Dashboard/          # Ãœbersichten und Dashboards
â”‚   â””â”€â”€ Dashboard.md       # Haupt-Dashboard mit Dataview
â”œâ”€â”€ 01-Sessions/           # OpenClaw Sessions (automatisch)
â”œâ”€â”€ 02-Areas/              # Lebensbereiche
â”‚   â”œâ”€â”€ Decisions/         # Architektur-Entscheidungen (ADRs)
â”‚   â””â”€â”€ Projects/          # Aktive Projekte
â”œâ”€â”€ 03-Resources/          # Ressourcen
â”‚   â”œâ”€â”€ CodeBlocks/        # Extrahierte Code-Snippets
â”‚   â””â”€â”€ Dataview/          # Query-Templates
â”œâ”€â”€ 04-Archive/            # Archivierte Inhalte
â””â”€â”€ 05-Templates/          # Obsidian-Templates
```

## Schnellstart

### 1. Sync durchfÃ¼hren
```powershell
.\second-brain\scripts\sync-openclaw-to-secondbrain.ps1
```

### 2. Dashboard Ã¶ffnen
Ã–ffne `00-Dashboard/Dashboard.md` in Obsidian

### 3. Empfohlene Plugins
- **Dataview** - Dynamische Queries (erforderlich)
- **Templater** - Erweiterte Templates
- **Git** - Versionskontrolle

## Features

### Automatische Synchronisation
- Sessions aus `memory/` werden automatisch Ã¼bernommen
- Code-BlÃ¶cke werden extrahiert und verlinkt
- Metadaten werden in YAML-Frontmatter Ã¼berfÃ¼hrt

### Dashboard-Ansicht
- Letzte Sessions
- Offene TODOs
- Unentschiedene Entscheidungen
- Projekt-Fortschritt

### VerknÃ¼pfungen
Alle Inhalte sind Ã¼ber Backlinks verbunden:
- Sessions verlinken auf Entscheidungen
- Projekte sammeln zugehÃ¶rige Sessions
- Code-BlÃ¶cke zeigen auf ihre Quelle

## Templates

### Session Template
```yaml
---
date: 2026-03-26
time: 14:30
session_id: 20260326143000
agent: andrew-main
tokens_in: 5000
tokens_out: 1200
cost: 0.0240
status: completed
tags: [architecture, decision]
---
```

### Decision Template (ADR)
```yaml
---
date: 2026-03-26
adr_id: ADR-001
title: Use YAML for Registry
status: Accepted
priority: High
---
```

### Project Template
```yaml
---
date: 2026-03-26
project_id: PROJ-001
title: Modular Framework
status: Active
progress: 75
---
```

## Dataview Queries

### Alle Sessions anzeigen
```dataview
TABLE date, tokens_in, tokens_out
FROM "second-brain/01-Sessions"
SORT date DESC
```

### Offene Entscheidungen
```dataview
TABLE status, priority
FROM "second-brain/02-Areas/Decisions"
WHERE status = "Proposed"
```

### Projekt-Fortschritt
```dataview
TABLE progress, status
FROM "second-brain/02-Areas/Projects"
```

## Integration mit Framework

Das Second Brain ist Teil des Frameworks:
- Sessions werden aus `memory/` gesynct
- Entscheidungen kommen aus `registry/ADRs.md`
- Projekte kommen aus `plans/`
- Code-BlÃ¶cke werden aus Sessions extrahiert

## Workflow

1. **Session beenden** â†’ Wird automatisch in `memory/` gespeichert
2. **Sync ausfÃ¼hren** â†’ `sync-openclaw-to-secondbrain.ps1`
3. **Dashboard prÃ¼fen** â†’ Ãœbersicht Ã¼ber alle AktivitÃ¤ten
4. **Entscheidungen dokumentieren** â†’ ADR erstellen
5. **Projekte tracken** â†’ Fortschritt aktualisieren

## Lizenz

MIT License - Teil des Modular Agent Frameworks
