---
date: 2026-04-05
time: 18:12
session_id: obsidian-second-brain-implementation
agent: andrew-main
status: active
tags: [second-brain, setup, obsidian]
---

# Second Brain Dashboard

> PARA-basiertes Wissensmanagement für OpenClaw Sessions
> Letzte Aktualisierung: `=dateformat(date(today), "yyyy-MM-dd HH:mm")`

---

## 📊 Übersicht

| Metrik | Wert |
|--------|------|
| **Sessions** | `=length(filter(this.file.inlinks, (f) => contains(string(f), "01-Sessions")))` |
| **Aktive Projekte** | `=length(filter(this.file.inlinks, (f) => contains(string(f), "Projects") and !contains(string(f), "Archive")))` |
| **Entscheidungen** | `=length(filter(this.file.inlinks, (f) => contains(string(f), "Decisions")))` |
| **Code-Snippets** | `=length(filter(this.file.inlinks, (f) => contains(string(f), "CodeBlocks")))` |

---

## 🎯 Aktive Projekte

```dataview
TABLE progress as "Fortschritt", status as "Status", priority as "Priorität"
FROM "SecondBrain/02-Areas/Projects"
WHERE status = "Active"
SORT priority DESC, progress DESC
```

---

## 📝 Letzte Sessions

```dataview
TABLE date as "Datum", agent as "Agent", tags as "Tags"
FROM "SecondBrain/01-Sessions"
SORT date DESC
LIMIT 10
```

---

## ⚖️ Offene Entscheidungen

```dataview
TABLE status as "Status", priority as "Priorität", date as "Datum"
FROM "SecondBrain/02-Areas/Decisions"
WHERE status = "Proposed" OR status = "Under Review"
SORT priority DESC, date DESC
```

---

## 💻 Code-Snippets

```dataview
TABLE language as "Sprache", source as "Quelle", date as "Datum"
FROM "SecondBrain/03-Resources/CodeBlocks"
SORT date DESC
LIMIT 15
```

---

## 🔗 Schnellzugriff

### PARA-Struktur
- [[SecondBrain/02-Areas/Projects|📁 Projekte]]
- [[SecondBrain/02-Areas/Decisions|⚖️ Entscheidungen]]
- [[SecondBrain/03-Resources|📚 Ressourcen]]
- [[SecondBrain/04-Archive|🗄️ Archiv]]

### Tools
- [[SecondBrain/05-Templates/Session-Template|📝 Session Template]]
- [[SecondBrain/05-Templates/ADR-Template|⚖️ ADR Template]]
- [[SecondBrain/05-Templates/Project-Template|🎯 Project Template]]

---

## 📈 Aktivität (letzte 30 Tage)

```dataview
CALENDAR date
FROM "SecondBrain/01-Sessions"
WHERE date > date(today) - dur(30 days)
```

---

## 🔄 Sync-Status

- **Letzter Sync**: `=this.date` `=this.time`
- **Sync-Quelle**: `~/.openclaw/workspace/memory/`
- **Ziel**: `SecondBrain/01-Sessions/`

---

## Tags

#dashboard #second-brain #overview
