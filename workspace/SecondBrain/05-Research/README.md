# 05-Research — AI-Generated Improvement Proposals

**Zweck:** Staging-Area für vom Agenten generierte Verbesserungen, Erkenntnisse und Experimente. Nichts hier wird automatisch implementiert — alles wartet auf explizites GO.

## Workflow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Pending   │ ──► │  Validated  │ ──► │ Implemented │
│  (Vorschlag)│     │  (GePrüft)  │     │  (Fertig)   │
└─────────────┘     └─────────────┘     └─────────────┘
       │
       └────────────►┌─────────────┐
                     │   Rejected  │
                     │  (Abgelehnt)│
                     └─────────────┘
```

## Ordner

| Ordner | Inhalt |
|--------|--------|
| `pending/` | Neue Vorschläge vom Agenten. Jeder Vorschlag ist eine separate Markdown-Datei mit Kontext, Begründung und Diff/Änderung. |
| `validated/` | Von dir (oder nach Test) bestätigte Vorschläge, die bereit für Implementierung sind. |
| `rejected/` | Abgelehnte Vorschläge — nicht löschen, sondern als negatives Wissen archivieren. |

## Datei-Format für Vorschläge

Jeder Vorschlag sollte folgende Struktur haben:

```markdown
---
status: pending
source: asi-evolve-loop
target: skills/secure-api-client
created: 14-04-2026
score: 87.5
---

# Vorschlag: [Kurztitel]

## Kontext
Was wurde analysiert?

## Begründung
Warum ist das eine Verbesserung?

## Konkrete Änderung
SEARCH/REPLACE-Block oder vollständiger Code.

## Risiken / Offene Fragen
Was könnte schiefgehen?

## Validation
- [ ] Getestet
- [ ] Implementiert
- [ ] Abgelehnt
```

## Regel

**Niemand implementiert aus diesem Ordner ohne explizites GO von Parzival.**
