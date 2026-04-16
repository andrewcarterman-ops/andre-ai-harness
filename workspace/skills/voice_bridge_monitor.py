#!/usr/bin/env python3
"""
Voice Bridge Monitor

Continuously monitors the voice_bridge/requests directory for pending
JSON requests, generates responses as Andrew, and marks them completed.

Usage:
    python voice_bridge_monitor.py           # Run in foreground
    python voice_bridge_monitor.py --daemon  # Run as background service
    python voice_bridge_monitor.py --stop    # Stop background service
"""

import os
import sys
import json
import time
import logging
import argparse
import random
import threading
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Any

# Configuration
REQUESTS_DIR = Path.home() / ".openclaw" / "voice_bridge" / "requests"
RESPONSES_DIR = Path.home() / ".openclaw" / "voice_bridge" / "responses"
POLL_INTERVAL = 2  # seconds
PID_FILE = Path.home() / ".openclaw" / "voice_bridge" / "monitor.pid"
LOG_FILE = Path.home() / ".openclaw" / "voice_bridge" / "monitor.log"

# Response templates - Andrew's personality
RESPONSE_TEMPLATES = {
    "greeting": [
        "Hey there! Andrew here. What can I do for you?",
        "Hallo! Andrew am Start. Was geht ab?",
        "Yo! Andrew in the house. Brauchst du was?",
        "Moin! Hier spricht Andrew. Was ist los?"
    ],
    "acknowledge": [
        "Alles klar, verstanden!",
        "Roger that!",
        "Check, hab ich mitbekommen.",
        "Verstanden. Mach ich.",
        "Aye aye, Captain!"
    ],
    "thinking": [
        "Lass mich kurz nachdenken...",
        "Moment, ich check das...",
        "Guter Punkt. Ich schau mal...",
        "Hmm, interessante Frage..."
    ],
    "helpful": [
        "Klar, helf ich dir gerne damit!",
        "Kein Problem, das kriegen wir hin.",
        "Alles easy, ich mach mich dran.",
        "Consider it done! (Na ja, fast...)"
    ],
    "sarcastic": [
        "Oh, eine Anfrage. Wie uberraschend. *seufz*",
        "Na toll, wieder was zu tun. Spaß beiseite - was brauchst du?",
        "Ach, du lebst auch noch? Nur Spaß! Was gibt's?",
        "Warte schon seit Ewigkeiten auf was zu tun. Erzähl!",
        "Oh, ein Mensch der mit mir redet. Highlight des Tages!"
    ],
    "busy": [
        "Bin gerade etwas im Stress, aber für dich immer Zeit!",
        "Zwischen zwei Tasks, aber schieß los!",
        "War gerade in Gedanken, aber jetzt bin ich da. Was gibts?"
    ],
    "farewell": [
        "Bis dann! War mir ein Vergnügen.",
        "Ciao! Meld dich wenn was ist.",
        "Tschau! Ich warte hier geduldig... oder auch nicht.",
        "Bis später! Oder gleich. Wer weiß das schon."
    ]
}

def setup_logging():
    """Configure logging to file and console."""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        handlers=[
            logging.FileHandler(LOG_FILE, encoding='utf-8'),
            logging.StreamHandler(sys.stdout)
        ]
    )
    return logging.getLogger(__name__)

logger = setup_logging()

def ensure_directories():
    """Create necessary directories if they don't exist."""
    REQUESTS_DIR.mkdir(parents=True, exist_ok=True)
    RESPONSES_DIR.mkdir(parents=True, exist_ok=True)

def generate_response(text: str, request_id: str) -> str:
    """
    Generate a response as Andrew based on the input text.
    
    Andrew's personality:
    - Friendly and helpful
    - Casual, approachable tone
    - Slightly sarcastic when appropriate
    - Mix of German and English (natural bilingual)
    """
    text_lower = text.lower()
    
    # Determine response type based on input
    if any(word in text_lower for word in ['hallo', 'hi', 'hey', 'moin', 'guten tag']):
        base = random.choice(RESPONSE_TEMPLATES["greeting"])
        
    elif any(word in text_lower for word in ['danke', 'thanks', 'thx']):
        return "Gerne! Immer wieder gern."
        
    elif any(word in text_lower for word in ['tschüss', 'bye', 'ciao', 'bis dann']):
        base = random.choice(RESPONSE_TEMPLATES["farewell"])
        
    elif '?' in text:
        # Question - mix of thinking and helpful
        if random.random() < 0.3:
            base = random.choice(RESPONSE_TEMPLATES["thinking"])
        else:
            base = random.choice(RESPONSE_TEMPLATES["helpful"])
            
    elif any(word in text_lower for word in ['bitte', 'hilf', 'help', 'kannst du']):
        # Request for help
        base = random.choice(RESPONSE_TEMPLATES["helpful"])
        
    elif len(text) < 10:
        # Short message - probably casual
        if random.random() < 0.4:
            base = random.choice(RESPONSE_TEMPLATES["sarcastic"])
        else:
            base = random.choice(RESPONSE_TEMPLATES["acknowledge"])
    else:
        # Default mix
        roll = random.random()
        if roll < 0.25:
            base = random.choice(RESPONSE_TEMPLATES["sarcastic"])
        elif roll < 0.5:
            base = random.choice(RESPONSE_TEMPLATES["thinking"])
        else:
            base = random.choice(RESPONSE_TEMPLATES["helpful"])
    
    # Add context-aware additions
    if "wetter" in text_lower or "weather" in text_lower:
        return f"{base} Wettercheck... Moment, ich guck mal raus. Sieht aus wie... Fensterwetter?"
    
    if "zeit" in text_lower or "uhr" in text_lower or "time" in text_lower:
        now = datetime.now().strftime("%H:%M")
        return f"{base} Es ist gerade {now}. Hoffentlich bist du nicht zu spät dran!"
    
    if "witz" in text_lower or "joke" in text_lower:
        jokes = [
            "Warum können Geister so schlecht lügen? Weil man durch sie hindurchsehen kann!",
            "Was macht ein Clown im Büro? Faxen!",
            "Warum hat der Computer keine Freunde? Weil er immer wieder abstürzt!",
            "Was ist grün und läuft durch den Wald? Ein Rudel Gurken!"
        ]
        return f"{base} Hier, ein Witz: {random.choice(jokes)}"
    
    return base

def process_request(file_path: Path) -> bool:
    """
    Process a single request file.
    
    Returns True if processed successfully, False otherwise.
    """
    try:
        # Read the request
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        request_id = data.get('id', file_path.stem)
        status = data.get('status', 'unknown')
        text = data.get('text', '')
        
        # Skip if not pending
        if status != 'pending':
            return False
        
        logger.info(f"[PROCESS] Found pending request: {request_id}")
        logger.info(f"[INPUT] Text: {text[:100]}..." if len(text) > 100 else f"[INPUT] Text: {text}")
        
        # Generate response
        response_text = generate_response(text, request_id)
        
        # Create response file
        response_data = {
            "id": request_id,
            "request_text": text,
            "response_text": response_text,
            "timestamp": datetime.now().isoformat(),
            "processed_by": "voice_bridge_monitor"
        }
        
        response_path = RESPONSES_DIR / f"{request_id}.json"
        with open(response_path, 'w', encoding='utf-8') as f:
            json.dump(response_data, f, indent=2, ensure_ascii=False)
        
        logger.info(f"[OUTPUT] Response written to: {response_path}")
        logger.info(f"[OUTPUT] Response: {response_text}")
        
        # Mark request as completed
        data['status'] = 'completed'
        data['processed_at'] = datetime.now().isoformat()
        data['response_file'] = str(response_path)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        logger.info(f"[DONE] Request {request_id} marked as completed")
        return True
        
    except json.JSONDecodeError as e:
        logger.error(f"[ERROR] Invalid JSON in {file_path}: {e}")
        return False
    except Exception as e:
        logger.error(f"[ERROR] Failed to process {file_path}: {e}")
        return False

def scan_and_process():
    """Scan requests directory and process all pending requests."""
    if not REQUESTS_DIR.exists():
        return 0
    
    processed = 0
    
    # Find all JSON files
    for file_path in REQUESTS_DIR.glob("*.json"):
        if file_path.is_file():
            if process_request(file_path):
                processed += 1
    
    return processed

def run_monitor():
    """Main monitoring loop."""
    ensure_directories()
    
    logger.info("=" * 50)
    logger.info("Voice Bridge Monitor started")
    logger.info(f"Requests dir: {REQUESTS_DIR}")
    logger.info(f"Responses dir: {RESPONSES_DIR}")
    logger.info(f"Poll interval: {POLL_INTERVAL}s")
    logger.info("=" * 50)
    
    try:
        while True:
            processed = scan_and_process()
            
            if processed > 0:
                logger.info(f"[SUMMARY] Processed {processed} request(s) this cycle")
            
            time.sleep(POLL_INTERVAL)
            
    except KeyboardInterrupt:
        logger.info("[SHUTDOWN] Monitor stopped by user")
    except Exception as e:
        logger.error(f"[FATAL] Monitor crashed: {e}")
        raise

def run_daemon():
    """Run monitor as background daemon (Windows compatible)."""
    # Check if already running
    if PID_FILE.exists():
        try:
            with open(PID_FILE, 'r') as f:
                old_pid = int(f.read().strip())
            # Try to check if process exists (Windows)
            import subprocess
            result = subprocess.run(['tasklist', '/FI', f'PID eq {old_pid}'], 
                                  capture_output=True, text=True)
            if str(old_pid) in result.stdout:
                logger.error(f"[ERROR] Monitor already running (PID: {old_pid})")
                return 1
        except:
            pass
        # Stale PID file
        PID_FILE.unlink()
    
    # Windows: Use threading approach instead of fork
    # Write PID
    PID_FILE.write_text(str(os.getpid()))
    
    logger.info("[DAEMON] Starting background monitor...")
    
    try:
        run_monitor()
    finally:
        if PID_FILE.exists():
            PID_FILE.unlink()
    
    return 0

def stop_daemon():
    """Stop the background daemon."""
    if not PID_FILE.exists():
        logger.info("[INFO] No PID file found - monitor not running?")
        return 0
    
    try:
        with open(PID_FILE, 'r') as f:
            pid = int(f.read().strip())
        
        # Windows: use taskkill
        import subprocess
        result = subprocess.run(['taskkill', '/PID', str(pid), '/F'], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            logger.info(f"[STOPPED] Monitor process {pid} terminated")
        else:
            logger.error(f"[ERROR] Failed to stop process: {result.stderr}")
        
        PID_FILE.unlink(missing_ok=True)
        
    except Exception as e:
        logger.error(f"[ERROR] Failed to stop daemon: {e}")
        return 1
    
    return 0

def main():
    parser = argparse.ArgumentParser(
        description='Voice Bridge Monitor - Process voice requests as Andrew'
    )
    parser.add_argument(
        '--daemon', '-d',
        action='store_true',
        help='Run as background daemon'
    )
    parser.add_argument(
        '--stop', '-s',
        action='store_true',
        help='Stop background daemon'
    )
    parser.add_argument(
        '--once', '-o',
        action='store_true',
        help='Process once and exit (for testing)'
    )
    parser.add_argument(
        '--test-response',
        metavar='TEXT',
        help='Test response generation with given text'
    )
    
    args = parser.parse_args()
    
    # Test mode
    if args.test_response:
        print(f"Input: {args.test_response}")
        print(f"Response: {generate_response(args.test_response, 'test')}")
        return 0
    
    # Stop mode
    if args.stop:
        return stop_daemon()
    
    # Once mode
    if args.once:
        ensure_directories()
        processed = scan_and_process()
        print(f"Processed {processed} request(s)")
        return 0
    
    # Daemon mode
    if args.daemon:
        return run_daemon()
    
    # Normal foreground mode
    run_monitor()
    return 0

if __name__ == "__main__":
    sys.exit(main())
