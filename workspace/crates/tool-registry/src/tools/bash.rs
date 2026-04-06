//! Bash Tool
//! 
//! Execute bash/shell commands

use async_trait::async_trait;
use serde_json::Value;
use tokio::process::Command;
use tokio::time::{timeout, Duration};

use crate::{Tool, ToolOutput, ToolError};

/// Bash command execution tool
pub struct BashTool {
    /// Maximum command timeout
    timeout_secs: u64,
    /// Allowed commands (empty = allow all)
    allowed_commands: Vec<String>,
    /// Blocked commands
    blocked_commands: Vec<String>,
}

impl BashTool {
    /// Create new bash tool with defaults
    pub fn new() -> Self {
        Self {
            timeout_secs: 60,
            allowed_commands: Vec::new(),
            blocked_commands: vec![
                "rm -rf /".to_string(),
                "rm -rf /*".to_string(),
                "mkfs".to_string(),
                "dd if=/dev/zero of=/dev/sda".to_string(),
                "> /dev/sda".to_string(),
                ":(){ :|:& };:".to_string(), // Fork bomb
            ],
        }
    }
    
    /// Set timeout
    pub fn with_timeout(mut self, secs: u64) -> Self {
        self.timeout_secs = secs;
        self
    }
    
    /// Add allowed command
    pub fn allow(mut self, cmd: impl Into<String>) -> Self {
        self.allowed_commands.push(cmd.into());
        self
    }
    
    /// Add blocked command
    pub fn block(mut self, cmd: impl Into<String>) -> Self {
        self.blocked_commands.push(cmd.into());
        self
    }
    
    /// Validate command for safety
    fn validate_command(&self, command: &str) -> Result<(), ToolError> {
        // Check blocked patterns
        for blocked in &self.blocked_commands {
            if command.contains(blocked) {
                return Err(ToolError::PermissionDenied);
            }
        }
        
        // Check dangerous patterns
        let dangerous = [
            "rm -rf /",
            "rm -rf ~",
            "rm -rf $HOME",
            "> /dev/sd",
            "mkfs",
            "format c:",
        ];
        
        let lower = command.to_lowercase();
        for pattern in &dangerous {
            if lower.contains(pattern) {
                return Err(ToolError::PermissionDenied);
            }
        }
        
        Ok(())
    }
}

impl Default for BashTool {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Tool for BashTool {
    fn name(&self) -> &str {
        "bash"
    }
    
    fn description(&self) -> &str {
        "Execute bash commands"
    }
    
    fn parameters_schema(&self) -> Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "command": {
                    "type": "string",
                    "description": "Bash command to execute"
                },
                "timeout": {
                    "type": "integer",
                    "description": "Timeout in seconds (default: 60)",
                    "minimum": 1,
                    "maximum": 300
                },
                "working_dir": {
                    "type": "string",
                    "description": "Working directory for command"
                }
            },
            "required": ["command"]
        })
    }
    
    async fn execute(&self, args: Value) -> Result<ToolOutput, ToolError> {
        let command = args.get("command")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing command".to_string()))?;
        
        // Validate command
        self.validate_command(command)?;
        
        // Get timeout
        let timeout_secs = args.get("timeout")
            .and_then(|v| v.as_u64())
            .map(|v| v.min(300)) // Max 5 minutes
            .unwrap_or(self.timeout_secs);
        
        // Build command
        let mut cmd = Command::new("bash");
        cmd.arg("-c").arg(command);
        
        // Set working directory if specified
        if let Some(dir) = args.get("working_dir").and_then(|v| v.as_str()) {
            cmd.current_dir(dir);
        }
        
        // Execute with timeout
        let result = timeout(
            Duration::from_secs(timeout_secs),
            cmd.output()
        ).await;
        
        match result {
            Ok(Ok(output)) => {
                let stdout = String::from_utf8_lossy(&output.stdout);
                let stderr = String::from_utf8_lossy(&output.stderr);
                
                if output.status.success() {
                    Ok(ToolOutput::success(stdout.to_string()))
                } else {
                    let error_msg = if stderr.is_empty() {
                        format!("Command failed with exit code: {:?}", output.status.code())
                    } else {
                        stderr.to_string()
                    };
                    Ok(ToolOutput::error(error_msg))
                }
            }
            Ok(Err(e)) => {
                Err(ToolError::Execution(e.to_string()))
            }
            Err(_) => {
                Err(ToolError::Timeout)
            }
        }
    }
}

/// PowerShell execution tool (Windows)
pub struct PowerShellTool {
    timeout_secs: u64,
}

impl PowerShellTool {
    /// Create new PowerShell tool
    pub fn new() -> Self {
        Self {
            timeout_secs: 60,
        }
    }
}

impl Default for PowerShellTool {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Tool for PowerShellTool {
    fn name(&self) -> &str {
        "powershell"
    }
    
    fn description(&self) -> &str {
        "Execute PowerShell commands"
    }
    
    fn parameters_schema(&self) -> Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "command": {
                    "type": "string",
                    "description": "PowerShell command to execute"
                },
                "timeout": {
                    "type": "integer",
                    "description": "Timeout in seconds (default: 60)",
                    "minimum": 1,
                    "maximum": 300
                }
            },
            "required": ["command"]
        })
    }
    
    async fn execute(&self, args: Value) -> Result<ToolOutput, ToolError> {
        let command = args.get("command")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing command".to_string()))?;
        
        let timeout_secs = args.get("timeout")
            .and_then(|v| v.as_u64())
            .map(|v| v.min(300))
            .unwrap_or(self.timeout_secs);
        
        let mut cmd = Command::new("powershell");
        cmd.arg("-Command").arg(command);
        
        let result = timeout(
            Duration::from_secs(timeout_secs),
            cmd.output()
        ).await;
        
        match result {
            Ok(Ok(output)) => {
                let stdout = String::from_utf8_lossy(&output.stdout);
                if output.status.success() {
                    Ok(ToolOutput::success(stdout.to_string()))
                } else {
                    let stderr = String::from_utf8_lossy(&output.stderr);
                    Ok(ToolOutput::error(stderr.to_string()))
                }
            }
            Ok(Err(e)) => Err(ToolError::Execution(e.to_string())),
            Err(_) => Err(ToolError::Timeout),
        }
    }
}
