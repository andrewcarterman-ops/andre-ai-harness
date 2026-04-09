
# SUB-AGENT SPEZIFIKATION: SSE Streaming Integration
## Task: Integriere claw-code SSE Streaming in OpenClaw Secure API Client

---

## KONTEXT

**Quelle:** claw-code/rust/crates/api/src/stream.rs
**Ziel:** ~/.openclaw/workspace/skills/secure-api-client/
**Bestehend:** Secure API Client Skill mit Auth/Rate Limiting

---

## EXTRAHIERTE KOMPONENTEN (aus claw-code)

### 1. SseStreamParser
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

### 2. Retry Logic (aus client.rs)
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

## INTEGRATIONSSCHRITTE

### Schritt 1: Kopiere SseStreamParser
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

    pub fn feed(&mut self, chunk: &str) -> Result<Vec<SseFrame>, SseParseError> {
        self.buffer.push_str(chunk);

        // Check max frame size
        if self.buffer.len() > self.max_frame_bytes {
            return Err(SseParseError::FrameTooLarge);
        }

        // Parse complete frames
        let mut frames = Vec::new();
        while let Some(frame) = self.parse_frame() {
            // Filter ping messages
            if frame.event_type != "ping" {
                frames.push(frame);
            }
        }

        Ok(frames)
    }

    pub fn flush(&mut self) -> Vec<SseFrame> {
        let remaining = std::mem::take(&mut self.buffer);
        if !remaining.is_empty() {
            // Attempt to parse final frame
            if let Some(frame) = self.try_parse(&remaining) {
                if frame.event_type != "ping" {
                    return vec![frame];
                }
            }
        }
        vec![]
    }

    fn parse_frame(&mut self) -> Option<SseFrame> {
        // Look for double newline (frame boundary)
        if let Some(pos) = self.buffer.find("\n\n") {
            let frame_text = self.buffer[..pos].to_string();
            self.buffer = self.buffer[pos + 2..].to_string();
            self.try_parse(&frame_text)
        } else {
            None
        }
    }

    fn try_parse(&self, text: &str) -> Option<SseFrame> {
        let mut event_type = "message".to_string();
        let mut data = String::new();
        let mut id = None;

        for line in text.lines() {
            if let Some((key, value)) = line.split_once(':') {
                match key.trim() {
                    "event" => event_type = value.trim().to_string(),
                    "data" => {
                        if !data.is_empty() {
                            data.push('\n');
                        }
                        data.push_str(value.trim());
                    }
                    "id" => id = Some(value.trim().to_string()),
                    _ => {} // Ignore unknown fields
                }
            }
        }

        if data.is_empty() {
            None
        } else {
            Some(SseFrame { event_type, data, id })
        }
    }
}

#[derive(Debug)]
pub enum SseParseError {
    FrameTooLarge,
    InvalidEncoding,
}
```

### Schritt 2: Integriere mit bestehendem Auth
```rust
// skills/secure-api-client/src/lib.rs

pub struct SecureStreamingClient {
    http_client: reqwest::Client,
    auth_manager: AuthManager,
    rate_limiter: RateLimiter,
    retry_policy: ExponentialBackoff,
    sse_parser: SseStreamParser,
}

impl SecureStreamingClient {
    pub async fn stream_request(
        &self,
        request: StreamingRequest,
    ) -> Result<impl Stream<Item = Result<SseFrame, ClientError>>, ClientError> {
        // Apply rate limiting
        self.rate_limiter.acquire().await?;

        // Build request with auth
        let mut builder = self.http_client
            .post(&request.url)
            .headers(request.headers)
            .json(&request.body);

        // Add auth headers
        let auth_headers = self.auth_manager.get_headers().await?;
        for (key, value) in auth_headers {
            builder = builder.header(key, value);
        }

        // Execute with retry
        let response = self.execute_with_retry(builder).await?;

        // Stream response body
        let stream = response.bytes_stream();
        let parser = Arc::new(Mutex::new(self.sse_parser.clone()));

        Ok(stream.then(move |chunk| {
            let parser = parser.clone();
            async move {
                match chunk {
                    Ok(bytes) => {
                        let text = String::from_utf8_lossy(&bytes);
                        let mut p = parser.lock().await;
                        p.feed(&text).map_err(|e| ClientError::Parse(e))
                    }
                    Err(e) => Err(ClientError::Network(e)),
                }
            }
        }).flatten())
    }

    async fn execute_with_retry(
        &self,
        builder: RequestBuilder,
    ) -> Result<Response, ClientError> {
        let mut attempt = 0;
        loop {
            match builder.try_clone().unwrap().send().await {
                Ok(response) => {
                    let status = response.status();
                    if status.is_success() {
                        return Ok(response);
                    }

                    // Check if retryable
                    if !self.is_retryable(status) || attempt >= self.retry_policy.max_retries {
                        return Err(ClientError::Http(status));
                    }
                }
                Err(e) => {
                    if attempt >= self.retry_policy.max_retries {
                        return Err(ClientError::Network(e));
                    }
                }
            }

            attempt += 1;
            let delay = self.retry_policy.calculate_delay(attempt);
            tokio::time::sleep(delay).await;
        }
    }

    fn is_retryable(&self, status: StatusCode) -> bool {
        matches!(
            status.as_u16(),
            408 | 429 | 500..=599
        )
    }
}
```

### Schritt 3: Token Tracking (Anthropic-spezifisch)
```rust
#[derive(Debug, Default)]
pub struct TokenUsage {
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub cache_creation_input_tokens: u64,
    pub cache_read_input_tokens: u64,
}

impl TokenUsage {
    pub fn from_headers(headers: &HeaderMap) -> Option<Self> {
        Some(Self {
            input_tokens: parse_header_u64(headers, "anthropic-input-tokens")?,
            output_tokens: parse_header_u64(headers, "anthropic-output-tokens")?,
            cache_creation_input_tokens: parse_header_u64(
                headers, 
                "anthropic-cache-creation-input-tokens"
            ).unwrap_or(0),
            cache_read_input_tokens: parse_header_u64(
                headers,
                "anthropic-cache-read-input-tokens"
            ).unwrap_or(0),
        })
    }

    pub fn total_cost(&self, input_price: f64, output_price: f64, cache_price: f64) -> f64 {
        let input_cost = (self.input_tokens as f64 / 1_000_000.0) * input_price;
        let output_cost = (self.output_tokens as f64 / 1_000_000.0) * output_price;
        let cache_cost = (self.cache_read_input_tokens as f64 / 1_000_000.0) * cache_price;
        input_cost + output_cost + cache_cost
    }
}
```

---

## TESTS

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sse_parse_simple() {
        let mut parser = SseStreamParser::new(1024);
        let frames = parser.feed("data: hello\n\n").unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].data, "hello");
    }

    #[test]
    fn test_sse_parse_multiline() {
        let mut parser = SseStreamParser::new(1024);
        let frames = parser.feed("data: line1\ndata: line2\n\n").unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].data, "line1\nline2");
    }

    #[test]
    fn test_sse_filter_ping() {
        let mut parser = SseStreamParser::new(1024);
        let frames = parser.feed("event: ping\n\ndata: hello\n\n").unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].data, "hello");
    }

    #[test]
    fn test_sse_partial_frame() {
        let mut parser = SseStreamParser::new(1024);
        let frames1 = parser.feed("data: hel").unwrap();
        assert!(frames1.is_empty());

        let frames2 = parser.feed("lo\n\n").unwrap();
        assert_eq!(frames2.len(), 1);
        assert_eq!(frames2[0].data, "hello");
    }
}
```

---

## AKZEPTANZKRITERIEN

- [ ] SSE Parser korrekt geparst: simple frames, multiline, partial chunks
- [ ] Ping messages werden gefiltert
- [ ] Retry-Logik: 408, 429, 5xx mit Exponential Backoff
- [ ] Auth-Header werden korrekt hinzugefuegt
- [ ] Token-Tracking: input, output, cache tokens
- [ ] Rate-Limiting funktioniert vor Requests
- [ ] Alle Tests passen

---

## OUTPUT

Erstelle:
1. `skills/secure-api-client/src/streaming.rs`
2. Update `skills/secure-api-client/src/lib.rs`
3. Update `skills/secure-api-client/Cargo.toml` (Dependencies)
4. Tests in `skills/secure-api-client/tests/streaming_tests.rs`
