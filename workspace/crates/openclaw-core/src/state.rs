//! State Management for OpenClaw Sessions
//! 
//! Sessions are stored as Markdown with YAML Frontmatter.

use anyhow::Result;
use chrono::{DateTime, Utc, Timelike};
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

/// Session status
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum SessionStatus {
    #[serde(rename = "active")]
    Active,
    #[serde(rename = "completed")]
    Completed,
    #[serde(rename = "failed")]
    Failed,
    #[serde(rename = "archived")]
    Archived,
}

impl Default for SessionStatus {
    fn default() -> Self {
        SessionStatus::Active
    }
}

/// YAML Frontmatter for a session
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionFrontmatter {
    pub session_id: String,
    pub status: SessionStatus,
    pub agent: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent_session: Option<String>,
    pub tokens_in: usize,
    pub tokens_out: usize,
    pub cost_usd: f64,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub tags: Vec<String>,
}

impl SessionFrontmatter {
    pub fn new(session_id: impl Into<String>, agent: impl Into<String>) -> Self {
        let now = Utc::now();
        Self {
            session_id: session_id.into(),
            status: SessionStatus::Active,
            agent: agent.into(),
            created_at: now,
            updated_at: now,
            parent_session: None,
            tokens_in: 0,
            tokens_out: 0,
            cost_usd: 0.0,
            tags: Vec::new(),
        }
    }
    
    pub fn touch(mut self) -> Self {
        self.updated_at = Utc::now();
        self
    }
    
    pub fn add_usage(mut self, tokens_in: usize, tokens_out: usize, cost: f64) -> Self {
        self.tokens_in += tokens_in;
        self.tokens_out += tokens_out;
        self.cost_usd += cost;
        self
    }
    
    pub fn with_status(mut self, status: SessionStatus) -> Self {
        self.status = status;
        self
    }
    
    pub fn with_tags(mut self, tags: Vec<String>) -> Self {
        self.tags = tags;
        self
    }
}

/// A complete session with frontmatter and content
#[derive(Debug, Clone)]
pub struct Session {
    pub frontmatter: SessionFrontmatter,
    pub content: String,
}

impl Session {
    pub fn new(session_id: impl Into<String>, agent: impl Into<String>) -> Self {
        Self {
            frontmatter: SessionFrontmatter::new(session_id, agent),
            content: String::new(),
        }
    }
    
    pub fn add_content(&mut self, role: &str, text: impl Into<String>) {
        let text = text.into();
        if !text.trim().is_empty() {
            self.content.push_str(&format!("## {}\n\n{}\n\n", role, text));
        }
    }
    
    pub fn to_markdown(&self) -> Result<String> {
        let yaml = serde_yaml::to_string(&self.frontmatter)?;
        Ok(format!("---\n{}---\n\n{}", yaml, self.content))
    }
    
    pub fn from_markdown(text: &str) -> Result<Self> {
        let parts: Vec<&str> = text.splitn(3, "---").collect();
        if parts.len() < 3 {
            return Err(anyhow::anyhow!("Invalid Markdown format: missing frontmatter"));
        }
        
        let yaml_text = parts[1].trim();
        let content = parts[2].trim();
        
        let frontmatter: SessionFrontmatter = serde_yaml::from_str(yaml_text)?;
        
        Ok(Self {
            frontmatter,
            content: content.to_string(),
        })
    }
    
    pub fn save(&self, path: &Path) -> Result<()> {
        let markdown = self.to_markdown()?;
        crate::atomic::atomic_write(path, &markdown)?;
        Ok(())
    }
    
    pub fn load(path: &Path) -> Result<Self> {
        let text = std::fs::read_to_string(path)?;
        Self::from_markdown(&text)
    }
}

/// Session manager for handling multiple sessions
pub struct SessionManager {
    sessions_dir: PathBuf,
}

impl SessionManager {
    pub fn new(sessions_dir: impl Into<PathBuf>) -> Self {
        Self {
            sessions_dir: sessions_dir.into(),
        }
    }
    
    pub fn generate_session_id(&self) -> String {
        let now = Utc::now();
        format!("{}-{:02}{:02}{:02}", 
            now.format("%Y%m%d"),
            now.hour(),
            now.minute(),
            now.second()
        )
    }
    
    pub fn session_path(&self, session_id: &str) -> PathBuf {
        self.sessions_dir.join(format!("{}.md", session_id))
    }
    
    pub fn create_session(&self, agent: impl Into<String>) -> Result<(Session, PathBuf)> {
        let session_id = self.generate_session_id();
        let session = Session::new(&session_id, agent);
        let path = self.session_path(&session_id);
        
        std::fs::create_dir_all(&self.sessions_dir)?;
        
        Ok((session, path))
    }
    
    pub fn list_sessions(&self) -> Result<Vec<(String, PathBuf)>> {
        let mut sessions = Vec::new();
        
        if !self.sessions_dir.exists() {
            return Ok(sessions);
        }
        
        for entry in std::fs::read_dir(&self.sessions_dir)? {
            let entry = entry?;
            let path = entry.path();
            
            if path.extension().map_or(false, |ext| ext == "md") {
                if let Some(stem) = path.file_stem() {
                    sessions.push((stem.to_string_lossy().to_string(), path));
                }
            }
        }
        
        sessions.sort_by(|a, b| b.0.cmp(&a.0));
        
        Ok(sessions)
    }
    
    pub fn load_latest(&self) -> Result<Option<(Session, PathBuf)>> {
        let sessions = self.list_sessions()?;
        
        if let Some((_, path)) = sessions.first() {
            let session = Session::load(path)?;
            Ok(Some((session, path.clone())))
        } else {
            Ok(None)
        }
    }
}
