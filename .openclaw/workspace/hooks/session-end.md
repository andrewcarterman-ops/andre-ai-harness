# Hook: Session End (Phase 1 - Manual Execution)
# Hook-ID: session:end
# Priorität: 100
# Async: false
# Status: ✅ IMPLEMENTIERT (Manuelle Ausführung)

## Beschreibung
Dieser Hook wird vom Agenten **manuell** am Ende einer Session ausgeführt.
Er speichert Session-Daten, synchronisiert mit Second Brain und räumt auf.

## Ausführung (Phase 1 - Manuell)

Der Agent führt diesen Hook am Ende jeder Session aus:

```rust
// Pseudocode für Agent-Implementierung
async fn on_session_end() {
    // 1. Session-Metadaten aktualisieren
    update_session_metadata()?;
    
    // 2. Tägliches Log schreiben
    write_daily_log()?;
    
    // 3. Second Brain Sync (falls Bedingung erfüllt)
    if session.duration_minutes > 10 {
        sync_second_brain()?;
    }
    
    // 4. Cleanup
    cleanup_temp_files()?;
    
    // 5. Logging
    log_hook_event("session:end", "success")?;
}
```

## Aktionen

### 1. Session-Metadaten aktualisieren ✅
```rust
fn update_session_metadata() -> Result<()> {
    let session = load_session(session_id)?;
    let updated = SessionEntry {
        end_time: now(),
        duration_seconds: now() - session.start_time,
        message_count: count_messages(),
        files_modified: get_modified_files(),
        skills_used: get_skills_used(),
        ..session
    };
    write_yaml(format!("memory/sessions/{session_id}.yaml"), updated)?;
    Ok(())
}
```

### 2. Tägliches Log schreiben ✅
```rust
fn write_daily_log() -> Result<()> {
    let today = today_iso8601(); // 2026-04-03
    let log_entry = format!(
        "## Session {session_id}\n\n- Start: {start}\n- End: {end}\n- Duration: {duration}\n- Messages: {count}\n- Skills: {skills:?}\n\n"
    );
    append_file(format!("memory/{today}.md"), log_entry)?;
    Ok(())
}
```

### 3. Second Brain Sync (Post-Action) ✅
```rust
fn sync_second_brain() -> Result<()> {
    // Bedingung: session.duration_minutes > 10
    if session.duration_minutes <= 10 {
        log("Skipping Second Brain sync (session too short)");
        return Ok(());
    }
    
    // Führe Sync-Script aus
    execute("second-brain/scripts/sync-openclaw-to-secondbrain.ps1")?;
    Ok(())
}
```

### 4. Cleanup ✅
```rust
fn cleanup_temp_files() -> Result<()> {
    // Lösche temporäre Dateien im workspace/
    // Behalte: MEMORY.md, registry/, skills/, agents/
    // Lösche: *.tmp, cache/, temp_sessions/
    remove_temp_files("workspace/*.tmp")?;
    Ok(())
}
```

### 5. Logging ✅
```rust
fn log_hook_event(hook_id: &str, status: &str) -> Result<()> {
    let log_entry = format!(
        "[{}] [{}] {}: Session ended (duration: {}m, messages: {})\n",
        now_iso8601(),
        hook_id,
        status,
        session.duration_minutes,
        session.message_count
    );
    append_file("memory/hooks.log", log_entry)?;
    Ok(())
}
```

## Kontext (verfügbar bei Ausführung)

```yaml
session:
  id: "550e8400-e29b-41d4-a716-446655440000"
  start_time: "2026-04-03T00:35:00+01:00"
  end_time: "2026-04-03T01:15:30+01:00"
  duration_seconds: 2430
  duration_minutes: 40.5
  message_count: 28
  agent_id: "andrew-main"
  channel: "webchat"
  
session_summary:
  skills_used:
    - secure-api-client
    - self-improving-andrew
  files_modified:
    - crates/tool-registry/src/tools/file_ops.rs
    - registry/hooks.yaml
    - MEMORY.md
  commands_executed: 5
  
post_actions:
  sync-second-brain:
    condition: "session.duration_minutes > 10"
    condition_met: true  # 40.5 > 10
    executed: true
    status: "success"
```

## Beispiel-Output

```
[SESSION END - Phase 1 Manual]
Agent: Andrew (andrew-main)
Session ID: 550e8400-e29b-41d4-a716-446655440000
Start: 2026-04-03 00:35:00 CET
End: 2026-04-03 01:15:30 CET
Duration: 40m 30s
Messages: 28

Skills used:
  - secure-api-client
  - self-improving-andrew

Files modified:
  - crates/tool-registry/src/tools/file_ops.rs
  - registry/hooks.yaml
  - MEMORY.md

Post-Actions:
  sync-second-brain:
    Condition: session.duration_minutes > 10
    Condition met: 40.5 > 10 = true ✅
    Status: ✅ SUCCESS
    Output: Synced 3 files to Second Brain

Cleanup:
  Temp files removed: 2
  Cache cleared: ✅

Logging:
  Session log: memory/sessions/550e8400-e29b-41d4-a716-446655440000.yaml
  Daily log: memory/2026-04-03.md
  Hook log: memory/hooks.log
```

## Implementierungs-Status

| Komponente | Status | Datei |
|------------|--------|-------|
| Hook-Definition | ✅ | `registry/hooks.yaml` |
| Hook-Template | ✅ | `hooks/session-end.md` (diese Datei) |
| Metadata-Update | ✅ | Agent implementiert |
| Daily Log | ✅ | Agent implementiert |
| Second Brain Sync | ✅ | Script vorhanden, Agent ruft auf |
| Cleanup | ✅ | Agent implementiert |
| Logging | ✅ | Agent implementiert |
| Hook-Engine (Auto) | 🔄 | Phase 2 geplant |

## Phase 2 (Geplant)

Wenn die Hook-Engine implementiert ist:

```rust
// Statt manueller Ausführung:
// Hook-Engine fängt "session:end" Event ab
// und führt Hook automatisch aus

engine.on_event("session:end", |ctx| {
    execute_hook("session:end", ctx)?;
    
    // Führe Post-Actions aus
    for action in ctx.hook.post_actions {
        if evaluate_condition(&action.condition, ctx) {
            execute_post_action(&action)?;
        }
    }
});
```

## Post-Actions

### sync-second-brain

```yaml
post_action:
  name: "sync-second-brain"
  command: "second-brain/scripts/sync-openclaw-to-secondbrain.ps1"
  condition: "session.duration_minutes > 10"
  enabled: true
  phase: 1  # In Phase 1 implementiert
```

**Bedingungs-Evaluation:**
```rust
fn evaluate_condition(condition: &str, ctx: &Context) -> bool {
    match condition {
        "session.duration_minutes > 10" => ctx.session.duration_minutes > 10,
        "session.message_count > 5" => ctx.session.message_count > 5,
        _ => true, // Default: ausführen
    }
}
```

## Manuelle Ausführung (für Debugging)

```bash
# Direkte Ausführung des Hooks
openclaw hook:trigger session:end

# Oder via Agent:
# "Führe session:end Hook aus"
```

## Fehlerbehandlung

| Fehler | Aktion | Fallback |
|--------|--------|----------|
| Session-Datei nicht gefunden | Log Error | Neue Session-Datei erstellen |
| Daily Log nicht schreibbar | Log Warning | Ohne Daily Log fortfahren |
| Second Brain Sync fehlgeschlagen | Log Error | Ohne Sync beenden |
| Cleanup fehlgeschlagen | Log Warning | Ohne Cleanup beenden |
| Hook-Log nicht schreibbar | Log Warning | Ohne Logging beenden |

## Cleanup-Checkliste

- [ ] Temporäre Dateien (*.tmp) entfernt
- [ ] Cache-Verzeichnis geleert
- [ ] Session-Lock freigegeben (falls vorhanden)
- [ ] Offene Datei-Handles geschlossen
- [ ] Second Brain Sync durchgeführt (falls Bedingung erfüllt)
- [ ] Daily Log geschrieben
- [ ] Session-Metadaten aktualisiert
- [ ] Hook-Event geloggt

---

**Version:** 1.2 (Phase 1)  
**Ausführung:** Manual (Agent-gesteuert)  
**Phase 2:** Automatisch via Hook-Engine geplant  
**Architektur:** Siehe `docs/adr/003-hook-execution-model.md`
