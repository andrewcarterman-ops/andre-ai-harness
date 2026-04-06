# Second Brain für OpenClaw

Ein PARA-basiertes Second Brain System für OpenClaw Sessions.

## PARA-Struktur

```
second-brain/
├── 00-Dashboard/          # Übersichten und Dashboards
│   └── Dashboard.md       # Haupt-Dashboard mit Dataview
├── 01-Sessions/           # OpenClaw Sessions (automatisch)
├── 02-Areas/              # Lebensbereiche
│   ├── Decisions/         # Architektur-Entscheidungen (ADRs)
│   └── Projects/          # Aktive Projekte
├── 03-Resources/          # Ressourcen
│   ├── CodeBlocks/        # Extrahierte Code-Snippets
│   └── Dataview/          # Query-Templates
├── 04-Archive/            # Archivierte Inhalte
└── 05-Templates/          # Obsidian-Templates
```

## Schnellstart

### 1. Sync durchführen
```powershell
.\second-brain\scripts\sync-openclaw-to-secondbrain.ps1
```

### 2. Dashboard öffnen
Öffne `00-Dashboard/Dashboard.md` in Obsidian

### 3. Empfohlene Plugins
- **Dataview** - Dynamische Queries (erforderlich)
- **Templater** - Erweiterte Templates
- **Git** - Versionskontrolle

## Features

### Automatische Synchronisation
- Sessions aus `memory/` werden automatisch übernommen
- Code-Blöcke werden extrahiert und verlinkt
- Metadaten werden in YAML-Frontmatter überführt

### Dashboard-Ansicht
- Letzte Sessions
- Offene TODOs
- Unentschiedene Entscheidungen
- Projekt-Fortschritt

### Verknüpfungen
Alle Inhalte sind über Backlinks verbunden:
- Sessions verlinken auf Entscheidungen
- Projekte sammeln zugehörige Sessions
- Code-Blöcke zeigen auf ihre Quelle

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
- Code-Blöcke werden aus Sessions extrahiert

## Workflow

1. **Session beenden** → Wird automatisch in `memory/` gespeichert
2. **Sync ausführen** → `sync-openclaw-to-secondbrain.ps1`
3. **Dashboard prüfen** → Übersicht über alle Aktivitäten
4. **Entscheidungen dokumentieren** → ADR erstellen
5. **Projekte tracken** → Fortschritt aktualisieren

## Lizenz

MIT License - Teil des Modular Agent Frameworks
