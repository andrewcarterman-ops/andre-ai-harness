//! Tool Registry Core
//! 
//! Tool trait system and registry for file operations, bash execution, etc.
//! Extracted from claw-code/rust/crates/tools/src/lib.rs

use async_trait::async_trait;
use serde::{Serialize, Deserialize};
use serde_json::Value;

/// Tool trait - all tools implement this
#[async_trait]
pub trait Tool: Send + Sync {
    /// Tool name
    fn name(&self) -> &str;
    
    /// Tool description
    fn description(&self) -> &str;
    
    /// JSON schema for tool parameters
    fn parameters_schema(&self) -> Value;
    
    /// Execute the tool
    async fn execute(&self, args: Value) -> Result<ToolOutput, ToolError>;
}

/// Tool execution result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolOutput {
    pub content: String,
    pub is_error: bool,
}

impl ToolOutput {
    /// Create successful output
    pub fn success(content: impl Into<String>) -> Self {
        Self {
            content: content.into(),
            is_error: false,
        }
    }
    
    /// Create error output
    pub fn error(content: impl Into<String>) -> Self {
        Self {
            content: content.into(),
            is_error: true,
        }
    }
}

/// Tool error
#[derive(Debug, Clone)]
pub enum ToolError {
    /// Tool not found
    NotFound(String),
    /// Invalid arguments
    InvalidArguments(String),
    /// Execution failed
    Execution(String),
    /// Permission denied
    PermissionDenied,
    /// Timeout
    Timeout,
    /// IO error
    Io(String),
}

impl std::fmt::Display for ToolError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NotFound(name) => write!(f, "Tool not found: {}", name),
            Self::InvalidArguments(msg) => write!(f, "Invalid arguments: {}", msg),
            Self::Execution(msg) => write!(f, "Execution failed: {}", msg),
            Self::PermissionDenied => write!(f, "Permission denied"),
            Self::Timeout => write!(f, "Tool execution timeout"),
            Self::Io(msg) => write!(f, "IO error: {}", msg),
        }
    }
}

impl std::error::Error for ToolError {}

/// Tool definition for LLM
#[derive(Debug, Clone, Serialize)]
pub struct ToolDefinition {
    pub name: String,
    pub description: String,
    pub parameters: Value,
}

impl ToolDefinition {
    /// Create new tool definition
    pub fn new(name: impl Into<String>, description: impl Into<String>, parameters: Value) -> Self {
        Self {
            name: name.into(),
            description: description.into(),
            parameters,
        }
    }
}
