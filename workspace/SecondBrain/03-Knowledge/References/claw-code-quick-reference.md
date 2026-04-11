---
date: 01-04-2026
type: reference
status: active
tags: [claw-code, quick-reference, constants, checklist]
source: vault-archive/Main_Obsidian_Vault/Kimi_Agent_OpenClaw GitHub/
topics: [reference, constants, testing, troubleshooting]
projects: [openclaw-renovation]
tier: 2
priority: medium
---

# Claw-Code: Quick Reference

> Kompakte Übersicht aller wichtigen Konstanten, Traits und Checklisten.
> **Original:** QUICK_REFERENCE.md (6 KB)

---

## Prioritäten (Nach PDF-Audit)

```
TIER 1 (Deploy Today):        TIER 2 (Deploy This Week):
├── SSE Streaming             ├── Session Compaction
├── Conversation Loop         ├── Tool Executor Trait
├── Permission Framework      ├── MCP Integration
├── HTTP Retry Logic          ├── Plugin Hooks
└── File Operation Tools      └── CLAW.md Config
```

---

## Wichtige Konstanten

### Runtime Config
```
MAX_ITERATIONS: 16
MAX_CONTEXT_TOKENS: 102_400  // 80% of 128K
TIMEOUT_SECONDS: 300
MAX_RETRIES: 3
```

### Compaction
```
MAX_ESTIMATED_TOKENS: 10_000
PRESERVE_RECENT_MESSAGES: 4
```

### Retry
```
RETRY_BASE_MS: 1_000
RETRY_MAX_MS: 60_000
RETRY_JITTER: 0.25  // ±25%
```

---

## Trait-Hierarchie

### Kern-Traits (claw-code)
- `ApiClient` → `stream_request()`
- `ToolExecutor` → `execute()`
- `PermissionPrompter` → `prompt()`
- `Summarizer` → `summarize()`

### ECC-Erweiterungen
- `SafetyGuard` → `validate_tool_call()`
- `MemoryBridge` → `sync_conversation()`

---

## Test-Checkliste

### Unit Tests
- [ ] SSE Parser: simple, multiline, partial, ping
- [ ] Permission: allow, deny, prompt, overrides
- [ ] Compaction: trigger, partition, summary

### Integration Tests
- [ ] End-to-End Conversation
- [ ] Tool Execution mit Permissions
- [ ] Session Persistence

### ECC Tests
- [ ] Fort Knox Isolation
- [ ] Second Brain Sync

---

## Häufige Fehler

| Problem | Lösung |
|---------|--------|
| SSE frames verloren | `max_frame_bytes` erhöhen |
| Infinite loop | `max_iterations: 16` setzen |
| Token overflow | 80% threshold nutzen |
| Permission bypass | Check VOR execution |

---

## Verwandte Dokumente

- [[claw-code-integration-index|Index]] → Hauptübersicht
- [[claw-code-masterplan|MASTERPLAN]] → Detaillierte Planung
- [[openclaw-renovation|Renovierung]] → Projekt-Kontext

---

*Kuratierte Version. Für vollständige Details siehe spezifische SPECs.*