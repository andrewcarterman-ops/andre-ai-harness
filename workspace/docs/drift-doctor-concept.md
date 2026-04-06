# Drift Doctor - Konzeptdokumentation

**Status:** Phase 4 - Konzept (nicht implementiert)  
**Priorität:** Optional  
**Geplante Implementierung:** Phase 4+ oder Erweiterung

---

## Zweck

Drift Doctor erkennt und dokumentiert Abweichungen zwischen dem **Soll-Zustand** (Install-Manifest) und dem **Ist-Zustand** (tatsächliches System).

---

## Problem

Über Zeit entstehen Unterschiede zwischen dem definierten Zustand und der Realität:
- Dateien werden manuell gelöscht oder verschoben
- Registry-Einträge werden nicht aktualisiert
- Neue Dateien erscheinen ohne Manifest-Eintrag
- Versionen drift auseinander

---

## Konzept

### 1. Soll-Zustand (Source of Truth)
```yaml
# registry/install-manifest.yaml
components:
  - id: "registry-core"
    files:
      - path: "registry/agents.yaml"
        checksum: "sha256:abc123..."
```

### 2. Ist-Zustand (Scan)
```yaml
# Aktueller Zustand
 detected_files:
  - path: "registry/agents.yaml"
    exists: true
    size: 1157
    modified: "2026-03-25T22:15:00Z"
    checksum: "sha256:abc123..."
```

### 3. Vergleich (Drift Detection)
```yaml
# Drift Report
drift_detected: true
differences:
  - type: "file_missing"
    path: "registry/old-file.yaml"
    manifest: "present"
    actual: "missing"
    severity: "high"
    
  - type: "checksum_mismatch"
    path: "registry/agents.yaml"
    expected: "sha256:abc123..."
    actual: "sha256:def456..."
    severity: "medium"
    
  - type: "untracked_file"
    path: "registry/new-file.yaml"
    manifest: "missing"
    actual: "present"
    severity: "low"
```

---

## Arten von Drift

| Typ | Beschreibung | Schwere | Beispiel |
|-----|--------------|---------|----------|
| **File Missing** | Datei im Manifest fehlt im System | Hoch | Wichtige Config gelöscht |
| **Checksum Mismatch** | Datei wurde verändert | Mittel | Manuelle Änderung ohne Update |
| **Untracked File** | Datei existiert nicht im Manifest | Niedrig | Neue Datei hinzugefügt |
| **Version Drift** | Versionsnummern weichen ab | Mittel | Update nicht dokumentiert |
| **Dependency Drift** | Abhängigkeiten nicht erfüllt | Hoch | Benötigte Datei fehlt |

---

## Workflow

```
1. Soll laden (install-manifest.yaml)
      ↓
2. Ist scannen (Dateisystem)
      ↓
3. Vergleichen (Diff generieren)
      ↓
4. Report erstellen (memory/drift/DRIFT-{timestamp}.md)
      ↓
5. Benachrichtigen (bei Schwere > threshold)
      ↓
6. Optional: Auto-Fix (nicht empfohlen für Minimal)
```

---

## Report-Format

```markdown
# Drift Report 2026-03-25

## Zusammenfassung
- Drift erkannt: Ja
- Kritisch: 1
- Mittel: 2
- Niedrig: 3

## Details

### ❌ Kritisch
| Datei | Typ | Aktion |
|-------|-----|--------|
| registry/skills.yaml | File Missing | Wiederherstellen oder Manifest aktualisieren |

### ⚠️ Mittel
| Datei | Typ | Aktion |
|-------|-----|--------|
| registry/agents.yaml | Checksum Mismatch | Manifest-Checksum aktualisieren |

### ℹ️ Niedrig
| Datei | Typ | Aktion |
|-------|-----|--------|
| registry/extra.yaml | Untracked | Zum Manifest hinzufügen oder löschen |

## Empfohlene Aktionen
1. [ ] registry/skills.yaml wiederherstellen
2. [ ] Manifest-Checksums aktualisieren
```

---

## Integration

### Mit Install-Manifest
```yaml
# install-manifest.yaml
components:
  - id: "registry-core"
    checksums:
      agents.yaml: "sha256:abc123..."
      skills.yaml: "sha256:def456..."
```

### Mit Hooks
```yaml
# Drift-Check bei jedem Session-Start
hooks:
  session:start:
    actions:
      - type: "drift_check"
        if_drift: "warn"
```

### Mit Audit
```yaml
# Audit-Kategorie für Drift
audit:
  categories:
    - id: "drift"
      checks:
        - type: "drift_detect"
          threshold: "medium"
```

---

## Implementierungsoptionen

### Option A: Report-Only (Empfohlen)
- Nur Erkennen und Berichten
- Keine automatischen Änderungen
- Mensch entscheidet und korrigiert

### Option B: Auto-Fix (Fortgeschritten)
- Automatische Korrektur von "File Missing"
- Manuelle Bestätigung für "Checksum Mismatch"
- Backup vor Änderungen

### Option C: Self-Healing (Expert)
- Vollautomatische Korrektur
- Rollback bei Fehlern
- Überwachung erforderlich

---

## Status

- [x] Konzept dokumentiert
- [ ] Implementierung geplant für Phase 4+
- [ ] Checksum-Generierung im Manifest
- [ ] Vergleichs-Algorithmus
- [ ] Report-Generator
- [ ] Integration mit Hooks

---

*Konzept erstellt: 2026-03-25*  
*Autor: Andrew*  
*Phase: 4 (Konzept)*
