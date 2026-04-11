---
date: 11-04-2026
type: reference-index
status: active
tags: [claw-code, integration, reference, index, rust, openclaw]
source: vault-archive/Main_Obsidian_Vault
topics: [streaming, runtime, permissions, compaction, architecture]
projects: [openclaw-renovation, vector-search-integration]
tier: mixed
---

# Claw-Code Integration: Index & Übersicht

> Zentrale Einstiegsseite für alle claw-code Spezifikationen und Integrationspläne.
> Quelle: `vault-archive/Main_Obsidian_Vault/Kimi_Agent_OpenClaw GitHub/`

---

## Was ist claw-code?

**claw-code** ist eine Rust-basierte Agent-Runtime, die folgende Komponenten bietet:
- SSE Streaming API Client
- Conversation Runtime Loop
- Permission Policy Framework
- Session Compaction Engine
- Tool Executor System

**Relevanz für uns:** Diese Komponenten können unser OpenClaw-System erweitern, insbesondere für:
- Echtzeit-Streaming von API-Antworten
- Robuste Sub-Agent-Runtime
- Verbesserte Sicherheit (Risk-based Permissions)
- Automatische Session-Zusammenfassung

---

## Die 6 Kern-Dokumente

### Tier 1: Sofort relevant (Hohe Priorität)

| Dokument | Thema | Nutzen | Link |
|----------|-------|--------|------|
| **MASTERPLAN** | Komplette Integrationsstrategie | Architektur-Entscheidungen, 3-Phasen-Plan | [[claw-code-masterplan\|Ansehen]] |
| **SSE_STREAMING_SPEC** | Echtzeit-API-Streaming | Sofortige Antworten, Token-Tracking, Retry-Logik | [[claw-code-sse-streaming\|Ansehen]] |
| **RUNTIME_SPEC** | Agent-Loop mit Safety | Fort Knox Integration, Memory-Bridge, robuste Ausführung | [[claw-code-runtime-spec\|Ansehen]] |
| **PERMISSIONS_SPEC** | Risk-basierte Permissions | Auto-Allow/Deny/Prompt, Audit-Logging, Sicherheit | [[claw-code-permissions-spec\|Ansehen]] |

### Tier 2: Mittelfristig relevant

| Dokument | Thema | Nutzen | Link |
|----------|-------|--------|------|
| **COMPACTION_SPEC** | Session-Zusammenfassung | Automatische Memory-Verwaltung, Night Agent | [[claw-code-compaction-spec\|Ansehen]] |
| **QUICK_REFERENCE** | Kompakte Übersicht | Schnelles Nachschlagen, Konstanten, Checklisten | [[claw-code-quick-reference\|Ansehen]] |

---

## Integration mit unseren Projekten

```
[[openclaw-renovation|OpenClaw Renovierung]]
├── Phase 3: Rust-Integration
│   ├── [[claw-code-masterplan|MASTERPLAN]] → Architektur
│   ├── [[claw-code-sse-streaming|SSE Streaming]] → API Layer
│   └── [[claw-code-runtime-spec|Runtime]] → Core Loop
│
├── Phase 4: Security & Safety
│   └── [[claw-code-permissions-spec|Permissions]] → Fort Knox Upgrade
│
└── Phase 5: Memory & RAG
    └── [[claw-code-compaction-spec|Compaction]] → Night Agent
```

---

## Wichtige Konstanten (Quick Reference)

```
MAX_ITERATIONS: 16
MAX_CONTEXT_TOKENS: 102_400 (80% of 128K)
TIMEOUT_SECONDS: 300
MAX_RETRIES: 3
RETRY_BASE_MS: 1_000
RETRY_MAX_MS: 60_000
```

---

## Wann sollte ich diese Dokumente lesen?

**Sofort:**
- "Wie integriere ich claw-code in OpenClaw?" → [[claw-code-masterplan|MASTERPLAN]]
- "Wie mache ich Echtzeit-Streaming?" → [[claw-code-sse-streaming|SSE_SPEC]]

**Bei Security-Themen:**
- "Wie sichere ich Tool-Ausführung?" → [[claw-code-permissions-spec|PERMISSIONS]]
- "Wie integriere ich Fort Knox?" → [[claw-code-runtime-spec|RUNTIME]]

**Für Langzeit-Architektur:**
- "Wie verwalte ich lange Sessions?" → [[claw-code-compaction-spec|COMPACTION]]

---

## Technologie-Stack

| Komponente | Technologie | Datei |
|------------|-------------|-------|
| Core | Rust | `crates/ecc-runtime/` |
| API Client | Rust + SSE | `skills/secure-api-client/streaming.rs` |
| Security | Rust + Policies | `skills/security-review/permissions.rs` |
| Memory | Rust + Obsidian Sync | `crates/memory-compaction/` |

---

## Verwandte Themen

- [[vector-search-integration|Vector Search Integration]] → Bessere Auffindbarkeit
- [[_MOC-Knowledge|Knowledge MOC]] → Übergeordnete Wissensstruktur
- [[_MOC-Projects|Projects MOC]] → Projekt-Übersicht

---

## Changelog

- **11-04-2026**: Index erstellt, 6 SPECs verlinkt
- **Status**: Warte auf Migration der Original-Dateien

---

*Dieser Index verlinkt auf die detaillierten Spezifikationen. Für die vollständigen Original-Dokumente siehe Backup in `00-Meta/Backups/BATCH1_*/`*
