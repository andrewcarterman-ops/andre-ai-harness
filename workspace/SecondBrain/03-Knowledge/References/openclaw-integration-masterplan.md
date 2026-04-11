---
date: 01-04-2026
type: reference
category: openclaw
source: "vault-archive/Kimi_Agent_OpenClaw GitHub/"
tags: [reference, openclaw, claw-code, integration, architecture]
---

# OpenClaw-ClawCode Integration Masterplan

> Vollständige Integration von claw-code Komponenten in OpenClaw (ECC Framework)

## Executive Summary

**Kernprinzipien:**
- Nutze Rust-Layer (produktionsreif), ignoriere Python-Layer (Scaffolding)
- Priorisiere: SSE Streaming → Conversation Loop → Permissions → Compaction
- Erhalte ECC-Framework Integrität (Fort Knox, Second Brain, Autoresearch)
- Synergien > Neuerfindung

---

## 1. Bestandsanalyse: OpenClaw Setup

### Aktuelle Architektur
```
~/.openclaw/workspace/
├── SOUL.md                    # Identität
├── USER.md                    # Parzival Profil
├── MEMORY.md                  # Kuratiertes Langzeitgedächtnis
├── AGENTS.md                  # Systemkonfiguration
├── HEARTBEAT.md               # Periodische Tasks
├── TOOLS.md                   # Umgebungsspezifische Notizen
├── memory/YYYY-MM-DD.md       # Tägliche Session-Logs
├── skills/                    # Agent Skills
└── docs/                      # OpenClaw Dokumentation
```

### Aktive Fähigkeiten
- **Security Review**: Automatisierte Sicherheitsanalyse
- **Secure API Client**: HTTP mit Auth/Rate Limiting
- **ECC Autoresearch**: Autonome Recherche mit Safety-Constraints
- **Sub-Agent Orchestration**: sessions_spawn, ACP-Protokoll
- **Memory System**: Tägliche Logs + kuratiertes MEMORY.md

---

## 2. Claw-Code Komponenten

### Repository Struktur
```
claw-code/
├── rust/crates/               # PRODUKTIONSREIF (4,000 LOC)
│   ├── api/                   # SSE Streaming + HTTP Client
│   ├── runtime/               # Conversation Loop + Session
│   ├── tools/                 # Tool Implementierungen
│   ├── commands/              # Slash Commands
│   ├── plugins/               # Hooks Pipeline
│   └── claw-cli/              # REPL Binary
└── PARITY.md                  # Implementierungs-Status
```

### Prioritäten (Nach PDF-Audit)

```
TIER 1 (Deploy Today):        TIER 2 (Deploy This Week):
├── SSE Streaming             ├── Session Compaction
├── Conversation Loop         ├── Tool Executor Trait
├── Permission Framework      ├── MCP Integration
├── HTTP Retry Logic          ├── Plugin Hooks
└── File Operation Tools      └── CLAW.md Config
```

---

## 3. Wichtige Konstanten

```rust
// Runtime Config Defaults
const MAX_ITERATIONS: usize = 16;
const MAX_CONTEXT_TOKENS: usize = 102_400; // 80% of 128K
const TIMEOUT_SECONDS: u64 = 300;
const MAX_RETRIES: u32 = 3;

// Compaction
const MAX_ESTIMATED_TOKENS: usize = 10_000;
const PRESERVE_RECENT_MESSAGES: usize = 4;

// Retry
const RETRY_BASE_MS: u64 = 1_000;
const RETRY_MAX_MS: u64 = 60_000;
const RETRY_JITTER: f64 = 0.25; // ±25%
```

---

## 4. ECC-Integration Punkte

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

## 5. Trait-Hierarchie

### Kern-Traits (aus claw-code)
```rust
trait ApiClient { async fn stream_request(...) -> SseStream; }
trait ToolExecutor { async fn execute(...) -> ToolResult; }
trait PermissionPrompter { async fn prompt(...) -> PermissionResponse; }
trait Summarizer { async fn summarize(...) -> String; }
```

### ECC-Erweiterungen
```rust
trait SafetyGuard { 
    async fn validate_tool_call(...);
    fn validate_file_access(...);
    fn validate_network_request(...);
}
trait MemoryBridge { async fn sync_conversation(...); }
trait MemoryClassifier { async fn classify(...) -> Importance; }
```

---

## 6. Konversations-Loop Fluss

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
│ Stream Request  │ ──► API
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
```

---

## 7. Datei-Zuordnung

| Claw-Code Datei | Ziel im OpenClaw | Status |
|-----------------|------------------|--------|
| `api/src/stream.rs` | `skills/secure-api-client/streaming.rs` | TIER 1 |
| `runtime/conversation.rs` | `crates/ecc-runtime/runtime.rs` | TIER 1 |
| `runtime/permissions.rs` | `skills/security-review/permissions.rs` | TIER 1 |
| `runtime/compact.rs` | `crates/memory-compaction/compactor.rs` | TIER 2 |
| `runtime/prompt.rs` | `crates/context-assembly/prompt.rs` | TIER 2 |
| `tools/file_ops.rs` | `crates/tool-registry/file_ops.rs` | TIER 1 |

---

## 8. Test-Checkliste

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

## 9. Häufige Fehler

| Problem | Ursache | Lösung |
|---------|---------|--------|
| SSE frames verloren | Buffer zu klein | max_frame_bytes erhöhen |
| Infinite loop | Kein iteration limit | max_iterations: 16 |
| Token overflow | Keine compaction | 80% threshold |
| Permission bypass | Falsche Reihenfolge | Check VOR execution |
| Memory loss | Kein sync | Nach jedem Turn |

---

**Version:** 1.0  
**Letzte Aktualisierung:** 2026-04-01
