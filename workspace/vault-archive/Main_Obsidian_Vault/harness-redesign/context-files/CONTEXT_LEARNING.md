# CONTEXT_LEARNING.md

## Continuous Learning System

### Overview

Automatic pattern recognition and knowledge capture from sessions.

### Mechanism

1. **Pattern Recognition:** Identify recurring patterns
2. **Knowledge Extraction:** Extract insights from sessions
3. **YAML Storage:** Structured metadata in SKILL.md files
4. **Confidence Scoring:** Reliability assessment

### SKILL.md Format

```yaml
---
skill: API Error Handling
created: 2025-01-15
confidence: high
triggers: ["axios error", "fetch failed"]
---

## Pattern

When encountering API errors:
1. Check network connectivity
2. Validate request format
3. Implement retry logic
```

### Learning Pipeline

1. **Session Analysis:** Extract learnings
2. **Confidence Scoring:** 0-1 scale
3. **Knowledge Store:** Vector embeddings
4. **SKILL.md Generation:** Auto-create files
5. **Obsidian Sync:** Update Second Brain

### Statistics

- **Total Skills:** 15+
- **Categories:** Planning, Development, Security, Quality
- **Sources:** Original + ECC-adapted

---

*Learning System Document*
*Version: 1.0.0*
