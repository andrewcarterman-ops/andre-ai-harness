//! Audit Logger for Permission Events
//! 
//! ECC Extension: Comprehensive audit logging for security compliance

use std::path::PathBuf;
use serde::{Serialize, Deserialize};
use chrono::{DateTime, Utc};
use tokio::fs::OpenOptions;
use tokio::io::AsyncWriteExt;

use crate::risk_analyzer::RiskScore;

/// Audit logger for permission events
#[derive(Debug, Clone)]
pub struct AuditLogger {
    log_file: PathBuf,
    max_entries: usize,
}

impl AuditLogger {
    /// Create new audit logger with default location
    pub fn new() -> Self {
        let log_dir = dirs::data_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("openclaw")
            .join("audit");
        
        std::fs::create_dir_all(&log_dir).ok();
        
        Self {
            log_file: log_dir.join("permissions.log"),
            max_entries: 10000,
        }
    }

    /// Create logger with custom log file path
    pub fn with_path(log_file: impl Into<PathBuf>) -> Self {
        let log_file = log_file.into();
        if let Some(parent) = log_file.parent() {
            std::fs::create_dir_all(parent).ok();
        }
        
        Self {
            log_file,
            max_entries: 10000,
        }
    }

    /// Set maximum number of entries to keep
    pub fn with_max_entries(mut self, max: usize) -> Self {
        self.max_entries = max;
        self
    }

    /// Log a permission event
    pub async fn log(&self, event: PermissionEvent) -> Result<(), AuditError> {
        let entry = serde_json::to_string(&event)
            .map_err(|e| AuditError::Serialize(e.to_string()))?;

        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_file)
            .await
            .map_err(|e| AuditError::Io(e.to_string()))?;

        file.write_all(format!("{}\n", entry).as_bytes())
            .await
            .map_err(|e| AuditError::Io(e.to_string()))?;

        file.flush()
            .await
            .map_err(|e| AuditError::Io(e.to_string()))?;

        // Rotate if needed
        self.rotate_if_needed().await?;

        Ok(())
    }

    /// Log allowed event
    pub async fn log_allowed(
        &self,
        tool: impl Into<String>,
        risk_score: RiskScore,
        auto_allowed: bool,
    ) -> Result<(), AuditError> {
        self.log(PermissionEvent {
            timestamp: Utc::now().to_rfc3339(),
            tool: tool.into(),
            action: PermissionAction::Allowed {
                risk_score: format!("{:?}", risk_score),
                auto_allowed,
            },
            context: None,
        }).await
    }

    /// Log denied event
    pub async fn log_denied(
        &self,
        tool: impl Into<String>,
        reason: impl Into<String>,
    ) -> Result<(), AuditError> {
        self.log(PermissionEvent {
            timestamp: Utc::now().to_rfc3339(),
            tool: tool.into(),
            action: PermissionAction::Denied {
                reason: reason.into(),
            },
            context: None,
        }).await
    }

    /// Log prompted event
    pub async fn log_prompted(
        &self,
        tool: impl Into<String>,
        risk_score: RiskScore,
        user_response: impl Into<String>,
    ) -> Result<(), AuditError> {
        self.log(PermissionEvent {
            timestamp: Utc::now().to_rfc3339(),
            tool: tool.into(),
            action: PermissionAction::Prompted {
                risk_score: format!("{:?}", risk_score),
                user_response: user_response.into(),
            },
            context: None,
        }).await
    }

    /// Get recent events
    pub async fn get_recent_events(&self, limit: usize) -> Result<Vec<PermissionEvent>, AuditError> {
        let content = tokio::fs::read_to_string(&self.log_file)
            .await
            .map_err(|e| AuditError::Io(e.to_string()))?;

        let events: Vec<PermissionEvent> = content
            .lines()
            .rev()
            .take(limit)
            .filter_map(|line| serde_json::from_str(line).ok())
            .collect();

        Ok(events)
    }

    /// Get events for a specific tool
    pub async fn get_tool_events(&self, tool: &str) -> Result<Vec<PermissionEvent>, AuditError> {
        let all = self.get_recent_events(self.max_entries).await?;
        Ok(all.into_iter()
            .filter(|e| e.tool == tool)
            .collect())
    }

    /// Get events since timestamp
    pub async fn get_events_since(
        &self,
        since: DateTime<Utc>,
    ) -> Result<Vec<PermissionEvent>, AuditError> {
        let all = self.get_recent_events(self.max_entries).await?;
        Ok(all.into_iter()
            .filter(|e| {
                DateTime::parse_from_rfc3339(&e.timestamp)
                    .map(|dt| dt.with_timezone(&Utc) >= since)
                    .unwrap_or(false)
            })
            .collect())
    }

    /// Get statistics
    pub async fn get_stats(&self) -> Result<AuditStats, AuditError> {
        let events = self.get_recent_events(self.max_entries).await?;
        
        let mut allowed = 0;
        let mut denied = 0;
        let mut prompted = 0;
        let mut auto_allowed = 0;

        for event in &events {
            match &event.action {
                PermissionAction::Allowed { auto_allowed: true, .. } => {
                    allowed += 1;
                    auto_allowed += 1;
                }
                PermissionAction::Allowed { auto_allowed: false, .. } => {
                    allowed += 1;
                }
                PermissionAction::Denied { .. } => {
                    denied += 1;
                }
                PermissionAction::Prompted { .. } => {
                    prompted += 1;
                }
                _ => {}
            }
        }

        Ok(AuditStats {
            total_events: events.len(),
            allowed,
            denied,
            prompted,
            auto_allowed,
        })
    }

    /// Rotate log file if too large
    async fn rotate_if_needed(&self) -> Result<(), AuditError> {
        let metadata = tokio::fs::metadata(&self.log_file)
            .await
            .map_err(|e| AuditError::Io(e.to_string()))?;

        // Rotate if > 10MB
        if metadata.len() > 10 * 1024 * 1024 {
            let rotated = self.log_file.with_extension("log.old");
            tokio::fs::rename(&self.log_file, rotated)
                .await
                .map_err(|e| AuditError::Io(e.to_string()))?;
        }

        Ok(())
    }

    /// Clear all logs
    pub async fn clear(&self) -> Result<(), AuditError> {
        tokio::fs::remove_file(&self.log_file)
            .await
            .map_err(|e| AuditError::Io(e.to_string()))?;
        Ok(())
    }
}

impl Default for AuditLogger {
    fn default() -> Self {
        Self::new()
    }
}

/// Permission event for audit log
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PermissionEvent {
    /// ISO 8601 timestamp
    pub timestamp: String,
    pub tool: String,
    pub action: PermissionAction,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context: Option<String>,
}

/// Permission action types
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "details")]
pub enum PermissionAction {
    #[serde(rename = "allowed")]
    Allowed {
        risk_score: String,
        auto_allowed: bool,
    },
    #[serde(rename = "denied")]
    Denied {
        reason: String,
    },
    #[serde(rename = "prompted")]
    Prompted {
        risk_score: String,
        user_response: String,
    },
    #[serde(rename = "override_set")]
    OverrideSet {
        mode: String,
    },
}

/// Audit statistics
#[derive(Debug, Clone, Default)]
pub struct AuditStats {
    pub total_events: usize,
    pub allowed: usize,
    pub denied: usize,
    pub prompted: usize,
    pub auto_allowed: usize,
}

/// Audit errors
#[derive(Debug, Clone)]
pub enum AuditError {
    Io(String),
    Serialize(String),
    NotFound,
}

impl std::fmt::Display for AuditError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Io(msg) => write!(f, "IO error: {}", msg),
            Self::Serialize(msg) => write!(f, "Serialize error: {}", msg),
            Self::NotFound => write!(f, "Log not found"),
        }
    }
}

impl std::error::Error for AuditError {}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[tokio::test]
    async fn test_log_and_retrieve() {
        let temp_dir = TempDir::new().unwrap();
        let log_file = temp_dir.path().join("test.log");
        
        let logger = AuditLogger::with_path(&log_file);
        
        logger.log_allowed("read", RiskScore::Low, true).await.unwrap();
        logger.log_denied("bash", "Critical pattern detected").await.unwrap();
        
        let events = logger.get_recent_events(10).await.unwrap();
        assert_eq!(events.len(), 2);
    }

    #[tokio::test]
    async fn test_get_stats() {
        let temp_dir = TempDir::new().unwrap();
        let logger = AuditLogger::with_path(temp_dir.path().join("test.log"));
        
        logger.log_allowed("read", RiskScore::Low, true).await.unwrap();
        logger.log_allowed("write", RiskScore::Medium, false).await.unwrap();
        logger.log_denied("bash", "Dangerous").await.unwrap();
        
        let stats = logger.get_stats().await.unwrap();
        assert_eq!(stats.total_events, 3);
        assert_eq!(stats.allowed, 2);
        assert_eq!(stats.denied, 1);
        assert_eq!(stats.auto_allowed, 1);
    }
}
