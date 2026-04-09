---
session_id: "ECC-PATTERN-202401-001"
date: "2024-01-15"
tokens_used: 0
agent_mode: "pattern"
key_decisions: []
tags: ["pattern", "yaml", "frontmatter", "metadata"]
language: "markdown"
category: "documentation"
usage_count: 10
---

# PATTERN: YAML Frontmatter

## Überblick

| Feld | Wert |
|------|------|
| **Sprache** | Markdown |
| **Kategorie** | Documentation |
| **Usage Count** | 10 |
| **Status** | production |

## Problem

Dokumente benötigen strukturierte Metadaten für:
- Kategorisierung
- Filterung
- Automatisierung
- Tracking

## Lösung

YAML Frontmatter am Anfang von Markdown-Dateien für maschinenlesbare Metadaten.

## Implementierung

### Standard-Template

```markdown
---
session_id: "ECC-XXX-YYYYMM-NNN"
date: "YYYY-MM-DD"
tokens_used: 0
agent_mode: "mode"
key_decisions: []
tags: []
status: "active"
---
```

### ECC-spezifisch

```markdown
---
session_id: "ECC-PROJ-202401-001"
date: "2024-01-15"
tokens_used: 1500
agent_mode: "architect"
key_decisions:
  - "Entscheidung 1"
  - "Entscheidung 2"
tags: ["project", "ecc", "active"]
status: "active"
progress: 25
---
```

## Vorteile

- ✓ Maschinenlesbar
- ✓ Einfach zu parsen
- ✓ Weit verbreitet
- ✓ Funktioniert mit Dataview
- ✓ Git-freundlich

## Nachteile

- ✗ Nicht visuell im gerenderten Output
- ✗ Syntax-Fehler können Probleme verursachen
- ✗ Nicht standardisiert

## Wann verwenden?

- Obsidian Vaults
- GitHub/GitLab Repos
- Jekyll/Hugo Sites
- ECC Framework

## Wann NICHT verwenden?

- Einfache Notizen ohne Metadaten
- Externe Dokumente
- WYSIWYG-Editoren ohne YAML-Support

## Verwandte Patterns

- [[PATTERN-Dataview-Queries]]
- [[PATTERN-Documentation-as-Code]]

## Referenzen

- [YAML Spec](https://yaml.org/)
- [Obsidian Frontmatter](https://help.obsidian.md/Editing+and+formatting/Properties)

## Projekte mit diesem Pattern

```dataview
LIST
FROM "01-Projects"
WHERE contains(tags, "yaml")
```

## Notizen

### 2024-01-15
- Basis für alle ECC Templates
- Konsistente Metadaten-Struktur

---
*Pattern Created: 2024-01-15*
