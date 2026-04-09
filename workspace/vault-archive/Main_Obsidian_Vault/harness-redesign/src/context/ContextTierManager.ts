/**
 * Context Tier Manager
 * Manages 3-tier context with automatic promotion/demotion
 * 
 * @module ContextTierManager
 * @version 1.0.0
 */

import { EventEmitter } from 'events';
import TokenBudgetManager, { 
  ContextItem, 
  Tier, 
  TokenBudgetConfig 
} from './TokenBudgetManager';

export interface RelevanceScore {
  recency: number;
  frequency: number;
  semantic: number;
  explicit: boolean;
  total: number;
}

export interface TierManagerConfig extends TokenBudgetConfig {
  relevanceWeights: {
    recency: number;
    frequency: number;
    semantic: number;
    explicit: number;
  };
  autoPromoteThreshold: number;
  autoDemoteThreshold: number;
}

export class ContextTierManager extends EventEmitter {
  private budgetManager: TokenBudgetManager;
  private config: TierManagerConfig;
  private itemScores: Map<string, RelevanceScore>;

  constructor(config: TierManagerConfig) {
    super();
    this.config = config;
    this.budgetManager = new TokenBudgetManager(config);
    this.itemScores = new Map();

    // Listen to budget manager events
    this.budgetManager.on('item:evicted', (item: ContextItem, tier: Tier) => {
      this.emit('context:evicted', item, tier);
    });

    this.budgetManager.on('item:promoted', (item: ContextItem, from: Tier, to: Tier) => {
      this.emit('context:promoted', item, from, to);
    });

    this.budgetManager.on('item:demoted', (item: ContextItem, from: Tier, to: Tier) => {
      this.emit('context:demoted', item, from, to);
    });
  }

  /**
   * Add context item with automatic tier assignment
   */
  async addContext(item: ContextItem, targetTier?: Tier): Promise<void> {
    // Calculate initial relevance score
    const score = this.calculateRelevanceScore(item);
    this.itemScores.set(item.id, score);

    // Determine tier if not specified
    const tier = targetTier || this.determineTier(score);

    // Allocate to budget manager
    const result = this.budgetManager.allocate(item, tier);

    if (!result.success) {
      throw new Error(`Failed to add context: ${result.message}`);
    }

    this.emit('context:added', item, tier);
  }

  /**
   * Access context item (triggers score update)
   */
  accessContext(itemId: string): ContextItem | undefined {
    const item = this.budgetManager.access(itemId);
    
    if (item) {
      // Update score
      const currentScore = this.itemScores.get(itemId);
      if (currentScore) {
        currentScore.frequency = Math.min(1, currentScore.frequency + 0.1);
        currentScore.recency = 1; // Just accessed
        currentScore.total = this.computeTotalScore(currentScore);
        
        // Check for promotion
        if (currentScore.total >= this.config.autoPromoteThreshold) {
          this.promoteContext(itemId).catch(() => {});
        }
      }
    }

    return item;
  }

  /**
   * Update semantic relevance score
   */
  updateSemanticScore(itemId: string, similarity: number): void {
    const score = this.itemScores.get(itemId);
    if (score) {
      score.semantic = Math.max(score.semantic, similarity);
      score.total = this.computeTotalScore(score);
    }
  }

  /**
   * Promote context item to higher tier
   */
  async promoteContext(itemId: string): Promise<void> {
    await this.budgetManager.promote(itemId);
  }

  /**
   * Demote context item to lower tier
   */
  async demoteContext(itemId: string): Promise<void> {
    await this.budgetManager.demote(itemId);
  }

  /**
   * Get context from appropriate tier
   */
  getContext(itemId: string): ContextItem | undefined {
    return this.accessContext(itemId);
  }

  /**
   * Get all context items from a specific tier
   */
  getTierContents(tier: Tier): ContextItem[] {
    const status = this.budgetManager.getStatus();
    const items: ContextItem[] = [];

    // This is a simplified version - in production would need direct access
    // to the underlying storage
    return items;
  }

  /**
   * Perform relevance-based eviction
   */
  async evictByRelevance(tokensNeeded: number, tier: Tier): Promise<void> {
    // Get all items in tier with their scores
    const tierItems = this.getTierContents(tier)
      .map(item => ({
        item,
        score: this.itemScores.get(item.id),
      }))
      .filter(({ score }) => score !== undefined)
      .sort((a, b) => (a.score?.total || 0) - (b.score?.total || 0)); // Lowest first

    let tokensFreed = 0;
    const itemsToEvict: ContextItem[] = [];

    for (const { item } of tierItems) {
      if (tokensFreed >= tokensNeeded) break;
      
      itemsToEvict.push(item);
      tokensFreed += item.tokenCount;
    }

    // Evict selected items
    for (const item of itemsToEvict) {
      await this.removeContext(item.id);
    }
  }

  /**
   * Get system status
   */
  getStatus() {
    const budgetStatus = this.budgetManager.getStatus();
    const averageScore = this.calculateAverageScore();

    return {
      ...budgetStatus,
      averageRelevanceScore: averageScore,
      itemsTracked: this.itemScores.size,
    };
  }

  /**
   * Pin context item (never evict)
   */
  pinContext(itemId: string): void {
    const score = this.itemScores.get(itemId);
    if (score) {
      score.explicit = true;
      score.total = this.computeTotalScore(score);
    }
  }

  /**
   * Unpin context item
   */
  unpinContext(itemId: string): void {
    const score = this.itemScores.get(itemId);
    if (score) {
      score.explicit = false;
      score.total = this.computeTotalScore(score);
    }
  }

  /**
   * Remove context item
   */
  async removeContext(itemId: string): Promise<void> {
    this.itemScores.delete(itemId);
    this.emit('context:removed', itemId);
  }

  /**
   * Optimize context distribution across tiers
   */
  async optimizeDistribution(): Promise<void> {
    const status = this.budgetManager.getStatus();

    // Promote high-relevance cold items to warm
    const coldItems = this.getTierContents('cold');
    for (const item of coldItems) {
      const score = this.itemScores.get(item.id);
      if (score && score.total >= this.config.autoPromoteThreshold) {
        await this.promoteContext(item.id).catch(() => {});
      }
    }

    // Demote low-relevance hot items to warm
    const hotItems = this.getTierContents('hot');
    for (const item of hotItems) {
      const score = this.itemScores.get(item.id);
      if (score && score.total <= this.config.autoDemoteThreshold && !score.explicit) {
        await this.demoteContext(item.id).catch(() => {});
      }
    }
  }

  // Private helper methods
  private calculateRelevanceScore(item: ContextItem): RelevanceScore {
    const now = Date.now();
    const lastAccessed = item.metadata?.lastAccessed?.getTime() || now;
    const age = now - lastAccessed;
    const maxAge = 24 * 60 * 60 * 1000; // 24 hours

    const recency = Math.max(0, 1 - (age / maxAge));
    const frequency = Math.min(1, (item.metadata?.accessCount || 0) / 10);
    const semantic = 0; // Will be updated by search
    const explicit = false;

    const score: RelevanceScore = {
      recency,
      frequency,
      semantic,
      explicit,
      total: 0,
    };

    score.total = this.computeTotalScore(score);
    return score;
  }

  private computeTotalScore(score: RelevanceScore): number {
    if (score.explicit) return 1.0;

    const weights = this.config.relevanceWeights;
    return (
      score.recency * weights.recency +
      score.frequency * weights.frequency +
      score.semantic * weights.semantic +
      (score.explicit ? weights.explicit : 0)
    );
  }

  private determineTier(score: RelevanceScore): Tier {
    if (score.total >= 0.8 || score.explicit) return 'hot';
    if (score.total >= 0.5) return 'warm';
    return 'cold';
  }

  private calculateAverageScore(): number {
    if (this.itemScores.size === 0) return 0;
    
    let total = 0;
    for (const score of this.itemScores.values()) {
      total += score.total;
    }
    
    return total / this.itemScores.size;
  }
}

export default ContextTierManager;
