---
session_id: "ECC-SNIPPET-202401-001"
date: "2024-01-15"
tokens_used: 0
agent_mode: "snippet"
key_decisions: []
tags: ["snippet", "yaml", "template", "metadata"]
language: "yaml"
---

# SNIPPET: YAML Template

## Überblick

| Feld | Wert |
|------|------|
| **Sprache** | YAML |
| **Tags** | [yaml, template, metadata] |
| **Usage Count** | 15 |

## Beschreibung

Standard YAML Frontmatter Template für ECC Dokumente.

## Code

```yaml
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

## Verwendung

1. Am Anfang jeder neuen Markdown-Datei einfügen
2. Felder ausfüllen
3. Datei speichern

## Parameter

| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| session_id | string | Eindeutige Session-ID (ECC-TYPE-YYYYMM-NNN) |
| date | string | Datum im Format YYYY-MM-DD |
| tokens_used | int | Anzahl verwendeter Tokens |
| agent_mode | string | Agent-Modus (architect/coder/researcher/etc) |
| key_decisions | array | Wichtige Entscheidungen |
| tags | array | Tags für Kategorisierung |
| status | string | Status (active/completed/archived) |

## Output

Gültiges YAML Frontmatter für Obsidian/Dataview.

## Abhängigkeiten

- Obsidian mit Dataview Plugin
- YAML-fähiger Editor

## Verwandte Snippets

- [[SNIPPET-Markdown-Table]]
- [[SNIPPET-Dataview-Query]]

## Notizen

### 2024-01-15
- Basis für alle ECC Templates
- Konsistente Struktur

---
*Snippet Created: 2024-01-15*
