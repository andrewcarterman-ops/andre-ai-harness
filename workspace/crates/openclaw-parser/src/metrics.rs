//! Code metrics extraction

use serde::{Serialize, Deserialize};

/// Metrics for a single function
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct FunctionMetrics {
    pub name: String,
    pub lines: usize,
    pub complexity: usize,
    pub parameters: usize,
    pub has_doc_comment: bool,
}

/// Overall code metrics
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CodeMetrics {
    pub total_lines: usize,
    pub code_lines: usize,
    pub comment_lines: usize,
    pub blank_lines: usize,
    pub function_count: usize,
    pub struct_count: usize,
    pub enum_count: usize,
    pub average_function_length: f64,
    pub functions: Vec<FunctionMetrics>,
}

impl CodeMetrics {
    pub fn new() -> Self {
        Self::default()
    }
    
    /// Calculate average function length
    pub fn calculate_averages(&mut self) {
        if !self.functions.is_empty() {
            let total: usize = self.functions.iter().map(|f| f.lines).sum();
            self.average_function_length = total as f64 / self.functions.len() as f64;
        }
    }
    
    /// Add function metrics
    pub fn add_function(&mut self, func: FunctionMetrics) {
        self.function_count += 1;
        self.functions.push(func);
        self.calculate_averages();
    }
    
    /// Generate summary report
    pub fn summary(&self) -> String {
        format!(
            "Code Metrics Summary:\n\
             - Total lines: {}\n\
             - Functions: {}\n\
             - Structs: {}\n\
             - Enums: {}\n\
             - Avg function length: {:.1} lines\n",
            self.total_lines,
            self.function_count,
            self.struct_count,
            self.enum_count,
            self.average_function_length
        )
    }
}
