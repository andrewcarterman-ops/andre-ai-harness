//! Bridge modules for external integrations
//! 
//! Provides bridges to:
//! - Obsidian (Second Brain sync)
//! - Knowledge stores
//! - External APIs

pub mod obsidian;

pub use obsidian::{
    ObsidianBridge,
    ObsidianConfig,
    SyncSettings,
    SyncMode,
    DirectoryMapping,
    ObsidianBridgeError,
    SyncResult,
    ConflictStrategy,
};
