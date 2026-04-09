# CONTEXT_BRIDGE.md

## Bridge Architecture

### Overview

Connects Harness with external systems through standardized bridges.

### Implemented Bridges

#### 1. Obsidian Bridge
- **Purpose:** Bidirectional Second Brain sync
- **Sync Mode:** Bidirectional / To Obsidian / From Obsidian
- **Interval:** 5 minutes
- **Mapping:**
  - Sessions → AI/Sessions/
  - Insights → AI/Insights/
  - Errors → AI/Errors/
  - Skills → AI/Skills/

#### 2. YAML↔SKILL Bridge
- **Purpose:** Sync YAML registry with SKILL.md files
- **Flow:** Bidirectional
- **Auto-generate:** From SKILL.md frontmatter

#### 3. Hook Bridge
- **Purpose:** Integrate hook system with new architecture
- **Events:** context:promote, context:demote, knowledge:discovered

### Configuration

```yaml
obsidian_bridge:
  vault_path: "~/Obsidian/SecondBrain"
  sync:
    mode: bidirectional
    interval: 300
```

---

*Bridge Architecture Document*
*Version: 1.0.0*
