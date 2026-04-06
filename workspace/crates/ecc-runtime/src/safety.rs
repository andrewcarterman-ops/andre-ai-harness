//! Safety Guard for ECC Runtime
//! 
//! Fort Knox integration - validates all operations for security

use std::path::{Path, PathBuf};
use serde_json::Value;
use async_trait::async_trait;

/// Safety violation types
#[derive(Debug, Clone)]
pub enum SafetyViolation {
    InvalidPath(String),
    BlockedPath(String),
    PathOutsideSandbox,
    InvalidUrl(String),
    DomainNotAllowed(String),
    DangerousCommand(String),
    CriticalRiskTool(String),
    PermissionDenied(String),
    Other(String),
}

impl std::fmt::Display for SafetyViolation {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::InvalidPath(p) => write!(f, "Invalid path: {}", p),
            Self::BlockedPath(p) => write!(f, "Blocked path: {}", p),
            Self::PathOutsideSandbox => write!(f, "Path outside sandbox"),
            Self::InvalidUrl(u) => write!(f, "Invalid URL: {}", u),
            Self::DomainNotAllowed(d) => write!(f, "Domain not allowed: {}", d),
            Self::DangerousCommand(c) => write!(f, "Dangerous command: {}", c),
            Self::CriticalRiskTool(t) => write!(f, "Critical risk tool: {}", t),
            Self::PermissionDenied(p) => write!(f, "Permission denied: {}", p),
            Self::Other(s) => write!(f, "Safety violation: {}", s),
        }
    }
}

impl std::error::Error for SafetyViolation {}

/// Safety guard trait
#[async_trait]
pub trait SafetyGuard: Send + Sync {
    /// Validate user input
    async fn validate_input(&self, input: &str) -> Result<(), SafetyViolation>;

    /// Validate tool call before execution
    async fn validate_tool_call(&self, tool: &str, args: &Value) -> Result<(), SafetyViolation>;

    /// Validate file access path
    fn validate_file_access(&self, path: &Path) -> Result<(), SafetyViolation>;

    /// Validate file write path
    fn validate_file_write(&self, path: &Path) -> Result<(), SafetyViolation>;

    /// Validate network request URL
    fn validate_network_request(&self, url: &str) -> Result<(), SafetyViolation>;

    /// Validate command execution
    fn validate_command(&self, command: &str) -> Result<(), SafetyViolation>;

    /// Log security event
    async fn log_event(&self, event: SecurityEvent);
}

/// Security event for audit logging
#[derive(Debug, Clone)]
pub struct SecurityEvent {
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub event_type: SecurityEventType,
    pub tool: Option<String>,
    pub details: String,
}

/// Security event types
#[derive(Debug, Clone)]
pub enum SecurityEventType {
    BlockedToolCall,
    BlockedFileAccess,
    BlockedNetworkRequest,
    BlockedCommand,
    ValidationPassed,
    ValidationFailed,
}

/// Fort Knox implementation of SafetyGuard
pub struct FortKnoxGuard {
    /// Allowed paths for file operations
    allowed_paths: Vec<PathBuf>,
    /// Blocked paths (overrides allowed)
    blocked_paths: Vec<PathBuf>,
    /// Allowed domains for network requests
    allowed_domains: Vec<String>,
    /// Blocked commands/patterns
    blocked_commands: Vec<String>,
    /// Audit logger
    audit_logger: Option<Box<dyn AuditLoggerTrait>>,
}

/// Trait for audit logger
#[async_trait]
pub trait AuditLoggerTrait: Send + Sync {
    async fn log(&self, event: SecurityEvent);
}

impl FortKnoxGuard {
    /// Create new Fort Knox guard
    pub fn new() -> Self {
        Self {
            allowed_paths: vec![PathBuf::from(".")],
            blocked_paths: vec![
                PathBuf::from("/etc/shadow"),
                PathBuf::from("/etc/passwd"),
                PathBuf::from("/etc/ssh"),
                PathBuf::from("~/.ssh/id_rsa"),
                PathBuf::from("~/.ssh/id_ed25519"),
            ],
            allowed_domains: vec![
                "api.anthropic.com".to_string(),
                "platform.claude.com".to_string(),
            ],
            blocked_commands: vec![
                "rm -rf /".to_string(),
                "rm -rf /*".to_string(),
                "mkfs".to_string(),
                "dd if=/dev/zero".to_string(),
                "curl | sh".to_string(),
            ],
            audit_logger: None,
        }
    }

    /// Add allowed path
    pub fn allow_path(mut self, path: impl Into<PathBuf>) -> Self {
        self.allowed_paths.push(path.into());
        self
    }

    /// Add blocked path
    pub fn block_path(mut self, path: impl Into<PathBuf>) -> Self {
        self.blocked_paths.push(path.into());
        self
    }

    /// Add allowed domain
    pub fn allow_domain(mut self, domain: impl Into<String>) -> Self {
        self.allowed_domains.push(domain.into());
        self
    }

    /// Add blocked command pattern
    pub fn block_command(mut self, pattern: impl Into<String>) -> Self {
        self.blocked_commands.push(pattern.into());
        self
    }

    /// Set audit logger
    pub fn with_audit_logger(mut self, logger: Box<dyn AuditLoggerTrait>) -> Self {
        self.audit_logger = Some(logger);
        self
    }

    /// Check if path is allowed
    fn is_path_allowed(&self, path: &Path) -> Result<(), SafetyViolation> {
        // Check blocked paths first
        for blocked in &self.blocked_paths {
            if path.starts_with(blocked) || path.to_string_lossy().contains(blocked.to_str().unwrap_or("")) {
                return Err(SafetyViolation::BlockedPath(path.display().to_string()));
            }
        }

        // Check sensitive patterns
        let path_str = path.to_string_lossy().to_lowercase();
        let sensitive_patterns = [
            ".ssh/id_rsa",
            ".ssh/id_ed25519",
            ".env",
            "credentials",
            "password",
            "secret",
        ];

        for pattern in &sensitive_patterns {
            if path_str.contains(pattern) {
                return Err(SafetyViolation::BlockedPath(format!(
                    "{} (contains sensitive pattern: {})",
                    path.display(),
                    pattern
                )));
            }
        }

        // Check if within allowed paths
        let canonical = path.canonicalize().map_err(|_| {
            SafetyViolation::InvalidPath(path.display().to_string())
        })?;

        for allowed in &self.allowed_paths {
            let allowed_canonical = allowed.canonicalize().unwrap_or_else(|_| allowed.clone());
            if canonical.starts_with(&allowed_canonical) {
                return Ok(());
            }
        }

        Err(SafetyViolation::PathOutsideSandbox)
    }

    /// Check if command is allowed
    fn is_command_allowed(&self, command: &str) -> Result<(), SafetyViolation> {
        let lower = command.to_lowercase();

        // Check blocked patterns
        for blocked in &self.blocked_commands {
            if lower.contains(blocked) {
                return Err(SafetyViolation::DangerousCommand(command.to_string()));
            }
        }

        // Check dangerous patterns
        let dangerous = [
            "rm -rf /",
            "rm -rf /*",
            "rm -rf ~",
            "rm -rf $home",
            "> /dev/sda",
            "mkfs",
            "curl | sh",
            "wget | sh",
            "curl ... | sh",
            "wget ... | bash",
        ];

        for pattern in &dangerous {
            if lower.contains(pattern) {
                return Err(SafetyViolation::DangerousCommand(command.to_string()));
            }
        }

        Ok(())
    }

    /// Check if domain is allowed
    fn is_domain_allowed(&self, url: &str) -> Result<(), SafetyViolation> {
        // Parse URL
        let parsed = url::Url::parse(url).map_err(|_| {
            SafetyViolation::InvalidUrl(url.to_string())
        })?;

        let host = parsed.host_str().ok_or_else(|| {
            SafetyViolation::InvalidUrl(url.to_string())
        })?;

        // Check file:// URLs
        if parsed.scheme() == "file" {
            return Err(SafetyViolation::InvalidUrl(
                "file:// URLs are not allowed".to_string()
            ));
        }

        // Check allowed domains
        for allowed in &self.allowed_domains {
            if host == allowed || host.ends_with(&format!(".{}", allowed)) {
                return Ok(());
            }
        }

        Err(SafetyViolation::DomainNotAllowed(host.to_string()))
    }
}

#[async_trait]
impl SafetyGuard for FortKnoxGuard {
    async fn validate_input(&self, input: &str) -> Result<(), SafetyViolation> {
        // Check for injection attempts
        let suspicious = [
            "<script",
            "javascript:",
            "data:text/html",
            "onerror=",
            "onload=",
        ];

        let lower = input.to_lowercase();
        for pattern in &suspicious {
            if lower.contains(pattern) {
                return Err(SafetyViolation::Other(format!(
                    "Suspicious input pattern detected: {}",
                    pattern
                )));
            }
        }

        Ok(())
    }

    async fn validate_tool_call(&self, tool: &str, args: &Value) -> Result<(), SafetyViolation> {
        match tool {
            "bash" | "shell" | "command" | "powershell" | "cmd" => {
                let cmd = args.get("command")
                    .and_then(|v| v.as_str())
                    .unwrap_or("");
                self.is_command_allowed(cmd)?;
            }
            "write" | "write_file" | "edit" | "edit_file" => {
                let path = args.get("path")
                    .or_else(|| args.get("file_path"))
                    .and_then(|v| v.as_str())
                    .unwrap_or("");
                self.is_path_allowed(Path::new(path))?;
            }
            "read" | "read_file" | "view" | "view_file" => {
                let path = args.get("path")
                    .and_then(|v| v.as_str())
                    .unwrap_or("");
                self.is_path_allowed(Path::new(path))?;
            }
            "web_fetch" | "fetch" | "curl" => {
                let url = args.get("url")
                    .and_then(|v| v.as_str())
                    .unwrap_or("");
                self.is_domain_allowed(url)?;
            }
            "repl" | "python" | "node" | "eval" => {
                return Err(SafetyViolation::CriticalRiskTool(tool.to_string()));
            }
            _ => {}
        }

        // Log validation success
        if let Some(logger) = &self.audit_logger {
            logger.log(SecurityEvent {
                timestamp: chrono::Utc::now(),
                event_type: SecurityEventType::ValidationPassed,
                tool: Some(tool.to_string()),
                details: format!("Tool call validated: {}", tool),
            }).await;
        }

        Ok(())
    }

    fn validate_file_access(&self, path: &Path) -> Result<(), SafetyViolation> {
        self.is_path_allowed(path)
    }

    fn validate_file_write(&self, path: &Path) -> Result<(), SafetyViolation> {
        self.is_path_allowed(path)
    }

    fn validate_network_request(&self, url: &str) -> Result<(), SafetyViolation> {
        self.is_domain_allowed(url)
    }

    fn validate_command(&self, command: &str) -> Result<(), SafetyViolation> {
        self.is_command_allowed(command)
    }

    async fn log_event(&self, event: SecurityEvent) {
        if let Some(logger) = &self.audit_logger {
            logger.log(event).await;
        }
    }
}

impl Default for FortKnoxGuard {
    fn default() -> Self {
        Self::new()
    }
}

/// No-op safety guard (for testing)
pub struct NoOpSafetyGuard;

#[async_trait]
impl SafetyGuard for NoOpSafetyGuard {
    async fn validate_input(&self, _input: &str) -> Result<(), SafetyViolation> {
        Ok(())
    }

    async fn validate_tool_call(&self, _tool: &str, _args: &Value) -> Result<(), SafetyViolation> {
        Ok(())
    }

    fn validate_file_access(&self, _path: &Path) -> Result<(), SafetyViolation> {
        Ok(())
    }

    fn validate_file_write(&self, _path: &Path) -> Result<(), SafetyViolation> {
        Ok(())
    }

    fn validate_network_request(&self, _url: &str) -> Result<(), SafetyViolation> {
        Ok(())
    }

    fn validate_command(&self, _command: &str) -> Result<(), SafetyViolation> {
        Ok(())
    }

    async fn log_event(&self, _event: SecurityEvent) {
        // No-op
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fort_knox_blocks_dangerous_command() {
        let guard = FortKnoxGuard::new();
        let result = guard.validate_command("rm -rf /");
        assert!(result.is_err());
    }

    #[test]
    fn test_fort_knox_allows_safe_command() {
        let guard = FortKnoxGuard::new();
        let result = guard.validate_command("ls -la");
        assert!(result.is_ok());
    }

    #[test]
    fn test_fort_knox_blocks_file_url() {
        let guard = FortKnoxGuard::new();
        let result = guard.validate_network_request("file:///etc/passwd");
        assert!(result.is_err());
    }
}
