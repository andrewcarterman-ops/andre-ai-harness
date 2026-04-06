# Security Audit Report: claw-code
**Repository:** https://github.com/instructkr/claw-code.git  
**Audit Date:** 2026-04-01  
**Auditor:** Andrew (OpenClaw Security Review)  
**Scope:** Python (67 files) + Rust (35 files) codebase

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Critical Issues** | 0 |
| **High Risk** | 3 |
| **Medium Risk** | 4 |
| **Low Risk** | 2 |
| **Info** | 3 |

**Overall Risk Rating:** MEDIUM-HIGH ⚠️

The codebase implements a Claude Code-like AI assistant with extensive tool capabilities. While the architecture includes a permission system (`PermissionMode`), several high-risk tools (`bash`, `PowerShell`, `REPL`, `Agent`) can execute arbitrary code if misconfigured or exploited.

---

## Findings

### 🔴 HIGH-1: Arbitrary Code Execution via REPL Tool

**Location:** `rust/crates/tools/src/lib.rs:1028-1060`

**Issue:** The `REPL` tool executes code in a subprocess without proper sandboxing:

```rust
fn execute_repl(input: ReplInput) -> Result<ReplOutput, String> {
    // ...
    let output = Command::new(runtime.program)
        .args(runtime.args)
        .arg(&input.code)  // User-controlled code execution
        .output()
        // ...
}
```

**Risk:** An attacker can execute arbitrary system commands through Python, Node.js, or shell interpreters.

**Mitigation:** 
- Requires `PermissionMode::DangerFullAccess`
- Implement code sandboxing (e.g., seccomp, chroot)
- Add resource limits (CPU, memory)

---

### 🔴 HIGH-2: PowerShell/Bash Command Injection

**Location:** `rust/crates/tools/src/lib.rs:1275-1360` (execute_powershell, execute_shell_command)

**Issue:** Shell commands are executed with user-controlled input without sanitization:

```rust
fn execute_shell_command(
    shell: &str,
    command: &str,  // User input
    timeout: Option<u64>,
    run_in_background: Option<bool>,
) -> std::io::Result<runtime::BashCommandOutput> {
    // ...
    process
        .arg("-Command")
        .arg(command)  // Direct pass-through
```

**Risk:** Command injection vulnerabilities if the LLM generates malicious commands.

**Mitigation:**
- Requires `PermissionMode::DangerFullAccess`
- Shell escaping applied
- Timeout protection

---

### 🔴 HIGH-3: Agent Tool Spawns Unrestricted Sub-agents

**Location:** `rust/crates/tools/src/lib.rs:720-850`

**Issue:** The `Agent` tool can spawn background sub-agents with tool subsets that may include dangerous tools:

```rust
fn execute_agent(input: AgentInput) -> Result<AgentOutput, String> {
    // Spawns thread with tool execution capabilities
    std::thread::Builder::new()
        .spawn(move || {
            let result = run_agent_job(&job);  // Unrestricted execution
        })
}
```

**Risk:** Recursive agent spawning could lead to resource exhaustion or privilege escalation.

---

### 🟡 MEDIUM-1: File Path Traversal in File Operations

**Location:** `rust/crates/tools/src/lib.rs` (read_file, write_file, edit_file)

**Issue:** No path validation to prevent directory traversal:

```rust
fn run_read_file(input: ReadFileInput) -> Result<String, String> {
    read_file(&input.path, ...)  // Path used directly
}
```

**Impact:** Could read/write files outside workspace if `PermissionMode::DangerFullAccess` is active.

**Recommendation:** Validate paths are within workspace directory.

---

### 🟡 MEDIUM-2: `dangerouslyDisableSandbox` Parameter

**Location:** ToolSpec schema in `rust/crates/tools/src/lib.rs:72-85`

**Issue:** The bash tool accepts a `dangerouslyDisableSandbox` flag:

```rust
ToolSpec {
    name: "bash",
    input_schema: json!({
        "properties": {
            "dangerouslyDisableSandbox": { "type": "boolean" }
        }
    }),
    required_permission: PermissionMode::DangerFullAccess,
}
```

**Impact:** Explicit bypass mechanism for sandbox controls.

---

### 🟡 MEDIUM-3: WebFetch URL Redirection to File System

**Location:** `rust/crates/tools/src/lib.rs:950-1000` (execute_web_fetch)

**Issue:** URL normalization upgrades HTTP to HTTPS but doesn't prevent file:// URLs:

```rust
fn normalize_fetch_url(url: &str) -> Result<String, String> {
    // Only upgrades http -> https for non-local hosts
    // file:// URLs pass through
}
```

**Impact:** Potential for local file disclosure via crafted URLs.

---

### 🟡 MEDIUM-4: NotebookEdit Arbitrary JSON Manipulation

**Location:** `rust/crates/tools/src/lib.rs:1100-1250`

**Issue:** Direct JSON manipulation of `.ipynb` files without validation:

```rust
fn execute_notebook_edit(input: NotebookEditInput) -> Result<NotebookEditOutput, String> {
    let mut notebook: serde_json::Value = serde_json::from_str(&original_file)?;
    // Direct mutation of notebook structure
}
```

**Impact:** Could corrupt notebook files or inject malicious code cells.

---

### 🟢 LOW-1: Default Permission Mode is DangerFullAccess

**Location:** `rust/crates/rusty-claude-cli/src/main.rs:195-201`

```rust
fn default_permission_mode() -> PermissionMode {
    env::var("RUSTY_CLAUDE_PERMISSION_MODE")
        .ok()
        .map_or(PermissionMode::DangerFullAccess, ...)  // ⚠️ Default
}
```

**Impact:** Users without explicit configuration run with maximum privileges.

**Recommendation:** Default to `ReadOnly` or `WorkspaceWrite`.

---

### 🟢 LOW-2: Environment Variable Leakage in MCP Servers

**Location:** `rust/crates/runtime/src/mcp_stdio.rs:380-385`

```rust
fn apply_env(command: &mut Command, env: &BTreeMap<String, String>) {
    for (key, value) in env {
        command.env(key, value);  // Full env passthrough
    }
}
```

**Impact:** Sensitive environment variables may be exposed to MCP subprocesses.

---

### ℹ️ INFO-1: Comprehensive Permission System Exists

**Positive Finding:** The codebase implements a robust permission tier system:

```rust
pub enum PermissionMode {
    ReadOnly,           // Search/read only
    WorkspaceWrite,     // File edits within workspace
    DangerFullAccess,   // Full shell access
}
```

All dangerous tools require `DangerFullAccess` level.

---

### ℹ️ INFO-2: Input Validation via JSON Schema

**Positive Finding:** Tool inputs are validated against JSON schemas with proper type checking.

---

### ℹ️ INFO-3: Timeout Protection

**Positive Finding:** Network and shell operations have timeout protections (20s for HTTP, configurable for shell).

---

## Recommendations Summary

| Priority | Recommendation |
|----------|---------------|
| HIGH | Implement sandboxing for REPL/code execution |
| HIGH | Add path traversal validation for file operations |
| HIGH | Change default permission mode to ReadOnly |
| MEDIUM | Remove or protect `dangerouslyDisableSandbox` flag |
| MEDIUM | Add URL scheme whitelist for WebFetch |
| MEDIUM | Sanitize notebook cell content |
| LOW | Implement environment variable filtering |
| LOW | Add audit logging for tool executions |

---

## Appendix: Tool Permission Matrix

| Tool | Required Permission | Risk Level |
|------|---------------------|------------|
| read_file | ReadOnly | 🟢 Low |
| glob_search | ReadOnly | 🟢 Low |
| grep_search | ReadOnly | 🟢 Low |
| WebFetch | ReadOnly | 🟡 Medium |
| WebSearch | ReadOnly | 🟢 Low |
| write_file | WorkspaceWrite | 🟡 Medium |
| edit_file | WorkspaceWrite | 🟡 Medium |
| TodoWrite | WorkspaceWrite | 🟢 Low |
| NotebookEdit | WorkspaceWrite | 🟡 Medium |
| bash | DangerFullAccess | 🔴 High |
| PowerShell | DangerFullAccess | 🔴 High |
| REPL | DangerFullAccess | 🔴 High |
| Agent | DangerFullAccess | 🔴 High |
| Skill | ReadOnly | 🟢 Low |
| Config | WorkspaceWrite | 🟢 Low |

---

*Report generated by OpenClaw Security Review Skill*
