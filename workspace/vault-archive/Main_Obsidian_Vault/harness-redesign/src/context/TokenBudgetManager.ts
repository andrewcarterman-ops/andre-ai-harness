/**
 * Token Budget Manager
 * Implements 3-tier token allocation system (Hot/Warm/Cold)
 * 
 * @module TokenBudgetManager
 * @version 1.0.0
 */

import { EventEmitter } from 'events';
import { LRUCache } from 'lru-cache';

export type Tier = 'hot' | 'warm' | 'cold';

export interface ContextItem {
  id: string;
  content: string;
  tokenCount: number;
  tier: Tier;
  metadata?: {
    source?: string;
    type?: string;
    created?: Date;
    lastAccessed?: Date;
    accessCount?: number;
  };
}

export interface AllocationResult {
  success: boolean;
  item?: ContextItem;
  evictedItems?: ContextItem[];
  message?: string;
}

export interface EvictionResult {
  evicted: ContextItem[];
  freedTokens: number;
}

export interface BudgetStatus {
  totalLimit: number;
  usedTokens: number;
  availableTokens: number;
  tierStatus: {
    hot: { used: number; max: number };
    warm: { used: number; max: number };
    cold: { used: number; max: number };
  };
  itemsByTier: {
    hot: number;
    warm: number;
    cold: number;
  };
}

export interface TokenBudgetConfig {
  totalLimit: number;
  tiers: {
    hot: { maxTokens: number; evictionPolicy: string };
    warm: { maxTokens: number; evictionPolicy: string };
    cold: { maxTokens: number | null; evictionPolicy: string };
  };
  allocation: {
    systemPrompt: number;
    context: number;
    conversationHistory: number;
    responseBuffer: number;
  };
}

export class TokenBudgetManager extends EventEmitter {
  private config: TokenBudgetConfig;
  private hotCache: LRUCache<string, ContextItem>;
  private warmCache: Map<string, ContextItem>;
  private coldStorage: Map<string, ContextItem>;
  private usedTokens: { hot: number; warm: number; cold: number };

  constructor(config: TokenBudgetConfig) {
    super();
    this.config = config;
    this.usedTokens = { hot: 0, warm: 0, cold: 0 };
    
    // Initialize Hot Tier (LRU Cache)
    this.hotCache = new LRUCache({
      max: config.tiers.hot.maxTokens,
      sizeCalculation: (item) => item.tokenCount,
      dispose: (value, key) => {
        this.usedTokens.hot -= value.tokenCount;
        this.emit('item:evicted', value, 'hot');
      },
      updateAgeOnGet: true,
      updateAgeOnHas: true,
    });

    // Initialize Warm Tier
    this.warmCache = new Map();

    // Initialize Cold Tier
    this.coldStorage = new Map();
  }

  /**
   * Allocate tokens to a context item
   */
  allocate(item: ContextItem, tier: Tier): AllocationResult {
    const tierMax = this.getTierMax(tier);
    const tierUsed = this.usedTokens[tier];
    
    if (item.tokenCount > this.config.totalLimit) {
      return {
        success: false,
        message: `Item too large: ${item.tokenCount} tokens exceeds total limit`,
      };
    }

    // Check if we need to evict items
    const evictedItems: ContextItem[] = [];
    
    if (tierMax !== null && tierUsed + item.tokenCount > tierMax) {
      const tokensNeeded = (tierUsed + item.tokenCount) - tierMax;
      const evictionResult = this.evict(tokensNeeded, tier);
      evictedItems.push(...evictionResult.evicted);
    }

    // Store item in appropriate tier
    item.tier = tier;
    switch (tier) {
      case 'hot':
        this.hotCache.set(item.id, item);
        break;
      case 'warm':
        this.warmCache.set(item.id, item);
        break;
      case 'cold':
        this.coldStorage.set(item.id, item);
        break;
    }
    
    this.usedTokens[tier] += item.tokenCount;
    this.emit('item:allocated', item, tier);

    return {
      success: true,
      item,
      evictedItems: evictedItems.length > 0 ? evictedItems : undefined,
    };
  }

  /**
   * Evict items to free tokens
   */
  evict(tokensNeeded: number, fromTier: Tier): EvictionResult {
    const evicted: ContextItem[] = [];
    let freedTokens = 0;

    switch (fromTier) {
      case 'hot':
        // LRU cache handles eviction automatically
        while (freedTokens < tokensNeeded && this.hotCache.size > 0) {
          const key = this.hotCache.keys().next().value;
          if (key) {
            const item = this.hotCache.get(key);
            if (item) {
              this.hotCache.delete(key);
              evicted.push(item);
              freedTokens += item.tokenCount;
            }
          }
        }
        break;

      case 'warm':
        // Evict least recently used items
        const warmItems = Array.from(this.warmCache.values())
          .sort((a, b) => (a.metadata?.lastAccessed?.getTime() || 0) - 
                         (b.metadata?.lastAccessed?.getTime() || 0));
        
        for (const item of warmItems) {
          if (freedTokens >= tokensNeeded) break;
          this.warmCache.delete(item.id);
          this.usedTokens.warm -= item.tokenCount;
          evicted.push(item);
          freedTokens += item.tokenCount;
        }
        break;

      case 'cold':
        // Move oldest items to archive
        const coldItems = Array.from(this.coldStorage.values())
          .sort((a, b) => (a.metadata?.created?.getTime() || 0) - 
                         (b.metadata?.created?.getTime() || 0));
        
        for (const item of coldItems) {
          if (freedTokens >= tokensNeeded) break;
          this.coldStorage.delete(item.id);
          this.usedTokens.cold -= item.tokenCount;
          evicted.push(item);
          freedTokens += item.tokenCount;
          this.emit('item:archived', item);
        }
        break;
    }

    this.emit('tier:evicted', fromTier, evicted);
    return { evicted, freedTokens };
  }

  /**
   * Promote item to higher tier
   */
  async promote(itemId: string): Promise<void> {
    const item = this.findItem(itemId);
    if (!item) {
      throw new Error(`Item ${itemId} not found`);
    }

    const currentTier = item.tier;
    const newTier = this.getHigherTier(currentTier);
    
    if (newTier === currentTier) {
      return; // Already at highest tier
    }

    // Remove from current tier
    this.removeFromTier(itemId, currentTier);
    
    // Allocate to new tier
    const result = this.allocate(item, newTier);
    
    if (!result.success) {
      // Revert: put back in original tier
      this.allocate(item, currentTier);
      throw new Error(`Failed to promote item: ${result.message}`);
    }

    this.emit('item:promoted', item, currentTier, newTier);
  }

  /**
   * Demote item to lower tier
   */
  async demote(itemId: string): Promise<void> {
    const item = this.findItem(itemId);
    if (!item) {
      throw new Error(`Item ${itemId} not found`);
    }

    const currentTier = item.tier;
    const newTier = this.getLowerTier(currentTier);
    
    if (newTier === currentTier) {
      return; // Already at lowest tier
    }

    // Remove from current tier
    this.removeFromTier(itemId, currentTier);
    
    // Allocate to new tier
    const result = this.allocate(item, newTier);
    
    if (!result.success) {
      // Revert: put back in original tier
      this.allocate(item, currentTier);
      throw new Error(`Failed to demote item: ${result.message}`);
    }

    this.emit('item:demoted', item, currentTier, newTier);
  }

  /**
   * Get current budget status
   */
  getStatus(): BudgetStatus {
    const hotItems = this.hotCache.size;
    const warmItems = this.warmCache.size;
    const coldItems = this.coldStorage.size;

    return {
      totalLimit: this.config.totalLimit,
      usedTokens: this.usedTokens.hot + this.usedTokens.warm + this.usedTokens.cold,
      availableTokens: this.config.totalLimit - 
        (this.usedTokens.hot + this.usedTokens.warm + this.usedTokens.cold),
      tierStatus: {
        hot: { used: this.usedTokens.hot, max: this.config.tiers.hot.maxTokens },
        warm: { used: this.usedTokens.warm, max: this.config.tiers.warm.maxTokens },
        cold: { used: this.usedTokens.cold, max: this.config.tiers.cold.maxTokens || 0 },
      },
      itemsByTier: { hot: hotItems, warm: warmItems, cold: coldItems },
    };
  }

  /**
   * Access an item (updates last accessed time)
   */
  access(itemId: string): ContextItem | undefined {
    // Try hot tier first
    let item = this.hotCache.get(itemId);
    if (item) {
      item.metadata = item.metadata || {};
      item.metadata.lastAccessed = new Date();
      item.metadata.accessCount = (item.metadata.accessCount || 0) + 1;
      return item;
    }

    // Try warm tier
    item = this.warmCache.get(itemId);
    if (item) {
      item.metadata = item.metadata || {};
      item.metadata.lastAccessed = new Date();
      item.metadata.accessCount = (item.metadata.accessCount || 0) + 1;
      
      // Consider promoting to hot tier
      if ((item.metadata.accessCount || 0) > 5) {
        this.promote(itemId).catch(() => {}); // Fire and forget
      }
      
      return item;
    }

    // Try cold tier
    item = this.coldStorage.get(itemId);
    if (item) {
      item.metadata = item.metadata || {};
      item.metadata.lastAccessed = new Date();
      item.metadata.accessCount = (item.metadata.accessCount || 0) + 1;
      
      // Consider promoting to warm tier
      if ((item.metadata.accessCount || 0) > 3) {
        this.promote(itemId).catch(() => {}); // Fire and forget
      }
      
      return item;
    }

    return undefined;
  }

  // Helper methods
  private getTierMax(tier: Tier): number | null {
    switch (tier) {
      case 'hot': return this.config.tiers.hot.maxTokens;
      case 'warm': return this.config.tiers.warm.maxTokens;
      case 'cold': return this.config.tiers.cold.maxTokens;
      default: return null;
    }
  }

  private getHigherTier(tier: Tier): Tier {
    switch (tier) {
      case 'cold': return 'warm';
      case 'warm': return 'hot';
      case 'hot': return 'hot';
      default: return tier;
    }
  }

  private getLowerTier(tier: Tier): Tier {
    switch (tier) {
      case 'hot': return 'warm';
      case 'warm': return 'cold';
      case 'cold': return 'cold';
      default: return tier;
    }
  }

  private findItem(itemId: string): ContextItem | undefined {
    return this.hotCache.get(itemId) || 
           this.warmCache.get(itemId) || 
           this.coldStorage.get(itemId);
  }

  private removeFromTier(itemId: string, tier: Tier): void {
    switch (tier) {
      case 'hot':
        const hotItem = this.hotCache.get(itemId);
        if (hotItem) {
          this.usedTokens.hot -= hotItem.tokenCount;
          this.hotCache.delete(itemId);
        }
        break;
      case 'warm':
        const warmItem = this.warmCache.get(itemId);
        if (warmItem) {
          this.usedTokens.warm -= warmItem.tokenCount;
          this.warmCache.delete(itemId);
        }
        break;
      case 'cold':
        const coldItem = this.coldStorage.get(itemId);
        if (coldItem) {
          this.usedTokens.cold -= coldItem.tokenCount;
          this.coldStorage.delete(itemId);
        }
        break;
    }
  }
}

export default TokenBudgetManager;
