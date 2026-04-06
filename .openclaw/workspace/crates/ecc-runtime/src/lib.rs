//! ECC Conversation Runtime
//! 
//! Extracted from claw-code/rust/crates/runtime/src/conversation.rs
//! Integrated with ECC Safety (Fort Knox) and Memory Bridge (Second Brain)

use std::time::{Duration, Instant};
use serde_json::Value;
use async_trait::async_trait;

pub mod safety;
pub mod memory_bridge;
pub mod streaming;
pub mod mcp_stdio;
pub mod mcp_integration;
pub mod api_client;
pub mod context;
pub mod bridge;

pub use safety::{SafetyGuard, FortKnoxGuard, SafetyViolation};
pub use memory_bridge::{MemoryBridge, ObsidianSync, DailyLogWriter};
pub use streaming::SseFrame;
pub use mcp_stdio::{McpServerManager, McpTool, McpRequest, McpResponse, McpError};
pub use mcp_integration::{McpToolAdapter, McpAdapterError};
pub use api_client::SecureApiClient;
pub use context::{TokenBudgetManager, TokenBudgetConfig, ContextItem, Tier, BudgetStatus};
pub use bridge::{ObsidianBridge, ObsidianConfig, SyncMode, ObsidianBridgeError, SyncResult};

/// Maximum iterations to prevent infinite loops
const DEFAULT_MAX_ITERATIONS: usize = 16;

/// Maximum context tokens (80% of 128K)
const DEFAULT_MAX_CONTEXT_TOKENS: usize = 102_400;

/// Default timeout for conversation
const DEFAULT_TIMEOUT_SECONDS: u64 = 300;

/// Default max retries
const DEFAULT_MAX_RETRIES: u32 = 3;

/// Conversation runtime configuration
#[derive(Debug, Clone)]
pub struct RuntimeConfig {
    /// Maximum iterations before stopping
    pub max_iterations: usize,
    /// Maximum context tokens before compaction
    pub max_context_tokens: usize,
    /// Timeout for entire conversation
    pub timeout_seconds: u64,
    /// Max retries for failed requests
    pub max_retries: u32,
    /// Enable automatic compaction
    pub auto_compact: bool,
    /// Enable Fort Knox safety
    pub fort_knox_enabled: bool,
    /// Enable Second Brain sync
    pub memory_sync_enabled: bool,
}

impl RuntimeConfig {
    /// Create default configuration
    pub fn new() -> Self {
        Self {
            max_iterations: DEFAULT_MAX_ITERATIONS,
            max_context_tokens: DEFAULT_MAX_CONTEXT_TOKENS,
            timeout_seconds: DEFAULT_TIMEOUT_SECONDS,
            max_retries: DEFAULT_MAX_RETRIES,
            auto_compact: true,
            fort_knox_enabled: true,
            memory_sync_enabled: true,
        }
    }

    /// Create permissive configuration (for testing)
    pub fn permissive() -> Self {
        Self {
            max_iterations: 32,
            max_context_tokens: 200_000,
            timeout_seconds: 600,
            max_retries: 5,
            auto_compact: false,
            fort_knox_enabled: false,
            memory_sync_enabled: false,
        }
    }

    /// Create restrictive configuration
    pub fn restrictive() -> Self {
        Self {
            max_iterations: 8,
            max_context_tokens: 50_000,
            timeout_seconds: 120,
            max_retries: 1,
            auto_compact: true,
            fort_knox_enabled: true,
            memory_sync_enabled: true,
        }
    }
}

impl Default for RuntimeConfig {
    fn default() -> Self {
        Self::new()
    }
}

/// Message role in conversation
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MessageRole {
    System,
    User,
    Assistant,
    Tool,
}

impl std::fmt::Display for MessageRole {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::System => write!(f, "system"),
            Self::User => write!(f, "user"),
            Self::Assistant => write!(f, "assistant"),
            Self::Tool => write!(f, "tool"),
        }
    }
}

/// Message in conversation
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Message {
    pub role: MessageRole,
    pub content: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_calls: Option<Vec<ToolCall>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_call_id: Option<String>,
}

impl Message {
    /// Create system message
    pub fn system(content: impl Into<String>) -> Self {
        Self {
            role: MessageRole::System,
            content: content.into(),
            tool_calls: None,
            tool_call_id: None,
        }
    }

    /// Create user message
    pub fn user(content: impl Into<String>) -> Self {
        Self {
            role: MessageRole::User,
            content: content.into(),
            tool_calls: None,
            tool_call_id: None,
        }
    }

    /// Create assistant message
    pub fn assistant(content: impl Into<String>, tool_calls: Option<Vec<ToolCall>>) -> Self {
        Self {
            role: MessageRole::Assistant,
            content: content.into(),
            tool_calls,
            tool_call_id: None,
        }
    }

    /// Create tool result message
    pub fn tool_result(tool_call_id: impl Into<String>, content: impl Into<String>) -> Self {
        Self {
            role: MessageRole::Tool,
            content: content.into(),
            tool_calls: None,
            tool_call_id: Some(tool_call_id.into()),
        }
    }

    /// Estimate token count (naive: chars / 4)
    pub fn estimate_tokens(&self) -> usize {
        self.content.len() / 4
    }
}

/// Tool call from assistant
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ToolCall {
    pub id: String,
    pub name: String,
    pub arguments: Value,
}

impl ToolCall {
    /// Create new tool call
    pub fn new(id: impl Into<String>, name: impl Into<String>, arguments: Value) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            arguments,
        }
    }
}

/// Tool result
#[derive(Debug, Clone)]
pub struct ToolResult {
    pub tool_call_id: String,
    pub content: String,
    pub is_error: bool,
}

impl ToolResult {
    /// Create successful result
    pub fn success(tool_call_id: impl Into<String>, content: impl Into<String>) -> Self {
        Self {
            tool_call_id: tool_call_id.into(),
            content: content.into(),
            is_error: false,
        }
    }

    /// Create error result
    pub fn error(tool_call_id: impl Into<String>, content: impl Into<String>) -> Self {
        Self {
            tool_call_id: tool_call_id.into(),
            content: content.into(),
            is_error: true,
        }
    }
}

/// Tool definition for API
#[derive(Debug, Clone, serde::Serialize)]
pub struct ToolDefinition {
    pub name: String,
    pub description: String,
    pub parameters: Value,
}

impl ToolDefinition {
    /// Create new tool definition
    pub fn new(name: impl Into<String>, description: impl Into<String>, parameters: Value) -> Self {
        Self {
            name: name.into(),
            description: description.into(),
            parameters,
        }
    }
}

/// Conversation session with token budget
#[derive(Debug, Default)]
pub struct Session {
    pub messages: Vec<Message>,
    pub tool_results: Vec<ToolResult>,
    pub metadata: SessionMetadata,
    pub token_budget: Option<TokenBudgetManager>,
}

/// Session metadata
#[derive(Debug, Clone, Default)]
pub struct SessionMetadata {
    pub created_at: Option<chrono::DateTime<chrono::Utc>>,
    pub updated_at: Option<chrono::DateTime<chrono::Utc>>,
    pub total_tokens: usize,
    pub iteration_count: usize,
    pub compaction_count: usize,
}

impl Session {
    /// Create new session
    pub fn new() -> Self {
        Self {
            messages: Vec::new(),
            tool_results: Vec::new(),
            metadata: SessionMetadata {
                created_at: Some(chrono::Utc::now()),
                updated_at: Some(chrono::Utc::now()),
                total_tokens: 0,
                iteration_count: 0,
                compaction_count: 0,
            },
            token_budget: None,
        }
    }

    /// Create new session with token budget
    pub fn with_token_budget(config: TokenBudgetConfig) -> Self {
        let mut session = Self::new();
        session.token_budget = Some(TokenBudgetManager::new(config));
        session
    }

    /// Add user message
    pub fn add_user_message(&mut self, content: impl Into<String>) {
        self.messages.push(Message::user(content));
        self.update_metadata();
    }

    /// Add assistant message
    pub fn add_assistant_message(&mut self, content: impl Into<String>, tool_calls: Option<Vec<ToolCall>>) {
        self.messages.push(Message::assistant(content, tool_calls));
        self.update_metadata();
    }

    /// Add tool result
    pub fn add_tool_result(&mut self, tool_call_id: impl Into<String>, content: impl Into<String>) {
        let result = ToolResult::success(tool_call_id, content);
        self.tool_results.push(result.clone());
        self.messages.push(Message::tool_result(result.tool_call_id, result.content));
        self.update_metadata();
    }

    /// Add system message
    pub fn add_system_message(&mut self, content: impl Into<String>) {
        self.messages.push(Message::system(content));
        self.update_metadata();
    }

    /// Estimate total tokens
    pub fn estimate_tokens(&self) -> usize {
        self.messages.iter().map(|m| m.estimate_tokens()).sum()
    }

    /// Check if compaction is needed
    pub fn needs_compaction(&self, max_tokens: usize) -> bool {
        self.estimate_tokens() > max_tokens && self.messages.len() > 5
    }

    /// Get recent messages (last n)
    pub fn recent_messages(&self, n: usize) -> &[Message] {
        let start = self.messages.len().saturating_sub(n);
        &self.messages[start..]
    }

    fn update_metadata(&mut self) {
        self.metadata.updated_at = Some(chrono::Utc::now());
        self.metadata.total_tokens = self.estimate_tokens();
    }
}

/// API client trait
#[async_trait]
pub trait ApiClient: Send + Sync {
    /// Stream a request and return SSE frames
    async fn stream_request(
        &self,
        request: ApiRequest,
    ) -> Result<Box<dyn Iterator<Item = SseFrame> + Send>, ApiError>;
}

/// API request
#[derive(Debug, Clone)]
pub struct ApiRequest {
    pub model: String,
    pub system: Option<String>,
    pub messages: Vec<Message>,
    pub tools: Vec<ToolDefinition>,
    pub temperature: Option<f32>,
    pub max_tokens: Option<u32>,
}

impl ApiRequest {
    /// Create new request
    pub fn new(model: impl Into<String>) -> Self {
        Self {
            model: model.into(),
            system: None,
            messages: Vec::new(),
            tools: Vec::new(),
            temperature: None,
            max_tokens: None,
        }
    }

    /// Add system prompt
    pub fn with_system(mut self, system: impl Into<String>) -> Self {
        self.system = Some(system.into());
        self
    }

    /// Add messages
    pub fn with_messages(mut self, messages: Vec<Message>) -> Self {
        self.messages = messages;
        self
    }

    /// Add tools
    pub fn with_tools(mut self, tools: Vec<ToolDefinition>) -> Self {
        self.tools = tools;
        self
    }
}

/// Tool executor trait
#[async_trait]
pub trait ToolExecutor: Send + Sync {
    /// Execute a tool call
    async fn execute(&self, tool_call: &ToolCall) -> Result<ToolResult, ToolError>;
    
    /// Get available tools
    fn available_tools(&self) -> Vec<ToolDefinition>;
}

/// Conversation result
#[derive(Debug, Clone)]
pub enum ConversationResult {
    /// Completed successfully
    Complete { 
        message: String, 
        tool_calls: Vec<ToolCall>,
        iterations: usize,
    },
    /// Reached max iterations
    MaxIterationsReached { 
        last_message: String,
        iterations: usize,
    },
    /// Timeout
    Timeout { 
        last_message: String,
        elapsed: Duration,
    },
    /// Error occurred
    Error(RuntimeError),
}

/// Runtime error
#[derive(Debug, Clone)]
pub enum RuntimeError {
    Api(ApiError),
    Tool(ToolError),
    Safety(SafetyViolation),
    Compaction(String),
    Timeout,
    MaxIterations,
    Other(String),
}

impl std::fmt::Display for RuntimeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Api(e) => write!(f, "API error: {}", e),
            Self::Tool(e) => write!(f, "Tool error: {}", e),
            Self::Safety(e) => write!(f, "Safety violation: {}", e),
            Self::Compaction(e) => write!(f, "Compaction error: {}", e),
            Self::Timeout => write!(f, "Conversation timeout"),
            Self::MaxIterations => write!(f, "Max iterations reached"),
            Self::Other(s) => write!(f, "Error: {}", s),
        }
    }
}

impl std::error::Error for RuntimeError {}

/// API error
#[derive(Debug, Clone)]
pub enum ApiError {
    Network(String),
    Parse(String),
    Http(u16),
    RateLimited,
    Other(String),
}

impl std::fmt::Display for ApiError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Network(s) => write!(f, "Network error: {}", s),
            Self::Parse(s) => write!(f, "Parse error: {}", s),
            Self::Http(code) => write!(f, "HTTP error: {}", code),
            Self::RateLimited => write!(f, "Rate limited"),
            Self::Other(s) => write!(f, "API error: {}", s),
        }
    }
}

impl std::error::Error for ApiError {}

/// Tool error
#[derive(Debug, Clone)]
pub enum ToolError {
    NotFound(String),
    InvalidArguments(String),
    Execution(String),
    Timeout,
    PermissionDenied,
}

impl std::fmt::Display for ToolError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NotFound(name) => write!(f, "Tool not found: {}", name),
            Self::InvalidArguments(s) => write!(f, "Invalid arguments: {}", s),
            Self::Execution(s) => write!(f, "Execution error: {}", s),
            Self::Timeout => write!(f, "Tool timeout"),
            Self::PermissionDenied => write!(f, "Permission denied"),
        }
    }
}

impl std::error::Error for ToolError {}

/// ECC Conversation Runtime
pub struct EccConversationRuntime<C, T, S, M>
where
    C: ApiClient,
    T: ToolExecutor,
    S: SafetyGuard,
    M: MemoryBridge,
{
    /// API client
    client: C,
    /// Tool executor
    tools: T,
    /// Safety guard (Fort Knox)
    safety_guard: S,
    /// Memory bridge (Second Brain)
    memory_bridge: M,
    /// Runtime configuration
    config: RuntimeConfig,
    /// Current session
    session: Session,
}

impl<C, T, S, M> EccConversationRuntime<C, T, S, M>
where
    C: ApiClient,
    T: ToolExecutor,
    S: SafetyGuard,
    M: MemoryBridge,
{
    /// Create new runtime
    pub fn new(
        client: C,
        tools: T,
        safety_guard: S,
        memory_bridge: M,
        config: RuntimeConfig,
    ) -> Self {
        Self {
            client,
            tools,
            safety_guard,
            memory_bridge,
            config,
            session: Session::new(),
        }
    }

    /// Run conversation turn
    pub async fn run(&mut self, user_message: &str) -> Result<ConversationResult, RuntimeError> {
        let start_time = Instant::now();
        
        // 1. Safety check on user input
        if self.config.fort_knox_enabled {
            self.safety_guard.validate_input(user_message).await
                .map_err(RuntimeError::Safety)?;
        }

        // 2. Add user message
        self.session.add_user_message(user_message);

        let mut iteration = 0;

        loop {
            // Safety: iteration limit
            if iteration >= self.config.max_iterations {
                self.sync_memory().await?;
                return Ok(ConversationResult::MaxIterationsReached {
                    last_message: self.last_assistant_message(),
                    iterations: iteration,
                });
            }
            iteration += 1;
            self.session.metadata.iteration_count = iteration;

            // Timeout check
            if start_time.elapsed().as_secs() > self.config.timeout_seconds {
                self.sync_memory().await?;
                return Ok(ConversationResult::Timeout {
                    last_message: self.last_assistant_message(),
                    elapsed: start_time.elapsed(),
                });
            }

            // 3. Check token budget and compact if needed
            if self.config.auto_compact && self.session.needs_compaction(self.config.max_context_tokens) {
                tracing::info!("Session needs compaction, triggering...");
                self.compact_session().await?;
            }

            // 4. Build system prompt
            let system_prompt = self.build_system_prompt();

            // 5. Stream request
            let request = ApiRequest::new("claude-opus-4")
                .with_system(system_prompt)
                .with_messages(self.session.messages.clone())
                .with_tools(self.tools.available_tools());

            let mut stream = self.client.stream_request(request).await
                .map_err(RuntimeError::Api)?;

            // 6. Process stream
            let mut assistant_message = String::new();
            let mut tool_calls = Vec::new();

            while let Some(frame) = stream.next() {
                match frame {
                    SseFrame { event_type, data, .. } => {
                        match event_type.as_str() {
                            "message" | "content" => {
                                assistant_message.push_str(&data);
                            }
                            "tool_use" => {
                                if let Ok(tool_call) = serde_json::from_str::<ToolCall>(&data) {
                                    tool_calls.push(tool_call);
                                }
                            }
                            "done" => break,
                            _ => {}
                        }
                    }
                }
            }

            // 7. Add assistant message
            let has_tool_calls = !tool_calls.is_empty();
            self.session.add_assistant_message(&assistant_message, 
                if has_tool_calls { Some(tool_calls.clone()) } else { None });

            // 8. Execute tools if any
            if !has_tool_calls {
                self.sync_memory().await?;
                return Ok(ConversationResult::Complete {
                    message: assistant_message,
                    tool_calls: Vec::new(),
                    iterations: iteration,
                });
            }

            for tool_call in tool_calls {
                let result = self.execute_tool_with_safety(&tool_call).await?;
                self.session.add_tool_result(&tool_call.id, &result.content);
            }

            // Sync memory periodically
            if iteration % 5 == 0 {
                self.sync_memory().await?;
            }
        }
    }

    /// Compact session to reduce token count
    async fn compact_session(&mut self) -> Result<(), RuntimeError> {
        use memory_compaction::{
            CompactionEngine, CompactionConfig, SimpleSummarizer,
            MessageSummary, CompactionResult
        };

        // Need at least 6 messages to compact (summary + 5 preserved)
        if self.session.messages.len() <= 6 {
            tracing::debug!("Not enough messages to compact");
            return Ok(());
        }

        tracing::info!(
            "Compacting session: {} messages, ~{} tokens",
            self.session.messages.len(),
            self.session.estimate_tokens()
        );

        let config = CompactionConfig::with_settings(
            self.config.max_context_tokens,
            4 // preserve recent
        );

        let engine = CompactionEngine::new(config, SimpleSummarizer);

        // Convert messages to summaries
        let summaries: Vec<MessageSummary> = self.session.messages
            .iter()
            .map(|m| MessageSummary::new(
                format!("{:?}", m.role), 
                &m.content
            ))
            .collect();

        // Perform compaction
        match engine.compact(&summaries).await {
            Ok(CompactionResult::Compacted { messages_removed, summary }) => {
                let before_count = self.session.messages.len();
                
                // Remove old messages (keep last 4)
                let preserve_count = 4;
                let remove_count = self.session.messages.len() - preserve_count;
                self.session.messages.drain(0..remove_count);
                
                // Insert summary as system message at the beginning
                let summary_msg = format!(
                    "[Session Summary - {} messages compacted] {}",
                    messages_removed,
                    summary
                );
                self.session.messages.insert(0, Message::system(summary_msg));
                
                // Update metadata
                self.session.metadata.compaction_count += 1;
                
                let after_count = self.session.messages.len();
                let after_tokens = self.session.estimate_tokens();
                
                tracing::info!(
                    "Compaction complete: {} -> {} messages, ~{} tokens",
                    before_count,
                    after_count,
                    after_tokens
                );
            }
            Ok(CompactionResult::NotNeeded) => {
                tracing::debug!("Compaction not needed");
            }
            Ok(CompactionResult::NothingToCompact) => {
                tracing::debug!("Nothing to compact");
            }
            Err(e) => {
                tracing::error!("Compaction failed: {}", e);
                return Err(RuntimeError::Compaction(e.to_string()));
            }
        }

        Ok(())
    }

    /// Execute tool with safety checks
    async fn execute_tool_with_safety(&self, tool_call: &ToolCall) -> Result<ToolResult, RuntimeError> {
        if self.config.fort_knox_enabled {
            self.safety_guard.validate_tool_call(&tool_call.name, &tool_call.arguments).await
                .map_err(|e| {
                    tracing::warn!("Safety violation for tool {}: {}", tool_call.name, e);
                    RuntimeError::Safety(e)
                })?;
        }

        match tokio::time::timeout(
            Duration::from_secs(60),
            self.tools.execute(tool_call)
        ).await {
            Ok(Ok(result)) => Ok(result),
            Ok(Err(e)) => Err(RuntimeError::Tool(e)),
            Err(_) => Ok(ToolResult::error(&tool_call.id, "Tool execution timeout")),
        }
    }

    /// Build system prompt with ECC context
    fn build_system_prompt(&self) -> String {
        let mut prompt = String::new();

        if let Ok(soul) = std::fs::read_to_string("SOUL.md") {
            prompt.push_str("# Identity\n\n");
            prompt.push_str(&soul);
            prompt.push_str("\n\n");
        }

        if let Ok(user) = std::fs::read_to_string("USER.md") {
            prompt.push_str("# User Context\n\n");
            prompt.push_str(&user);
            prompt.push_str("\n\n");
        }

        if let Ok(memory) = std::fs::read_to_string("MEMORY.md") {
            let recent: String = memory.lines().take(100).collect::<Vec<_>>().join("\n");
            prompt.push_str("# Relevant Memory\n\n");
            prompt.push_str(&recent);
            prompt.push_str("\n\n");
        }

        prompt.push_str("# Current Context\n\n");
        prompt.push_str(&format!("Date: {}\n", chrono::Local::now().format("%Y-%m-%d %H:%M")));
        prompt.push_str(&format!("Session messages: {}\n", self.session.messages.len()));
        prompt.push_str(&format!("Session compactions: {}\n", self.session.metadata.compaction_count));
        prompt.push_str(&format!("Estimated tokens: {}\n", self.session.estimate_tokens()));

        prompt
    }

    /// Sync memory to Second Brain
    async fn sync_memory(&self) -> Result<(), RuntimeError> {
        if !self.config.memory_sync_enabled {
            return Ok(());
        }

        self.memory_bridge.sync_conversation(&self.session).await
            .map_err(|e| RuntimeError::Other(format!("Memory sync failed: {}", e)))?;

        Ok(())
    }

    /// Get last assistant message
    fn last_assistant_message(&self) -> String {
        self.session.messages.iter()
            .rev()
            .find(|m| m.role == MessageRole::Assistant)
            .map(|m| m.content.clone())
            .unwrap_or_default()
    }

    /// Get current session
    pub fn session(&self) -> &Session {
        &self.session
    }

    /// Get mutable session
    pub fn session_mut(&mut self) -> &mut Session {
        &mut self.session
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_runtime_config_default() {
        let config = RuntimeConfig::new();
        assert_eq!(config.max_iterations, 16);
        assert_eq!(config.max_context_tokens, 102_400);
        assert_eq!(config.timeout_seconds, 300);
    }

    #[test]
    fn test_message_estimate_tokens() {
        let msg = Message::user("Hello, world!");
        assert!(msg.estimate_tokens() > 0);
    }

    #[test]
    fn test_session_needs_compaction() {
        let mut session = Session::new();
        for _ in 0..100 {
            session.add_user_message("This is a test message with some content. ");
        }
        assert!(session.needs_compaction(100));
    }

    #[test]
    fn test_session_metadata() {
        let mut session = Session::new();
        assert_eq!(session.metadata.compaction_count, 0);
        
        // Simulate compaction by manually incrementing
        session.metadata.compaction_count += 1;
        assert_eq!(session.metadata.compaction_count, 1);
    }

    #[test]
    fn test_session_with_token_budget() {
        let session = Session::with_token_budget(TokenBudgetConfig::default());
        assert!(session.token_budget.is_some());
    }
}
