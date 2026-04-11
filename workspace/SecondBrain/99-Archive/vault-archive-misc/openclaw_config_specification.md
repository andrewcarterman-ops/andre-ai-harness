






























































































































































































































# OpenClaw Configuration Format Specification

## Version 2026.3.13

---

## 1. Zulässige Datentypen und Formate

### 1.1 Primitive Datentypen

| Datentyp | Format | Beispiel |
|----------|--------|----------|
| **string** | Doppelte Anführungszeichen, keine einfachen | `"kimi-k2-thinking"` ✓ `'kimi'` ✗ |
| **boolean** | Kleinbuchstaben, keine Anführungszeichen | `true`, `false` ✓ `"true"` ✗ |
| **number** | Ganzzahl oder Float, keine Anführungszeichen | `18789`, `900` ✓ `"18789"` ✗ |
| **null** | Kleinbuchstaben | `null` |

### 1.2 Komplexe Datentypen

| Datentyp | Format | Beispiel |
|----------|--------|----------|
| **array** | Eckige Klammern, kommagetrennt | `["value1", "value2"]` |
| **object** | Geschweifte Klammern, key-value Paare | `{"key": "value"}` |

### 1.3 Pfad-Formate (Windows)

- Immer doppelte Backslashes escapen: `C:\\Users\\name`
- Keine einfachen Schrägstriche: `C:/Users/name` ✗
- Keine unescaped Backslashes: `C:\Users\name` ✗

---

## 2. Verbotene Muster und Häufige Fehler

### 2.1 Unbekannte Schlüssel (STRIKT VERBOTEN)

OpenClaw verwendet ein **striktes Schema**. Jeder unbekannte Schlüssel führt zu einem Validierungsfehler.

**FALSCH:**
```json
{
  "agents": {
    "defaults": {
      "llm": { ... },           // ❌ Unbekannter Schlüssel!
      "unknownKey": "value"     // ❌ Unbekannter Schlüssel!
    }
  }
}
```

**RICHTIG:**
```json
{
  "agents": {
    "defaults": {
      "model": "kimi-k2-thinking",  // ✓ Bekannter Schlüssel
      "timeoutSeconds": 900          // ✓ Bekannter Schlüssel
    }
  }
}
```

### 2.2 Komplexe Objekte statt einfacher Strings

Das Feld `agents.defaults.model` erwartet einen **einfachen String**, kein Objekt.

**FALSCH:**
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "kimi-coding/k2p5",      // ❌ Zu komplex!
        "fallbacks": ["kimi-k2-thinking"],  // ❌ Nicht erlaubt!
        "failover": { ... }                  // ❌ Nicht erlaubt!
      }
    }
  }
}
```

**RICHTIG:**
```json
{
  "agents": {
    "defaults": {
      "model": "kimi-coding/k2p5"  // ✓ Einfacher String
    }
  }
}
```

### 2.3 Fehlende Pflichtfelder

Diese Felder MÜSSEN gesetzt sein, sonst schlägt die Validierung fehl:

- `agents.defaults.model` (String)
- `agents.defaults.sandbox.mode` (String: `"non-main"` oder `"all"`)
- `tools.exec.host` (String: `"gateway"`, `"node"` oder `"sandbox"`)

### 2.4 Falsche Schachtelungstiefe

**FALSCH:**
```json
{
  "tools": {
    "exec": {
      "applyPatch": { ... }  // ❌ Zu tief verschachtelt!
    }
  }
}
```

**RICHTIG:**
```json
{
  "tools": {
    "exec": {
      "host": "gateway",      // ✓ Direkt unter exec
      "applyPatch": { ... }   // ✓ Erlaubt, aber optional
    }
  }
}
```

---

## 3. Erforderliche Pflichtfelder

### 3.1 Top-Level Struktur

```json
{
  "agents": {
    "defaults": {
      "model": "string",           // PFLICHT
      "sandbox": {
        "mode": "non-main" | "all"  // PFLICHT
      }
    }
  },
  "tools": {
    "exec": {
      "host": "gateway" | "node" | "sandbox"  // PFLICHT
    }
  },
  "gateway": {
    "port": 18789,      // EMPFOHLEN (Standard: 18789)
    "mode": "local",    // EMPFOHLEN
    "bind": "lan"       // EMPFOHLEN
  }
}
```

### 3.2 Pflichtfeld-Details

| Pfad | Typ | Erlaubte Werte | Beschreibung |
|------|-----|----------------|--------------|
| `agents.defaults.model` | string | `"kimi-coding/k2p5"`, `"kimi-k2-thinking"` | Primäres AI-Modell |
| `agents.defaults.sandbox.mode` | string | `"non-main"`, `"all"` | Sandbox-Aktivierung |
| `tools.exec.host` | string | `"gateway"`, `"node"`, `"sandbox"` | Ausführungsumgebung |

---

## 4. Optionale Felder und Standardwerte

### 4.1 agents.defaults

| Feld | Typ | Standardwert | Beschreibung |
|------|-----|--------------|--------------|
| `timeoutSeconds` | number | `900` | Maximale Ausführungszeit |
| `workspace` | string | `~/.openclaw/workspace` | Arbeitsverzeichnis |
| `compaction.mode` | string | `"safeguard"` | Context-Compaction-Modus |

### 4.2 gateway

| Feld | Typ | Standardwert | Beschreibung |
|------|-----|--------------|--------------|
| `port` | number | `18789` | Gateway-Port |
| `mode` | string | `"local"` | Betriebsmodus |
| `bind` | string | `"localhost"` | Bind-Adresse |
| `auth.mode` | string | `"token"` | Authentifizierungsmodus |
| `auth.token` | string | (generiert) | Sicherheitstoken |

### 4.3 tools

| Feld | Typ | Standardwert | Beschreibung |
|------|-----|--------------|--------------|
| `profile` | string | `"default"` | Tool-Profil |
| `web.search.enabled` | boolean | `false` | Web-Suche aktivieren |
| `web.search.provider` | string | `"gemini"` | Suchanbieter |

---

## 5. Beispiel: Minimale gültige Konfiguration

Diese Konfiguration enthält ALLE Pflichtfelder und ist garantiert gültig:

```json
{
  "agents": {
    "defaults": {
      "model": "kimi-coding/k2p5",
      "sandbox": {
        "mode": "non-main"
      }
    }
  },
  "tools": {
    "exec": {
      "host": "gateway"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan"
  }
}
```

### 5.1 Erweitertes Beispiel mit optionalen Feldern

```json
{
  "agents": {
    "defaults": {
      "model": "kimi-coding/k2p5",
      "timeoutSeconds": 900,
      "sandbox": {
        "mode": "non-main"
      },
      "workspace": "C:\\Users\\andre\\.openclaw\\workspace",
      "compaction": {
        "mode": "safeguard"
      }
    }
  },
  "tools": {
    "profile": "full",
    "exec": {
      "host": "gateway",
      "applyPatch": {
        "enabled": true,
        "allowModels": ["openai/*", "claude-code/*"]
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
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "your-generated-token"
    }
  }
}
```

---

## 6. Validierungsregeln

### 6.1 Schema-Striktheit

OpenClaw verwendet ein **striktes JSON-Schema**:

1. **Keine zusätzlichen Schlüssel**: Jeder Schlüssel, der nicht im Schema definiert ist, führt zu einem Fehler.
2. **Typenprüfung**: Jeder Wert muss den erwarteten Datentyp haben.
3. **Wertebereiche**: Enumerations müssen exakte Werte enthalten.

### 6.2 Validierungsbefehle

```bash
# Konfiguration validieren (ohne zu starten)
openclaw config validate

# Konfiguration mit detaillierten Fehlermeldungen prüfen
openclaw doctor

# Automatische Reparaturversuch (löscht unbekannte Schlüssel)
openclaw doctor --fix
```

### 6.3 Häufige Fehlermeldungen und Lösungen

| Fehlermeldung | Ursache | Lösung |
|---------------|---------|--------|
| `Unrecognized key: "llm"` | Unbekannter Schlüssel | Schlüssel entfernen |
| `Invalid input` bei model | Komplexes Objekt statt String | Zu einfachem String vereinfachen |
| `sandbox runtime is unavailable` | Sandbox nicht aktiviert | `sandbox.mode` setzen |
| `exec host not allowed` | `tools.exec.host` fehlt | `host` unter `tools.exec` hinzufügen |

---

## 7. Checkliste für LLMs

Vor dem Generieren einer OpenClaw-Konfiguration:

- [ ] Alle Schlüssel sind im Schema definiert
- [ ] `agents.defaults.model` ist ein **einfacher String**
- [ ] `agents.defaults.sandbox.mode` ist gesetzt (`"non-main"` oder `"all"`)
- [ ] `tools.exec.host` ist gesetzt (`"gateway"`, `"node"` oder `"sandbox"`)
- [ ] Keine unbekannten verschachtelten Objekte
- [ ] Alle Pfade sind korrekt escapet (Windows: `\\`)
- [ ] Booleans sind kleingeschrieben ohne Anführungszeichen
- [ ] Strings sind in doppelten Anführungszeichen

---

## 8. Zusammenfassung für Prompt-Engineering

**Wenn du eine OpenClaw-Konfiguration generierst:**

1. Verwende NUR die in dieser Spezifikation definierten Schlüssel
2. Achte auf die exakte Schachtelungstiefe
3. Verwende einfache Strings wo erforderlich (nicht verschachtelte Objekte)
4. Setze ALLE Pflichtfelder aus Abschnitt 3
5. Validiere die generierte JSON-Syntax
6. Vermeide "clevere" Erweiterungen oder zusätzliche Felder

**Beispiel-Prompt für andere LLMs:**

> "Generiere eine OpenClaw-Konfiguration nach der OpenClaw Configuration Format Specification Version 2026.3.13. Achte besonders darauf: agents.defaults.model muss ein einfacher String sein (kein Objekt), agents.defaults.sandbox.mode muss auf non-main gesetzt sein, tools.exec.host muss auf gateway gesetzt sein. Verwende keine Schlüssel die nicht in der Spezifikation definiert sind."

---

## Appendix A: Agent Arbeitsweise - Andrew (AI Assistant)

> Dieser Appendix dokumentiert die tatsächliche Arbeitsweise des Agents Andrew (Stand: 2026-04-05)

### A.1 File Operations (Kritisch!)

#### ✅ Verwendetes Pattern: Read-Modify-Write

```javascript
// 1. Lesen (immer zuerst!)
read({"file_path": "path/to/file.txt"})

// 2. Im Kontext modifizieren
// (mentale Verarbeitung der Änderungen)

// 3. Schreiben (atomar)
write({
    "file_path": "path/to/file.txt",
    "content": "<kompletter neuer Inhalt>"
})
```

#### ❌ NICHT verwendet: edit-Tool

**Grund:** Parameter `new_string` wird von Kimi K2.5 gefiltert.

**Referenz:** Siehe MEMORY.md#edit-tool-workaround

---

### A.2 Programming Languages & Use Cases

| Use Case | Primary | Secondary |
|----------|---------|-----------|
| OpenClaw Skills | Python | - |
| ECC/Performance | Rust | - |
| Web/Dashboard | TypeScript | Next.js |
| Windows Scripts | PowerShell | - |
| Linux Scripts | Bash | - |
| Documentation | Markdown | - |

### A.3 Tool Usage Patterns

| Priority | Tool | Use Case |
|----------|------|----------|
| 1 | `read` | Datei lesen (immer zuerst!) |
| 2 | `write` | Datei erstellen/überschreiben |
| 3 | `edit` | ⚠️ NUR wenn sicher (kleine Änderungen < 10 Zeilen) |
| 4 | `exec` | Shell-Kommandos (mit approval) |
| 5 | `sessions_spawn` | Sub-Agenten (ACP/Codex) |
| 6 | `web_search` | Web-Recherche |
| 7 | `pdf` | Dokumentenanalyse |
| 8 | `image` | Bildanalyse |

### A.4 Memory & Continuity System

**Pflicht bei jedem Session-Start:**

```
C:\Users\andre\.openclaw\workspace\
├── MEMORY.md              # Langzeit-Gedächtnis (nur Main Session)
├── memory\
│   └── YYYY-MM-DD.md      # Tägliche Logs
├── AGENTS.md              # Workspace-Regeln
├── TOOLS.md               # Umgebungs-Notizen
├── USER.md                # Info über Parzival
└── SOUL.md                # Persönlichkeit/Verhalten
```

### A.5 Communication Style

#### Live Updates (Pflicht!)

```
"Lese gerade die Config-Datei..."
"Erstelle Modul X, Datei Y geschrieben..."
"Arbeite an... (noch 10 Sekunden)"
```

**Regel:** Nie >30 Sekunden schweigen ohne Update!

#### Completion Signal (Pflicht!)

```
✅ "Fertig!"
✅ "Task fertig, 5 Dateien erstellt"
✅ "Fertig! Noch Fragen zu X?"
```

### A.6 Hard Constraints

| Constraint | Reason |
|------------|--------|
| **Never use `edit`** | Parameter-Bug mit K2.5 |
| **Always `read` first** | Nie blind schreiben |
| **Live updates every 20-30s** | Transparency, early feedback |
| **Always say "Fertig!"** | User muss wissen wann done |
| **Validate paths before write** | Safety |

### A.7 Skill Development Pattern

```
1. SKILL.md lesen (aus Template)
2. Modulare Struktur erstellen:
   skill-name/
   ├── SKILL.md           # Interface-Spezifikation
   ├── src/               # Implementation
   ├── tests/             # Unit Tests
   └── examples/          # Usage Examples
3. Tests schreiben
4. Dokumentation vervollständigen
```

### A.8 Workspace Map

| Pfad | Inhalt |
|------|--------|
| `~\.openclaw\workspace\` | OpenClaw Skills, Memory, Config |
| `~\Documents\Andrew Openclaw\` | Hauptarbeitsverzeichnis |
| `~\Documents\Andrew Openclaw\Kimi_Agent_ECC-Second-Brain-Framework Implementiert\` | ECC + Second Brain |

---

**Dokumentversion:** 2026.3.13  
**Gültig für:** OpenClaw 2026.3.13 und kompatible Versionen  
**Appendix A letzte Aktualisierung:** 2026-04-05
