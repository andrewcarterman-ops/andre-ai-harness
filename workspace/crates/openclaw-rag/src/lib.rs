//! OpenClaw RAG - Retrieval Augmented Generation
//! 
//! This crate provides:
//! - Vault indexing (Markdown files → Chunks)
//! - Placeholder for semantic search with embeddings
//! - Markdown-aware chunking

pub mod chunker;
pub mod embeddings;
pub mod indexer;
pub mod searcher;
pub mod vault;

pub use chunker::{Chunk, MarkdownChunker};
pub use embeddings::{EmbeddingModel, PlaceholderEmbeddingModel};
pub use indexer::{VaultIndexer, IndexStats};
pub use searcher::{VaultSearcher, SearchResult};
pub use vault::{Vault, VaultConfig};
