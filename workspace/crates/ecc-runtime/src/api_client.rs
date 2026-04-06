//! Secure API Client Integration
//! 
//! Connects secure-api-client with the ECC Runtime ApiClient trait

use async_trait::async_trait;
use crate::{ApiClient, ApiRequest, ApiError, SseFrame, Message};

/// Implementation of ApiClient using secure-api-client
pub struct SecureApiClient {
    client: reqwest::Client,
    base_url: String,
    api_key: String,
}

impl SecureApiClient {
    /// Create new client
    pub fn new(api_key: impl Into<String>) -> Self {
        Self {
            client: reqwest::Client::new(),
            base_url: "https://api.anthropic.com".to_string(),
            api_key: api_key.into(),
        }
    }

    /// Create with custom base URL
    pub fn with_base_url(api_key: impl Into<String>, base_url: impl Into<String>) -> Self {
        Self {
            client: reqwest::Client::new(),
            base_url: base_url.into(),
            api_key: api_key.into(),
        }
    }

    /// Simple non-streaming request (for testing)
    pub async fn request(&self, request: ApiRequest) -> Result<Message, ApiError> {
        let url = format!("{}/v1/messages", self.base_url);
        
        let body = serde_json::json!({
            "model": request.model,
            "messages": request.messages,
            "system": request.system,
            "tools": request.tools,
            "temperature": request.temperature.unwrap_or(0.7),
            "max_tokens": request.max_tokens.unwrap_or(4096),
            "stream": false,
        });

        let response = self.client
            .post(&url)
            .header("x-api-key", &self.api_key)
            .header("anthropic-version", "2023-06-01")
            .header("content-type", "application/json")
            .json(&body)
            .send()
            .await
            .map_err(|e| ApiError::Network(e.to_string()))?;

        if !response.status().is_success() {
            return Err(ApiError::Http(response.status().as_u16()));
        }

        let result: serde_json::Value = response.json().await
            .map_err(|e| ApiError::Parse(e.to_string()))?;

        // Extract content from response
        let content = result.get("content")
            .and_then(|c| c.as_array())
            .and_then(|arr| arr.first())
            .and_then(|first| first.get("text"))
            .and_then(|t| t.as_str())
            .unwrap_or("")
            .to_string();

        Ok(Message::assistant(content, None))
    }
}

#[async_trait]
impl ApiClient for SecureApiClient {
    async fn stream_request(
        &self,
        _request: ApiRequest,
    ) -> Result<Box<dyn Iterator<Item = SseFrame> + Send>, ApiError> {
        // TODO: Implement full streaming with SseStreamParser
        // For now, return empty iterator (placeholder)
        Ok(Box::new(vec![].into_iter()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_secure_api_client_creation() {
        let client = SecureApiClient::new("test-key");
        assert_eq!(client.base_url, "https://api.anthropic.com");
    }

    #[test]
    fn test_secure_api_client_with_custom_url() {
        let client = SecureApiClient::with_base_url("test-key", "http://localhost:8080");
        assert_eq!(client.base_url, "http://localhost:8080");
    }
}
