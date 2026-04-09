# OpenClaw Dashboard

## Schnellübersicht

```dataviewjs
const totalSessions = dv.pages('"01-Sessions"').length;
const totalTokens = dv.pages('"01-Sessions"').token_usage.array().reduce((a, b) => a + b, 0);
const totalCost = dv.pages('"01-Sessions"').cost.array().reduce((a, b) => a + b, 0);
const openTodos = dv.pages().file.tasks.where(t => !t.completed).length;
const openDecisions = dv.pages('"02-Areas/Decisions"').where(p => p.status == "proposed").length;

dv.table(
  ["📊 Metrik", "📈 Wert"],
  [
    ["📝 Sessions", totalSessions],
    ["🔤 Gesamt Tokens", totalTokens.toLocaleString()],
    ["💰 Gesamt Kosten", "$" + totalCost.toFixed(2)],
    ["☑️ Offene TODOs", openTodos],
    ["❓ Unentschiedene Entscheidungen", openDecisions]
  ]
);
```

---

## Heutige Sessions

```dataview
TABLE
  title AS "Titel",
  token_usage AS "Tokens",
  cost AS "Kosten",
  project AS "Projekt"
FROM "01-Sessions"
WHERE created >= date(today)
SORT created DESC
```

---

## Diese Woche

```dataview
TABLE
  title AS "Titel",
  token_usage AS "Tokens",
  project AS "Projekt",
  created AS "Erstellt"
FROM "01-Sessions"
WHERE created >= date(today - 7 days)
SORT created DESC
```

---

## Offene TODOs (Top 10)

```dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed
SORT created DESC
LIMIT 10
```

---

## Überfällige TODOs

```dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed AND created < date(today - 7 days)
SORT created ASC
```

---

## Unentschiedene Entscheidungen

```dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  date(today) - created AS "Tage offen"
FROM "02-Areas/Decisions"
WHERE status = "proposed"
SORT created ASC
LIMIT 5
```

---

## Aktive Projekte

```dataview
TABLE
  project AS "Projekt",
  priority AS "Priorität",
  progress AS "Fortschritt",
  due_date AS "Fällig"
FROM "02-Areas/Projects"
WHERE status = "active"
SORT priority DESC, due_date ASC
```

---

## Token-Usage nach Projekt

```dataview
TABLE WITHOUT ID
  project AS "Projekt",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
GROUP BY project
SORT sum(rows.token_usage) DESC
```

---

## Aktivitäts-Kalender

```dataview
CALENDAR created
FROM "01-Sessions"
```

---

## Top Sessions (nach Token-Usage)

```dataview
TABLE
  title AS "Titel",
  project AS "Projekt",
  token_usage AS "Tokens",
  cost AS "Kosten"
FROM "01-Sessions"
SORT token_usage DESC
LIMIT 10
```

---

## Monatliche Kosten

```dataview
TABLE WITHOUT ID
  dateformat(created, "yyyy-MM") AS "Monat",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
GROUP BY dateformat(created, "yyyy-MM")
SORT dateformat(created, "yyyy-MM") DESC
LIMIT 12
```

---

## Unbenutzte Code-Blocks

```dataview
TABLE
  file.name AS "Code-Block",
  file.ctime AS "Erstellt",
  date(today) - file.ctime AS "Tage unbenutzt"
FROM "03-Resources/CodeBlocks"
WHERE !file.inlinks
SORT file.ctime ASC
LIMIT 10
```

---

## Tag-Cloud

```dataview
TABLE WITHOUT ID
  tag AS "Tag",
  length(rows.file.name) AS "Häufigkeit"
FROM "01-Sessions" OR "02-Areas" OR "03-Resources"
FLATTEN tags AS tag
WHERE tag != null
GROUP BY tag
SORT length(rows.file.name) DESC
LIMIT 20
```

---

*Letzte Aktualisierung: `=dateformat(this.file.mtime, "yyyy-MM-dd HH:mm")`*
