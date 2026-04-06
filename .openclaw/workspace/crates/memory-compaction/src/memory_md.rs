//! Memory.md Updater
//! 
//! Updates MEMORY.md with key insights

use std::path::PathBuf;
use tokio::fs;

/// MEMORY.md updater
#[derive(Debug, Clone)]
pub struct MemoryMdUpdater {
    memory_file: PathBuf,
}

/// Memory insight entry
#[derive(Debug, Clone)]
pub struct MemoryInsight {
    pub date: String,
    pub title: String,
    pub content: String,
    pub tags: Vec<String>,
}

impl MemoryInsight {
    /// Create new insight
    pub fn new(date: impl Into<String>, title: impl Into<String>, content: impl Into<String>) -> Self {
        Self {
            date: date.into(),
            title: title.into(),
            content: content.into(),
            tags: Vec::new(),
        }
    }

    /// Add tags
    pub fn with_tags(mut self, tags: Vec<String>) -> Self {
        self.tags = tags;
        self
    }
}

/// Updater error
#[derive(Debug, Clone)]
pub enum UpdaterError {
    Io(String),
    Read(String),
    Write(String),
    InvalidFormat(String),
}

impl std::fmt::Display for UpdaterError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Io(s) => write!(f, "IO error: {}", s),
            Self::Read(s) => write!(f, "Read error: {}", s),
            Self::Write(s) => write!(f, "Write error: {}", s),
            Self::InvalidFormat(s) => write!(f, "Invalid format: {}", s),
        }
    }
}

impl std::error::Error for UpdaterError {}

impl MemoryMdUpdater {
    /// Create new updater
    pub fn new(memory_file: impl Into<PathBuf>) -> Self {
        Self {
            memory_file: memory_file.into(),
        }
    }

    /// Update MEMORY.md with insights
    pub async fn update(&self, insights: &[MemoryInsight]) -> Result<(), UpdaterError> {
        if insights.is_empty() {
            return Ok(());
        }

        // Read existing content or create new
        let mut content = match fs::read_to_string(&self.memory_file).await {
            Ok(c) => c,
            Err(_) => create_default_memory_md(),
        };

        // Format new insights
        let new_entries = format_insights(insights);

        // Find or create insertion point
        let insertion_point = find_insertion_point(&content);

        // Insert new entries
        content.insert_str(insertion_point, &new_entries);

        // Write back
        fs::write(&self.memory_file, content).await
            .map_err(|e| UpdaterError::Write(e.to_string()))?;

        Ok(())
    }

    /// Get memory file path
    pub fn memory_file(&self) -> &PathBuf {
        &self.memory_file
    }

    /// Check if memory file exists
    pub async fn exists(&self) -> bool {
        fs::metadata(&self.memory_file).await.is_ok()
    }
}

/// Create default MEMORY.md content
fn create_default_memory_md() -> String {
    format!(
        "# MEMORY.md - Kuratiertes Langzeit-Gedächtnis\n\n\
        > Wichtige Erkenntnisse, Patterns und Best Practices\n\
        > Automatisch kuratiert aus täglichen Sessions\n\n\
        ---\n\n\
        ## Key Insights\n\n"
    )
}

/// Find insertion point in content
fn find_insertion_point(content: &str) -> usize {
    // Look for "## Key Insights" section
    if let Some(pos) = content.find("## Key Insights") {
        let after_header = pos + "## Key Insights".len();
        // Find end of line
        if let Some(newline) = content[after_header..].find('\n') {
            return after_header + newline + 1;
        }
        return after_header;
    }

    // Look for any ## section
    if let Some(pos) = content.find("\n## ") {
        return pos + 1;
    }

    // Default: end of content
    content.len()
}

/// Format insights for insertion
fn format_insights(insights: &[MemoryInsight]) -> String {
    insights
        .iter()
        .map(|i| format_insight(i))
        .collect::<Vec<_>>()
        .join("\n")
}

/// Format single insight
fn format_insight(insight: &MemoryInsight) -> String {
    let tags_str = if insight.tags.is_empty() {
        String::new()
    } else {
        format!(" ",)
    };

    format!(
        "- [{}] **{}**: {}{}\n",
        insight.date,
        insight.title,
        truncate(&insight.content, 200),
        tags_str
    )
}

/// Truncate string with ellipsis
fn truncate(s: &str, max_len: usize) -> String {
    if s.len() <= max_len {
        s.to_string()
    } else {
        format!("{}...", &s[..max_len])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_memory_insight_creation() {
        let insight = MemoryInsight::new(
            "2026-04-02",
            "Test Insight",
            "This is a test insight with some content"
        ).with_tags(vec!["test".to_string()]);

        assert_eq!(insight.date, "2026-04-02");
        assert_eq!(insight.title, "Test Insight");
        assert!(insight.content.contains("test insight"));
    }

    #[test]
    fn test_truncate() {
        assert_eq!(truncate("short", 10), "short");
        assert_eq!(truncate("this is a very long string", 10), "this is a ...");
    }

    #[test]
    fn test_find_insertion_point() {
        let content = "# Header\n\n## Key Insights\n\nExisting content";
        let pos = find_insertion_point(content);
        assert!(pos > content.find("## Key Insights").unwrap());
    }

    #[test]
    fn test_format_insight() {
        let insight = MemoryInsight::new(
            "2026-04-02",
            "Test",
            "This is the content of the insight"
        );

        let formatted = format_insight(&insight);
        assert!(formatted.contains("[2026-04-02]"));
        assert!(formatted.contains("**Test**"));
        assert!(formatted.contains("content of the insight"));
    }

    #[test]
    fn test_create_default_memory_md() {
        let content = create_default_memory_md();
        assert!(content.contains("# MEMORY.md"));
        assert!(content.contains("## Key Insights"));
    }
}
