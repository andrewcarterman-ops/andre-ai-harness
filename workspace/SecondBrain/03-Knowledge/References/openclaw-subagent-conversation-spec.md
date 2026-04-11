---
date: 01-04-2026
type: reference
category: openclaw
source: "vault-archive/Kimi_Agent_OpenClaw GitHub/"
tags: [reference, openclaw, subagent, conversation, runtime, rust]
---

# Sub-Agent Spezifikation: Conversation Runtime Loop

> Integriere claw-code Conversation Loop mit ECC Safety

---

## Kontext

| Eigenschaft | Wert |
|-------------|------|
| **Quelle** | claw-code/rust/crates/runtime/src/conversation.rs |
| **Ziel** | ~/.openclaw/workspace/crates/ecc-runtime/ |
| **Bestehend** | Sub-Agent Orchestration, ACP-Protokoll |

---

## Kern-Komponenten

### ConversationRuntime
```rust
pub struct ConversationRuntime<C, T> 
where
    C: ApiClient,
    T: ToolExecutor,
{
    client: C,
    tools: T,
    session: Session,
    config: RuntimeConfig,
}

pub struct RuntimeConfig {
    pub max_iterations: usize,      // default: 16
    pub max_context_tokens: usize,  // default: 102400 (80% of 128K)
    pub timeout_seconds: u64,       // default: 300
    pub max_retries: u32,           // default: 3
}
```

### Agent Loop Pattern
```
User message → API call → Parse response → Execute tools → Feed results → Repeat
```

---

## ECC-Erweiterungen

### SafetyGuard Trait
```rust
#[async_trait]
pub trait SafetyGuard: Send + Sync {
    /// Validate tool call before execution
    async fn validate_tool_call(
        &self,
        tool: &str,
        args: &Value
    ) -> Result<(), SafetyViolation>;

    /// Validate file access path
    fn validate_file_access(&self, path: &Path) -> Result<(), SafetyViolation>;

    /// Validate network request
    fn validate_network_request(&self, url: &Url) -> Result<(), SafetyViolation>;

    /// Log security event
    async fn log_event(&self, event: SecurityEvent);
}

pub struct FortKnoxGuard {
    allowed_paths: Vec<PathBuf>,
    blocked_paths: Vec<PathBuf>,
    allowed_domains: Vec<String>,
    audit_logger: AuditLogger,
}
```

### FortKnox Implementation
```rust
#[async_trait]
impl SafetyGuard for FortKnoxGuard {
    async fn validate_tool_call(&self, 
        tool: &str, 
        args: &Value
    ) -> Result<(), SafetyViolation> {
        match tool {
            "bash" | "shell" => {
                self.validate_bash_args(args).await
            }
            "file_write" | "file_edit" => {
                let path = args.get("path")
                    .and_then(|v| v.as_str())
                    .ok_or(SafetyViolation::MissingPath)?;
                self.validate_file_access(Path::new(path))
            }
            "http_request" => {
                let url = args.get("url")
                    .and_then(|v| v.as_str())
                    .ok_or(SafetyViolation::MissingUrl)?;
                let url = Url::parse(url)
                    .map_err(|_| SafetyViolation::InvalidUrl)?;
                self.validate_network_request(&url)
            }
            _ => Ok(()), // Unknown tools pass through
        }
    }

    fn validate_file_access(&self, 
        path: &Path
    ) -> Result<(), SafetyViolation> {
        // Check blocked paths first
        for blocked in &self.blocked_paths {
            if path.starts_with(blocked) {
                return Err(SafetyViolation::BlockedPath {
                    path: path.to_path_buf(),
                    reason: "Path in blocked list".to_string(),
                });
            }
        }

        // Check allowed paths
        let allowed = self.allowed_paths.iter()
            .any(|allowed| path.starts_with(allowed));

        if !allowed {
            return Err(SafetyViolation::PathOutsideSandbox {
                path: path.to_path_buf(),
                allowed_roots: self.allowed_paths.clone(),
            });
        }

        Ok(())
    }

    fn validate_network_request(&self, 
        url: &Url
    ) -> Result<(), SafetyViolation> {
        let domain = url.host_str()
            .ok_or(SafetyViolation::InvalidUrl)?;

        let allowed = self.allowed_domains.iter()
            .any(|allowed| domain.ends_with(allowed));

        if !allowed {
            return Err(SafetyViolation::DomainNotAllowed {
                domain: domain.to_string(),
                allowed: self.allowed_domains.clone(),
            });
        }

        Ok(())
    }

    async fn log_event(&self, 
        event: SecurityEvent
    ) {
        self.audit_logger.log(event).await;
    }
}
```

---

## Erweiterter Conversation Loop

### EccConversationRuntime
```rust
pub struct EccConversationRuntime<C, T, G, M>
where
    C: ApiClient,
    T: ToolExecutor,
    G: SafetyGuard,
    M: MemoryBridge,
{
    // From claw-code
    base: ConversationRuntime<C, T>,

    // ECC extensions
    safety_guard: G,
    memory_bridge: M,
    compaction_engine: CompactionEngine,
}

impl<C, T, G, M> EccConversationRuntime<C, T, G, M> {
    pub async fn run(&mut self, user_message: String) -> Result<ConversationResult> {
        // 1. Add user message to session
        self.base.session.add_message(Message::user(user_message));

        let mut iterations = 0;
        loop {
            iterations += 1;
            if iterations > self.base.config.max_iterations {
                return Err(Error::MaxIterationsReached);
            }

            // 2. Check token limit and compact if needed
            self.compact_if_needed().await?;

            // 3. Build prompt with context
            let prompt = self.build_prompt().await;

            // 4. Stream request to API
            let response = self.stream_with_retry(&prompt).await?;

            // 5. Process response
            match response {
                Response::Text(text) => {
                    self.base.session.add_message(Message::assistant(text));
                    break;
                }
                Response::ToolCalls(calls) => {
                    // 6. Safety check BEFORE execution
                    for call in &calls {
                        if let Err(violation) = self.safety_guard
                            .validate_tool_call(&call.tool, &call.args)
                            .await {
                            self.handle_safety_violation(violation).await?;
                            continue;
                        }
                    }

                    // 7. Execute tools
                    let results = self.execute_tools(calls).await?;

                    // 8. Feed results back
                    for result in results {
                        self.base.session.add_message(Message::tool_result(result));
                    }
                }
            }
        }

        // 9. Sync to memory systems
        self.memory_bridge.sync(&self.base.session).await?;

        Ok(ConversationResult {
            final_message: self.base.session.last_message().cloned(),
            iterations,
        })
    }

    async fn compact_if_needed(&mut self
    ) -> Result<()> {
        let tokens = self.estimate_tokens();
        if tokens > self.base.config.max_context_tokens {
            self.compaction_engine
                .compact(&mut self.base.session)
                .await?;
        }
        Ok(())
    }

    async fn build_prompt(&self
    ) -> Prompt {
        let context = PromptContext {
            soul_md: self.load_soul_md().await,
            user_md: self.load_user_md().await,
            memory_md: self.load_memory_md().await,
            recent_sessions: self.load_recent_sessions(5).await,
        };

        Prompt::assemble(context, &self.base.session.messages)
    }
}
```

---

## Prompt Assembly

### PromptContext
```rust
pub struct PromptContext {
    pub soul_md: String,           // Agent identity
    pub user_md: String,           // User profile
    pub memory_md: String,         // Curated long-term memory
    pub recent_sessions: Vec<SessionSummary>,
}

pub struct Prompt;

impl Prompt {
    pub fn assemble(
        context: PromptContext, 
        messages: &[Message]
    ) -> String {
        let system = format!(
            "You are {}.\n\nUser Profile:\n{}\n\nKey Memories:\n{}\n\nRecent Context:\n{}",
            context.soul_md,
            context.user_md,
            context.memory_md,
            format_recent_sessions(&context.recent_sessions)
        );

        // Build message sequence
        let mut parts = vec![format!("<system>{}\n\nYou have access to tools. Use them when appropriate.</system>", system)];
        parts.extend(messages.iter().map(|m| m.to_string()));

        parts.join("\n\n")
    }
}
```

---

## Retry-Logik

```rust
impl<C, T, G, M> EccConversationRuntime<C, T, G, M> {
    async fn stream_with_retry(
        &self,
        prompt: &str
    ) -> Result<Response> {
        let mut retries = 0;
        let mut backoff = ExponentialBackoff::new(
            Duration::from_millis(1000),
            Duration::from_millis(60000),
        );

        loop {
            match self.base.client.complete(prompt).await {
                Ok(response) => return Ok(response),
                Err(e) if e.is_retryable() && retries < self.base.config.max_retries => {
                    retries += 1;
                    let delay = backoff.next_delay();
                    tokio::time::sleep(delay).await;
                }
                Err(e) => return Err(e.into()),
            }
        }
    }
}

pub struct ExponentialBackoff {
    base: Duration,
    max: Duration,
    current: Duration,
    jitter: f64, // ±25%
}

impl ExponentialBackoff {
    pub fn next_delay(&mut self
    ) -> Duration {
        let jittered = self.current.as_millis() as f64 
            * (1.0 + (rand::random::<f64>() - 0.5) * self.jitter);
        
        let next = Duration::from_millis(jittered as u64);
        self.current = std::cmp::min(self.current * 2, self.max);
        
        next
    }
}
```

---

## Output Dateien

1. `crates/ecc-runtime/src/lib.rs`
2. `crates/ecc-runtime/src/runtime.rs`
3. `crates/ecc-runtime/src/safety.rs` (FortKnoxGuard)
4. `crates/ecc-runtime/src/prompt.rs`
5. `crates/ecc-runtime/src/retry.rs`
6. `crates/ecc-runtime/Cargo.toml`
