# Dataview Queries für OpenClaw-Obsidian Integration

Diese Datei enthält vorgefertigte Dataview-Queries für die Analyse und Übersicht deiner OpenClaw-Sessions und Projekte.

---

## Inhaltsverzeichnis

1. [Offene TODOs](#offene-todos)
2. [Entscheidungen](#entscheidungen)
3. [Session-Statistiken](#session-statistiken)
4. [Projektübersichten](#projektübersichten)
5. [Code-Block Index](#code-block-index)
6. [Tag-Analysen](#tag-analysen)
7. [Zeiterfassung](#zeiterfassung)
8. [Dashboard](#dashboard)

---

## Offene TODOs

### Alle offenen TODOs

```dataview
TASK
FROM "01-Sessions" OR "02-Areas" OR "03-Resources"
WHERE !completed
SORT created DESC
LIMIT 100
```

### TODOs nach Projekt gruppiert

```dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed
GROUP BY project AS Projekt
SORT project ASC
```

### TODOs nach Priorität

#### Hohe Priorität (!)

```dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed AND text.contains("!")
SORT created DESC
```

#### Normale Priorität

```dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed AND !text.contains("!") AND !text.contains("?")
SORT created DESC
```

#### Niedrige Priorität (?)

```dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed AND text.contains("?")
SORT created DESC
```

### Überfällige TODOs (älter als 7 Tage)

```dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed AND created < date(today - 7 days)
SORT created ASC
```

### TODO-Statistik pro Session

```dataview
TABLE WITHOUT ID
  file.link AS "Session",
  length(filter(file.tasks, (t) => !t.completed)) AS "Offen",
  length(filter(file.tasks, (t) => t.completed)) AS "Erledigt",
  length(file.tasks) AS "Gesamt",
  round(length(filter(file.tasks, (t) => t.completed)) / length(file.tasks) * 100, 1) + "%" AS "Fortschritt"
FROM "01-Sessions"
WHERE file.tasks
SORT length(filter(file.tasks, (t) => !t.completed)) DESC
```

---

## Entscheidungen

### Alle Entscheidungen

```dataview
TABLE
  decision AS "Entscheidung",
  status AS "Status",
  project AS "Projekt",
  session_id AS "Session",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE file.name != "README"
SORT created DESC
```

### Unentschiedene Entscheidungen (Status: proposed)

```dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  session_id AS "Session",
  created AS "Erstellt",
  date(today) - created AS "Tage offen"
FROM "02-Areas/Decisions"
WHERE status = "proposed"
SORT created ASC
```

### Entscheidungen nach Status

#### Vorgeschlagen

```dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE status = "proposed"
SORT created DESC
```

#### Genehmigt

```dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE status = "approved"
SORT created DESC
```

#### Implementiert

```dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE status = "implemented"
SORT created DESC
```

#### Verworfen

```dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE status = "rejected"
SORT created DESC
```

### Entscheidungs-Timeline

```dataview
CALENDAR created
FROM "02-Areas/Decisions"
WHERE status != "rejected"
```

---

## Session-Statistiken

### Gesamtübersicht

```dataview
TABLE WITHOUT ID
  length(rows.session_id) AS "Anzahl Sessions",
  sum(rows.token_usage) AS "Gesamt Tokens",
  round(sum(rows.cost), 2) AS "Gesamt Kosten",
  round(avg(rows.token_usage), 0) AS "Ø Tokens/Session"
FROM "01-Sessions"
GROUP BY true
```

### Sessions nach Token-Usage (Top 20)

```dataview
TABLE
  title AS "Titel",
  project AS "Projekt",
  token_usage AS "Tokens",
  cost AS "Kosten",
  model AS "Modell"
FROM "01-Sessions"
SORT token_usage DESC
LIMIT 20
```

### Sessions nach Projekt gruppiert

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

### Token-Usage nach Modell

```dataview
TABLE WITHOUT ID
  model AS "Modell",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Gesamt Tokens",
  round(avg(rows.token_usage), 0) AS "Ø Tokens"
FROM "01-Sessions"
GROUP BY model
SORT sum(rows.token_usage) DESC
```

### Tägliche Session-Statistik

```dataview
TABLE WITHOUT ID
  dateformat(created, "yyyy-MM-dd") AS "Datum",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
GROUP BY dateformat(created, "yyyy-MM-dd")
SORT dateformat(created, "yyyy-MM-dd") DESC
LIMIT 30
```

### Monatliche Kostenanalyse

```dataview
TABLE WITHOUT ID
  dateformat(created, "yyyy-MM") AS "Monat",
  round(sum(rows.cost), 2) AS "Kosten",
  sum(rows.token_usage) AS "Tokens",
  length(rows.session_id) AS "Sessions"
FROM "01-Sessions"
GROUP BY dateformat(created, "yyyy-MM")
SORT dateformat(created, "yyyy-MM") DESC
```

### Aktivitäts-Kalender

```dataview
CALENDAR created
FROM "01-Sessions"
```

---

## Projektübersichten

### Alle Projekte

```dataview
TABLE
  project AS "Projekt",
  status AS "Status",
  priority AS "Priorität",
  start_date AS "Start",
  due_date AS "Fällig",
  progress AS "Fortschritt"
FROM "02-Areas/Projects"
WHERE file.name != "README"
SORT priority DESC, due_date ASC
```

### Aktive Projekte

```dataview
TABLE
  project AS "Projekt",
  priority AS "Priorität",
  due_date AS "Fällig",
  progress AS "Fortschritt"
FROM "02-Areas/Projects"
WHERE status = "active"
SORT priority DESC, due_date ASC
```

### Projekte mit Session-Metriken

```dataview
TABLE WITHOUT ID
  project AS "Projekt",
  length(filter(file.tasks, (t) => !t.completed)) AS "Offene TODOs",
  length(filter(file.tasks, (t) => t.completed)) AS "Erledigt",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
WHERE project != null
GROUP BY project
SORT sum(rows.token_usage) DESC
```

### Projekt-Timeline (Start-Daten)

```dataview
CALENDAR start_date
FROM "02-Areas/Projects"
WHERE status = "active"
```

### Projekt-Timeline (Fälligkeits-Daten)

```dataview
CALENDAR due_date
FROM "02-Areas/Projects"
WHERE status = "active"
```

---

## Code-Block Index

### Alle Code-Blocks

```dataview
TABLE
  file.name AS "Datei",
  file.ctime AS "Erstellt",
  file.mtime AS "Geändert"
FROM "03-Resources/CodeBlocks"
WHERE file.name != "README"
SORT file.ctime DESC
```

### Code-Blocks nach Sprache

```dataview
TABLE WITHOUT ID
  substring(file.name, reverse(string(file.name)).indexOf(".") * -1) AS "Sprache",
  length(rows.file.name) AS "Anzahl",
  rows.file.name AS "Dateien"
FROM "03-Resources/CodeBlocks"
GROUP BY substring(file.name, reverse(string(file.name)).indexOf(".") * -1)
SORT length(rows.file.name) DESC
```

### Code-Blocks mit Session-Links

```dataview
TABLE
  file.name AS "Code-Block",
  file.inlinks AS "Verlinkt von",
  file.ctime AS "Erstellt"
FROM "03-Resources/CodeBlocks"
WHERE file.inlinks
SORT file.ctime DESC
```

### Unbenutzte Code-Blocks

```dataview
TABLE
  file.name AS "Code-Block",
  file.ctime AS "Erstellt",
  date(today) - file.ctime AS "Tage unbenutzt"
FROM "03-Resources/CodeBlocks"
WHERE !file.inlinks
SORT file.ctime ASC
```

### PowerShell Code-Blocks

```dataview
TABLE
  file.name AS "Datei",
  file.inlinks AS "Verlinkt von"
FROM "03-Resources/CodeBlocks"
WHERE file.name.contains(".ps1") OR file.name.contains(".powershell")
SORT file.ctime DESC
```

---

## Tag-Analysen

### Tag-Cloud (alle Tags)

```dataview
TABLE WITHOUT ID
  tag AS "Tag",
  length(rows.file.name) AS "Häufigkeit",
  rows.file.name AS "Dateien"
FROM "01-Sessions" OR "02-Areas" OR "03-Resources"
FLATTEN tags AS tag
WHERE tag != null
GROUP BY tag
SORT length(rows.file.name) DESC
```

### Häufigste Tags (min. 2 Vorkommen)

```dataview
TABLE WITHOUT ID
  tag AS "Tag",
  length(rows.file.name) AS "Häufigkeit"
FROM "01-Sessions" OR "02-Areas" OR "03-Resources"
FLATTEN tags AS tag
WHERE tag != null
GROUP BY tag
SORT length(rows.file.name) DESC
WHERE length(rows.file.name) >= 2
```

### Projekt-Tags

```dataview
LIST
FROM "01-Sessions"
WHERE contains(tags, "project-")
FLATTEN filter(tags, (t) => contains(t, "project-")) AS project_tag
GROUP BY project_tag
```

### Technologie-Tags

```dataview
LIST
FROM "01-Sessions" OR "03-Resources"
WHERE contains(tags, "tech-") OR contains(tags, "lang-")
FLATTEN filter(tags, (t) => contains(t, "tech-") OR contains(t, "lang-")) AS tech_tag
GROUP BY tech_tag
```

---

## Zeiterfassung

### Tägliche Aktivität (letzte 30 Tage)

```dataview
TABLE WITHOUT ID
  dateformat(created, "yyyy-MM-dd") AS "Datum",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
GROUP BY dateformat(created, "yyyy-MM-dd")
SORT dateformat(created, "yyyy-MM-dd") DESC
LIMIT 30
```

### Wöchentliche Zusammenfassung

```dataview
TABLE WITHOUT ID
  dateformat(created, "yyyy-'W'WW") AS "Woche",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
GROUP BY dateformat(created, "yyyy-'W'WW")
SORT dateformat(created, "yyyy-'W'WW") DESC
LIMIT 12
```

### Monatliche Zusammenfassung

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

## Dashboard

### JavaScript Dashboard

```dataviewjs
const totalSessions = dv.pages('"01-Sessions"').length;
const totalTokens = dv.pages('"01-Sessions"').token_usage.array().reduce((a, b) => a + b, 0);
const totalCost = dv.pages('"01-Sessions"').cost.array().reduce((a, b) => a + b, 0);
const openTodos = dv.pages().file.tasks.where(t => !t.completed).length;
const openDecisions = dv.pages('"02-Areas/Decisions"').where(p => p.status == "proposed").length;

dv.table(
  ["Metrik", "Wert"],
  [
    ["Sessions", totalSessions],
    ["Gesamt Tokens", totalTokens.toLocaleString()],
    ["Gesamt Kosten", "$" + totalCost.toFixed(2)],
    ["Offene TODOs", openTodos],
    ["Unentschiedene Entscheidungen", openDecisions]
  ]
);
```

### Heutige Sessions

```dataview
TABLE
  title AS "Titel",
  token_usage AS "Tokens",
  project AS "Projekt"
FROM "01-Sessions"
WHERE created >= date(today)
SORT created DESC
```

### Diese Woche

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

### Diesen Monat

```dataview
TABLE
  title AS "Titel",
  token_usage AS "Tokens",
  project AS "Projekt",
  created AS "Erstellt"
FROM "01-Sessions"
WHERE created >= date(today - 30 days)
SORT created DESC
```

---

## Erweiterte Queries

### Sessions mit Backlinks

```dataview
TABLE
  title AS "Titel",
  file.inlinks AS "Eingehende Links",
  file.outlinks AS "Ausgehende Links"
FROM "01-Sessions"
WHERE file.inlinks OR file.outlinks
SORT length(file.inlinks) DESC
```

### Verwaiste Sessions (keine Links)

```dataview
TABLE
  title AS "Titel",
  created AS "Erstellt",
  date(today) - created AS "Tage verwaist"
FROM "01-Sessions"
WHERE !file.inlinks AND !file.outlinks
SORT created ASC
```

### Sessions mit vielen TODOs

```dataview
TABLE
  title AS "Titel",
  length(file.tasks) AS "TODOs",
  length(filter(file.tasks, (t) => !t.completed)) AS "Offen"
FROM "01-Sessions"
WHERE length(file.tasks) > 5
SORT length(file.tasks) DESC
```

### Sessions mit Code-Blocks

```dataview
TABLE
  title AS "Titel",
  project AS "Projekt",
  length(file.outlinks) AS "Code-Blocks"
FROM "01-Sessions"
WHERE file.outlinks
SORT length(file.outlinks) DESC
```

### Älteste unvollständige Sessions

```dataview
TABLE
  title AS "Titel",
  status AS "Status",
  created AS "Erstellt",
  date(today) - created AS "Tage alt"
FROM "01-Sessions"
WHERE status != "completed"
SORT created ASC
LIMIT 10
```

---

## Nutzungshinweise

1. **Dataview Plugin erforderlich**: Diese Queries benötigen das [Dataview Plugin](https://github.com/blacksmithgu/obsidian-dataview) für Obsidian.

2. **Query ausführen**: Füge eine Query in eine Note ein und sie wird automatisch ausgeführt.

3. **Query anpassen**: Passe die Queries an deine Bedürfnisse an, z.B. durch Ändern von `LIMIT` oder Filter-Kriterien.

4. **Performance**: Bei großen Vaults können komplexe Queries langsam sein. Verwende `LIMIT` um die Performance zu verbessern.

5. **JavaScript Queries**: DataviewJS Queries bieten mehr Flexibilität, erfordern aber JavaScript-Kenntnisse.

---

*Generiert vom OpenClaw-Obsidian Sync Script*
