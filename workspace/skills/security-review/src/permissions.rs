//! Permission Policy Framework
//! 
//! Extracted from claw-code/rust/crates/runtime/src/permissions.rs
//! Integrated with OpenClaw Security Review Skill

use std::collections::BTreeMap;
use serde_json::Value;
use async_trait::async_trait;

/// Three-tier permission mode
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PermissionMode {
    /// Execute without prompting
    Allow,
    /// Always reject
    Deny,
    /// Ask user for confirmation
    Prompt,
}

impl PermissionMode {
    /// Parse from string
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "allow" | "allowed" | "yes" | "true" => Some(Self::Allow),
            "deny" | "denied" | "no" | "false" => Some(Self::Deny),
            "prompt" | "ask" => Some(Self::Prompt),
            _ => None,
        }
    }

    /// Convert to string
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Allow => "allow",
            Self::Deny => "deny",
            Self::Prompt => "prompt",
        }
    }

    /// Check if this mode allows execution
    pub fn is_allowed(&self) -> bool {
        matches!(self, Self::Allow)
    }

    /// Check if this mode requires prompting
    pub fn requires_prompt(&self) -> bool {
        matches!(self, Self::Prompt)
    }
}

impl Default for PermissionMode {
    fn default() -> Self {
        Self::Prompt
    }
}

/// Permission policy with tool overrides
#[derive(Debug, Clone)]
pub struct PermissionPolicy {
    pub default_mode: PermissionMode,
    pub tool_overrides: BTreeMap<String, PermissionMode>,
}

impl PermissionPolicy {
    /// Create new policy with default mode
    pub fn new(default_mode: PermissionMode) -> Self {
        Self {
            default_mode,
            tool_overrides: BTreeMap::new(),
        }
    }

    /// Create default policy (Prompt mode)
    pub fn default_policy() -> Self {
        Self::new(PermissionMode::Prompt)
    }

    /// Create restrictive policy (Deny mode)
    pub fn restrictive() -> Self {
        Self::new(PermissionMode::Deny)
    }

    /// Create permissive policy (Allow mode)
    pub fn permissive() -> Self {
        Self::new(PermissionMode::Allow)
        .with_override("bash", PermissionMode::Prompt)
        .with_override("powershell", PermissionMode::Prompt)
        .with_override("write", PermissionMode::Prompt)
        .with_override("edit", PermissionMode::Prompt)
    }

    /// Add tool override
    pub fn with_override(mut self, tool: impl Into<String>, mode: PermissionMode) -> Self {
        self.tool_overrides.insert(tool.into(), mode);
        self
    }

    /// Set override for a tool
    pub fn set_override(&mut self, tool: impl Into<String>, mode: PermissionMode) {
        self.tool_overrides.insert(tool.into(), mode);
    }

    /// Resolve permission for a tool
    pub fn resolve(&self, tool_name: &str) -> PermissionMode {
        self.tool_overrides
            .get(tool_name)
            .copied()
            .unwrap_or(self.default_mode)
    }

    /// Check if tool is allowed
    pub fn is_allowed(&self, tool_name: &str) -> bool {
        self.resolve(tool_name).is_allowed()
    }

    /// Check if tool requires prompt
    pub fn requires_prompt(&self, tool_name: &str) -> bool {
        self.resolve(tool_name).requires_prompt()
    }

    /// Remove override for a tool
    pub fn remove_override(&mut self, tool: &str) {
        self.tool_overrides.remove(tool);
    }

    /// Get all tool overrides
    pub fn overrides(&self) -> &BTreeMap<String, PermissionMode> {
        &self.tool_overrides
    }

    /// Clear all overrides
    pub fn clear_overrides(&mut self) {
        self.tool_overrides.clear();
    }
}

impl Default for PermissionPolicy {
    fn default() -> Self {
        Self::default_policy()
    }
}

/// Permission response from user
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PermissionResponse {
    Allow,
    Deny,
    AllowOnce,
    DenyOnce,
}

impl PermissionResponse {
    /// Check if this response allows execution
    pub fn is_allowed(&self) -> bool {
        matches!(self, Self::Allow | Self::AllowOnce)
    }

    /// Check if this response should persist
    pub fn is_persistent(&self) -> bool {
        matches!(self, Self::Allow | Self::Deny)
    }

    /// Convert to mode if persistent
    pub fn to_mode(&self) -> Option<PermissionMode> {
        match self {
            Self::Allow => Some(PermissionMode::Allow),
            Self::Deny => Some(PermissionMode::Deny),
            _ => None,
        }
    }
}

/// Trait for permission prompters
#[async_trait]
pub trait PermissionPrompter: Send + Sync {
    /// Prompt user for permission
    async fn prompt(
        &self,
        tool: &str,
        args: &Value,
    ) -> Result<PermissionResponse, PromptError>;
}

/// Prompt errors
#[derive(Debug, Clone)]
pub enum PromptError {
    Cancelled,
    Timeout,
    InvalidInput(String),
    IoError(String),
}

impl std::fmt::Display for PromptError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Cancelled => write!(f, "User cancelled prompt"),
            Self::Timeout => write!(f, "Prompt timed out"),
            Self::InvalidInput(msg) => write!(f, "Invalid input: {}", msg),
            Self::IoError(msg) => write!(f, "IO error: {}", msg),
        }
    }
}

impl std::error::Error for PromptError {}

/// Console-based permission prompter
pub struct ConsolePrompter {
    timeout_secs: u64,
}

impl ConsolePrompter {
    pub fn new() -> Self {
        Self { timeout_secs: 60 }
    }

    pub fn with_timeout(timeout_secs: u64) -> Self {
        Self { timeout_secs }
    }
}

impl Default for ConsolePrompter {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl PermissionPrompter for ConsolePrompter {
    async fn prompt(
        &self,
        tool: &str,
        args: &Value,
    ) -> Result<PermissionResponse, PromptError> {
        println!("\n╔══════════════════════════════════════════════════════════╗");
        println!("║  Permission Required                                     ║");
        println!("╠══════════════════════════════════════════════════════════╣");
        println!("║  Tool: {:<48} ║", tool);
        
        // Format args nicely
        let args_str = serde_json::to_string_pretty(args)
            .unwrap_or_else(|_| args.to_string());
        
        for line in args_str.lines().take(10) {
            let truncated = if line.len() > 56 {
                format!("{}...", &line[..53])
            } else {
                line.to_string()
            };
            println!("║  Args: {:<48} ║", truncated);
        }
        if args_str.lines().count() > 10 {
            println!("║  Args: ... ({:<3} more lines)                      ║", 
                args_str.lines().count() - 10);
        }
        
        println!("╠══════════════════════════════════════════════════════════╣");
        println!("║  [Y] Allow  [N] Deny  [A] Allow Always  [D] Deny Always  ║");
        println!("╚══════════════════════════════════════════════════════════╝");
        print!("Choice: ");
        
        // For now, return AllowOnce as default
        // In real implementation, this would read from stdin
        Ok(PermissionResponse::AllowOnce)
    }
}

/// Permission decision after evaluation
#[derive(Debug, Clone)]
pub enum PermissionDecision {
    Allow,
    Deny,
    Prompt,
}

impl PermissionDecision {
    pub fn is_allowed(&self) -> bool {
        matches!(self, Self::Allow)
    }
}

/// Permission event for audit logging
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct PermissionEvent {
    pub timestamp: String,
    pub tool: String,
    pub action: PermissionAction,
    pub context: Option<String>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub enum PermissionAction {
    Allowed { auto_allowed: bool },
    Denied { reason: String },
    Prompted { user_response: String },
    OverrideSet { mode: String },
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_permission_mode_from_str() {
        assert_eq!(PermissionMode::from_str("allow"), Some(PermissionMode::Allow));
        assert_eq!(PermissionMode::from_str("deny"), Some(PermissionMode::Deny));
        assert_eq!(PermissionMode::from_str("prompt"), Some(PermissionMode::Prompt));
        assert_eq!(PermissionMode::from_str("unknown"), None);
    }

    #[test]
    fn test_permission_policy_resolve() {
        let policy = PermissionPolicy::new(PermissionMode::Deny)
            .with_override("read", PermissionMode::Allow)
            .with_override("bash", PermissionMode::Prompt);

        assert_eq!(policy.resolve("read"), PermissionMode::Allow);
        assert_eq!(policy.resolve("bash"), PermissionMode::Prompt);
        assert_eq!(policy.resolve("write"), PermissionMode::Deny);
    }

    #[test]
    fn test_permission_policy_permissive() {
        let policy = PermissionPolicy::permissive();
        
        assert_eq!(policy.default_mode, PermissionMode::Allow);
        assert_eq!(policy.resolve("bash"), PermissionMode::Prompt);
        assert_eq!(policy.resolve("unknown_tool"), PermissionMode::Allow);
    }

    #[test]
    fn test_permission_response() {
        assert!(PermissionResponse::Allow.is_allowed());
        assert!(PermissionResponse::AllowOnce.is_allowed());
        assert!(!PermissionResponse::Deny.is_allowed());
        assert!(!PermissionResponse::DenyOnce.is_allowed());

        assert!(PermissionResponse::Allow.is_persistent());
        assert!(!PermissionResponse::AllowOnce.is_persistent());
    }

    #[test]
    fn test_permission_mode_is_allowed() {
        assert!(PermissionMode::Allow.is_allowed());
        assert!(!PermissionMode::Deny.is_allowed());
        assert!(!PermissionMode::Prompt.is_allowed());
    }
}
