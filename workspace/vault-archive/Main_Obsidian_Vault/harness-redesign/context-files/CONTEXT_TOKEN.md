# CONTEXT_TOKEN.md

## Token Budget Management

### 3-Tier System

| Tier | Storage | Capacity | Access Time | Use Case |
|------|---------|----------|-------------|----------|
| **Hot** | Memory | ~2K tokens | <1ms | Active conversation |
| **Warm** | Redis | ~10K tokens | 5-20ms | Recent context |
| **Cold** | Disk + Vector | Unlimited | 50-200ms | Archived knowledge |

### Configuration

```yaml
token_budget:
  total_limit: 12000
  allocation:
    system_prompt: 1000
    context: 8000
    conversation_history: 2000
    response_buffer: 1000
```

### Eviction Policy

- **Hot:** LRU (Least Recently Used)
- **Warm:** Relevance score
- **Cold:** Archive oldest

### Relevance Formula

```
score = (recency × 0.3) + (frequency × 0.3) + (semantic × 0.3)
```

### Performance Targets

- Token Efficiency: **85%+**
- Waste Reduction: **40%**
- Auto-pruning: **Enabled**

---

*Token Management Document*
*Version: 1.0.0*
