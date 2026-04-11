---
date: 01-04-2026
type: reference
category: openclaw
source: "vault-archive/Kimi_Agent_OpenClaw GitHub/"
tags: [reference, openclaw, subagent, compaction, rust, implementation]
---

# Sub-Agent Spezifikation: Session Compaction Engine

> Integriere claw-code Compaction mit ECC Memory System

---

## Kontext

| Eigenschaft | Wert |
|-------------|------|
| **Quelle** | claw-code/rust/crates/runtime/src/compact.rs |
| **Ziel** | ~/.openclaw/workspace/crates/memory-compaction/ |
| **Bestehend** | MEMORY.md, memory/YYYY-MM-DD.md, Second Brain |

---

## Kern-Komponenten

### CompactionEngine
```rust
pub struct CompactionEngine<S: Summarizer> {
    config: CompactionConfig,
    summarizer: S,
}

pub struct CompactionConfig {
    pub max_estimated_tokens: usize,  // default: 10_000 (80% of 128K)
    pub preserve_recent: usize,       // default: 4 messages
}

#[async_trait]
pub trait Summarizer: Send + Sync {
    async fn summarize(&self, messages: &[Message]) -> Result<String, SummarizeError>;
}
```

### Compaction Algorithmus
```rust
impl<S: Summarizer> CompactionEngine<S> {
    pub async fn compact(&self, session: &mut Session) -> Result<CompactionResult, CompactionError> {
        // 1. Check if compaction needed
        let estimated = self.estimate_tokens(&session.messages);
        if estimated <= self.config.max_estimated_tokens {
            return Ok(CompactionResult::NotNeeded);
        }

        // 2. Partition messages
        let split_point = session.messages.len()
            .saturating_sub(self.config.preserve_recent);

        let to_summarize = &session.messages[..split_point];
        let to_preserve: Vec<Message> = session.messages[split_point..].to_vec();

        // 3. Generate summary
        let summary = self.summarizer.summarize(to_summarize).await?;

        // 4. Reconstruct session
        let compacted_count = to_summarize.len();
        session.messages.clear();
        session.messages.push(Message::system(format!(
            "[Previous {} messages summarized]: {}",
            compacted_count,
            summary
        )));
        session.messages.extend(to_preserve);

        // 5. Track compaction
        session.compactions.push(CompactionRecord {
            timestamp: Utc::now(),
            messages_compacted: compacted_count,
            summary_length: summary.len(),
        });

        Ok(CompactionResult::Compacted {
            messages_removed: compacted_count,
            summary,
        })
    }

    fn estimate_tokens(&self, messages: &[Message]) -> usize {
        // Naive estimation: chars / 4
        messages.iter()
            .map(|m| m.content.len() / 4)
            .sum()
    }
}
```

---

## ECC-Erweiterungen

### EccMemoryCompaction
```rust
pub struct EccMemoryCompaction<S: Summarizer> {
    compaction_engine: CompactionEngine<S>,
    memory_classifier: MemoryClassifier,
    obsidian_sync: ObsidianSync,
    daily_log_writer: DailyLogWriter,
    memory_md_updater: MemoryMdUpdater,
}

pub struct MemoryClassifier {
    importance_model: ImportanceModel,
}

#[derive(Debug, Clone)]
pub struct ClassifiedMemory {
    pub critical: Vec<MemoryEntry>,      // Must preserve exactly
    pub important: Vec<MemoryEntry>,     // Preserve in Second Brain
    pub reference: Vec<MemoryEntry>,     // Summarize only
    pub trivial: Vec<MemoryEntry>,       // Discard
}
```

### Memory Classification
```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Importance {
    Critical,   // Must preserve: decisions, errors, security events
    Important,  // Should preserve: key insights, patterns learned
    Reference,  // Nice to have: context, explanations
    Trivial,    // Can discard: greetings, confirmations
}

impl MemoryClassifier {
    pub async fn classify(&self, message: &Message) -> Importance {
        let content = &message.content;

        // Critical patterns
        if self.patterns.is_critical(content) {
            return Importance::Critical;
        }

        // Important patterns
        if self.patterns.is_important(content) {
            return Importance::Important;
        }

        // Trivial patterns
        if self.patterns.is_trivial(content) {
            return Importance::Trivial;
        }

        Importance::Reference
    }
}
```

### Classification Patterns
```rust
impl ClassificationPatterns {
    fn is_critical(&self, content: &str) -> bool {
        let critical_patterns = [
            "error:", "exception:", "failed",
            "security", "permission denied",
            "decided to", "conclusion:",
            "CVE-", "vulnerability",
        ];

        critical_patterns.iter().any(|p| 
            content.to_lowercase().contains(p)
        )
    }

    fn is_important(&self, content: &str) -> bool {
        let important_patterns = [
            "lesson learned",
            "best practice",
            "pattern:",
            "key insight",
            "solution:",
            "workaround",
            "optimization",
        ];

        important_patterns.iter().any(|p| 
            content.to_lowercase().contains(p)
        )
    }

    fn is_trivial(&self, content: &str) -> bool {
        // Short messages are often trivial
        if content.len() < 50 {
            return true;
        }

        let trivial_patterns = [
            "hello", "hi", "thanks",
            "got it", "understood",
            "ok", "okay",
        ];

        trivial_patterns.iter().any(|p| 
            content.to_lowercase().trim() == *p
        )
    }
}
```

---

## Sync-Komponenten

### ObsidianSync
```rust
pub struct ObsidianSync {
    vault_path: PathBuf,
    inbox_path: PathBuf,
}

impl ObsidianSync {
    pub async fn sync_entries(&self, entries: &[MemoryEntry]) -> Result<()> {
        for entry in entries {
            let filename = format!(
                "{}-{}.md",
                entry.timestamp.format("%Y-%m-%d"),
                self.sanitize_filename(&entry.title)
            );

            let content = format!(
                "# {}\n\n**Source:** {}\n**Timestamp:** {}\n\n{}\n\n## Tags\n- #claw-compaction\n- #auto-generated\n",
                entry.title,
                entry.source,
                entry.timestamp,
                entry.content
            );

            tokio::fs::write(&filepath, content).await?;
        }
        Ok(())
    }
}
```

### MemoryMdUpdater
```rust
pub struct MemoryMdUpdater {
    memory_file: PathBuf,
}

impl MemoryMdUpdater {
    pub async fn update(&self, entries: &[MemoryEntry]) -> Result<()> {
        let mut content = tokio::fs::read_to_string(&self.memory_file).await?;

        // Find insertion point
        let insertion_point = content.find("## Key Insights")
            .map(|i| i + "## Key Insights".len())
            .unwrap_or(content.len());

        // Format new entries
        let new_entries = entries.iter()
            .map(|e| format!(
                "\n- [{}] {}: {}",
                e.timestamp.format("%Y-%m-%d"),
                e.title,
                e.summary()
            ))
            .collect::<String>();

        content.insert_str(insertion_point, &new_entries);
        tokio::fs::write(&self.memory_file, content).await?;
        Ok(())
    }
}
```

---

## Summarizer Implementierung

```rust
pub struct LlmSummarizer<C: ApiClient> {
    client: C,
    model: String,
    max_summary_length: usize,
}

#[async_trait]
impl<C: ApiClient> Summarizer for LlmSummarizer<C> {
    async fn summarize(&self, messages: &[Message]) -> Result<String, SummarizeError> {
        let prompt = format!(
            "Summarize the following conversation messages concisely. \
             Preserve: task objectives, key decisions, file modifications, errors.\
             Messages to summarize:\n\n{}",
            messages.iter()
                .map(|m| format!("{}: {}", m.role, m.content))
                .collect::<Vec<_>>()
                .join("\n\n")
        );

        let response = self.client.complete(CompletionRequest {
            model: self.model.clone(),
            prompt,
            max_tokens: self.max_summary_length as u32,
        }).await?;

        Ok(response.text.trim().to_string())
    }
}
```

---

## Akzeptanzkriterien

- [ ] Compaction triggered bei 80% Token-Limit
- [ ] Letzte 4 Nachrichten werden erhalten
- [ ] Summary wird in System Prompt eingefügt
- [ ] Critical messages werden identifiziert
- [ ] Important messages syncen zu Obsidian
- [ ] MEMORY.md wird bei Critical aktualisiert
- [ ] Daily Log wird geschrieben
- [ ] Token-Estimation funktioniert
- [ ] Alle Tests passen

---

## Output Dateien

1. `crates/memory-compaction/src/lib.rs`
2. `crates/memory-compaction/src/compactor.rs`
3. `crates/memory-compaction/src/classifier.rs`
4. `crates/memory-compaction/src/obsidian_sync.rs`
5. `crates/memory-compaction/src/memory_md.rs`
6. `crates/memory-compaction/Cargo.toml`
7. Tests in `crates/memory-compaction/tests/`
