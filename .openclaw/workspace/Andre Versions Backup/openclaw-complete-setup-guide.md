

---

## 12. Code-Referenz

### 12.1 PowerShell - Berechtigungen

#### Eigentum übernehmen + Berechtigungen setzen
```powershell
# 1. Verzeichnis erstellen
New-Item -Path "C:\Autoresearch" -ItemType Directory -Force

# 2. Eigentum übernehmen (interaktiv Y/J drücken)
takeown /F "C:\Autoresearch" /R

# 3. Schreibrechte für aktuellen User
$currentUser = $env:USERNAME
icacls "C:\Autoresearch" /grant "${currentUser}:(OI)(CI)F" /T

# 4. Dateien kopieren
Copy-Item "source\file.txt" "C:\Autoresearch\"

# 5. Finale Rechte für andere User (optional)
icacls "C:\Autoresearch" /grant "autoresearch:(OI)(CI)F" /T
```

#### Variable Interpolation (korrekt)
```powershell
# FALSCH - wird als Variable interpretiert:
icacls "$path" /grant "$UserName:(OI)(CI)F"

# RICHTIG - geschweifte Klammern:
icacls "$path" /grant "${UserName}:(OI)(CI)F"
```

#### Datei-Inhalt ersetzen
```powershell
(Get-Content "C:\path\to\file.txt") `
  -replace 'oldText', 'newText' `
  | Set-Content "C:\path\to\file.txt" -Encoding UTF8
```

#### Backup wiederherstellen
```powershell
# Backups finden
Get-ChildItem -Path "$env:APPDATA\npm\node_modules\openclaw\dist" `
  -Filter "*.backup-*" -Recurse

# Wiederherstellen
Copy-Item "source.backup-20240403" "source" -Force
```

---

### 12.2 TypeScript - Edit-Tool Bugfix

#### Original-Bug (pi-tools.params.ts)
```typescript
// Datei: src/agents/pi-tools.params.ts
// Zeile: ~218

// VORHER (BUG):
const idx = params.required.indexOf(original);
if (idx !== -1) {
  params.required.splice(idx, 1);  // ❌ Entfernt nur!
  changed = true;
}

// NACHER (FIX):
const idx = params.required.indexOf(original);
if (idx !== -1) {
  params.required.splice(idx, 1, alias);  // ✅ Ersetzt!
  changed = true;
}
```

---

### 12.3 JavaScript - Parameter-Normalisierung

```javascript
// Aus thread-bindings-SYAnWHuW.js
// Normalisierung für verschiedene Parameter-Namen

function normalizeToolParams(params, toolName) {
  const normalized = { ...params };
  
  // file_path → path
  if ("file_path" in normalized && !("path" in normalized)) {
    normalized.path = normalized.file_path;
    delete normalized.file_path;
  }
  
  // old_string → oldText
  if ("old_string" in normalized && !("oldText" in normalized)) {
    normalized.oldText = normalized.old_string;
    delete normalized.old_string;
  }
  
  // new_string → newText
  if ("new_string" in normalized && !("newText" in normalized)) {
    normalized.newText = normalized.new_string;
    delete normalized.new_string;
  }
  
  return normalized;
}
```

---

### 12.4 JSON - Konfiguration

#### openclaw.json (Auszug)
```json
{
  "tools": {
    "profile": "full",
    "exec": {
      "applyPatch": {
        "enabled": true,
        "allowModels": [
          "openai/*",
          "openai-codex/*",
          "gpt-*",
          "claude-code/*"
        ]
      }
    },
    "web": {
      "search": {
        "enabled": true,
        "provider": "gemini",
        "gemini": {
          "apiKey": "YOUR_API_KEY",
          "model": "gemini-2.5-flash"
        }
      }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan"
  }
}
```

---

### 12.5 YAML - Registry-Definitionen

#### Agent-Definition (agents.yaml)
```yaml
agents:
  - id: "andrew-main"
    name: "Andrew"
    type: "main"
    description: "Hauptagent für direkte Interaktion"
    emoji: "🤖"
    active: true
    capabilities:
      - chat
      - file_access
      - web_search
      - tool_use
      - exec
    default_model: "kimi-coding/kimi-k2-thinking"
```

#### Skill-Definition (skills.yaml)
```yaml
skills:
  - id: "write-a-prd"
    name: "write-a-prd"
    category: "planning"
    triggers: ["write prd", "product requirements"]
    status: "active"
```

#### Hook-Definition (hooks.yaml)
```yaml
hooks:
  session:start:
    description: "Wird beim Start einer neuen Session ausgeführt"
    handler_file: "hooks/session-start.md"
    enabled: true
    priority: 100
    actions:
      - name: "validate_registry"
        required: true
      - name: "load_context"
        required: true
```

---

### 12.6 Bash - Build-Script

```bash
#!/bin/bash
# Build script for OpenClaw with fix

cd /c/Users/andre/Documents/GitHub/openclaw-temp-fix
export PATH="/c/Program Files/nodejs:/c/Users/andre/AppData/Roaming/npm:$PATH"

# Install dependencies
pnpm install

# Build
pnpm run build 2>&1 | tee build.log

echo "Build completed with exit code: ${PIPESTATUS[0]}"
```

---

### 12.7 JavaScript - Tool-Workaround

#### Read → Modify → Write Pattern
```javascript
// SCHLECHT (funktioniert nicht zuverlässig):
edit({
  file_path: "test.txt",
  old_string: "alt",
  new_string: "neu"
})

// GUT (funktioniert zuverlässig):
// 1. Lesen
const content = read({file_path: "test.txt"})

// 2. Modifizieren (im Kontext)
const newContent = content.replace("alt", "neu")

// 3. Schreiben
write({
  file_path: "test.txt",
  content: newContent
})
```

---

### 12.8 PowerShell - Backup-Management

```powershell
# Alle Backups auflisten
Get-ChildItem -Path "$env:APPDATA\npm\node_modules\openclaw\dist" `
  -Filter "*.backup-*" -Recurse | `
  Select-Object Name, LastWriteTime, FullName

# Neuestes Backup pro Datei finden
Get-ChildItem -Path "$env:APPDATA\npm\node_modules\openclaw\dist" `
  -Filter "*.backup-*" -Recurse | `
  Sort-Object LastWriteTime -Descending | `
  Group-Object { $_.DirectoryName + "\" + $_.BaseName } | `
  ForEach-Object { $_.Group | Select-Object -First 1 }

# Wiederherstellen
Copy-Item -Path "backup-file" -Destination "original-file" -Force
```

---

### 12.9 JSON - Cron-Job Definition

```json
{
  "job": {
    "name": "obsidian-sync-pipeline",
    "schedule": {
      "kind": "every",
      "everyMs": 300000
    },
    "payload": {
      "kind": "systemEvent",
      "text": "Sync OpenClaw to Second Brain"
    },
    "sessionTarget": "main",
    "enabled": true
  }
}
```

---

## Anhänge

### A. Wichtige Dateien für zukünftige LLMs

**Müssen immer gelesen werden bei Session-Start:**
1. `SOUL.md` - Wer ich bin
2. `USER.md` - Wer der Benutzer ist
3. `MEMORY.md` - Kuratiertes Langzeit-Gedächtnis
4. `TOOLS.md` - Tool-Notizen
5. `registry/agents.yaml` - Agent-Definitionen
6. `registry/skills.yaml` - Skill-Registry
7. Diese Datei (`openclaw-complete-setup-guide.md`)

### B. Kontakt & Support

- **OpenClaw Docs:** https://docs.openclaw.ai
- **GitHub (Original):** https://github.com/openclaw/openclaw
- **GitHub (Inspiration):** https://github.com/instructkr/claw-code
- **Community:** https://discord.com/invite/clawd

### C. Changelog

| Datum | Änderung | Autor |
|-------|----------|-------|
| 2026-04-03 | Erste Version | Andrew |
| 2026-04-03 | Edit-Tool Workaround etabliert | Andrew |
| 2026-04-03 | Profil auf `full` geändert | Andrew |
| 2026-04-03 | Source-Code Backup erstellt | Andrew |
| 2026-04-03 | Vollständige Registry dokumentiert | Andrew |
| 2026-04-03 | Code-Referenz hinzugefügt | Andrew |

---

**Ende der Dokumentation**

*Diese Datei ist die zentrale Referenz für alle OpenClaw-bezogenen Informationen. Bei Änderungen oder Erweiterungen sollte sie aktualisiert werden.*

*Registry-Stand: 2026-04-03*
- **Agents:** 7 (1 Main + 6 Sub)
- **Skills:** 15 (5 Planning, 1 Dev, 5 Original, 4 ECC)
- **Hooks:** 2 aktiv (Phase 1), 4 geplant (Phase 2)
- **Tools:** 15+ (Core, Web, Session, Model, Restricted)
- **Code-Beispiele:** 9 Abschnitte (PowerShell, TypeScript, JSON, YAML, Bash, JavaScript)