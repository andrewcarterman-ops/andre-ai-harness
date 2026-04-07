//! Base Agent trait and types

use async_trait::async_trait;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

/// Configuration for an agent
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentConfig {
    pub name: String,
    pub model: String,
    pub timeout_seconds: u64,
    pub max_tokens: usize,
}

impl Default for AgentConfig {
    fn default() -> Self {
        Self {
            name: "unnamed-agent".to_string(),
            model: "kimi-coding/k2p5".to_string(),
            timeout_seconds: 900,
            max_tokens: 8192,
        }
    }
}

/// Output from an agent execution
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentOutput {
    pub agent_name: String,
    pub timestamp: DateTime<Utc>,
    pub success: bool,
    pub content: String,
    pub tokens_used: usize,
    pub metadata: serde_json::Value,
}

impl AgentOutput {
    pub fn new(agent_name: &str, content: impl Into<String>) -> Self {
        Self {
            agent_name: agent_name.to_string(),
            timestamp: Utc::now(),
            success: true,
            content: content.into(),
            tokens_used: 0,
            metadata: serde_json::Value::Null,
        }
    }
    
    pub fn with_tokens(mut self, tokens: usize) -> Self {
        self.tokens_used = tokens;
        self
    }
    
    pub fn with_metadata(mut self, metadata: serde_json::Value) -> Self {
        self.metadata = metadata;
        self
    }
}

/// Base trait that all agents must implement
#[async_trait]
pub trait Agent: Send + Sync {
    /// Returns the agent's name
    fn name(&self) -> &str;
    
    /// Returns the agent's configuration
    fn config(&self) -> &AgentConfig;
    
    /// Executes the agent with the given task
    async fn execute(&self, task: &str, context: &str) -> Result<AgentOutput>;
}
