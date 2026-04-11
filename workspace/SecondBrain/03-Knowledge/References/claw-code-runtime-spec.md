---
date: 06-04-2026
type: reference
status: active
tags: [claw-code, runtime, agent-loop, safety, memory-bridge]
source: vault-archive/Main_Obsidian_Vault/Kimi_Agent_OpenClaw GitHub/
topics: [runtime, conversation-loop, safety-guard, fort-knox]
projects: [openclaw-renovation]
tier: 1
priority: high
---

# Claw-Code: Conversation Runtime Specification

> Der Kern-Agent-Loop mit Safety-Integration und Memory-Bridge.
> **Original:** SUBAGENT_CONVERSATION_RUNTIME_SPEC.md (12 KB)

---

## Kern-Struktur

```rust
pub struct ConversationRuntime<C, T> {
    client: C,        // API Client
    tools: T,         // Tool Executor
    session: Session,
    config: RuntimeConfig,
}
```

### RuntimeConfig Defaults
```
MAX_ITERATIONS: 16
MAX_CONTEXT_TOKENS: 102_400  // 80% of 128K
TIMEOUT_SECONDS: 300
MAX_RETRIES: 3
```

---

## ECC-Erweiterungen

### SafetyGuard Trait
- `validate_tool_call()` - Prüft vor Ausführung
- `validate_file_access()` - Sandbox-Prüfung
- `validate_network_request()` - Domain-Check

### MemoryBridge
- `sync_conversation()` → Daily Log
- `update_memory_md()` → MEMORY.md bei Signifikanz
- `sync_to_obsidian()` → Second Brain

---

## Agent Loop Fluss

```
User Input
    ↓
Safety Check (Fort Knox)
    ↓
Add to Session
    ↓
Token Limit? → Compact
    ↓
Build Prompt (SOUL + USER + MEMORY)
    ↓
Stream Request
    ↓
Process Response
    ↓
Execute Tools (mit Safety)
    ↓
Sync Memory
    ↓
Done
```

---

## Nutzen für OpenClaw

| Feature | Vorteil |
|---------|---------|
| Iteration Limit | Endlosschleifen verhindern |
| Timeout | Hängende Sessions erkennen |
| Safety Guard | Sichere Tool-Ausführung |
| Memory Bridge | Automatische Dokumentation |
| Compaction | Lange Sessions möglich |

---

## Verwandte Dokumente

- [[claw-code-masterplan|MASTERPLAN]] → Architektur
- [[claw-code-permissions-spec|PERMISSIONS]] → Safety Details
- [[claw-code-compaction-spec|COMPACTION]] → Memory Management
- [[openclaw-renovation|Renovierung]] → Integrationsziel

---

*Kuratierte Version. Vollständige Trait-Definitionen im Original.*