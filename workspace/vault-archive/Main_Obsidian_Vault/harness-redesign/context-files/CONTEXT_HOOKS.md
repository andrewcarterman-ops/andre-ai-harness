# CONTEXT_HOOKS.md

## Hook System

### Overview

The Hook System provides event-driven architecture for extending Harness functionality.

### Execution Mode

**Current:** Phase 1 - Manual Execution
**Planned:** Phase 2 - Automatic Hook Engine

### Active Hooks (Phase 1)

#### session:start
- **Trigger:** Session initialization
- **Handler:** `hooks/session-start.md`
- **Actions:**
  1. Validate registry files
  2. Create session entry
  3. Load context (SOUL.md, USER.md, MEMORY.md)
  4. Log session start

#### session:end
- **Trigger:** Session termination
- **Handler:** `hooks/session-end.md`
- **Actions:**
  1. Update session metadata
  2. Write daily log
  3. Log session end
  4. Cleanup temp files
- **Post-Action:** Sync to Second Brain (if session > 10 min)

### Planned Hooks (Phase 2)

- `review:post_execution` - After critical operations
- `message:pre` - Before message processing
- `message:post` - After message processing
- `error:critical` - On critical errors
- `context:promote` - Context tier promotion
- `context:demote` - Context tier demotion
- `knowledge:discovered` - New knowledge found
- `token:budget_exceeded` - Token limit reached
- `obsidian:sync` - Obsidian sync triggered

### Manual Execution

In Phase 1, agents explicitly check and execute hooks:

```typescript
// Check at session start
hooks.check('session:start');

// Execute hook
hooks.execute('session:start', context);
```

---

*Hooks System Document*
*Version: 1.0.0*
