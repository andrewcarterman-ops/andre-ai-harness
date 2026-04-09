# Projekt-Übersicht

Alle Projekte im Framework.

## Aktive Projekte

```dataview
TABLE 
  progress as Fortschritt,
  status as Status,
  priority as Priorität
FROM "second-brain/02-Areas/Projects"
WHERE status = "Active"
SORT priority ASC, progress DESC
```

## Abgeschlossene Projekte

```dataview
TABLE 
  completed_date as "Abgeschlossen",
  summary as Zusammenfassung
FROM "second-brain/02-Areas/Projects"
WHERE status = "Completed"
SORT completed_date DESC
```

## Neues Projekt erstellen

1. Template kopieren: [[05-Templates/Project-Template|Project Template]]
2. In `02-Areas/Projects/` speichern
3. Mit Sessions verknüpfen
