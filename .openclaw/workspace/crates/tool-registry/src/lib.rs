//! Tool Registry
//! 
//! Tool trait system and registry for file operations, bash execution, etc.
//! Extracted from claw-code/rust/crates/tools/src/lib.rs

pub mod tool;
pub mod registry;
pub mod tools;

pub use tool::{Tool, ToolDefinition, ToolOutput, ToolError};
pub use registry::ToolRegistry;
pub use tools::{
    ReadFileTool, WriteFileTool, EditFileTool, GlobTool, GrepTool,
    BashTool, PowerShellTool,
};

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
