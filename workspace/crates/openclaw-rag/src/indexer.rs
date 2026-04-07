//! Vault indexer - indexes Markdown files into vector database

use crate::{Chunk, MarkdownChunker, PlaceholderEmbeddingModel};
use anyhow::Result;
use std::path::{Path, PathBuf};
use tracing::info;

/// Statistics about the indexing process
#[derive(Debug, Clone)]
pub struct IndexStats {
    pub files_processed: usize,
    pub chunks_created: usize,
    pub errors: usize,
}

impl IndexStats {
    pub fn new() -> Self {
        Self {
            files_processed: 0,
            chunks_created: 0,
            errors: 0,
        }
    }
}

/// Indexes a vault of Markdown files
pub struct VaultIndexer {
    chunker: MarkdownChunker,
    embedding_model: PlaceholderEmbeddingModel,
    db_path: PathBuf,
}

impl VaultIndexer {
    pub fn new(
        chunker: MarkdownChunker,
        db_path: impl Into<PathBuf>,
    ) -> Self {
        Self {
            chunker,
            embedding_model: PlaceholderEmbeddingModel::new(),
            db_path: db_path.into(),
        }
    }
    
    /// Index a single file
    pub async fn index_file(&self, path: &Path) -> Result<Vec<Chunk>> {
        info!("Indexing file: {}", path.display());
        
        let content = tokio::fs::read_to_string(path).await?;
        let chunks = self.chunker.chunk_file(&content, &path.to_string_lossy());
        
        Ok(chunks)
    }
    
    /// Index entire vault directory
    pub async fn index_vault(&self, vault_path: &Path) -> Result<IndexStats> {
        info!("Starting vault indexing: {}", vault_path.display());
        info!("Database path: {}", self.db_path.display());
        
        let mut stats = IndexStats::new();
        
        // Walk directory and find Markdown files
        for entry in walkdir::WalkDir::new(vault_path) {
            let entry = entry?;
            let path = entry.path();
            
            // Skip excluded directories
            if path.to_string_lossy().contains(".git") ||
               path.to_string_lossy().contains(".obsidian") ||
               path.to_string_lossy().contains(".system") {
                continue;
            }
            
            if path.extension().map_or(false, |ext| ext == "md") {
                match self.index_file(path).await {
                    Ok(chunks) => {
                        stats.files_processed += 1;
                        stats.chunks_created += chunks.len();
                        
                        for chunk in &chunks {
                            info!("  Chunk: {} lines from {}", 
                                chunk.line_end - chunk.line_start + 1,
                                chunk.source_path);
                        }
                    }
                    Err(e) => {
                        tracing::warn!("Failed to index {}: {}", path.display(), e);
                        stats.errors += 1;
                    }
                }
            }
        }
        
        info!(
            "Indexing complete: {} files, {} chunks, {} errors",
            stats.files_processed, stats.chunks_created, stats.errors
        );
        
        Ok(stats)
    }
    
    /// Get database path
    pub fn db_path(&self) -> &Path {
        &self.db_path
    }
}
