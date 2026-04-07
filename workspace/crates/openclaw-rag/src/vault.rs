//! Vault configuration and management

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Vault configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VaultConfig {
    pub path: PathBuf,
    pub exclude_patterns: Vec<String>,
    pub max_file_size: usize,
}

impl Default for VaultConfig {
    fn default() -> Self {
        Self {
            path: PathBuf::from("."),
            exclude_patterns: vec![
                ".git".to_string(),
                ".obsidian".to_string(),
                ".system".to_string(),
            ],
            max_file_size: 10 * 1024 * 1024, // 10 MB
        }
    }
}

/// Represents an Obsidian vault
pub struct Vault {
    config: VaultConfig,
}

impl Vault {
    pub fn new(config: VaultConfig) -> Self {
        Self { config }
    }
    
    pub fn config(&self) -> &VaultConfig {
        &self.config
    }
    
    /// Check if a path should be excluded
    pub fn should_exclude(&self, path: &std::path::Path) -> bool {
        let path_str = path.to_string_lossy();
        self.config.exclude_patterns.iter().any(|pattern| {
            path_str.contains(pattern)
        })
    }
}
