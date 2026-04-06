# Hook Execution Model - Architecture Decision

**Datum:** 2026-04-03  
**Status:** DECIDED - Manual Execution (Phase 2: Automatic)  
**Entscheidung:** Phase 1 = Manuelle Ausführung, Phase 2 = Automatische Integration

---

## Ausgangslage

Die Hooks sind in `registry/hooks.yaml` definiert und in `hooks/*.md` dokumentiert. Die Hook-Engine wurde für Phase 2 geplant, ist aber noch nicht implementiert.

**Verfügbare Hooks:**
- `session:start` - Wird bei Session-Start ausgeführt
- `session:end` - Wird bei Session-Ende ausgeführt (+ Post-Action: Second Brain Sync)
- `review:post_execution` - Nach kritischen Operationen

**Geplante Hooks (auskommentiert):**
- `message:pre` / `message:post` - Vor/Nach Nachrichtenverarbeitung
- `error:critical` - Bei kritischen Fehlern

---

## Entscheidung: Zwei-Phasen-Ansatz

### Phase 1 (AKTUELL): Manuelle Hook-Ausführung

**Begründung:**
- Hook-Engine nicht implementiert
- Sofortige Nutzbarkeit ohne weitere Entwicklung
- Einfache Integration in bestehende Workflows

**Implementierung:**
- Hooks werden durch **explizite Tool-Aufrufe** ausgeführt
- Agent prüft zu Beginn/Ende einer Session ob Hooks ausgeführt werden sollen
- Hook-Logik in Skills ausgelagert (`skills/hook-executor/`)

**Workflow:**
```
1. Session Start → Agent liest hooks.yaml
2. Agent prüft: Ist session:start enabled?
3. Ja → Agent führt Hook-Logik manuell aus
4. Session Ende → Gleiches für session:end
```

### Phase 2 (GEPLANT): Automatische Hook-Engine

**Begründung:**
- Vollständige Automation
- Konsistente Ausführung über alle Sessions
- Weniger Boilerplate für Agent-Entwickler

**Implementierung:**
- Hook-Engine als Rust-Modul in `crates/ecc-runtime/`
- Event-Driven Architektur
- Async Ausführung mit Priority-Queue

**Workflow:**
```
1. Session Start → Hook-Engine fängt Event ab
2. Engine sucht passende Hooks (session:start)
3. Engine führt Hooks in Prioritätsreihenfolge aus
4. Session Ende → Gleiches für session:end
```

---

## Vergleich: Manual vs Automatic

| Aspekt | Manual (Phase 1) | Automatic (Phase 2) |
|--------|------------------|---------------------|
| **Implementierungsaufwand** | Gering (sofort) | Hoch (1-2 Tage) |
| **Flexibilität** | Hoch (Agent entscheidet) | Niedrig (Engine entscheidet) |
| **Konsistenz** | Variiert je nach Agent | Einheitlich |
| **Debugging** | Einfach (sichtbar im Code) | Komplexer (Engine-Logik) |
| **Überkopplung** | Niedrig | Möglich (falsche Trigger) |

---

## Konkrete Implementierung Phase 1

### Hook-Executor Skill

```yaml
# skills/hook-executor/SKILL.md
name: hook-executor
triggers: ["hook", "execute hook", "run hook"]
```

### Manuelle Ausführung in Sessions

```rust
// Pseudocode für Agent-Implementierung
impl Agent {
    async fn on_session_start(&mut self) {
        // Lade Hook-Registry
        let hooks = load_hooks_yaml();
        
        // Prüfe session:start Hook
        if let Some(hook) = hooks.get("session:start") {
            if hook.enabled {
                self.execute_hook(hook).await;
            }
        }
        
        // Normale Session-Logik
        self.load_context();
    }
    
    async fn on_session_end(&mut self) {
        // Prüfe session:end Hook
        if let Some(hook) = hooks.get("session:end") {
            if hook.enabled {
                self.execute_hook(hook).await;
                
                // Führe Post-Actions aus
                for action in &hook.post_actions {
                    if self.evaluate_condition(&action.condition) {
                        self.execute_post_action(action).await;
                    }
                }
            }
        }
    }
}
```

### Session-Start Hook Logik

```rust
// Was session:start tatsächlich macht:
1. Registry-Dateien validieren (agents.yaml, skills.yaml, hooks.yaml)
2. Session-Eintrag in memory/sessions/{id}.yaml erstellen
3. Kontext laden (SOUL.md, USER.md, MEMORY.md)
4. Hook-Event loggen (memory/hooks.log)
```

### Session-End Hook Logik

```rust
// Was session:end tatsächlich macht:
1. Session-Metadaten aktualisieren (duration, message_count)
2. Second Brain Sync (falls duration > 10min)
3. Tägliche Logs schreiben (memory/YYYY-MM-DD.md)
4. Hook-Event loggen
5. Cleanup temporärer Dateien
```

---

## Konfiguration

### hooks.yaml (bestehend)

```yaml
hooks:
  session:start:
    enabled: true        # Aktiviert für manuelle Ausführung
    priority: 100
    async: false
    
  session:end:
    enabled: true
    priority: 100
    async: false
    post_actions:
      - name: "sync-second-brain"
        command: "..."
        condition: "session.duration_minutes > 10"
        enabled: true      # Post-Action aktiv
```

### Agent-Konfiguration

```yaml
# In agents.yaml pro Agent
hook_execution:
  mode: "manual"         # "manual" (Phase 1) oder "automatic" (Phase 2)
  enabled_hooks:
    - session:start
    - session:end
  skip_hooks: []         # Liste zu überspringender Hooks
```

---

## Migration nach Phase 2

Wenn die Hook-Engine implementiert ist:

1. **Engine implementieren** in `crates/ecc-runtime/src/hooks/`
2. **Agents aktualisieren** - `hook_execution.mode` auf "automatic" setzen
3. **Manuelle Logik entfernen** aus Agent-Implementierungen
4. **Backward Compatibility** - Manuelle Ausführung weiterhin möglich

---

## Offene Fragen (für Phase 2)

1. **Soll session:end bei Absturz ausgeführt werden?**
   - Ja: Cleanup wichtig
   - Nein: Könnte zu Dateninkonsistenzen führen

2. **Was passiert bei Hook-Fehlern?**
   - `fail_on_error: false` (aktuell) → Loggen und weitermachen
   - Alternative: Session abbrechen

3. **Sind async Hooks notwendig?**
   - Aktuell alle `async: false`
   - Use-Case für `async: true`?

---

## Zusammenfassung

| Phase | Zeitraum | Modus | Status |
|-------|----------|-------|--------|
| Phase 1 | Jetzt | **Manuell** | ✅ Implementiert |
| Phase 2 | Später | Automatisch | 🔄 Geplant |

**Empfehlung für aktuelle Sessions:**
- Agent führt Hooks manuell aus
- Prüfung am Session-Start/Ende
- Logging für Debugging

---

**Autor:** Andrew  
**Datum:** 2026-04-03  
**Tags:** #hooks #architecture #decision #phase1 #phase2
