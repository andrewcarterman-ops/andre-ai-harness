//! MCP Tool Adapter
//! 
//! Integrates MCP servers with the ECC Runtime ToolExecutor trait
//! Makes MCP tools usable as regular runtime tools

use async_trait::async_trait;
use serde_json::Value;
use std::collections::BTreeMap;
use std::sync::Arc;
use tokio::sync::Mutex;

use crate::{ToolExecutor, ToolDefinition, ToolCall, ToolResult, ToolError};
use crate::mcp_stdio::{McpServerManager, McpTool};

/// MCP Tool Adapter - bridges MCP servers to Runtime tool system
#[derive(Clone)]
pub struct McpToolAdapter {
    manager: Arc<Mutex<McpServerManager>>,
    server_prefix: String,
}

impl McpToolAdapter {
    /// Create new adapter
    pub fn new() -> Self {
        Self {
            manager: Arc::new(Mutex::new(McpServerManager::new())),
            server_prefix: "mcp".to_string(),
        }
    }

    /// Create with custom prefix for tool names
    pub fn with_prefix(prefix: impl Into<String>) -> Self {
        Self {
            manager: Arc::new(Mutex::new(McpServerManager::new())),
            server_prefix: prefix.into(),
        }
    }

    /// Start an MCP server and register its tools
    pub async fn start_server(
        &self,
        name: &str,
        command: &str,
        args: Vec<String>,
        env: BTreeMap<String, String>,
    ) -> Result<(), McpAdapterError> {
        let mut manager = self.manager.lock().await;
        
        manager.start_server(name, command, args, env).await
            .map_err(|e| McpAdapterError::ServerStartFailed(e.message))?;
        Ok(())
    }

    /// Stop an MCP server
    pub async fn stop_server(&self, name: &str) -> Result<(), McpAdapterError> {
        let mut manager = self.manager.lock().await;
        
        manager.stop_server(name).await
            .map_err(|e| McpAdapterError::ServerStopFailed(e.message))?;
        Ok(())
    }

    /// List all running MCP servers
    pub async fn list_servers(&self) -> Vec<String> {
        let manager = self.manager.lock().await;
        manager.list_servers()
    }

    /// Format tool name with server prefix
    /// Format: "{prefix}.{server_name}.{tool_name}"
    fn format_tool_name(&self, server_name: &str, tool_name: &str) -> String {
        format!("{}.{}.{}", self.server_prefix, server_name, tool_name)
    }

    /// Parse tool name to extract server and tool
    /// Expected format: "{prefix}.{server_name}.{tool_name}"
    fn parse_tool_name(&self, full_name: &str) -> Result<(String, String), McpAdapterError> {
        let prefix = &self.server_prefix;
        let expected_start = format!("{}.", prefix);
        
        if !full_name.starts_with(&expected_start) {
            return Err(McpAdapterError::InvalidToolName {
                name: full_name.to_string(),
                expected_format: format!("{}.{{server_name}}.{{tool_name}}", prefix),
            });
        }

        let without_prefix = &full_name[expected_start.len()..];
        
        // Find the separator between server and tool name
        if let Some(dot_pos) = without_prefix.find('.') {
            let server_name = without_prefix[..dot_pos].to_string();
            let tool_name = without_prefix[dot_pos + 1..].to_string();
            
            // Validate non-empty names
            if server_name.is_empty() || tool_name.is_empty() {
                return Err(McpAdapterError::InvalidToolName {
                    name: full_name.to_string(),
                    expected_format: format!("{}.{{server_name}}.{{tool_name}}", prefix),
                });
            }
            
            Ok((server_name, tool_name))
        } else {
            Err(McpAdapterError::InvalidToolName {
                name: full_name.to_string(),
                expected_format: format!("{}.{{server_name}}.{{tool_name}}", prefix),
            })
        }
    }

    /// Convert MCP tool to Runtime ToolDefinition
    fn convert_tool_definition(&self, server_name: &str, mcp_tool: &McpTool) -> ToolDefinition {
        let full_name = self.format_tool_name(server_name, &mcp_tool.name);
        
        ToolDefinition::new(
            full_name,
            &mcp_tool.description,
            mcp_tool.input_schema.clone()
        )
    }

    /// Check if a tool name belongs to this adapter
    pub fn handles_tool(&self, tool_name: &str) -> bool {
        tool_name.starts_with(&format!("{}.", self.server_prefix))
    }
}

impl Default for McpToolAdapter {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl ToolExecutor for McpToolAdapter {
    async fn execute(&self, tool_call: &ToolCall) -> Result<ToolResult, ToolError> {
        // Parse the tool name
        let (server_name, tool_name) = self.parse_tool_name(&tool_call.name)
            .map_err(|e| ToolError::InvalidArguments(e.to_string()))?;

        // Execute via MCP server
        let mut manager = self.manager.lock().await;
        let result = manager.execute_tool(&server_name, &tool_name, tool_call.arguments.clone()).await
            .map_err(|e| ToolError::Execution(format!("MCP error: {}", e.message)))?;

        // Convert result to string
        let content = serde_json::to_string_pretty(&result)
            .unwrap_or_else(|_| result.to_string());

        Ok(ToolResult::success(&tool_call.id, content))
    }

    fn available_tools(&self) -> Vec<ToolDefinition> {
        // Note: This is synchronous, so we can't use async mutex.
        // For now, return empty list - tools should be cached or
        // available_tools should be called asynchronously elsewhere
        Vec::new()
    }
}

/// MCP Adapter errors
#[derive(Debug, Clone)]
pub enum McpAdapterError {
    ServerStartFailed(String),
    ServerStopFailed(String),
    ServerNotFound(String),
    ToolNotFound {
        server: String,
        tool: String,
    },
    InvalidToolName {
        name: String,
        expected_format: String,
    },
    ExecutionFailed(String),
}

impl std::fmt::Display for McpAdapterError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::ServerStartFailed(msg) => write!(f, "Failed to start MCP server: {}", msg),
            Self::ServerStopFailed(msg) => write!(f, "Failed to stop MCP server: {}", msg),
            Self::ServerNotFound(name) => write!(f, "MCP server not found: {}", name),
            Self::ToolNotFound { server, tool } => {
                write!(f, "Tool '{}' not found on server '{}'", tool, server)
            }
            Self::InvalidToolName { name, expected_format } => {
                write!(f, "Invalid tool name '{}'. Expected format: {}", name, expected_format)
            }
            Self::ExecutionFailed(msg) => write!(f, "Execution failed: {}", msg),
        }
    }
}

impl std::error::Error for McpAdapterError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_tool_name() {
        let adapter = McpToolAdapter::new();
        let name = adapter.format_tool_name("filesystem", "read_file");
        assert_eq!(name, "mcp.filesystem.read_file");
    }

    #[test]
    fn test_parse_tool_name_valid() {
        let adapter = McpToolAdapter::new();
        let result = adapter.parse_tool_name("mcp.filesystem.read_file").unwrap();
        assert_eq!(result.0, "filesystem");
        assert_eq!(result.1, "read_file");
    }

    #[test]
    fn test_parse_tool_name_invalid() {
        let adapter = McpToolAdapter::new();
        
        // Missing prefix
        assert!(adapter.parse_tool_name("filesystem.read_file").is_err());
        
        // Missing server separator
        assert!(adapter.parse_tool_name("mcp.read_file").is_err());
        
        // Empty tool name
        assert!(adapter.parse_tool_name("mcp.filesystem.").is_err());
    }

    #[test]
    fn test_handles_tool() {
        let adapter = McpToolAdapter::new();
        
        assert!(adapter.handles_tool("mcp.filesystem.read_file"));
        assert!(adapter.handles_tool("mcp.github.create_issue"));
        assert!(!adapter.handles_tool("bash"));
        assert!(!adapter.handles_tool("read_file"));
    }

    #[test]
    fn test_convert_tool_definition() {
        let adapter = McpToolAdapter::new();
        let mcp_tool = McpTool {
            name: "read_file".to_string(),
            description: "Read a file".to_string(),
            input_schema: serde_json::json!({
                "type": "object",
                "properties": {
                    "path": {"type": "string"}
                }
            }),
        };
        
        let def = adapter.convert_tool_definition("filesystem", &mcp_tool);
        assert_eq!(def.name, "mcp.filesystem.read_file");
        assert_eq!(def.description, "Read a file");
    }
}
