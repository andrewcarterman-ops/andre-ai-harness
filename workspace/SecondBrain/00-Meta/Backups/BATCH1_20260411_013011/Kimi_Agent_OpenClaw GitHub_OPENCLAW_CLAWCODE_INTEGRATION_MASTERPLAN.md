
# OPENCLAW-CLAWCODE INTEGRATION MASTERPLAN
## Fuer LLM-Implementation & Automatisierte Integration

---

## EXECUTIVE SUMMARY

Dieses Dokument spezifiziert die vollstaendige Integration von claw-code Komponenten 
in das bestehende OpenClaw-Setup (Andrew/ECC Framework). 

**Kernprinzipien:**
- Nutze Rust-Layer (produktionsreif), ignoriere Python-Layer (Scaffolding)
- Priorisiere: SSE Streaming → Conversation Loop → Permissions → Compaction
- Erhalte ECC-Framework Integritaet (Fort Knox, Second Brain, Autoresearch)
- Synergien > Neuerfindung

---

## 1. BESTANDSANALYSE: OPENCLAW SETUP (ANDREW/ECC)

### 1.1 Aktuelle Architektur
```
C:\Users\andre\.openclaw\workspace\
├── SOUL.md                    # Identitaet (Andrew)
├── USER.md                    # Parzival Profil
├── MEMORY.md                  # Kuratiertes Langzeitgedaechtnis
├── AGENTS.md                  # Systemkonfiguration
├── HEARTBEAT.md               # Periodische Tasks
├── TOOLS.md                   # Umgebungsspezifische Notizen
├── memory\YYYY-MM-DD.md      # Taegliche Session-Logs
├── skills\                   # Agent Skills
│   ├── security-review\SKILL.md
│   ├── api-design\SKILL.md
│   ├── tdd-loop\SKILL.md
│   └── ecc-autoresearch\SKILL.md
└── docs\                     # OpenClaw Dokumentation

C:\Users\andre\Documents\Andrew Openclaw\
├── Kimi_Agent_ECC-Second-Brain-Framework\
│   └── SecondBrain\          # Obsidian Vault
└── Code implement\           # Code-Projekte
```

### 1.2 Aktive Faehigkeiten
- **Security Review**: Automatisierte Sicherheitsanalyse
- **Secure API Client**: HTTP mit Auth/Rate Limiting
- **ECC Autoresearch**: Autonome Recherche mit Safety-Constraints
- **Sub-Agent Orchestration**: sessions_spawn, ACP-Protokoll
- **Memory System**: Taegliche Logs + kuratiertes MEMORY.md

### 1.3 Technische Umgebung
- **OS**: Windows 10 (German locale)
- **Shell**: PowerShell
- **Main PC**: DESKTOP-JAQLG9S (OpenClaw Gateway port 18789)
- **Netzwerk**: 192.168.1.25 / 192.168.178.192, Tailscale
- **Praeferenzen**: Docker fuer Isolation, Git, Obsidian

---

## 2. CLAW-CODE KOMPONENTEN-ANALYSE

### 2.1 Repository Struktur
```
claw-code/
├── rust/crates/               # PRODUKTIONSREIF (4,000 LOC)
│   ├── api/                   # SSE Streaming + HTTP Client
│   ├── runtime/               # Conversation Loop + Session
│   │   ├── conversation.rs    # Agent Loop (COPY-PASTE READY)
│   │   ├── permissions.rs     # Permission Framework
│   │   ├── compact.rs         # Session Compaction
│   │   ├── session.rs         # State Management
│   │   └── prompt.rs          # Context Assembly
│   ├── tools/                 # Tool Implementierungen
│   ├── commands/              # Slash Commands
│   ├── plugins/               # Hooks Pipeline
│   └── claw-cli/              # REPL Binary
├── src/                       # REFERENCE ONLY (1,500 LOC)
│   └── Python scaffolding (nicht fuer Produktion)
└── PARITY.md                  # Implementierungs-Status
```

### 2.2 Priorisierte Komponenten (aus PDF-Audit)

#### TIER 1: DEPLOY TODAY (Velocity Score 9-10)
| Rank | Komponente | Datei | Nutzen | Action |
|------|------------|-------|--------|--------|
| 1 | SSE Streaming API Client | api/src/stream.rs | 10/10 | COPY |
| 2 | Conversation Runtime Loop | runtime/conversation.rs | 10/10 | COPY |
| 3 | Permission Policy Framework | runtime/permissions.rs | 9/10 | COPY |
| 4 | HTTP Client mit Retry | api/src/client.rs | 9/10 | COPY |
| 5 | File Operation Tools | tools/file_ops.rs | 8/10 | COPY |

#### TIER 2: DEPLOY THIS WEEK (Velocity Score 6-8)
| Rank | Komponente | Datei | Nutzen | Action |
|------|------------|-------|--------|--------|
| 6 | Session Compaction Engine | runtime/compact.rs | 8/10 | ADAPT |
| 7 | Tool Executor Trait System | tools/lib.rs | 8/10 | ADAPT |
| 8 | MCP Stdio Integration | runtime/mcp_stdio.rs | 7/10 | ADAPT |
| 9 | Plugin Hooks Pipeline | plugins/src/lib.rs | 7/10 | ADAPT |
| 10 | CLAW.md Config Hierarchy | runtime/config.rs | 6/10 | ADAPT |

---

## 3. SYNERGIE-ANALYSE & INTEGRATIONSSTRATEGIE

### 3.1 Hochsynergetische Integrationen

#### A) SSE Streaming API Client → Secure API Client Skill
**Bestehend:** `secure-api-client` Skill mit Auth/Rate Limiting
**claw-code:** api/src/stream.rs (SSE mit Backpressure, Retry)
**Synergie:** Kombiniere beide fuer produktionsreifen Streaming-Client

**Integrationsplan:**
```rust
// NEU: openclaw/crates/streaming-api-client/
// Kombiniert:
// - claw-code: SSE frame parsing, incremental parsing
// - OpenClaw: Auth-Management, Rate-Limiting, Token-Tracking

pub struct SecureStreamingClient {
    // Von claw-code:
    sse_parser: SseStreamParser,      // stream.rs
    retry_policy: ExponentialBackoff, // client.rs

    // Von OpenClaw:
    auth_manager: AuthManager,        // secure-api-client
    rate_limiter: RateLimiter,        // secure-api-client
    token_tracker: TokenTracker,      // secure-api-client
}
```

**Konkrete Schritte:**
1. Extrahiere `SseStreamParser` aus claw-code/api/src/stream.rs
2. Integriere in bestehenden `secure-api-client` Skill
3. Fuege Token-Tracking hinzu (cache_creation_input_tokens, cache_read_input_tokens)
4. Teste mit Anthropic Messages API v1

---

#### B) Conversation Runtime Loop → ECC Agent Orchestration
**Bestehend:** Sub-Agent Spawning, ACP-Protokoll
**claw-code:** runtime/conversation.rs (trait-basierte Abstraktion)
**Synergie:** Ersetze monolithische Loop durch claw-codes generische, testbare Architektur

**Integrationsplan:**
```rust
// NEU: openclaw/crates/ecc-runtime/
// Erweitert claw-code Pattern mit ECC-Safety

pub struct EccConversationRuntime<C, T, S> 
where
    C: ApiClient,
    T: ToolExecutor,
    S: SafetyGuard,  // NEU: ECC Fort Knox Integration
{
    // Von claw-code:
    client: C,
    tools: T,
    session: Session,
    config: RuntimeConfig,

    // ECC-Erweiterungen:
    safety_guard: S,              // Fort Knox Isolation
    memory_bridge: MemoryBridge,  // Second Brain Integration
    subagent_spawner: SubAgentSpawner,  // Bestehende Funktionalitaet
}
```

**Konkrete Schritte:**
1. Kopiere `ConversationRuntime` Struktur aus claw-code
2. Fuege `SafetyGuard` Trait fuer Fort Knox Integration hinzu
3. Ersetze direkte Tool-Ausfuehrung durch ECC-sandboxed Execution
4. Integriere MemoryBridge fuer automatische Second Brain Updates

---

#### C) Permission Policy Framework → Security Review Skill
**Bestehend:** `security-review` Skill
**claw-code:** runtime/permissions.rs (Three-tier: Allow/Deny/Prompt)
**Synergie:** Verstaerke Security Review mit granularem Permission System

**Integrationsplan:**
```rust
// ERWEITERT: skills/security-review/ mit claw-code Permissions

pub struct EccPermissionPolicy {
    // Von claw-code:
    default_mode: PermissionMode,  // Allow/Deny/Prompt
    tool_overrides: BTreeMap<String, PermissionMode>,

    // ECC-Erweiterungen:
    risk_analyzer: RiskAnalyzer,           // Aus security-review
    audit_logger: AuditLogger,             // Compliance-Logging
    auto_escalation: AutoEscalationConfig, // Fuer kritische Tools
}
```

**Konkrete Schritte:**
1. Extrahiere `PermissionPolicy` und `PermissionPrompter` Trait
2. Integriere in `security-review` Skill
3. Fuege Risk-Scoring basierend auf Tool-Kategorie hinzu
4. Implementiere Audit-Logging fuer alle Permission-Entscheidungen

---

#### D) Session Compaction → Memory System
**Bestehend:** MEMORY.md, memory/YYYY-MM-DD.md
**claw-code:** runtime/compact.rs (Token-basierte Zusammenfassung)
**Synergie:** Automatisiere Memory-Kuratierung durch claw-code Compaction

**Integrationsplan:**
```rust
// NEU: openclaw/crates/memory-compaction/

pub struct EccMemoryCompaction {
    // Von claw-code:
    compaction_engine: CompactionEngine,
    token_estimator: TokenEstimator,

    // ECC-Erweiterungen:
    memory_classifier: MemoryClassifier,  // Wichtig vs. Trivial
    obsidian_sync: ObsidianSync,          // Second Brain Integration
    daily_log_writer: DailyLogWriter,     // memory/YYYY-MM-DD.md
}

impl EccMemoryCompaction {
    pub async fn compact_and_sync(&mut self) -> Result<()> {
        // 1. claw-code: Komprimiere Session
        let summary = self.compaction_engine.compact().await?;

        // 2. ECC: Klassifiziere nach Wichtigkeit
        let classified = self.memory_classifier.classify(summary);

        // 3. ECC: Schreibe in Second Brain
        self.obsidian_sync.sync(classified.important).await?;

        // 4. ECC: Aktualisiere MEMORY.md
        self.update_memory_md(classified.key_insights).await?;

        Ok(())
    }
}
```

---

### 3.2 Mittlere Synergie (Anpassung erforderlich)

#### E) MCP Stdio Integration → ECC Autoresearch
**Bestehend:** `ecc-autoresearch` Skill
**claw-code:** runtime/mcp_stdio.rs (MCP Transport)
**Synergie:** Nutze MCP fuer externe Tool-Integration in Autoresearch

**Herausforderung:** MCP Integration unvollstaendig in claw-code
**Loesung:** Verwende als Inspiration, implementiere vollstaendig

---

#### F) Tool Executor Trait → Bestehende Tools
**Bestehend:** File Operations, exec, web_search, etc.
**claw-code:** tools/lib.rs (Tool Trait + Registry)
**Synergie:** Standardisiere Tool-Implementierungen

**Integrationsplan:**
```rust
// REFACTOR: Bestehende Tools auf claw-code Pattern

// Vorher (monolithisch):
fn bash_command(cmd: &str) -> Result<String>

// Nachher (trait-basiert):
pub trait Tool {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn schema(&self) -> Value;  // JSON Schema
    async fn execute(&self, args: Value) -> Result<ToolResult>;
}

pub struct BashTool {
    permission_policy: PermissionPolicy,
    timeout: Duration,
}

impl Tool for BashTool {
    // ...
}
```

---

## 4. DETAILLIERTE IMPLEMENTIERUNGSPLAENE

### 4.1 Phase 1: Foundation (Woche 1)

#### Task 1.1: SSE Streaming Integration
**Ziel:** Produktionsreifer Streaming-Client mit Auth/Retry
**Dateien:**
- Quelle: `claw-code/rust/crates/api/src/stream.rs`
- Ziel: `~/.openclaw/workspace/skills/secure-api-client/`

**Extrahiere:**
```rust
// Aus stream.rs
pub struct SseStreamParser {
    buffer: String,
    max_frame_bytes: usize,
}

impl SseStreamParser {
    pub fn new(max_frame_bytes: usize) -> Self;
    pub fn feed(&mut self, chunk: &str) -> Vec<SseFrame>;
    pub fn flush(&mut self) -> Vec<SseFrame>;
}

pub struct SseFrame {
    pub event_type: String,
    pub data: String,
    pub id: Option<String>,
}
```

**Integrationsschritte:**
1. Kopiere `stream.rs` in Skill-Verzeichnis
2. Fuege Auth-Header Management hinzu
3. Integriere Rate-Limiting
4. Implementiere Token-Tracking
5. Schreibe Tests

**Ergebnis:** `secure-streaming-api-client` Skill

---

#### Task 1.2: Conversation Loop Integration
**Ziel:** Generische, testbare Agent Loop
**Dateien:**
- Quelle: `claw-code/rust/crates/runtime/src/conversation.rs`
- Ziel: `~/.openclaw/workspace/crates/ecc-runtime/`

**Extrahiere:**
```rust
// Aus conversation.rs
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
    pub max_context_tokens: usize,  // default: 128000 * 0.8
    pub timeout_seconds: u64,
    pub max_retries: u32,
}

pub trait ApiClient {
    async fn stream_request(&self, request: Request) -> Result<SseStream>;
}

pub trait ToolExecutor {
    async fn execute(&self, tool_use: ToolUse) -> Result<ToolResult>;
    fn available_tools(&self) -> Vec<ToolDefinition>;
}
```

**ECC-Erweiterungen:**
```rust
// Zusaetzlich fuer OpenClaw:
pub trait SafetyGuard {
    fn validate_tool_call(&self, tool: &str, args: &Value) -> Result<()>;
    fn validate_file_access(&self, path: &Path) -> Result<()>;
    fn validate_network_request(&self, url: &str) -> Result<()>;
}

pub struct EccRuntimeConfig {
    // Von claw-code
    base: RuntimeConfig,
    // ECC-spezifisch
    fort_knox_enabled: bool,
    auto_research_enabled: bool,
    memory_sync_enabled: bool,
}
```

---

#### Task 1.3: Permission Framework Integration
**Ziel:** Granulares Permission System
**Dateien:**
- Quelle: `claw-code/rust/crates/runtime/src/permissions.rs`
- Ziel: `~/.openclaw/workspace/skills/security-review/permissions.rs`

**Extrahiere:**
```rust
pub enum PermissionMode {
    Allow,
    Deny,
    Prompt,
}

pub struct PermissionPolicy {
    pub default_mode: PermissionMode,
    pub tool_overrides: BTreeMap<String, PermissionMode>,
}

#[async_trait]
pub trait PermissionPrompter {
    async fn prompt(&self, tool: &str, args: &Value) -> Result<bool>;
}
```

**Integration:**
- Verbinde mit `security-review` Skill
- Fuege Risk-Scoring hinzu
- Implementiere Audit-Logging

---

### 4.2 Phase 2: Memory & Context (Woche 2)

#### Task 2.1: Session Compaction
**Ziel:** Automatisierte Memory-Kuratierung
**Dateien:**
- Quelle: `claw-code/rust/crates/runtime/src/compact.rs`
- Ziel: `~/.openclaw/workspace/crates/memory-compaction/`

**Algorithmus (aus claw-code):**
```rust
pub struct CompactionEngine {
    max_estimated_tokens: usize,  // default: 10,000 (80% of 128K)
    preserve_recent: usize,       // default: 4 messages
}

impl CompactionEngine {
    pub async fn compact(&self, session: &mut Session) -> Result<()> {
        // 1. Trigger: Token count vs threshold
        let estimated = self.estimate_tokens(&session.messages);
        if estimated < self.max_estimated_tokens {
            return Ok(());  // No compaction needed
        }

        // 2. Partition: Identify summarization target
        let to_summarize = &session.messages[..session.messages.len() - self.preserve_recent];
        let to_preserve = &session.messages[session.messages.len() - self.preserve_recent..];

        // 3. Generate summary via LLM
        let summary = self.summarize(to_summarize).await?;

        // 4. Reconstruct session
        session.messages.clear();
        session.messages.push(Message::system(summary));
        session.messages.extend(to_preserve.iter().cloned());

        Ok(())
    }
}
```

**ECC-Erweiterung:**
- Speichere Summary in Second Brain
- Aktualisiere MEMORY.md
- Klassifiziere nach Wichtigkeit

---

#### Task 2.2: Context Assembly
**Ziel:** Dynamischer System Prompt
**Dateien:**
- Quelle: `claw-code/rust/crates/runtime/src/prompt.rs`
- Ziel: `~/.openclaw/workspace/crates/context-assembly/`

**CLAW.md Discovery (aus claw-code):**
```rust
pub fn discover_instruction_files(cwd: &Path) -> io::Result<Vec<ContextFile>> {
    // Traverse from current directory to root
    let mut directories = Vec::new();
    let mut cursor = Some(cwd);
    while let Some(dir) = cursor {
        directories.push(dir.to_path_buf());
        cursor = dir.parent();
    }

    // Reverse for root-to-leaf ordering
    directories.reverse();

    // Collect candidates
    let mut files = Vec::new();
    for dir in directories {
        for candidate in [
            dir.join("CLAUDE.md"),
            dir.join("CLAUDE.local.md"),
            dir.join(".claude").join("CLAUDE.md"),
            dir.join(".claude").join("instructions.md"),
        ] {
            if candidate.exists() {
                files.push(ContextFile::from_path(candidate)?);
            }
        }
    }

    // Deduplication by content hash
    Ok(dedupe_instruction_files(files))
}
```

**ECC-Anpassung:**
- Nutze SOUL.md als Basis
- Integriere USER.md Kontext
- Fuege MEMORY.md fuer relevante Historie

---

### 4.3 Phase 3: Tools & Erweiterungen (Woche 3)

#### Task 3.1: Tool Registry Standardisierung
**Ziel:** Einheitliche Tool-Implementierung
**Dateien:**
- Quelle: `claw-code/rust/crates/tools/src/lib.rs`
- Ziel: `~/.openclaw/workspace/crates/tool-registry/`

**Trait-Definition:**
```rust
#[async_trait]
pub trait Tool: Send + Sync {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn parameters(&self) -> Value;  // JSON Schema
    async fn execute(&self, args: Value) -> Result<ToolResult>;
}

pub struct ToolResult {
    pub content: String,
    pub is_error: bool,
    pub metadata: Option<Value>,
}

pub struct ToolRegistry {
    tools: HashMap<String, Box<dyn Tool>>,
}

impl ToolRegistry {
    pub fn register<T: Tool + 'static>(&mut self, tool: T);
    pub async fn execute(&self, name: &str, args: Value) -> Result<ToolResult>;
}
```

**MVP Tools (aus claw-code):**
1. Bash - Command execution with timeout
2. Read - File read with size limits
3. Write - File write with auto-mkdir
4. Edit - Exact string replacement
5. Glob - Pattern matching (mtime sort)
6. Grep - Text search with context

---

#### Task 3.2: MCP Integration
**Ziel:** Externe Tool-Erweiterung
**Dateien:**
- Quelle: `claw-code/rust/crates/runtime/src/mcp*.rs`
- Ziel: `~/.openclaw/workspace/crates/mcp-client/`

**Hinweis:** claw-code MCP unvollstaendig - als Inspiration nutzen

---

## 5. KONKRETE DATEISTRUKTUR FUER INTEGRATION

### 5.1 Empfohlene Verzeichnisstruktur
```
~/.openclaw/workspace/
├── SOUL.md                              # Bestehend
├── USER.md                              # Bestehend
├── MEMORY.md                            # Bestehend
├── AGENTS.md                            # Bestehend
├── HEARTBEAT.md                         # Bestehend
├── TOOLS.md                             # Bestehend
├── CLAW.md                              # NEU: Projekt-Instructions
├── CLAW.local.md                        # NEU: Lokale Anpassungen
├── memory/                              # Bestehend
├── skills/                              # Bestehend + Erweiterungen
│   ├── security-review/
│   │   ├── SKILL.md                     # Bestehend
│   │   ├── permissions.rs               # NEU: claw-code Integration
│   │   └── risk_analyzer.rs             # Bestehend
│   ├── secure-api-client/
│   │   ├── SKILL.md                     # Bestehend
│   │   ├── streaming.rs                 # NEU: claw-code SSE
│   │   └── retry.rs                     # NEU: claw-code Retry
│   ├── ecc-autoresearch/
│   │   ├── SKILL.md                     # Bestehend
│   │   └── mcp_bridge.rs                # NEU: MCP Integration
│   └── tool-registry/
│       └── SKILL.md                     # NEU: Standardisierte Tools
├── crates/                              # NEU: Rust-Integration
│   ├── ecc-runtime/                     # NEU: Conversation Loop
│   │   ├── src/
│   │   │   ├── lib.rs
│   │   │   ├── runtime.rs               # claw-code + ECC
│   │   │   ├── safety.rs                # Fort Knox Integration
│   │   │   └── memory_bridge.rs         # Second Brain Sync
│   │   └── Cargo.toml
│   ├── memory-compaction/               # NEU: Session Compaction
│   │   ├── src/
│   │   │   ├── lib.rs
│   │   │   ├── compactor.rs             # claw-code
│   │   │   └── obsidian_sync.rs         # ECC
│   │   └── Cargo.toml
│   ├── context-assembly/                # NEU: Prompt Builder
│   │   ├── src/
│   │   │   ├── lib.rs
│   │   │   ├── prompt.rs                # claw-code
│   │   │   └── ecc_context.rs           # SOUL/USER/MEMORY
│   │   └── Cargo.toml
│   └── tool-registry/                   # NEU: Tool System
│       ├── src/
│       │   ├── lib.rs
│       │   ├── registry.rs              # claw-code
│       │   ├── bash.rs                  # claw-code
│       │   ├── file_ops.rs              # claw-code
│       │   └── ecc_tools.rs             # Bestehende Tools
│       └── Cargo.toml
└── docs/                                # Bestehend
```

---

## 6. IMPLEMENTIERUNGSREIHENFOLGE

### Sprint 1: Foundation (Tage 1-3)
- [ ] Task 1.1: SSE Streaming in secure-api-client
- [ ] Task 1.2: Conversation Loop Struktur
- [ ] Task 1.3: Permission Framework

### Sprint 2: Memory & Context (Tage 4-6)
- [ ] Task 2.1: Session Compaction
- [ ] Task 2.2: Context Assembly
- [ ] Task 2.3: CLAW.md Integration

### Sprint 3: Tools & Polish (Tage 7-9)
- [ ] Task 3.1: Tool Registry
- [ ] Task 3.2: Bestehende Tools migrieren
- [ ] Task 3.3: MCP Client (optional)

### Sprint 4: Integration & Testing (Tage 10-12)
- [ ] Integration aller Komponenten
- [ ] End-to-End Tests
- [ ] Dokumentation

---

## 7. RISIKEN & MITIGATIONEN

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| claw-code API-Aenderungen | Mittel | Hoch | Pin auf spezifischen Commit |
| Rust-Komplexitaet | Mittel | Mittel | Inkrementelle Integration |
| Windows-Kompatibilitaet | Niedrig | Hoch | CI mit Windows-Tests |
| ECC-Framework Konflikte | Niedrig | Hoch | Feature-Flags fuer Modularitaet |
| Performance-Regression | Niedrig | Mittel | Benchmarks vor/nach |

---

## 8. TESTSTRATEGIE

### 8.1 Unit Tests
- Jede extrahierte Komponente isoliert testen
- Mock-Implementierungen fuer ApiClient/ToolExecutor

### 8.2 Integration Tests
- End-to-End Conversation Loop
- Tool Execution mit Permission Checks
- Session Persistence & Compaction

### 8.3 ECC-Specific Tests
- Fort Knox Isolation
- Second Brain Sync
- Memory System Integration

---

## 9. DOKUMENTATION

### 9.1 Fuer Entwickler
- Architektur-Uebersicht (Dieses Dokument)
- API-Dokumentation (rustdoc)
- Integration-Guide

### 9.2 Fuer LLMs
- Dieses Dokument als Kontext
- Inline-Kommentare mit ECC-Referenzen
- Beispiel-Integrationen

---

## 10. ANHANG: CODE-EXTRAKTE

### 10.1 Aus conversation.rs (Kern-Loop)
```rust
// Aus claw-code/rust/crates/runtime/src/conversation.rs
// SIMPLIFIED EXTRACT

pub async fn run(&mut self, user_message: &str) -> Result<ConversationResult> {
    // 1. Add user message to session
    self.session.add_user_message(user_message);

    let mut iteration = 0;
    loop {
        // Safety: iteration limit
        if iteration >= self.config.max_iterations {
            return Ok(ConversationResult::MaxIterationsReached);
        }
        iteration += 1;

        // 2. Check token budget
        if self.should_compact() {
            self.compact_session().await?;
        }

        // 3. Build system prompt
        let system_prompt = self.build_system_prompt();

        // 4. Stream request to LLM
        let mut stream = self.client.stream_request(Request {
            system: system_prompt,
            messages: self.session.messages.clone(),
            tools: self.tools.available_tools(),
        }).await?;

        // 5. Process stream
        let mut assistant_message = String::new();
        let mut tool_uses = Vec::new();

        while let Some(frame) = stream.next().await {
            match frame {
                SseFrame::Content(text) => {
                    assistant_message.push_str(&text);
                    // Stream to UI...
                }
                SseFrame::ToolUse(tool_use) => {
                    tool_uses.push(tool_use);
                }
                SseFrame::Done => break,
            }
        }

        // 6. Add assistant message
        self.session.add_assistant_message(&assistant_message, &tool_uses);

        // 7. Execute tools
        if tool_uses.is_empty() {
            // No tools, conversation complete
            return Ok(ConversationResult::Complete);
        }

        for tool_use in tool_uses {
            // Check permission
            if !self.check_permission(&tool_use).await? {
                self.session.add_tool_result(&tool_use.id, "Permission denied");
                continue;
            }

            // Execute
            let result = self.tools.execute(tool_use).await?;
            self.session.add_tool_result(&tool_use.id, &result);
        }

        // Loop continues with tool results
    }
}
```

### 10.2 Aus permissions.rs
```rust
// Aus claw-code/rust/crates/runtime/src/permissions.rs

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

#[async_trait]
pub trait PermissionPrompter: Send + Sync {
    async fn prompt(&self, tool: &str, args: &Value) -> Result<PermissionResponse>;
}

pub enum PermissionResponse {
    Allow,
    Deny,
    AllowOnce,
    DenyOnce,
}
```

### 10.3 Aus compact.rs
```rust
// Aus claw-code/rust/crates/runtime/src/compact.rs

pub struct CompactionConfig {
    pub max_estimated_tokens: usize,  // default: 10_000
    pub preserve_recent: usize,       // default: 4
}

pub struct CompactionEngine<S: Summarizer> {
    config: CompactionConfig,
    summarizer: S,
}

#[async_trait]
pub trait Summarizer: Send + Sync {
    async fn summarize(&self, messages: &[Message]) -> Result<String>;
}

impl<S: Summarizer> CompactionEngine<S> {
    pub async fn compact(&self, session: &mut Session) -> Result<()> {
        let estimated = self.estimate_tokens(&session.messages);

        if estimated <= self.config.max_estimated_tokens {
            return Ok(());
        }

        let split_point = session.messages.len().saturating_sub(self.config.preserve_recent);
        let to_summarize = &session.messages[..split_point];
        let to_preserve = &session.messages[split_point..].to_vec();

        let summary = self.summarizer.summarize(to_summarize).await?;

        session.messages.clear();
        session.messages.push(Message::system(format!(
            "Previous conversation summary: {}",
            summary
        )));
        session.messages.extend(to_preserve.into_iter());

        Ok(())
    }

    fn estimate_tokens(&self, messages: &[Message]) -> usize {
        // Naive: chars / 4
        // TODO: Use proper tokenizer
        messages.iter()
            .map(|m| m.content.len() / 4)
            .sum()
    }
}
```

---

**END OF DOCUMENT**

Dieser Plan ist optimiert fuer:
1. **LLM-Verstaendnis**: Klare Struktur, Code-Beispiele, konkrete Dateipfade
2. **Inkrementelle Implementation**: Phasen, Sprints, Tasks
3. **Synergie-Maximierung**: Bestehende ECC-Funktionalitaet erhalten
4. **Produktionsreife**: Fokus auf getestete claw-code Rust-Komponenten
