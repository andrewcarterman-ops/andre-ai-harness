# CONTEXT_KNOWLEDGE.md

## Knowledge Store (ChromaDB)

### Overview

Vector database for semantic knowledge retrieval with hybrid search.

### Schema

```typescript
interface KnowledgeDocument {
  id: string;
  content: string;
  metadata: {
    source: string;
    type: 'skill' | 'error' | 'insight' | 'context';
    created: Date;
    project: string;
    tags: string[];
    confidence: number;
  };
  embedding: number[384]; // all-MiniLM-L6-v2
}
```

### Hybrid Search

```typescript
{
  semanticWeight: 0.7,  // Vector similarity
  keywordWeight: 0.3    // BM25/TF-IDF
}
```

### Collections

- **skills:** Extracted patterns
- **errors:** Error patterns & solutions
- **insights:** Session learnings

### Performance

- **Retrieval Time:** <2 seconds
- **Embedding Model:** all-MiniLM-L6-v2
- **Dimensions:** 384
- **Similarity:** Cosine

---

*Knowledge Store Document*
*Version: 1.0.0*
