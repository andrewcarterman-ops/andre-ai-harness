//! Secure API Client Skill
//! 
//! HTTP API client with SSE streaming, authentication, rate limiting,
//! and retry logic. Extracted and integrated from claw-code.

pub mod streaming;

pub use streaming::{
    SseStreamParser,
    SseFrame,
    SseParseError,
    TokenUsage,
    ExponentialBackoff,
};

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
