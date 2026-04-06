//! CompactionEngine Example
//! 
//! Demonstrates token-based session compaction with summary generation
//! 
//! Usage: cargo run --example compaction_demo

use memory_compaction::{
    CompactionEngine, CompactionConfig, SimpleSummarizer,
    MessageSummary, CompactionResult, Importance, MemoryClassifier
};

#[tokio::main]
async fn main() {
    println!("╔══════════════════════════════════════════════════════════╗");
    println!("║     CompactionEngine Demo - Session Compaction           ║");
    println!("╚══════════════════════════════════════════════════════════╝\n");

    // 1. Erstelle eine simulierte Session mit vielen Nachrichten
    println!("📋 Simuliere Session mit 20 Nachrichten...\n");
    
    let messages = create_sample_session();
    
    // 2. Zeige vorherigen Zustand
    println!("VOR Compaction:");
    println!("  Anzahl Nachrichten: {}", messages.len());
    println!("  Geschätzte Tokens: ~{}", estimate_tokens(&messages));
    println!();
    
    // 3. CompactionEngine erstellen (niedriger Threshold für Demo)
    let config = CompactionConfig::with_settings(50, 4); // 50 Tokens, 4 preserve
    let engine = CompactionEngine::new(config, SimpleSummarizer);
    
    // 4. Prüfen ob Compaction nötig
    println!("🔍 Prüfe ob Compaction nötig...");
    if !engine.needs_compaction(&messages) {
        println!("  ❌ Keine Compaction nötig");
        return;
    }
    println!("  ✅ Compaction wird benötigt!\n");
    
    // 5. Compaction ausführen
    println!("🔄 Führe Compaction aus...\n");
    
    match engine.compact(&messages).await {
        Ok(result) => {
            match result {
                CompactionResult::NotNeeded => {
                    println!("  ℹ️  Keine Compaction nötig");
                }
                CompactionResult::NothingToCompact => {
                    println!("  ℹ️  Nicht genug Nachrichten zum Kompaktifizieren");
                }
                CompactionResult::Compacted { messages_removed, summary } => {
                    println!("✅ Compaction erfolgreich!");
                    println!("   Entfernte Nachrichten: {}", messages_removed);
                    println!("   Behaltene Nachrichten: {}", 4); // preserve_recent
                    println!("   Reduktion: {:.0}%\n", 
                        (messages_removed as f64 / messages.len() as f64) * 100.0);
                    
                    println!("📄 Generierte Zusammenfassung:");
                    println!("   {}\n", summary);
                    
                    // 6. Zeige neue Session-Struktur
                    println!("📊 NEUE Session-Struktur:");
                    println!("   [1] System-Message (Summary)");
                    for i in 0..4 {
                        let idx = messages.len() - 4 + i;
                        println!("   [{}] {}: {}", 
                            i + 2, 
                            messages[idx].role,
                            &messages[idx].content[..messages[idx].content.len().min(40)]
                        );
                    }
                    println!();
                    
                    // 7. Zeige Token-Einsparung
                    let new_token_count = summary.len() / 4 + 
                        messages.iter().skip(messages.len() - 4)
                            .map(|m| m.content.len() / 4)
                            .sum::<usize>();
                    let old_token_count = estimate_tokens(&messages);
                    
                    println!("💾 Token-Einsparung:");
                    println!("   Vorher: ~{} Tokens", old_token_count);
                    println!("   Nachher: ~{} Tokens", new_token_count);
                    println!("   Gespart: ~{} Tokens ({:.0}%)", 
                        old_token_count - new_token_count,
                        ((old_token_count - new_token_count) as f64 / old_token_count as f64) * 100.0
                    );
                }
            }
        }
        Err(e) => {
            eprintln!("❌ Fehler bei Compaction: {}", e);
        }
    }
    
    // 8. Zeige Wichtigkeits-Klassifizierung
    println!("\n📊 Wichtigkeits-Analyse der Nachrichten:");
    let classifier = MemoryClassifier::new();
    
    for (i, msg) in messages.iter().enumerate() {
        let importance = classifier.classify(&msg.role, &msg.content);
        let symbol = match importance {
            Importance::Critical => "🔴",
            Importance::Important => "🟡",
            Importance::Reference => "⚪",
            Importance::Trivial => "⚫",
        };
        
        println!("   {} [{:?}] Message {}: {}", 
            symbol, 
            importance, 
            i + 1,
            &msg.content[..msg.content.len().min(35)]
        );
    }
}

/// Erstellt eine Beispiel-Session
fn create_sample_session() -> Vec<MessageSummary> {
    vec![
        MessageSummary::new("user", "Hallo, kannst du mir helfen?"),
        MessageSummary::new("assistant", "Hi! Natürlich, womit brauchst du Hilfe?"),
        MessageSummary::new("user", "Ich möchte ein Rust-Projekt aufsetzen"),
        MessageSummary::new("assistant", "Gerne! Erstelle ein neues Projekt mit cargo new..."),
        MessageSummary::new("user", "ok"),
        MessageSummary::new("assistant", "Super! Als nächstes fügen wir Dependencies hinzu..."),
        MessageSummary::new("user", "Welche Crates empfiehlst du?"),
        MessageSummary::new("assistant", "Für Async: tokio, für Serialization: serde..."),
        MessageSummary::new("user", "Alles klar"),
        MessageSummary::new("assistant", "Key insight: Verwende immer anyhow für Error Handling!"),
        MessageSummary::new("user", "Guter Tipp, danke!"),
        MessageSummary::new("assistant", "Decision: Wir werden tokio mit full features verwenden."),
        MessageSummary::new("user", "Error: cargo build schlägt fehl"),
        MessageSummary::new("assistant", "Schauen wir uns die Fehlermeldung an..."),
        MessageSummary::new("user", "Solution gefunden, es fehlte ein Feature-Flag"),
        MessageSummary::new("assistant", "Perfekt! Fixed: dependency mit richtigem Feature-Flag."),
        MessageSummary::new("user", "Jetzt compiliert es!"),
        MessageSummary::new("assistant", "Lesson learned: Immer --features prüfen bei tokio."),
        MessageSummary::new("user", "thanks"),
        MessageSummary::new("assistant", "Gerne! Viel Erfolg mit dem Projekt!"),
    ]
}

/// Schätzt Token-Anzahl (naive Berechnung)
fn estimate_tokens(messages: &[MessageSummary]) -> usize {
    messages.iter()
        .map(|m| m.content.len() / 4)
        .sum()
}
