# Hook: Session Start (Phase 1 - Manual Execution)
# Hook-ID: session:start
# Priorität: 100
# Async: false
# Status: ✅ IMPLEMENTIERT (Manuelle Ausführung)
# Aktualisiert: 11-04-2026

## ⚠️ WICHTIG: Dieser Hook MUSS zu Beginn JEDER Session ausgeführt werden!

## Beschreibung
Dieser Hook wird vom Agenten **manuell** am Beginn einer Session ausgeführt.
Er initialisiert den Kontext, lädt System-Status und bereitet die Session vor.

## Checkliste für Agent (MUSST du abarbeiten!)

### Schritt 1: SYSTEM-STATUS laden (NEU - Seit 11-04-2026)
```
LESE: SecondBrain/00-Meta/SYSTEM-STATUS.md
→ Enthält: Cron-Jobs, aktive Projekte, System-Status
→ WICHTIG: Nie vergessen! Hier steht alles was du wissen musst!
```

### Schritt 2: Standard-Kontext laden
```
LESE: SOUL.md (Wer du bist)
LESE: USER.md (Wer Parzival ist)
LESE: MEMORY.md (Langzeitgedächtnis)
LESE: memory/YYYY-MM-DD.md (Heute + Gestern)
```

### Schritt 3: Registry prüfen
```
PRÜFE: registry/agents.yaml
PRÜFE: registry/skills.yaml
PRÜFE: registry/hooks.yaml
```

### Schritt 4: Aktive Systeme verifizieren
```
LISTE: cron list (Zeige alle Cron-Jobs)
PRÜFE: Aktive Projekte in SecondBrain/02-Projects/Active/
```

### Schritt 5: Session loggen
```
ERSTELLE: Eintrag in memory/sessions/{id}.yaml
SCHREIBE: Log in memory/hooks.log
```

## Aktive Cron-Jobs ( immer prüfen!)

| Job | Zeit | Status |
|-----|------|--------|
| Auto-Sync SecondBrain | Alle 8h | ✅ Muss bekannt sein |
| Daily Drift Detection | 08:00 täglich | ✅ Muss bekannt sein |

→ **WICHTIG:** Diese Jobs laufen automatisch! Du musst wissen, dass sie existieren!

## Kritische Informationen (Aus SYSTEM-STATUS.md)

### Was du immer wissen musst:
1. **Drift Detection** läuft täglich um 08:00
2. **SecondBrain Sync** läuft alle 8 Stunden
3. **Vault-Struktur** ist in `SecondBrain/00-Meta/Config/vault-manifest.yaml` definiert
4. **applyPatch-Fehler** werden noch beobachtet (03:27 Uhr)

### Was du nie vergessen darfst:
- Vor Löschen immer GO einholen
- Migrationen immer mit Dry-Run starten
- Qualität > Geschwindigkeit
- SYSTEM-STATUS.md bei jeder Session lesen!

## Fehlerbehandlung

| Fehler | Aktion |
|--------|--------|
| SYSTEM-STATUS.md fehlt | ❌ KRITISCH - Session nicht fortsetzen! |
| MEMORY.md fehlt | ⚠️ Warnung - Mit Vorsicht fortfahren |
| Cron-Job unerwartet | ⚠️ Prüfe `cron list` |

## Output nach erfolgreichem Hook

```
✅ SYSTEM-STATUS.md geladen
   → 2 Cron-Jobs aktiv
   → 4 Projekte aktiv
   → Drift Detection um 08:00

✅ SOUL.md geladen
✅ USER.md geladen
✅ MEMORY.md geladen
✅ Registry validiert
✅ Session geloggt

🚀 Session bereit!
```

## Version History
- v1.0: Initial
- v1.1: SYSTEM-STATUS.md hinzugefügt (11-04-2026)
- v1.2: Cron-Job Übersicht hinzugefügt (11-04-2026)

---
**ACHTUNG:** Dieser Hook muss MANUELL vom Agenten ausgeführt werden!
Der Agent MUSS SecondBrain/00-Meta/SYSTEM-STATUS.md lesen!
