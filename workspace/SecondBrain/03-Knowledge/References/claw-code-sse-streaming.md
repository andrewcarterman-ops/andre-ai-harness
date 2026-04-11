---
date: 06-04-2026
type: reference
status: active
tags: [claw-code, sse, streaming, api, real-time, retry]
source: vault-archive/Main_Obsidian_Vault/Kimi_Agent_OpenClaw GitHub/
topics: [streaming, api-client, token-tracking, retry-logic]
projects: [openclaw-renovation]
tier: 1
priority: high
---

# Claw-Code: SSE Streaming Specification

> Echtzeit-Streaming von API-Antworten mit Retry-Logik und Token-Tracking.
> **Original:** SUBAGENT_SSE_STREAMING_SPEC.md (10 KB)

---

## Kern-Komponenten

### 1. SseStreamParser
```rust
pub struct SseStreamParser {
    buffer: String,
    max_frame_bytes: usize,
}
```

**Features:**
- Incremental frame parsing mit Buffering
- Multi-line SSE frame handling
- Ping filtering (keepalive messages)
- Frame size limits
- JSON object boundary handling

### 2. Retry Logic (Exponential Backoff)
```rust
RETRY_BASE_MS: 1_000
RETRY_MAX_MS: 60_000
MAX_RETRIES: 3
RETRY_JITTER: 0.25  // ±25%
```

**Retryable Status Codes:** 408, 429, 5xx

### 3. Token Tracking (Anthropic)
```rust
input_tokens: u64
output_tokens: u64
cache_creation_input_tokens: u64
cache_read_input_tokens: u64
```

---

## Integration: SecureStreamingClient

**Ziel:** `skills/secure-api-client/src/streaming.rs`

Kombiniert:
- claw-code: SSE Parser, Retry
- OpenClaw: Auth-Manager, Rate-Limiter

**Ergebnis:** Produktionsreifer Streaming-Client

---

## Nutzen für OpenClaw

| Feature | Vorteil |
|---------|---------|
| Streaming | User sieht Antwort sofort |
| Retry | Keine Abbrüche bei Netzwerkfehlern |
| Token-Tracking | Kostenkontrolle pro Session |
| Backoff | API nicht überlasten |

---

## Verwandte Dokumente

- [[claw-code-masterplan|MASTERPLAN]] → Übergeordnete Strategie
- [[claw-code-runtime-spec|RUNTIME]] → Wie wird Streaming genutzt?
- [[openclaw-renovation|OpenClaw Renovierung]] → Wo integrieren?

---

*Kuratierte Version. Vollständige Implementierungsdetails im Original.*