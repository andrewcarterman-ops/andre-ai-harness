//! Memory Bridge for ECC Runtime
//! 
//! Integrates with Second Brain (Obsidian) and manages daily logs

use std::path::PathBuf;
use std::collections::HashMap;
use serde::{Serialize, Deserialize};
use chrono::{DateTime, Utc, Local};
use tokio::fs::{self, OpenOptions};
use tokio::io::AsyncWriteExt;

use crate::{Session, Message};

/// Memory bridge for syncing to Second Brain
#[async_trait::async_trait]
pub trait MemoryBridge: Send + Sync {
    /// Sync conversation to memory systems
    async fn sync_conversation(&self, session: &Session) -> Result<(), MemoryError>;
    
    /// Sync specific memory entry
    async fn sync_entry(&self, entry: &MemoryEntry) -> Result<(), MemoryError>;
    
    /// Get recent entries
    async fn get_recent_entries(&self, limit: usize) -> Result<Vec<MemoryEntry>, MemoryError>;
}

/// Memory entry for Second Brain
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryEntry {
    pub id: String,
    pub timestamp: DateTime<Utc>,
    pub title: String,
    pub content: String,
    pub source: String,
    pub importance: Importance,
    pub tags: Vec<String>,
    pub metadata: HashMap<String, String>,
}

/// Importance level for memory classification
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Importance {
    Critical,
    Important,
    Reference,
    Trivial,
}

impl Importance {
    pub fn should_sync(&self) -> bool {
        matches!(self, Self::Critical | Self::Important)
    }
    
    pub fn should_update_memory_md(&self) -> bool {
        matches!(self, Self::Critical)
    }
}

/// Memory classifier
pub struct MemoryClassifier;

impl MemoryClassifier {
    pub fn new() -> Self {
        Self
    }
    
    pub fn classify_message(&self, message: &Message) -> Importance {
        let content = &message.content.to_lowercase();
        
        if content.contains("error") || content.contains("decision") {
            return Importance::Critical;
        }
        if content.contains("insight") || content.contains("solution") {
            return Importance::Important;
        }
        if content.len() < 30 {
            return Importance::Trivial;
        }
        
        Importance::Reference
    }
}

/// Obsidian sync for Second Brain
pub struct ObsidianSync {
    vault_path: PathBuf,
}

impl ObsidianSync {
    pub fn new(vault_path: impl Into<PathBuf>) -> Self {
        Self {
            vault_path: vault_path.into(),
        }
    }
    
    pub async fn sync_to_inbox(&self, entry: &MemoryEntry) -> Result<(), MemoryError> {
        let filename = format!("{}-{}.md", entry.timestamp.format("%Y-%m-%d"), entry.title.replace(" ", "-"));
        let filepath = self.vault_path.join("Inbox").join(filename);
        
        fs::create_dir_all(filepath.parent().unwrap()).await.map_err(|e| MemoryError::Io(e.to_string()))?;
        
        let content = format!("# {}\n\n{}", entry.title, entry.content);
        fs::write(&filepath, content).await.map_err(|e| MemoryError::Io(e.to_string()))?;
        
        Ok(())
    }
}

/// Daily log writer
pub struct DailyLogWriter {
    log_dir: PathBuf,
}

impl DailyLogWriter {
    pub fn new(log_dir: impl Into<PathBuf>) -> Self {
        Self {
            log_dir: log_dir.into(),
        }
    }
    
    pub async fn write_session(&self, session: &Session) -> Result<(), MemoryError> {
        let today = Local::now().format("%Y-%m-%d");
        let log_path = self.log_dir.join(format!("{}.md", today));
        
        fs::create_dir_all(&self.log_dir).await.map_err(|e| MemoryError::Io(e.to_string()))?;
        
        let entry = format!("\n## Session {}\n\nMessages: {}\nTokens: {}\n\n",
            session.metadata.created_at.map(|d| d.format("%H:%M").to_string()).unwrap_or_default(),
            session.messages.len(),
            session.estimate_tokens()
        );
        
        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&log_path)
            .await
            .map_err(|e| MemoryError::Io(e.to_string()))?;
        
        file.write_all(entry.as_bytes()).await.map_err(|e| MemoryError::Io(e.to_string()))?;
        Ok(())
    }
}

/// MEMORY.md updater
pub struct MemoryMdUpdater {
    memory_file: PathBuf,
}

impl MemoryMdUpdater {
    pub fn new(memory_file: impl Into<PathBuf>) -> Self {
        Self {
            memory_file: memory_file.into(),
        }
    }
    
    pub async fn update(&self, entries: &[MemoryEntry]) -> Result<(), MemoryError> {
        if entries.is_empty() {
            return Ok(());
        }
        
        let mut content = match fs::read_to_string(&self.memory_file).await {
            Ok(c) => c,
            Err(_) => "# MEMORY.md\n\n## Key Insights\n\n".to_string(),
        };
        
        let new_entries: String = entries
            .iter()
            .filter(|e| e.importance.should_update_memory_md())
            .map(|e| format!("- [{}] **{}**: {}\n", e.timestamp.format("%Y-%m-%d"), e.title, &e.content[..e.content.len().min(200)]))
            .collect();
        
        if let Some(pos) = content.find("## Key Insights") {
            let insert_pos = pos + "## Key Insights".len();
            content.insert_str(insert_pos, &new_entries);
        }
        
        fs::write(&self.memory_file, content).await.map_err(|e| MemoryError::Io(e.to_string()))?;
        Ok(())
    }
}

/// Memory error
#[derive(Debug, Clone)]
pub enum MemoryError {
    Io(String),
    Serialize(String),
}

impl std::fmt::Display for MemoryError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Io(s) => write!(f, "IO error: {}", s),
            Self::Serialize(s) => write!(f, "Serialize error: {}", s),
        }
    }
}

impl std::error::Error for MemoryError {}

impl From<std::io::Error> for MemoryError {
    fn from(e: std::io::Error) -> Self {
        MemoryError::Io(e.to_string())
    }
}
