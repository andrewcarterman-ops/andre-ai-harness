//! Code parser using Tree-sitter
//! 
//! Supports multiple languages: Rust, Python, TypeScript, JavaScript

use anyhow::{Result, anyhow};
use tree_sitter::{Parser, Tree, Language};

/// Supported programming languages
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SupportedLanguage {
    Rust,
    Python,
    TypeScript,
    JavaScript,
}

impl SupportedLanguage {
    /// Get the tree-sitter language
    pub fn language(&self) -> Language {
        match self {
            SupportedLanguage::Rust => tree_sitter_rust::LANGUAGE.into(),
            SupportedLanguage::Python => tree_sitter_python::LANGUAGE.into(),
            SupportedLanguage::TypeScript => tree_sitter_typescript::LANGUAGE_TYPESCRIPT.into(),
            SupportedLanguage::JavaScript => tree_sitter_javascript::LANGUAGE.into(),
        }
    }
    
    /// Detect language from file extension
    pub fn from_extension(ext: &str) -> Option<Self> {
        match ext.to_lowercase().as_str() {
            "rs" => Some(Self::Rust),
            "py" => Some(Self::Python),
            "ts" => Some(Self::TypeScript),
            "tsx" => Some(Self::TypeScript),
            "js" => Some(Self::JavaScript),
            "jsx" => Some(Self::JavaScript),
            _ => None,
        }
    }
}

/// Result of parsing a file
#[derive(Debug)]
pub struct ParseResult {
    pub tree: Tree,
    pub language: SupportedLanguage,
    pub source: String,
}

/// Code parser for multiple languages
pub struct CodeParser {
    parsers: std::collections::HashMap<SupportedLanguage, Parser>,
}

impl CodeParser {
    pub fn new() -> Result<Self> {
        let mut parsers = std::collections::HashMap::new();
        
        // Initialize parsers for each language
        for lang in [SupportedLanguage::Rust, SupportedLanguage::Python, 
                     SupportedLanguage::TypeScript, SupportedLanguage::JavaScript] {
            let mut parser = Parser::new();
            parser.set_language(&lang.language())?;
            parsers.insert(lang, parser);
        }
        
        Ok(Self { parsers })
    }
    
    /// Parse source code
    pub fn parse(&mut self, source: &str, language: SupportedLanguage) -> Result<ParseResult> {
        let parser = self.parsers.get_mut(&language)
            .ok_or_else(|| anyhow!("Parser for {:?} not initialized", language))?;
        
        let tree = parser.parse(source, None)
            .ok_or_else(|| anyhow!("Failed to parse source"))?;
        
        Ok(ParseResult {
            tree,
            language,
            source: source.to_string(),
        })
    }
    
    /// Parse a file by path (auto-detect language)
    pub fn parse_file(&mut self, path: &std::path::Path) -> Result<ParseResult> {
        let ext = path.extension()
            .and_then(|e| e.to_str())
            .ok_or_else(|| anyhow!("Could not determine file extension"))?;
        
        let language = SupportedLanguage::from_extension(ext)
            .ok_or_else(|| anyhow!("Unsupported file extension: {}", ext))?;
        
        let source = std::fs::read_to_string(path)?;
        self.parse(&source, language)
    }
}
