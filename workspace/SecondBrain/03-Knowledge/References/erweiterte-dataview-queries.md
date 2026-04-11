---
date: 10-04-2026
type: reference
category: reference
tags: [reference, dataview, queries, dashboard]
---

# Erweiterte Dataview-Queries

> Zusaetzliche Queries aus dem ECC-Framework fuer unser Dashboard

---

## Token-Statistiken

### Token Usage pro Monat
```dataview
TABLE sum(tokens_used) as "Total Tokens"
FROM "01-Daily"
WHERE session_id
GROUP BY dateformat(date, "yyyy-MM") as Month
SORT Month DESC
```

### Sessions nach Token-Usage (Top 10)
```dataview
TABLE session_id, date, tokens_used, agent_mode
FROM "01-Daily"
WHERE session_id
SORT tokens_used DESC
LIMIT 10
```

---

## TODOs

### Ueberfaellige TODOs
```dataview
TASK
FROM #todo
WHERE !completed AND dueDate < date(today)
SORT dueDate ASC
```

### TODOs nach Projekt gruppiert
```dataview
TASK
FROM #todo
WHERE !completed
GROUP BY file.folder AS Project
SORT priority DESC, dueDate ASC
```

---

## Areas

### Alle Areas (Verantwortungsbereiche)
```dataview
TABLE status, priority, category, lastReviewed
FROM "02-Areas"
WHERE file.name != "README"
SORT priority DESC
```

### Areas die Review brauchen
```dataview
TABLE lastReviewed, reviewInterval
FROM "02-Areas"
WHERE lastReviewed < date(today) - dur(7 days) AND reviewInterval = "weekly"
   OR lastReviewed < date(today) - dur(30 days) AND reviewInterval = "monthly"
SORT lastReviewed ASC
```

---

## Wochenuebersicht

### Tasks pro Tag (letzte 7 Tage)
```dataview
TABLE
  length(filter(file.tasks, (t) => !t.completed)) as "Open Tasks",
  length(filter(file.tasks, (t) => t.completed)) as "Completed Tasks"
FROM "01-Daily"
WHERE date >= date(today) - dur(7 days)
GROUP BY dateformat(date, "yyyy-MM-dd") as Day
SORT Day DESC
```

---

## Tag-Analyse

### Tag-Cloud (Top 20)
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

## Verwendung

Diese Queries koennen:
1. In `_MOC-Startseite.md` eingefuegt werden
2. Als separate Dashboard-Notizen verwendet werden
3. Nach Bedarf angepasst werden

---

*Aus ECC-Framework uebernommen*
