//! Markdown-aware chunking for RAG
//! 
//! Splits Markdown into semantic chunks respecting headers.

/// A chunk of content with metadata
#[derive(Debug, Clone)]
pub struct Chunk {
    pub content: String,
    pub source_path: String,
    pub heading: String,
    pub line_start: usize,
    pub line_end: usize,
}

/// Markdown chunker that respects headers
pub struct MarkdownChunker {
    max_chars: usize,
}

impl MarkdownChunker {
    pub fn new(max_chars: usize) -> Self {
        Self { max_chars }
    }
    
    /// Chunk a single Markdown file
    pub fn chunk_file(&self, content: &str, path: &str) -> Vec<Chunk> {
        let mut chunks = Vec::new();
        let mut current_chunk = String::new();
        let mut current_heading = String::from("Root");
        let mut line_start = 0;
        let mut line_current = 0;
        
        for line in content.lines() {
            // New header = new chunk
            if line.starts_with('#') {
                if !current_chunk.is_empty() {
                    chunks.push(Chunk {
                        content: current_chunk.clone(),
                        source_path: path.to_string(),
                        heading: current_heading.clone(),
                        line_start,
                        line_end: line_current,
                    });
                    current_chunk.clear();
                    line_start = line_current;
                }
                current_heading = line.trim_start_matches('#').trim().to_string();
            }
            
            current_chunk.push_str(line);
            current_chunk.push('\n');
            
            // Chunk too big? Split it
            if current_chunk.len() > self.max_chars {
                chunks.push(Chunk {
                    content: current_chunk.clone(),
                    source_path: path.to_string(),
                    heading: current_heading.clone(),
                    line_start,
                    line_end: line_current,
                });
                current_chunk.clear();
                line_start = line_current;
            }
            
            line_current += 1;
        }
        
        // Add remaining content
        if !current_chunk.is_empty() {
            chunks.push(Chunk {
                content: current_chunk,
                source_path: path.to_string(),
                heading: current_heading,
                line_start,
                line_end: line_current,
            });
        }
        
        chunks
    }
}
