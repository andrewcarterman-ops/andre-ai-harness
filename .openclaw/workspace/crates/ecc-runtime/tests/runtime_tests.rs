//! Runtime Tests
//! 
//! Tests for Session, Message, RuntimeConfig, and related types

use ecc_runtime::{
    RuntimeConfig,
    Session,
    Message,
    MessageRole,
    ToolCall,
    ToolResult,
    ToolDefinition,
    ApiRequest,
};
use serde_json::json;

#[test]
fn test_runtime_config_default() {
    let config = RuntimeConfig::new();
    assert_eq!(config.max_iterations, 16);
    assert_eq!(config.max_context_tokens, 102_400);
    assert_eq!(config.timeout_seconds, 300);
    assert_eq!(config.max_retries, 3);
    assert!(config.auto_compact);
    assert!(config.fort_knox_enabled);
    assert!(config.memory_sync_enabled);
}

#[test]
fn test_runtime_config_permissive() {
    let config = RuntimeConfig::permissive();
    assert_eq!(config.max_iterations, 32);
    assert_eq!(config.max_context_tokens, 200_000);
    assert_eq!(config.timeout_seconds, 600);
    assert_eq!(config.max_retries, 5);
    assert!(!config.auto_compact);
    assert!(!config.fort_knox_enabled);
    assert!(!config.memory_sync_enabled);
}

#[test]
fn test_runtime_config_restrictive() {
    let config = RuntimeConfig::restrictive();
    assert_eq!(config.max_iterations, 8);
    assert_eq!(config.max_context_tokens, 50_000);
    assert_eq!(config.timeout_seconds, 120);
    assert_eq!(config.max_retries, 1);
    assert!(config.auto_compact);
    assert!(config.fort_knox_enabled);
    assert!(config.memory_sync_enabled);
}

#[test]
fn test_message_creation() {
    let system_msg = Message::system("System prompt");
    assert_eq!(system_msg.role, MessageRole::System);
    assert_eq!(system_msg.content, "System prompt");
    assert!(system_msg.tool_calls.is_none());
    
    let user_msg = Message::user("User input");
    assert_eq!(user_msg.role, MessageRole::User);
    assert_eq!(user_msg.content, "User input");
    
    let assistant_msg = Message::assistant("Response", None);
    assert_eq!(assistant_msg.role, MessageRole::Assistant);
    assert_eq!(assistant_msg.content, "Response");
}

#[test]
fn test_message_with_tool_calls() {
    let tool_calls = vec![
        ToolCall::new("call-1", "bash", json!({"command": "ls"}))
    ];
    let msg = Message::assistant("I'll list files", Some(tool_calls));
    
    assert!(msg.tool_calls.is_some());
    assert_eq!(msg.tool_calls.as_ref().unwrap().len(), 1);
}

#[test]
fn test_message_tool_result() {
    let msg = Message::tool_result("call-1", "file1.txt\nfile2.txt");
    assert_eq!(msg.role, MessageRole::Tool);
    assert_eq!(msg.content, "file1.txt\nfile2.txt");
    assert_eq!(msg.tool_call_id, Some("call-1".to_string()));
}

#[test]
fn test_message_estimate_tokens() {
    let msg = Message::user("Hello, world!");
    let tokens = msg.estimate_tokens();
    // Naive estimation: chars / 4
    assert!(tokens > 0);
    assert_eq!(tokens, "Hello, world!".len() / 4);
}

#[test]
fn test_message_role_display() {
    assert_eq!(format!("{}", MessageRole::System), "system");
    assert_eq!(format!("{}", MessageRole::User), "user");
    assert_eq!(format!("{}", MessageRole::Assistant), "assistant");
    assert_eq!(format!("{}", MessageRole::Tool), "tool");
}

#[test]
fn test_session_creation() {
    let session = Session::new();
    assert!(session.messages.is_empty());
    assert!(session.tool_results.is_empty());
    assert!(session.metadata.created_at.is_some());
    assert_eq!(session.metadata.iteration_count, 0);
}

#[test]
fn test_session_add_user_message() {
    let mut session = Session::new();
    session.add_user_message("Hello");
    
    assert_eq!(session.messages.len(), 1);
    assert_eq!(session.messages[0].role, MessageRole::User);
    assert_eq!(session.messages[0].content, "Hello");
}

#[test]
fn test_session_add_assistant_message() {
    let mut session = Session::new();
    session.add_assistant_message("Hi there!", None);
    
    assert_eq!(session.messages.len(), 1);
    assert_eq!(session.messages[0].role, MessageRole::Assistant);
}

#[test]
fn test_session_add_tool_result() {
    let mut session = Session::new();
    session.add_tool_result("call-123", "Command output");
    
    assert_eq!(session.messages.len(), 1);
    assert_eq!(session.messages[0].role, MessageRole::Tool);
    assert_eq!(session.tool_results.len(), 1);
    assert_eq!(session.tool_results[0].tool_call_id, "call-123");
}

#[test]
fn test_session_add_system_message() {
    let mut session = Session::new();
    session.add_system_message("System prompt");
    
    assert_eq!(session.messages.len(), 1);
    assert_eq!(session.messages[0].role, MessageRole::System);
}

#[test]
fn test_session_estimate_tokens() {
    let mut session = Session::new();
    session.add_user_message("Hello, world!");
    session.add_assistant_message("Hi!", None);
    
    let tokens = session.estimate_tokens();
    assert!(tokens > 0);
}

#[test]
fn test_session_needs_compaction() {
    let mut session = Session::new();
    
    // Add many messages to exceed threshold
    for _ in 0..100 {
        session.add_user_message("This is a test message with substantial content to increase token count. ");
    }
    
    assert!(session.needs_compaction(1000));
}

#[test]
fn test_session_recent_messages() {
    let mut session = Session::new();
    session.add_user_message("Message 1");
    session.add_user_message("Message 2");
    session.add_user_message("Message 3");
    
    let recent = session.recent_messages(2);
    assert_eq!(recent.len(), 2);
    assert_eq!(recent[0].content, "Message 2");
    assert_eq!(recent[1].content, "Message 3");
}

#[test]
fn test_tool_call_creation() {
    let tool_call = ToolCall::new(
        "call-123",
        "bash",
        json!({"command": "ls -la"})
    );
    
    assert_eq!(tool_call.id, "call-123");
    assert_eq!(tool_call.name, "bash");
    assert_eq!(tool_call.arguments["command"], "ls -la");
}

#[test]
fn test_tool_result_success() {
    let result = ToolResult::success("call-123", "Output content");
    assert_eq!(result.tool_call_id, "call-123");
    assert_eq!(result.content, "Output content");
    assert!(!result.is_error);
}

#[test]
fn test_tool_result_error() {
    let result = ToolResult::error("call-123", "Error message");
    assert_eq!(result.tool_call_id, "call-123");
    assert_eq!(result.content, "Error message");
    assert!(result.is_error);
}

#[test]
fn test_tool_definition_creation() {
    let tool = ToolDefinition::new(
        "read",
        "Read a file",
        json!({
            "type": "object",
            "properties": {
                "path": {"type": "string"}
            }
        })
    );
    
    assert_eq!(tool.name, "read");
    assert_eq!(tool.description, "Read a file");
}

#[test]
fn test_api_request_builder() {
    let request = ApiRequest::new("claude-opus-4")
        .with_system("System prompt")
        .with_messages(vec![
            Message::user("Hello"),
        ])
        .with_tools(vec![
            ToolDefinition::new("bash", "Run commands", json!({})),
        ]);
    
    assert_eq!(request.model, "claude-opus-4");
    assert_eq!(request.system, Some("System prompt".to_string()));
    assert_eq!(request.messages.len(), 1);
    assert_eq!(request.tools.len(), 1);
}
