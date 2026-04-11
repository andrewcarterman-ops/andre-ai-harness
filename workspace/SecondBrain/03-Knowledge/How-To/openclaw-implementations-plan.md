---
date: 07-04-2026
type: knowledge
category: how-to
tags: [how-to, openclaw, implementation, roadmap]
---

# How-To: OpenClaw Renovierung - 12-Wochen-Plan

## Übersicht

Transformation von 175k LOC Chaos zu einem stabilen Multi-Agent AI Harness.

| Phase | Dauer | Fokus | Status |
|-------|-------|-------|--------|
| 0 | Woche 1 | Stabilisierung | 🔄 |
| 1 | Wochen 2-3 | Modularisierung | ⏳ |
| 2 | Woche 4 | State Management | ⏳ |
| 3 | Wochen 5-6 | Obsidian RAG | ⏳ |
| 4 | Wochen 7-8 | Code-Analyse | ⏳ |
| 5 | Wochen 9-10 | Sequential Workflow | ⏳ |
| 6 | Wochen 11-12 | Integration | ⏳ |

## Phase 0: Stabilisierung (Woche 1) - KRITISCH

**Ziel:** Datenverlust verhindern

### Schritte

1. **Atomic Writes implementieren**
   ```rust
   fn atomic_write(path: &Path, content: &str) -> Result<()> {
       let temp_path = path.with_extension("tmp");
       std::fs::write(&temp_path, content)?;
       std::fs::rename(&temp_path, path)?;  // Atomar
       Ok(())
   }
   ```

2. **Backup-System für Sessions**
   - Backup in `.system/backups/`
   - Git-Commit nach jeder Session
   - 7-Tage-Rollback-Fenster

3. **Fehlerbehandlung vereinheitlichen**
   - Kein `unwrap()` mehr im Produktivcode
   - Jedes Datei-Operation muss `Result` zurückgeben

## Phase 1: Modularisierung (Wochen 2-3)

**Ziel:** 175k LOC in Module aufteilen

**Neue Struktur:**
```
openclaw/
├── crates/
│   ├── core/          # Orchestrator, State Management
│   ├── agents/        # Agenten-Implementierungen
│   ├── obsidian/      # Obsidian-Integration
│   └── code-analysis/ # Tree-sitter Integration
└── python/            # AI-Layer
```

## Phase 2: State Management (Woche 4)

**Ziel:** Markdown-basiertes State System

**Key Concept:**
```rust
pub struct Session {
    pub id: String,
    pub status: SessionStatus,  // Todo, InProgress, Review, Done
    pub agent: String,
    pub content: String,  // Markdown
}
```

## Phase 3: Obsidian RAG (Wochen 5-6)

**Stack:**
- Vector DB: LanceDB
- Embeddings: BGE-M3 (Python)
- Chunking: Markdown-aware

## Phase 4: Code-Analyse (Wochen 7-8)

**Agenten:**
1. Structure Agent - Mappt Codebase
2. Quality Agent - Findet Code-Smells
3. Security Agent - Scannt auf Schwachstellen
4. Refactor Agent - Schlägt Änderungen vor

## Phase 5: Sequential Workflow (Wochen 9-10)

**Pattern:**
```
Analyzer → Planner → Executor → Report
```

## Phase 6: Integration (Wochen 11-12)

**CLI-Interface:**
```bash
openclaw session list
openclaw analyze --target <path>
openclaw vault search "<query>"
```

## Verwandte Dokumente

- [[ADR-004-openclaw-architecture|Architektur-Entscheidungen]]
- [[openclaw-renovation|Projekt-Übersicht]]

## Ressourcen

- [swarms-rs](https://github.com/The-Swarm-Corporation/swarms-rs)
- [LanceDB](https://lancedb.github.io/lancedb/)
- [Tree-sitter](https://tree-sitter.github.io/)

## Erstellt
07-04-2026

## Letzte Aktualisierung
10-04-2026
