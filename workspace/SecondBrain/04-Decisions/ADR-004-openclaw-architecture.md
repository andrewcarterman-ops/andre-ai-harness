---
date: 07-04-2026
type: decision
status: accepted
tags: [decision, adr, architecture, openclaw]
adr_id: ADR-004
---

# ADR-004: OpenClaw Renovierung - Architektur-Entscheidungen

## Kontext

Das aktuelle System leidet unter "Frankenstein-Architektur": 175k LOC aus zwei großen Projekten (`everything-claude-code`, `claw-code`) zusammengeführt ohne klare Integrationsstrategie.

## Entscheidungen

### 1. Multi-Agent Pattern: "Subagents with Sequential Workflow"

**Entschieden:** Sequentielle Workflows statt paralleler Ausführung.

**Begründung:**
- Hardware kann nicht gut parallel skalieren (GTX 980M, 32GB RAM)
- Einfacheres Debugging
- Weniger Race Conditions bei Datei-Operationen

**Architektur:**
```
Orchestrator (Rust)
    ├── Analyzer Agent
    ├── Planner Agent
    └── Executor Agent
            ↓
    Obsidian RAG (Vector DB)
```

### 2. State Management: Git als State Machine

**Entschieden:** Jede Session als Markdown-File mit YAML Frontmatter.

**Begründung:**
- Jede Änderung ist versioniert
- Rollback möglich
- Obsidian kann direkt lesen/schreiben
- Menschenlesbar

### 3. Obsidian RAG Stack

| Komponente | Technologie | Begründung |
|------------|-------------|------------|
| Embeddings | BGE-M3 | Lokal, 1024 Dimensionen, beste Qualität |
| Vector DB | LanceDB | Lokal, datei-basiert |
| Chunking | Markdown-aware | Respektiert Überschriften, Code-Blöcke |

### 4. Code-Analyse: Tree-sitter statt Regex

**Entschieden:** AST-basierte Analyse.

**Begründung:**
- Versteht Code-Struktur
- Multi-Language (Rust, Python, TypeScript)
- Inkrementelles Parsing (schnell bei großen Dateien)

## Konsequenzen

- ✅ Besseres State Management
- ✅ Schnellere Code-Analyse
- ✅ Lokale RAG ohne Cloud-Abhängigkeit
- ⚠️ 12 Wochen Renovierungsaufwand
- ⚠️ Lernkurve für Tree-sitter

## Verwandte Entscheidungen

- [[openclaw-renovation|Projekt-Übersicht]]
- [[openclaw-implementations-plan|Implementations-Plan]]

## Erstellt
07-04-2026
