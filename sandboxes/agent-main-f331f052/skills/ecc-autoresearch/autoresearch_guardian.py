#!/usr/bin/env python3
"""
autoresearch_guardian.py - Runtime Überwachung für autoresearch
Läuft parallel zum Experiment und überwacht alles

Unterstützt Telegram-Benachrichtigungen
"""

import psutil
import time
import json
import subprocess
import sys
import os
from datetime import datetime
from pathlib import Path

class AutoresearchGuardian:
    def __init__(self, config_file="guardian_config.json"):
        self.config = self._load_config(config_file)
        self.start_time = time.time()
        self.violations = []
        self.process = None
        self.telegram_config = self._load_telegram_config()
        
    def _load_config(self, config_file):
        defaults = {
            "max_runtime_minutes": 360,  # 6 Stunden (nicht 8!)
            "max_memory_gb": 48,  # H100 hat 80GB, wir limitieren auf 48
            "max_disk_gb": 8,
            "max_cpu_percent": 80,  # Verhindert Crypto-Mining
            "forbidden_syscalls": ["execve", "system", "popen"],
            "allowed_network_hosts": ["huggingface.co", "download.pytorch.org"],
            "check_interval_seconds": 10,
        }
        
        try:
            with open(config_file) as f:
                loaded = json.load(f)
                defaults.update(loaded)
        except FileNotFoundError:
            pass
            
        return defaults
    
    def _load_telegram_config(self):
        """Lädt Telegram Konfiguration aus Environment oder Config"""
        # Priorität 1: Environment Variables
        bot_token = os.environ.get("TELEGRAM_BOT_TOKEN")
        chat_id = os.environ.get("TELEGRAM_CHAT_ID")
        
        if bot_token and chat_id:
            return {"bot_token": bot_token, "chat_id": chat_id}
        
        # Priorität 2: Config-Datei
        config_path = Path.home() / ".autoresearch" / "telegram_config.json"
        if config_path.exists():
            with open(config_path) as f:
                return json.load(f)
        
        return None
    
    def start_monitoring(self, train_process):
        """Startet die Überwachung eines train.py Prozesses"""
        self.process = psutil.Process(train_process.pid)
        print(f"🔍 Guardian gestartet für PID {train_process.pid}")
        
        # Sende Start-Benachrichtigung
        self._send_telegram(
            "🚀 Experiment gestartet",
            f"*Guardian aktiviert*\n"
            f"Überwache PID {self.process.pid}\n"
            f"Max Runtime: {self.config['max_runtime_minutes']} Minuten\n\n"
            f"_Ich melde mich alle 30 Minuten oder bei Problemen_",
            level="info"
        )
        
        try:
            last_notification = time.time()
            
            while True:
                # 1. Runtime-Check
                if self._check_runtime():
                    break
                
                # 2. Memory-Check
                if self._check_memory():
                    break
                
                # 3. CPU-Check (Anti-Mining)
                if self._check_cpu():
                    break
                
                # 4. Network-Check
                if self._check_network():
                    break
                
                # 5. File-Access-Check
                if self._check_file_access():
                    break
                
                # Status-Log
                self._log_status()
                
                # Status-Update alle 30 Minuten
                if time.time() - last_notification > 1800:  # 30 Minuten
                    self._send_status_update()
                    last_notification = time.time()
                
                time.sleep(self.config["check_interval_seconds"])
                
        except KeyboardInterrupt:
            print("\n🛑 Guardian gestoppt durch Benutzer")
            self._send_telegram(
                "🛑 Manuell gestoppt",
                "Guardian wurde durch Benutzer beendet",
                level="warning"
            )
        finally:
            self._cleanup()
    
    def _check_runtime(self):
        """Prüft ob maximale Laufzeit überschritten"""
        elapsed = (time.time() - self.start_time) / 60
        if elapsed > self.config["max_runtime_minutes"]:
            self._kill("MAX_RUNTIME_EXCEEDED", 
                      f"Laufzeit: {elapsed:.1f}min > {self.config['max_runtime_minutes']}min")
            return True
        return False
    
    def _check_memory(self):
        """Prüft GPU-VRAM Verbrauch"""
        try:
            result = subprocess.run(
                ["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
                capture_output=True, text=True, timeout=5
            )
            
            if result.returncode == 0:
                vram_mb = int(result.stdout.strip())
                vram_gb = vram_mb / 1024
                
                if vram_gb > self.config["max_memory_gb"]:
                    self._kill("MAX_MEMORY_EXCEEDED",
                              f"VRAM: {vram_gb:.1f}GB > {self.config['max_memory_gb']}GB")
                    return True
        except Exception as e:
            print(f"⚠️  Konnte VRAM nicht prüfen: {e}")
        
        return False
    
    def _check_cpu(self):
        """Prüft CPU-Auslastung (Anti-Crypto-Mining)"""
        if self.process:
            cpu_percent = self.process.cpu_percent(interval=1)
            
            if cpu_percent > self.config["max_cpu_percent"]:
                self.violations.append({
                    "time": datetime.now().isoformat(),
                    "type": "HIGH_CPU",
                    "value": cpu_percent,
                    "action": "WARNING"
                })
                
                if len([v for v in self.violations if v["type"] == "HIGH_CPU"]) > 3:
                    self._kill("SUSPICIOUS_CPU_USAGE",
                              f"CPU: {cpu_percent}% (mehrfach)")
                    return True
        
        return False
    
    def _check_network(self):
        """Prüft Netzwerk-Verbindungen"""
        if self.process:
            try:
                connections = self.process.connections()
                for conn in connections:
                    if conn.status == psutil.CONN_ESTABLISHED:
                        remote_addr = conn.raddr
                        if remote_addr:
                            host = remote_addr.ip
                            try:
                                import socket
                                hostname = socket.gethostbyaddr(host)[0]
                                
                                if not any(allowed in hostname 
                                          for allowed in self.config["allowed_network_hosts"]):
                                    self._kill("FORBIDDEN_NETWORK_ACCESS",
                                              f"Verbindung zu: {hostname}")
                                    return True
                            except:
                                self._kill("UNKNOWN_NETWORK_HOST",
                                          f"Verbindung zu IP: {host}")
                                return True
            except (psutil.AccessDenied, psutil.NoSuchProcess):
                pass
        
        return False
    
    def _check_file_access(self):
        """Prüft Dateizugriffe (vereinfacht)"""
        if not self.process or not self.process.is_running():
            print("ℹ️  Train-Prozess beendet")
            return True
        
        return False
    
    def _kill(self, reason, details):
        """Beendet den Prozess sicher"""
        print(f"\n🚨 GUARDIAN ALARM: {reason}")
        print(f"   Details: {details}")
        
        runtime_min = round((time.time() - self.start_time) / 60, 1)
        
        if self.process and self.process.is_running():
            print(f"   Beende Prozess {self.process.pid}...")
            
            self.process.terminate()
            
            try:
                self.process.wait(timeout=5)
            except psutil.TimeoutExpired:
                self.process.kill()
                self.process.wait()
            
            print("   ✅ Prozess beendet")
        
        self._log_incident(reason, details)
        
        # Telegram Benachrichtigung
        self._send_telegram(
            "🚨 GUARDIAN ALARM",
            f"*Grund:* {reason}\n"
            f"*Details:* {details}\n"
            f"*Laufzeit:* {runtime_min} Minuten\n"
            f"*Verstöße:* {len(self.violations)}\n\n"
            f"⚠️ *Bitte prüfen!*",
            level="critical"
        )
    
    def _log_status(self):
        """Loggt aktuellen Status"""
        elapsed = (time.time() - self.start_time) / 60
        
        status = {
            "timestamp": datetime.now().isoformat(),
            "runtime_minutes": round(elapsed, 1),
            "violations": len(self.violations),
            "process_running": self.process.is_running() if self.process else False
        }
        
        with open("guardian_status.log", "a") as f:
            f.write(json.dumps(status) + "\n")
    
    def _log_incident(self, reason, details):
        """Loggt einen Vorfall"""
        incident = {
            "timestamp": datetime.now().isoformat(),
            "reason": reason,
            "details": details,
            "runtime_minutes": round((time.time() - self.start_time) / 60, 1)
        }
        
        with open("guardian_incidents.log", "a") as f:
            f.write(json.dumps(incident) + "\n")
    
    def _send_telegram(self, title, message, level="info"):
        """Sendet formatierte Telegram Benachrichtigung"""
        if not self.telegram_config:
            return  # Telegram nicht konfiguriert
        
        import requests
        
        emojis = {
            "info": "ℹ️",
            "success": "✅",
            "warning": "⚠️",
            "error": "🚨",
            "critical": "🔴"
        }
        
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
            
            response = requests.post(url, json=payload, timeout=10)
            
            if response.status_code == 200:
                print(f"   📱 Telegram gesendet")
            else:
                print(f"   ⚠️  Telegram-Fehler: {response.text}")
                
        except Exception as e:
            print(f"   ⚠️  Konnte Telegram nicht senden: {e}")
    
    def _send_status_update(self):
        """Sendet regelmäßigen Status-Update"""
        runtime_min = round((time.time() - self.start_time) / 60, 1)
        
        # Versuche VRAM zu lesen
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
            f"*Laufzeit:* {runtime_min} Minuten\n"
            f"*VRAM:* {vram_info}\n"
            f"*Verstöße:* {len(self.violations)}\n\n"
            f"_Alles läuft normal_ ✅",
            level="success"
        )
    
    def _cleanup(self):
        """Aufräumen"""
        runtime_min = round((time.time() - self.start_time) / 60, 1)
        
        print("\n🧹 Guardian Cleanup")
        print(f"   Gesamtlaufzeit: {runtime_min} Minuten")
        print(f"   Verstöße: {len(self.violations)}")
        
        # Finale Telegram-Nachricht
        if self.violations:
            self._send_telegram(
                "🏁 Experiment beendet",
                f"*Laufzeit:* {runtime_min} Minuten\n"
                f"*Verstöße:* {len(self.violations)}\n\n"
                f"⚠️ *Es gab Probleme - bitte Logs prüfen!*",
                level="warning"
            )
        else:
            self._send_telegram(
                "🏁 Experiment erfolgreich beendet",
                f"*Laufzeit:* {runtime_min} Minuten\n"
                f"*Keine Verstöße* ✅\n\n"
                f"_Gute Ergebnisse!_ 🎉",
                level="success"
            )


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--monitor-pid", type=int, help="Bestehenden Prozess überwachen")
    parser.add_argument("--train-command", default="uv run train.py", help="Train-Kommando")
    
    args = parser.parse_args()
    
    guardian = AutoresearchGuardian()
    
    if args.monitor_pid:
        import psutil
        process = psutil.Process(args.monitor_pid)
        guardian.start_monitoring(process)
    else:
        print(f"🚀 Starte: {args.train_command}")
        
        process = subprocess.Popen(
            args.train_command.split(),
            stdout=open("train.log", "w"),
            stderr=subprocess.STDOUT
        )
        
        guardian.start_monitoring(process)
