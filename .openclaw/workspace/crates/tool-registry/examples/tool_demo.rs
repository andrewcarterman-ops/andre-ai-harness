//! Tool Registry Demo
//! 
//! Demonstrates practical usage of all tools
//! 
//! Run: cargo run --example tool_demo

use std::sync::Arc;
use tool_registry::{ToolRegistry, Tool};
use serde_json::json;

#[tokio::main]
async fn main() {
    println!("╔══════════════════════════════════════════════════════════╗");
    println!("║     Tool Registry Demo - Practical Usage                 ║");
    println!("╚══════════════════════════════════════════════════════════╝\n");

    // 1. Create registry with all default tools
    let registry = ToolRegistry::with_defaults();
    
    println!("📦 Registered Tools ({}):", registry.count());
    for tool in registry.list_tools() {
        println!("  • {}", tool);
    }
    println!();

    // 2. Get tool definitions (for LLM)
    let definitions = registry.get_definitions();
    println!("📋 Tool Definitions for LLM:");
    for def in &definitions {
        println!("  {}: {}", def.name, def.description);
    }
    println!();

    // 3. Demo: Write a file
    println!("📝 Demo: Write File");
    let result = registry.execute("write_file", json!({
        "path": "/tmp/tool_demo_test.txt",
        "content": "Hello from Tool Registry!\nThis is a test file."
    })).await;
    
    match result {
        Ok(output) => println!("  ✅ {}", output.content),
        Err(e) => println!("  ❌ Error: {}", e),
    }
    println!();

    // 4. Demo: Read the file
    println!("📖 Demo: Read File");
    let result = registry.execute("read_file", json!({
        "path": "/tmp/tool_demo_test.txt"
    })).await;
    
    match result {
        Ok(output) => {
            println!("  ✅ Content:");
            for line in output.content.lines() {
                println!("     {}", line);
            }
        }
        Err(e) => println!("  ❌ Error: {}", e),
    }
    println!();

    // 5. Demo: Edit the file
    println!("✏️  Demo: Edit File");
    let result = registry.execute("edit_file", json!({
        "path": "/tmp/tool_demo_test.txt",
        "old_string": "Hello from Tool Registry!",
        "new_string": "Hello from Tool Registry (EDITED)!"
    })).await;
    
    match result {
        Ok(output) => println!("  ✅ {}", output.content),
        Err(e) => println!("  ❌ Error: {}", e),
    }
    println!();

    // 6. Demo: Glob search
    println!("🔍 Demo: Glob Search");
    let result = registry.execute("glob", json!({
        "pattern": "*.rs",
        "path": "."
    })).await;
    
    match result {
        Ok(output) => {
            let files: Vec<_> = output.content.lines().take(5).collect();
            println!("  ✅ Found {} files (showing 5):", output.content.lines().count());
            for file in files {
                println!("     {}", file);
            }
        }
        Err(e) => println!("  ❌ Error: {}", e),
    }
    println!();

    // 7. Demo: Grep search
    println!("🔎 Demo: Grep Search");
    let result = registry.execute("grep", json!({
        "pattern": "async fn",
        "path": "src"
    })).await;
    
    match result {
        Ok(output) => {
            let lines: Vec<_> = output.content.lines().take(3).collect();
            println!("  ✅ Found matches (showing 3):");
            for line in lines {
                println!("     {}", line);
            }
        }
        Err(e) => println!("  ❌ Error: {}", e),
    }
    println!();

    // 8. Demo: Bash command
    println!("💻 Demo: Bash Command");
    let result = registry.execute("bash", json!({
        "command": "echo 'Hello from Bash!' && pwd",
        "timeout": 10
    })).await;
    
    match result {
        Ok(output) => {
            if output.is_error {
                println!("  ⚠️  Error: {}", output.content);
            } else {
                println!("  ✅ Output:");
                for line in output.content.lines() {
                    println!("     {}", line);
                }
            }
        }
        Err(e) => println!("  ❌ Error: {}", e),
    }
    println!();

    // 9. Demo: Safety check (blocked command)
    println!("🛡️  Demo: Safety Check (Blocked Command)");
    let result = registry.execute("bash", json!({
        "command": "rm -rf /",
        "timeout": 5
    })).await;
    
    match result {
        Ok(output) => println!("  ⚠️  Unexpected success: {}", output.content),
        Err(e) => println!("  ✅ Correctly blocked: {}", e),
    }
    println!();

    // 10. Execute tool directly
    println!("🔧 Demo: Direct Tool Execution");
    use tool_registry::ReadFileTool;
    
    let read_tool = Arc::new(ReadFileTool);
    let result = read_tool.execute(json!({
        "path": "/tmp/tool_demo_test.txt"
    })).await;
    
    match result {
        Ok(output) => {
            println!("  ✅ Direct execution successful");
            println!("     First line: {}", output.content.lines().next().unwrap_or("empty"));
        }
        Err(e) => println!("  ❌ Error: {}", e),
    }
    println!();

    // Cleanup
    println!("🧹 Cleanup: Removing test file");
    let _ = registry.execute("bash", json!({
        "command": "rm /tmp/tool_demo_test.txt"
    })).await;
    println!("  ✅ Done\n");

    println!("═══════════════════════════════════════════════════════════");
    println!("✨ All demos completed!");
    println!("═══════════════════════════════════════════════════════════");
}
