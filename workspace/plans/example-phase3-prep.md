---
plan_id: "plan-phase3-prep-001"
title: "Vorbereitung Phase 3: Session Store, projektbezogenes Lernen, Tool-/MCP-Registry"
created_at: "2026-03-25T22:38:00+01:00"
created_by: "andrew-main"
status: "draft"
priority: "high"
version: "1.0"

tags:
  - "phase-transition"
  - "architecture"
  - "session-management"
  - "learning"

related_plans: []

assigned_agent: "andrew-main"

required_capabilities:
  - "file_operations"
  - "yaml_editing"
  - "json_editing"
  - "directory_management"

suggested_skills:
  - "secure-api-client"
  - "mission-control"

steps_total: 5
steps_completed: 0
steps_failed: 0
progress_percent: 0

estimated_duration: "3h"
started_at: null
completed_at: null
actual_duration: null

review_required: true
review_trigger: "on_error"
reviewed_by: null
reviewed_at: null
review_status: null
---

# Plan: Vorbereitung Phase 3

## 🎯 Ziel

**Primäres Ziel:**
Erstelle die Infrastruktur für Phase 3 (Session Store, projektbezogenes Lernen, Tool-/MCP-Registry) basierend auf den Phase 1 & 2 Fundamenten.

**Erfolgskriterien:**
- [ ] Session Store Konzept definiert und dokumentiert
- [ ] Projektbezogenes Lernen-Mechanik spezifiziert
- [ ] Tool-/MCP-Registry Struktur entworfen
- [ ] Integration mit Phase 1 & 2 validiert
- [ ] Keine Breaking Changes zu bestehendem System

**Nicht im Scope:**
- Vollständige Implementierung (nur Vorbereitung/Design)
- Datenmigration aus bestehenden Systemen
- Produktivsetzung

---

## 🧠 Kontext

### Ausgangslage
Phase 1 (Registry) und Phase 2 (Search, Plan, Review) sind abgeschlossen. Das System hat:
- Agent Registry (agents.yaml)
- Skill Registry (skills.yaml)
- Hook-Engine (hooks.yaml)
- Search-Index (search-index.json)
- Plan-Template (plans/TEMPLATE.md)

### Einschränkungen
- Keine externen Datenbanken (File-basiert bleibt Prinzip)
- Keine Breaking Changes zu Phase 1/2
- Minimalprinzip beachten

### Relevante Dateien/Resourcen
- `registry/agents.yaml`
- `registry/skills.yaml`
- `registry/hooks.yaml`
- `registry/search-index.json`
- `plans/TEMPLATE.md`
- `skills/self-improving-andrew/SKILL.md` (für Lern-Mechanik)

### Gefundene Skills (via Search-Index)
```yaml
relevant_skills:
  - id: "self-improving-andrew"
    relevance_score: 95
    why_relevant: "Liefert Pattern für projektbezogenes Lernen"
  - id: "secure-api-client"
    relevance_score: 70
    why_relevant: "Für MCP-Registry API-Patterns relevant"
  - id: "mission-control"
    relevance_score: 60
    why_relevant: "Tool-Erstellung ähnlich zu MCP-Tools"
```

---

## 📋 Schritte

### Schritt 1: Session Store Analyse & Design
**Status:** ⬜ pending

**Ziel:**
Konzept für Session Store erstellen (Speicherung von Sessions über Zeit).

**Aktionen:**
1. Analysiere bestehendes Memory-System (memory/YYYY-MM-DD.md)
2. Identifiziere Lücken: Was fehlt für vollständige Session-Speicherung?
3. Design Session-Datenstruktur (Session-ID, Zeit, Agent, Kontext, Ergebnisse)
4. Erstelle Beispiel-Session-Eintrag
5. Dokumentiere Integration mit Hook-Engine (session:start/end)

**Verwendete Skills:**
- Kein Skill nötig (Analyse/Dokumentation)

**Erwartetes Ergebnis:**
- `docs/session-store-design.md` mit Konzept
- Beispieldatenstruktur in `registry/examples/session-example.yaml`

**Validierung:**
- [ ] Design dokumentiert
- [ ] Beispielstruktur valide YAML
- [ ] Integration mit bestehenden Hooks beschrieben

**Betroffene Dateien:**
- `docs/session-store-design.md` (neu)
- `registry/examples/session-example.yaml` (neu)

**Rollback:**
Einfaches Löschen der neuen Dateien.

---

### Schritt 2: Projektbezogenes Lernen Spezifikation
**Status:** ⬜ pending

**Ziel:**
Mechanik für lernen auf Projektebene (nicht nur global wie self-improving-andrew).

**Aktionen:**
1. Studiere `skills/self-improving-andrew/SKILL.md`
2. Extrahiere wiederverwendbare Patterns
3. Design projektspezifische Lern-Struktur
4. Definiere: Was ist ein "Projekt" im OpenClaw-Kontext?
5. Erstelle Projekt-Lern-Template

**Verwendete Skills:**
- `self-improving-andrew` — Pattern-Analyse

**Erwartetes Ergebnis:**
- `docs/project-learning-design.md`
- `registry/templates/project-learning-template.yaml`

**Validierung:**
- [ ] Unterscheidung Global vs Projekt-Lernen klar
- [ ] Template nutzbar
- [ ] Integration mit Phase 1/2 beschrieben

**Betroffene Dateien:**
- `docs/project-learning-design.md` (neu)
- `registry/templates/project-learning-template.yaml` (neu)

**Rollback:**
Löschen der neuen Dateien.

---

### Schritt 3: Tool-/MCP-Registry Entwurf
**Status:** ⬜ pending

**Ziel:**
Konzept für Tool- und MCP-Server Registry erstellen.

**Aktionen:**
1. Recherchiere MCP (Model Context Protocol) Basics
2. Analysiere bestehende Tool-Nutzung in OpenClaw
3. Design Registry-Struktur für externe Tools/MCPs
4. Definiere Schnittstelle zwischen internen Skills und externen Tools
5. Erstelle Beispiel-MCP-Registration

**Verwendete Skills:**
- `secure-api-client` — API-Pattern-Referenz
- `mission-control` — Tool-Erstellungs-Pattern

**Erwartetes Ergebnis:**
- `docs/mcp-registry-design.md`
- `registry/examples/mcp-example.yaml`

**Validierung:**
- [ ] MCP-Konzept verständlich dokumentiert
- [ ] Unterschied interne Skills vs externe Tools klar
- [ ] Schnittstelle definiert

**Betroffene Dateien:**
- `docs/mcp-registry-design.md` (neu)
- `registry/examples/mcp-example.yaml` (neu)

**Rollback:**
Löschen der neuen Dateien.

---

### Schritt 4: Integrations-Validierung
**Status:** ⬜ pending

**Ziel:**
Sicherstellen, dass Phase 3 Designs kompatibel mit Phase 1/2 sind.

**Aktionen:**
1. Prüfe: Nutzt Session Store bestehende Hook-Engine?
2. Prüfe: Kann Projekt-Lernen auf Search-Index zugreifen?
3. Prüfe: Sind MCP-Tools in Skill-Registry integrierbar?
4. Erstelle Integrations-Diagramm
5. Identifiziere potentielle Konflikte

**Verwendete Skills:**
- Kein Skill nötig

**Erwartetes Ergebnis:**
- `docs/phase3-integration.md` mit Analyse
- Liste von Anpassungen an Phase 1/2 (falls nötig)

**Validierung:**
- [ ] Keine Breaking Changes identifiziert ODER
- [ ] Breaking Changes dokumentiert mit Migrationspfad
- [ ] Integrationspunkte klar definiert

**Betroffene Dateien:**
- `docs/phase3-integration.md` (neu)

**Rollback:**
Löschen der Datei.

---

### Schritt 5: Review & Freigabe
**Status:** ⬜ pending

**Ziel:**
Alle Designs reviewn und Freigabe für Implementierung vorbereiten.

**Aktionen:**
1. Sammle alle Design-Dokumente
2. Erstelle Zusammenfassung für Parzival
3. Markiere Entscheidungspunkte
4. Vorbereitung Freigabefrage
5. Update Plan-Status auf "ready for implementation"

**Verwendete Skills:**
- Kein Skill nötig

**Erwartetes Ergebnis:**
- Vollständiger Plan mit allen Designs
- Freigabefrage formuliert

**Validierung:**
- [ ] Alle vorherigen Schritte abgeschlossen
- [ ] Dokumentation vollständig
- [ ] Freigabe bereit

**Betroffene Dateien:**
- Dieser Plan (Status-Update)

**Rollback:**
Status zurücksetzen auf "draft".

---

## 🔍 Review

### Automatisches Review

**Review-Checkliste:**
- [ ] Alle Schritte ausgeführt?
- [ ] Designs konsistent mit Phase 1/2?
- [ ] Keine unbeabsichtigten Breaking Changes?
- [ ] Dokumentation vollständig?
- [ ] Freigabe klar formuliert?

**Gefundene Probleme:**
| Problem | Schwere | Lösung | Status |
|---------|---------|--------|--------|
| - | - | - | - |

**Gelernte Erkenntnisse:**
- {{Wird nach Abschluss gefüllt}}

**Feedback für self-improving-andrew:**
```
{{Wird nach Abschluss gefüllt}}
```

---

### Manuelles Review

**Reviewer:** Parzival

**Review-Notizen:**
{{Freitext für Feedback}}

**Genehmigung:**
- [ ] Plan designs approved for implementation

**Unterschrift:**
`Parzival` am `{{Datum}}`

---

## 📝 Notizen & Log

### 2026-03-25 22:38 — Plan erstellt
Plan angelegt als Beispiel für Phase 2 Plan-Template.

---

## 🏁 Abschluss

**Zusammenfassung:**
{{Wird nach Abschluss gefüllt}}

**Metriken:**
- Geplante Schritte: 5
- Tatsächliche Schritte: {{N}}
- Erfolgreich: {{N}}
- Fehlgeschlagen: {{N}}
- Dauer: {{Zeit}}

**Nächste Schritte:**
- Phase 3 Implementierung (nach Freigabe)

**Archivierung:**
- [ ] Plan nach Abschluss archivieren

---

*Dies ist ein Beispiel-Plan zur Demonstration des Templates*
