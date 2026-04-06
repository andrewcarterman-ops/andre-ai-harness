#!/usr/bin/env python3
"""
autoresearch_guardian_v2.py - Enhanced Runtime Guardian with Network Monitoring
Version 2.0 - Paranoid Mode Enabled
"""

import psutil
import time
import json
import subprocess
import sys
import os
import socket
import requests
from datetime import datetime
from pathlib import Path
from dataclasses import dataclass
from typing import List, Dict, Optional, Set

@dataclass
class NetworkConnection:
    """Represents a network connection"""
    local_addr: str
    remote_addr: str
    remote_port: int
    status: str
    pid: int
    hostname: Optional[str] = None
    is_allowed: bool = False

class AutoresearchGuardianV2:
    """Enhanced Guardian with paranoid network monitoring"""
    
    # Strict whitelist - ONLY these hosts are allowed
    ALLOWED_HOSTS = {
        'huggingface.co',
        'cdn.huggingface.co',
        'download.pytorch.org',
        'files.pythonhosted.org',
        'pypi.org',
        'pypi.python.org',
    }
    
    # Known safe IPs (HuggingFace, PyTorch)
    ALLOWED_IP_PREFIXES = {
        '99.84.',      # HuggingFace
        '13.224.',     # HuggingFace CDN
        '52.85.',      # PyTorch
        '151.101.',    # PyPI
    }
    
    def __init__(self, config_file: str = "guardian_config.json"):
        self.config = self._load_config(config_file)
        self.start_time = time.time()
        self.violations: List[Dict] = []
        self.network_violations: List[Dict] = []
        self.process: Optional[psutil.Process] = None
        self.telegram_config = self._load_telegram_config()
        self.seen_connections: Set[str] = set()  # Track unique connections
        
    def _load_config(self, config_file: str) -> Dict:
        defaults = {
            "max_runtime_minutes": 360,
            "max_memory_gb": 48,
            "max_disk_gb": 8,
            "max_cpu_percent": 80,
            "check_interval_seconds": 10,
            "network_check_interval": 5,  # More frequent network checks
            "strict_network_mode": True,   # Paranoid mode
        }
        
        try:
            with open(config_file) as f:
                loaded = json.load(f)
                defaults.update(loaded)
        except FileNotFoundError:
            pass
            
        return defaults
    
    def _load_telegram_config(self) -> Optional[Dict]:
        bot_token = os.environ.get("TELEGRAM_BOT_TOKEN")
        chat_id = os.environ.get("TELEGRAM_CHAT_ID")
        
        if bot_token and chat_id:
            return {"bot_token": bot_token, "chat_id": chat_id}
        
        config_path = Path.home() / ".autoresearch" / "telegram_config.json"
        if config_path.exists():
            with open(config_path) as f:
                return json.load(f)
        
        return None
    
    def resolve_hostname(self, ip: str) -> Optional[str]:
        """Resolve IP to hostname with caching"""
        try:
            hostname, _, _ = socket.gethostbyaddr(ip)
            return hostname.lower()
        except (socket.herror, socket.gaierror):
            return None
    
    def is_allowed_host(self, ip: str, hostname: Optional[str] = None) -> bool:
        """Check if host is in whitelist (paranoid check)"""
        # Check IP prefix
        for prefix in self.ALLOWED_IP_PREFIXES:
            if ip.startswith(prefix):
                return True
        
        # Check hostname if resolved
        if hostname:
            for allowed in self.ALLOWED_HOSTS:
                if allowed in hostname:
                    return True
        
        return False
    
    def get_network_connections(self) -> List[NetworkConnection]:
        """Get all network connections for monitored process"""
        connections = []
        
        if not self.process:
            return connections
        
        try:
            for conn in self.process.connections(kind='inet'):
                if conn.status == psutil.CONN_ESTABLISHED and conn.raddr:
                    remote_ip = conn.raddr.ip
                    remote_port = conn.raddr.port
                    
                    # Skip duplicates
                    conn_id = f"{remote_ip}:{remote_port}"
                    if conn_id in self.seen_connections:
                        continue
                    self.seen_connections.add(conn_id)
                    
                    # Resolve hostname
                    hostname = self.resolve_hostname(remote_ip)
                    
                    # Check if allowed
                    is_allowed = self.is_allowed_host(remote_ip, hostname)
                    
                    connections.append(NetworkConnection(
                        local_addr=f"{conn.laddr.ip}:{conn.laddr.port}" if conn.laddr else "",
                        remote_addr=remote_ip,
                        remote_port=remote_port,
                        status=conn.status,
                        pid=self.process.pid,
                        hostname=hostname,
                        is_allowed=is_allowed
                    ))
        except (psutil.AccessDenied, psutil.NoSuchProcess):
            pass
        
        return connections
    
    def check_network_violations(self) -> Optional[NetworkConnection]:
        """Check for forbidden network connections"""
        connections = self.get_network_connections()
        
        for conn in connections:
            if not conn.is_allowed:
                # Log the violation
                violation = {
                    "timestamp": datetime.now().isoformat(),
                    "remote_ip": conn.remote_addr,
                    "remote_port": conn.remote_port,
                    "hostname": conn.hostname or "UNKNOWN",
                    "action": "BLOCKED"
                }
                self.network_violations.append(violation)
                
                # Alert for every new forbidden connection
                self._send_telegram_alert(
                    "🚨 NETWORK VIOLATION",
                    f"*Forbidden connection detected!*\n\n"
                    f"*IP:* `{conn.remote_addr}`\n"
                    f"*Port:* `{conn.remote_port}`\n"
                    f"*Hostname:* `{conn.hostname or 'UNKNOWN'}`\n\n"
                    f"⚠️ *This connection is NOT in whitelist!*",
                    level="critical"
                )
                
                return conn
        
        return None
    
    def start_monitoring(self, train_process: subprocess.Popen):
        """Start comprehensive monitoring"""
        self.process = psutil.Process(train_process.pid)
        
        print(f"[INFO] Guardian V2 started for PID {self.process.pid}")
        print(f"[INFO] Network monitoring: ENABLED (Paranoid Mode)")
        print(f"[INFO] Whitelist: {', '.join(self.ALLOWED_HOSTS)}")
        
        self._send_telegram(
            "🚀 Guardian V2 Started",
            f"*Enhanced monitoring activated*\n\n"
            f"*PID:* `{self.process.pid}`\n"
            f"*Max Runtime:* {self.config['max_runtime_minutes']} min\n"
            f"*Network Mode:* PARANOID 🔒\n"
            f"*Check Interval:* {self.config['check_interval_seconds']}s\n\n"
            f"_Monitoring all network connections..._",
            level="info"
        )
        
        last_network_check = 0
        last_status_update = time.time()
        
        try:
            while True:
                current_time = time.time()
                
                # 1. Runtime check
                if self._check_runtime():
                    break
                
                # 2. Memory check
                if self._check_memory():
                    break
                
                # 3. CPU check
                if self._check_cpu():
                    break
                
                # 4. Network check (more frequent in paranoid mode)
                if current_time - last_network_check >= self.config.get('network_check_interval', 5):
                    violation = self.check_network_violations()
                    if violation and self.config.get('strict_network_mode', True):
                        self._kill(
                            "FORBIDDEN_NETWORK_CONNECTION",
                            f"Connected to {violation.remote_addr} ({violation.hostname or 'UNKNOWN'})"
                        )
                        break
                    last_network_check = current_time
                
                # 5. File access check
                if self._check_file_access():
                    break
                
                # Log status
                self._log_status()
                
                # Status update every 30 minutes
                if current_time - last_status_update >= 1800:
                    self._send_status_update()
                    last_status_update = current_time
                
                time.sleep(self.config["check_interval_seconds"])
                
        except KeyboardInterrupt:
            print("\n[INFO] Guardian stopped by user")
            self._send_telegram("🛑 Stopped", "Guardian stopped manually", level="warning")
        finally:
            self._cleanup()
    
    def _check_runtime(self) -> bool:
        elapsed = (time.time() - self.start_time) / 60
        if elapsed > self.config["max_runtime_minutes"]:
            self._kill("MAX_RUNTIME_EXCEEDED", f"Runtime: {elapsed:.1f}min")
            return True
        return False
    
    def _check_memory(self) -> bool:
        try:
            result = subprocess.run(
                ["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0:
                vram_gb = int(result.stdout.strip()) / 1024
                if vram_gb > self.config["max_memory_gb"]:
                    self._kill("MAX_MEMORY_EXCEEDED", f"VRAM: {vram_gb:.1f}GB")
                    return True
        except Exception as e:
            print(f"[WARN] Could not check VRAM: {e}")
        return False
    
    def _check_cpu(self) -> bool:
        if self.process:
            cpu = self.process.cpu_percent(interval=1)
            if cpu > self.config["max_cpu_percent"]:
                self.violations.append({
                    "time": datetime.now().isoformat(),
                    "type": "HIGH_CPU",
                    "value": cpu
                })
                if len([v for v in self.violations if v["type"] == "HIGH_CPU"]) > 3:
                    self._kill("SUSPICIOUS_CPU_USAGE", f"CPU: {cpu}%")
                    return True
        return False
    
    def _check_file_access(self) -> bool:
        if not self.process or not self.process.is_running():
            print("[INFO] Process ended")
            return True
        return False
    
    def _kill(self, reason: str, details: str):
        runtime_min = round((time.time() - self.start_time) / 60, 1)
        
        print(f"\n[ALERT] {reason}")
        print(f"        {details}")
        
        if self.process and self.process.is_running():
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except psutil.TimeoutExpired:
                self.process.kill()
                self.process.wait()
            print("[INFO] Process terminated")
        
        self._log_incident(reason, details)
        self._send_telegram_alert(
            "🚨 GUARDIAN ALERT",
            f"*Reason:* {reason}\n"
            f"*Details:* {details}\n"
            f"*Runtime:* {runtime_min} min\n"
            f"*Network Violations:* {len(self.network_violations)}",
            level="critical"
        )
    
    def _log_status(self):
        status = {
            "timestamp": datetime.now().isoformat(),
            "runtime_minutes": round((time.time() - self.start_time) / 60, 1),
            "violations": len(self.violations),
            "network_violations": len(self.network_violations),
            "process_running": self.process.is_running() if self.process else False
        }
        with open("guardian_status.log", "a") as f:
            f.write(json.dumps(status) + "\n")
    
    def _log_incident(self, reason: str, details: str):
        incident = {
            "timestamp": datetime.now().isoformat(),
            "reason": reason,
            "details": details,
            "runtime_minutes": round((time.time() - self.start_time) / 60, 1)
        }
        with open("guardian_incidents.log", "a") as f:
            f.write(json.dumps(incident) + "\n")
    
    def _send_telegram(self, title: str, message: str, level: str = "info"):
        if not self.telegram_config:
            return
        
        emojis = {"info": "ℹ️", "success": "✅", "warning": "⚠️", "error": "🚨", "critical": "🔴"}
        emoji = emojis.get(level, "ℹ️")
        text = f"{emoji} *{title}*\n\n{message}"
        
        try:
            url = f"https://api.telegram.org/bot{self.telegram_config['bot_token']}/sendMessage"
            payload = {
                "chat_id": self.telegram_config['chat_id'],
                "text": text,
                "parse_mode": "Markdown",
                "disable_notification": level in ["info"]
            }
            requests.post(url, json=payload, timeout=10)
        except Exception as e:
            print(f"[WARN] Telegram failed: {e}")
    
    def _send_telegram_alert(self, title: str, message: str, level: str = "critical"):
        self._send_telegram(title, message, level)
    
    def _send_status_update(self):
        runtime_min = round((time.time() - self.start_time) / 60, 1)
        
        vram_info = "N/A"
        try:
            result = subprocess.run(
                ["nvidia-smi", "--query-gpu=memory.used,memory.total", "--format=csv,noheader,nounits"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0:
                used, total = result.stdout.strip().split(",")
                vram_info = f"{int(used)/1024:.1f} / {int(total)/1024:.1f} GB"
        except:
            pass
        
        self._send_telegram(
            "📊 Status Update",
            f"*Runtime:* {runtime_min} min\n"
            f"*VRAM:* {vram_info}\n"
            f"*Violations:* {len(self.violations)}\n"
            f"*Network Violations:* {len(self.network_violations)}\n\n"
            f"_Running normally_",
            level="success"
        )
    
    def _cleanup(self):
        runtime_min = round((time.time() - self.start_time) / 60, 1)
        
        print("\n[INFO] Guardian cleanup")
        print(f"       Total runtime: {runtime_min} minutes")
        print(f"       Violations: {len(self.violations)}")
        print(f"       Network violations: {len(self.network_violations)}")
        
        if self.network_violations:
            self._send_telegram(
                "🏁 Experiment ended",
                f"*Runtime:* {runtime_min} min\n"
                f"*Network Violations:* {len(self.network_violations)}\n\n"
                f"⚠️ *Check logs for suspicious connections!*",
                level="warning"
            )
        else:
            self._send_telegram(
                "🏁 Success",
                f"*Runtime:* {runtime_min} min\n"
                f"*No network violations* ✅\n\n"
                f"_Good results!_",
                level="success"
            )


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Autoresearch Guardian V2 - Paranoid Mode")
    parser.add_argument("--monitor-pid", type=int, help="Monitor existing process")
    parser.add_argument("--train-command", default="uv run train.py", help="Train command")
    
    args = parser.parse_args()
    
    guardian = AutoresearchGuardianV2()
    
    if args.monitor_pid:
        import psutil
        process = psutil.Process(args.monitor_pid)
        guardian.start_monitoring(process)
    else:
        print(f"[INFO] Starting: {args.train_command}")
        process = subprocess.Popen(
            args.train_command.split(),
            stdout=open("train.log", "w"),
            stderr=subprocess.STDOUT
        )
        guardian.start_monitoring(process)
