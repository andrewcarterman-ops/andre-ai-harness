---
date: 01-04-2026
type: reference
category: openclaw
source: "vault-archive/Kimi_Agent_OpenClaw GitHub/"
tags: [reference, openclaw, quick-reference, cheat-sheet]
---

# OpenClaw Quick Reference

> Schnelle Übersicht für Implementation

---

## Prioritäten

```
TIER 1 (Deploy Today):        TIER 2 (Deploy This Week):
├── SSE Streaming             ├── Session Compaction
├── Conversation Loop         ├── Tool Executor Trait
├── Permission Framework      ├── MCP Integration
├── HTTP Retry Logic          ├── Plugin Hooks
└── File Operation Tools      └── CLAW.md Config
```

---

## Datei-Zuordnung

| Claw-Code Datei | Ziel im OpenClaw |
|-----------------|------------------|
| `api/src/stream.rs` | `skills/secure-api-client/streaming.rs` |
| `runtime/conversation.rs` | `crates/ecc-runtime/runtime.rs` |
| `runtime/permissions.rs` | `skills/security-review/permissions.rs` |
| `runtime/compact.rs` | `crates/memory-compaction/compactor.rs` |
| `runtime/prompt.rs` | `crates/context-assembly/prompt.rs` |
| `tools/file_ops.rs` | `crates/tool-registry/file_ops.rs` |

---

## Konstanten

```rust
// Runtime
const MAX_ITERATIONS: usize = 16;
const MAX_CONTEXT_TOKENS: usize = 102_400;
const TIMEOUT_SECONDS: u64 = 300;
const MAX_RETRIES: u32 = 3;

// Compaction
const MAX_ESTIMATED_TOKENS: usize = 10_000;
const PRESERVE_RECENT_MESSAGES: usize = 4;

// Retry
const RETRY_BASE_MS: u64 = 1_000;
const RETRY_MAX_MS: u64 = 60_000;
const RETRY_JITTER: f64 = 0.25;
```

---

## ECC-Integration

```
Fort Knox ◄────► SafetyGuard
Second Brain ◄─► MemoryBridge
Autoresearch ◄─► MCP Client
Security Review ◄► PermissionPolicy
Daily Logs ◄───► DailyLogWriter
MEMORY.md ◄────► MemoryMdUpdater
```

---

## Sub-Agenten

| Sub-Agent | Input | Output |
|-----------|-------|--------|
| SSE Streaming | stream.rs | streaming.rs |
| Conversation | conversation.rs | ecc-runtime/ |
| Permissions | permissions.rs + risk | permissions.rs |
| Compaction | compact.rs + classifier | compactor.rs |

---

**Version:** 1.0  
**Letzte Aktualisierung:** 2026-04-01
