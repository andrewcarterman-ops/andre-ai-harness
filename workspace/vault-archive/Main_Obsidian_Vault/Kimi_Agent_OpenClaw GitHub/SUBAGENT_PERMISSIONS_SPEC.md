
# SUB-AGENT SPEZIFIKATION: Permission Policy Framework
## Task: Integriere claw-code Permissions mit Security Review Skill

---

## KONTEXT

**Quelle:** claw-code/rust/crates/runtime/src/permissions.rs
**Ziel:** ~/.openclaw/workspace/skills/security-review/
**Bestehend:** security-review Skill mit Risk-Analyse

---

## KERN-KOMPONENTEN (aus claw-code)

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

## ECC-ERWEITERUNGEN

### Risk-based Permission Policy
```rust
pub struct EccPermissionPolicy {
    // From claw-code
    default_mode: PermissionMode,
    tool_overrides: BTreeMap<String, PermissionMode>,

    // ECC extensions
    risk_analyzer: RiskAnalyzer,
    audit_logger: AuditLogger,
    escalation_config: EscalationConfig,
}

pub struct RiskAnalyzer {
    tool_risk_scores: HashMap<String, RiskScore>,
    pattern_matcher: PatternMatcher,
}

#[derive(Clone, Copy)]
pub enum RiskScore {
    Low = 1,
    Medium = 2,
    High = 3,
    Critical = 4,
}

impl EccPermissionPolicy {
    pub fn new() -> Self {
        let mut tool_risk_scores = HashMap::new();

        // Define risk scores for tools
        tool_risk_scores.insert("read".to_string(), RiskScore::Low);
        tool_risk_scores.insert("glob".to_string(), RiskScore::Low);
        tool_risk_scores.insert("grep".to_string(), RiskScore::Low);
        tool_risk_scores.insert("write".to_string(), RiskScore::Medium);
        tool_risk_scores.insert("edit".to_string(), RiskScore::Medium);
        tool_risk_scores.insert("bash".to_string(), RiskScore::High);
        tool_risk_scores.insert("web_fetch".to_string(), RiskScore::Medium);

        Self {
            default_mode: PermissionMode::Prompt,
            tool_overrides: BTreeMap::new(),
            risk_analyzer: RiskAnalyzer {
                tool_risk_scores,
                pattern_matcher: PatternMatcher::new(),
            },
            audit_logger: AuditLogger::new(),
            escalation_config: EscalationConfig::default(),
        }
    }

    pub async fn evaluate(
        &self,
        tool: &str,
        args: &Value
    ) -> Result<PermissionDecision, PolicyError> {
        // 1. Check explicit override
        let base_mode = self.tool_overrides
            .get(tool)
            .copied()
            .unwrap_or(self.default_mode);

        match base_mode {
            PermissionMode::Deny => {
                self.audit_logger.log(PermissionEvent::Denied {
                    tool: tool.to_string(),
                    reason: "Explicit deny policy".to_string(),
                }).await;
                return Ok(PermissionDecision::Deny);
            }
            PermissionMode::Allow => {
                // Still do risk analysis for audit
                let risk = self.risk_analyzer.analyze(tool, args);
                self.audit_logger.log(PermissionEvent::Allowed {
                    tool: tool.to_string(),
                    risk_score: risk,
                    auto_allowed: true,
                }).await;
                return Ok(PermissionDecision::Allow);
            }
            PermissionMode::Prompt => {
                // Continue to risk analysis
            }
        }

        // 2. Risk analysis
        let risk = self.risk_analyzer.analyze(tool, args);

        // 3. Auto-allow low risk in non-interactive mode
        if risk == RiskScore::Low && !self.is_interactive() {
            self.audit_logger.log(PermissionEvent::Allowed {
                tool: tool.to_string(),
                risk_score: risk,
                auto_allowed: true,
            }).await;
            return Ok(PermissionDecision::Allow);
        }

        // 4. Auto-deny critical risk
        if risk == RiskScore::Critical {
            self.audit_logger.log(PermissionEvent::Denied {
                tool: tool.to_string(),
                reason: "Critical risk detected".to_string(),
            }).await;
            return Ok(PermissionDecision::Deny);
        }

        // 5. Prompt user
        Ok(PermissionDecision::Prompt)
    }
}

impl RiskAnalyzer {
    pub fn analyze(&self, tool: &str, args: &Value) -> RiskScore {
        let base_score = self.tool_risk_scores
            .get(tool)
            .copied()
            .unwrap_or(RiskScore::Medium);

        // Analyze arguments for dangerous patterns
        let arg_risk = self.analyze_arguments(tool, args);

        // Combine scores
        match (base_score as u8).max(arg_risk as u8) {
            1 => RiskScore::Low,
            2 => RiskScore::Medium,
            3 => RiskScore::High,
            _ => RiskScore::Critical,
        }
    }

    fn analyze_arguments(&self, tool: &str, args: &Value) -> RiskScore {
        match tool {
            "bash" => self.analyze_bash_args(args),
            "write" | "edit" => self.analyze_file_args(args),
            "web_fetch" => self.analyze_web_args(args),
            _ => RiskScore::Low,
        }
    }

    fn analyze_bash_args(&self, args: &Value) -> RiskScore {
        let command = args.get("command")
            .and_then(|v| v.as_str())
            .unwrap_or("");

        // Dangerous patterns
        let dangerous = [
            "rm -rf", "dd if=", "mkfs", "fdisk",
            "> /dev/sda", "curl.*sh", "wget.*sh",
            "sudo", "su -", "passwd",
        ];

        for pattern in &dangerous {
            if command.contains(pattern) {
                return RiskScore::Critical;
            }
        }

        // Medium risk patterns
        let medium_risk = [
            "git push", "git reset --hard",
            "docker", "kubectl",
        ];

        for pattern in &medium_risk {
            if command.contains(pattern) {
                return RiskScore::High;
            }
        }

        RiskScore::Medium
    }

    fn analyze_file_args(&self, args: &Value) -> RiskScore {
        let path = args.get("path")
            .and_then(|v| v.as_str())
            .unwrap_or("");

        // Critical paths
        let critical = [
            "/etc/passwd", "/etc/shadow",
            "C:\Windows\System32",
            "~/.ssh", ".env",
        ];

        for critical_path in &critical {
            if path.contains(critical_path) {
                return RiskScore::Critical;
            }
        }

        // Check file extension
        if path.ends_with(".key") || path.ends_with(".pem") {
            return RiskScore::High;
        }

        RiskScore::Medium
    }

    fn analyze_web_args(&self, args: &Value) -> RiskScore {
        let url = args.get("url")
            .and_then(|v| v.as_str())
            .unwrap_or("");

        // Suspicious domains
        let suspicious = ["pastebin", "transfer.sh", "file.io"];
        for domain in &suspicious {
            if url.contains(domain) {
                return RiskScore::High;
            }
        }

        RiskScore::Medium
    }
}
```

### AuditLogger
```rust
pub struct AuditLogger {
    log_file: PathBuf,
}

#[derive(Debug, Serialize)]
pub enum PermissionEvent {
    Allowed {
        tool: String,
        risk_score: RiskScore,
        auto_allowed: bool,
        timestamp: DateTime<Utc>,
    },
    Denied {
        tool: String,
        reason: String,
        timestamp: DateTime<Utc>,
    },
    Prompted {
        tool: String,
        risk_score: RiskScore,
        user_response: String,
        timestamp: DateTime<Utc>,
    },
}

impl AuditLogger {
    pub async fn log(&self, event: PermissionEvent) {
        let entry = serde_json::to_string(&event).unwrap();

        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_file)
            .await
            .expect("Failed to open audit log");

        file.write_all(format!("{}\n", entry).as_bytes()).await.ok();
    }

    pub async fn get_recent_events(&self, limit: usize) -> Vec<PermissionEvent> {
        // Read and parse recent events
        if let Ok(content) = tokio::fs::read_to_string(&self.log_file).await {
            content.lines()
                .rev()
                .take(limit)
                .filter_map(|line| serde_json::from_str(line).ok())
                .collect()
        } else {
            vec![]
        }
    }
}
```

---

## INTEGRATION MIT BESTEHENDEM SECURITY-REVIEW SKILL

```rust
// skills/security-review/src/lib.rs (erweitert)

pub struct SecurityReview {
    permission_policy: EccPermissionPolicy,
    vulnerability_scanner: VulnerabilityScanner,
}

impl SecurityReview {
    pub fn new() -> Self {
        Self {
            permission_policy: EccPermissionPolicy::new(),
            vulnerability_scanner: VulnerabilityScanner::new(),
        }
    }

    pub async fn review_tool_call(
        &self,
        tool: &str,
        args: &Value
    ) -> SecurityReviewResult {
        // 1. Permission check
        let permission = self.permission_policy.evaluate(tool, args).await;

        // 2. Vulnerability scan
        let vulnerabilities = self.vulnerability_scanner.scan(tool, args);

        SecurityReviewResult {
            permission,
            vulnerabilities,
            recommendations: self.generate_recommendations(&vulnerabilities),
        }
    }
}
```

---

## AKZEPTANZKRITERIEN

- [ ] Three-tier permission system (Allow/Deny/Prompt) funktioniert
- [ ] Tool overrides koennen konfiguriert werden
- [ ] Risk-Analyzer erkennt gefaehrliche Bash-Befehle
- [ ] Risk-Analyzer erkennt kritische Dateipfade
- [ ] Audit-Logger schreibt alle Events
- [ ] Auto-allow fuer Low-Risk in non-interactive mode
- [ ] Auto-deny fuer Critical-Risk
- [ ] Integration mit security-review Skill
- [ ] Alle Tests passen

---

## OUTPUT

Erstelle:
1. `skills/security-review/src/permissions.rs`
2. `skills/security-review/src/risk_analyzer.rs`
3. `skills/security-review/src/audit_logger.rs`
4. Update `skills/security-review/src/lib.rs`
5. Tests in `skills/security-review/tests/`
