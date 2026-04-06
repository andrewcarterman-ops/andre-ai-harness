//! Permissions Tests
//! 
//! Tests for PermissionMode, PermissionPolicy, and RiskAnalyzer

use security_review::{
    PermissionMode, 
    PermissionPolicy, 
    PermissionResponse,
    PermissionDecision,
    RiskScore,
    RiskAnalyzer,
    RiskBasedDecision,
};
use serde_json::json;

#[test]
fn test_permission_mode_from_str() {
    assert_eq!(PermissionMode::from_str("allow"), Some(PermissionMode::Allow));
    assert_eq!(PermissionMode::from_str("deny"), Some(PermissionMode::Deny));
    assert_eq!(PermissionMode::from_str("prompt"), Some(PermissionMode::Prompt));
    assert_eq!(PermissionMode::from_str("yes"), Some(PermissionMode::Allow));
    assert_eq!(PermissionMode::from_str("no"), Some(PermissionMode::Deny));
    assert_eq!(PermissionMode::from_str("unknown"), None);
}

#[test]
fn test_permission_mode_as_str() {
    assert_eq!(PermissionMode::Allow.as_str(), "allow");
    assert_eq!(PermissionMode::Deny.as_str(), "deny");
    assert_eq!(PermissionMode::Prompt.as_str(), "prompt");
}

#[test]
fn test_permission_mode_is_allowed() {
    assert!(PermissionMode::Allow.is_allowed());
    assert!(!PermissionMode::Deny.is_allowed());
    assert!(!PermissionMode::Prompt.is_allowed());
}

#[test]
fn test_permission_mode_requires_prompt() {
    assert!(!PermissionMode::Allow.requires_prompt());
    assert!(!PermissionMode::Deny.requires_prompt());
    assert!(PermissionMode::Prompt.requires_prompt());
}

#[test]
fn test_permission_policy_default() {
    let policy = PermissionPolicy::default_policy();
    assert_eq!(policy.default_mode, PermissionMode::Prompt);
    assert!(policy.overrides().is_empty());
}

#[test]
fn test_permission_policy_restrictive() {
    let policy = PermissionPolicy::restrictive();
    assert_eq!(policy.default_mode, PermissionMode::Deny);
}

#[test]
fn test_permission_policy_permissive() {
    let policy = PermissionPolicy::permissive();
    assert_eq!(policy.default_mode, PermissionMode::Allow);
    assert_eq!(policy.resolve("bash"), PermissionMode::Prompt);
    assert_eq!(policy.resolve("unknown"), PermissionMode::Allow);
}

#[test]
fn test_permission_policy_with_override() {
    let policy = PermissionPolicy::new(PermissionMode::Deny)
        .with_override("read", PermissionMode::Allow)
        .with_override("bash", PermissionMode::Prompt);
    
    assert_eq!(policy.resolve("read"), PermissionMode::Allow);
    assert_eq!(policy.resolve("bash"), PermissionMode::Prompt);
    assert_eq!(policy.resolve("write"), PermissionMode::Deny);
}

#[test]
fn test_permission_policy_set_override() {
    let mut policy = PermissionPolicy::new(PermissionMode::Prompt);
    policy.set_override("dangerous_tool", PermissionMode::Deny);
    
    assert_eq!(policy.resolve("dangerous_tool"), PermissionMode::Deny);
}

#[test]
fn test_permission_policy_remove_override() {
    let mut policy = PermissionPolicy::new(PermissionMode::Deny)
        .with_override("read", PermissionMode::Allow);
    
    assert_eq!(policy.resolve("read"), PermissionMode::Allow);
    
    policy.remove_override("read");
    assert_eq!(policy.resolve("read"), PermissionMode::Deny);
}

#[test]
fn test_permission_policy_is_allowed() {
    let policy = PermissionPolicy::new(PermissionMode::Allow);
    assert!(policy.is_allowed("any_tool"));
    
    let policy = PermissionPolicy::new(PermissionMode::Deny);
    assert!(!policy.is_allowed("any_tool"));
}

#[test]
fn test_permission_response_is_allowed() {
    assert!(PermissionResponse::Allow.is_allowed());
    assert!(PermissionResponse::AllowOnce.is_allowed());
    assert!(!PermissionResponse::Deny.is_allowed());
    assert!(!PermissionResponse::DenyOnce.is_allowed());
}

#[test]
fn test_permission_response_is_persistent() {
    assert!(PermissionResponse::Allow.is_persistent());
    assert!(!PermissionResponse::AllowOnce.is_persistent());
    assert!(PermissionResponse::Deny.is_persistent());
    assert!(!PermissionResponse::DenyOnce.is_persistent());
}

#[test]
fn test_permission_response_to_mode() {
    assert_eq!(PermissionResponse::Allow.to_mode(), Some(PermissionMode::Allow));
    assert_eq!(PermissionResponse::Deny.to_mode(), Some(PermissionMode::Deny));
    assert_eq!(PermissionResponse::AllowOnce.to_mode(), None);
    assert_eq!(PermissionResponse::DenyOnce.to_mode(), None);
}

#[test]
fn test_risk_score_ordering() {
    assert!(RiskScore::Critical.value() > RiskScore::High.value());
    assert!(RiskScore::High.value() > RiskScore::Medium.value());
    assert!(RiskScore::Medium.value() > RiskScore::Low.value());
}

#[test]
fn test_risk_analyzer_critical() {
    let analyzer = RiskAnalyzer::new();
    
    // Critical: rm -rf /
    let args = json!({"command": "rm -rf /"});
    let risk = analyzer.analyze("bash", &args);
    assert_eq!(risk, RiskScore::Critical);
    
    // Critical: sudo su
    let args = json!({"command": "sudo su"});
    let risk = analyzer.analyze("bash", &args);
    assert_eq!(risk, RiskScore::Critical);
}

#[test]
fn test_risk_analyzer_high() {
    let analyzer = RiskAnalyzer::new();
    
    // High: git push --force
    let args = json!({"command": "git push --force"});
    let risk = analyzer.analyze("bash", &args);
    assert_eq!(risk, RiskScore::High);
    
    // High: docker system prune
    let args = json!({"command": "docker system prune"});
    let risk = analyzer.analyze("bash", &args);
    assert_eq!(risk, RiskScore::High);
}

#[test]
fn test_risk_analyzer_medium() {
    let analyzer = RiskAnalyzer::new();
    
    // Medium: git push
    let args = json!({"command": "git push"});
    let risk = analyzer.analyze("bash", &args);
    assert_eq!(risk, RiskScore::Medium);
}

#[test]
fn test_risk_analyzer_low() {
    let analyzer = RiskAnalyzer::new();
    
    // Low: read file
    let args = json!({"path": "/tmp/test.txt"});
    let risk = analyzer.analyze("read", &args);
    assert_eq!(risk, RiskScore::Low);
    
    // Low: ls -la
    let args = json!({"command": "ls -la"});
    let risk = analyzer.analyze("bash", &args);
    assert_eq!(risk, RiskScore::Low);
}

#[test]
fn test_risk_analyzer_file_critical() {
    let analyzer = RiskAnalyzer::new();
    
    // Critical: writing to /etc/shadow
    let args = json!({"path": "/etc/shadow"});
    let risk = analyzer.analyze("write", &args);
    assert_eq!(risk, RiskScore::Critical);
    
    // Critical: SSH keys
    let args = json!({"path": "~/.ssh/id_rsa"});
    let risk = analyzer.analyze("read", &args);
    assert_eq!(risk, RiskScore::Critical);
}

#[test]
fn test_risk_analyzer_web_suspicious() {
    let analyzer = RiskAnalyzer::new();
    
    // High: pastebin
    let args = json!({"url": "https://pastebin.com/raw/abc123"});
    let risk = analyzer.analyze("web_fetch", &args);
    assert_eq!(risk, RiskScore::High);
}

#[test]
fn test_risk_based_decision() {
    let decision = RiskBasedDecision::from_risk(RiskScore::Critical, true, false);
    assert!(!decision.should_allow);
    assert!(!decision.should_prompt);
    
    let decision = RiskBasedDecision::from_risk(RiskScore::High, true, false);
    assert!(!decision.should_allow);
    assert!(decision.should_prompt);
    
    let decision = RiskBasedDecision::from_risk(RiskScore::Low, false, true);
    assert!(decision.should_allow);
    assert!(!decision.should_prompt);
}
