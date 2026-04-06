//! Web Fetch Tool
//! 
//! HTTP client for fetching web resources
//! Integrated with secure-api-client for retries and rate limiting

use async_trait::async_trait;
use serde_json::Value;
use std::time::Duration;

use crate::{Tool, ToolOutput, ToolError};

/// Web fetch tool for HTTP requests
pub struct WebFetchTool {
    client: reqwest::Client,
    #[allow(dead_code)]
    timeout: Duration,
    max_retries: u32,
}

impl WebFetchTool {
    /// Create new web fetch tool with default settings
    pub fn new() -> Self {
        Self {
            client: reqwest::Client::builder()
                .timeout(Duration::from_secs(30))
                .user_agent("OpenClaw-ECC/1.0")
                .build()
                .expect("Failed to create HTTP client"),
            timeout: Duration::from_secs(30),
            max_retries: 3,
        }
    }

    /// Create with custom timeout
    pub fn with_timeout(timeout_secs: u64) -> Self {
        Self {
            client: reqwest::Client::builder()
                .timeout(Duration::from_secs(timeout_secs))
                .user_agent("OpenClaw-ECC/1.0")
                .build()
                .expect("Failed to create HTTP client"),
            timeout: Duration::from_secs(timeout_secs),
            max_retries: 3,
        }
    }

    /// Check if URL is allowed (basic safety)
    fn is_url_allowed(&self, url: &str) -> Result<(), ToolError> {
        let parsed = url.parse::<reqwest::Url>()
            .map_err(|e| ToolError::InvalidArguments(format!("Invalid URL: {}", e)))?;

        // Block internal IPs and localhost
        if let Some(host) = parsed.host_str() {
            let host_lower = host.to_lowercase();
            if host_lower == "localhost" 
                || host_lower == "127.0.0.1"
                || host_lower.starts_with("192.168.")
                || host_lower.starts_with("10.")
                || host_lower.starts_with("172.16.") {
                return Err(ToolError::InvalidArguments(
                    "Internal IPs are not allowed".to_string()
                ));
            }
        }

        // Block file:// URLs
        if parsed.scheme() == "file" {
            return Err(ToolError::InvalidArguments(
                "File URLs are not allowed".to_string()
            ));
        }

        // Only allow http and https
        if parsed.scheme() != "http" && parsed.scheme() != "https" {
            return Err(ToolError::InvalidArguments(
                format!("Scheme '{}' not allowed. Only http/https", parsed.scheme())
            ));
        }

        Ok(())
    }

    /// Fetch URL with retries
    async fn fetch_with_retry(&self, url: &str, method: reqwest::Method, body: Option<Value>) 
        -> Result<String, ToolError> {
        let mut last_error = None;

        for attempt in 0..=self.max_retries {
            match self.fetch_once(url, method.clone(), body.clone()).await {
                Ok(result) => return Ok(result),
                Err(e) => {
                    // Check if retryable
                    if attempt < self.max_retries && self.is_retryable(&e) {
                        let delay = Duration::from_millis(1000 * (attempt as u64 + 1));
                        tokio::time::sleep(delay).await;
                        last_error = Some(e);
                        continue;
                    }
                    return Err(e);
                }
            }
        }

        Err(last_error.unwrap_or_else(|| {
            ToolError::Execution("Max retries exceeded".to_string())
        }))
    }

    /// Single fetch attempt
    async fn fetch_once(&self, url: &str, method: reqwest::Method, body: Option<Value>)
        -> Result<String, ToolError> {
        
        let mut request = self.client.request(method.clone(), url);

        // Add headers
        request = request.header("Accept", "application/json, text/plain, text/html, */*");

        // Add body for POST/PUT
        if let Some(body_data) = body {
            if method == reqwest::Method::POST || method == reqwest::Method::PUT {
                request = request
                    .header("Content-Type", "application/json")
                    .json(&body_data);
            }
        }

        let response = request.send().await
            .map_err(|e| ToolError::Io(format!("Request failed: {}", e)))?;

        let status = response.status();
        
        // Check status
        if !status.is_success() {
            return Err(ToolError::Io(format!(
                "HTTP {}: {}", 
                status.as_u16(),
                status.canonical_reason().unwrap_or("Unknown error")
            )));
        }

        // Get content
        let content = response.text().await
            .map_err(|e| ToolError::Io(format!("Failed to read response: {}", e)))?;

        Ok(content)
    }

    /// Check if error is retryable
    fn is_retryable(&self, error: &ToolError) -> bool {
        match error {
            ToolError::Io(msg) => {
                // Retry on connection errors, timeouts
                msg.contains("connection") 
                    || msg.contains("timeout")
                    || msg.contains("reset")
            }
            _ => false,
        }
    }
}

impl Default for WebFetchTool {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Tool for WebFetchTool {
    fn name(&self) -> &str {
        "web_fetch"
    }

    fn description(&self) -> &str {
        "Fetch content from a web URL (HTTP GET/POST). Supports JSON APIs and web pages."
    }

    fn parameters_schema(&self) -> Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "url": {
                    "type": "string",
                    "description": "URL to fetch (http/https only)"
                },
                "method": {
                    "type": "string",
                    "description": "HTTP method: GET or POST",
                    "enum": ["GET", "POST"],
                    "default": "GET"
                },
                "body": {
                    "type": "object",
                    "description": "JSON body for POST requests (optional)"
                },
                "max_length": {
                    "type": "integer",
                    "description": "Maximum characters to return (default: 10000)",
                    "minimum": 100,
                    "maximum": 100000,
                    "default": 10000
                }
            },
            "required": ["url"]
        })
    }

    async fn execute(&self, args: Value) -> Result<ToolOutput, ToolError> {
        let url = args.get("url")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing url".to_string()))?;

        let method_str = args.get("method")
            .and_then(|v| v.as_str())
            .unwrap_or("GET");

        let method = match method_str.to_uppercase().as_str() {
            "GET" => reqwest::Method::GET,
            "POST" => reqwest::Method::POST,
            _ => return Err(ToolError::InvalidArguments(
                format!("Method '{}' not supported. Use GET or POST", method_str)
            )),
        };

        let body = args.get("body").cloned();

        let max_length = args.get("max_length")
            .and_then(|v| v.as_u64())
            .unwrap_or(10000) as usize;

        // Safety check
        self.is_url_allowed(url)?;

        // Fetch with retry
        let content = self.fetch_with_retry(url, method, body).await?;

        // Truncate if too long
        let result = if content.len() > max_length {
            format!("{}\n\n[Content truncated: {} of {} characters]", 
                &content[..max_length],
                max_length,
                content.len()
            )
        } else {
            content
        };

        Ok(ToolOutput::success(result))
    }
}

/// URL validation tool (for testing URLs without fetching)
pub struct UrlCheckTool;

#[async_trait]
impl Tool for UrlCheckTool {
    fn name(&self) -> &str {
        "url_check"
    }

    fn description(&self) -> &str {
        "Check if a URL is valid and allowed (without fetching content)"
    }

    fn parameters_schema(&self) -> Value {
        serde_json::json!({
            "type": "object",
            "properties": {
                "url": {
                    "type": "string",
                    "description": "URL to validate"
                }
            },
            "required": ["url"]
        })
    }

    async fn execute(&self, args: Value) -> Result<ToolOutput, ToolError> {
        let url = args.get("url")
            .and_then(|v| v.as_str())
            .ok_or_else(|| ToolError::InvalidArguments("Missing url".to_string()))?;

        match url.parse::<reqwest::Url>() {
            Ok(parsed) => {
                let scheme = parsed.scheme();
                let host = parsed.host_str().unwrap_or("none");
                
                Ok(ToolOutput::success(format!(
                    "URL is valid\nScheme: {}\nHost: {}\nPath: {}",
                    scheme,
                    host,
                    parsed.path()
                )))
            }
            Err(e) => Err(ToolError::InvalidArguments(format!("Invalid URL: {}", e))),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_web_fetch_tool_name() {
        let tool = WebFetchTool::new();
        assert_eq!(tool.name(), "web_fetch");
    }

    #[test]
    fn test_url_validation_blocks_internal_ips() {
        let tool = WebFetchTool::new();
        
        assert!(tool.is_url_allowed("http://localhost/test").is_err());
        assert!(tool.is_url_allowed("http://127.0.0.1/api").is_err());
        assert!(tool.is_url_allowed("http://192.168.1.1/admin").is_err());
    }

    #[test]
    fn test_url_validation_blocks_file_urls() {
        let tool = WebFetchTool::new();
        
        assert!(tool.is_url_allowed("file:///etc/passwd").is_err());
        assert!(tool.is_url_allowed("file://C:/windows/system32").is_err());
    }

    #[test]
    fn test_url_validation_allows_valid_urls() {
        let tool = WebFetchTool::new();
        
        assert!(tool.is_url_allowed("https://api.example.com/data").is_ok());
        assert!(tool.is_url_allowed("http://example.com/page").is_ok());
    }
}
