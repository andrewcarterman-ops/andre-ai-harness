//! File Operations Tools
//! 
//! Read, write, edit, glob, grep operations

use async_trait::async_trait;
use serde_json::Value;
use std::path::Path;
use tokio::fs;

use crate::{Tool, ToolOutput, ToolError};

/// Read file tool
pub struct ReadFileTool;

#[async_trait]
impl Tool for ReadFileTool {
    fn name(&self) -> &str {
        "read_file"
    }
    
    fn description(&self) -> &str {
        "Read the contents of a file"
    }
    
    fn parameters_schema(&self) -> Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Path to the file to read"
                },
                "limit": {
                    "type": "integer",
                    "description": "Maximum number of lines to read (optional)",
                    "minimum": 1
                }
            },
            "required": ["path"]
        })
    }
    
    async fn execute(&self, args: Value) -> Result<ToolOutput, ToolError> {
        let path = args.get("path")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing path".to_string()))?;
        
        // Validate path
        if !Path::new(path).exists() {
            return Err(ToolError::Io(format!("File not found: {}", path)));
        }
        
        // Read content
        let content = fs::read_to_string(path).await
            .map_err(|e| ToolError::Io(e.to_string()))?;
        
        // Apply limit if specified
        if let Some(limit) = args.get("limit").and_then(|v| v.as_u64()) {
            let lines: Vec<_> = content.lines().take(limit as usize).collect();
            Ok(ToolOutput::success(lines.join("\n")))
        } else {
            Ok(ToolOutput::success(content))
        }
    }
}

/// Write file tool
pub struct WriteFileTool;

#[async_trait]
impl Tool for WriteFileTool {
    fn name(&self) -> &str {
        "write_file"
    }
    
    fn description(&self) -> &str {
        "Write content to a file (creates or overwrites)"
    }
    
    fn parameters_schema(&self) -> Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Path to the file"
                },
                "content": {
                    "type": "string",
                    "description": "Content to write"
                }
            },
            "required": ["path", "content"]
        })
    }
    
    async fn execute(&self, args: Value) -> Result<ToolOutput, ToolError> {
        let path = args.get("path")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing path".to_string()))?;

        let content = args.get("content")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing content".to_string()))?;
        
        // Create parent directories if needed
        if let Some(parent) = Path::new(path).parent() {
            fs::create_dir_all(parent).await
                .map_err(|e| ToolError::Io(e.to_string()))?;
        }
        
        // Write file
        fs::write(path, content).await
            .map_err(|e| ToolError::Io(e.to_string()))?;
        
        Ok(ToolOutput::success(format!("File written: {}", path)))
    }
}

/// Edit file tool (search and replace)
/// Supports both snake_case (old_string/new_string) and camelCase (oldText/newText) parameters
/// FIXED: Only replaces FIRST occurrence (not all)
pub struct EditFileTool;

#[async_trait]
impl Tool for EditFileTool {
    fn name(&self) -> &str {
        "edit_file"
    }
    
    fn description(&self) -> &str {
        "Edit a file by replacing text. Supports both old_string/new_string and oldText/newText parameter names. Replaces only the first occurrence."
    }
    
    fn parameters_schema(&self) -> Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Path to the file"
                },
                "old_string": {
                    "type": "string",
                    "description": "Text to find and replace (alternative: oldText)"
                },
                "new_string": {
                    "type": "string",
                    "description": "Replacement text (alternative: newText)"
                },
                "oldText": {
                    "type": "string",
                    "description": "Text to find and replace (alternative: old_string)"
                },
                "newText": {
                    "type": "string",
                    "description": "Replacement text (alternative: new_string)"
                }
            },
            "required": ["path"]
        })
    }
    
    async fn execute(&self, args: Value) -> Result<ToolOutput, ToolError> {
        let path = args.get("path")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing path".to_string()))?;
        
        // Support both snake_case and camelCase parameter names
        let old_string = args.get("old_string")
            .and_then(|v| v.as_str())
            .or_else(|| args.get("oldText").and_then(|v| v.as_str()))
            .ok_or_else(|| ToolError::InvalidArguments(
                "Missing old_string or oldText".to_string()
            ))?;
        
        let new_string = args.get("new_string")
            .and_then(|v| v.as_str())
            .or_else(|| args.get("newText").and_then(|v| v.as_str()))
            .ok_or_else(|| ToolError::InvalidArguments(
                "Missing new_string or newText".to_string()
            ))?;
        
        // Read existing content
        let content = fs::read_to_string(path).await
            .map_err(|e| ToolError::Io(e.to_string()))?;
        
        // Find position of old_string
        let index = content.find(old_string)
            .ok_or_else(|| ToolError::InvalidArguments(
                format!("Text not found in file: {}", old_string)
            ))?;
        
        // FIXED: Replace only FIRST occurrence using string slicing
        let before = &content[..index];
        let after = &content[index + old_string.len()..];
        let new_content = format!("{}{}{}", before, new_string, after);
        
        // Write back
        fs::write(path, new_content).await
            .map_err(|e| ToolError::Io(e.to_string()))?;
        
        Ok(ToolOutput::success(format!("File edited: {}", path)))
    }
}

/// Glob search tool
pub struct GlobTool;

#[async_trait]
impl Tool for GlobTool {
    fn name(&self) -> &str {
        "glob"
    }
    
    fn description(&self) -> &str {
        "Find files matching a glob pattern"
    }
    
    fn parameters_schema(&self) -> Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "pattern": {
                    "type": "string",
                    "description": "Glob pattern (e.g., '*.rs', 'src/**/*.txt')"
                },
                "path": {
                    "type": "string",
                    "description": "Starting directory (default: current)"
                }
            },
            "required": ["pattern"]
        })
    }
    
    async fn execute(&self, args: Value) -> Result<ToolOutput, ToolError> {
        let pattern = args.get("pattern")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing pattern".to_string()))?;
        
        let path = args.get("path")
            .and_then(|v| v.as_str())
            .unwrap_or(".");
        
        // Use glob crate to find files
        let full_pattern = format!("{}/{}", path, pattern);
        let paths = glob::glob(&full_pattern)
            .map_err(|e| ToolError::InvalidArguments(format!("Invalid pattern: {}", e)))?;
        
        let mut results = Vec::new();
        for entry in paths {
            if let Ok(path) = entry {
                results.push(path.to_string_lossy().to_string());
            }
        }
        
        Ok(ToolOutput::success(results.join("\n")))
    }
}

/// Grep search tool
pub struct GrepTool;

#[async_trait]
impl Tool for GrepTool {
    fn name(&self) -> &str {
        "grep"
    }
    
    fn description(&self) -> &str {
        "Search for text patterns in files"
    }
    
    fn parameters_schema(&self) -> Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "pattern": {
                    "type": "string",
                    "description": "Regex pattern to search for"
                },
                "path": {
                    "type": "string",
                    "description": "File or directory to search"
                },
                "include": {
                    "type": "string",
                    "description": "Glob pattern for files to include"
                }
            },
            "required": ["pattern", "path"]
        })
    }
    
    async fn execute(&self, args: Value) -> Result<ToolOutput, ToolError> {
        let pattern = args.get("pattern")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing pattern".to_string()))?;
        
        let path = args.get("path")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing path".to_string()))?;
        
        // Compile regex
        let regex = regex::Regex::new(pattern)
            .map_err(|e| ToolError::InvalidArguments(format!("Invalid regex: {}", e)))?;
        
        let mut results = Vec::new();
        
        // Search in single file or directory
        let path = Path::new(path);
        if path.is_file() {
            let content = fs::read_to_string(path).await
                .map_err(|e| ToolError::Io(e.to_string()))?;
            
            for (line_num, line) in content.lines().enumerate() {
                if regex.is_match(line) {
                    results.push(format!("{}:{}: {}", 
                        path.display(), 
                        line_num + 1, 
                        line
                    ));
                }
            }
        } else {
            // Directory search (simplified - would use WalkDir in production)
            results.push(format!("Directory search not fully implemented for: {}", path.display()));
        }
        
        Ok(ToolOutput::success(results.join("\n")))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::io::Write;
    use tempfile::NamedTempFile;

    #[tokio::test]
    async fn test_edit_file_with_snake_case() {
        let tool = EditFileTool;
        
        // Create temp file with content
        let mut temp_file = NamedTempFile::new().unwrap();
        write!(temp_file, "Hello World\nSecond line").unwrap();
        let path = temp_file.path().to_str().unwrap();
        
        // Test with snake_case parameters
        let args = json!({
            "path": path,
            "old_string": "Hello World",
            "new_string": "Goodbye World"
        });
        
        let result = tool.execute(args).await;
        assert!(result.is_ok());
        assert!(result.unwrap().content.contains("edited"));
        
        // Verify file was modified
        let content = fs::read_to_string(path).await.unwrap();
        assert!(content.contains("Goodbye World"));
        assert!(!content.contains("Hello World"));
    }

    #[tokio::test]
    async fn test_edit_file_with_camel_case() {
        let tool = EditFileTool;
        
        // Create temp file with content
        let mut temp_file = NamedTempFile::new().unwrap();
        write!(temp_file, "Hello World\nSecond line").unwrap();
        let path = temp_file.path().to_str().unwrap();
        
        // Test with camelCase parameters (as used by Gateway)
        let args = json!({
            "path": path,
            "oldText": "Hello World",
            "newText": "Goodbye World"
        });
        
        let result = tool.execute(args).await;
        assert!(result.is_ok(), "camelCase parameters should work: {:?}", result.err());
        assert!(result.unwrap().content.contains("edited"));
        
        // Verify file was modified
        let content = fs::read_to_string(path).await.unwrap();
        assert!(content.contains("Goodbye World"));
        assert!(!content.contains("Hello World"));
    }

    #[tokio::test]
    async fn test_edit_file_replaces_only_first_occurrence() {
        let tool = EditFileTool;
        
        // Create temp file with MULTIPLE occurrences
        let mut temp_file = NamedTempFile::new().unwrap();
        write!(temp_file, "old and old and old").unwrap();
        let path = temp_file.path().to_str().unwrap();
        
        // Test - should only replace FIRST occurrence
        let args = json!({
            "path": path,
            "old_string": "old",
            "new_string": "new"
        });
        
        let result = tool.execute(args).await;
        assert!(result.is_ok(), "Edit should succeed: {:?}", result.err());
        
        // Verify only FIRST occurrence was replaced
        let content = fs::read_to_string(path).await.unwrap();
        assert_eq!(content, "new and old and old", 
            "Should only replace first occurrence, got: {}", content);
    }

    #[tokio::test]
    async fn test_edit_file_prefers_snake_case_over_camel_case() {
        let tool = EditFileTool;
        
        // Create temp file with content
        let mut temp_file = NamedTempFile::new().unwrap();
        write!(temp_file, "original content").unwrap();
        let path = temp_file.path().to_str().unwrap();
        
        // Test with BOTH parameter types - snake_case should win
        let args = json!({
            "path": path,
            "old_string": "original",
            "new_string": "modified_snake",
            "oldText": "content",
            "newText": "modified_camel"
        });
        
        let result = tool.execute(args).await;
        assert!(result.is_ok());
        
        // Verify snake_case was used (not camelCase)
        let content = fs::read_to_string(path).await.unwrap();
        assert!(content.contains("modified_snake"));
        assert!(!content.contains("modified_camel"));
    }

    #[tokio::test]
    async fn test_edit_file_missing_both_parameters() {
        let tool = EditFileTool;
        
        let mut temp_file = NamedTempFile::new().unwrap();
        write!(temp_file, "test content").unwrap();
        let path = temp_file.path().to_str().unwrap();
        
        // Test with missing old/oldText parameter
        let args = json!({
            "path": path,
            "new_string": "replacement"
        });
        
        let result = tool.execute(args).await;
        assert!(result.is_err());
        let err_msg = format!("{}", result.unwrap_err());
        assert!(err_msg.contains("old_string") || err_msg.contains("oldText"));
    }

    #[tokio::test]
    async fn test_read_file_with_limit() {
        let tool = ReadFileTool;
        
        // Create temp file with multiple lines
        let mut temp_file = NamedTempFile::new().unwrap();
        writeln!(temp_file, "Line 1").unwrap();
        writeln!(temp_file, "Line 2").unwrap();
        writeln!(temp_file, "Line 3").unwrap();
        let path = temp_file.path().to_str().unwrap();
        
        // Test with limit
        let args = json!({
            "path": path,
            "limit": 2
        });
        
        let result = tool.execute(args).await;
        assert!(result.is_ok());
        let content = result.unwrap().content;
        assert!(content.contains("Line 1"));
        assert!(content.contains("Line 2"));
        assert!(!content.contains("Line 3"));
    }

    #[tokio::test]
    async fn test_write_file_creates_parent_dirs() {
        let tool = WriteFileTool;
        
        // Use temp directory
        let temp_dir = tempfile::tempdir().unwrap();
        let file_path = temp_dir.path().join("subdir/nested/file.txt");
        
        let args = json!({
            "path": file_path.to_str().unwrap(),
            "content": "test content"
        });
        
        let result = tool.execute(args).await;
        assert!(result.is_ok());
        
        // Verify file exists
        assert!(file_path.exists());
        let content = fs::read_to_string(&file_path).await.unwrap();
        assert_eq!(content, "test content");
    }

    #[tokio::test]
    async fn test_glob_finds_files() {
        let tool = GlobTool;
        
        // Use temp directory with known files
        let temp_dir = tempfile::tempdir().unwrap();
        let temp_path = temp_dir.path();
        
        // Create test files
        fs::write(temp_path.join("test1.rs"), "").await.unwrap();
        fs::write(temp_path.join("test2.rs"), "").await.unwrap();
        fs::write(temp_path.join("test.txt"), "").await.unwrap();
        
        let args = json!({
            "pattern": "*.rs",
            "path": temp_path.to_str().unwrap()
        });
        
        let result = tool.execute(args).await;
        assert!(result.is_ok());
        let content = result.unwrap().content;
        assert!(content.contains("test1.rs"));
        assert!(content.contains("test2.rs"));
        assert!(!content.contains("test.txt"));
    }

    #[tokio::test]
    async fn test_grep_finds_pattern() {
        let tool = GrepTool;
        
        // Create temp file with content
        let mut temp_file = NamedTempFile::new().unwrap();
        writeln!(temp_file, "foo bar").unwrap();
        writeln!(temp_file, "baz qux").unwrap();
        writeln!(temp_file, "foo baz").unwrap();
        let path = temp_file.path().to_str().unwrap();
        
        let args = json!({
            "pattern": "foo",
            "path": path
        });
        
        let result = tool.execute(args).await;
        assert!(result.is_ok());
        let content = result.unwrap().content;
        assert!(content.contains("foo bar"));
        assert!(!content.contains("baz qux"));
        assert!(content.contains("foo baz"));
    }
}
