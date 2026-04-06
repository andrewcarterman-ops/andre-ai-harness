//! MCP (Model Context Protocol) Integration
//! 
//! Stdio-based MCP server communication
//! Extracted from claw-code/rust/crates/runtime/src/mcp_stdio.rs

use std::collections::BTreeMap;
use std::process::Stdio;
use tokio::io::{BufReader, AsyncBufReadExt, AsyncWriteExt};
use tokio::process::{Child, Command};
use serde::{Serialize, Deserialize};
use serde_json::Value;

/// MCP Stdio Manager
pub struct McpServerManager {
    servers: BTreeMap<String, McpServerInstance>,
}

/// MCP Server instance
pub struct McpServerInstance {
    pub name: String,
    pub process: Child,
    pub tools: Vec<McpTool>,
}

/// MCP Tool definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpTool {
    pub name: String,
    pub description: String,
    pub input_schema: Value,
}

/// MCP Request
#[derive(Debug, Serialize, Deserialize)]
pub struct McpRequest {
    pub jsonrpc: String,
    pub id: Option<u64>,
    pub method: String,
    pub params: Option<Value>,
}

/// MCP Response
#[derive(Debug, Serialize, Deserialize)]
pub struct McpResponse {
    pub jsonrpc: String,
    pub id: Option<u64>,
    pub result: Option<Value>,
    pub error: Option<McpError>,
}

/// MCP Error
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpError {
    pub code: i32,
    pub message: String,
}

impl McpServerManager {
    /// Create new manager
    pub fn new() -> Self {
        Self {
            servers: BTreeMap::new(),
        }
    }
    
    /// Start an MCP server
    pub async fn start_server(
        &mut self,
        name: &str,
        command: &str,
        args: Vec<String>,
        env: BTreeMap<String, String>,
    ) -> Result<(), McpError> {
        let mut cmd = Command::new(command);
        cmd.args(&args)
            .envs(&env)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::null());
        
        let mut child = cmd.spawn()
            .map_err(|e| McpError {
                code: -1,
                message: format!("Failed to start server: {}", e),
            })?;
        
        // Initialize with tools/list request
        let init_request = McpRequest {
            jsonrpc: "2.0".to_string(),
            id: Some(1),
            method: "tools/list".to_string(),
            params: None,
        };
        
        send_request(&mut child, &init_request).await?;
        let response = read_response(&mut child).await?;
        
        let tools = if let Some(result) = response.result {
            result.get("tools")
                .and_then(|t| t.as_array())
                .map(|arr| {
                    arr.iter()
                        .filter_map(|v| serde_json::from_value(v.clone()).ok())
                        .collect()
                })
                .unwrap_or_default()
        } else {
            Vec::new()
        };
        
        let instance = McpServerInstance {
            name: name.to_string(),
            process: child,
            tools,
        };
        
        self.servers.insert(name.to_string(), instance);
        
        Ok(())
    }
    
    /// Stop a server
    pub async fn stop_server(&mut self, name: &str) -> Result<(), McpError> {
        if let Some(mut instance) = self.servers.remove(name) {
            let _ = instance.process.kill().await;
        }
        Ok(())
    }
    
    /// Execute tool on MCP server
    pub async fn execute_tool(
        &mut self,
        server_name: &str,
        tool_name: &str,
        arguments: Value,
    ) -> Result<Value, McpError> {
        let instance = self.servers.get_mut(server_name)
            .ok_or_else(|| McpError {
                code: -32601,
                message: format!("Server not found: {}", server_name),
            })?;
        
        let request = McpRequest {
            jsonrpc: "2.0".to_string(),
            id: Some(3),
            method: "tools/call".to_string(),
            params: Some(serde_json::json!({
                "name": tool_name,
                "arguments": arguments
            })),
        };
        
        send_request(&mut instance.process, &request).await?;
        let response = read_response(&mut instance.process).await?;
        
        if let Some(error) = response.error {
            return Err(error);
        }
        
        response.result.ok_or_else(|| McpError {
            code: -32603,
            message: "No result from tool execution".to_string(),
        })
    }
    
    /// Get all tools from all servers
    pub fn get_all_tools(&self) -> Vec<(String, McpTool)> {
        let mut tools = Vec::new();
        for (server_name, instance) in &self.servers {
            for tool in &instance.tools {
                tools.push((server_name.clone(), tool.clone()));
            }
        }
        tools
    }
    
    /// List running servers
    pub fn list_servers(&self) -> Vec<String> {
        self.servers.keys().cloned().collect()
    }
    
    /// Get all servers with their instances (for adapter integration)
    pub fn get_all_servers(&self) -> &BTreeMap<String, McpServerInstance> {
        &self.servers
    }
}

/// Send request to server (standalone function to avoid borrow issues)
async fn send_request(
    child: &mut Child,
    request: &McpRequest,
) -> Result<(), McpError> {
    let stdin = child.stdin.as_mut()
        .ok_or_else(|| McpError {
            code: -1,
            message: "Server stdin not available".to_string(),
        })?;
    
    let json = serde_json::to_string(request)
        .map_err(|e| McpError {
            code: -32700,
            message: format!("JSON error: {}", e),
        })?;
    
    stdin.write_all(format!("{}\n", json).as_bytes()).await
        .map_err(|e| McpError {
            code: -1,
            message: format!("Write error: {}", e),
        })?;
    
    stdin.flush().await
        .map_err(|e| McpError {
            code: -1,
            message: format!("Flush error: {}", e),
        })?;
    
    Ok(())
}

/// Read response from server (standalone function)
async fn read_response(child: &mut Child) -> Result<McpResponse, McpError> {
    let stdout = child.stdout.as_mut()
        .ok_or_else(|| McpError {
            code: -1,
            message: "Server stdout not available".to_string(),
        })?;
    
    let mut reader = BufReader::new(stdout);
    let mut line = String::new();
    
    tokio::time::timeout(
        std::time::Duration::from_secs(30),
        reader.read_line(&mut line)
    ).await
        .map_err(|_| McpError {
            code: -32603,
            message: "Timeout waiting for response".to_string(),
        })?
        .map_err(|e| McpError {
            code: -1,
            message: format!("Read error: {}", e),
        })?;
    
    serde_json::from_str(&line)
        .map_err(|e| McpError {
            code: -32700,
            message: format!("JSON parse error: {}", e),
        })
}

impl Default for McpServerManager {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mcp_server_manager_new() {
        let manager = McpServerManager::new();
        assert!(manager.list_servers().is_empty());
    }

    #[test]
    fn test_mcp_tool_serialization() {
        let tool = McpTool {
            name: "test".to_string(),
            description: "Test tool".to_string(),
            input_schema: serde_json::json!({}),
        };
        
        let json = serde_json::to_string(&tool).unwrap();
        assert!(json.contains("test"));
    }
}
