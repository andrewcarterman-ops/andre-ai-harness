
# OPENCLAW-CLAWCODE INTEGRATION: QUICK REFERENCE
## Fuer schnelle Orientierung waehrend Implementation

---

## PRIORITAETEN (Nach PDF-Audit)

```
TIER 1 (Deploy Today):        TIER 2 (Deploy This Week):
├── SSE Streaming             ├── Session Compaction
├── Conversation Loop         ├── Tool Executor Trait
├── Permission Framework      ├── MCP Integration
├── HTTP Retry Logic          ├── Plugin Hooks
└── File Operation Tools      └── CLAW.md Config
```

---

## DATEI-ZUORDNUNG

| claw-code Datei | Ziel im OpenClaw | Status |
|-----------------|------------------|--------|
| `api/src/stream.rs` | `skills/secure-api-client/streaming.rs` | TIER 1 |
| `runtime/conversation.rs` | `crates/ecc-runtime/runtime.rs` | TIER 1 |
| `runtime/permissions.rs` | `skills/security-review/permissions.rs` | TIER 1 |
| `runtime/compact.rs` | `crates/memory-compaction/compactor.rs` | TIER 2 |
| `runtime/prompt.rs` | `crates/context-assembly/prompt.rs` | TIER 2 |
| `tools/file_ops.rs` | `crates/tool-registry/file_ops.rs` | TIER 1 |

---

## ECC-INTEGRATION PUNKTE

```
┌─────────────────────────────────────────────────────────┐
│                    ECC FRAMEWORK                         │
├─────────────────────────────────────────────────────────┤
│  Fort Knox ◄────► SafetyGuard (validate_tool_call)      │
│  Second Brain ◄─► MemoryBridge (sync_conversation)      │
│  Autoresearch ◄─► MCP Client (externe Tools)            │
│  Security Review ◄► PermissionPolicy (risk_analyzer)    │
│  Daily Logs ◄───► DailyLogWriter (write_daily_log)      │
│  MEMORY.md ◄────► MemoryMdUpdater (update_memory_md)    │
└─────────────────────────────────────────────────────────┘
```

---

## WICHTIGE KONSTANTEN (aus claw-code)

```rust
// Runtime Config Defaults
const MAX_ITERATIONS: usize = 16;
const MAX_CONTEXT_TOKENS: usize = 102_400; // 80% of 128K
const TIMEOUT_SECONDS: u64 = 300;
const MAX_RETRIES: u32 = 3;

// Compaction
const MAX_ESTIMATED_TOKENS: usize = 10_000;
const PRESERVE_RECENT_MESSAGES: usize = 4;

// Prompt Assembly
const MAX_INSTRUCTION_FILE_CHARS: usize = 4_000;
const MAX_TOTAL_INSTRUCTION_CHARS: usize = 12_000;

// Retry
const RETRY_BASE_MS: u64 = 1_000;
const RETRY_MAX_MS: u64 = 60_000;
const RETRY_JITTER: f64 = 0.25; // ±25%
```

---

## TRAIT-HIERARCHIE

```rust
// Kern-Traits (aus claw-code)
trait ApiClient { async fn stream_request(...) -> SseStream; }
trait ToolExecutor { async fn execute(...) -> ToolResult; }
trait PermissionPrompter { async fn prompt(...) -> PermissionResponse; }
trait Summarizer { async fn summarize(...) -> String; }

// ECC-Erweiterungen
trait SafetyGuard { 
    async fn validate_tool_call(...);
    fn validate_file_access(...);
    fn validate_network_request(...);
}
trait MemoryBridge { async fn sync_conversation(...); }
trait MemoryClassifier { async fn classify(...) -> Importance; }
```

---

## KONVERSATIONS-LOOP FLUSS

```
User Message
    │
    ▼
┌─────────────────┐
│ Safety Check    │ ──► Fort Knox Guard
└─────────────────┘
    │
    ▼
┌─────────────────┐
│ Add to Session  │
└─────────────────┘
    │
    ▼
┌─────────────────┐     YES
│ Token Limit?    │ ─────────► Compact
└─────────────────┘
    │ NO
    ▼
┌─────────────────┐
│ Build Prompt    │ ──► SOUL.md + USER.md + MEMORY.md
└─────────────────┘
    │
    ▼
┌─────────────────┐
│ Stream Request  │ ──► Anthropic API
└─────────────────┘
    │
    ▼
┌─────────────────┐
│ Process Stream  │ ──► Content + Tool Calls
└─────────────────┘
    │
    ▼
┌─────────────────┐     YES
│ Tools?          │ ─────────► Execute + Loop
└─────────────────┘
    │ NO
    ▼
┌─────────────────┐
│ Sync Memory     │ ──► Daily Log + MEMORY.md + Obsidian
└─────────────────┘
    │
    ▼
   Done
```

---

## TEST-CHECKLISTE

### Unit Tests
- [ ] SSE Parser: simple, multiline, partial, ping-filter
- [ ] Permission: allow, deny, prompt, overrides
- [ ] Compaction: trigger, partition, summary, reconstruct
- [ ] Token Estimation: accuracy check

### Integration Tests
- [ ] End-to-End Conversation
- [ ] Tool Execution mit Permissions
- [ ] Session Persistence
- [ ] Memory Sync

### ECC Tests
- [ ] Fort Knox Isolation
- [ ] Second Brain Sync
- [ ] Safety Guard Blocks
- [ ] Audit Log Writes

---

## HAUFIGE FEHLER

| Problem | Ursache | Loesung |
|---------|---------|---------|
| SSE frames verloren | Buffer zu klein | max_frame_bytes erhöhen |
| Infinite loop | Kein iteration limit | max_iterations: 16 |
| Token overflow | Keine compaction | 80% threshold |
| Permission bypass | Falsche Reihenfolge | Check VOR execution |
| Memory loss | Kein sync | Nach jedem Turn |

---

## ROLLEN DER SUB-AGENTEN

| Sub-Agent | Verantwortlichkeit | Input | Output |
|-----------|-------------------|-------|--------|
| SSE Streaming | API Client | claw-code stream.rs | streaming.rs |
| Conversation | Core Loop | claw-code conversation.rs | ecc-runtime/ |
| Permissions | Security | claw-code permissions.rs + risk | permissions.rs |
| Compaction | Memory | claw-code compact.rs + classifier | compactor.rs |

---

**Letzte Aktualisierung:** 2026-04-01
**Version:** 1.0
