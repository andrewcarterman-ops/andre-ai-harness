# Harness Redesign - Complete Implementation

> **Version:** 1.0.0  
> **Date:** 2026-04-04  
> **Status:** ✅ IMPLEMENTED  

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture](#2-architecture)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [API Reference](#5-api-reference)
6. [Hooks](#6-hooks)
7. [Learning System](#7-learning-system)
8. [Context Management](#8-context-management)
9. [Token Optimization](#9-token-optimization)
10. [Troubleshooting](#10-troubleshooting)
11. [Contributing](#11-contributing)

---

## 1. System Overview

The Harness Redesign is a comprehensive AI assistant framework with:

- **3-Tier Context System:** Hot (2K), Warm (10K), Cold (∞)
- **Vector Knowledge Store:** ChromaDB with hybrid search
- **Parallel Execution:** Thread pool with 2-8 workers
- **Obsidian Integration:** Bidirectional Second Brain sync

### Performance Metrics

| Metric | Target | Status |
|--------|--------|--------|
| Token Efficiency | 85%+ | ✅ Implemented |
| Knowledge Retrieval | <2s | ✅ Implemented |
| Learning Capture | 80%+ | ✅ Implemented |
| Response Latency | -30% | ✅ Implemented |

---

## 2. Architecture

See `CONTEXT_SYSTEM.md` for detailed architecture.

### Key Components

1. **TokenBudgetManager** - 3-tier token allocation
2. **ContextTierManager** - Automatic promotion/demotion
3. **ChromaKnowledgeStore** - Vector storage
4. **ParallelOrchestrator** - Thread pool execution
5. **ObsidianBridge** - Bidirectional sync

---

## 3. Installation

```bash
# Clone repository
git clone https://github.com/openclaw/harness.git
cd harness

# Install dependencies
npm install

# Setup
npm run setup

# Migrate
npm run migrate

# Test
npm test
```

---

## 4. Configuration

### Token Budget

```yaml
# config/token_budget.yaml
token_budget:
  total_limit: 12000
  tiers:
    hot: { max_tokens: 2000, eviction_policy: lru }
    warm: { max_tokens: 10000, eviction_policy: relevance }
    cold: { max_tokens: null, eviction_policy: archive }
```

### Obsidian Bridge

```yaml
# config/obsidian.yaml
obsidian_bridge:
  vault_path: "~/Obsidian/SecondBrain"
  sync:
    mode: bidirectional
    interval: 300
```

---

## 5. API Reference

### Token Budget Manager

```typescript
const budget = new TokenBudgetManager(config);
await budget.allocate(item, 'hot');
const status = budget.getStatus();
```

### Context Tier Manager

```typescript
const context = new ContextTierManager(config);
await context.addContext(item, 'hot');
await context.promoteContext(itemId);
```

### Knowledge Store

```typescript
const store = new ChromaKnowledgeStore(config);
await store.addDocument(doc);
const results = await store.search({ query, topK: 5 });
```

### Parallel Orchestrator

```typescript
const orchestrator = new ParallelOrchestrator(config);
orchestrator.start();
const results = await orchestrator.submitAll(tasks);
```

---

## 6. Hooks

See `CONTEXT_HOOKS.md` for detailed hook documentation.

### Active Hooks (Phase 1)

- `session:start` - Session initialization
- `session:end` - Session termination + sync

### Planned Hooks (Phase 2)

- `context:promote` - Tier promotion
- `context:demote` - Tier demotion
- `knowledge:discovered` - New knowledge

---

## 7. Learning System

See `CONTEXT_LEARNING.md` for details.

### SKILL.md Format

```yaml
---
skill: Pattern Name
created: 2025-01-15
confidence: high
triggers: ["trigger1", "trigger2"]
---

## Pattern Description
```

---

## 8. Context Management

See `CONTEXT_TOKEN.md` and `CONTEXT_KNOWLEDGE.md`.

### 3-Tier System

| Tier | Storage | Capacity | Access |
|------|---------|----------|--------|
| Hot | Memory | 2K | <1ms |
| Warm | Redis | 10K | 5-20ms |
| Cold | Disk | ∞ | 50-200ms |

---

## 9. Token Optimization

### Targets

- **Efficiency:** 85%+ (40% improvement)
- **Auto-pruning:** Enabled
- **No manual `/compact` needed**

---

## 10. Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Token budget exceeded | Auto-eviction enabled |
| Edit tool fails | Use read+write workaround |
| Sync errors | Check Obsidian vault path |

### Edit Tool Fix

```typescript
// FIXED: splice(idx, 1, alias) instead of splice(idx, 1)
// See src/utils/EditTool.ts
```

---

## 11. Contributing

1. Fork repository
2. Create feature branch
3. Add tests
4. Submit PR

### License

MIT License

---

## Context Files

- `CONTEXT_SYSTEM.md` - Architecture
- `CONTEXT_TOOLS.md` - Tool reference
- `CONTEXT_HOOKS.md` - Hook system
- `CONTEXT_LEARNING.md` - Learning system
- `CONTEXT_TOKEN.md` - Token management
- `CONTEXT_KNOWLEDGE.md` - Knowledge store
- `CONTEXT_BRIDGE.md` - Bridge architecture

---

*Complete Implementation*
*© 2026 OpenClaw Harness Redesign*
