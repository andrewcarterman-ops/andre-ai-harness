# TODO: applyPatch Fehler beheben

**Projekt-Typ:** System-Debug / OpenClaw Konfiguration  
**Status:** Offen - Beobachtungsphase  
**Priorität:** Mittel  
**Erstellt:** 11-04-2026

---

## Ziel
Die wiederkehrenden Tool-Fehler (`edit`, `memory_get`, `browser`) im OpenClaw Gateway identifizieren und beheben.

## Beschreibung
Seit der Vault-Migration treten um 03:27 Uhr (nach dem 8h-Cron) Fehler auf:
- `edit failed: Missing required parameters: oldText`
- `memory_get failed: path required`
- `browser failed`

## Verdacht
Die `applyPatch` Konfiguration ist aktiviert, aber Kimi ist nicht in `allowModels`. Dies könnte interne Fehler verursachen.

## Nächste Schritte

### Phase 1: Beobachtung (AKTUELL)
- [ ] Warten auf nächsten Cron-Lauf (11:22 Uhr)
- [ ] Prüfen ob Fehler reproduzierbar auftreten
- [ ] TUI-Log vor den Fehlern analysieren

### Phase 2: Test (falls reproduzierbar)
- [ ] `applyPatch` temporär deaktivieren
- [ ] Beobachten ob Fehler verschwinden
- [ ] Ggf. Cron-Job isoliert testen

### Phase 3: Fix
- [ ] Entscheidung: Dauerhafte Deaktivierung vs. Kimi zu allowModels hinzufügen
- [ ] Konfiguration anpassen
- [ ] Dokumentation updaten

## Dokumentation
- **Details:** `03-Knowledge/How-To/applypatch-error-analysis.md`
- **Daily:** `01-Daily/11-04-2026.md`

## Notizen
- Keine aktiven Subagents zur Fehlerzeit
- Keine automatischen Hooks
- Cron-Job: Auto-Sync SecondBrain alle 8h

## ERKENNTNIS (11-04-2026 05:46)

**Beobachtete Tool-Fehler während der Arbeit:**

```
05:39:48 [tools] read failed: Offset 335 is beyond end of file (1 lines total)
05:40:39 [tools] edit failed: Missing required parameter: newText
05:40:46 [tools] edit failed: Missing required parameters: oldText and newText
```

**Analyse:**
- Diese Fehler treten auf, wenn `read` mit falschem Offset oder `edit` ohne Parameter aufgerufen wird
- Es sind **KEINE** systematischen Gateway-Fehler, sondern Bedienfehler bei der Tool-Nutzung
- Die Fehler haben **NICHTS** mit dem ursprünglichen applyPatch-Problem zu tun
- Sie entstehen durch inkorrekte Tool-Aufrufe während der Skript-Entwicklung

**Unterschied zum applyPatch-Problem:**
| applyPatch-Fehler | Tool-Bedienfehler |
|-------------------|-------------------|
| Treten automatisch um 03:27 auf | Treten nur bei falschen Aufrufen auf |
| Systematisch (Cron-Job) | Zufällig (Entwicklung) |
| Betreffen Gateway-Interna | Betreffen Tool-Parameter |

**Fazit:** Die beobachteten Fehler sind keine neuen Erkenntnisse für das applyPatch-Problem. Sie sind normale Tool-Fehler bei der Entwicklung.

---
*Projekt erstellt: 11-04-2026*  
*Letzte Aktualisierung: 11-04-2026 05:46*
