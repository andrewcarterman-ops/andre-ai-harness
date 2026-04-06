# Session Store

**Status:** Phase 3 — Aktiv  
**Format:** JSON  
**Location:** `memory/sessions/`

---

## Zweck

Der Session Store speichert vollständige Session-Informationen über Zeit.
Ergänzt das Memory-System (Tagesnotizen) mit strukturierten Session-Daten.

---

## Struktur

```
memory/sessions/
├── README.md                          # Diese Datei
├── SESSION-{YYYYMMDD}-{HHMMSS}-{NNN}.json  # Einzelne Sessions
└── archive/                           # Archivierte Sessions (optional)
    └── SESSION-*.json
```

---

## Session-ID Format

```
SESSION-YYYYMMDD-HHMMSS-NNN

Beispiel: SESSION-20260325-224500-001
          │       │       │      │
          │       │       │      └── Sequenznummer (001-999)
          │       │       └───────── Zeit (HHMMSS)
          │       └───────────────── Datum (YYYYMMDD)
          └───────────────────────── Prefix
```

---

## Session Lifecycle

### 1. Session Start (via Hook: session:start)

```json
{
  "session_id": "SESSION-20260325-224500-001",
  "agent_id": "andrew-main",
  "start_time": "2026-03-25T22:45:00+01:00",
  "status": "active",
  "channel": "terminal",
  "context": {
    "registry_version": "1.1",
    "loaded_skills": ["secure-api-client", "self-improving-andrew"],
    "plan_in_progress": null
  }
}
```

### 2. Session Update (während der Session)

```json
{
  "status": "active",
  "messages_exchanged": 15,
  "plans_executed": ["plan-phase3-prep-001"],
  "files_modified": [
    "registry/hooks.yaml",
    "memory/sessions/SESSION-..."
  ],
  "skills_used": ["secure-api-client"]
}
```

### 3. Session End (via Hook: session:end)

```json
{
  "status": "completed",
  "end_time": "2026-03-25T23:15:00+01:00",
  "duration_seconds": 1800,
  "summary": "Phase 3 Session Store implementiert",
  "outcome": "success"
}
```

---

## Integration mit Hooks

### session:start
- Erzeugt neue Session-Datei
- Schreibt Initial-Metadaten
- Setzt Status auf "active"

### session:end
- Aktualisiert Session-Datei
- Setzt end_time
- Berechnet duration
- Setzt Status auf "completed" oder "cancelled"

### review:post_execution
- Kann Session-Referenz zu Reviews hinzufügen
- Speichert Review-Ergebnisse in Session

---

## Zugriff

### Lesen einer Session
```python
# Via File-Read
session = read("memory/sessions/SESSION-20260325-224500-001.json")
```

### Liste aller Sessions
```bash
# Sortiert nach Zeit (neueste zuerst)
ls -lt memory/sessions/SESSION-*.json
```

### Aktive Session finden
```bash
# Suche nach Status: active
grep -l '"status": "active"' memory/sessions/SESSION-*.json
```

---

## Rotation & Archivierung

### Automatisch (empfohlen ab 100 Sessions)
- Sessions älter als 30 Tage → `archive/`
- Sessions älter als 365 Tage → Löschung (oder externes Backup)

### Manuell
```bash
# Archivierung
mv memory/sessions/SESSION-202603*.json memory/sessions/archive/
```

---

## Zusammenhang mit anderen Systemen

| System | Zusammenhang |
|--------|--------------|
| Memory (Tagesnotizen) | Tageszusammenfassung verweist auf Sessions |
| Hook-Engine | Triggert Session-Start/End |
| Planner | Plans können Session-IDs referenzieren |
| Reviewer | Reviews können Sessions analysieren |
| Projekt-Registry | Sessions können Projekt-Zugehörigkeit haben |

---

## Beispiel: Session mit Projekt-Zuordnung

```json
{
  "session_id": "SESSION-20260325-224500-001",
  "project_id": "proj-modular-agent",
  "agent_id": "andrew-main",
  "start_time": "2026-03-25T22:45:00+01:00",
  "end_time": "2026-03-25T23:15:00+01:00",
  "status": "completed",
  "duration_seconds": 1800,
  "context": {
    "project_phase": "3",
    "registry_version": "1.1"
  }
}
```

---

*Dokumentation erstellt: 2026-03-25*  
*Autor: Andrew*  
*Phase: 3*
