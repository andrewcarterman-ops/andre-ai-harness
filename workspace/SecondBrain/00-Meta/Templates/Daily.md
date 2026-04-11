---
date: {{date:DD-MM-YYYY}}
type: daily
session_id: "{{date:YYYYMMDD}}{{time:HHmm}}00"
tokens_used: 
agent_mode: main
projects: []
tags: [daily, journal, session]
---

# {{date:DD-MM-YYYY}} - Daily Note

## Session-Metadaten

| Feld | Wert |
|------|------|
| **Session ID** | `{{date:YYYYMMDD}}{{time:HHmm}}00` |
| **Tokens Used** | (wird automatisch erfasst) |
| **Agent Mode** | main |
| **Projects** | (verknuepfte Projekte) |

## Zusammenfassung
<!-- 3 Saetze: Was war der Fokus? Was wurde erreicht? Was ist offen? -->

## Notizen / Gedanken
-

## Entscheidungen
-

## Offene TODOs
```dataview
TASK
FROM #todo
WHERE !completed
AND file.path = this.file.path
SORT priority DESC
```

## Verknuepfte Projekte
<!-- Format: [[02-Projects/Active/projektname|Projektname]] -->

## Links / Verwandtes
- [[_MOC-Daily|Daily MOC]]
- [[_MOC-Startseite|Startseite]]

## Erstellt
{{date:DD-MM-YYYY HH:mm}}

---

## Retrospktive (am Ende der Session ausfuellen)

### Was lief gut?
-

### Was war schwierig?
-

### Was nehmen wir mit?
-

### Tokens (manuell oder via Script)
- Input: 
- Output: 
- Gesamt: 
