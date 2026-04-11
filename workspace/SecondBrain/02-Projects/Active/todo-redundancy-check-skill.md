---
date: 11-04-2026
time: 03:49
type: todo
status: todo
priority: high
tags: [todo, skill, planning, redundancy-check, enhancement]
---

# TODO: Redundanz-Check Skill erstellen

## Problem
Heute (11-04-2026 03:40) habe ich redundant gearbeitet:
- Es gab bereits `edit-tool-workaround.md` (einfacher Workaround)
- Ich habe zusätzlich `SafeEdit.psm1` erstellt (komplexeres Modul)
- Gleiches Problem, zwei Lösungen = Verschwendung

## Lösung: Neuer Skill "redundancy-check"

### Zweck
Vor jeder Erstellung prüfen, ob es bereits gibt:
- Workarounds in How-To/
- Skills in skills/ + registry/
- Scripts in 00-Meta/Scripts/
- Dokumentation in MEMORY.md + MOCs
- Projekte in 02-Projects/
- Tools in TOOLS.md

### Checkliste (Vor jeder Erstellung)
- [ ] `memory_search` nach Keywords
- [ ] `How-To/` Ordner durchsuchen
- [ ] `skills/` + `registry/skills.yaml` prüfen
- [ ] `00-Meta/Scripts/` prüfen
- [ ] `_MOC-Knowledge.md` prüfen
- [ ] MEMORY.md prüfen
- [ ] Bei Unsicherheit: User fragen!

### Integration
Dieser Check sollte Teil des **plan-feature Skills** sein:
- Phase 0: "Existenz-Check" (neu)
- Vor jeder Implementierung: "Haben wir das schon?"

## Verwandte Dokumente
- [[vault-migration-redundancy-process|Vault Migration Redundancy Process]]
- [[plan-feature|Plan Feature Skill]] (soll erweitert werden)

## Status
- [ ] Skill-Konzept erstellen
- [ ] In plan-feature Skill integrieren
- [ ] Testen mit nächstem Feature

---
**Erstellt:** 11-04-2026 (Nach Redundanz-Vorfall)