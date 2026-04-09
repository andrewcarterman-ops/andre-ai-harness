---
tags:
  - index
  - moc
  - startseite
---

# ECC Second Brain 🧠

> **Master Map of Content** - Dein zentrales Navigations-Dashboard

---

## Quick Links

| Bereich | Beschreibung | Link |
|---------|--------------|------|
| **Inbox** | Neue Inputs & Quick Capture | [[00-Inbox/README\|Inbox]] |
| **Projekte** | Aktive ECC-Projekte | [[01-Projects/README\|Projekte]] |
| **Bereiche** | Langfristige Verantwortung | [[02-Areas/README\|Bereiche]] |
| **Ressourcen** | Wiederverwendbares Wissen | [[03-Resources/README\|Ressourcen]] |
| **Archiv** | Abgeschlossene Sessions | [[04-Archive/README\|Archiv]] |
| **Daily** | Tägliche Session-Logs | [[05-Daily/README\|Daily]] |

---

## Aktive Projekte

```dataview
TABLE status, startDate, dueDate, completion
FROM "01-Projects"
WHERE status = "active"
SORT priority DESC, startDate DESC
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

## Letzte Entscheidungen

```dataview
TABLE decision_id, status, date
FROM #decision
WHERE status = "accepted"
SORT date DESC
LIMIT 5
```

---

## Session-Statistiken

```dataview
TABLE date, tokens_used, agent_mode
FROM "05-Daily"
SORT date DESC
LIMIT 7
```

---

## Tags

### System-Tags
- `#decision` - Architekturentscheidungen
- `#todo` - Offene Aufgaben
- `#insight` - Erkenntnisse
- `#session` - Session-Logs
- `#context` - Kontext-Informationen
- `#project` - Projekte
- `#area` - Bereiche

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

## Wöchentliche Übersicht

| Tag | Sessions | Tokens | Entscheidungen |
|-----|----------|--------|----------------|
| Montag | | | |
| Dienstag | | | |
| Mittwoch | | | |
| Donnerstag | | | |
| Freitag | | | |

---

## Sync-Status

- **Letzter Sync**: 
- **Sync-Quelle**: OpenClaw
- **Vault-Version**: 1.0.0

---

*ECC Second Brain Framework v1.0.0*
*Powered by Obsidian + OpenClaw*
