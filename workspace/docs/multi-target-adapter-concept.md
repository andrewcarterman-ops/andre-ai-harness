# Multi-Target Adapter - Konzeptdokumentation

**Status:** Phase 4 - Konzept (nicht implementiert)  
**Priorität:** Optional / Zukunft  
**Geplante Implementierung:** Phase 4+ oder separate Erweiterung

---

## Zweck

Multi-Target Adapter ermöglichen das Deployment des Frameworks auf verschiedene Ziele:
- **Lokal:** Aktueller Workspace (bereits implementiert)
- **Remote:** VPS, Server (geplant)
- **Container:** Docker, Kubernetes (geplant)
- **Cloud:** AWS, GCP, Azure (geplant)

---

## Problem

Aktuell ist das Framework nur für lokale Nutzung im OpenClaw-Workspace konzipiert. Für Produktivnutzung müsste es auf verschiedene Ziele deploybar sein.

---

## Konzept

### Adapter-Pattern

```
┌─────────────────────────────────────┐
│         Framework Core              │
│  (Registry, Hooks, Plans, etc.)     │
└─────────────────┬───────────────────┘
                  │
    ┌─────────────┼─────────────┐
    ↓             ↓             ↓
┌───────┐    ┌───────┐    ┌───────┐
│ Local │    │Remote │    │Docker │
│Adapter│    │Adapter│    │Adapter│
└───┬───┘    └───┬───┘    └───┬───┘
    │            │            │
    ↓            ↓            ↓
 Workspace    VPS/Server   Container
```

---

## Target-Definition

```yaml
# registry/targets.yaml
targets:
  - id: "local"
    name: "Local Workspace"
    type: "local"
    path: "C:/Users/andre/.openclaw/workspace"
    adapter: "local"
    active: true
    
  - id: "vps-prod"
    name: "Production VPS"
    type: "remote"
    host: "vps.example.com"
    user: "deploy"
    path: "/opt/openclaw/workspace"
    adapter: "ssh"
    active: false
    
  - id: "docker-local"
    name: "Local Docker"
    type: "container"
    image: "openclaw/agent:latest"
    adapter: "docker"
    active: false
```

---

## Adapter-Schnittstelle

Jeder Adapter implementiert:

```typescript
interface TargetAdapter {
  // Verbindung
  connect(): Promise<Connection>;
  disconnect(): Promise<void>;
  
  // Datei-Operationen
  readFile(path: string): Promise<string>;
  writeFile(path: string, content: string): Promise<void>;
  deleteFile(path: string): Promise<void>;
  listFiles(path: string): Promise<string[]>;
  
  // Deployment
  deploy(manifest: InstallManifest): Promise<DeployResult>;
  validate(): Promise<ValidationResult>;
  
  // Sync
  sync(localPath: string, remotePath: string): Promise<SyncResult>;
}
```

---

## Adapter-Implementierungen

### 1. Local Adapter (bereits implizit vorhanden)
```yaml
adapter:
  type: "local"
  operations:
    - read
    - write
    - delete
    - list
```

### 2. SSH Adapter (geplant)
```yaml
adapter:
  type: "ssh"
  config:
    host: "{{host}}"
    user: "{{user}}"
    key_file: "~/.ssh/id_rsa"
    port: 22
  operations:
    - read
    - write
    - delete
    - list
    - exec
```

### 3. Docker Adapter (geplant)
```yaml
adapter:
  type: "docker"
  config:
    image: "openclaw/agent:latest"
    container_name: "openclaw-agent"
    volumes:
      - "{{workspace}}:/workspace"
  operations:
    - read
    - write
    - exec
    - logs
```

---

## Deployment-Workflow

```bash
# 1. Target auswählen
openclaw target:use vps-prod

# 2. Validieren
openclaw target:validate
# → Prüft Verbindung, Berechtigungen, Voraussetzungen

# 3. Deploy
openclaw deploy
# → Überträgt alle Dateien aus install-manifest.yaml

# 4. Verifizieren
openclaw target:verify
# → Prüft ob Deployment erfolgreich

# 5. Sync (inkrementell)
openclaw sync
# → Nur geänderte Dateien
```

---

## Manifest-Erweiterung

```yaml
# install-manifest.yaml
# Mit Multi-Target Support

deployment:
  default_target: "local"
  
  targets:
    local:
      path: "C:/Users/andre/.openclaw/workspace"
      
    vps-prod:
      pre_deploy:
        - "mkdir -p /opt/openclaw"
      post_deploy:
        - "chmod +x /opt/openclaw/scripts/*.sh"
        - "systemctl restart openclaw"
      
    docker-local:
      build:
        dockerfile: "./Dockerfile"
        context: "."
      run:
        ports:
          - "8080:8080"
        env:
          - "OPENCLAW_MODE=production"

  # Umgebungs-spezifische Konfiguration
  env_config:
    local:
      log_level: "debug"
    vps-prod:
      log_level: "warning"
    docker-local:
      log_level: "info"
```

---

## Sicherheit

### SSH
- Key-basierte Authentifizierung
- Keine Passwörter im Manifest
- `SSH_AUTH_SOCK` forwarding

### Docker
- Non-root User im Container
- Read-only Volumes wo möglich
- Secrets als Env-Variablen (nicht im Image)

### Remote
- TLS für API-Calls
- Network Policies
- Secret Management (Vault, etc.)

---

## Integration mit anderen Komponenten

### Mit Install-Manifest
- Target-spezifische Pfade
- Pre/Post Deploy Hooks
- Env-Konfiguration pro Target

### Mit Audit
- Deployment validieren
- Remote-System prüfen
- Konsistenz checken

### Mit Drift Doctor
- Remote vs Local vergleichen
- Sync-Status ermitteln
- Konflikte erkennen

---

## Implementierungsphasen

### Phase 4 (Minimal)
- [x] Konzept dokumentiert
- [ ] Target-Registry (`registry/targets.yaml`)
- [ ] Local Adapter formalisiert

### Phase 4+ (Erweiterung)
- [ ] SSH Adapter
- [ ] Docker Adapter
- [ ] Deploy-Kommando
- [ ] Sync-Mechanismus

### Phase 5 (Produktion)
- [ ] Kubernetes Adapter
- [ ] Cloud Provider Adapter
- [ ] CI/CD Integration
- [ ] Secret Management

---

## Aktueller Status

- **Lokal:** ✅ Funktioniert (implizit)
- **SSH:** ❌ Nicht implementiert
- **Docker:** ❌ Nicht implementiert
- **Cloud:** ❌ Nicht implementiert

---

*Konzept erstellt: 2026-03-25*  
*Autor: Andrew*  
*Phase: 4 (Konzept)*
