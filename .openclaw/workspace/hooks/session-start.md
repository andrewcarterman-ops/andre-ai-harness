# Hook: Session Start (Phase 1 - Manual Execution)
# Hook-ID: session:start
# Priorität: 100
# Async: false
# Status: ✅ IMPLEMENTIERT (Manuelle Ausführung)

## Beschreibung
Dieser Hook wird vom Agenten **manuell** am Beginn einer Session ausgeführt.
Er initialisiert den Kontext und bereitet die Session vor.

## Ausführung (Phase 1 - Manuell)

Der Agent führt diesen Hook zu Beginn jeder Session aus:

```rust
// Pseudocode für Agent-Implementierung
async fn on_session_start() {
    // 1. Registry validieren
    validate_registry_files()?;
    
    // 2. Session-Eintrag erstellen
    create_session_entry()?;
    
    // 3. Kontext laden
    load_soul_md()?;
    load_user_md()?;
    load_memory_md()?;
    
    // 4. Logging
    log_hook_event("session:start", "success")?;
}
```

## Aktionen

### 1. Registry Validierung ✅
```rust
fn validate_registry_files() -> Result<()> {
    assert!(exists("registry/agents.yaml"));
    assert!(exists("registry/skills.yaml"));
    assert!(exists("registry/hooks.yaml"));
    assert!(valid_yaml("registry/hooks.yaml"));
    Ok(())
}
```

### 2. Session-Eintrag erstellen ✅
```rust
fn create_session_entry() -> Result<()> {
    let session_id = generate_uuid();
    let entry = SessionEntry {
        id: session_id,
        start_time: now(),
        agent_id: "andrew-main",
        channel: detect_channel(),
    };
    write_yaml(format!("memory/sessions/{session_id}.yaml"), entry)?;
    Ok(())
}
```

### 3. Kontext laden ✅
```rust
fn load_context() -> Result<Context> {
    Ok(Context {
        soul: read_file("SOUL.md")?,
        user: read_file("USER.md")?,
        memory: read_file("MEMORY.md")?,
        today_log: read_file(format!("memory/{today}.md"))?, // optional
    })
}
```

### 4. Logging ✅
```rust
fn log_hook_event(hook_id: &str, status: &str) -> Result<()> {
    let log_entry = format!(
        "[{}] [{}] {}: Session started\n",
        now_iso8601(),
        hook_id,
        status
    );
    append_file("memory/hooks.log", log_entry)?;
    Ok(())
}
```

## Kontext (verfügbar nach Ausführung)

```yaml
session:
  id: "<uuid>"
  start_time: "2026-04-03T00:35:00+01:00"
  agent_id: "andrew-main"
  channel: "webchat"  # webchat, telegram, terminal, etc.
  
context:
  soul_loaded: true
  user_loaded: true
  memory_loaded: true
  
registry:
  agents_yaml: "valid"
  skills_yaml: "valid"
  hooks_yaml: "valid"
  
logging:
  hooks_log: "memory/hooks.log"
  session_log: "memory/sessions/{id}.yaml"
```

## Beispiel-Output

```
[SESSION START - Phase 1 Manual]
Agent: Andrew (andrew-main)
Channel: webchat
Time: 2026-04-03 00:35:00 CET
Session ID: 550e8400-e29b-41d4-a716-446655440000

Registry Check:
  agents.yaml: ✅ OK
  skills.yaml: ✅ OK
  hooks.yaml: ✅ OK

Context Loaded:
  SOUL.md: ✅ (1.2 KB)
  USER.md: ✅ (0.4 KB)
  MEMORY.md: ✅ (8.7 KB)

Hook logged to: memory/hooks.log
Session entry: memory/sessions/550e8400-e29b-41d4-a716-446655440000.yaml
```

## Implementierungs-Status

| Komponente | Status | Datei |
|------------|--------|-------|
| Hook-Definition | ✅ | `registry/hooks.yaml` |
| Hook-Template | ✅ | `hooks/session-start.md` (diese Datei) |
| Registry-Validierung | ✅ | Agent implementiert |
| Session-Erstellung | ✅ | Agent implementiert |
| Kontext-Laden | ✅ | Agent implementiert (`AGENTS.md`) |
| Logging | ✅ | Agent implementiert |
| Hook-Engine (Auto) | 🔄 | Phase 2 geplant |

## Phase 2 (Geplant)

Wenn die Hook-Engine implementiert ist:

```rust
// Statt manueller Ausführung:
// Hook-Engine fängt "session:start" Event ab
// und führt Hook automatisch aus

engine.on_event("session:start", |ctx| {
    execute_hook("session:start", ctx)?;
});
```

## Manuelle Ausführung (für Debugging)

```bash
# Direkte Ausführung des Hooks
openclaw hook:trigger session:start

# Oder via Agent:
# "Führe session:start Hook aus"
```

## Fehlerbehandlung

| Fehler | Aktion | Fallback |
|--------|--------|----------|
| Registry-Datei fehlt | Log Warning | Session ohne Registry-Check fortsetzen |
| YAML ungültig | Log Error | Session mit Default-Werten fortsetzen |
| Kontext-Datei fehlt | Log Warning | Session mit leerem Kontext fortsetzen |
| Log-File nicht schreibbar | Log Warning | Session ohne Logging fortsetzen |

---

**Version:** 1.2 (Phase 1)  
**Ausführung:** Manual (Agent-gesteuert)  
**Phase 2:** Automatisch via Hook-Engine geplant  
**Architektur:** Siehe `docs/adr/003-hook-execution-model.md`
