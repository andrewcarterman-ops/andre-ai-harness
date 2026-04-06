//! Context management module
//! 
//! Provides 3-tier token budget management and context tier optimization.

pub mod token_budget;
pub mod tier_manager;

pub use token_budget::{
    TokenBudgetManager, 
    TokenBudgetConfig,
    ContextItem,
    ContextMetadata,
    Tier,
    AllocationResult,
    BudgetStatus,
    TokenBudgetError,
};

pub use tier_manager::{
    ContextTierManager,
    TierManagerConfig,
};
