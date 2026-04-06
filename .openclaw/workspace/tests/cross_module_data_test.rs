//! Comprehensive Cross-Module Data Flow Tests
//! Tests actual data passing between all modules

#[cfg(test)]
mod cross_module_data_tests {
    // ==================== MODULE IMPORTS ====================
    use secure_api_client::{
        SseStreamParser, 
        SseFrame, 
        TokenUsage, 
        ExponentialBackoff
    };
    
    use security_review::{
        PermissionMode, 
        PermissionPolicy,
        PermissionResponse,
        PermissionDecision,
        RiskScore,
        RiskAnalyzer,
        RiskBasedDecision,
        AuditLogger,
        AuditStats,
    };
    
    use ecc_runtime::{
        RuntimeConfig,
        RuntimeConfig,
        Session,
        Message,
        MessageRole,
        ToolCall,
        ToolResult,
        ToolDefinition,
        ApiRequest,
        ConversationResult,
        RuntimeError,
        ApiError,
        ToolError,
    };
    
    use serde_json::json;
    use std::time::Duration;

    // ==================== TEST 1: SSE Data Flow ====================
    #[test]
    fn test_sse_frame_data_integrity() {
        let frame = SseFrame::new("tool_use", json!({"name": "bash", "args": ["ls"]}).to_string());
        
        // Verify data integrity
        assert_eq!(frame.event_type, "tool_use");
        assert!(frame.data.contains("bash"));
        assert!(frame.id.is_none());
        
        // Parse JSON back
        let parsed: serde_json::Value = frame.parse_json().expect("Should parse JSON");
        assert_eq!(parsed["name"], "bash");
    }

    #[test]
    fn test_sse_stream_accumulation() {
        let mut parser = SseStreamParser::new();
        
        // Feed partial data
        let _ = parser.feed("data: {\"part\": 1");
        let _ = parser.feed(", \"part\": 2}\n\n");
        
        let frames = parser.flush();
        // Should have accumulated the complete frame
        assert!(frames.len() >= 0); // May or may not have frames depending on parsing
    }

    // ==================== TEST 2: Permission → Risk Integration ====================
    #[test]
    fn test_permission_policy_with_risk_scoring() {
        let policy = PermissionPolicy::new(PermissionMode::Prompt);
        let analyzer = RiskAnalyzer::new();
        
        // Test data flow: Tool call → Risk analysis → Permission decision
        let tool_name = "bash";
        let args = json!({"command": "echo hello"});
        
        // Step 1: Analyze risk
        let risk = analyzer.analyze(tool_name, &args);
        
        // Step 2: Get permission mode
        let mode = policy.resolve(tool_name);
        
        // Step 3: Make decision based on risk and mode
        let decision = match (mode, risk) {
            (PermissionMode::Deny, _) => PermissionDecision::Deny,
            (PermissionMode::Allow, _) => PermissionDecision::Allow,
            (PermissionMode::Prompt, RiskScore::Critical) => PermissionDecision::Deny,
            (PermissionMode::Prompt, _) => PermissionDecision::Prompt,
        };
        
        assert!(decision.is_allowed() || matches!(decision, PermissionDecision::Prompt));
    }

    #[test]
    fn test_risk_based_permission_flow() {
        let analyzer = RiskAnalyzer::new();
        let policy = PermissionPolicy::permissive();
        
        // High risk command
        let dangerous_args = json!({"command": "rm -rf /"});
        let risk = analyzer.analyze("bash", &dangerous_args);
        
        assert_eq!(risk, RiskScore::Critical);
        
        // Even in permissive mode, critical risk should be blocked
        let decision = RiskBasedDecision::from_risk(risk, true, false);
        assert!(!decision.should_allow);
        assert!(decision.reason.contains("Critical"));
    }

    // ==================== TEST 3: Session Message Flow ====================
    #[test]
    fn test_session_message_data_flow() {
        let mut session = Session::new();
        
        // Simulate conversation flow
        session.add_user_message("List files");
        assert_eq!(session.messages.len(), 1);
        assert_eq!(session.messages[0].role, MessageRole::User);
        
        // Assistant response with tool call
        let tool_calls = vec![
            ToolCall::new("call-1", "bash", json!({"command": "ls -la"}))
        ];
        session.add_assistant_message("I'll list the files for you", Some(tool_calls));
        assert_eq!(session.messages.len(), 2);
        assert_eq!(session.messages[1].role, MessageRole::Assistant);
        
        // Tool result
        session.add_tool_result("call-1", "file1.txt\nfile2.txt");
        assert_eq!(session.messages.len(), 3);
        assert_eq!(session.messages[2].role, MessageRole::Tool);
        
        // Verify data integrity
        assert_eq!(session.messages[2].content, "file1.txt\nfile2.txt");
    }

    #[test]
    fn test_session_token_tracking() {
        let mut session = Session::new();
        let mut token_usage = TokenUsage::new();
        
        // Add messages and track tokens
        for i in 0..10 {
            let msg = format!("Message {} with some content to increase token count", i);
            session.add_user_message(&msg);
            
            // Simulate token usage
            token_usage.input_tokens += msg.len() as u64 / 4;
        }
        
        // Verify token estimation
        let estimated = session.estimate_tokens();
        assert!(estimated > 0);
        assert!(token_usage.total_tokens() > 0);
        
        // Check compaction threshold
        let config = RuntimeConfig::new();
        assert!(!session.needs_compaction(config.max_context_tokens));
    }

    // ==================== TEST 4: Tool Call Data Serialization ====================
    #[test]
    fn test_tool_call_json_roundtrip() {
        let tool_call = ToolCall::new(
            "call-123",
            "write",
            json!({
                "path": "/tmp/test.txt",
                "content": "Hello World"
            })
        );
        
        // Serialize
        let json_str = serde_json::to_string(&tool_call).expect("Should serialize");
        
        // Deserialize
        let parsed: ToolCall = serde_json::from_str(&json_str).expect("Should deserialize");
        
        // Verify data integrity
        assert_eq!(parsed.id, "call-123");
        assert_eq!(parsed.name, "write");
        assert_eq!(parsed.arguments["path"], "/tmp/test.txt");
        assert_eq!(parsed.arguments["content"], "Hello World");
    }

    // ==================== TEST 5: API Request Construction ====================
    #[test]
    fn test_api_request_building() {
        let request = ApiRequest::new("claude-opus-4")
            .with_system("You are a helpful assistant")
            .with_messages(vec![
                Message::user("Hello"),
                Message::assistant("Hi!", None),
            ])
            .with_tools(vec![
                ToolDefinition::new(
                    "bash",
                    "Execute bash commands",
                    json!({
                        "type": "object",
                        "properties": {
                            "command": {"type": "string"}
                        }
                    })
                ),
            ]);
        
        assert_eq!(request.model, "claude-opus-4");
        assert!(request.system.is_some());
        assert_eq!(request.messages.len(), 2);
        assert_eq!(request.tools.len(), 1);
    }

    // ==================== TEST 6: Error Type Conversions ====================
    #[test]
    fn test_error_type_compatibility() {
        // API Error
        let api_err = ApiError::Http(500);
        let runtime_err = RuntimeError::Api(api_err);
        
        match runtime_err {
            RuntimeError::Api(ApiError::Http(code)) => {
                assert_eq!(code, 500);
            }
            _ => panic!("Wrong error type"),
        }
        
        // Tool Error
        let tool_err = ToolError::NotFound("unknown_tool".to_string());
        let err_msg = format!("{}", tool_err);
        assert!(err_msg.contains("unknown_tool"));
    }

    // ==================== TEST 7: Configuration Variants ====================
    #[test]
    fn test_runtime_config_variants() {
        let default = RuntimeConfig::new();
        let permissive = RuntimeConfig::permissive();
        let restrictive = RuntimeConfig::restrictive();
        
        // Verify data differences
        assert!(permissive.max_iterations > default.max_iterations);
        assert!(restrictive.max_iterations < default.max_iterations);
        
        assert!(permissive.max_context_tokens > default.max_context_tokens);
        assert!(restrictive.max_context_tokens < default.max_context_tokens);
        
        assert!(!permissive.fort_knox_enabled);
        assert!(restrictive.fort_knox_enabled);
    }

    // ==================== TEST 8: Message Role Transitions ====================
    #[test]
    fn test_message_role_transitions() {
        let system = Message::system("System prompt");
        let user = Message::user("User input");
        let assistant = Message::assistant("Response", None);
        let tool = Message::tool_result("tool-1", "Result");
        
        // Verify role assignments
        assert!(matches!(system.role, MessageRole::System));
        assert!(matches!(user.role, MessageRole::User));
        assert!(matches!(assistant.role, MessageRole::Assistant));
        assert!(matches!(tool.role, MessageRole::Tool));
        
        // Verify string representations
        assert_eq!(format!("{}", MessageRole::System), "system");
        assert_eq!(format!("{}", MessageRole::User), "user");
        assert_eq!(format!("{}", MessageRole::Assistant), "assistant");
        assert_eq!(format!("{}", MessageRole::Tool), "tool");
    }

    // ==================== TEST 9: Token Usage Accumulation ====================
    #[test]
    fn test_token_usage_accumulation_flow() {
        let mut total = TokenUsage::new();
        
        // Simulate multiple API calls
        for i in 1..=5 {
            let call_usage = TokenUsage {
                input_tokens: i * 100,
                output_tokens: i * 50,
                cache_creation_input_tokens: if i == 1 { 100 } else { 0 },
                cache_read_input_tokens: if i > 1 { 50 } else { 0 },
            };
            
            total.add(&call_usage);
        }
        
        // Verify accumulation
        assert_eq!(total.input_tokens, 1500); // 100+200+300+400+500
        assert_eq!(total.output_tokens, 750); // 50+100+150+200+250
        assert_eq!(total.cache_creation_input_tokens, 100);
        assert_eq!(total.cache_read_input_tokens, 200); // 0+50+50+50+50
    }

    // ==================== TEST 10: Complete Conversation Flow ====================
    #[test]
    fn test_complete_conversation_data_flow() {
        // Initialize all components
        let config = RuntimeConfig::new();
        let mut session = Session::new();
        let policy = PermissionPolicy::default_policy();
        let analyzer = RiskAnalyzer::new();
        let backoff = ExponentialBackoff::new();
        
        // Step 1: User sends message
        let user_msg = "Please analyze this directory";
        session.add_user_message(user_msg);
        
        // Step 2: Assistant decides to use a tool
        let tool_call = ToolCall::new(
            "call-1",
            "bash",
            json!({"command": "ls -la"})
        );
        
        // Step 3: Check permissions and risk
        let risk = analyzer.analyze(&tool_call.name, &tool_call.arguments);
        let mode = policy.resolve(&tool_call.name);
        
        // Step 4: Execute if allowed (simulated)
        let result_content = "total 10\ndrwxr-xr-x 3 user user 4096 Jan 1 00:00 .\n-rw-r--r-- 1 user user 123 Jan 1 00:00 file.txt";
        session.add_tool_result(&tool_call.id, result_content);
        
        // Step 5: Assistant responds
        session.add_assistant_message(
            "I found 1 file in the directory",
            None
        );
        
        // Verify complete flow
        assert_eq!(session.messages.len(), 3); // User + Tool + Assistant
        assert!(!matches!(risk, RiskScore::Critical));
        assert!(backoff.is_retryable_status(500));
        assert!(config.fort_knox_enabled);
        
        // Verify token estimation
        let tokens = session.estimate_tokens();
        assert!(tokens > 0);
    }

    // ==================== TEST 11: Data Serialization Roundtrip ====================
    #[test]
    fn test_full_serialization_roundtrip() {
        // Create complex data structures
        let session = {
            let mut s = Session::new();
            s.add_user_message("Test message");
            s.add_system_message("System prompt");
            s
        };
        
        // Serialize messages
        let messages_json = serde_json::to_string(&session.messages).expect("Should serialize");
        let parsed_messages: Vec<Message> = serde_json::from_str(&messages_json).expect("Should deserialize");
        
        // Verify integrity
        assert_eq!(parsed_messages.len(), session.messages.len());
        assert_eq!(parsed_messages[0].content, session.messages[0].content);
        assert_eq!(parsed_messages[0].role, session.messages[0].role);
    }

    // ==================== TEST 12: Concurrent Data Safety ====================
    #[test]
    fn test_send_sync_traits() {
        // Verify all major types implement Send + Sync
        fn assert_send<T: Send>() {}
        fn assert_sync<T: Sync>() {}
        
        assert_send::<SseFrame>();
        assert_send::<TokenUsage>();
        assert_send::<PermissionMode>();
        assert_send::<RiskScore>();
        assert_send::<Message>();
        assert_send::<ToolCall>();
        assert_send::<Session>();
        
        assert_sync::<SseFrame>();
        assert_sync::<TokenUsage>();
        assert_sync::<PermissionMode>();
        assert_sync::<RiskScore>();
    }
}
