# HEARTBEAT.md
# Periodische Tasks für den Agenten

version: "1.0"
last_updated: "2026-03-26"

# Heartbeat-Konfiguration
settings:
  enabled: true
  log_heartbeats: false  # Reduziert Noise
  
# Tägliche Tasks
tasks:
  - name: "Second Brain Sync Check"
    description: "Prüft ob Second Brain sync ist, sonst automatisch syncen"
    schedule: "daily"
    time: "23:00"
    timezone: "Europe/Berlin"
    condition: "new_sessions_since_last_sync OR last_sync_older_than_24h"
    action: "sync-second-brain"
    notify: false  # Silent - nur bei Fehlern benachrichtigen
    enabled: true
    
  - name: "Health Check"
    description: "Tägliche Systemprüfung"
    schedule: "daily"
    time: "08:00"
    action: "validate-complete"
    notify_only_on_failure: true
    enabled: true
    
  - name: "Drift Detection"
    description: "Prüft auf Konfigurationsabweichungen"
    schedule: "weekly"
    day: "sunday"
    time: "10:00"
    action: "drift-check"
    notify_only_on_drift: true
    enabled: true

# Bedingungen für Tasks
conditions:
  new_sessions_since_last_sync: "exists(memory/2026-*.md newer than second-brain/last-sync.timestamp)"
  last_sync_older_than_24h: "second-brain/last-sync.timestamp age > 24h"
