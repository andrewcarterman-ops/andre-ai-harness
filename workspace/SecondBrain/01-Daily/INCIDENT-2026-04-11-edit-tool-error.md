---
date: 11-04-2026
time: 03:40
type: incident
severity: critical
status: active
tags: [incident, edit-tool, bug, live-error]
---

# INCIDENT: Edit-Tool Bug - Live-Fehler

## Zeitpunkt
**Datum:** 11-04-2026  
**Uhrzeit:** 03:28:10  
**Location:** OpenClaw Gateway Terminal

## Fehlermeldung
```
[tools] edit failed: Missing required parameters: 
  oldText (oldText or old_string), 
  newText (newText or new_string). 
  Supply correct parameters before retrying.
```

## Kontext
- Fehler trat während normaler Bearbeitung auf
- Vorherige Fehler:
  - 03:27:06: browser failed (Wikiwand unreachable)
  - 03:27:15: memory_get failed (path required)
- Dann: Edit-Tool Fehler

## Analyse
Der Bug, den wir in [[openclaw-edit-bug-analysis]] analysiert haben, ist **jetzt aktiv**.

**Problem:**
- System verlangt beide Parameter-Varianten gleichzeitig
- Weder `old_string` noch `oldText` werden akzeptiert
- Validation-Layer ist fehlerhaft

## Sofortmaßnahme (Angewendet)
**WORKAROUND:** Ab sofort `read` + `write` statt `edit` verwenden!

```powershell
# Statt:
edit file.txt old_string: "x" new_string: "y"

# Jetzt:
$content = Get-Content file.txt
$content = $content.Replace("x", "y")
Set-Content file.txt $content
```

## Status
- ✅ Workaround aktiv
- ⏳ Permanenter Fix pending (siehe Action Checklist P1-1)
- 📊 Überwachung: Alle Edit-Operationen werden geloggt

## Verwandte Dokumente
- [[openclaw-edit-bug-analysis|Root-Cause Analysis]]
- [[openclaw-action-checklist|Action Checklist P1-1]]
- [[edit-tool-workaround|Edit-Tool Workaround]]

---
**Letzte Aktualisierung:** 11-04-2026 03:40