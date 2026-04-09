# OpenClaw → Obsidian Sync

PowerShell-basierte Synchronisation zwischen OpenClaw-Sessions und Obsidian Vault.

## Features

- **Automatische Session-Erfassung** aus Windows Registry
- **YAML-Frontmatter-Generierung** für Obsidian-Notes
- **Mermaid-Diagramme** für Systemarchitektur
- **Code-Block-Extraktion** mit Spracherkennung
- **Backlinks** zu vorherigen Sessions
- **Retry-Logik** für alle Operationen
- **Dataview-Queries** für Analysen

## Installation

1. Kopiere alle Dateien in dein Vault-Verzeichnis
2. Passe `sync-config.json` an deine Bedürfnisse an
3. Führe das Skript aus:

```powershell
.\sync-openclaw-to-obsidian.ps1
```

## Verwendung

### Standard-Sync

```powershell
.\sync-openclaw-to-obsidian.ps1
```

### Mit Parametern

```powershell
# Trockenlauf (keine Änderungen)
.\sync-openclaw-to-obsidian.ps1 -DryRun

# Spezifische Session
.\sync-openclaw-to-obsidian.ps1 -SessionId "sess_abc123"

# Erzwinge Überschreiben
.\sync-openclaw-to-obsidian.ps1 -Force

# Benutzerdefinierter Vault-Pfad
.\sync-openclaw-to-obsidian.ps1 -VaultPath "D:\\MeinVault"
```

## Dateistruktur

```
SecondBrain/
├── scripts/
│   ├── sync-openclaw-to-obsidian.ps1    # Hauptskript
│   ├── README.md                         # Diese Datei
│   ├── sync.bat                          # Batch-Wrapper
│   └── lib/
│       ├── MermaidGenerator.psm1         # Mermaid-Modul
│       └── DataviewQuery.psm1            # Dataview-Modul
├── .obsidian/
│   ├── plugins/
│   │   └── ecc-vault/
│   │       └── sync-config.json          # Konfiguration
│   └── logs/
│       └── sync.log                      # Sync-Log
├── 01-Sessions/                          # Session-Notes
├── 02-Areas/
│   ├── Decisions/                        # Entscheidungen
│   └── Projects/                         # Projekte
├── 03-Resources/
│   ├── CodeBlocks/                       # Extrahierte Code
│   └── Dataview/
│       └── queries.md                    # Dataview-Queries
├── 04-Archive/                           # Archiv
└── 05-Templates/                         # Templates
```

## Registry-Struktur

Das Skript erwartet Sessions im Registry-Pfad:

```
HKCU:\Software\OpenClaw\Sessions\
  ├── {SessionId1}\
  │     ├── SessionId
  │     ├── Title
  │     ├── Description
  │     ├── CreatedAt
  │     ├── UpdatedAt
  │     ├── TokenUsage
  │     ├── Cost
  │     ├── Model
  │     ├── Project
  │     ├── Tags
  │     ├── Status
  │     ├── Content
  │     ├── Decisions
  │     ├── Todos
  │     ├── CodeBlocks
  │     ├── PreviousSessionId
  │     └── RelatedSessions
  └── {SessionId2}\
        └── ...
```

## Module

### MermaidGenerator.psm1

```powershell
Import-Module .\lib\MermaidGenerator.psm1

# Architekturdiagramm
New-ArchitectureDiagram -Title "System" -Components $comps -Relationships $rels

# Flussdiagramm
New-Flowchart -Title "Workflow" -Steps $steps -Connections $conn

# Mindmap
New-Mindmap -Title "Overview" -Root "Project" -Branches $branches
```

### DataviewQuery.psm1

```powershell
Import-Module .\lib\DataviewQuery.psm1

# Offene TODOs
Get-OpenTodos -GroupBy project

# Entscheidungen
Get-RecentDecisions -Status proposed

# Session-Statistiken
Get-SessionStats -Metric tokens
```

## Konfiguration

Die `sync-config.json` enthält alle Einstellungen:

| Sektion | Beschreibung |
|---------|--------------|
| `sync` | Sync-Verhalten (auto, interval, dryRun) |
| `folders` | Ordnerstruktur im Vault |
| `mapping` | Feld-Mapping OpenClaw → Obsidian |
| `yamlFrontmatter` | YAML-Frontmatter-Einstellungen |
| `mermaid` | Mermaid-Diagramm-Einstellungen |
| `codeBlocks` | Code-Block-Extraktion |
| `retry` | Retry-Logik-Konfiguration |
| `logging` | Logging-Einstellungen |

## Troubleshooting

### Registry nicht gefunden

```powershell
# Prüfe Registry-Pfad
Test-Path "HKCU:\Software\OpenClaw\Sessions"

# Erstelle Fallback-JSON
New-Item -Path "${env:LOCALAPPDATA}\OpenClaw" -ItemType Directory
```

### Berechtigungsfehler

```powershell
# Als Administrator ausführen
Start-Process powershell -Verb RunAs -ArgumentList "-File .\sync-openclaw-to-obsidian.ps1"
```

### Encoding-Probleme

```powershell
# Setze UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

## Lizenz

MIT License - Andrew
