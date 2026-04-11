---
date: 10-04-2026
type: knowledge
category: concept
tags: [knowledge, system, memory, agent]
---

# System: Memory & Vault Architektur

## Übersicht

Dieses SecondBrain funktioniert zusammen mit dem Agent-Memory-System. Hier ist die Architektur:

## Zwei Systeme

### 1. MEMORY.md (Agent Langzeit-Gedächtnis)

**Ort:** `C:\Users\andre\.openclaw\workspace\MEMORY.md`

**Inhalt:**
- System-Spezifikationen (Hardware, Software)
- User-Präferenzen (Sprache, Datumsformat, Design)
- Wichtige Kontexte über Parzival
- **Verweis auf dieses Vault!**

**Wann wird es gelesen?**
- Bei jedem Session-Start (automatisch)
- Enthält "Bootstrapping"-Information

### 2. SecondBrain Vault (Strukturiertes Wissen)

**Ort:** `C:\Users\andre\.openclaw\workspace\SecondBrain\` (dieses Verzeichnis)

**Inhalt:**
- Daily Notes (was passiert ist)
- Projekte (aktiv, pausiert, abgeschlossen)
- Entscheidungen (ADRs)
- Wissens-Base (Konzepte, How-Tos, Referenzen)

## Wie sie zusammenarbeiten

```
┌─────────────────┐         ┌──────────────────┐
│   MEMORY.md     │◄───────►│  SecondBrain/    │
│  (Bootstrapping)│         │  (Wissens-Base)  │
└─────────────────┘         └──────────────────┘
        │                             │
        │   "Parzival hat Vault bei    │   "Was sind meine
        │    SecondBrain/"            │    aktiven Projekte?"
        │                             │
        ▼                             ▼
┌─────────────────────────────────────────────┐
│              AGENT (Andrew)                 │
│  1. Liest MEMORY.md beim Start              │
│  2. Weiß wo das Vault ist                   │
│  3. Kann gezielt im Vault suchen            │
└─────────────────────────────────────────────┘
```

## Für den Agent: Wichtige Pfade

| Wenn der User fragt nach... | Dann schaue in... |
|---------------------------|-------------------|
| "Was sind meine Projekte?" | `SecondBrain/02-Projects/` |
| "Was haben wir besprochen?" | `SecondBrain/01-Daily/` |
| "Zeig meine Entscheidungen" | `SecondBrain/04-Decisions/` |
| "Wissen über X" | `SecondBrain/03-Knowledge/` |
| "Meine Notizen" | `SecondBrain/01-Daily/` |

## Konventionen (WICHTIG!)

- **Sprache:** Deutsch für Antworten
- **Datum:** DD-MM-YYYY (deutsches Format, z.B. 10-04-2026)
- **Dateinamen:** Snake_Case (z.B. mission_control_v2.md)
- **Links:** WikiLinks mit Aliases (z.B. `[[projekt|Anzeigename]]`)
- **Design:** Linear-style dark aesthetic bevorzugt

## Night Agent (Geplant)

Ein automatisierter Agent, der jede Nacht:
- Den Index aktualisiert
- Broken Links findet
- Duplikate erkennt
- Einen Morning Report sendet

**Projekt:** Siehe `02-Projects/Active/vault-migration.md`

---

*Diese Note erklärt der LLM, wie das System funktioniert.*
*Letzte Aktualisierung: 10-04-2026*
