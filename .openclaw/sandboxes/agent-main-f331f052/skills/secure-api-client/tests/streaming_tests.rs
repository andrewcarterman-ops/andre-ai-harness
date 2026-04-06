//! SSE Streaming Tests
//! 
//! Tests for SseStreamParser, TokenUsage, and ExponentialBackoff

use secure_api_client::{
    SseStreamParser, 
    SseFrame, 
    SseParseError, 
    TokenUsage, 
    ExponentialBackoff
};

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
    assert!(!frames[0].is_ping());
}

#[test]
fn test_sse_partial_frame() {
    let mut parser = SseStreamParser::new();
    
    // Feed partial data
    let frames1 = parser.feed("data: hel").unwrap();
    assert!(frames1.is_empty());
    
    // Complete the frame
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
fn test_sse_frame_too_large() {
    let mut parser = SseStreamParser::with_max_frame_bytes(10);
    let result = parser.feed("data: this is a very long message that exceeds the limit");
    assert!(result.is_err());
    match result.unwrap_err() {
        SseParseError::FrameTooLarge { .. } => {},
        _ => panic!("Expected FrameTooLarge error"),
    }
}

#[test]
fn test_sse_flush() {
    let mut parser = SseStreamParser::new();
    parser.feed("data: incomplete").unwrap();
    
    let flushed = parser.flush();
    // May or may not contain a frame depending on parsing logic
    assert!(parser.is_buffer_empty());
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
    assert_eq!(usage1.total_tokens(), 225);
}

#[test]
fn test_token_usage_cost() {
    let usage = TokenUsage {
        input_tokens: 1_000_000, // 1M tokens
        output_tokens: 500_000,  // 500K tokens
        cache_creation_input_tokens: 0,
        cache_read_input_tokens: 0,
    };
    
    // $3 per 1M input, $15 per 1M output (Claude 3 Opus prices)
    let cost = usage.estimated_cost(3.0, 15.0);
    assert_eq!(cost, 10.5); // $3 + $7.50
}

#[test]
fn test_exponential_backoff() {
    let backoff = ExponentialBackoff::new();
    
    // Test retryable status codes
    assert!(backoff.is_retryable_status(408)); // Timeout
    assert!(backoff.is_retryable_status(429)); // Rate limit
    assert!(backoff.is_retryable_status(500)); // Server error
    assert!(backoff.is_retryable_status(503)); // Service unavailable
    
    // Test non-retryable status codes
    assert!(!backoff.is_retryable_status(200));
    assert!(!backoff.is_retryable_status(400));
    assert!(!backoff.is_retryable_status(404));
}

#[test]
fn test_exponential_backoff_delay() {
    let backoff = ExponentialBackoff::new();
    
    // First attempt: ~1000ms
    let d1 = backoff.delay(0);
    assert!(d1.as_millis() >= 750 && d1.as_millis() <= 1250);
    
    // Second attempt: ~2000ms
    let d2 = backoff.delay(1);
    assert!(d2.as_millis() >= 1500 && d2.as_millis() <= 2500);
    
    // Third attempt: ~4000ms
    let d3 = backoff.delay(2);
    assert!(d3.as_millis() >= 3000 && d3.as_millis() <= 5000);
}

#[test]
fn test_sse_frame_creation() {
    let frame = SseFrame::new("message", "test data");
    assert_eq!(frame.event_type, "message");
    assert_eq!(frame.data, "test data");
    assert!(frame.id.is_none());
}

#[test]
fn test_sse_frame_content() {
    let frame = SseFrame::content("hello world");
    assert_eq!(frame.event_type, "message");
    assert_eq!(frame.data, "hello world");
}

#[test]
fn test_sse_frame_tool_use() {
    let frame = SseFrame::tool_use(r#"{"name": "read", "args": {"path": "/tmp/test"}}"#);
    assert_eq!(frame.event_type, "tool_use");
}

#[test]
fn test_sse_frame_done() {
    let frame = SseFrame::done();
    assert_eq!(frame.event_type, "done");
    assert_eq!(frame.data, "");
}

#[test]
fn test_sse_frame_parse_json() {
    let frame = SseFrame::tool_use(r#"{"name": "bash", "args": ["ls", "-la"]}"#);
    let parsed: serde_json::Value = frame.parse_json().expect("Should parse JSON");
    assert_eq!(parsed["name"], "bash");
}

#[test]
fn test_sse_windows_line_endings() {
    let mut parser = SseStreamParser::new();
    let frames = parser.feed("data: hello\r\n\r\n").unwrap();
    assert_eq!(frames.len(), 1);
    assert_eq!(frames[0].data, "hello");
}
