//! Compaction Tests
//! 
//! Tests for CompactionEngine, MemoryClassifier, and related types

use memory_compaction::{
    CompactionEngine,
    CompactionConfig,
    CompactionResult,
    SimpleSummarizer,
    Summarizer,
    MessageSummary,
    MemoryClassifier,
    Importance,
    ClassifiedMemory,
    ClassificationPatterns,
};