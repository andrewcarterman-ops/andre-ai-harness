# applyPatch Fehleranalyse - TODO

**Datum:** 11-04-2026  
**Status:** Offen - Weiter Beobachtung nötig  
**Priorität:** Mittel

---

## Problem

Seit der Vault-Migration (09-10.04.2026) treten im OpenClaw TUI Log wiederkehrende Tool-Fehler auf:

```
03:27:06 [tools] browser failed:
03:27:15 [tools] memory_get failed: path required
03:28:10 [tools] edit failed: Missing required parameters: oldText (oldText or old_string)
```

---

## Zeitliches Muster

- **Erstes Auftreten:** 11.04.2026 um 03:27-03:28 Uhr
- **Häufigkeit:** Unbekannt (möglicherweise alle 8 Stunden)
- **Korrelation:** Zeitgleich mit Cron-Job "Auto-Sync SecondBrain alle 8h"
  - Cron läuft um: 03:22, 11:22, 19:22 Uhr
  - Fehler um: 03:27 Uhr (5 Min. nach Cron-Start)

---

## Analyse-Ergebnisse

### 1. Nicht von Agent direkt verursacht
- Keine aktiven Subagents zur Zeit der Fehler
- Keine automatischen Hooks (nur manuelle Ausführung)
- Meine Tool-Aufrufe sind korrekt parametrisiert

### 2. applyPatch Konfiguration verdächtig

**Aktuelle Config:**
```json
"applyPatch": {
  "enabled": true,
  "allowModels": [
    "openai/*",
    "openai-codex/*",
    "gpt-*",
    "claude-code/*"
  ]
}
```

**Problem:**
- `applyPatch` ist aktiviert
- Aber **Kimi ist NICHT in allowModels**
- Wenn OpenClaw intern versucht, Patches anzuwenden, könnte das Fehler verursachen

### 3. Mögliche Ursachen

1. **Cron-Job triggert internen Prozess**
   - Der 8h Sync könnte etwas im Gateway auslösen
   - Vielleicht versucht OpenClaw automatisch zu "patchen"?

2. **applyPatch versucht trotzdem zu laufen**
   - Obwohl Kimi nicht erlaubt ist, könnte der Code versuchen, aufzurufen
   - Führt zu fehlenden Parametern (`path`, `oldText`)

3. **Bug in OpenClaw 2026.3.13**
   - Interne Fehler beim Cron-Event-Handling

---

## TODOs / Nächste Schritte

### Sofort
- [ ] **Beobachten:** Prüfen ob Fehler beim nächsten Cron-Lauf (11:22 Uhr) wieder kommen
- [ ] **Log-Kontext:** TUI Log VOR den Fehlern anschauen (was triggert es?)

### Bei Reproduktion
- [ ] **applyPatch deaktivieren testen:**
  ```json
  "applyPatch": { "enabled": false }
  ```
- [ ] **Cron-Job deaktivieren testen:**
  ```bash
  openclaw cron disable 6f87a771-32f2-42ab-ad8e-fdac9991438f
  ```

### Langfristig
- [ ] Bug Report an OpenClaw erstellen, falls systematisch reproduzierbar
- [ ] Entscheiden: `applyPatch` dauerhaft deaktivieren oder Kimi zu allowModels hinzufügen

---

## Workaround (falls nötig)

Wenn die Fehler stören oder zu Problemen führen:

1. **applyPatch deaktivieren** (empfohlen, da wir es nicht nutzen)
2. **Oder:** Kimi zu allowModels hinzufügen:
   ```json
   "allowModels": [
     "openai/*",
     "openai-codex/*",
     "gpt-*",
     "claude-code/*",
     "kimi-coding/*"
   ]
   ```

---

## Verwandte Dateien

- `registry/hooks.yaml` - Keine automatischen Hooks
- `registry/skills.yaml` - Keine Skills mit automatischem edit
- Cron-Job: `6f87a771-32f2-42ab-ad8e-fdac9991438f`

---

*Dokumentation erstellt: 11-04-2026*  
*Nächste Prüfung: Nach nächstem Cron-Lauf (11:22 Uhr)*
