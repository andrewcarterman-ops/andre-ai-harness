//! Token Budget Management
//! 
//! Implements 3-tier context system (Hot/Warm/Cold) for optimal token usage.

use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use tracing::{debug, info, warn};

/// Error types for token budget operations
#[derive(Error, Debug)]
pub enum TokenBudgetError {
    #[error("Item exceeds total token limit: {0} > {1}")]
    ItemTooLarge(usize, usize),
    
    #[error("Tier {0} would exceed limit: {1} > {2}")]
    TierLimitExceeded(String, usize, usize),
    
    #[error("Item not found: {0}")]
    ItemNotFound(String),
    
    #[error("Invalid tier: {0}")]
    InvalidTier(String),
    
    #[error("Eviction failed: {0}")]
    EvictionFailed(String),
}

/// Tier types for context storage
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Tier {
    Hot,
    Warm,
    Cold,
}

impl Tier {
    pub fn higher(&self) -> Option<Tier> {
        match self {
            Tier::Cold => Some(Tier::Warm),
            Tier::Warm => Some(Tier::Hot),
            Tier::Hot => None,
        }
    }
    
    pub fn lower(&self) -> Option<Tier> {
        match self {
            Tier::Hot => Some(Tier::Warm),
            Tier::Warm => Some(Tier::Cold),
            Tier::Cold => None,
        }
    }
}

impl std::fmt::Display for Tier {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Tier::Hot => write!(f, "hot"),
            Tier::Warm => write!(f, "warm"),
            Tier::Cold => write!(f, "cold"),
        }
    }
}

/// Metadata for context items
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextMetadata {
    pub source: String,
    #[serde(rename = "type")]
    pub item_type: String,
    pub created: DateTime<Utc>,
    pub last_accessed: Option<DateTime<Utc>>,
    pub access_count: usize,
    pub pinned: bool,
    pub tags: Vec<String>,
}

impl Default for ContextMetadata {
    fn default() -> Self {
        Self {
            source: "unknown".to_string(),
            item_type: "context".to_string(),
            created: Utc::now(),
            last_accessed: None,
            access_count: 0,
            pinned: false,
            tags: Vec::new(),
        }
    }
}

/// A single context item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextItem {
    pub id: String,
    pub content: String,
    pub token_count: usize,
    pub tier: Tier,
    pub metadata: ContextMetadata,
}

impl ContextItem {
    pub fn new(id: impl Into<String>, content: impl Into<String>, token_count: usize) -> Self {
        Self {
            id: id.into(),
            content: content.into(),
            token_count,
            tier: Tier::Cold,
            metadata: ContextMetadata::default(),
        }
    }
    
    pub fn record_access(&mut self) {
        self.metadata.last_accessed = Some(Utc::now());
        self.metadata.access_count += 1;
    }
}

/// Result of an allocation operation
#[derive(Debug, Clone)]
pub struct AllocationResult {
    pub success: bool,
    pub item: Option<ContextItem>,
    pub evicted_items: Vec<ContextItem>,
    pub message: Option<String>,
}

impl AllocationResult {
    pub fn success(item: ContextItem) -> Self {
        Self {
            success: true,
            item: Some(item),
            evicted_items: Vec::new(),
            message: None,
        }
    }
    
    pub fn success_with_eviction(item: ContextItem, evicted: Vec<ContextItem>) -> Self {
        let len = evicted.len();
        Self {
            success: true,
            item: Some(item),
            evicted_items: evicted,
            message: Some(format!("Evicted {} items", len)),
        }
    }
    
    pub fn failure(message: impl Into<String>) -> Self {
        Self {
            success: false,
            item: None,
            evicted_items: Vec::new(),
            message: Some(message.into()),
        }
    }
}

/// Result of an eviction operation
#[derive(Debug, Clone)]
pub struct EvictionResult {
    pub evicted: Vec<ContextItem>,
    pub freed_tokens: usize,
}

/// Configuration for token budget
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenBudgetConfig {
    pub total_limit: usize,
    pub tiers: TierConfig,
    pub allocation: AllocationConfig,
}

impl Default for TokenBudgetConfig {
    fn default() -> Self {
        Self {
            total_limit: 12000,
            tiers: TierConfig::default(),
            allocation: AllocationConfig::default(),
        }
    }
}

/// Configuration for each tier
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TierConfig {
    pub hot: TierSettings,
    pub warm: TierSettings,
    pub cold: TierSettings,
}

impl Default for TierConfig {
    fn default() -> Self {
        Self {
            hot: TierSettings {
                max_tokens: Some(2000),
                eviction_policy: EvictionPolicy::Lru,
            },
            warm: TierSettings {
                max_tokens: Some(10000),
                eviction_policy: EvictionPolicy::RelevanceScore,
            },
            cold: TierSettings {
                max_tokens: None,
                eviction_policy: EvictionPolicy::Archive,
            },
        }
    }
}

/// Settings for a single tier
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TierSettings {
    pub max_tokens: Option<usize>,
    pub eviction_policy: EvictionPolicy,
}

/// Eviction policies
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EvictionPolicy {
    Lru,
    RelevanceScore,
    Archive,
}

/// Token allocation configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AllocationConfig {
    pub system_prompt: usize,
    pub context: usize,
    pub conversation_history: usize,
    pub response_buffer: usize,
}

impl Default for AllocationConfig {
    fn default() -> Self {
        Self {
            system_prompt: 1000,
            context: 8000,
            conversation_history: 2000,
            response_buffer: 1000,
        }
    }
}

/// Status of the token budget
#[derive(Debug, Clone, Serialize)]
pub struct BudgetStatus {
    pub total_limit: usize,
    pub used_tokens: usize,
    pub available_tokens: usize,
    pub tier_status: HashMap<Tier, TierStatus>,
    pub items_by_tier: HashMap<Tier, usize>,
}

/// Status of a single tier
#[derive(Debug, Clone, Serialize)]
pub struct TierStatus {
    pub used: usize,
    pub max: Option<usize>,
    pub utilization: f64,
}

/// Main Token Budget Manager
#[derive(Debug)]
pub struct TokenBudgetManager {
    config: TokenBudgetConfig,
    hot_tier: Arc<RwLock<HashMap<String, ContextItem>>>,
    warm_tier: Arc<RwLock<HashMap<String, ContextItem>>>,
    cold_tier: Arc<RwLock<HashMap<String, ContextItem>>>,
    used_tokens: Arc<RwLock<HashMap<Tier, usize>>>,
}

impl TokenBudgetManager {
    pub fn new(config: TokenBudgetConfig) -> Self {
        let mut used_tokens = HashMap::new();
        used_tokens.insert(Tier::Hot, 0);
        used_tokens.insert(Tier::Warm, 0);
        used_tokens.insert(Tier::Cold, 0);
        
        Self {
            config,
            hot_tier: Arc::new(RwLock::new(HashMap::new())),
            warm_tier: Arc::new(RwLock::new(HashMap::new())),
            cold_tier: Arc::new(RwLock::new(HashMap::new())),
            used_tokens: Arc::new(RwLock::new(used_tokens)),
        }
    }
    
    pub fn default() -> Self {
        Self::new(TokenBudgetConfig::default())
    }
    
    /// Allocate an item to a specific tier
    pub async fn allocate(&self, item: ContextItem, tier: Tier) -> AllocationResult {
        if item.token_count > self.config.total_limit {
            return AllocationResult::failure(
                format!("Item too large: {} tokens exceeds total limit {}", 
                    item.token_count, self.config.total_limit)
            );
        }
        
        let tier_max = match tier {
            Tier::Hot => self.config.tiers.hot.max_tokens,
            Tier::Warm => self.config.tiers.warm.max_tokens,
            Tier::Cold => self.config.tiers.cold.max_tokens,
        };
        
        let used = *self.used_tokens.read().await.get(&tier).unwrap_or(&0);
        
        let mut evicted = Vec::new();
        if let Some(max) = tier_max {
            if used + item.token_count > max {
                let tokens_needed = (used + item.token_count) - max;
                match self.evict(tokens_needed, tier).await {
                    Ok(result) => {
                        evicted = result.evicted;
                    }
                    Err(e) => {
                        return AllocationResult::failure(format!("Eviction failed: {}", e));
                    }
                }
            }
        }
        
        let mut item = item;
        item.tier = tier;
        
        match tier {
            Tier::Hot => {
                self.hot_tier.write().await.insert(item.id.clone(), item.clone());
            }
            Tier::Warm => {
                self.warm_tier.write().await.insert(item.id.clone(), item.clone());
            }
            Tier::Cold => {
                self.cold_tier.write().await.insert(item.id.clone(), item.clone());
            }
        }
        
        *self.used_tokens.write().await.entry(tier).or_insert(0) += item.token_count;
        
        info!("Allocated {} tokens to {:?} tier (item: {})", item.token_count, tier, item.id);
        
        if evicted.is_empty() {
            AllocationResult::success(item)
        } else {
            AllocationResult::success_with_eviction(item, evicted)
        }
    }
    
    /// Evict items to free tokens
    pub async fn evict(&self, tokens_needed: usize, tier: Tier) -> Result<EvictionResult, TokenBudgetError> {
        let mut evicted = Vec::new();
        let mut freed_tokens = 0;
        
        match tier {
            Tier::Hot => {
                let items_to_evict: Vec<ContextItem> = {
                    let hot = self.hot_tier.read().await;
                    let mut items: Vec<_> = hot.values().cloned().collect();
                    
                    items.sort_by(|a, b| {
                        if a.metadata.pinned && !b.metadata.pinned {
                            std::cmp::Ordering::Greater
                        } else if !a.metadata.pinned && b.metadata.pinned {
                            std::cmp::Ordering::Less
                        } else {
                            a.metadata.last_accessed
                                .unwrap_or(a.metadata.created)
                                .cmp(&b.metadata.last_accessed.unwrap_or(b.metadata.created))
                        }
                    });
                    
                    let mut to_evict = Vec::new();
                    let mut freed = 0;
                    for item in items {
                        if freed >= tokens_needed || item.metadata.pinned {
                            break;
                        }
                        freed += item.token_count;
                        to_evict.push(item);
                    }
                    to_evict
                };
                
                let mut hot = self.hot_tier.write().await;
                let mut used = self.used_tokens.write().await;
                
                for item in items_to_evict {
                    if let Some(removed) = hot.remove(&item.id) {
                        freed_tokens += removed.token_count;
                        *used.get_mut(&Tier::Hot).unwrap() -= removed.token_count;
                        evicted.push(removed);
                    }
                }
            }
            
            Tier::Warm => {
                let items_to_evict: Vec<ContextItem> = {
                    let warm = self.warm_tier.read().await;
                    let mut items: Vec<_> = warm.values().cloned().collect();
                    
                    items.sort_by(|a, b| {
                        let score_a = (a.metadata.access_count as f64) * 0.5;
                        let score_b = (b.metadata.access_count as f64) * 0.5;
                        score_a.partial_cmp(&score_b).unwrap_or(std::cmp::Ordering::Equal)
                    });
                    
                    let mut to_evict = Vec::new();
                    let mut freed = 0;
                    for item in items {
                        if freed >= tokens_needed || item.metadata.pinned {
                            break;
                        }
                        freed += item.token_count;
                        to_evict.push(item);
                    }
                    to_evict
                };
                
                let mut warm = self.warm_tier.write().await;
                let mut used = self.used_tokens.write().await;
                
                for item in items_to_evict {
                    if let Some(removed) = warm.remove(&item.id) {
                        freed_tokens += removed.token_count;
                        *used.get_mut(&Tier::Warm).unwrap() -= removed.token_count;
                        evicted.push(removed);
                    }
                }
            }
            
            Tier::Cold => {
                let items_to_evict: Vec<ContextItem> = {
                    let cold = self.cold_tier.read().await;
                    let mut items: Vec<_> = cold.values().cloned().collect();
                    
                    items.sort_by(|a, b| a.metadata.created.cmp(&b.metadata.created));
                    
                    let mut to_evict = Vec::new();
                    let mut freed = 0;
                    for item in items {
                        if freed >= tokens_needed || item.metadata.pinned {
                            break;
                        }
                        freed += item.token_count;
                        to_evict.push(item);
                    }
                    to_evict
                };
                
                let mut cold = self.cold_tier.write().await;
                let mut used = self.used_tokens.write().await;
                
                for item in items_to_evict {
                    if let Some(removed) = cold.remove(&item.id) {
                        freed_tokens += removed.token_count;
                        *used.get_mut(&Tier::Cold).unwrap() -= removed.token_count;
                        evicted.push(removed);
                    }
                }
            }
        }
        
        warn!("Evicted {} items ({} tokens) from {:?} tier", evicted.len(), freed_tokens, tier);
        
        Ok(EvictionResult { evicted, freed_tokens })
    }
    
    /// Access an item (updates statistics)
    pub async fn access(&self, item_id: &str) -> Option<ContextItem> {
        // Try hot tier
        {
            let mut hot = self.hot_tier.write().await;
            if let Some(mut item) = hot.get(item_id).cloned() {
                item.record_access();
                hot.insert(item_id.to_string(), item.clone());
                return Some(item);
            }
        }
        
        // Try warm tier
        {
            let mut warm = self.warm_tier.write().await;
            if let Some(mut item) = warm.get(item_id).cloned() {
                item.record_access();
                warm.insert(item_id.to_string(), item.clone());
                return Some(item);
            }
        }
        
        // Try cold tier
        {
            let mut cold = self.cold_tier.write().await;
            if let Some(mut item) = cold.get(item_id).cloned() {
                item.record_access();
                cold.insert(item_id.to_string(), item.clone());
                return Some(item);
            }
        }
        
        None
    }
    
    /// Get current budget status
    pub async fn get_status(&self) -> BudgetStatus {
        let used = self.used_tokens.read().await;
        let hot = self.hot_tier.read().await;
        let warm = self.warm_tier.read().await;
        let cold = self.cold_tier.read().await;
        
        let mut tier_status = HashMap::new();
        
        let hot_used = *used.get(&Tier::Hot).unwrap_or(&0);
        let hot_max = self.config.tiers.hot.max_tokens;
        tier_status.insert(Tier::Hot, TierStatus {
            used: hot_used,
            max: hot_max,
            utilization: hot_max.map(|m| hot_used as f64 / m as f64).unwrap_or(0.0),
        });
        
        let warm_used = *used.get(&Tier::Warm).unwrap_or(&0);
        let warm_max = self.config.tiers.warm.max_tokens;
        tier_status.insert(Tier::Warm, TierStatus {
            used: warm_used,
            max: warm_max,
            utilization: warm_max.map(|m| warm_used as f64 / m as f64).unwrap_or(0.0),
        });
        
        let cold_used = *used.get(&Tier::Cold).unwrap_or(&0);
        let cold_max = self.config.tiers.cold.max_tokens;
        tier_status.insert(Tier::Cold, TierStatus {
            used: cold_used,
            max: cold_max,
            utilization: cold_max.map(|m| cold_used as f64 / m as f64).unwrap_or(0.0),
        });
        
        let mut items_by_tier = HashMap::new();
        items_by_tier.insert(Tier::Hot, hot.len());
        items_by_tier.insert(Tier::Warm, warm.len());
        items_by_tier.insert(Tier::Cold, cold.len());
        
        let total_used = hot_used + warm_used + cold_used;
        
        BudgetStatus {
            total_limit: self.config.total_limit,
            used_tokens: total_used,
            available_tokens: self.config.total_limit.saturating_sub(total_used),
            tier_status,
            items_by_tier,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_allocate_to_hot_tier() {
        let manager = TokenBudgetManager::default();
        
        let item = ContextItem::new("test-1", "Test content", 500);
        let result = manager.allocate(item, Tier::Hot).await;
        
        assert!(result.success);
        assert!(result.evicted_items.is_empty());
        
        let status = manager.get_status().await;
        assert_eq!(status.items_by_tier.get(&Tier::Hot), Some(&1));
        assert_eq!(status.used_tokens, 500);
    }

    #[tokio::test]
    async fn test_eviction_when_tier_full() {
        let mut config = TokenBudgetConfig::default();
        config.tiers.hot.max_tokens = Some(1000);
        
        let manager = TokenBudgetManager::new(config);
        
        let item1 = ContextItem::new("test-1", "Content 1", 600);
        manager.allocate(item1, Tier::Hot).await;
        
        let item2 = ContextItem::new("test-2", "Content 2", 500);
        let result = manager.allocate(item2, Tier::Hot).await;
        
        assert!(result.success);
        assert!(!result.evicted_items.is_empty());
        
        let status = manager.get_status().await;
        assert!(status.used_tokens <= 1000);
    }

    #[tokio::test]
    async fn test_access_item() {
        let manager = TokenBudgetManager::default();
        
        let item = ContextItem::new("test-1", "Test content", 500);
        manager.allocate(item, Tier::Hot).await;
        
        let accessed = manager.access("test-1").await;
        assert!(accessed.is_some());
        
        let accessed = accessed.unwrap();
        assert_eq!(accessed.metadata.access_count, 1);
        assert!(accessed.metadata.last_accessed.is_some());
    }

    #[tokio::test]
    async fn test_item_too_large() {
        let config = TokenBudgetConfig::default();
        let manager = TokenBudgetManager::new(config);
        
        let item = ContextItem::new("test-1", "Large content", 20000);
        let result = manager.allocate(item, Tier::Hot).await;
        
        assert!(!result.success);
        assert!(result.message.is_some());
    }
}
