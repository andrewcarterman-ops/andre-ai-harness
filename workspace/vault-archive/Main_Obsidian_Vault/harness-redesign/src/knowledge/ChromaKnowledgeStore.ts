/**
 * Chroma Knowledge Store
 * Vector database for semantic knowledge retrieval
 * 
 * @module ChromaKnowledgeStore
 * @version 1.0.0
 */

import { EventEmitter } from 'events';

export interface KnowledgeDocument {
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
  embedding?: number[];
}

export interface SearchOptions {
  query: string;
  filters?: {
    type?: string[];
    project?: string;
    tags?: string[];
    dateRange?: [Date, Date];
  };
  topK: number;
  hybrid?: {
    semanticWeight: number;
    keywordWeight: number;
  };
}

export interface SearchResult {
  document: KnowledgeDocument;
  score: number;
  semanticScore?: number;
  keywordScore?: number;
}

export interface KnowledgeStoreConfig {
  collectionName: string;
  embeddingModel?: string;
  embeddingDimension?: number;
  distanceMetric?: 'cosine' | 'euclidean' | 'dot';
}

export class ChromaKnowledgeStore extends EventEmitter {
  private config: KnowledgeStoreConfig;
  private documents: Map<string, KnowledgeDocument>;
  private initialized: boolean;

  constructor(config: KnowledgeStoreConfig) {
    super();
    this.config = {
      embeddingModel: 'all-MiniLM-L6-v2',
      embeddingDimension: 384,
      distanceMetric: 'cosine',
      ...config,
    };
    this.documents = new Map();
    this.initialized = false;
  }

  /**
   * Initialize the knowledge store
   */
  async initialize(): Promise<void> {
    if (this.initialized) return;

    // In production, this would connect to ChromaDB
    // For now, using in-memory storage
    this.initialized = true;
    this.emit('initialized');
  }

  /**
   * Add document to knowledge store
   */
  async addDocument(doc: KnowledgeDocument): Promise<void> {
    await this.initialize();

    // Generate embedding if not provided
    if (!doc.embedding) {
      doc.embedding = await this.generateEmbedding(doc.content);
    }

    this.documents.set(doc.id, doc);
    this.emit('document:added', doc);
  }

  /**
   * Add multiple documents
   */
  async addDocuments(docs: KnowledgeDocument[]): Promise<void> {
    for (const doc of docs) {
      await this.addDocument(doc);
    }
  }

  /**
   * Search knowledge store with hybrid search
   */
  async search(options: SearchOptions): Promise<SearchResult[]> {
    await this.initialize();

    const queryEmbedding = await this.generateEmbedding(options.query);
    const results: SearchResult[] = [];

    for (const doc of this.documents.values()) {
      // Filter check
      if (!this.matchesFilters(doc, options.filters)) continue;

      // Semantic similarity
      const semanticScore = doc.embedding 
        ? this.cosineSimilarity(queryEmbedding, doc.embedding)
        : 0;

      // Keyword matching (BM25-like)
      const keywordScore = this.keywordMatch(options.query, doc.content);

      // Hybrid score
      const hybrid = options.hybrid || { semanticWeight: 0.7, keywordWeight: 0.3 };
      const totalScore = 
        semanticScore * hybrid.semanticWeight +
        keywordScore * hybrid.keywordWeight;

      if (totalScore > 0) {
        results.push({
          document: doc,
          score: totalScore,
          semanticScore,
          keywordScore,
        });
      }
    }

    // Sort by score and return topK
    return results
      .sort((a, b) => b.score - a.score)
      .slice(0, options.topK);
  }

  /**
   * Get document by ID
   */
  async getDocument(id: string): Promise<KnowledgeDocument | undefined> {
    return this.documents.get(id);
  }

  /**
   * Update document
   */
  async updateDocument(id: string, updates: Partial<KnowledgeDocument>): Promise<void> {
    const doc = this.documents.get(id);
    if (!doc) {
      throw new Error(`Document ${id} not found`);
    }

    Object.assign(doc, updates);
    
    // Regenerate embedding if content changed
    if (updates.content) {
      doc.embedding = await this.generateEmbedding(doc.content);
    }

    this.documents.set(id, doc);
    this.emit('document:updated', doc);
  }

  /**
   * Delete document
   */
  async deleteDocument(id: string): Promise<void> {
    this.documents.delete(id);
    this.emit('document:deleted', id);
  }

  /**
   * Get all documents
   */
  async getAllDocuments(): Promise<KnowledgeDocument[]> {
    return Array.from(this.documents.values());
  }

  /**
   * Get documents by type
   */
  async getDocumentsByType(type: string): Promise<KnowledgeDocument[]> {
    return Array.from(this.documents.values())
      .filter(doc => doc.metadata.type === type);
  }

  /**
   * Get documents by project
   */
  async getDocumentsByProject(project: string): Promise<KnowledgeDocument[]> {
    return Array.from(this.documents.values())
      .filter(doc => doc.metadata.project === project);
  }

  /**
   * Get similar documents
   */
  async getSimilarDocuments(docId: string, topK: number = 5): Promise<SearchResult[]> {
    const doc = this.documents.get(docId);
    if (!doc) {
      throw new Error(`Document ${docId} not found`);
    }

    return this.search({
      query: doc.content,
      topK: topK + 1, // +1 to exclude self
      hybrid: { semanticWeight: 1.0, keywordWeight: 0 },
    }).then(results => results.filter(r => r.document.id !== docId).slice(0, topK));
  }

  /**
   * Get store statistics
   */
  async getStats(): Promise<{
    totalDocuments: number;
    byType: Record<string, number>;
    byProject: Record<string, number>;
    averageConfidence: number;
  }> {
    const docs = Array.from(this.documents.values());
    
    const byType: Record<string, number> = {};
    const byProject: Record<string, number> = {};
    let totalConfidence = 0;

    for (const doc of docs) {
      byType[doc.metadata.type] = (byType[doc.metadata.type] || 0) + 1;
      byProject[doc.metadata.project] = (byProject[doc.metadata.project] || 0) + 1;
      totalConfidence += doc.metadata.confidence;
    }

    return {
      totalDocuments: docs.length,
      byType,
      byProject,
      averageConfidence: docs.length > 0 ? totalConfidence / docs.length : 0,
    };
  }

  /**
   * Clear all documents
   */
  async clear(): Promise<void> {
    this.documents.clear();
    this.emit('cleared');
  }

  // Private methods
  private async generateEmbedding(text: string): Promise<number[]> {
    // In production, this would use a real embedding model
    // For demo purposes, generating random normalized vector
    const embedding: number[] = [];
    let sum = 0;
    
    for (let i = 0; i < this.config.embeddingDimension!; i++) {
      const val = Math.random() * 2 - 1;
      embedding.push(val);
      sum += val * val;
    }
    
    // Normalize
    const norm = Math.sqrt(sum);
    return embedding.map(v => v / norm);
  }

  private cosineSimilarity(a: number[], b: number[]): number {
    let dotProduct = 0;
    let normA = 0;
    let normB = 0;
    
    for (let i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
  }

  private keywordMatch(query: string, content: string): number {
    const queryTerms = query.toLowerCase().split(/\s+/);
    const contentTerms = content.toLowerCase().split(/\s+/);
    
    let matches = 0;
    for (const term of queryTerms) {
      if (contentTerms.some(ct => ct.includes(term))) {
        matches++;
      }
    }
    
    return matches / queryTerms.length;
  }

  private matchesFilters(doc: KnowledgeDocument, filters?: SearchOptions['filters']): boolean {
    if (!filters) return true;

    if (filters.type && !filters.type.includes(doc.metadata.type)) return false;
    if (filters.project && filters.project !== doc.metadata.project) return false;
    if (filters.tags && !filters.tags.some(tag => doc.metadata.tags.includes(tag))) return false;
    if (filters.dateRange) {
      const [start, end] = filters.dateRange;
      if (doc.metadata.created < start || doc.metadata.created > end) return false;
    }

    return true;
  }
}

export default ChromaKnowledgeStore;
