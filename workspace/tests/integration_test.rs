// Integration Test for OpenClaw-ECC Components
// Tests cross-module functionality

#[cfg(test)]
mod integration_tests {
    // Test 1: Secure API Client
    use secure_api_client::{
        SseStreamParser, 
        SseFrame, 
        TokenUsage, 
        ExponentialBackoff
    };

    #[test]
    fn test_sse_parser_integration() {
        let mut parser = SseStreamParser::new();
        let frames = parser.feed("data: test\n\n").unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].data, "test");
    }

    #[test]
    fn test_token_usage_integration() {
        let usage = TokenUsage {
            input_tokens: 100,
            output_tokens: 50,
            cache_creation_input_tokens: 10,
            cache_read_input_tokens: 5,
        };
        assert_eq!(usage.total_tokens(), 150);
    }

    #[test]
    fn test_exponential_backoff_integration() {
        let backoff = ExponentialBackoff::new();
        assert!(backoff.is_retryable_status(500));
        assert!(!backoff.is_retryable_status(200));
    }

    // Test 2: Security Review Components
    use security_review::{
        PermissionMode, 
        PermissionPolicy,
        RiskScore,
        RiskAnalyzer,
        AuditLogger
    };
    use serde_json::json;

    #[test]
    fn test_permission_policy_integration() {
        let policy = PermissionPolicy::new(PermissionMode::Prompt)
            .with_override("bash", PermissionMode::Deny);
        
        assert_eq!(policy.resolve("bash"), PermissionMode::Deny);
        assert_eq!(policy.resolve("read"), PermissionMode::Prompt);
    }

    #[test]
    fn test_risk_analyzer_integration() {
        let analyzer = RiskAnalyzer::new();
        let args = json!({"command": "ls -la"});
        let risk = analyzer.analyze("bash", &args);
        assert!(risk.value() <= 3); // Not critical
    }

    #[test]
    fn test_risk_analyzer_critical() {
        let analyzer = RiskAnalyzer::new();
        let args = json!({"command": "rm -rf /"});
        let risk = analyzer.analyze("bash", &args);
        assert_eq!(risk, RiskScore::Critical);
    }

    // Test 3: ECC Runtime Components
    use ecc_runtime::{
        RuntimeConfig,
        Session,
        Message,
        MessageRole,
        ToolCall
    };

    #[test]
    fn test_runtime_config_integration() {
        let config = RuntimeConfig::new();
        assert_eq!(config.max_iterations, 16);
        assert_eq!(config.max_context_tokens, 102_400);
        assert!(config.fort_knox_enabled);
        assert!(config.memory_sync_enabled);
    }

    #[test]
    fn test_session_integration() {
        let mut session = Session::new();
        session.add_user_message("Hello");
        session.add_assistant_message("Hi!", None);
        
        assert_eq!(session.messages.len(), 2);
        assert!(session.estimate_tokens() > 0);
    }

    #[test]
    fn test_message_roles() {
        let system_msg = Message::system("System prompt");
        let user_msg = Message::user("User input");
        let assistant_msg = Message::assistant("Response", None);
        
        assert_eq!(system_msg.role, MessageRole::System);
        assert_eq!(user_msg.role, MessageRole::User);
        assert_eq!(assistant_msg.role, MessageRole::Assistant);
    }

    #[test]
    fn test_tool_call_creation() {
        let tool_call = ToolCall::new(
            "call-123",
            "bash",
            json!({"command": "echo test"})
        );
        assert_eq!(tool_call.id, "call-123");
        assert_eq!(tool_call.name, "bash");
    }

    // Test 4: Cross-module interaction
    #[test]
    fn test_permission_risk_integration() {
        let policy = PermissionPolicy::new(PermissionMode::Prompt);
        let analyzer = RiskAnalyzer::new();
        
        // High risk tool
        let args = json!({"command": "git push --force"});
        let risk = analyzer.analyze("bash", &args);
        
        // Should be high or critical risk
        assert!(risk.value() >= 3);
        
        // Should require prompt
        assert!(policy.requires_prompt("bash"));
    }

    #[test]
    fn test_session_compaction_detection() {
        let mut session = Session::new();
        
        // Add many messages to trigger compaction need
        for _ in 0..50 {
            session.add_user_message("This is a test message with substantial content to increase token count. ");
        }
        
        assert!(session.needs_compaction(1000));
    }

    #[test]
    fn test_token_usage_accumulation() {
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
}
