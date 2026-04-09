
# SUB-AGENT SPEZIFIKATION: Conversation Runtime Loop
## Task: Integriere claw-code Conversation Loop mit ECC Safety

---

## KONTEXT

**Quelle:** claw-code/rust/crates/runtime/src/conversation.rs
**Ziel:** ~/.openclaw/workspace/crates/ecc-runtime/
**Bestehend:** Sub-Agent Orchestration, ACP-Protokoll

---

## KERN-KOMPONENTEN (aus claw-code)

### ConversationRuntime<C, T>
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

## ECC-ERWEITERUNGEN

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

#[async_trait]
impl SafetyGuard for FortKnoxGuard {
    async fn validate_tool_call(&self, tool: &str, args: &Value) -> Result<(), SafetyViolation> {
        // Check tool against policy
        match tool {
            "bash" => self.validate_bash_args(args).await,
            "write" | "edit" => self.validate_file_mutation(args).await,
            "web_fetch" => self.validate_web_request(args).await,
            _ => Ok(()),
        }
    }

    fn validate_file_access(&self, path: &Path) -> Result<(), SafetyViolation> {
        // Check if path is within allowed directories
        let canonical = path.canonicalize()
            .map_err(|_| SafetyViolation::InvalidPath)?;

        for allowed in &self.allowed_paths {
            if canonical.starts_with(allowed) {
                // Check blocked subpaths
                for blocked in &self.blocked_paths {
                    if canonical.starts_with(blocked) {
                        return Err(SafetyViolation::BlockedPath);
                    }
                }
                return Ok(());
            }
        }

        Err(SafetyViolation::PathOutsideSandbox)
    }

    fn validate_network_request(&self, url: &Url) -> Result<(), SafetyViolation> {
        let host = url.host_str()
            .ok_or(SafetyViolation::InvalidUrl)?;

        for allowed in &self.allowed_domains {
            if host == allowed || host.ends_with(&format!(".{}", allowed)) {
                return Ok(());
            }
        }

        Err(SafetyViolation::DomainNotAllowed)
    }

    async fn log_event(&self, event: SecurityEvent) {
        self.audit_logger.log(event).await;
    }
}
```

### MemoryBridge
```rust
pub struct MemoryBridge {
    obsidian_vault: PathBuf,
    daily_log_dir: PathBuf,
    memory_file: PathBuf,
}

impl MemoryBridge {
    pub async fn sync_conversation(&self, session: &Session) -> Result<()> {
        // 1. Write to daily log
        self.write_daily_log(session).await?;

        // 2. Update MEMORY.md if significant
        if self.is_significant(session) {
            self.update_memory_md(session).await?;
        }

        // 3. Sync to Second Brain
        self.sync_to_obsidian(session).await?;

        Ok(())
    }

    async fn write_daily_log(&self, session: &Session) -> Result<()> {
        let today = chrono::Local::now().format("%Y-%m-%d");
        let log_path = self.daily_log_dir.join(format!("{}.md", today));

        let entry = format!(
            "## Session: {}\n\n**Model:** {}\n**Duration:** {}s\n\n### Summary\n{}\n\n---\n\n",
            session.id,
            session.model,
            session.duration_secs(),
            session.summary()
        );

        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&log_path)
            .await?;

        file.write_all(entry.as_bytes()).await?;
        Ok(())
    }

    async fn update_memory_md(&self, session: &Session) -> Result<()> {
        // Extract key insights
        let insights = self.extract_insights(session);

        // Append to MEMORY.md
        let mut content = tokio::fs::read_to_string(&self.memory_file).await?;
        content.push_str(&format!("\n## {}\n\n", chrono::Local::now().format("%Y-%m-%d")));
        for insight in insights {
            content.push_str(&format!("- {}\n", insight));
        }

        tokio::fs::write(&self.memory_file, content).await?;
        Ok(())
    }

    fn is_significant(&self, session: &Session) -> bool {
        // Criteria for significance
        session.token_usage.total() > 10000 ||
        session.tools_used.iter().any(|t| t == "bash" || t == "write") ||
        session.duration_secs() > 300
    }
}
```

---

## IMPLEMENTIERUNG: EccConversationRuntime

```rust
pub struct EccConversationRuntime<C, T, S, M> 
where
    C: ApiClient,
    T: ToolExecutor,
    S: SafetyGuard,
    M: MemoryBridge,
{
    // Core (from claw-code)
    client: C,
    tools: T,
    session: Session,
    config: EccRuntimeConfig,

    // ECC extensions
    safety_guard: S,
    memory_bridge: M,
    compaction_engine: CompactionEngine,
}

pub struct EccRuntimeConfig {
    // From claw-code
    pub max_iterations: usize,
    pub max_context_tokens: usize,
    pub timeout_seconds: u64,
    pub max_retries: u32,

    // ECC-specific
    pub fort_knox_enabled: bool,
    pub auto_compact: bool,
    pub memory_sync_interval: Duration,
}

impl<C, T, S, M> EccConversationRuntime<C, T, S, M>
where
    C: ApiClient,
    T: ToolExecutor,
    S: SafetyGuard,
    M: MemoryBridge,
{
    pub async fn run(&mut self, user_message: &str) -> Result<ConversationResult, RuntimeError> {
        // 1. Safety check on user message
        if self.config.fort_knox_enabled {
            self.safety_guard.validate_input(user_message).await?;
        }

        // 2. Add user message
        self.session.add_user_message(user_message);

        let mut iteration = 0;
        let start_time = Instant::now();

        loop {
            // Safety: iteration limit
            if iteration >= self.config.max_iterations {
                self.memory_bridge.sync_conversation(&self.session).await?;
                return Ok(ConversationResult::MaxIterationsReached);
            }
            iteration += 1;

            // Timeout check
            if start_time.elapsed().as_secs() > self.config.timeout_seconds {
                self.memory_bridge.sync_conversation(&self.session).await?;
                return Ok(ConversationResult::Timeout);
            }

            // 3. Check token budget and compact if needed
            if self.config.auto_compact && self.should_compact() {
                self.compaction_engine.compact(&mut self.session).await?;
            }

            // 4. Build system prompt with ECC context
            let system_prompt = self.build_ecc_system_prompt();

            // 5. Stream request
            let mut stream = self.client.stream_request(Request {
                system: system_prompt,
                messages: self.session.messages.clone(),
                tools: self.tools.available_tools(),
            }).await?;

            // 6. Process stream
            let mut assistant_message = String::new();
            let mut tool_uses = Vec::new();

            while let Some(frame) = stream.next().await {
                match frame {
                    Ok(SseFrame::Content(text)) => {
                        assistant_message.push_str(&text);
                        // Stream to UI if needed
                    }
                    Ok(SseFrame::ToolUse(tool_use)) => {
                        // Pre-validate tool
                        if self.config.fort_knox_enabled {
                            if let Err(e) = self.safety_guard.validate_tool_call(
                                &tool_use.name,
                                &tool_use.arguments
                            ).await {
                                self.safety_guard.log_event(SecurityEvent::BlockedToolCall {
                                    tool: tool_use.name.clone(),
                                    reason: e.to_string(),
                                }).await;
                                continue;
                            }
                        }
                        tool_uses.push(tool_use);
                    }
                    Ok(SseFrame::Done) => break,
                    Err(e) => return Err(RuntimeError::Stream(e)),
                }
            }

            // 7. Add assistant message
            self.session.add_assistant_message(&assistant_message, &tool_uses);

            // 8. Execute tools with safety
            if tool_uses.is_empty() {
                // No tools, conversation complete
                self.memory_bridge.sync_conversation(&self.session).await?;
                return Ok(ConversationResult::Complete);
            }

            for tool_use in tool_uses {
                let result = self.execute_tool_with_safety(tool_use).await?;
                self.session.add_tool_result(&tool_use.id, &result);
            }

            // Sync memory periodically
            if iteration % 5 == 0 {
                self.memory_bridge.sync_conversation(&self.session).await?;
            }
        }
    }

    async fn execute_tool_with_safety(
        &self,
        tool_use: ToolUse
    ) -> Result<ToolResult, RuntimeError> {
        // Check permission (from claw-code)
        if !self.check_permission(&tool_use).await? {
            return Ok(ToolResult {
                content: "Permission denied".to_string(),
                is_error: true,
                metadata: None,
            });
        }

        // Execute with timeout
        match timeout(
            Duration::from_secs(60),
            self.tools.execute(tool_use)
        ).await {
            Ok(Ok(result)) => Ok(result),
            Ok(Err(e)) => Ok(ToolResult {
                content: format!("Tool error: {}", e),
                is_error: true,
                metadata: None,
            }),
            Err(_) => Ok(ToolResult {
                content: "Tool execution timeout".to_string(),
                is_error: true,
                metadata: None,
            }),
        }
    }

    fn build_ecc_system_prompt(&self) -> String {
        let mut prompt = String::new();

        // Base instructions
        prompt.push_str(&include_str!("../../SOUL.md"));
        prompt.push_str("\n\n");

        // User context
        prompt.push_str(&include_str!("../../USER.md"));
        prompt.push_str("\n\n");

        // Relevant memory
        if let Ok(memory) = std::fs::read_to_string("../../MEMORY.md") {
            prompt.push_str("## Relevant Memory\n");
            prompt.push_str(&memory);
            prompt.push_str("\n\n");
        }

        // Compacted history
        if let Some(summary) = &self.session.compacted_summary {
            prompt.push_str("## Previous Conversation Summary\n");
            prompt.push_str(summary);
            prompt.push_str("\n\n");
        }

        prompt
    }

    fn should_compact(&self) -> bool {
        let estimated = self.session.estimate_tokens();
        estimated > self.config.max_context_tokens
    }
}
```

---

## AKZEPTANZKRITERIEN

- [ ] Conversation Loop laeuft stabil
- [ ] Iteration limit (16) enforced
- [ ] Timeout (5min) enforced
- [ ] SafetyGuard validiert alle Tool Calls
- [ ] MemoryBridge schreibt taegliche Logs
- [ ] MEMORY.md wird bei Signifikanz aktualisiert
- [ ] Compaction funktioniert bei Token-Limit
- [ ] ECC-System-Prompt enthaelt SOUL/USER/MEMORY
- [ ] Alle Tests passen

---

## OUTPUT

Erstelle:
1. `crates/ecc-runtime/src/lib.rs`
2. `crates/ecc-runtime/src/runtime.rs`
3. `crates/ecc-runtime/src/safety.rs`
4. `crates/ecc-runtime/src/memory_bridge.rs`
5. `crates/ecc-runtime/Cargo.toml`
6. Tests in `crates/ecc-runtime/tests/`
