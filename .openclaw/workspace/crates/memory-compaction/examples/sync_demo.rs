//! Sync Pipeline Demo
//! 
//! Demonstrates automatic Obsidian sync with importance classification
//! Run with: cargo run --example sync_demo -- <obsidian_vault_path>

use std::path::PathBuf;
use memory_compaction::{
    SyncPipeline, SyncConfig, SyncMessage, Importance,
};

#[tokio::main]
async fn main() {
    // Get vault path from args or use default
    let vault_path: PathBuf = std::env::args()
        .nth(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            PathBuf::from("C:/Users/andre/Documents/Andrew Openclaw/Kimi_Agent_ECC-Second-Brain-Framework/SecondBrain")
        });

    println!("=== OpenClaw-ECC Sync Pipeline Demo ===\n");
    println!("Vault path: {:?}\n", vault_path);

    // Create pipeline with verbose config (syncs Reference and above)
    let pipeline = SyncPipeline::new(&vault_path)
        .with_config(SyncConfig::verbose());

    // Initialize (creates directories)
    println!("Initializing...");
    pipeline.initialize().await.expect("Failed to initialize");
    println!("✓ Ready\n");

    // Demo messages
    let messages = vec![
        SyncMessage::new("1", "user", "Hello, can you help me?"),
        SyncMessage::new("2", "assistant", "Hi! Sure, what do you need?"),
        SyncMessage::new("3", "user", "ok"),
        SyncMessage::new("4", "assistant", "Error: failed to connect to database"),
        SyncMessage::new("5", "user", "What's the solution?"),
        SyncMessage::new("6", "assistant", "Key insight: use connection pooling for better performance"),
        SyncMessage::new("7", "user", "thanks"),
        SyncMessage::new("8", "assistant", "Decision: we will use PostgreSQL with Redis cache"),
    ];

    println!("Processing {} messages...\n", messages.len());

    // Process all messages
    let result = pipeline.process_messages(&messages).await
        .expect("Failed to process messages");

    // Show results
    println!("\n=== Sync Results ===");
    println!("Timestamp: {}", result.timestamp.format("%Y-%m-%d %H:%M:%S"));
    println!("Entries synced: {}", result.entries_synced);
    println!("  - Critical: {}", result.entries_critical);
    println!("  - Important: {}", result.entries_important);

    if result.entries_synced > 0 {
        println!("\n✓ Successfully synced to Obsidian Inbox!");
        println!("  Location: {:?}", vault_path.join("Inbox"));
    } else {
        println!("\n○ No entries met the importance threshold");
    }

    println!("\n=== Classification Breakdown ===");
    for msg in &messages {
        use memory_compaction::MemoryClassifier;
        let classifier = MemoryClassifier::new();
        let importance = classifier.classify(&msg.role, &msg.content);
        
        let symbol = match importance {
            Importance::Critical => "🔴",
            Importance::Important => "🟡",
            Importance::Reference => "⚪",
            Importance::Trivial => "⚫",
        };
        
        let synced = if importance.priority() >= Importance::Reference.priority() {
            "✓"
        } else {
            "○"
        };
        
        println!("{} {} [{:?}] {}: {}", 
            synced, symbol, importance, msg.role, 
            &msg.content[..msg.content.len().min(40)]);
    }

    println!("\n=== Done ===");
}
