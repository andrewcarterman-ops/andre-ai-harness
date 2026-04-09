# SecondBrain - OpenClaw Obsidian Vault

Dies ist ein Obsidian Vault für die Integration mit OpenClaw-Sessions.

## Struktur

```
SecondBrain/
├── 00-Dashboard/          # Dashboards und Übersichten
│   └── Dashboard.md       # Haupt-Dashboard
├── 01-Sessions/           # OpenClaw Session-Notes
│   └── EXAMPLE_sess_001.md
├── 02-Areas/              # Lebensbereiche
│   ├── Decisions/         # Entscheidungen (ADRs)
│   └── Projects/          # Projekte
├── 03-Resources/          # Ressourcen
│   ├── CodeBlocks/        # Extrahierte Code-Blöcke
│   └── Dataview/          # Dataview-Queries
├── 04-Archive/            # Archiv
├── 05-Templates/          # Templates
│   ├── Session Template.md
│   ├── Decision Template.md
│   └── Project Template.md
├── scripts/               # Sync-Skripte
│   ├── sync-openclaw-to-obsidian.ps1
│   ├── sync.bat
│   ├── setup-registry.ps1
│   └── lib/
│       ├── MermaidGenerator.psm1
│       └── DataviewQuery.psm1
└── .obsidian/             # Obsidian-Konfiguration
    └── plugins/
        └── ecc-vault/
            └── sync-config.json
```

## Schnellstart

1. **Obsidian öffnen** und diesen Vault laden
2. **Dataview Plugin** installieren (Community Plugins)
3. **Sync-Skript ausführen**:
   ```powershell
   .\scripts\sync-openclaw-to-obsidian.ps1
   ```
   Oder einfach per Batch:
   ```
   .\scripts\sync.bat
   ```

## Features

- **Automatische Synchronisation** von OpenClaw-Sessions
- **YAML-Frontmatter** für strukturierte Metadaten
- **Mermaid-Diagramme** für Visualisierungen
- **Code-Block-Extraktion** mit Syntax-Highlighting
- **Backlinks** für verbundene Sessions
- **Dataview-Queries** für Analysen und Übersichten

## Dashboard

Öffne `00-Dashboard/Dashboard.md` für eine Übersicht:
- Sessions nach Token-Usage
- Offene TODOs
- Unentschiedene Entscheidungen
- Projekt-Fortschritt
- Kostenanalyse

## Konfiguration

Passe die Synchronisation in `.obsidian/plugins/ecc-vault/sync-config.json` an:
- Sync-Verhalten
- Ordnerstruktur
- Feld-Mapping
- Retry-Logik
- Logging

## Empfohlene Plugins

- **Dataview** - Dynamische Queries
- **Templater** - Erweiterte Templates
- **Git** - Versionskontrolle
- **Calendar** - Kalender-Ansicht
- **Kanban** - Kanban-Boards

## Lizenz

MIT License
