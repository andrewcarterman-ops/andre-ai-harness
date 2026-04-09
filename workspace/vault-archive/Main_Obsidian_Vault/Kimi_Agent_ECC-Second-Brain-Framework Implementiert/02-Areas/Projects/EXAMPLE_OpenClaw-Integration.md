---
project: OpenClaw-Integration
status: active
priority: high
start_date: 2024-01-15
due_date: 2024-02-15
progress: 75%
tags: [project, OpenClaw-Integration, sync]
---

# Projekt: OpenClaw-Integration

## Übersicht

**Status:** active

**Priorität:** high

**Zeitraum:** 2024-01-15 → 2024-02-15

**Fortschritt:** 75%

## Beschreibung

Integration zwischen OpenClaw-Sessions und Obsidian Vault für nahtlose Wissensverwaltung.

## Ziele

- [x] Sync-Skript erstellen
- [x] Mermaid-Integration
- [x] Dataview-Queries
- [ ] Tests durchführen
- [ ] Dokumentation vervollständigen

## Sessions

```dataview
TABLE
  title AS "Session",
  token_usage AS "Tokens",
  created AS "Erstellt"
FROM "01-Sessions"
WHERE project = "OpenClaw-Integration"
SORT created DESC
```

## Entscheidungen

```dataview
TABLE
  decision AS "Entscheidung",
  status AS "Status",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE project = "OpenClaw-Integration"
SORT created DESC
```

## Offene TODOs

```dataview
TASK
FROM "01-Sessions"
WHERE !completed AND project = "OpenClaw-Integration"
SORT created DESC
```

## Ressourcen

- [PowerShell Dokumentation](https://docs.microsoft.com/powershell/)
- [Obsidian Dataview](https://blacksmithgu.github.io/obsidian-dataview/)
- [Mermaid Diagrams](https://mermaid-js.github.io/)

## Notizen

- Registry-Pfad: `HKCU:\Software\OpenClaw\Sessions`
- Vault-Pfad: `C:\Users\andre\Documents\Andrew Openclaw\SecondBrain`

---

*Erstellt: 2024-01-15*
