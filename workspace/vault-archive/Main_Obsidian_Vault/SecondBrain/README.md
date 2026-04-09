# Merged Second Brain

PARA-basiertes Second Brain für OpenClaw Sessions.

> **Hinweis:** Dies ist das MERGED Second Brain - kombiniert das beste aus beiden Welten:
> - Fortgeschrittenes Sync-Script (vom Original)
> - Erweiterte Dashboard-Queries (neu)
> - Optimierte Templates (neu)

## PARA-Struktur

```
SecondBrain/
├── 00-Dashboard/          # Übersichten und Dashboards
│   └── Dashboard.md       # Haupt-Dashboard mit Dataview
├── 01-Sessions/           # OpenClaw Sessions (auto-sync)
├── 02-Areas/              # Lebensbereiche
│   ├── Decisions/         # Architektur-Entscheidungen (ADRs)
│   └── Projects/          # Aktive Projekte
├── 03-Resources/          # Ressourcen
│   ├── CodeBlocks/        # Extrahierte Code-Snippets
│   └── Dataview/          # Query-Templates
├── 04-Archive/            # Archivierte Inhalte
└── 05-Templates/          # Obsidian-Templates
    ├── Session-Template.md
    ├── ADR-Template.md
    └── Project-Template.md
```

## Schnellstart

### 1. Vault öffnen
Öffne `C:\Users\andre\Documents\Andrew Openclaw` in Obsidian.

### 2. Plugins installieren
- **Dataview** (erforderlich) - für Dashboard-Queries
- **Templater** (empfohlen) - für Templates
- **Git** (optional)

### 3. Sync durchführen
```powershell
.\SecondBrain\scripts\sync-openclaw-to-secondbrain.ps1
```

### 4. Dashboard öffnen
Gehe zu `SecondBrain/00-Dashboard/Dashboard.md`

## Sync-Features

Das Sync-Script übernimmt automatisch:

| Quelle | Ziel | Beschreibung |
|--------|------|--------------|
| `~/.openclaw/workspace/memory/` | `01-Sessions/` | Session-Logs |
| `~/.openclaw/workspace/plans/` | `02-Areas/Projects/` | Projekt-Pläne |
| Session-Inhalte | `03-Resources/CodeBlocks/` | Code-Snippets (auto-extrahiert) |

## Templates

| Template | Zweck |
|----------|-------|
| Session-Template | Neue OpenClaw Sessions |
| ADR-Template | Architektur-Entscheidungen |
| Project-Template | Projekt-Tracking |

## Dataview Queries

Alle Queries sind im Dashboard integriert:
- Letzte Sessions
- Aktive Projekte mit Fortschritt
- Offene Entscheidungen
- Code-Snippets

## Verknüpfungen

Alles ist über Backlinks verbunden:
- Sessions → Entscheidungen
- Projekte → Sessions
- Code-Blöcke → Sessions

---

Erstellt: 2026-04-05 (Merged)
