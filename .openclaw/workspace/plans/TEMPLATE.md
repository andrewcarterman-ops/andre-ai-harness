---
# Plan Metadaten (YAML-Frontmatter)
plan_id: "{{auto-generated-uuid}}"
title: "{{kurzer beschreibender Titel}}"
created_at: "{{ISO8601-timestamp}}"
created_by: "andrew-main"
status: "draft"  # draft | active | completed | cancelled
priority: "normal"  # low | normal | high | critical
version: "1.0"

# Context
tags:
  - "{{tag1}}"
  - "{{tag2}}"

# Verknüpfungen
related_plans: []
  # - "plans/previous-plan.md"
  # - "plans/follow-up-plan.md"

# Agent-Zuordnung
assigned_agent: "andrew-main"
  # Für später: Multi-Agent-Plans
  # agents:
  #   - id: "andrew-main"
  #     role: "executor"
  #   - id: "andrew-reviewer"
  #     role: "reviewer"

# Search-Integration (auto-populated)
required_capabilities:
  - "{{capability1}}"
  - "{{capability2}}"

suggested_skills:
  - "{{skill-id-1}}"
  - "{{skill-id-2}}"
  # Wird aus search-index.json abgeleitet

# Status-Tracking
steps_total: 0
steps_completed: 0
steps_failed: 0
progress_percent: 0

# Zeittracking
estimated_duration: "{{z.B. '30m', '2h', '1d'}}"
started_at: null
completed_at: null
actual_duration: null

# Review-Config
review_required: true
review_trigger: "on_error"  # always | on_error | manual
reviewed_by: null
reviewed_at: null
review_status: null  # pending | passed | failed
---

# Plan: {{Titel}}

## 🎯 Ziel

**Primäres Ziel:**
{{Eindeutige, messbare Zielbeschreibung}}

**Erfolgskriterien:**
- [ ] {{Kriterium 1}}
- [ ] {{Kriterium 2}}
- [ ] {{Kriterium 3}}

**Nicht im Scope:**
- {{Was explizit nicht gemacht wird}}

---

## 🧠 Kontext

### Ausgangslage
{{Was ist der aktuelle Stand? Was wurde bereits getan?}}

### Einschränkungen
{{Zeit, Ressourcen, technische Limits}}

### Relevante Dateien/Resourcen
- `{{pfad/zu/datei1}}`
- `{{pfad/zu/datei2}}`
- {{URLs, externe Referenzen}}

### Gefundene Skills (via Search-Index)
```yaml
# Suche nach: "{{keywords}}"
# Ergebnisse aus registry/search-index.json:
relevant_skills:
  - id: "{{skill-id}}"
    relevance_score: 95
    why_relevant: "{{Begründung}}"
```

---

## 📋 Schritte

### Schritt 1: {{Titel}}
**Status:** ⬜ pending <!-- ⬜ pending | 🟡 active | ✅ completed | ❌ failed -->

**Ziel:**
{{Was wird in diesem Schritt erreicht?}}

**Aktionen:**
1. {{Konkrete Aktion}}
2. {{Konkrete Aktion}}
3. {{Konkrete Aktion}}

**Verwendete Skills:**
- `{{skill-id}}` — {{Wofür?}}

**Erwartetes Ergebnis:**
{{Was sollte nach diesem Schritt vorliegen?}}

**Validierung:**
- [ ] {{Prüfpunkt 1}}
- [ ] {{Prüfpunkt 2}}

**Betroffene Dateien:**
- `{{datei1}}` (neu/änderung/löschung)
- `{{datei2}}` (neu/änderung/löschung)

**Rollback:**
{{Falls dieser Schritt fehlschlägt: Wie machen wir es rückgängig?}}

---

### Schritt 2: {{Titel}}
**Status:** ⬜ pending

**Ziel:**
{{...}}

**Aktionen:**
1. {{...}}

**Verwendete Skills:**
- `{{skill-id}}`

**Erwartetes Ergebnis:**
{{...}}

**Validierung:**
- [ ] {{...}}

**Betroffene Dateien:**
- `{{...}}`

**Rollback:**
{{...}}

---

### Schritt 3: {{Titel}}
**Status:** ⬜ pending

{{...}}

---

## 🔍 Review

### Automatisches Review (durchgeführt bei Plan-Abschluss oder Fehler)

**Review-Checkliste:**
- [ ] Alle Schritte ausgeführt?
- [ ] Erfolgskriterien erfüllt?
- [ ] Keine unbeabsichtigten Seiteneffekte?
- [ ] Dokumentation aktualisiert?
- [ ] Rollback-Info notiert?

**Gefundene Probleme:**
| Problem | Schwere | Lösung | Status |
|---------|---------|--------|--------|
| {{Beschreibung}} | low/medium/high | {{Fix}} | ⬜ open/✅ resolved |

**Gelernte Erkenntnisse:**
- {{Was können wir beim nächsten Mal besser machen?}}

**Feedback für self-improving-andrew:**
```
{{Korrekturen oder Präferenzen, die gespeichert werden sollten}}
```

---

### Manuelles Review (falls review_trigger = "manual")

**Reviewer:** {{Name oder andrew-main}}

**Review-Notizen:**
{{Freitext für menschliches Feedback}}

**Genehmigung:**
- [ ] Plan genehmigt für Ausführung
- [ ] Plan abgeschlossen bestätigt

**Unterschrift (Reviewed-By):**
`{{Name}}` am `{{Datum}}`

---

## 📝 Notizen & Log

### 2026-03-25 22:37 — Plan erstellt
{{Initiale Erstellung des Plans}}

### {{Timestamp}} — Schritt 1 begonnen
{{...}}

### {{Timestamp}} — Problem aufgetreten
{{...}}

### {{Timestamp}} — Plan abgeschlossen
{{...}}

---

## 🏁 Abschluss

**Zusammenfassung:**
{{Was wurde erreicht?}}

**Metriken:**
- Geplante Schritte: {{N}}
- Tatsächliche Schritte: {{N}}
- Erfolgreich: {{N}}
- Fehlgeschlagen: {{N}}
- Dauer: {{Zeit}}

**Nächste Schritte:**
- {{Follow-up Plan oder Aktionen}}

**Archivierung:**
- [ ] Plan verschoben nach `plans/archive/{{plan_id}}.md`
- [ ] Lessons learned in MEMORY.md übernommen

---

## 📚 Anhänge

### Nutzungsbeispiel

```markdown
---
plan_id: "plan-001"
title: "Implementiere neue Skill Registry"
status: "draft"
priority: "high"
estimated_duration: "2h"
required_capabilities:
  - "file_operations"
  - "yaml_parsing"
suggested_skills:
  - "secure-api-client"
---

# Plan: Implementiere neue Skill Registry

## 🎯 Ziel
Erstelle eine YAML-basierte Skill Registry für das modulare Agentensystem.

## 📋 Schritte

### Schritt 1: Analyse bestehender Skills
**Status:** ⬜ pending
**Ziel:** Alle Skills im skills/ Ordner identifizieren
**Aktionen:**
1. Liste alle skills/*/SKILL.md Dateien
2. Extrahiere Metadaten (Name, Description, Category)
3. Erstelle temporäre Übersicht
**Validierung:**
- [ ] Mindestens 5 Skills gefunden
- [ ] Keine duplicate IDs
```

---

*Template-Version: 1.0*  
*Zuletzt aktualisiert: 2026-03-25*
