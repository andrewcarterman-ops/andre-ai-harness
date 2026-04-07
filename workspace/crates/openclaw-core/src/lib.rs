//! OpenClaw Core - Atomic file operations and state management
//! 
//! Provides safe, atomic file operations with backup and recovery.

pub mod atomic;
pub mod state;

// Re-exports from atomic module - prüfe welche Funktionen existieren
pub use atomic::atomic_write;

// Re-exports from state module
pub use state::{
    Session, SessionFrontmatter, SessionManager, SessionStatus,
};
