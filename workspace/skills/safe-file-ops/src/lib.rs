//! Safe File Operations - Pre-flight Check Implementation
//! 
//! Wrapper around edit/write with validation and fallbacks

use std::path::Path;

/// Result of pre-flight check
#[derive(Debug)]
pub enum PreflightResult {
    /// Safe to proceed with edit
    SafeToEdit,
    /// Use write instead (file doesn't exist or old_string not found)
    UseWrite { reason: String },
    /// Missing required parameter
    MissingParameter { param: String },
    /// File has changed since last read
    ContentMismatch { expected: String, actual: String },
}

/// Pre-flight check for file operations
pub fn preflight_check(
    file_path: &str,
    old_string: Option<&str>,
    new_string: Option<&str>,
) -> PreflightResult {
    // 1. Check if file exists
    if !Path::new(file_path).exists() {
        if old_string.is_some() && new_string.is_some() {
            return PreflightResult::UseWrite {
                reason: "File does not exist - use write() to create".to_string(),
            };
        }
    }
    
    // 2. Check required parameters for edit
    if old_string.is_some() && new_string.is_none() {
        return PreflightResult::MissingParameter {
            param: "new_string".to_string(),
        };
    }
    
    if new_string.is_some() && old_string.is_none() {
        return PreflightResult::MissingParameter {
            param: "old_string".to_string(),
        };
    }
    
    // 3. If we have the file content, verify old_string exists
    if let (Some(old), Some(_)) = (old_string, new_string) {
        if let Ok(content) = std::fs::read_to_string(file_path) {
            if !content.contains(old) {
                return PreflightResult::ContentMismatch {
                    expected: old.to_string(),
                    actual: "(not found in current file)".to_string(),
                };
            }
        }
    }
    
    PreflightResult::SafeToEdit
}

/// Safe edit with automatic fallback
pub fn safe_edit(
    file_path: &str,
    old_string: &str,
    new_string: &str,
) -> Result<(), String> {
    // Pre-flight check
    match preflight_check(file_path, Some(old_string), Some(new_string)) {
        PreflightResult::SafeToEdit => {
            // Proceed with edit
            let content = std::fs::read_to_string(file_path)
                .map_err(|e| format!("Cannot read file: {}", e))?;
            
            if !content.contains(old_string) {
                return Err("old_string not found in file".to_string());
            }
            
            let new_content = content.replace(old_string, new_string);
            std::fs::write(file_path, new_content)
                .map_err(|e| format!("Cannot write file: {}", e))?;
            
            Ok(())
        }
        PreflightResult::UseWrite { reason } => {
            Err(format!("Use write() instead: {}", reason))
        }
        PreflightResult::MissingParameter { param } => {
            Err(format!("Missing required parameter: {}", param))
        }
        PreflightResult::ContentMismatch { expected, actual } => {
            Err(format!(
                "Content mismatch - file may have changed. Expected: {}, Found: {}",
                expected, actual
            ))
        }
    }
}

/// Safe write with backup
pub fn safe_write(file_path: &str, content: &str, create_backup: bool) -> Result<(), String> {
    // Create backup if requested and file exists
    if create_backup && Path::new(file_path).exists() {
        let backup_path = format!("{}.bak", file_path);
        std::fs::copy(file_path, &backup_path)
            .map_err(|e| format!("Cannot create backup: {}", e))?;
    }
    
    // Write new content
    std::fs::write(file_path, content)
        .map_err(|e| format!("Cannot write file: {}", e))?;
    
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    use std::fs;

    #[test]
    fn test_preflight_missing_new_string() {
        let result = preflight_check("test.txt", Some("old"), None);
        match result {
            PreflightResult::MissingParameter { param } => {
                assert_eq!(param, "new_string");
            }
            _ => panic!("Expected MissingParameter"),
        }
    }

    #[test]
    fn test_preflight_missing_old_string() {
        let result = preflight_check("test.txt", None, Some("new"));
        match result {
            PreflightResult::MissingParameter { param } => {
                assert_eq!(param, "old_string");
            }
            _ => panic!("Expected MissingParameter"),
        }
    }

    #[test]
    fn test_preflight_file_not_exists() {
        let result = preflight_check("/nonexistent/path.txt", Some("old"), Some("new"));
        match result {
            PreflightResult::UseWrite { .. } => {}
            _ => panic!("Expected UseWrite for non-existent file"),
        }
    }

    #[test]
    fn test_safe_edit_success() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.txt");
        fs::write(&file_path, "Hello World").unwrap();
        
        safe_edit(
            file_path.to_str().unwrap(),
            "Hello",
            "Goodbye"
        ).unwrap();
        
        let content = fs::read_to_string(&file_path).unwrap();
        assert_eq!(content, "Goodbye World");
    }

    #[test]
    fn test_safe_edit_missing_old_string() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.txt");
        fs::write(&file_path, "Hello World").unwrap();
        
        let result = safe_edit(
            file_path.to_str().unwrap(),
            "NotFound",
            "Replacement"
        );
        
        assert!(result.is_err());
    }

    #[test]
    fn test_safe_write_with_backup() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.txt");
        fs::write(&file_path, "Original content").unwrap();
        
        safe_write(
            file_path.to_str().unwrap(),
            "New content",
            true
        ).unwrap();
        
        // Verify backup exists
        let backup_path = temp_dir.path().join("test.txt.bak");
        assert!(backup_path.exists());
        
        // Verify backup content
        let backup_content = fs::read_to_string(&backup_path).unwrap();
        assert_eq!(backup_content, "Original content");
        
        // Verify new content
        let content = fs::read_to_string(&file_path).unwrap();
        assert_eq!(content, "New content");
    }
}
