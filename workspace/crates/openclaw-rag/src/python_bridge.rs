//! Python Bridge for BGE-M3 Embeddings
//! 
//! Uses pyo3 to call Python's BGE-M3 model for generating embeddings.

use anyhow::{Result, anyhow};

/// Generate embeddings using Python BGE-M3 model
/// 
/// This function calls Python code to generate embeddings.
/// Requires: pip install FlagEmbedding
pub fn generate_embeddings_bge_m3(texts: Vec<String>) -> Result<Vec<Vec<f32>>> {
    pyo3::prepare_freethreaded_python();
    
    Python::with_gil(|py| {
        // Import FlagEmbedding
        let flag_embedding = py.import("FlagEmbedding")?;
        let bgem3 = flag_embedding.getattr("BGEM3FlagModel")?;
        
        // Initialize model (downloads on first run)
        let model = bgem3.call1(("BAAI/bge-m3",))?;
        
        // Generate embeddings
        let embeddings = model.call_method1(
            "encode",
            (texts,),
            Some(&[("batch_size", 12), ("max_length", 8192)])
        )?;
        
        // Convert Python array to Rust Vec<Vec<f32>>
        let embeddings: Vec<Vec<f32>> = embeddings.extract()?;
        
        Ok(embeddings)
    }).map_err(|e: PyErr| anyhow!("Python error: {}", e))
}

use pyo3::prelude::*;
use pyo3::types::PyList;

/// Check if Python BGE-M3 is available
pub fn check_bge_m3_available() -> bool {
    pyo3::prepare_freethreaded_python();
    
    Python::with_gil(|py| {
        py.import("FlagEmbedding").is_ok()
    })
}

/// Get embedding dimension for BGE-M3
pub const BGE_M3_DIMENSION: usize = 1024;
