//! OpenClaw CLI - Unified command-line interface
//! 
//! Usage:
//!   openclaw index <vault-path>     - Index a vault into LanceDB
//!   openclaw search <query>         - Search indexed content
//!   openclaw session list           - List all sessions
//!   openclaw analyze <file>         - Analyze code file

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
        Commands::Index { vault_path, db_path } => {
            info!("Indexing vault: {}", vault_path);
            info!("Database path: {}", db_path);
            
            // TODO: Implement vault indexing
            println!("Indexing not yet implemented. Use Phase 4+ RAG.");
            
            Ok(())
        }
        
        Commands::Search { query, top_k, db_path } => {
            info!("Searching for: {}", query);
            info!("Top {} results from {}", top_k, db_path);
            
            // TODO: Implement search
            println!("Search not yet implemented.");
            
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
                    
                    println!("Created new session: {}", session.frontmatter.session_id);
                    println!("Path: {}", path.display());
                    
                    Ok(())
                }
            }
        }
        
        Commands::Analyze { file, analysis } => {
            info!("Analyzing file: {}", file);
            info!("Analysis type: {:?}", analysis);
            
            // TODO: Implement code analysis with openclaw-parser
            println!("Code analysis not yet implemented.");
            
            Ok(())
        }
        
        Commands::Status => {
            println!("OpenClaw AI Harness v0.1.0");
            println!("");
            println!("Available modules:");
            println!("  - openclaw-core:    ✅ Atomic writes + State management");
            println!("  - openclaw-agents:  ✅ Agent system");
            println!("  - openclaw-rag:     ✅ RAG + LanceDB");
            println!("  - openclaw-parser:  ✅ Tree-sitter parsing");
            println!("");
            println!("Session directory: .openclaw/sessions");
            println!("Database directory: .openclaw/db");
            
            Ok(())
        }
    }
}
