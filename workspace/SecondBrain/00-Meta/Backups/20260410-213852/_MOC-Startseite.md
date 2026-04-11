---
date: 10-04-2026
type: moc
category: navigation
tags: [moc, dashboard, startseite, navigation]
---

# Second Brain - Startseite

> **Master Map of Content** - Dein zentrales Navigations-Dashboard

---

## Session-Statistiken

```dataviewjs
// Token-Statistiken aus Session-Logs
const sessions = dv.pages('"01-Daily"').where(p => p.session_id);
const totalTokens = sessions.values.reduce((acc, p) => acc + (p.tokens_used || 0), 0);
const totalSessions = sessions.length;
const avgTokens = totalSessions > 0 ? Math.round(totalTokens / totalSessions) : 0;

dv.table(
    ["Metrik", "Wert"],
    [
        ["Gesamt Sessions", totalSessions],
        ["Gesamt Tokens", totalTokens.toLocaleString()],
        ["Durchschnitt/Session", avgTokens.toLocaleString()],
        ["Aktive Projekte", dv.pages('"02-Projects"').where(p => p.status === "active").length],
        ["Offene TODOs", dv.pages().file.tasks.where(t => !t.completed && t.text.includes("#todo")).length]
    ]
);
```

---

## Uebersichten

| Bereich | Beschreibung | Link |
|---------|--------------|------|
| **Daily** | Tagesnotizen & Sessions | [[01-Daily/_MOC-Daily|Daily Uebersicht]] |
| **Projekte** | Aktive & abgeschlossene Projekte | [[02-Projects/_MOC-Projects|Projekt-Uebersicht]] |
| **Wissen** | How-To's, Konzepte, Referenzen | [[03-Knowledge/_MOC-Knowledge|Wissens-Uebersicht]] |
| **Entscheidungen** | Architektur-Entscheidungen (ADRs) | [[04-Decisions/|Entscheidungen]] |
| **Meine Faehigkeiten** | Was ich alles kann | [[00-Meta/Capabilities-Index|Meine Tools & Skills]] |
| **Inbox** | Quick-Capture | [[00-Meta/Inbox|Inbox]] |

---

## Aktive Projekte

```dataview
TABLE status, priority, completion as "%"
FROM "02-Projects"
WHERE status = "active"
SORT priority DESC, startDate DESC
```

---

## Letzte Sessions

```dataview
TABLE session_id, tokens_used, agent_mode
FROM "01-Daily"
WHERE session_id
SORT date DESC
LIMIT 10
```

---

## Offene TODOs

```dataview
TASK
FROM #todo
WHERE !completed
SORT priority DESC, dueDate ASC
LIMIT 15
```

---

## Wichtige Tags

### System-Tags
- `#decision` - Architekturentscheidungen
- `#todo` - Offene Aufgaben
- `#insight` - Erkenntnisse & Learnings
- `#session` - Session-Logs
- `#project` - Projekte
- `#how-to` - Anleitungen

### Themen-Tags
```dataview
TABLE length(rows) as "Anzahl"
FLATTEN file.tags as Tag
FROM ""
WHERE !contains(["#decision", "#todo", "#insight", "#session", "#project", "#how-to", "#moc", "#reference", "#knowledge", "#daily"], Tag)
GROUP BY Tag
WHERE length(rows) >= 2
SORT length(rows) DESC
LIMIT 15
```

---

## Letzte Entscheidungen

```dataview
TABLE decision_id, status, date
FROM "04-Decisions"
WHERE status = "accepted"
SORT date DESC
LIMIT 5
```

---

## Schnellzugriff: Meine Faehigkeiten

> **Neu:** Alle meine Skills, Tools und Commands auf einen Blick  
> -> [[00-Meta/Capabilities-Index|Hier klicken fuer die komplette Uebersicht]]

**Beliebt:**
- [[00-Meta/Capabilities-Index#Security Review|Security Review]] - Code auf Schwachstellen pruefen
- [[00-Meta/Capabilities-Index#Grill Me|Grill Me]] - Deinen Plan auf Schwaechen testen
- [[00-Meta/Capabilities-Index#Plan Feature|Plan Feature]] - Feature in Schritte zerlegen
- [[00-Meta/Capabilities-Index#TDD Loop|TDD Loop]] - Test-driven Development

---

## Externe Links

| Ressource | Link |
|-----------|------|
| **OpenClaw Docs** | `~/.openclaw/workspace/docs/` |
| **Skills Ordner** | `~/.openclaw/workspace/skills/` |
| **Memory (Sessions)** | `~/.openclaw/workspace/memory/` |
| **Outside Resources** | `~/Documents/Outside_resources/` |

---

## Sync-Status

- **Letzter Sync:** 10-04-2026
- **Vault-Version:** 2.1 (mit DataviewJS)
- **Struktur:** PARA + Second Brain Hybrid

---

*Powered by Obsidian + OpenClaw + ECC Framework*  
*Letzte Aktualisierung: 10-04-2026*