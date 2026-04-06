# Demo: CompactionEngine in Aktion

## Simulierte Session (vor Compaction)

```
[Message 1] user: "Hallo, ich brauche Hilfe beim Setup"
[Message 2] assistant: "Hi! Womit kann ich helfen?"
[Message 3] user: "Ich will claw-code integrieren"
[Message 4] assistant: "Gerne! Ich schaue mir die MD-Dateien an..."
[Message 5] user: "Starte mit SSE Streaming"
[Message 6] assistant: "Ok, erstelle skills/secure-api-client/..."
[Message 7] user: "Weiter mit Permissions"
[Message 8] assistant: "Erstelle security-review mit risk_analyzer..."
[Message 9] user: "Und Runtime?"
[Message 10] assistant: "ecc-runtime mit safety.rs und memory_bridge..."
[Message 11] user: "Nun Compaction"
[Message 12] assistant: "Erstelle memory-compaction Crate..."
[Message 13] user: "Perfekt! Tests?"
[Message 14] assistant: "Füge alle Test-Dateien hinzu..."
[Message 15] user: "Und Tool Registry?"
[Message 16] assistant: "Beginne mit tool-registry..."
```

## CompactionEngine Config
- max_estimated_tokens: 10_000
- preserve_recent: 4

## Ergebnis der Compaction

### Zusammenfassung (Messages 1-12):
```
[SYSTEM - Compacted Summary]
User initiierte Integration von claw-code in OpenClaw-ECC Framework. 
Implementierte TIER 1 Komponenten: SSE Streaming (secure-api-client), 
Permissions (security-review mit risk_analyzer), Conversation Runtime 
(ecc-runtime mit safety/memory_bridge), Session Compaction (memory-compaction). 
Alle Module mit Tests. Begann TIER 2 mit Tool Registry.
```

### Behaltene Nachrichten (letzte 4):
```
[Message 13] user: "Perfekt! Tests?"
[Message 14] assistant: "Füge alle Test-Dateien hinzu..."
[Message 15] user: "Und Tool Registry?"
[Message 16] assistant: "Beginne mit tool-registry..."
```

## Statistik
- Original: 16 Nachrichten
- Compacted: 1 Summary + 4 Nachrichten = 5 Einträge
- Reduktion: 69% weniger Token
- Kritische Inhalte: Alle Features implementiert
- Wichtige Entscheidungen: Chronologischer Ablauf bewahrt
```

---

## Tatsächliche Umsetzung in Code:

```rust
use memory_compaction::{
    CompactionEngine, CompactionConfig, SimpleSummarizer, MessageSummary
};

#[tokio::main]
async fn main() {
    let config = CompactionConfig::with_settings(100, 4);
    let engine = CompactionEngine::new(config, SimpleSummarizer);
    
    let messages = vec![
        MessageSummary::new("user", "Hallo, ich brauche Hilfe..."),
        MessageSummary::new("assistant", "Hi! Womit kann ich helfen?"),
        // ... weitere Nachrichten ...
    ];
    
    let result = engine.compact(&messages).await.unwrap();
    
    match result {
        CompactionResult::Compacted { messages_removed, summary } => {
            println!("Zusammengefasst: {} Nachrichten", messages_removed);
            println!("Summary: {}", summary);
        }
        _ => println!("Keine Kompaktierung nötig"),
    }
}
```
