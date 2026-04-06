# ARCHITECTURE DECISION RECORD (ADR)
## ADR-001: Keine CLAW.md Discovery Implementation

**Status:** ✅ ACCEPTED (Abgelehnt / Won't Implement)
**Datum:** 2026-04-02
**Entscheidungsträger:** Parzival (User) + Andrew (AI)

---

## Kontext

Die CLAW.md Discovery aus claw-code wurde als potentielles Feature evaluiert. Es ermöglicht hierarchische Instructions-Dateien (von Root zu Leaf-Verzeichnissen) für kontext-abhängige Anweisungen.

## Optionen Evaluiert

| Option | Beschreibung | Aufwand |
|--------|--------------|---------|
| A | CLAW.md Discovery implementieren | ~30-45 Min |
| B | Aktuelles System beibehalten (SOUL.md + MEMORY.md) | 0 Min |

## Entscheidung

**Option B gewählt** - Keine Implementation von CLAW.md Discovery.

## Begründung

### Argumente GEGEN Implementation:

| Argument | Gewichtung | Erklärung |
|----------|------------|-----------|
| **Single-Projekt-Setup** | Hoch | Aktuell nur ein Hauptprojekt (OpenClaw-ECC Framework). Keine Notwendigkeit für projekt-spezifische Regeln. |
| **Bestehendes System funktioniert** | Hoch | SOUL.md (Identität) + MEMORY.md (Kontext) + USER.md (Profil) decken aktuelle Bedürfnisse vollständig ab. |
| **Keine Team-Anforderung** | Mittel | Keine Multi-User oder Team-Entwicklung geplant. Keine Notwendigkeit für versionierbare Standards im Repo. |
| **Komplexität vs. Nutzen** | Mittel | ~45 Min Implementierung + laufende Maintenance für Feature, das aktuell nicht genutzt würde. |
| **Fragmentierungsrisiko** | Mittel | Anweisungen über viele Dateien verteilt = schwerer nachzuvollziehen, wo eine Regel definiert ist. |
| **Konfliktpotential** | Niedrig | Widersprüchliche Regeln zwischen Root- und Sub-Verzeichnis möglich. |

### Argumente FÜR Implementation (zur Vollständigkeit):

| Argument | Gewichtung | Gegenargument |
|----------|------------|---------------|
| Flexibilität bei Multi-Projekten | Niedrig | Aktuell kein Bedarf sichtbar. Wenn später nötig, kann nachimplementiert werden. |
| Team-Standards versionieren | Niedrig | Kein Team-Setup geplant. |
| claw-code Parity | Niedrig | 100% Parity nicht erforderlich; nur Features die Nutzen bringen. |

## Konsequenzen

### Positiv:
- ✅ Weniger Code-Maintenance
- ✅ Einfacheres System (SOUL.md ist Single Source of Truth)
- ✅ Keine Fragmentierung der Anweisungen
- ✅ Zeit sparen für wichtigere Features (MCP, Web Fetch)

### Negativ:
- ❌ Keine automatische Kontext-Anpassung bei Verzeichnis-Wechsel
- ❌ Bei späterem Multi-Projekt-Setup: Manuelle SOUL.md-Anpassung nötig

## Alternative (falls später benötigt)

Wenn in Zukunft Multi-Projekt-Support nötig wird:
1. Einfache Lösung: Projekt-Präfixe in MEMORY.md
2. Komplexe Lösung: CLAW.md Discovery nachimplementieren (Code-Vorlage in FUTURE_FEATURES.md)

## Verwandte Dokumente

- `FUTURE_FEATURES.md` - Enthält Implementierungs-Vorlage falls später nötig
- `IMPLEMENTATION_ANALYSIS.md` - Zeigt 5/6 Features als implementiert

---

**Besonderheit dieser Entscheidung:**

Dies ist eine bewusste "Won't Implement"-Entscheidung, keine Aufschiebung. Das Feature wurde verstanden, evaluiert und aktiv abgelehnt wegen:
- Fehlender aktueller Use Cases
- Überwiegender Komplexität
- Funktionierender Alternativen

Die Entscheidung ist **reversibel** (kann später revidiert werden), aber **final** für aktuelle Version.

---

*Dokument erstellt: 2026-04-02*
*Zuletzt geändert: 2026-04-02*
