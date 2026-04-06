//! SSE Streaming Types for ECC Runtime
//! 
//! Minimal implementation for compatibility

/// SSE Frame for streaming responses
#[derive(Debug, Clone)]
pub struct SseFrame {
    pub event_type: String,
    pub data: String,
    pub id: Option<String>,
}

impl SseFrame {
    /// Create new frame
    pub fn new(event_type: impl Into<String>, data: impl Into<String>) -> Self {
        Self {
            event_type: event_type.into(),
            data: data.into(),
            id: None,
        }
    }
}

/// SSE Stream trait
pub trait SseStream: Iterator<Item = SseFrame> + Send {}

impl<T> SseStream for T where T: Iterator<Item = SseFrame> + Send {}
