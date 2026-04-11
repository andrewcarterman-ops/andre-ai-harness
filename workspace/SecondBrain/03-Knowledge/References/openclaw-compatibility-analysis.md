---
date: 06-04-2026
type: reference
status: active
tags: [openclaw, compatibility, analysis, frankenstein]
source: vault-archive/Main_Obsidian_Vault/Master Rework 06.04.2026/2.0 openclaw-kompatibilitaets-analyse.md
overlap_checked: true
overlap_with: [openclaw-renovation.md]
overlap_percentage: 20%
migration_strategy: ADD
reason: Externe Analyse unserer System-Architektur als FRANKENSTEIN
---

# OpenClaw: Kompatibilitäts-Analyse

> **Zusammenfassung**: Das ist ein FRANKENSTEIN - 3 Systeme ohne Integrations-Layer  
> **Analyst**: Externe System-Analyse  
> **Datum**: 06-04-2026

---

## Die 3 Systeme

| System | Ursprung | Was übernommen wurde |
|--------|----------|----------------------|
| **claw-code** | 173k Stars, Rust-basiert | Session-Management (.jsonl), Gateway |
| **everything-claude-code** | 142k Stars, JS/TS | Agent-Struktur, Skills-System |
| **Eigenentwicklung** | - | second-brain, PARA-Struktur |

**Ergebnis**: 175k LOC, die sich gegenseitig behindern.

---

## Struktur-Analyse

### Was gefunden wurde:

```
.openclaw/
├── openclaw.json (+ 5 Backup-Dateien!)          ← Konfiguration
├── agents/main/sessions/                        ← Sessions (JSONL)
│   ├── *.jsonl                                  ← Aktive Sessions
│   ├── *.jsonl.deleted.2026-04-02T00-02-39      ← GELÖSCHTE (viele!)
│   └── *.jsonl.reset.2026-03-25T20-01-17        ← RESETTED (viele!)
├── registry/hooks.yaml                          ← Minimal
├── workspace/                                   ← DEIN BEREICH
│   ├── second-brain/                            ← Existiert bereits!
│   ├── memory/                                  ← Sessions (Markdown?)
│   ├── plans/                                   ← Pläne
│   ├── registry/                                ← ADRs, etc.
│   ├── skills/                                  ← Skills
│   ├── contexts/                                ← Kontexte
│   ├── crates/                                  ← Rust-Code
│   ├── claw-code/                               ← Original-Repo
│   ├── claw-code-audit/                         ← Audit
│   └── test-obsidian-vault/PARA/Projects/       ← Test-Vault
```

---

## Kritische Probleme (Müssen komplett neu)

### 1. Session-Management (JSONL → Markdown)

**Aktuell:**
- Sessions als `.jsonl` (JSON Lines)
- `.deleted.` und `.reset.` Dateien überall
- Keine echte Versionierung
- **Das ist das claw-code System**

**Warum das schiefgeht:**
- Binary-Format (nicht menschenlesbar)
- Keine Integration mit Obsidian
- Datenverlust bei Korruption
- Schwer zu debuggen

**Lösung:** Markdown + YAML Frontmatter + Git

---

### 2. Hook-System

**Aktuell:**
- `hooks/session-start.md` existiert
- `hooks/session-end.md` existiert
- **Aber**: Keine automatische Ausführung!

**Problem:** Dokumentation sagt "Aktiv", aber es ist nur ein Protokoll.

---

### 3. Registry-System

**Aktuell:**
- `agents.yaml` - Definiert, aber werden alle genutzt?
- `skills.yaml` - 18 Skills, aber nicht alle aktiv?
- `hooks.yaml` - Minimal

**Frage:** Wird die Registry überhaupt vollständig genutzt?

---

## Empfohlene Fixes

| Problem | Lösung | Priorität |
|---------|--------|-----------|
| JSONL Sessions | Markdown + Git State Machine | P0 |
| Hook System | Automatisierung oder Klärung | P1 |
| Registry Usage | Audit und Cleanup | P2 |

---

## Verwandte Dokumente

- [[openclaw-renovation|OpenClaw Renovierung]] → Projekt-Plan
- [[openclaw-system-architecture|System Architecture]] → Domain-Analyse
- [[openclaw-action-checklist|Action Checklist]] → Konkrete Tasks
- [[openclaw-schritt-fuer-schritt|Schritt-für-Schritt]] → Detaillierte Anleitung

---

**Original**: openclaw-kompatibilitaets-analyse.md (9 KB)  
**Status**: Kritische Analyse unserer Architektur