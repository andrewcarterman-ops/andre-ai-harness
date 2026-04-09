---
tags:
  - dataview
  - queries
  - index
---

# Dataview Queries

> Sammlung von Dataview-Queries für das ECC Second Brain

---

## Offene TODOs

### Alle offenen TODOs
```dataview
TASK
FROM #todo
WHERE !completed
SORT priority DESC, dueDate ASC
```

### TODOs nach Projekt gruppiert
```dataview
TASK
FROM #todo
WHERE !completed
GROUP BY file.folder AS Project
SORT priority DESC, dueDate ASC
```

### Überfällige TODOs
```dataview
TASK
FROM #todo
WHERE !completed AND dueDate < date(today)
SORT dueDate ASC
```

---

## Entscheidungen

### Alle Entscheidungen
```dataview
TABLE decision_id, status, date
FROM #decision
SORT date DESC
```

### Akzeptierte Entscheidungen
```dataview
TABLE decision_id, date
FROM #decision
WHERE status = "accepted"
SORT date DESC
LIMIT 10
```

### Ausstehende Entscheidungen
```dataview
TABLE decision_id, date
FROM #decision
WHERE status = "proposed"
SORT date DESC
```

---

## Sessions

### Letzte Sessions
```dataview
TABLE session_id, date, tokens_used, agent_mode
FROM "05-Daily"
WHERE session_id
SORT date DESC
LIMIT 10
```

### Sessions nach Token-Usage
```dataview
TABLE session_id, date, tokens_used, agent_mode
FROM "05-Daily"
SORT tokens_used DESC
LIMIT 10
```

### Token Usage pro Monat
```dataview
TABLE sum(tokens_used) as "Total Tokens"
FROM "05-Daily"
GROUP BY dateformat(date, "yyyy-MM") as Month
SORT Month DESC
```

---

## Projekte

### Aktive Projekte
```dataview
TABLE status, priority, startDate, dueDate, completion
FROM "01-Projects"
WHERE status = "active"
SORT priority DESC, dueDate ASC
```

### Alle Projekte nach Status
```dataview
TABLE length(rows) as Count
FROM "01-Projects"
GROUP BY status
```

---

## Bereiche

### Alle Bereiche
```dataview
TABLE status, priority, category, lastReviewed
FROM "02-Areas"
WHERE file.name != "README"
SORT priority DESC
```

---

## Code Blocks

### Code-Snippets Index
```dataview
LIST
FROM "03-Resources/Snippets"
WHERE file.content contains "```"
```

### Nach Sprache
```dataview
LIST
FROM "03-Resources/Snippets"
WHERE file.content contains "```powershell"
```

---

## Tag-Analyse

### Tag-Cloud
```dataview
TABLE length(rows) as Count
FLATTEN file.tags as Tag
FROM ""
WHERE !contains(["#decision", "#todo", "#insight", "#session", "#context", "#project", "#area"], Tag)
GROUP BY Tag
WHERE length(rows) >= 2
SORT length(rows) DESC
LIMIT 20
```

---

## Dashboard

### Wöchentliche Übersicht
```dataview
TABLE
  length(filter(file.tasks, (t) => !t.completed)) as "Open Tasks",
  length(filter(file.tasks, (t) => t.completed)) as "Completed Tasks"
FROM "05-Daily"
WHERE date >= date(today) - dur(7 days)
GROUP BY dateformat(date, "yyyy-MM-dd") as Day
SORT Day DESC
```

---

*Dataview Queries - ECC Second Brain Framework*
