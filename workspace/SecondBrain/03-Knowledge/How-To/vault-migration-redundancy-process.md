---
date: 11-04-2026
type: process
status: active
tags: [migration, vault-analysis, best-practice, deduplication]
---

# Vault-Migration: Redundanz-Optimierter Prozess

> Für alle zukünftigen Batches: Nie 1:1 kopieren ohne Prüfung!

---

## Der 4-Schritte-Prozess

### Schritt 1: Analyse (100%)
- Datei lesen und verstehen
- Hauptthemen identifizieren
- Geschätzte Relevanz bewerten

### Schritt 2: Duplikat-Check (KRITISCH)
| Was prüfen | Wie |
|------------|-----|
| Themen-Überlappung | Keywords vergleichen |
| Gleiche Struktur | Überschriften vergleichen |
| Gleiche Empfehlungen | Inhalt vergleichen |

**Frage:** Gibt es bereits eine Datei zum gleichen Thema?

### Schritt 3: Entscheidungs-Matrix

| Überlappung | Aktion | Beispiel |
|-------------|--------|----------|
| **0-20%** (Keine) | 100% ADD | Neue Spezifikation |
| **21-50%** (Gering) | PARTIAL MERGE | Einzigartige Inhalte extrahieren |
| **51-80%** (Mittel) | VERLINKEN + Ergänzen | Bestehende Datei erweitern |
| **81-100%** (Hoch) | SKIP oder Ersetzen | Nur wenn besser |

### Schritt 4: Implementierung mit Verlinkung

**Für PARTIAL MERGE:**
```markdown
## Ergänzung aus [Quelle]
**Original:** [Pfad zur Original-Datei]

[Einzigartiger Inhalt hier]

**Siehe auch:** [[bestehende-datei|Hauptdokumentation]]
```

**Für 100% ADD:**
- Normale Migration mit YAML, Tags, WikiLinks
- In Index und MOCs verlinken

**Für VERLINKEN:**
- Nur Verweis in bestehender Datei hinzufügen
- "Detaillierte Analyse: [[neue-datei]]"

---

## Dokumentation von Entscheidungen

**In jeder Migration notieren:**
```yaml
---
source: [Original-Pfad]
overlap_checked: true
overlap_with: [Datei(en)]
overlap_percentage: [X%]
migration_strategy: [ADD|PARTIAL_MERGE|LINK|SKIP]
reason: [Kurze Begründung]
---
```

---

## Red Flags (WARNUNG)

Nie 1:1 migrieren wenn:
- [ ] Gleiche Überschriften gefunden
- [ ] Gleiche Code-Beispiele
- [ ] Gleiche Empfehlungen/ToDos
- [ ] Gleiche Architektur-Diagramme

Stattdessen:
→ VERGLEICHEN → EXTRAHIEREN → VERLINKEN

---

## Beispiele aus Batch 1 & 2

| Batch | Datei | Überlappung | Strategie | Ergebnis |
|-------|-------|-------------|-----------|----------|
| 1 | MASTERPLAN | 20% (Konzept) | 100% ADD | ✓ Neue Datei |
| 2 | Recommendations | 40% (Renovierung) | PARTIAL MERGE | ✓ Ergänzung |
| 2 | Action-Items | 30% (Renovierung) | 100% ADD + Link | ✓ Checkliste separat |
| 2 | Edit-Bug Analysis | 0% (nur Workaround) | 100% ADD | ✓ Neue Datei |

---

## Nächste Batches

**Noch zu analysieren:**
- [ ] Master Rework 06.04.2026/ (6 Dateien)
- [ ] Root-Dateien (AI_AGENT_WORK_INSTRUCTION.md, etc.)
- [ ] PowerShell Scripts (31 Dateien)
- [ ] Templates (12 Dateien)
- [ ] Obsidian Configs (44 Dateien)

**Für jede:** 4-Schritte-Prozess anwenden!

---

**Erstellt:** 11-04-2026  
**Gilt ab:** Sofort für alle Batches