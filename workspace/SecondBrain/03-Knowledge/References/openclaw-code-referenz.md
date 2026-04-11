---
date: 07-04-2026
type: knowledge
category: reference
tags: [reference, code, rust, openclaw]
---

# Code-Referenz: OpenClaw Renovierung

## Atomic Write (Rust)

```rust
use std::fs;
use std::io::Write;
use std::path::Path;
use anyhow::Result;

pub fn atomic_write(path: &Path, content: &str) -> Result<()> {
    // 1. Temp-Datei erstellen
    let temp_path = path.with_extension("tmp");
    
    // 2. Inhalt schreiben
    let mut temp_file = fs::File::create(&temp_path)?;
    temp_file.write_all(content.as_bytes())?;
    temp_file.sync_all()?;  // Sicherstellen, dass auf Disk
    drop(temp_file);
    
    // 3. Atomare Umbenennung
    fs::rename(&temp_path, path)?;
    
    Ok(())
}
```

## Markdown Chunking (Rust)

```rust
pub struct Chunk {
    pub content: String,
    pub source_path: String,
    pub heading: String,
    pub line_start: usize,
    pub line_end: usize,
}

pub fn chunk_markdown(content: &str, max_chars: usize) -> Vec<Chunk> {
    let mut chunks = Vec::new();
    let mut current_chunk = String::new();
    let mut current_heading = String::from("Root");
    
    for line in content.lines() {
        // Neue Überschrift = neuer Chunk
        if line.starts_with("#") {
            if !current_chunk.is_empty() {
                chunks.push(Chunk {
                    content: current_chunk.clone(),
                    source_path: String::new(),
                    heading: current_heading.clone(),
                    line_start: 0,
                    line_end: 0,
                });
                current_chunk.clear();
            }
            current_heading = line.trim_start_matches('#').trim().to_string();
        }
        
        current_chunk.push_str(line);
        current_chunk.push('\n');
        
        // Chunk zu groß?
        if current_chunk.len() > max_chars {
            chunks.push(Chunk {
                content: current_chunk.clone(),
                source_path: String::new(),
                heading: current_heading.clone(),
                line_start: 0,
                line_end: 0,
            });
            current_chunk.clear();
        }
    }
    
    chunks
}
```

## Session Template (Markdown)

```markdown
---
session_id: "{{date:YYYYMMDD}}-{{time:HHmmss}}"
status: "todo"  # todo | in_progress | review | done
agent: "{{agent_name}}"
created_at: "{{date:YYYY-MM-DD}}T{{time:HH:mm:ss}}Z"
updated_at: "{{date:YYYY-MM-DD}}T{{time:HH:mm:ss}}Z"
parent_session: null
tokens_used: 0
cost_usd: 0.0
tags: []
---

# {{title}}

## Ziel
{{ziel}}

## Kontext
{{kontext}}

## Ergebnisse

## Nächste Schritte
- [ ] 

## Notizen
```

## Verwandte Dokumente

- [[openclaw-renovation|Projekt-Übersicht]]
- [[openclaw-implementations-plan|Implementations-Plan]]

## Erstellt
07-04-2026
