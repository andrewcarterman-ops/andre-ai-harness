//! Security Review Skill
//! 
//! Security analysis skill with permission framework, risk analysis,
//! and audit logging. Integrated with claw-code patterns.

pub mod permissions;
pub mod risk_analyzer;
pub mod audit_logger;

pub use permissions::{
    PermissionMode,
    PermissionPolicy,
    PermissionResponse,
    PermissionPrompter,
    PermissionDecision,
    ConsolePrompter,
    PermissionEvent,
    PermissionAction,
    PromptError,
};

pub use risk_analyzer::{
    RiskScore,
    RiskAnalyzer,
    RiskBasedDecision,
    PatternMatcher,
};

pub use audit_logger::{
    AuditLogger,
    AuditStats,
    AuditError,
};

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
