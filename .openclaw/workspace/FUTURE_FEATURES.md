# FUTURE FEATURES - OpenClaw-ECC Framework
## Nicht-kritische Erweiterungen für zukünftige Versionen

---

## 1. CLAW.md Discovery System ⏳ VORGEMERKT

**Status:** Nicht implementiert (nice-to-have)
**Priorität:** Niedrig
**Aufwand:** ~30-45 Minuten

### Beschreibung
Hierarchisches Instructions-System aus claw-code für kontext-abhängige Anweisungen.

### Use Cases
- Mehrere Projekte mit unterschiedlichen Standards
- Team-Entwicklung mit versionierbaren Regeln
- Monorepo-Strukturen (Frontend/Backend/Mobile)

### Implementierung (wenn benötigt)
```rust
// crates/context-assembly/src/discovery.rs

pub struct ClawDiscovery;

impl ClawDiscovery {
    pub fn discover_instruction_files(cwd: &Path) -> Vec<ContextFile> {
        let mut directories = Vec::new();
        let mut cursor = Some(cwd);
        
        // Traverse to root
        while let Some(dir) = cursor {
            directories.push(dir.to_path_buf());
            cursor = dir.parent();
        }
        
        // Root-to-leaf ordering
        directories.reverse();
        
        // Search patterns
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
        dedupe_instruction_files(files)
    }
}
```

### Dateien zu erstellen (wenn implementiert)
- `crates/context-assembly/src/lib.rs`
- `crates/context-assembly/src/discovery.rs`
- `crates/context-assembly/Cargo.toml`
- Tests: `crates/context-assembly/tests/discovery_tests.rs`

---

## 2. ERWEITERTE TOOL-INTEGRATION ⏳ OPTIONAL

**Status:** Teilweise implementiert
**Priorität:** Mittel

### 2.1 Bash Tool (teilweise implementiert)
- ✅ Existiert in `tool-registry/src/tools/bash.rs`
- ❌ Keine vollständige Integration mit Permission Framework
- ❌ Keine Process Isolation (Fort Knox Sandbox)

### 2.2 Web Fetch Tool
- ❌ Nicht implementiert
- Quelle: `claw-code/rust/crates/tools/src/web.rs`
- Features: HTTP GET/POST mit Retry, Header-Management

### 2.3 REPL Tools (Python, Node)
- ❌ Nicht implementiert
- Quelle: `claw-code/rust/crates/tools/src/repl.rs`
- Use Case: Code-Ausführung in isolierten Umgebungen

---

## 3. MCP SERVER MANAGER ⏳ ERWEITERT

**Status:** Grundlegend implementiert
**Priorität:** Mittel

### Implementiert ✅
- McpServerManager mit start/stop
- Stdio-basierte Kommunikation
- Tool-Liste vom Server abrufen

### Fehlend ❌
- **McpToolAdapter** für ToolExecutor Trait
- **Async Tool Execution** mit Timeout
- **Server Health Checks**
- **Auto-Restart** bei Crash
- **Multi-Server Orchestration**

### Code-Vorlage (wenn implementiert)
```rust
// crates/ecc-runtime/src/mcp_integration.rs

pub struct McpToolAdapter {
    manager: McpServerManager,
}

#[async_trait]
impl ToolExecutor for McpToolAdapter {
    async fn execute(&self, tool_call: &ToolCall) -> Result<ToolResult, ToolError> {
        // Parse server_name.tool_name format
        let (server, tool) = tool_call.name.split_once('.')
            .ok_or(ToolError::InvalidFormat)?;
        
        self.manager.execute_tool(server, tool, tool_call.arguments).await
            .map_err(|e| ToolError::Execution(e.to_string()))
    }
}
```

---

## 4. PLUGIN SYSTEM ⏳ NICHT IMPLEMENTIERT

**Status:** Nicht implementiert
**Priorität:** Niedrig
**Komplexität:** Hoch

### Beschreibung
Hook-basiertes Plugin-System aus claw-code für Erweiterungen.

### Hooks (aus claw-code)
```rust
pub enum Hook {
    PreToolExecution(fn(&ToolCall) -> Result<(), HookError>),
    PostToolExecution(fn(&ToolCall, &ToolResult)),
    PreApiRequest(fn(&mut ApiRequest)),
    PostApiResponse(fn(&ApiResponse)),
    OnCompaction(fn(&SessionSummary)),
}
```

### Use Cases
- Custom Logging
- Metrics/Monitoring
- Benutzerdefinierte Validierung
- Auto-Fixes

---

## 5. ERWEITERTE COMPACTION-STRATEGIEN ⏳ OPTIONAL

**Status:** Einfache Version implementiert
**Priorität:** Niedrig

### Implementiert ✅
- Token-basierte Trigger (10K Limit)
- Nachrichten-Anzahl (keep last 4)
- Einfacher Summarizer

### Fehlend ❌
- **LLM-basierte Zusammenfassung** (mit echte LLM-Integration)
- **Wichtigkeits-basierte Selektion** (nur Triviales entfernen)
- **Semantic Clustering** (ähnliche Nachrichten gruppieren)
- **Selective Compaction** (nur System/User, nicht Tool-Results)

---

## 6. CLI/REPL BINARY ⏳ NICHT IMPLEMENTIERT

**Status:** Nicht implementiert
**Priorität:** Niedrig

### Beschreibung
Standalone CLI-Tool für direkte Nutzung der Runtime.

### Features (aus claw-code/claw-cli)
- Interaktive REPL
- Slash Commands (/compact, /clear, /help)
- History/Persistence
- Config Management

### Nicht benötigt für OpenClaw
- OpenClaw nutzt Gateway-Architektur (keine CLI nötig)
- Integration über Sub-Agent Spawning

---

## 7. ERWEITERTE SICHERHEIT ⏳ TEILWEISE

**Status:** Grundlegend implementiert
**Priorität:** Mittel (für Autoresearch)

### Implementiert ✅
- Path Validation (FortKnoxGuard)
- URL Validation
- Command Pattern-Matching
- Risk Scoring

### Fehlend ❌
- **Process Isolation** (Docker/container für Bash)
- **Network Isolation** (Firewall-Regeln)
- **Filesystem Sandboxing** (chroot/bind mounts)
- **Resource Limits** (CPU/Memory Cgroups)

### Empfohlen für Autoresearch
```rust
pub struct SandboxConfig {
    pub container_image: String,      // "rust:1.75-slim"
    pub network_isolated: bool,       // true für Autoresearch
    pub filesystem_read_only: bool,   // true für Autoresearch
    pub max_memory_mb: u64,           // 512
    pub max_cpu_percent: u64,         // 50
    pub timeout_seconds: u64,         // 300
}
```

---

## 8. OBSERVABILITY & METRICS ⏳ NICHT IMPLEMENTIERT

**Status:** Nicht implementiert
**Priorität:** Niedrig

### Fehlend
- **Prometheus Metrics** (Token-Nutzung, Latenz, Fehlerraten)
- **Tracing/Spans** (OpenTelemetry Integration)
- **Performance Monitoring** (Tool-Ausführungszeiten)
- **Cost Tracking** (API-Kosten pro Session)

---

## PRIORISIERUNG

| Feature | Nutzen | Aufwand | Priorität |
|---------|--------|---------|-----------|
| MCP ToolAdapter | Hoch | Gering | 🔴 Hoch |
| Process Isolation | Hoch | Hoch | 🟡 Mittel |
| Web Fetch Tool | Mittel | Gering | 🟡 Mittel |
| CLAW.md Discovery | Niedrig | Mittel | 🟢 Niedrig |
| Plugin System | Niedrig | Hoch | 🟢 Niedrig |
| LLM Compaction | Mittel | Mittel | 🟡 Mittel |
| CLI Binary | Nicht benötigt | Mittel | ⚪ - |
| Observability | Niedrig | Mittel | 🟢 Niedrig |

---

## NÄCHSTE SCHRITTE (Empfohlen)

1. **MCP ToolAdapter** implementieren (15-20 Min)
2. **Web Fetch Tool** hinzufügen (10 Min)
3. **Process Isolation** für Autoresearch planen
4. Rest als Future-Features vormerken

---

*Erstellt: 2026-04-02*
*Letzte Aktualisierung: 2026-04-02*
