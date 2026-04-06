//! Context Tier Manager
//! 
//! Manages automatic promotion/demotion between tiers based on access patterns.

use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use serde::{Deserialize, Serialize};
use tracing::{debug, info};

use crate::context::token_budget::{ContextItem, TokenBudgetManager};
use crate::context::Tier;

/// Configuration for context tier management
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TierManagerConfig {
    /// Threshold for auto-promotion (access count)
    pub promote_threshold: usize,
    /// Threshold for auto-demotion (days without access)
    pub demote_threshold_days: i64,
    /// Relevance score weights
    pub relevance_weights: RelevanceWeights,
}

impl Default for TierManagerConfig {
    fn default() -> Self {
        Self {
            promote_threshold: 5,
            demote_threshold_days: 7,
            relevance_weights: RelevanceWeights::default(),
        }
    }
}

/// Weights for relevance score calculation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RelevanceWeights {
    pub recency: f64,
    pub frequency: f64,
    pub semantic: f64,
    pub explicit: f64,
}

impl Default for RelevanceWeights {
    fn default() -> Self {
        Self {
            recency: 0.3,
            frequency: 0.3,
            semantic: 0.3,
            explicit: 1.0,
        }
    }
}

/// Context Tier Manager
/// 
/// Handles automatic tier management based on access patterns and relevance.
pub struct ContextTierManager {
    config: TierManagerConfig,
    token_budget: Arc<TokenBudgetManager>,
    /// Access statistics for items
    access_stats: Arc<RwLock<HashMap<String, AccessStats>>>,
}

/// Access statistics for an item
#[derive(Debug, Clone)]
struct AccessStats {
    first_access: chrono::DateTime<chrono::Utc>,
    last_access: chrono::DateTime<chrono::Utc>,
    access_count: usize,
}

impl ContextTierManager {
    /// Create a new tier manager
    pub fn new(config: TierManagerConfig, token_budget: Arc<TokenBudgetManager>) -> Self {
        Self {
            config,
            token_budget,
            access_stats: Arc::new(RwLock::new(HashMap::new())),
        }
    }
    
    /// Record access to an item
    pub async fn record_access(&self, item_id: &str) {
        let mut stats = self.access_stats.write().await;
        let now = chrono::Utc::now();
        
        stats.entry(item_id.to_string())
            .and_modify(|s| {
                s.last_access = now;
                s.access_count += 1;
            })
            .or_insert(AccessStats {
                first_access: now,
                last_access: now,
                access_count: 1,
            });
        
        debug!("Recorded access to item {}", item_id);
    }
    
    /// Check if item should be promoted
    pub async fn should_promote(&self, item_id: &str) -> bool {
        let stats = self.access_stats.read().await;
        
        if let Some(stat) = stats.get(item_id) {
            stat.access_count >= self.config.promote_threshold
        } else {
            false
        }
    }
    
    /// Check if item should be demoted
    pub async fn should_demote(&self, item_id: &str) -> bool {
        let stats = self.access_stats.read().await;
        
        if let Some(stat) = stats.get(item_id) {
            let days_since_access = (chrono::Utc::now() - stat.last_access).num_days();
            days_since_access >= self.config.demote_threshold_days
        } else {
            false
        }
    }
    
    /// Calculate relevance score for an item
    pub fn calculate_relevance(&self, item: &ContextItem) -> f64 {
        if item.metadata.pinned {
            return f64::MAX;
        }
        
        let weights = &self.config.relevance_weights;
        let now = chrono::Utc::now();
        
        // Recency score (exponential decay)
        let recency = item.metadata.last_accessed
            .map(|last| {
                let hours = (now - last).num_hours() as f64;
                (-hours / 24.0).exp()
            })
            .unwrap_or(0.0);
        
        // Frequency score
        let frequency = (item.metadata.access_count as f64 / 100.0).min(1.0);
        
        // Combined score
        recency * weights.recency + frequency * weights.frequency
    }
    
    /// Run maintenance (promote/demote items based on access patterns)
    pub async fn run_maintenance(&self) -> MaintenanceResult {
        info!("Running tier maintenance");
        
        let promoted = 0;
        let demoted = 0;
        
        // Get status to find items in each tier
        let _status = self.token_budget.get_status().await;
        
        // Check warm tier items for promotion
        // (In real implementation, would iterate through warm tier items)
        // For now, this is a placeholder
        
        MaintenanceResult {
            promoted,
            demoted,
        }
    }
}

/// Result of maintenance operation
#[derive(Debug, Clone)]
pub struct MaintenanceResult {
    pub promoted: usize,
    pub demoted: usize,
}
