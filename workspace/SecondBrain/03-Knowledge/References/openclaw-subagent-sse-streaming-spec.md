---
date: 01-04-2026
type: reference
category: openclaw
source: "vault-archive/Kimi_Agent_OpenClaw GitHub/"
tags: [reference, openclaw, subagent, sse, streaming, rust]
---

# Sub-Agent Spezifikation: SSE Streaming Integration

> Integriere claw-code SSE Streaming in OpenClaw Secure API Client

---

## Kontext

| Eigenschaft | Wert |
|-------------|------|
| **Quelle** | claw-code/rust/crates/api/src/stream.rs |
| **Ziel** | ~/.openclaw/workspace/skills/secure-api-client/ |
| **Bestehend** | Secure API Client Skill mit Auth/Rate Limiting |

---

## Extrahierte Komponenten

### SseStreamParser
```rust
pub struct SseStreamParser {
    buffer: String,
    max_frame_bytes: usize,
}

pub struct SseFrame {
    pub event_type: String,
    pub data: String,
    pub id: Option<String>,
}
```

**Key Features:**
- Incremental frame parsing with buffering
- Multi-line SSE frame handling
- Ping filtering (keepalive messages)
- Frame size limits
- JSON object boundary handling across packet boundaries

### Retry Logic
```rust
pub struct ExponentialBackoff {
    base_ms: u64,      // 1000ms
    max_ms: u64,       // 60000ms
    max_retries: u32,  // 7
    jitter: f64,       // ±25%
}

// Retryable status codes: 408, 429, 5xx
```

---

## Integrationsschritte

### Schritt 1: SseStreamParser
```rust
// skills/secure-api-client/src/streaming.rs

use std::collections::VecDeque;

pub struct SseStreamParser {
    buffer: String,
    max_frame_bytes: usize,
    pending_frames: VecDeque<SseFrame>,
}

#[derive(Debug, Clone)]
pub struct SseFrame {
    pub event_type: String,
    pub data: String,
    pub id: Option<String>,
}

impl SseStreamParser {
    pub fn new(max_frame_bytes: usize) -> Self {
        Self {
            buffer: String::new(),
            max_frame_bytes,
            pending_frames: VecDeque::new(),
        }
    }

    /// Parse incoming data chunk, returning complete frames
    pub fn parse_chunk(&mut self, chunk: &str) -> Result<Vec<SseFrame>> {
        self.buffer.push_str(chunk);

        // Check size limit
        if self.buffer.len() > self.max_frame_bytes {
            return Err(SseError::BufferOverflow);
        }

        let mut frames = vec![];

        // Process complete frames (delimited by \n\n)
        while let Some(pos) = self.buffer.find("\n\n") {
            let frame_text = self.buffer[..pos].to_string();
            self.buffer = self.buffer[pos + 2..].to_string();

            if let Some(frame) = self.parse_frame(&frame_text) {
                // Filter ping frames
                if !self.is_ping(&frame) {
                    frames.push(frame);
                }
            }
        }

        Ok(frames)
    }

    fn parse_frame(&self, text: &str
    ) -> Option<SseFrame> {
        let mut event_type = "message".to_string();
        let mut data_lines = vec![];
        let mut id = None;

        for line in text.lines() {
            if line.starts_with("event:") {
                event_type = line[6..].trim().to_string();
            } else if line.starts_with("data:") {
                data_lines.push(line[5..].trim());
            } else if line.starts_with("id:") {
                id = Some(line[3..].trim().to_string());
            }
            // Ignore other fields (retry, etc.)
        }

        if data_lines.is_empty() {
            return None;
        }

        Some(SseFrame {
            event_type,
            data: data_lines.join("\n"),
            id,
        })
    }

    fn is_ping(&self, frame: &SseFrame
    ) -> bool {
        // Ping frames often have empty data or specific event type
        frame.data.is_empty() || frame.event_type == "ping"
    }
}
```

### Schritt 2: Streaming API Client
```rust
use reqwest::Client;
use futures::StreamExt;

pub struct StreamingApiClient {
    http_client: Client,
    base_url: String,
    auth_token: String,
    sse_parser: SseStreamParser,
    backoff: ExponentialBackoff,
}

impl StreamingApiClient {
    pub async fn stream_completion(
        &mut self,
        request: CompletionRequest
    ) -> Result<impl Stream<Item = Result<SseFrame>>> {
        let mut retries = 0;

        loop {
            match self.try_stream(&request).await {
                Ok(stream) => return Ok(stream),
                Err(e) if e.is_retryable() && retries < self.backoff.max_retries => {
                    retries += 1;
                    let delay = self.backoff.next_delay();
                    tokio::time::sleep(delay).await;
                }
                Err(e) => return Err(e),
            }
        }
    }

    async fn try_stream(
        &self,
        request: &CompletionRequest
    ) -> Result<impl Stream<Item = Result<SseFrame>>> {
        let response = self.http_client
            .post(format!("{}/v1/chat/completions", self.base_url))
            .header("Authorization", format!("Bearer {}", self.auth_token))
            .header("Content-Type", "application/json")
            .json(request)
            .send()
            .await?;

        // Check for retryable status codes
        match response.status().as_u16() {
            408 | 429 | 500..=599 => {
                return Err(ApiError::Retryable(response.status()));
            }
            _ => {}
        }

        let mut parser = SseStreamParser::new(1024 * 1024); // 1MB max

        let stream = response.bytes_stream()
            .map(move |chunk| {
                let text = String::from_utf8_lossy(&chunk?);
                parser.parse_chunk(&text)
            })
            .filter_map(|result| async move {
                match result {
                    Ok(frames) => Some(Ok(frames)),
                    Err(e) => Some(Err(e)),
                }
            })
            .flat_map(|frames| futures::stream::iter(frames.unwrap_or_default()));

        Ok(stream)
    }
}
```

### Schritt 3: Integration mit Secure API Client
```rust
// skills/secure-api-client/src/lib.rs

pub struct SecureApiClient {
    base_client: StreamingApiClient,
    rate_limiter: RateLimiter,
    auth_manager: AuthManager,
}

impl SecureApiClient {
    pub async fn secure_stream(
        &mut self,
        request: CompletionRequest
    ) -> Result<impl Stream<Item = Result<SseFrame>>> {
        // Check rate limit
        self.rate_limiter.check().await?;

        // Refresh auth if needed
        self.auth_manager.ensure_valid().await?;

        // Make request with auth
        let token = self.auth_manager.token().await?;
        self.base_client.set_auth_token(token);

        // Stream with automatic retry
        Ok(self.base_client.stream_completion(request).await?)
    }
}
```

---

## Rate Limiting Integration

```rust
pub struct RateLimiter {
    requests_per_minute: u32,
    window_start: Instant,
    request_count: u32,
}

impl RateLimiter {
    pub async fn check(&mut self
    ) -> Result<()> {
        let now = Instant::now();
        
        // Reset window if expired
        if now.duration_since(self.window_start) >= Duration::from_secs(60) {
            self.window_start = now;
            self.request_count = 0;
        }

        // Check limit
        if self.request_count >= self.requests_per_minute {
            let wait = Duration::from_secs(60) - now.duration_since(self.window_start);
            return Err(RateLimitError::Exceeded { retry_after: wait });
        }

        self.request_count += 1;
        Ok(())
    }
}
```

---

## Exponential Backoff

```rust
pub struct ExponentialBackoff {
    base_ms: u64,
    max_ms: u64,
    max_retries: u32,
    jitter: f64,
    attempt: u32,
}

impl ExponentialBackoff {
    pub fn next_delay(&mut self
    ) -> Duration {
        let exp = 2u64.pow(self.attempt.min(6)); // Cap at 2^6 = 64
        let delay_ms = (self.base_ms * exp).min(self.max_ms);
        
        // Apply jitter: ±25%
        let jitter_factor = 1.0 + (rand::random::<f64>() - 0.5) * self.jitter;
        let final_ms = (delay_ms as f64 * jitter_factor) as u64;

        self.attempt += 1;
        Duration::from_millis(final_ms)
    }

    pub fn reset(&mut self) {
        self.attempt = 0;
    }
}
```

---

## Test-Beispiele

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_simple_frame() {
        let mut parser = SseStreamParser::new(1024);
        let chunk = "data: hello world\n\n";
        
        let frames = parser.parse_chunk(chunk).unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].data, "hello world");
    }

    #[test]
    fn test_parse_multiline_data() {
        let mut parser = SseStreamParser::new(1024);
        let chunk = "data: line 1\ndata: line 2\n\n";
        
        let frames = parser.parse_chunk(chunk).unwrap();
        assert_eq!(frames[0].data, "line 1\nline 2");
    }

    #[test]
    fn test_filter_ping() {
        let mut parser = SseStreamParser::new(1024);
        let chunk = "event: ping\n\ndata: real message\n\n";
        
        let frames = parser.parse_chunk(chunk).unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].data, "real message");
    }

    #[test]
    fn test_partial_frame_buffering() {
        let mut parser = SseStreamParser::new(1024);
        
        // First chunk - incomplete
        let frames1 = parser.parse_chunk("data: partial").unwrap();
        assert!(frames1.is_empty());
        
        // Second chunk - completes frame
        let frames2 = parser.parse_chunk(" message\n\n").unwrap();
        assert_eq!(frames2.len(), 1);
        assert_eq!(frames2[0].data, "partial message");
    }
}
```

---

## Output Dateien

1. `skills/secure-api-client/src/streaming.rs` (SseStreamParser)
2. `skills/secure-api-client/src/retry.rs` (ExponentialBackoff)
3. `skills/secure-api-client/src/streaming_client.rs`
4. Tests in `skills/secure-api-client/tests/streaming_tests.rs`
