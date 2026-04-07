//! OpenClaw RAG - Retrieval Augmented Generation
//! 
//! This crate provides:
//! - Vault indexing (Markdown files → Vector DB)
//! - Semantic search with embeddings
//! - Markdown-aware chunking
//! - Python Bridge for BGE-M3 embeddings (optional feature)

pub mod chunker;
pub mod embeddings;
pub mod indexer;
pub mod searcher;
pub mod vault;

// Python Bridge für BGE-M3 (nur mit feature "python-embeddings")
#[cfg(feature = "python-embeddings")]
pub mod python_bridge;

pub use chunker::{Chunk, MarkdownChunker};
pub use embeddings::{EmbeddingModel, PlaceholderEmbeddingModel};
pub use indexer::{VaultIndexer, IndexStats};
pub use searcher::{VaultSearcher, SearchResult};
pub use vault::{Vault, VaultConfig};

// Re-export Python Bridge wenn aktiviert
#[cfg(feature = "python-embeddings")]
pub use python_bridge::{generate_embeddings_bge_m3, check_bge_m3_available, BGE_M3_DIMENSION};
