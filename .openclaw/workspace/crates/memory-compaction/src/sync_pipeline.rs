//! Sync Pipeline Service
//! 
//! Automatic background sync to Obsidian Second Brain
//! Triggered by importance classification

use std::time::Duration;
use tokio::time::interval;
use chrono::Utc;

use crate::{
    MemoryClassifier, Importance, ClassifiedMemory,
    ObsidianSync, MemoryEntry,
};

/// Background sync service
pub struct SyncPipeline {
    classifier: MemoryClassifier,
    obsidian: ObsidianSync,
    config: SyncConfig,
}

/// Sync configuration
#[derive(Debug, Clone)]
pub struct SyncConfig {
    /// How often to check for new content (seconds)
    pub check_interval_secs: u64,
    /// Minimum importance level to sync to Obsidian
    pub min_importance: Importance,
    /// Enable automatic sync
    pub enabled: bool,
}

impl SyncConfig {
    /// Default configuration
    pub fn new() -> Self {
        Self {
            check_interval_secs: 300, // 5 minutes
            min_importance: Importance::Important,
            enabled: true,
        }
    }

    /// Sync everything (including Reference)
    pub fn verbose() -> Self {
        Self {
            check_interval_secs: 60,
            min_importance: Importance::Reference,
            enabled: true,
        }
    }

    /// Sync only Critical
    pub fn critical_only() -> Self {
        Self {
            check_interval_secs: 600, // 10 minutes
            min_importance: Importance::Critical,
            enabled: true,
        }
    }
}

impl Default for SyncConfig {
    fn default() -> Self {
        Self::new()
    }
}

/// Sync result
#[derive(Debug, Clone)]
pub struct SyncResult {
    pub timestamp: chrono::DateTime<Utc>,
    pub entries_synced: usize,
    pub entries_critical: usize,
    pub entries_important: usize,
}

/// Message to be classified and potentially synced
#[derive(Debug, Clone)]
pub struct SyncMessage {
    pub id: String,
    pub role: String,
    pub content: String,
    pub timestamp: chrono::DateTime<Utc>,
}

impl SyncMessage {
    /// Create new sync message
    pub fn new(id: impl Into<String>, role: impl Into<String>, content: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            role: role.into(),
            content: content.into(),
            timestamp: Utc::now(),
        }
    }
}

impl SyncPipeline {
    /// Create new sync pipeline
    pub fn new(obsidian_vault_path: impl AsRef<std::path::Path>) -> Self {
        let config = SyncConfig::new();
        let obsidian = ObsidianSync::new(obsidian_vault_path);
        
        Self {
            classifier: MemoryClassifier::new(),
            obsidian,
            config,
        }
    }

    /// Create with custom config
    pub fn with_config(mut self, config: SyncConfig) -> Self {
        self.config = config;
        self
    }

    /// Initialize directories
    pub async fn initialize(&self) -> Result<(), SyncError> {
        self.obsidian.initialize().await
            .map_err(|e| SyncError::Obsidian(e.to_string()))?;
        Ok(())
    }

    /// Process single message (immediate sync if important)
    pub async fn process_message(&self, msg: &SyncMessage) -> Result<bool, SyncError> {
        if !self.config.enabled {
            return Ok(false);
        }

        // Classify
        let importance = self.classifier.classify(&msg.role, &msg.content);
        
        // Check if should sync
        if importance.priority() < self.config.min_importance.priority() {
            return Ok(false);
        }

        // Create entry
        let entry = self.create_entry(msg, importance);

        // Sync to Obsidian
        self.obsidian.sync_to_inbox(&entry).await
            .map_err(|e| SyncError::Obsidian(e.to_string()))?;

        Ok(true)
    }

    /// Process multiple messages
    pub async fn process_messages(&self, messages: &[SyncMessage]) -> Result<SyncResult, SyncError> {
        if !self.config.enabled {
            return Ok(SyncResult {
                timestamp: Utc::now(),
                entries_synced: 0,
                entries_critical: 0,
                entries_important: 0,
            });
        }

        let mut classified = ClassifiedMemory::new();

        // Classify all messages
        for msg in messages {
            let importance = self.classifier.classify(&msg.role, &msg.content);
            let entry = self.create_entry(msg, importance);
            classified.add(entry, importance);
        }

        // Sync Important and Critical
        let to_sync: Vec<_> = classified.important_items()
            .into_iter()
            .cloned()
            .collect();

        let mut synced = 0;
        for entry in &to_sync {
            match self.obsidian.sync_to_inbox(entry).await {
                Ok(_) => synced += 1,
                Err(e) => eprintln!("Sync error: {}", e),
            }
        }

        Ok(SyncResult {
            timestamp: Utc::now(),
            entries_synced: synced,
            entries_critical: classified.critical.len(),
            entries_important: classified.important.len(),
        })
    }

    /// Start background sync loop
    pub async fn run_background(&self, mut message_rx: tokio::sync::mpsc::Receiver<SyncMessage>) {
        if !self.config.enabled {
            println!("[SyncPipeline] Disabled, not starting background task");
            return;
        }

        println!("[SyncPipeline] Starting background sync (interval: {}s)", 
            self.config.check_interval_secs);

        let mut interval = interval(Duration::from_secs(self.config.check_interval_secs));
        let mut buffer: Vec<SyncMessage> = Vec::new();

        loop {
            tokio::select! {
                // Periodic check
                _ = interval.tick() => {
                    if !buffer.is_empty() {
                        match self.process_messages(&buffer).await {
                            Ok(result) => {
                                println!("[SyncPipeline] Synced {} entries ({} critical, {} important)",
                                    result.entries_synced,
                                    result.entries_critical,
                                    result.entries_important);
                                buffer.clear();
                            }
                            Err(e) => eprintln!("[SyncPipeline] Error: {}", e),
                        }
                    }
                }
                
                // New message received
                Some(msg) = message_rx.recv() => {
                    // Immediate sync for Critical
                    let importance = self.classifier.classify(&msg.role, &msg.content);
                    if importance == Importance::Critical {
                        match self.process_message(&msg).await {
                            Ok(true) => println!("[SyncPipeline] Critical message synced immediately"),
                            Ok(false) => {}
                            Err(e) => eprintln!("[SyncPipeline] Immediate sync error: {}", e),
                        }
                    } else {
                        // Buffer for batch processing
                        buffer.push(msg);
                    }
                }
            }
        }
    }

    /// Manual trigger: Force sync all buffered content
    pub async fn force_sync(&self, messages: &[SyncMessage]) -> Result<SyncResult, SyncError> {
        self.process_messages(messages).await
    }

    fn create_entry(&self, msg: &SyncMessage, importance: Importance) -> MemoryEntry {
        let title = format!("{} - {}", msg.role, &msg.content[..msg.content.len().min(50)]);
        
        MemoryEntry::new(
            &msg.id,
            &title,
            &msg.content
        )
        .with_importance(importance.as_str())
        .with_source(&msg.role)
        .with_tags(vec![
            "auto-sync".to_string(),
            format!("importance-{}", importance.as_str()),
        ])
    }

    /// Check if sync is enabled
    pub fn is_enabled(&self) -> bool {
        self.config.enabled
    }

    /// Enable/disable sync
    pub fn set_enabled(&mut self, enabled: bool) {
        self.config.enabled = enabled;
    }
}

/// Sync error
#[derive(Debug, Clone)]
pub enum SyncError {
    Obsidian(String),
    Classifier(String),
    ChannelClosed,
}

impl std::fmt::Display for SyncError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Obsidian(s) => write!(f, "Obsidian error: {}", s),
            Self::Classifier(s) => write!(f, "Classifier error: {}", s),
            Self::ChannelClosed => write!(f, "Channel closed"),
        }
    }
}

impl std::error::Error for SyncError {}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[tokio::test]
    async fn test_sync_pipeline_disabled() {
        let temp_dir = TempDir::new().unwrap();
        let pipeline = SyncPipeline::new(temp_dir.path())
            .with_config(SyncConfig {
                enabled: false,
                ..SyncConfig::new()
            });

        let msg = SyncMessage::new("1", "user", "Hello");
        let result = pipeline.process_message(&msg).await.unwrap();
        
        assert!(!result);
    }

    #[tokio::test]
    async fn test_sync_pipeline_critical() {
        let temp_dir = TempDir::new().unwrap();
        let pipeline = SyncPipeline::new(temp_dir.path());
        pipeline.initialize().await.unwrap();

        let msg = SyncMessage::new("1", "assistant", "Error: database connection failed");
        let result = pipeline.process_message(&msg).await.unwrap();
        
        assert!(result); // Critical messages are synced
    }

    #[tokio::test]
    async fn test_sync_pipeline_trivial() {
        let temp_dir = TempDir::new().unwrap();
        let pipeline = SyncPipeline::new(temp_dir.path());

        let msg = SyncMessage::new("1", "user", "ok");
        let result = pipeline.process_message(&msg).await.unwrap();
        
        assert!(!result); // Trivial messages are not synced
    }
}
