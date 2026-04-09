---
tags:
  - archive
  - index
  - para
---

# 04 - Archive 📦

> **Completed Sessions** - Abgeschlossene Sessions und Projekte

---

## Definition

Das Archiv enthält:
- **Abgeschlossene** Projekte
- **Alte** Sessions
- **Nicht mehr relevante** Notizen
- **Referenzmaterial** für die Zukunft

---

## Archivierte Sessions

```dataview
TABLE session_id, date, tokens_used, agent_mode
FROM "04-Archive"
WHERE file.name != "README"
SORT date DESC
```

---

## Archivierte Projekte

```dataview
TABLE completionDate, status
FROM "01-Projects"
WHERE status = "archived"
SORT completionDate DESC
```

---

## Archive Statistics

```dataview
TABLE length(rows) as Count
FROM "04-Archive"
GROUP BY dateformat(date, "yyyy-MM") as Month
```

---

## Templates

- [[template-archived-session|Archived Session Template]]

---

*PARA Method - ECC Second Brain Framework*
