//! AST analysis and traversal

use tree_sitter::TreeCursor;
use crate::SupportedLanguage;

/// Represents an AST node with metadata
#[derive(Debug, Clone)]
pub struct AstNode {
    pub kind: String,
    pub start_line: usize,
    pub end_line: usize,
    pub text: String,
    pub children: Vec<AstNode>,
}

/// AST analyzer for extracting information
pub struct AstAnalyzer;

impl AstAnalyzer {
    pub fn new() -> Self {
        Self
    }
    
    /// Traverse the AST and collect nodes
    pub fn traverse(&self, cursor: &mut TreeCursor, source: &str) -> AstNode {
        let node = cursor.node();
        
        let mut children = Vec::new();
        if cursor.goto_first_child() {
            loop {
                children.push(self.traverse(cursor, source));
                if !cursor.goto_next_sibling() {
                    break;
                }
            }
            cursor.goto_parent();
        }
        
        AstNode {
            kind: node.kind().to_string(),
            start_line: node.start_position().row,
            end_line: node.end_position().row,
            text: source[node.byte_range()].to_string(),
            children,
        }
    }
    
    /// Find all functions in the AST
    pub fn find_functions(&self, root: &AstNode, language: SupportedLanguage) -> Vec<AstNode> {
        let function_kinds: &[&str] = match language {
            SupportedLanguage::Rust => &["function_item", "function_signature"],
            SupportedLanguage::Python => &["function_definition"],
            SupportedLanguage::TypeScript | SupportedLanguage::JavaScript => {
                &["function_declaration", "function_expression", "arrow_function"]
            }
        };
        
        self.find_nodes_by_kind(root, function_kinds)
    }
    
    /// Find all structs/classes
    pub fn find_types(&self, root: &AstNode, language: SupportedLanguage) -> Vec<AstNode> {
        let type_kinds: &[&str] = match language {
            SupportedLanguage::Rust => &["struct_item", "enum_item", "trait_item"],
            SupportedLanguage::Python => &["class_definition"],
            SupportedLanguage::TypeScript | SupportedLanguage::JavaScript => {
                &["class_declaration", "interface_declaration", "type_alias_declaration"]
            }
        };
        
        self.find_nodes_by_kind(root, type_kinds)
    }
    
    /// Find nodes by their kind
    fn find_nodes_by_kind(&self, node: &AstNode, kinds: &[&str]) -> Vec<AstNode> {
        let mut results = Vec::new();
        
        if kinds.contains(&node.kind.as_str()) {
            results.push(node.clone());
        }
        
        for child in &node.children {
            results.extend(self.find_nodes_by_kind(child, kinds));
        }
        
        results
    }
    
    /// Calculate lines of code
    pub fn count_lines(&self, node: &AstNode) -> usize {
        node.end_line - node.start_line + 1
    }
}
