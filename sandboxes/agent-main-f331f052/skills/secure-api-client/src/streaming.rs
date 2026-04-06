//! SSE Streaming Parser
//! 
//! Extracted from claw-code/rust/crates/api/src/stream.rs
//! Integrated with OpenClaw Secure API Client

use std::collections::VecDeque;

/// Maximum frame size to prevent memory exhaustion
const DEFAULT_MAX_FRAME_BYTES: usize = 1024 * 1024; // 1MB

/// SSE Frame representation
#[derive(Debug, Clone, PartialEq)]
pub struct SseFrame {
    pub event_type: String,
    pub data: String,
    pub id: Option<String>,
}

impl SseFrame {
    /// Create a new SSE frame
    pub fn new(event_type: impl Into<String>, data: impl Into<String>) -> Self {
        Self {
            event_type: event_type.into(),
            data: data.into(),
            id: None,
        }
    }

    /// Create a content frame (standard message)
    pub fn content(data: impl Into<String>) -> Self {
        Self::new("message", data)
    }

    /// Create a tool_use frame
    pub fn tool_use(data: impl Into<String>) -> Self {
        Self::new("tool_use", data)
    }

    /// Create a done frame
    pub fn done() -> Self {
        Self::new("done", "")
    }

    /// Check if this is a ping frame (should be filtered)
    pub fn is_ping(&self) -> bool {
        self.event_type == "ping" || self.data.trim().is_empty()
    }

    /// Parse data as JSON
    pub fn parse_json<T: serde::de::DeserializeOwned>(&self) -> Result<T, serde_json::Error> {
        serde_json::from_str(&self.data)
    }
}

/// SSE Parser with buffering for incremental parsing
#[derive(Debug, Clone)]
pub struct SseStreamParser {
    buffer: String,
    max_frame_bytes: usize,
    pending_frames: VecDeque<SseFrame>,
}

impl SseStreamParser {
    /// Create a new parser with default frame size limit
    pub fn new() -> Self {
        Self::with_max_frame_bytes(DEFAULT_MAX_FRAME_BYTES)
    }

    /// Create a parser with custom frame size limit
    pub fn with_max_frame_bytes(max_frame_bytes: usize) -> Self {
        Self {
            buffer: String::new(),
            max_frame_bytes,
            pending_frames: VecDeque::new(),
        }
    }

    /// Feed a chunk of data and return any complete frames
    pub fn feed(&mut self, chunk: &str) -> Result<Vec<SseFrame>, SseParseError> {
        self.buffer.push_str(chunk);

        // Check max frame size to prevent memory exhaustion
        if self.buffer.len() > self.max_frame_bytes {
            return Err(SseParseError::FrameTooLarge {
                size: self.buffer.len(),
                max: self.max_frame_bytes,
            });
        }

        // Parse complete frames
        let mut frames = Vec::new();
        while let Some(frame) = self.parse_frame() {
            // Filter ping messages
            if !frame.is_ping() {
                frames.push(frame);
            }
        }

        Ok(frames)
    }

    /// Flush any remaining data as a final frame
    pub fn flush(&mut self) -> Vec<SseFrame> {
        let remaining = std::mem::take(&mut self.buffer);
        if !remaining.is_empty() {
            // Attempt to parse final frame
            if let Some(frame) = self.try_parse(&remaining) {
                if !frame.is_ping() {
                    return vec![frame];
                }
            }
        }
        vec![]
    }

    /// Parse a single frame from buffer if complete
    fn parse_frame(&mut self) -> Option<SseFrame> {
        // Look for double newline (frame boundary)
        if let Some(pos) = self.buffer.find("\n\n") {
            let frame_text = self.buffer[..pos].to_string();
            self.buffer = self.buffer[pos + 2..].to_string();
            self.try_parse(&frame_text)
        } else if let Some(pos) = self.buffer.find("\r\n\r\n") {
            // Windows line endings
            let frame_text = self.buffer[..pos].to_string();
            self.buffer = self.buffer[pos + 4..].to_string();
            self.try_parse(&frame_text)
        } else {
            None
        }
    }

    /// Try to parse a frame from text
    fn try_parse(&self, text: &str) -> Option<SseFrame> {
        let mut event_type = "message".to_string();
        let mut data = String::new();
        let mut id = None;

        for line in text.lines() {
            if let Some((key, value)) = line.split_once(':') {
                let key = key.trim();
                let value = value.trim_start();
                
                match key {
                    "event" => event_type = value.to_string(),
                    "data" => {
                        if !data.is_empty() {
                            data.push('\n');
                        }
                        data.push_str(value);
                    }
                    "id" => id = Some(value.to_string()),
                    _ => {} // Ignore unknown fields
                }
            } else if !line.is_empty() {
                // Line without colon might be a comment (ignore)
                // or malformed data
            }
        }

        // Empty data frames are treated as pings
        if data.is_empty() && event_type != "ping" {
            None
        } else {
            Some(SseFrame { event_type, data, id })
        }
    }

    /// Get number of pending frames
    pub fn pending_count(&self) -> usize {
        self.pending_frames.len()
    }

    /// Check if buffer is empty
    pub fn is_buffer_empty(&self) -> bool {
        self.buffer.is_empty()
    }

    /// Get current buffer size
    pub fn buffer_size(&self) -> usize {
        self.buffer.len()
    }
}

impl Default for SseStreamParser {
    fn default() -> Self {
        Self::new()
    }
}

/// SSE Parse errors
#[derive(Debug, Clone, PartialEq)]
pub enum SseParseError {
    FrameTooLarge { size: usize, max: usize },
    InvalidEncoding(String),
    MalformedFrame(String),
}

impl std::fmt::Display for SseParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::FrameTooLarge { size, max } => {
                write!(f, "SSE frame too large: {} bytes (max: {})", size, max)
            }
            Self::InvalidEncoding(msg) => {
                write!(f, "Invalid SSE encoding: {}", msg)
            }
            Self::MalformedFrame(msg) => {
                write!(f, "Malformed SSE frame: {}", msg)
            }
        }
    }
}

impl std::error::Error for SseParseError {}

/// Token usage tracking for Anthropic API
#[derive(Debug, Default, Clone, Copy)]
pub struct TokenUsage {
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub cache_creation_input_tokens: u64,
    pub cache_read_input_tokens: u64,
}

impl TokenUsage {
    /// Create new token usage
    pub fn new() -> Self {
        Self::default()
    }

    /// Total tokens used
    pub fn total_tokens(&self) -> u64 {
        self.input_tokens + self.output_tokens
    }

    /// Calculate estimated cost
    pub fn estimated_cost(&self, input_price: f64, output_price: f64) -> f64 {
        let input_cost = (self.input_tokens as f64 / 1_000_000.0) * input_price;
        let output_cost = (self.output_tokens as f64 / 1_000_000.0) * output_price;
        input_cost + output_cost
    }

    /// Add another usage to this one
    pub fn add(&mut self, other: &TokenUsage) {
        self.input_tokens += other.input_tokens;
        self.output_tokens += other.output_tokens;
        self.cache_creation_input_tokens += other.cache_creation_input_tokens;
        self.cache_read_input_tokens += other.cache_read_input_tokens;
    }
}

/// Retry policy with exponential backoff
#[derive(Debug, Clone)]
pub struct ExponentialBackoff {
    pub base_ms: u64,
    pub max_ms: u64,
    pub max_retries: u32,
    pub jitter: f64,
}

impl ExponentialBackoff {
    /// Create default retry policy
    pub fn new() -> Self {
        Self {
            base_ms: 1000,
            max_ms: 60000,
            max_retries: 7,
            jitter: 0.25,
        }
    }

    /// Create with custom settings
    pub fn with_settings(base_ms: u64, max_ms: u64, max_retries: u32) -> Self {
        Self {
            base_ms,
            max_ms,
            max_retries,
            jitter: 0.25,
        }
    }

    /// Calculate delay for attempt number
    pub fn delay(&self, attempt: u32) -> std::time::Duration {
        let attempt = attempt.min(31) as u64; // Prevent overflow
        let exponential = self.base_ms * (1_u64 << attempt);
        let clamped = exponential.min(self.max_ms);
        
        // Add jitter (±25%)
        let jitter_factor = 1.0 + (rand::random::<f64>() - 0.5) * 2.0 * self.jitter;
        let with_jitter = (clamped as f64 * jitter_factor) as u64;
        
        std::time::Duration::from_millis(with_jitter.max(self.base_ms))
    }

    /// Check if status code is retryable
    pub fn is_retryable_status(&self, status: u16) -> bool {
        matches!(status, 408 | 429 | 500..=599)
    }
}

impl Default for ExponentialBackoff {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sse_parse_simple() {
        let mut parser = SseStreamParser::new();
        let frames = parser.feed("data: hello\n\n").unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].data, "hello");
        assert_eq!(frames[0].event_type, "message");
    }

    #[test]
    fn test_sse_parse_multiline() {
        let mut parser = SseStreamParser::new();
        let frames = parser.feed("data: line1\ndata: line2\n\n").unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].data, "line1\nline2");
    }

    #[test]
    fn test_sse_filter_ping() {
        let mut parser = SseStreamParser::new();
        let frames = parser.feed("event: ping\ndata: keepalive\n\ndata: hello\n\n").unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].data, "hello");
    }

    #[test]
    fn test_sse_partial_frame() {
        let mut parser = SseStreamParser::new();
        let frames1 = parser.feed("data: hel").unwrap();
        assert!(frames1.is_empty());

        let frames2 = parser.feed("lo\n\n").unwrap();
        assert_eq!(frames2.len(), 1);
        assert_eq!(frames2[0].data, "hello");
    }

    #[test]
    fn test_sse_event_type() {
        let mut parser = SseStreamParser::new();
        let frames = parser.feed("event: tool_use\ndata: {\"name\": \"bash\"}\n\n").unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].event_type, "tool_use");
    }

    #[test]
    fn test_token_usage_add() {
        let mut usage1 = TokenUsage {
            input_tokens: 100,
            output_tokens: 50,
            cache_creation_input_tokens: 10,
            cache_read_input_tokens: 5,
        };
        let usage2 = TokenUsage {
            input_tokens: 50,
            output_tokens: 25,
            cache_creation_input_tokens: 0,
            cache_read_input_tokens: 0,
        };
        usage1.add(&usage2);
        assert_eq!(usage1.input_tokens, 150);
        assert_eq!(usage1.output_tokens, 75);
    }

    #[test]
    fn test_exponential_backoff() {
        let backoff = ExponentialBackoff::new();
        
        // First attempt: ~1000ms
        let d1 = backoff.delay(0);
        assert!(d1.as_millis() >= 750 && d1.as_millis() <= 1250);
        
        // Second attempt: ~2000ms
        let d2 = backoff.delay(1);
        assert!(d2.as_millis() >= 1500 && d2.as_millis() <= 2500);
    }

    #[test]
    fn test_retryable_status() {
        let backoff = ExponentialBackoff::new();
        assert!(backoff.is_retryable_status(408));
        assert!(backoff.is_retryable_status(429));
        assert!(backoff.is_retryable_status(500));
        assert!(backoff.is_retryable_status(503));
        assert!(!backoff.is_retryable_status(200));
        assert!(!backoff.is_retryable_status(400));
    }
}
