//! OpenClaw Parser - Code parsing with Tree-sitter
//! 
//! This crate provides:
//! - Multi-language parsing (Rust, Python, TypeScript, JavaScript)
//! - AST analysis and traversal
//! - Code metrics extraction

pub mod parser;
pub mod ast_analysis;
pub mod queries;
pub mod metrics;

pub use parser::{CodeParser, ParseResult, SupportedLanguage};
pub use ast_analysis::{AstAnalyzer, AstNode};
pub use queries::{QueryEngine, CodePattern};
pub use metrics::{CodeMetrics, FunctionMetrics};
