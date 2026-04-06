//! Tool Registry
//! 
//! Central registry for all available tools

use std::collections::HashMap;
use std::sync::Arc;
use crate::{Tool, ToolDefinition, ToolOutput, ToolError};
use crate::tools::{ReadFileTool, WriteFileTool, EditFileTool, GlobTool, GrepTool, BashTool, PowerShellTool};
use serde_json::Value;

/// Tool registry - manages all available tools
pub struct ToolRegistry {
    tools: HashMap<String, Arc<dyn Tool>>,
}

impl ToolRegistry {
    /// Create new empty registry
    pub fn new() -> Self {
        Self {
            tools: HashMap::new(),
        }
    }
    
    /// Create registry with default tools
    pub fn with_defaults() -> Self {
        let mut registry = Self::new();
        registry.register_defaults();
        registry
    }
    
    /// Register default tools
    fn register_defaults(&mut self) {
        // File operations
        self.register(Arc::new(ReadFileTool));
        self.register(Arc::new(WriteFileTool));
        self.register(Arc::new(EditFileTool));
        self.register(Arc::new(GlobTool));
        self.register(Arc::new(GrepTool));
        
        // Shell execution
        self.register(Arc::new(BashTool::new()));
        self.register(Arc::new(PowerShellTool::new()));
    }
    
    /// Register a tool
    pub fn register(&mut self, tool: Arc<dyn Tool>) {
        let name = tool.name().to_string();
        self.tools.insert(name, tool);
    }
    
    /// Get a tool by name
    pub fn get(&self, name: &str) -> Option<Arc<dyn Tool>> {
        self.tools.get(name).cloned()
    }
    
    /// Check if tool exists
    pub fn has(&self, name: &str) -> bool {
        self.tools.contains_key(name)
    }
    
    /// Execute a tool by name
    pub async fn execute(&self, name: &str, args: Value) -> Result<ToolOutput, ToolError> {
        let tool = self.get(name)
            .ok_or_else(|| ToolError::NotFound(name.to_string()))?;
        
        tool.execute(args).await
    }
    
    /// Get all tool definitions (for LLM)
    pub fn get_definitions(&self) -> Vec<ToolDefinition> {
        self.tools.values()
            .map(|tool| ToolDefinition::new(
                tool.name(),
                tool.description(),
                tool.parameters_schema()
            ))
            .collect()
    }
    
    /// List all tool names
    pub fn list_tools(&self) -> Vec<String> {
        self.tools.keys().cloned().collect()
    }
    
    /// Get tool count
    pub fn count(&self) -> usize {
        self.tools.len()
    }
}

impl Default for ToolRegistry {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use async_trait::async_trait;
    use serde_json::json;
    
    struct MockTool;
    
    #[async_trait]
    impl Tool for MockTool {
        fn name(&self) -> &str {
            "mock"
        }
        
        fn description(&self) -> &str {
            "A mock tool for testing"
        }
        
        fn parameters_schema(&self) -> Value {
            json!({
                "type": "object",
                "properties": {}
            })
        }
        
        async fn execute(&self, _args: Value) -> Result<ToolOutput, ToolError> {
            Ok(ToolOutput::success("mock result"))
        }
    }
    
    #[test]
    fn test_registry_new() {
        let registry = ToolRegistry::new();
        assert_eq!(registry.count(), 0);
    }
    
    #[test]
    fn test_registry_with_defaults() {
        let registry = ToolRegistry::with_defaults();
        assert_eq!(registry.count(), 7); // 5 file ops + 2 shell
        assert!(registry.has("read_file"));
        assert!(registry.has("bash"));
    }
    
    #[test]
    fn test_registry_register() {
        let mut registry = ToolRegistry::new();
        registry.register(Arc::new(MockTool));
        
        assert_eq!(registry.count(), 1);
        assert!(registry.has("mock"));
    }
    
    #[test]
    fn test_registry_get() {
        let mut registry = ToolRegistry::new();
        registry.register(Arc::new(MockTool));
        
        let tool = registry.get("mock");
        assert!(tool.is_some());
        assert_eq!(tool.unwrap().name(), "mock");
    }
    
    #[test]
    fn test_registry_get_definitions() {
        let mut registry = ToolRegistry::new();
        registry.register(Arc::new(MockTool));
        
        let defs = registry.get_definitions();
        assert_eq!(defs.len(), 1);
        assert_eq!(defs[0].name, "mock");
    }
    
    #[tokio::test]
    async fn test_registry_execute() {
        let mut registry = ToolRegistry::new();
        registry.register(Arc::new(MockTool));
        
        let result = registry.execute("mock", json!({})).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap().content, "mock result");
    }
    
    #[tokio::test]
    async fn test_registry_execute_not_found() {
        let registry = ToolRegistry::new();
        
        let result = registry.execute("nonexistent", json!({})).await;
        assert!(result.is_err());
    }
}
