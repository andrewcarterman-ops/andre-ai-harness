//! Memory Compaction Engine
//! 
//! Session compaction with ECC Second Brain integration
//! Extracted from claw-code/rust/crates/runtime/src/compact.rs

pub mod compactor;
pub mod classifier;
pub mod obsidian_sync;
pub mod memory_md;
pub mod sync_pipeline;

pub use compactor::{
    CompactionEngine,
    CompactionConfig,
    CompactionResult,
    CompactionError,
    Summarizer,
    SimpleSummarizer,
    MessageSummary,
    CompactionRecord,
};
pub use classifier::{
    MemoryClassifier,
    Importance,
    ClassifiedMemory,
    ClassificationPatterns,
};
pub use obsidian_sync::{ObsidianSync, MemoryEntry};
pub use memory_md::MemoryMdUpdater;
pub use sync_pipeline::{
    SyncPipeline,
    SyncConfig,
    SyncResult,
    SyncMessage,
};

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
