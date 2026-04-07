//! OpenClaw Agents - Multi-Agent System for Code Analysis
//! 
//! This crate provides specialized agents for:
//! - Code analysis (structure, quality, security)
//! - Documentation generation
//! - Refactoring suggestions

pub mod agent;
pub mod orchestrator;
pub mod code_analyzer;
pub mod doc_agent;
pub mod security_agent;
pub mod refactor_agent;

pub use agent::{Agent, AgentConfig, AgentOutput};
pub use orchestrator::{Orchestrator, Workflow};
pub use code_analyzer::CodeAnalyzerAgent;
pub use doc_agent::DocumentationAgent;
pub use security_agent::SecurityAgent;
pub use refactor_agent::RefactorAgent;
