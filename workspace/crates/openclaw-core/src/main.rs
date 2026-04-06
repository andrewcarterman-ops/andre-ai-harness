//! OpenClaw Core - CLI Binary

use std::env;
use std::process;
use openclaw_core::atomic::{atomic_write, safe_delete};

fn print_usage() {
    eprintln!("OpenClaw Core - Atomare Dateioperationen");
    eprintln!();
    eprintln!("Verwendung:");
    eprintln!("  openclaw-core write <DATEI> <INHALT>  - Atomares Schreiben");
    eprintln!("  openclaw-core delete <DATEI>          - Sicheres Loeschen");
}

#[tokio::main]
async fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 2 {
        print_usage();
        process::exit(1);
    }
    
    let command = &args[1];
    
    match command.as_str() {
        "write" => {
            if args.len() < 4 {
                eprintln!("Fehler: 'write' benoetigt DATEI und INHALT");
                process::exit(1);
            }
            let path = &args[2];
            let content = &args[3];
            
            match atomic_write(path, content) {
                Ok(_) => println!("✓ Atomar geschrieben: {}", path),
                Err(e) => {
                    eprintln!("✗ Fehler: {}", e);
                    process::exit(1);
                }
            }
        }
        
        "delete" => {
            if args.len() < 3 {
                eprintln!("Fehler: 'delete' benoetigt DATEI");
                process::exit(1);
            }
            match safe_delete(&args[2]) {
                Ok(_) => println!("✓ Sicher geloescht: {}", &args[2]),
                Err(e) => {
                    eprintln!("✗ Fehler: {}", e);
                    process::exit(1);
                }
            }
        }
        
        _ => {
            print_usage();
            process::exit(1);
        }
    }
}
