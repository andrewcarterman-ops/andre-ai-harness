# Second Brain Dashboard

```dataview
TABLE WITHOUT ID
  link(file.name) as Session,
  dateformat(date, "yyyy-MM-dd") as Datum,
  tokens as Tokens,
  cost as Kosten,
  status as Status
FROM "second-brain/01-Sessions"
SORT date DESC
LIMIT 10
```

## 📊 Statistiken

### Gesamt
- **Sessions:** `=length(this.file.inlinks)`
- **Entscheidungen:** `=length(filter(file.inlinks, (f) => contains(f.path, "Decisions")))`
- **Projekte:** `=length(filter(file.inlinks, (f) => contains(f.path, "Projects")))`

### Token-Usage (letzte 30 Tage)
```dataview
TABLE sum(tokens) as "Gesamt Tokens"
FROM "second-brain/01-Sessions"
WHERE date >= date(today) - dur(30 days)
GROUP BY dateformat(date, "yyyy-MM") as Monat
```

## 🔴 Offene TODOs
```dataview
TASK
FROM "second-brain"
WHERE !completed
AND contains(text, "TODO")
SORT file.name ASC
```

## 🤔 Unentschiedene Entscheidungen
```dataview
TABLE status as Status, priority as Priorität
FROM "second-brain/02-Areas/Decisions"
WHERE status = "Proposed"
SORT priority ASC
```

## 📈 Projekt-Fortschritt
```dataview
TABLE progress as Fortschritt, status as Status
FROM "second-brain/02-Areas/Projects"
SORT file.name ASC
```

## 🔗 Schnellzugriff
- [[MOC-Framework|Framework Übersicht]]
- [[01-Sessions/|Alle Sessions]]
- [[02-Areas/Decisions/|Entscheidungen]]
- [[02-Areas/Projects/|Projekte]]
- [[03-Resources/|Ressourcen]]

## 📝 Letzte Änderungen
```dataview
LIST
FROM "second-brain"
SORT file.mtime DESC
LIMIT 5
```
