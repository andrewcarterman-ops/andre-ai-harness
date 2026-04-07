//! OpenClaw CLI - Unified command-line interface

use clap::{Parser, Subcommand};
use anyhow::Result;
use tracing::{info, warn};

#[derive(Parser)]
#[command(name = "openclaw")]
#[command(about = "OpenClaw AI Harness - Code analysis and refactoring")]
#[command(version = "0.1.0")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Index a vault into the vector database
    Index {
        /// Path to the vault directory
        #[arg(value_name = "PATH")]
        vault_path: String,
        
        /// Database path (optional)
        #[arg(short, long, default_value = ".openclaw/db")]
        db_path: String,
        
        /// Max chars per chunk
        #[arg(short, long, default_value_t = 2000)]
        chunk_size: usize,
    },
    
    /// Search indexed content
    Search {
        /// Search query
        #[arg(value_name = "QUERY")]
        query: String,
        
        /// Number of results
        #[arg(short, long, default_value_t = 5)]
        top_k: usize,
        
        /// Database path
        #[arg(short, long, default_value = ".openclaw/db")]
        db_path: String,
    },
    
    /// Session management
    Session {
        #[command(subcommand)]
        action: SessionAction,
    },
    
    /// Analyze a code file
    Analyze {
        /// Path to the file
        #[arg(value_name = "FILE")]
        file: String,
        
        /// Analysis type
        #[arg(short, long, value_enum, default_value = "full")]
        analysis: AnalysisType,
    },
    
    /// Show system status
    Status,
}

#[derive(Subcommand)]
enum SessionAction {
    /// List all sessions
    List,
    
    /// Show latest session
    Latest,
    
    /// Create new session
    New {
        /// Agent name
        #[arg(short, long, default_value = "main")]
        agent: String,
    },
}

#[derive(Clone, Copy, Debug, clap::ValueEnum)]
enum AnalysisType {
    Full,
    Structure,
    Security,
    Metrics,
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    let cli = Cli::parse();
    
    match cli.command {
        Commands::Index { vault_path, db_path, chunk_size } => {
            info!("Indexing vault: {}", vault_path);
            info!("Database path: {}", db_path);
            info!("Chunk size: {}", chunk_size);
            
            // Create directories
            std::fs::create_dir_all(&db_path)?;
            
            // Initialize indexer
            let chunker = openclaw_rag::MarkdownChunker::new(chunk_size);
            let indexer = openclaw_rag::VaultIndexer::new(chunker, &db_path);
            
            // Index vault
            let vault_path = std::path::PathBuf::from(vault_path);
            match indexer.index_vault(&vault_path).await {
                Ok(stats) => {
                    println!("✅ Indexing complete!");
                    println!("   Files processed: {}", stats.files_processed);
                    println!("   Chunks created: {}", stats.chunks_created);
                    println!("   Errors: {}", stats.errors);
                }
                Err(e) => {
                    eprintln!("❌ Indexing failed: {}", e);
                    return Err(e);
                }
            }
            
            Ok(())
        }
        
        Commands::Search { query, top_k, db_path } => {
            info!("Searching for: {}", query);
            info!("Top {} results from {}", top_k, db_path);
            
            // Initialize searcher
            let searcher = openclaw_rag::VaultSearcher::new(&db_path);
            
            // Search
            match searcher.search(&query, top_k).await {
                Ok(results) => {
                    println!("🔍 Found {} results for '{}':", results.len(), query);
                    println!("");
                    
                    for (i, result) in results.iter().enumerate() {
                        println!("{}. {} (score: {:.2})", i + 1, result.heading, result.score);
                        println!("   Source: {}", result.source_path);
                        println!("   Content: {:.100}...", result.content);
                        println!("");
                    }
                }
                Err(e) => {
                    eprintln!("❌ Search failed: {}", e);
                    return Err(e);
                }
            }
            
            Ok(())
        }
        
        Commands::Session { action } => {
            match action {
                SessionAction::List => {
                    info!("Listing all sessions");
                    
                    let sessions_dir = std::path::PathBuf::from(".openclaw/sessions");
                    let manager = openclaw_core::SessionManager::new(&sessions_dir);
                    
                    match manager.list_sessions() {
                        Ok(sessions) => {
                            println!("Found {} sessions:", sessions.len());
                            for (id, path) in sessions {
                                println!("  - {} ({})", id, path.display());
                            }
                        }
                        Err(e) => {
                            warn!("Failed to list sessions: {}", e);
                            println!("No sessions found or error: {}", e);
                        }
                    }
                    
                    Ok(())
                }
                
                SessionAction::Latest => {
                    info!("Showing latest session");
                    
                    let sessions_dir = std::path::PathBuf::from(".openclaw/sessions");
                    let manager = openclaw_core::SessionManager::new(&sessions_dir);
                    
                    match manager.load_latest()? {
                        Some((session, path)) => {
                            println!("Latest session: {}", session.frontmatter.session_id);
                            println!("Status: {:?}", session.frontmatter.status);
                            println!("Agent: {}", session.frontmatter.agent);
                            println!("Path: {}", path.display());
                        }
                        None => {
                            println!("No sessions found.");
                        }
                    }
                    
                    Ok(())
                }
                
                SessionAction::New { agent } => {
                    info!("Creating new session with agent: {}", agent);
                    
                    let sessions_dir = std::path::PathBuf::from(".openclaw/sessions");
                    let manager = openclaw_core::SessionManager::new(&sessions_dir);
                    
                    let (mut session, path) = manager.create_session(&agent)?;
                    session.add_content("System", "Session initialized");
                    session.save(&path)?;
                    
                    println!("✅ Created new session: {}", session.frontmatter.session_id);
                    println!("   Path: {}", path.display());
                    
                    Ok(())
                }
            }
        }
        
        Commands::Analyze { file, analysis } => {
            info!("Analyzing file: {}", file);
            info!("Analysis type: {:?}", analysis);
            
            let file_path = std::path::PathBuf::from(&file);
            
            if !file_path.exists() {
                eprintln!("❌ File not found: {}", file);
                return Err(anyhow::anyhow!("File not found: {}", file));
            }
            
            // Initialize parser
            let mut parser = openclaw_parser::CodeParser::new()?;
            
            // Parse file
            match parser.parse_file(&file_path) {
                Ok(parse_result) => {
                    println!("✅ Parsed: {} ({:?})", file, parse_result.language);
                    
                    // Analyze based on type
                    let analyzer = openclaw_parser::AstAnalyzer::new();
                    let mut cursor = parse_result.tree.walk();
                    let ast = analyzer.traverse(&mut cursor, &parse_result.source);
                    
                    match analysis {
                        AnalysisType::Structure | AnalysisType::Full => {
                            let functions = analyzer.find_functions(&ast, parse_result.language);
                            let types = analyzer.find_types(&ast, parse_result.language);
                            
                            println!("");
                            println!("📊 Structure Analysis:");
                            println!("   Functions: {}", functions.len());
                            println!("   Types: {}", types.len());
                            
                            if !functions.is_empty() {
                                println!("");
                                println!("   Functions:");
                                for func in functions.iter().take(5) {
                                    // Zeige ersten Teil des Textes (Funktionsname)
                                    let name = func.text.lines().next().unwrap_or("unknown");
                                    println!("     - {} (lines {}-{})", 
                                        name.trim(), func.start_line, func.end_line);
                                }
                            }
                        }
                        _ => {}
                    }
                    
                    match analysis {
                        AnalysisType::Metrics | AnalysisType::Full => {
                            println!("");
                            println!("📈 Metrics:");
                            println!("   Total lines: {}", parse_result.source.lines().count());
                        }
                        _ => {}
                    }
                    
                    println!("");
                    println!("✅ Analysis complete!");
                }
                Err(e) => {
                    eprintln!("❌ Parsing failed: {}", e);
                    return Err(e);
                }
            }
            
            Ok(())
        }
        
        Commands::Status => {
            println!("╔════════════════════════════════════════════════════════╗");
            println!("║        OpenClaw AI Harness v0.1.0                      ║");
            println!("╚════════════════════════════════════════════════════════╝");
            println!("");
            println!("📦 Available modules:");
            println!("   ✅ openclaw-core:    Atomic writes + State management");
            println!("   ✅ openclaw-agents:  Agent system");
            println!("   ✅ openclaw-rag:     RAG + LanceDB + Embeddings");
            println!("   ✅ openclaw-parser:  Tree-sitter parsing");
            println!("");
            println!("📁 Directories:");
            println!("   Sessions: .openclaw/sessions");
            println!("   Database: .openclaw/db");
            println!("");
            println!("🔧 Available commands:");
            println!("   openclaw index <path>        - Index vault");
            println!("   openclaw search <query>      - Search content");
            println!("   openclaw analyze <file>      - Analyze code");
            println!("   openclaw session new         - New session");
            println!("   openclaw session list        - List sessions");
            
            Ok(())
        }
    }
}
