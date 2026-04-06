//! Compaction Engine
//! 
//! Token-based session compaction with summarization

use std::time::Duration;
use async_trait::async_trait;
use chrono::{DateTime, Utc};

/// Compaction engine for session management
pub struct CompactionEngine<S: Summarizer> {
    config: CompactionConfig,
    summarizer: S,
}

/// Compaction configuration
#[derive(Debug, Clone)]
pub struct CompactionConfig {
    /// Maximum tokens before triggering compaction
    pub max_estimated_tokens: usize,
    /// Number of recent messages to preserve
    pub preserve_recent: usize,
}

impl CompactionConfig {
    /// Create default configuration
    pub fn new() -> Self {
        Self {
            max_estimated_tokens: 10_000, // 80% of 128K
            preserve_recent: 4,
        }
    }

    /// Create with custom settings
    pub fn with_settings(max_tokens: usize, preserve: usize) -> Self {
        Self {
            max_estimated_tokens: max_tokens,
            preserve_recent: preserve,
        }
    }
}

impl Default for CompactionConfig {
    fn default() -> Self {
        Self::new()
    }
}

/// Summarizer trait for generating message summaries
#[async_trait]
pub trait Summarizer: Send + Sync {
    /// Summarize a list of messages
    async fn summarize(&self, messages: &[MessageSummary]) -> Result<String, SummarizeError>;
}

/// Message summary for compaction
#[derive(Debug, Clone)]
pub struct MessageSummary {
    pub role: String,
    pub content: String,
}

impl MessageSummary {
    /// Create from role and content
    pub fn new(role: impl Into<String>, content: impl Into<String>) -> Self {
        Self {
            role: role.into(),
            content: content.into(),
        }
    }
}

/// Compaction result
#[derive(Debug, Clone)]
pub enum CompactionResult {
    /// No compaction needed
    NotNeeded,
    /// Nothing to compact
    NothingToCompact,
    /// Compaction successful
    Compacted {
        /// Number of messages removed
        messages_removed: usize,
        /// Generated summary
        summary: String,
    },
}

/// Compaction error
#[derive(Debug, Clone)]
pub enum CompactionError {
    /// Summarizer error
    Summarize(String),
    /// Session error
    Session(String),
    /// Other error
    Other(String),
}

impl std::fmt::Display for CompactionError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Summarize(s) => write!(f, "Summarize error: {}", s),
            Self::Session(s) => write!(f, "Session error: {}", s),
            Self::Other(s) => write!(f, "Error: {}", s),
        }
    }
}

impl std::error::Error for CompactionError {}

/// Summarizer error
#[derive(Debug, Clone)]
pub enum SummarizeError {
    /// LLM API error
    Api(String),
    /// Timeout
    Timeout,
    /// Invalid input
    InvalidInput(String),
}

impl std::fmt::Display for SummarizeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Api(s) => write!(f, "API error: {}", s),
            Self::Timeout => write!(f, "Summarization timeout"),
            Self::InvalidInput(s) => write!(f, "Invalid input: {}", s),
        }
    }
}

impl std::error::Error for SummarizeError {}

/// Compaction record for tracking
#[derive(Debug, Clone)]
pub struct CompactionRecord {
    /// Timestamp of compaction
    pub timestamp: DateTime<Utc>,
    /// Number of messages compacted
    pub messages_compacted: usize,
    /// Length of generated summary
    pub summary_length: usize,
}

impl<S: Summarizer> CompactionEngine<S> {
    /// Create new compaction engine
    pub fn new(config: CompactionConfig, summarizer: S) -> Self {
        Self {
            config,
            summarizer,
        }
    }

    /// Check if compaction is needed for messages
    pub fn needs_compaction(&self, messages: &[MessageSummary]) -> bool {
        let estimated = self.estimate_tokens(messages);
        estimated > self.config.max_estimated_tokens
    }

    /// Compact messages and return summary
    pub async fn compact(
        &self,
        messages: &[MessageSummary],
    ) -> Result<CompactionResult, CompactionError> {
        // 1. Check if compaction needed
        let estimated = self.estimate_tokens(messages);
        if estimated <= self.config.max_estimated_tokens {
            return Ok(CompactionResult::NotNeeded);
        }

        // 2. Partition messages
        let split_point = messages.len().saturating_sub(self.config.preserve_recent);
        let to_summarize = &messages[..split_point];
        let _to_preserve: Vec<MessageSummary> = messages[split_point..].to_vec();

        if to_summarize.is_empty() {
            return Ok(CompactionResult::NothingToCompact);
        }

        // 3. Generate summary
        let summary = self.summarizer.summarize(to_summarize).await
            .map_err(|e| CompactionError::Summarize(e.to_string()))?;

        // 4. Create compaction record
        let compacted_count = to_summarize.len();
        let _record = CompactionRecord {
            timestamp: Utc::now(),
            messages_compacted: compacted_count,
            summary_length: summary.len(),
        };

        Ok(CompactionResult::Compacted {
            messages_removed: compacted_count,
            summary,
        })
    }

    /// Estimate tokens for messages (naive: chars / 4)
    pub fn estimate_tokens(&self, messages: &[MessageSummary]) -> usize {
        messages.iter()
            .map(|m| m.content.len() / 4)
            .sum()
    }

    /// Get config
    pub fn config(&self) -> &CompactionConfig {
        &self.config
    }
}

/// Simple summarizer implementation (for testing)
pub struct SimpleSummarizer;

#[async_trait]
impl Summarizer for SimpleSummarizer {
    async fn summarize(&self, messages: &[MessageSummary]) -> Result<String, SummarizeError> {
        // Simple summary: concatenate first 100 chars of each message
        let summary = messages.iter()
            .take(3)
            .map(|m| format!("{}: {}", m.role, &m.content[..m.content.len().min(100)]))
            .collect::<Vec<_>>()
            .join("; ");
        
        Ok(format!("[Summary of {} messages]: {}", messages.len(), summary))
    }
}

/// LLM-based summarizer
#[allow(dead_code)]
pub struct LlmSummarizer<C> {
    client: C,
    model: String,
    max_summary_length: usize,
    timeout: Duration,
}

impl<C> LlmSummarizer<C> {
    /// Create new LLM summarizer
    pub fn new(client: C, model: impl Into<String>) -> Self {
        Self {
            client,
            model: model.into(),
            max_summary_length: 500,
            timeout: Duration::from_secs(30),
        }
    }

    /// Set max summary length
    pub fn with_max_length(mut self, length: usize) -> Self {
        self.max_summary_length = length;
        self
    }

    /// Set timeout
    pub fn with_timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compaction_config_default() {
        let config = CompactionConfig::new();
        assert_eq!(config.max_estimated_tokens, 10_000);
        assert_eq!(config.preserve_recent, 4);
    }

    #[test]
    fn test_estimate_tokens() {
        let engine = CompactionEngine::new(CompactionConfig::new(), SimpleSummarizer);
        let messages = vec![
            MessageSummary::new("user", "Hello, this is a test message"),
            MessageSummary::new("assistant", "Hi! How can I help you today?"),
        ];
        
        let tokens = engine.estimate_tokens(&messages);
        assert!(tokens > 0);
    }

    #[test]
    fn test_needs_compaction() {
        let engine = CompactionEngine::new(
            CompactionConfig::with_settings(100, 4),
            SimpleSummarizer
        );
        
        // Small message - no compaction needed
        let small = vec![MessageSummary::new("user", "Hi")];
        assert!(!engine.needs_compaction(&small));
        
        // Large message - compaction needed
        let large = vec![MessageSummary::new("user", &"a".repeat(500))];
        assert!(engine.needs_compaction(&large));
    }

    #[tokio::test]
    async fn test_simple_summarizer() {
        let summarizer = SimpleSummarizer;
        let messages = vec![
            MessageSummary::new("user", "Hello"),
            MessageSummary::new("assistant", "Hi there!"),
        ];
        
        let summary = summarizer.summarize(&messages).await.unwrap();
        assert!(summary.contains("user"));
        assert!(summary.contains("assistant"));
    }
}
