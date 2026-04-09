---
date: {{date:YYYY-MM-DD}}
project_id: PROJ-{{sequence:001}}
title: {{Projektname}}
status: Active  # Active | Paused | Completed | Cancelled
priority: Medium
progress: 0
area: {{Bereich}}
tags: [project]
---

# PROJ-{{sequence:001}}: {{Projektname}}

## Beschreibung
{{Was ist das Ziel dieses Projekts?}}

## Ziele
- [ ] Ziel 1
- [ ] Ziel 2
- [ ] Ziel 3

## Phasen
| Phase | Status | Fortschritt |
|-------|--------|-------------|
| 1. Planning | ⬜ | 0% |
| 2. Implementation | ⬜ | 0% |
| 3. Testing | ⬜ | 0% |
| 4. Deployment | ⬜ | 0% |

## Sessions
```dataview
TABLE date as Datum, summary as Zusammenfassung
FROM "second-brain/01-Sessions"
WHERE contains(projects, "PROJ-{{sequence:001}}")
SORT date DESC
```

## Entscheidungen
```dataview
TABLE status as Status
FROM "second-brain/02-Areas/Decisions"
WHERE contains(projects, "PROJ-{{sequence:001}}")
```

## Ressourcen
- [[03-Resources/|Dokumentation]]
- [[03-Resources/CodeBlocks/|Code-Beispiele]]

## Notizen
{{Projekt-Notizen}}
