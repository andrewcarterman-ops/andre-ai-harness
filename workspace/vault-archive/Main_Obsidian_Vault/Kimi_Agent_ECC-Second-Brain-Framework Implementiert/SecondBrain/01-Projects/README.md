---
tags:
  - projects
  - index
  - para
---

# 01 - Projects 🚀

> **Active Projects** - Projekte mit definiertem Ziel und Deadline

---

## Definition

Ein Projekt ist:
- Ein **Ziel** mit definiertem Ergebnis
- Eine **Deadline** oder Zeitrahmen
- Mehrere **Tasks** zur Erreichung

---

## Aktive Projekte

```dataview
TABLE status, priority, startDate, dueDate, completion
FROM "01-Projects"
WHERE status = "active"
SORT priority DESC, dueDate ASC
```

---

## Projekte nach Status

### 🟢 Aktiv
```dataview
LIST
FROM "01-Projects"
WHERE status = "active"
```

### 🟡 Geplant
```dataview
LIST
FROM "01-Projects"
WHERE status = "planned"
```

### 🔴 Blockiert
```dataview
LIST
FROM "01-Projects"
WHERE status = "blocked"
```

### ✅ Abgeschlossen
```dataview
LIST
FROM "01-Projects"
WHERE status = "completed"
```

---

## Templates

- [[template-project|Projekt-Template]]

---

## Project Statistics

```dataview
TABLE length(rows) as Count
FROM "01-Projects"
GROUP BY status
```

---

*PARA Method - ECC Second Brain Framework*
