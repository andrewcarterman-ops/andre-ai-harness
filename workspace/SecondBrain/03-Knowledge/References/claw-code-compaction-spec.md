---
date: 06-04-2026
type: reference
status: active
tags: [claw-code, compaction, memory, session, summarization]
source: vault-archive/Main_Obsidian_Vault/Kimi_Agent_OpenClaw GitHub/
topics: [compaction, memory-management, classification, obsidian-sync]
projects: [openclaw-renovation, night-agent]
tier: 2
priority: medium
---

# Claw-Code: Session Compaction Specification

> Automatische Zusammenfassung langer Sessions mit ECC Memory-Integration.
> **Original:** SUBAGENT_COMPACTION_SPEC.md (11 KB)

---

## Kern-Komponenten

### CompactionEngine
```rust
pub struct CompactionEngine<S: Summarizer> {
    config: CompactionConfig,
    summarizer: S,
}

pub struct CompactionConfig {
    max_estimated_tokens: usize,  // 10_000 (80% of 128K)
    preserve_recent: usize,       // 4 messages
}
```

### Algorithmus
1. **Check:** Token count vs threshold
2. **Partition:** Behalte letzte 4 Nachrichten
3. **Summarize:** Generiere Summary via LLM
4. **Reconstruct:** Session mit Summary + Preserve

---

## ECC-Erweiterungen

### MemoryClassifier
Vier Kategorien:
| Kategorie | Beispiel | Aktion |
|-----------|----------|--------|
| **Critical** | Fehler, Entscheidungen | → MEMORY.md |
| **Important** | Erkenntnisse, Patterns | → Second Brain |
| **Reference** | Kontext, Erklärungen | → In Summary |
| **Trivial** | "Hallo", "Ok" | → Löschen |

### ObsidianSync
Wichtige Messages automatisch nach Second Brain syncen.

### MemoryMdUpdater
Critical Insights in MEMORY.md eintragen.

---

## Nutzen für OpenClaw

| Feature | Vorteil |
|---------|---------|
| Token-Limit | Lange Sessions möglich |
| Klassifikation | Wichtiges behalten, triviales löschen |
| Auto-Sync | Keine manuelle Nacharbeit |
| Daily Logs | Automatische Dokumentation |

**Besonders relevant für:** [[night-agent|Night Agent Projekt]]

---

## Verwandte Dokumente

- [[claw-code-masterplan|MASTERPLAN]] → Architektur
- [[claw-code-runtime-spec|RUNTIME]] → Wann compacten?
- [[night-agent|Night Agent]] → Anwendungsfall

---

*Kuratierte Version. Vollständige Klassifikations-Logik im Original.*