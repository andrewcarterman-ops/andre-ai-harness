# Harness Redesign Integration in OpenClaw

## Ziel
Integration des Harness Redesigns (3-Tier Context, Token Budget, Edit Tool Fix) in das bestehende OpenClaw-System.

---

## Analyse: Aktueller Stand

### Was existiert bereits

| Komponente | Status | Ort |
|------------|--------|-----|
| Harness Redesign Code | ✅ Vollständig | `~/Documents/Andrew Openclaw/harness-redesign/` |
| OpenClaw Gateway | ✅ Läuft | `~/.openclaw/workspace/` |
| Rust Tool Registry | ✅ Implementiert | `~/.openclaw/workspace/crates/tool-registry/` |
| Session Management | ✅ Funktioniert | `registry/hooks.yaml` |

### Was fehlt für Integration

1. **Bridge zwischen Harness-TS und OpenClaw-Rust**
2. **Token Budget Integration in Session-Handling**
3. **Edit Tool Fix in Tool Registry**
4. **Konfigurations-Migration**

---

## Integrations-Strategie

### Option A: Rust-Native Integration (Empfohlen)
**Ansatz:** Harness-Logik in Rust übersetzen, direkt in `ecc-runtime` integrieren

**Vorteile:**
- Native Performance
- Keine Node.js Dependencies
- Konsistent mit bestehendem Rust-Code

**Nachteile:**
- Mehr Entwicklungsaufwand
- TypeScript-Code muss portiert werden

### Option B: Node.js Bridge (Schneller)
**Ansatz:** Harness als separate Node.js-App, Kommunikation via IPC/API

**Vorteile:**
- Wiederverwendung bestehenden Codes
- Schnellere Implementierung

**Nachteile:**
- Zusätzlicher Prozess-Overhead
- Komplexere Deployment

### Option C: Hybrid (Pragmatisch)
**Ansatz:** Kritische Komponenten in Rust, restliche Logik in TypeScript

**Vorteile:**
- Balance zwischen Performance und Entwicklungsgeschwindigkeit
- Inkrementelle Migration möglich

---

## Empfohlene Integration (Option C - Hybrid)

### Phase 1: Token Budget Manager (Rust)

**Ziel:** Token-Verwaltung direkt in `ecc-runtime` integrieren

**Schritte:**
1. **Rust-Modul erstellen:**
   ```
   crates/ecc-runtime/src/context/
   ├── mod.rs
   ├── token_budget.rs      # TokenBudgetManager Port
   ├── tier_manager.rs      # ContextTierManager Port
   └── types.rs             # ContextItem, Tier, etc.
   ```

2. **Session-Integration:**
   ```rust
   // In ecc-runtime/src/session/mod.rs
   pub struct Session {
       id: String,
       token_budget: TokenBudgetManager,  // NEU
       context_tiers: ContextTierManager, // NEU
       // ... existing fields
   }
   ```

3. **Hook-Integration:**
   ```yaml
   # registry/hooks.yaml
   hooks:
     session:start:
       actions:
         - name: "initialize_token_budget"
           description: "Initialize 3-tier token system"
         - name: "load_hot_context"
           description: "Load SOUL.md, USER.md, MEMORY.md into Hot tier"
   ```

**Zeitaufwand:** 2-3 Tage

---

### Phase 2: Edit Tool Fix (Rust)

**Ziel:** Splice-Bug im bestehenden `edit_file` Tool beheben

**Schritte:**
1. **Aktuellen Code analysieren:**
   ```bash
   cat crates/tool-registry/src/tools/file_ops.rs
   ```

2. **Fix implementieren:**
   ```rust
   // Korrekte String-Indexierung
   let before = &content[..index];
   let after = &content[index + old_string.len()..];
   let new_content = format!("{}{}{}", before, new_string, after);
   ```

3. **Tests hinzufügen:**
   - Multiple occurrences
   - Unicode characters
   - Large files

**Zeitaufwand:** 1 Tag

---

### Phase 3: Knowledge Store Bridge (TypeScript + Rust)

**Ziel:** ChromaDB-Integration für semantische Suche

**Schritte:**
1. **ChromaDB-Service:**
   ```yaml
   # docker-compose.yml
   services:
     chroma:
       image: chromadb/chroma:latest
       ports:
         - "8000:8000"
   ```

2. **Rust-Client:**
   ```rust
   // crates/ecc-runtime/src/knowledge/chroma_client.rs
   pub struct ChromaClient {
       base_url: String,
       collection: String,
   }
   ```

3. **Integration in Sessions:**
   - Automatische Indizierung wichtiger Dateien
   - Semantische Suche bei Context-Ladung

**Zeitaufwand:** 3-4 Tage

---

### Phase 4: Obsidian Bridge (TypeScript)

**Ziel:** Bidirektionale Synchronisation mit Obsidian

**Schritte:**
1. **Existierenden Code nutzen:**
   ```
   harness-redesign/src/bridge/ObsidianBridge.ts
   ```

2. **Integration in Session-End Hook:**
   ```typescript
   // hooks/session-end.ts
   import { ObsidianBridge } from '../bridge/ObsidianBridge';
   
   export async function onSessionEnd(session) {
       if (session.duration_minutes > 10) {
           await ObsidianBridge.sync(session);
       }
   }
   ```

3. **Cron-Job für Sync:**
   ```bash
   openclaw cron add --name "obsidian-sync" --interval 5m
   ```

**Zeitaufwand:** 2 Tage

---

### Phase 5: Parallel Orchestrator (Optional)

**Ziel:** Parallele Tool-Ausführung

**Schritte:**
1. **Rust-Implementierung:**
   ```rust
   // crates/ecc-runtime/src/execution/orchestrator.rs
   use tokio::task::JoinSet;
   
   pub struct ParallelOrchestrator {
       workers: usize,
       task_queue: PriorityQueue<Task>,
   }
   ```

2. **Integration in Tool-Execution:**
   - Unabhängige Tools parallel ausführen
   - Dependencies auflösen

**Zeitaufwand:** 3-4 Tage (Optional)

---

## Konfigurations-Migration

### Neue Config-Dateien

```yaml
# ~/.openclaw/workspace/config/token_budget.yaml
token_budget:
  total_limit: 12000
  tiers:
    hot:
      max_tokens: 2000
      eviction_policy: lru
    warm:
      max_tokens: 10000
      eviction_policy: relevance_score
    cold:
      max_tokens: null
      eviction_policy: archive

  allocation:
    system_prompt: 1000
    context: 8000
    conversation_history: 2000
    response_buffer: 1000

obsidian_bridge:
  enabled: true
  vault_path: "~/Documents/Andrew Openclaw/Obsidian"
  sync_interval: 300

knowledge_store:
  provider: chromadb
  url: "http://localhost:8000"
  collection: "openclaw-knowledge"
```

---

## Test-Strategie

### Integration Tests

```bash
# 1. Token Budget Tests
cargo test -p ecc-runtime token_budget

# 2. Edit Tool Tests
cargo test -p tool-registry edit_file

# 3. End-to-End Tests
./scripts/test-harness-integration.sh
```

### Manuelle Tests

1. **Session-Start:**
   - SOUL.md, USER.md, MEMORY.md in Hot Tier?
   - Token-Tracking aktiv?

2. **Edit Operation:**
   - `edit` Tool funktioniert korrekt?
   - Keine Workarounds nötig?

3. **Obsidian Sync:**
   - Änderungen erscheinen in Obsidian?
   - Bidirektionale Sync funktioniert?

---

## Zeitplan

| Phase | Komponente | Dauer | Kumulativ |
|-------|------------|-------|-----------|
| 1 | Token Budget Manager | 2-3 Tage | 2-3 Tage |
| 2 | Edit Tool Fix | 1 Tag | 3-4 Tage |
| 3 | Knowledge Store | 3-4 Tage | 6-8 Tage |
| 4 | Obsidian Bridge | 2 Tage | 8-10 Tage |
| 5 | Parallel Orchestrator | 3-4 Tage | 11-14 Tage |

**Gesamt:** 2-3 Wochen für vollständige Integration

**MVP (Minimum Viable Product):** Phasen 1+2 = 3-4 Tage

---

## Nächste Schritte

### Sofort (Heute)
1. ✅ Harness Redesign Implementierung verifiziert
2. ✅ Tests bestanden
3. 🔄 Integrationsplan erstellt

### Diese Woche
1. Phase 1 starten: Token Budget Manager in Rust
2. OpenClaw Gateway Konfiguration anpassen
3. Erste Integration-Tests schreiben

### Entscheidung benötigt

**Welche Option bevorzugst du?**

- **A) Rust-Native** - Beste Performance, mehr Aufwand
- **B) Node.js Bridge** - Schneller, aber Overhead
- **C) Hybrid** - Balance, empfohlen

**Und welcher Scope?**

- **MVP** - Nur Token Budget + Edit Tool Fix (3-4 Tage)
- **Vollständig** - Alle 5 Phasen (2-3 Wochen)
- **Custom** - Du wählst die Phasen

Sag mir deine Präferenz, dann starte ich mit der Implementierung.
