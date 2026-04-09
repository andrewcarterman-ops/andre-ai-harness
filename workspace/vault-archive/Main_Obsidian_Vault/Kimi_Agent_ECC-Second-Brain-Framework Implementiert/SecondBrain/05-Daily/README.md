---
tags:
  - daily
  - sessions
  - index
---

# 05 - Daily 📅

> **Daily Session Logs** - Tägliche Session-Logs mit YAML-Frontmatter

---

## Übersicht

Dieser Ordner enthält alle täglichen Session-Logs, die automatisch aus OpenClaw synchronisiert werden.

---

## Aktuelle Sessions

```dataview
TABLE session_id, date, tokens_used, agent_mode, key_decisions
FROM "05-Daily"
WHERE file.name != "README"
SORT date DESC
LIMIT 10
```

---

## Token Usage

```dataview
TABLE sum(tokens_used) as "Total Tokens"
FROM "05-Daily"
GROUP BY dateformat(date, "yyyy-MM") as Month
SORT Month DESC
```

---

## Agent Mode Distribution

```dataview
TABLE length(rows) as Sessions
FROM "05-Daily"
WHERE agent_mode
GROUP BY agent_mode
SORT length(rows) DESC
```

---

## Key Decisions

```dataview
TABLE date, key_decisions
FROM "05-Daily"
WHERE key_decisions
FLATTEN key_decisions
SORT date DESC
LIMIT 20
```

---

## Templates

- [[../.obsidian/templates/daily-note-template|Daily Note Template]]

---

*ECC Second Brain Framework*
