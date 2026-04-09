---
date: {{date:YYYY-MM-DD}}
project_id: PROJ-XXX
title: 
status: Active
progress: 0
priority: Medium
tags: [project]
---

# PROJ-XXX: {{title}}

## Übersicht

| Attribut | Wert |
|----------|------|
| **Startdatum** | {{date:YYYY-MM-DD}} |
| **Status** | Active |
| **Fortschritt** | 0% |
| **Priorität** | Medium |

---

## Ziel

> Was soll erreicht werden?

---

## Aufgaben

- [ ] Aufgabe 1
- [ ] Aufgabe 2
- [ ] Aufgabe 3

---

## Sessions

```dataview
TABLE date as "Datum", summary as "Zusammenfassung"
FROM "SecondBrain/01-Sessions"
WHERE contains(projects, this.project_id)
SORT date DESC
```

---

## Entscheidungen

```dataview
TABLE status as "Status", priority as "Priorität"
FROM "SecondBrain/02-Areas/Decisions"
WHERE contains(projects, this.project_id)
SORT priority DESC
```

---

## Code-Snippets

```dataview
LIST
FROM "SecondBrain/03-Resources/CodeBlocks"
WHERE contains(projects, this.project_id)
```

---

## Notizen

---

#project #active
