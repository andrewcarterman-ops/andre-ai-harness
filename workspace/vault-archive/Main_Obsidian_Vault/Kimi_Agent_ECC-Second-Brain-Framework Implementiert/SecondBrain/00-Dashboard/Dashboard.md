---
tags:
  - dashboard
  - index
---

# ECC Second Brain Dashboard 📊

> **Zentrales Dashboard** für alle wichtigen Metriken und Übersichten

---

## Quick Stats

```dataviewjs
const sessions = dv.pages('"05-Daily"').where(p => p.session_id);
const totalTokens = sessions.values.reduce((acc, p) => acc + (p.tokens_used || 0), 0);
const totalSessions = sessions.length;
const avgTokens = totalSessions > 0 ? Math.round(totalTokens / totalSessions) : 0;

dv.table(
    ["Metric", "Value"],
    [
        ["Total Sessions", totalSessions],
        ["Total Tokens Used", totalTokens.toLocaleString()],
        ["Avg Tokens/Session", avgTokens.toLocaleString()],
        ["Active Projects", dv.pages('"01-Projects"').where(p => p.status === "active").length],
        ["Open TODOs", dv.pages().file.tasks.where(t => !t.completed && t.text.includes("#todo")).length]
    ]
);
```

---

## Aktive Projekte

```dataview
TABLE status, priority, completion + "%" as Progress
FROM "01-Projects"
WHERE status = "active"
SORT priority DESC, completion DESC
```

---

## Offene TODOs

```dataview
TASK
FROM #todo
WHERE !completed
SORT priority DESC, dueDate ASC
LIMIT 10
```

---

## Letzte Sessions

```dataview
TABLE session_id, tokens_used, agent_mode
FROM "05-Daily"
WHERE session_id
SORT date DESC
LIMIT 7
```

---

## Entscheidungen

```dataview
TABLE decision_id, status, date
FROM #decision
SORT date DESC
LIMIT 5
```

---

## Token Usage (Letzte 30 Tage)

```dataview
TABLE sum(tokens_used) as "Tokens"
FROM "05-Daily"
WHERE date >= date(today) - dur(30 days)
GROUP BY dateformat(date, "yyyy-MM-dd") as Day
SORT Day DESC
```

---

## Tag-Cloud

```dataview
TABLE length(rows) as Count
FLATTEN file.tags as Tag
FROM ""
WHERE !contains(["#decision", "#todo", "#insight", "#session", "#context", "#project", "#area"], Tag)
GROUP BY Tag
WHERE length(rows) >= 2
SORT length(rows) DESC
LIMIT 15
```

---

## Sync-Status

- **Letzter Sync**: 
- **Vault-Version**: 1.0.0
- **Framework**: ECC Second Brain

---

*ECC Second Brain Dashboard*
