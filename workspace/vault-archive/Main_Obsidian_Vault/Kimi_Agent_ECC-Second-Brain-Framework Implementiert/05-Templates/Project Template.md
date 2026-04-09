---
project: {{project_name}}
status: {{status}}
priority: {{priority}}
start_date: {{start_date}}
due_date: {{due_date}}
progress: {{progress}}
tags: [project, {{project_name}}]
---

# Projekt: {{project_name}}

## Übersicht

**Status:** {{status}}

**Priorität:** {{priority}}

**Zeitraum:** {{start_date}} → {{due_date}}

**Fortschritt:** {{progress}}

## Beschreibung

{{description}}

## Ziele

- [ ] Ziel 1
- [ ] Ziel 2
- [ ] Ziel 3

## Sessions

```dataview
TABLE
  title AS "Session",
  token_usage AS "Tokens",
  created AS "Erstellt"
FROM "01-Sessions"
WHERE project = "{{project_name}}"
SORT created DESC
```

## Entscheidungen

```dataview
TABLE
  decision AS "Entscheidung",
  status AS "Status",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE project = "{{project_name}}"
SORT created DESC
```

## Offene TODOs

```dataview
TASK
FROM "01-Sessions"
WHERE !completed AND project = "{{project_name}}"
SORT created DESC
```

## Ressourcen

- *Links zu relevanten Ressourcen...*

## Notizen

*Projekt-spezifische Notizen...*

---

*Erstellt: {{created}}*
