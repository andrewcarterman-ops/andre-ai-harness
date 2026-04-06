//! Obsidian Bridge
//! 
//! Bidirectional sync with Obsidian Second Brain vault.
//! Syncs sessions, insights, errors, and skills between OpenClaw and Obsidian.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use tokio::fs;
use tracing::{debug, info, warn};

use crate::context::ContextItem;
use crate::context::Tier;
use crate::context::ContextMetadata;

/// Error types for Obsidian Bridge
#[derive(Error, Debug)]
pub enum ObsidianBridgeError {
    #[error("Vault not found: {0}")]
    VaultNotFound(String),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("Serialization error: {0}")]
    Serialization(String),
    
    #[error("Sync failed: {0}")]
    SyncFailed(String),
    
    #[error("Conflict resolution failed: {0}")]
    ConflictResolution(String),
}

/// Configuration for Obsidian Bridge
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ObsidianConfig {
    /// Path to Obsidian vault
    pub vault_path: PathBuf,
    /// Sync settings
    pub sync: SyncSettings,
    /// Directory mapping
    pub mapping: DirectoryMapping,
    /// Template settings
    pub templates: TemplateSettings,
}

impl Default for ObsidianConfig {
    fn default() -> Self {
        Self {
            vault_path: PathBuf::from("~/Documents/Andrew Openclaw/Obsidian"),
            sync: SyncSettings::default(),
            mapping: DirectoryMapping::default(),
            templates: TemplateSettings::default(),
        }
    }
}

/// Sync settings
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncSettings {
    /// Sync mode
    pub mode: SyncMode,
    /// Sync interval in seconds
    pub interval: u64,
    /// Sync on file change
    pub on_change: bool,
}

impl Default for SyncSettings {
    fn default() -> Self {
        Self {
            mode: SyncMode::Bidirectional,
            interval: 300, // 5 minutes
            on_change: true,
        }
    }
}

/// Sync mode
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum SyncMode {
    /// Bidirectional sync
    Bidirectional,
    /// Only sync to Obsidian
    ToObsidian,
    /// Only sync from Obsidian
    FromObsidian,
}

/// Directory mapping for different content types
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DirectoryMapping {
    /// Sessions directory
    pub sessions: String,
    /// Insights directory
    pub insights: String,
    /// Errors directory
    pub errors: String,
    /// Skills directory
    pub skills: String,
}

impl Default for DirectoryMapping {
    fn default() -> Self {
        Self {
            sessions: "AI/Sessions".to_string(),
            insights: "AI/Insights".to_string(),
            errors: "AI/Errors".to_string(),
            skills: "AI/Skills".to_string(),
        }
    }
}

/// Template settings
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemplateSettings {
    /// Session template
    pub session: String,
    /// Insight template
    pub insight: String,
    /// Error template
    pub error: String,
}

impl Default for TemplateSettings {
    fn default() -> Self {
        Self {
            session: "templates/session.md".to_string(),
            insight: "templates/insight.md".to_string(),
            error: "templates/error.md".to_string(),
        }
    }
}

/// Sync change record
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncChange {
    /// Type of change
    pub change_type: ChangeType,
    /// Source of change
    pub source: ChangeSource,
    /// File path
    pub file_path: PathBuf,
    /// Timestamp
    pub timestamp: DateTime<Utc>,
}

/// Type of change
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ChangeType {
    Create,
    Update,
    Delete,
}

/// Source of change
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ChangeSource {
    Obsidian,
    Harness,
}

/// Conflict resolution strategy
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ConflictStrategy {
    /// Newer timestamp wins
    TimestampWins,
    /// Specific source wins
    SourceWins(ChangeSource),
    /// Attempt to merge
    Merge,
    /// Flag for manual resolution
    Manual,
}

impl Default for ConflictStrategy {
    fn default() -> Self {
        ConflictStrategy::TimestampWins
    }
}

/// Conflict record
#[derive(Debug, Clone)]
pub struct Conflict {
    /// File path
    pub file: PathBuf,
    /// Resolution strategy used
    pub strategy: ConflictStrategy,
    /// Resolution description
    pub resolution: String,
}

/// Sync result
#[derive(Debug, Clone)]
pub struct SyncResult {
    /// Whether sync was successful
    pub success: bool,
    /// List of changes
    pub changes: Vec<SyncChange>,
    /// List of conflicts
    pub conflicts: Vec<Conflict>,
}

/// Obsidian Bridge
/// 
/// Manages bidirectional synchronization between OpenClaw and Obsidian vault.
pub struct ObsidianBridge {
    config: ObsidianConfig,
    last_sync: DateTime<Utc>,
}

impl ObsidianBridge {
    /// Create a new Obsidian Bridge
    pub fn new(config: ObsidianConfig) -> Self {
        Self {
            config,
            last_sync: DateTime::UNIX_EPOCH,
        }
    }
    
    /// Create with default configuration
    pub fn default() -> Self {
        Self::new(ObsidianConfig::default())
    }
    
    /// Initialize the bridge
    /// 
    /// Ensures vault directories exist.
    pub async fn initialize(&mut self) -> Result<(), ObsidianBridgeError> {
        self.ensure_directories().await?;
        info!("Obsidian Bridge initialized");
        Ok(())
    }
    
    /// Ensure all vault directories exist
    async fn ensure_directories(&self) -> Result<(), ObsidianBridgeError> {
        let vault = &self.config.vault_path;
        
        // Check if vault exists
        if !vault.exists() {
            return Err(ObsidianBridgeError::VaultNotFound(
                vault.to_string_lossy().to_string()
            ));
        }
        
        // Create mapping directories
        let mappings = [
            &self.config.mapping.sessions,
            &self.config.mapping.insights,
            &self.config.mapping.errors,
            &self.config.mapping.skills,
        ];
        
        for mapping in &mappings {
            let dir = vault.join(mapping);
            fs::create_dir_all(&dir).await?;
            debug!("Ensured directory: {}", dir.display());
        }
        
        Ok(())
    }
    
    /// Sync a session to Obsidian
    pub async fn sync_session(
        &self,
        session_id: &str,
        content: &str,
        metadata: &HashMap<String, String>,
    ) -> Result<PathBuf, ObsidianBridgeError> {
        let file_name = format!("{}.md", session_id);
        let file_path = self.config.vault_path
            .join(&self.config.mapping.sessions)
            .join(&file_name);
        
        // Build markdown content with YAML frontmatter
        let markdown = self.build_session_markdown(content, metadata);
        
        // Write file
        fs::write(&file_path, markdown).await?;
        
        info!("Synced session to: {}", file_path.display());
        Ok(file_path)
    }
    
    /// Sync an insight to Obsidian
    pub async fn sync_insight(
        &self,
        insight_id: &str,
        content: &str,
        tags: &[String],
    ) -> Result<PathBuf, ObsidianBridgeError> {
        let file_name = format!("{}.md", insight_id);
        let file_path = self.config.vault_path
            .join(&self.config.mapping.insights)
            .join(&file_name);
        
        // Build markdown with tags
        let mut markdown = String::new();
        markdown.push_str("---\n");
        markdown.push_str(&format!("id: {}\n", insight_id));
        markdown.push_str(&format!("created: {}\n", Utc::now().to_rfc3339()));
        markdown.push_str(&format!("tags: [{}]\n", tags.join(", ")));
        markdown.push_str("---\n\n");
        markdown.push_str(content);
        
        fs::write(&file_path, markdown).await?;
        
        info!("Synced insight to: {}", file_path.display());
        Ok(file_path)
    }
    
    /// Sync a skill to Obsidian
    pub async fn sync_skill(
        &self,
        skill_id: &str,
        content: &str,
        confidence: &str,
        triggers: &[String],
    ) -> Result<PathBuf, ObsidianBridgeError> {
        let file_name = format!("{}.md", skill_id);
        let file_path = self.config.vault_path
            .join(&self.config.mapping.skills)
            .join(&file_name);
        
        // Build markdown with YAML frontmatter
        let mut markdown = String::new();
        markdown.push_str("---\n");
        markdown.push_str(&format!("skill: {}\n", skill_id));
        markdown.push_str(&format!("created: {}\n", Utc::now().to_rfc3339()));
        markdown.push_str(&format!("confidence: {}\n", confidence));
        markdown.push_str(&format!("triggers: [{}]\n", triggers.join(", ")));
        markdown.push_str("---\n\n");
        markdown.push_str(content);
        
        fs::write(&file_path, markdown).await?;
        
        info!("Synced skill to: {}", file_path.display());
        Ok(file_path)
    }
    
    /// Read context from Obsidian
    pub async fn read_context(&self, context_id: &str) -> Result<Option<ContextItem>, ObsidianBridgeError> {
        // Try to find in different directories
        let dirs = [
            &self.config.mapping.sessions,
            &self.config.mapping.insights,
            &self.config.mapping.skills,
        ];
        
        for dir in &dirs {
            let file_path = self.config.vault_path
                .join(dir)
                .join(format!("{}.md", context_id));
            
            if file_path.exists() {
                let content = fs::read_to_string(&file_path).await?;
                
                // Parse markdown and extract content (skip YAML frontmatter)
                let parsed = self.parse_markdown(&content);
                let content_len = parsed.content.len();
                
                let item = ContextItem {
                    id: context_id.to_string(),
                    content: parsed.content,
                    token_count: content_len / 4, // Rough estimate
                    tier: Tier::Cold,
                    metadata: ContextMetadata {
                        source: format!("obsidian:{}", dir),
                        item_type: "obsidian_context".to_string(),
                        created: parsed.created.unwrap_or_else(Utc::now),
                        last_accessed: None,
                        access_count: 0,
                        pinned: false,
                        tags: parsed.tags,
                    },
                };
                
                return Ok(Some(item));
            }
        }
        
        Ok(None)
    }
    
    /// Build session markdown with YAML frontmatter
    fn build_session_markdown(
        &self,
        content: &str,
        metadata: &HashMap<String, String>,
    ) -> String {
        let mut markdown = String::new();
        
        // YAML frontmatter
        markdown.push_str("---\n");
        for (key, value) in metadata {
            markdown.push_str(&format!("{}: {}\n", key, value));
        }
        markdown.push_str(&format!("synced_at: {}\n", Utc::now().to_rfc3339()));
        markdown.push_str("---\n\n");
        
        // Content
        markdown.push_str(content);
        
        markdown
    }
    
    /// Parse markdown file
    fn parse_markdown(&self, content: &str) -> ParsedMarkdown {
        let mut result = ParsedMarkdown::default();
        
        // Check for YAML frontmatter
        if content.starts_with("---\n") {
            if let Some(end) = content.find("\n---\n") {
                let frontmatter = &content[4..end];
                result.content = content[end + 5..].trim().to_string();
                
                // Parse YAML frontmatter (simplified)
                for line in frontmatter.lines() {
                    if let Some((key, value)) = line.split_once(':') {
                        let key = key.trim();
                        let value = value.trim();
                        
                        match key {
                            "created" => {
                                if let Ok(dt) = DateTime::parse_from_rfc3339(value) {
                                    result.created = Some(dt.with_timezone(&Utc));
                                }
                            }
                            "tags" => {
                                // Parse tags array [tag1, tag2, ...]
                                let tags_str = value.trim_matches(|c| c == '[' || c == ']');
                                result.tags = tags_str
                                    .split(',')
                                    .map(|s| s.trim().to_string())
                                    .filter(|s| !s.is_empty())
                                    .collect();
                            }
                            _ => {}
                        }
                    }
                }
            } else {
                result.content = content.to_string();
            }
        } else {
            result.content = content.to_string();
        }
        
        result
    }
    
    /// Perform bidirectional sync
    pub async fn sync(&mut self) -> Result<SyncResult, ObsidianBridgeError> {
        let changes = Vec::new();
        let conflicts = Vec::new();
        
        info!("Starting Obsidian sync");
        
        // Note: Full bidirectional sync would require:
        // 1. Scanning OpenClaw for new/changed content
        // 2. Scanning Obsidian vault for new/changed content
        // 3. Comparing timestamps
        // 4. Resolving conflicts
        // 5. Applying changes
        
        // For now, this is a placeholder for the full implementation
        // The individual sync_* methods above handle specific content types
        
        self.last_sync = Utc::now();
        
        Ok(SyncResult {
            success: true,
            changes,
            conflicts,
        })
    }
    
    /// Get last sync time
    pub fn last_sync(&self) -> DateTime<Utc> {
        self.last_sync
    }
    
    /// Get vault path
    pub fn vault_path(&self) -> &Path {
        &self.config.vault_path
    }
}

/// Parsed markdown content
#[derive(Debug, Default)]
struct ParsedMarkdown {
    content: String,
    created: Option<DateTime<Utc>>,
    tags: Vec<String>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[tokio::test]
    async fn test_initialize_creates_directories() {
        let temp_dir = TempDir::new().unwrap();
        let vault_path = temp_dir.path().join("vault");
        fs::create_dir(&vault_path).await.unwrap();
        
        let config = ObsidianConfig {
            vault_path,
            ..Default::default()
        };
        
        let mut bridge = ObsidianBridge::new(config);
        bridge.initialize().await.unwrap();
        
        // Check directories were created
        assert!(temp_dir.path().join("vault/AI/Sessions").exists());
        assert!(temp_dir.path().join("vault/AI/Insights").exists());
        assert!(temp_dir.path().join("vault/AI/Errors").exists());
        assert!(temp_dir.path().join("vault/AI/Skills").exists());
    }

    #[tokio::test]
    async fn test_sync_session() {
        let temp_dir = TempDir::new().unwrap();
        let vault_path = temp_dir.path().join("vault");
        fs::create_dir(&vault_path).await.unwrap();
        
        let mut bridge = ObsidianBridge::new(ObsidianConfig {
            vault_path,
            ..Default::default()
        });
        bridge.initialize().await.unwrap();
        
        let mut metadata = HashMap::new();
        metadata.insert("session_id".to_string(), "test-123".to_string());
        
        let path = bridge.sync_session("test-123", "Session content", &metadata).await.unwrap();
        
        assert!(path.exists());
        let content = fs::read_to_string(&path).await.unwrap();
        assert!(content.contains("Session content"));
        assert!(content.contains("session_id: test-123"));
    }

    #[tokio::test]
    async fn test_parse_markdown_with_frontmatter() {
        let temp_dir = TempDir::new().unwrap();
        let vault_path = temp_dir.path().join("vault");
        fs::create_dir(&vault_path).await.unwrap();
        
        let bridge = ObsidianBridge::new(ObsidianConfig {
            vault_path,
            ..Default::default()
        });
        
        let markdown = r#"---
id: test-123
created: 2025-01-15T10:00:00Z
tags: [rust, ai]
---

This is the content."#;
        
        let parsed = bridge.parse_markdown(markdown);
        
        assert_eq!(parsed.content, "This is the content.");
        assert_eq!(parsed.tags, vec!["rust", "ai"]);
        assert!(parsed.created.is_some());
    }
}
