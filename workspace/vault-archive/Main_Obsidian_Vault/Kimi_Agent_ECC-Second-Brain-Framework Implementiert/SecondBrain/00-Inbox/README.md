---
tags:
  - inbox
  - quick-capture
  - index
---

# 00 - Inbox 📥

> **Quick Capture Zone** - Schnelle Erfassung ohne Organisation

---

## Zweck

Die Inbox ist dein **Entry Point** für alle neuen Informationen:
- Ideen
- Notizen
- Links
- Aufgaben
- Gedanken

---

## Workflow

1. **Capture** - Alles kommt zuerst hier rein
2. **Process** - Regelmäßig durchgehen (täglich/wöchentlich)
3. **Organize** - In die richtigen Ordner verschieben
4. **Archive** - Abgeschlossenes archivieren

---

## Neue Input-Vorlage

Verwende [[template-new-input]] für neue Inputs.

---

## Aktuelle Inbox

```dataview
TABLE file.ctime as "Created", file.size as "Size"
FROM "00-Inbox"
WHERE file.name != "README"
SORT file.ctime DESC
```

---

## Processing Checklist

- [ ] Inbox durchgehen
- [ ] Items kategorisieren
- [ ] In Projekte/Areas verschieben
- [ ] TODOs extrahieren
- [ ] Archivieren was fertig ist

---

*ECC Second Brain Framework*
