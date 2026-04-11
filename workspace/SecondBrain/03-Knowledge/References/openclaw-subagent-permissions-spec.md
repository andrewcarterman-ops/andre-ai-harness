---
date: 01-04-2026
type: reference
category: openclaw
source: "vault-archive/Kimi_Agent_OpenClaw GitHub/"
tags: [reference, openclaw, subagent, permissions, security, rust]
---

# Sub-Agent Spezifikation: Permission Policy Framework

> Integriere claw-code Permissions mit Security Review Skill

---

## Kontext

| Eigenschaft | Wert |
|-------------|------|
| **Quelle** | claw-code/rust/crates/runtime/src/permissions.rs |
| **Ziel** | ~/.openclaw/workspace/skills/security-review/ |
| **Bestehend** | security-review Skill mit Risk-Analyse |

---

## Kern-Komponenten

### PermissionMode
```rust
pub enum PermissionMode {
    Allow,   // Execute without prompting
    Deny,    // Always reject
    Prompt,  // Ask user for confirmation
}
```

### PermissionPolicy
```rust
pub struct PermissionPolicy {
    pub default_mode: PermissionMode,
    pub tool_overrides: BTreeMap<String, PermissionMode>,
}

impl PermissionPolicy {
    pub fn resolve(&self, tool_name: &str) -> PermissionMode {
        self.tool_overrides
            .get(tool_name)
            .copied()
            .unwrap_or(self.default_mode)
    }
}
```

### PermissionPrompter Trait
```rust
#[async_trait]
pub trait PermissionPrompter: Send + Sync {
    async fn prompt(
        &self,
        tool: &str,
        args: &Value
    ) -> Result<PermissionResponse, PromptError>;
}

pub enum PermissionResponse {
    Allow,
    Deny,
    AllowOnce,
    DenyOnce,
}
```

---

## ECC-Erweiterungen

### Risk-based Permission Policy
```rust
pub struct EccPermissionPolicy {
    default_mode: PermissionMode,
    tool_overrides: BTreeMap<String, PermissionMode>,

    // ECC extensions
    risk_analyzer: RiskAnalyzer,
    audit_logger: AuditLogger,
    escalation_config: EscalationConfig,
}

pub struct RiskAnalyzer {
    tool_risk_scores: HashMap<String, RiskScore>,
    pattern_matcher: RiskPatternMatcher,
}

#[derive(Debug, Clone)]
pub struct RiskScore {
    pub base_score: u8,      // 0-100
    pub modifiers: Vec<RiskModifier>,
}

impl RiskScore {
    pub fn final_score(&self) -> u8 {
        let modifier_sum: i16 = self.modifiers.iter()
            .map(|m| m.value as i16)
            .sum();
        
        (self.base_score as i16 + modifier_sum)
            .clamp(0, 100) as u8
    }
}
```

### Risk Analysis
```rust
impl RiskAnalyzer {
    pub async fn analyze(
        &self,
        tool: &str,
        args: &Value
    ) -> RiskAssessment {
        let base = self.tool_risk_scores
            .get(tool)
            .cloned()
            .unwrap_or_else(|| self.default_score(tool));

        let mut modifiers = vec![];

        // Check for high-risk patterns
        if self.is_destructive_operation(tool, args) {
            modifiers.push(RiskModifier {
                reason: "Destructive operation".to_string(),
                value: 30,
            });
        }

        if self.operates_on_sensitive_path(args) {
            modifiers.push(RiskModifier {
                reason: "Sensitive path".to_string(),
                value: 20,
            });
        }

        if self.has_external_network_access(args) {
            modifiers.push(RiskModifier {
                reason: "Network access".to_string(),
                value: 15,
            });
        }

        RiskAssessment {
            tool: tool.to_string(),
            score: RiskScore { base_score: base.base_score, modifiers },
            classification: self.classify(final_score),
        }
    }

    fn classify(&self, score: u8
    ) -> RiskClassification {
        match score {
            0..=20 => RiskClassification::Low,
            21..=50 => RiskClassification::Medium,
            51..=75 => RiskClassification::High,
            76..=100 => RiskClassification::Critical,
            _ => RiskClassification::Critical,
        }
    }
}
```

### Risk Patterns
```rust
impl RiskPatternMatcher {
    fn is_destructive_operation(
        &self, tool: &str, args: &Value
    ) -> bool {
        let destructive_tools = [
            "file_delete", "rm", "remove",
            "database_drop", "table_drop",
        ];

        if destructive_tools.contains(&tool) {
            return true;
        }

        // Check for destructive flags
        if let Some(flags) = args.get("flags").and_then(|v| v.as_array()) {
            let destructive_flags = ["-rf", "--force", "--delete"];
            return flags.iter()
                .filter_map(|v| v.as_str())
                .any(|f| destructive_flags.contains(&f));
        }

        false
    }

    fn operates_on_sensitive_path(
        &self, args: &Value
    ) -> bool {
        let sensitive_paths = [
            ".ssh", ".aws", ".env",
            "/etc", "/var/log",
            "password", "secret", "key",
        ];

        // Check all path arguments
        let path_args = ["path", "file", "directory", "target"];
        for arg_name in &path_args {
            if let Some(path) = args.get(arg_name).and_then(|v| v.as_str()) {
                let path_lower = path.to_lowercase();
                if sensitive_paths.iter().any(|s| path_lower.contains(s)) {
                    return true;
                }
            }
        }

        false
    }

    fn has_external_network_access(
        &self, args: &Value
    ) -> bool {
        // Check for external URLs
        if let Some(url) = args.get("url").and_then(|v| v.as_str()) {
            let external_patterns = [
                "http://", "https://",
                "api.", "service.",
            ];
            return external_patterns.iter()
                .any(|p| url.contains(p));
        }

        false
    }
}
```

---

## Permission Decision Flow

```rust
impl EccPermissionPolicy {
    pub async fn decide(
        &self,
        tool: &str,
        args: &Value,
        prompter: &dyn PermissionPrompter,
    ) -> Result<PermissionDecision> {
        // 1. Check explicit overrides
        let base_mode = self.resolve(tool);
        
        match base_mode {
            PermissionMode::Allow => {
                // Still analyze for audit trail
                let risk = self.risk_analyzer.analyze(tool, args).await;
                self.audit_logger.log_permission_granted(tool, args, risk).await;
                Ok(PermissionDecision::Allow)
            }
            PermissionMode::Deny => {
                self.audit_logger.log_permission_denied(tool, args, "Policy override".to_string()).await;
                Ok(PermissionDecision::Deny)
            }
            PermissionMode::Prompt => {
                // 2. Risk-based escalation
                let risk = self.risk_analyzer.analyze(tool, args).await;
                
                match risk.classification {
                    RiskClassification::Low => {
                        // Auto-allow low risk
                        self.audit_logger.log_auto_allowed(tool, args, risk).await;
                        Ok(PermissionDecision::Allow)
                    }
                    RiskClassification::Critical => {
                        // Auto-deny critical without prompt
                        self.audit_logger.log_auto_denied(tool, args, risk).await;
                        Ok(PermissionDecision::Deny)
                    }
                    _ => {
                        // 3. Prompt user
                        let response = prompter.prompt(tool, args).await?;
                        self.audit_logger.log_prompt_response(tool, args, &response).await;
                        Ok(response.into())
                    }
                }
            }
        }
    }
}
```

---

## Audit Logging

```rust
pub struct AuditLogger {
    log_file: PathBuf,
}

impl AuditLogger {
    pub async fn log_permission_granted(
        &self,
        tool: &str,
        args: &Value,
        risk: RiskAssessment,
    ) {
        let entry = AuditEntry {
            timestamp: Utc::now(),
            action: "PERMISSION_GRANTED",
            tool: tool.to_string(),
            args: args.clone(),
            risk_score: risk.score.final_score(),
            reason: "Policy allowed".to_string(),
        };
        self.write(entry).await;
    }

    pub async fn log_permission_denied(
        &self,
        tool: &str,
        args: &Value,
        reason: String,
    ) {
        let entry = AuditEntry {
            timestamp: Utc::now(),
            action: "PERMISSION_DENIED",
            tool: tool.to_string(),
            args: args.clone(),
            risk_score: 100, // Max risk for denied
            reason,
        };
        self.write(entry).await;
    }

    async fn write(&self, entry: AuditEntry) {
        let line = serde_json::to_string(&entry).unwrap();
        let mut file = tokio::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_file)
            .await
            .unwrap();
        
        tokio::io::AsyncWriteExt::write_all(
            &mut file, 
            format!("{}\n", line).as_bytes()
        ).await.unwrap();
    }
}
```

---

## Integration mit Security Review Skill

```rust
// skills/security-review/src/lib.rs

use ecc_permissions::{EccPermissionPolicy, RiskAnalyzer};

pub struct SecurityReviewSkill {
    policy: EccPermissionPolicy,
}

impl SecurityReviewSkill {
    pub async fn review_tool_call(
        &self,
        tool: &str,
        args: &Value
    ) -> SecurityReport {
        let risk = self.policy.risk_analyzer.analyze(tool, args).await;
        
        SecurityReport {
            tool: tool.to_string(),
            risk_score: risk.score.final_score(),
            classification: risk.classification,
            concerns: self.identify_concerns(tool, args, &risk),
            recommendations: self.generate_recommendations(&risk),
        }
    }

    fn identify_concerns(
        &self,
        tool: &str,
        args: &Value,
        risk: &RiskAssessment
    ) -> Vec<SecurityConcern> {
        let mut concerns = vec![];

        if risk.score.final_score() > 50 {
            concerns.push(SecurityConcern::HighRiskOperation);
        }

        if self.policy.risk_analyzer.operates_on_sensitive_path(args) {
            concerns.push(SecurityConcern::SensitiveDataAccess);
        }

        concerns
    }
}
```

---

## Output Dateien

1. `skills/security-review/src/permissions.rs`
2. `skills/security-review/src/risk.rs`
3. `skills/security-review/src/audit.rs`
4. `skills/security-review/src/policy.rs`
5. Tests in `skills/security-review/tests/`
