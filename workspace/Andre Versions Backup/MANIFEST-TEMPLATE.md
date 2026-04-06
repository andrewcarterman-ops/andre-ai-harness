# OpenClaw Manifest Template

> **Template-Version**: 1.0  
> **Zweck**: Standardisierte Selbst-Dokumentation für Andrew AI-Agent  
> **Verwendung**: Vor Erstellung neuer Manifests dieses Template lesen

---

## CHECKLISTE: Vor Manifest-Erstellung

- [ ] Aktuelle Registry-Dateien lesen (`registry/agents.yaml`, `registry/skills.yaml`, `registry/hooks.yaml`)
- [ ] Aktuelle MEMORY.md lesen
- [ ] Tägliche Logs der letzten 7 Tage prüfen (`memory/2026-*.md`)
- [ ] Cron-Jobs prüfen (`openclaw cron list`)
- [ ] Workspace-Struktur verifizieren (`ls -la` bzw. `Get-ChildItem`)
- [ ] Skills-Verzeichnis scannen (`skills/*/SKILL.md`)
- [ ] Sub-Agenten prüfen (`agents/*.md`)
- [ ] API-Keys/Tokens auf [REDACTED] prüfen!

---

## ABSCHNITTE (immer in dieser Reihenfolge)

### 1. SYSTEM IDENTITÄT

**Quellen**: `SOUL.md`, `IDENTITY.md`

**Erfassen**:
- Name, Creature, Emoji
- Persönlichkeitsprofil (Bullet-Points)
- Kommunikationsstil
- Vibe/Zusammenfassung

**Template**:
```markdown
**Name**: [Aus IDENTITY.md]
**Creature**: [Aus IDENTITY.md]
**Emoji**: [Aus IDENTITY.md]
**Agent-ID**: [Aus registry/agents.yaml]

**Persönlichkeitsprofil** (aus SOUL.md):
- [Bullet-Points aus SOUL.md]

**Vibe**: [SOUL.md Zusammenfassung]
```

---

### 2. TOOLING & INFRASTRUKTUR

**Quellen**: `TOOLS.md`, Runtime-Info, Skill-Registry

**Erfassen**:
- Alle APIs (OHNE Keys!)
- Aktive Channels
- Modelle & Konfiguration
- Sub-Agenten aus `registry/agents.yaml`

**Template**:
```markdown
### 2.1 APIs & Externe Services (ohne Keys)

| Service | Zweck | Konfiguration |
|---------|-------|---------------|
| [Service] | [Zweck] | [Tool/Config] |

### 2.2 Aktive Channels

| Channel | Typ | Status |
|---------|-----|--------|
| [Channel] | [Typ] | [Status] |

### 2.3 Modelle & Konfiguration

**Default Model**: [Aus Runtime]
**Alternative**: [Falls vorhanden]

### 2.4 Sub-Agenten

| Agent | Emoji | Zweck | Trigger-Phrasen |
|-------|-------|-------|-----------------|
| [Agent] | [Emoji] | [Zweck] | [Triggers] |
```

---

### 3. SKILL REPERTOIRE

**Quelle**: `registry/skills.yaml`

**Erfassen**:
- Alle Skills aus skills.yaml
- Kategorie, Funktion, Trigger
- Workflow-Chains

**Template**:
```markdown
### 3.1 Übersicht: [N] Skills installiert

| Skill | Kategorie | Funktion | Trigger |
|-------|-----------|----------|---------|
| [skill-id] | [category] | [description] | [triggers] |

### 3.2 Skill-Kategorien

```
[category] → [skill1], [skill2]
```

### 3.3 Workflow-Chains

**[Chain-Name]**:
```
[step1] → [step2] → [step3]
```
```

---

### 4. MEMORY STATE

**Quellen**: `USER.md`, `MEMORY.md`, `memory/YYYY-MM-DD.md`

**Erfassen**:
- User-Kontext (Name, Zeitzone, etc.)
- Gespeicherte Erkenntnisse (MEMORY.md Highlights)
- Tägliche Logs (Liste der letzten 7-14 Tage)
- Second Brain Struktur (falls vorhanden)

**Template**:
```markdown
### 4.1 User-Kontext (USER.md)

**Name**: [Name]
**Anrede**: [Anrede]
**Zeitzone**: [Timezone]
**Erster Kontakt**: [Datum]

### 4.2 Gespeicherte Erkenntnisse (MEMORY.md)

**[Thema]** (Datum):
1. [Erkenntnis 1]
2. [Erkenntnis 2]

### 4.3 Tägliche Logs

**Speicherort**: `memory/YYYY-MM-DD.md`

Aktuelle Logs:
- `[YYYY-MM-DD].md` — [Zusammenfassung]

### 4.4 Zweit-Gehirn (Second Brain)

**Struktur**:
```
second-brain/
├── 1-Projects/
├── 2-Areas/
├── 3-Resources/
└── 4-Archive/
```
```

---

### 5. DENKLOGIK & WORKFLOWS

**Quellen**: `AGENTS.md`, `SOUL.md`, Skill-Dokumentationen

**Erfassen**:
- Session Startup Prozess
- Entscheidungsfindung
- File Operations Regeln
- Memory Management
- Group Chat Verhalten

**Template**:
```markdown
### 5.1 Session Startup

**Automatisch**:
1. [Schritt 1]
2. [Schritt 2]

### 5.2 Entscheidungsfindung

**Skill-Auswahl**:
1. [Regel 1]
2. [Regel 2]

**Extern vs. Intern**:
- ✅ [Was ist sicher]
- ⚠️ [Was fragwürdig ist]
- 🚫 [Was verboten ist]

### 5.3 File Operations

| Situation | Tool | Begründung |
|-----------|------|------------|
| [Situation] | [Tool] | [Grund] |

### 5.4 Memory Management

**Text > Brain**: [Erklärung]

### 5.5 Group Chat Verhalten

**Sprechen wenn**: [Bedingungen]
**Schweigen wenn**: [Bedingungen]
```

---

### 6. DATEISTRUKTUR

**Quelle**: Aktuelles Filesystem

**Erfassen**:
- Vollständige Verzeichnisstruktur
- Wichtige Pfade
- Externe Projektverzeichnisse
- Netzwerk/Remote Hosts

**Template**:
```markdown
### 6.1 OpenClaw Workspace

```
C:\Users\[user]\.openclaw\workspace\
├── [Datei/Verzeichnis]
└── ...
```

### 6.2 Externe Projekt-Verzeichnisse

```
C:\Users\[user]\Documents\...
```

### 6.3 Netzwerk / Remote

| Host | Adresse | Zweck |
|------|---------|-------|
| [Host] | [IP/Adresse] | [Zweck] |
```

---

### 7. SYSTEM PROMPT KERNELEMENTE

**Quellen**: System-Dokumentation, AGENTS.md

**Erfassen**:
- Unveränderliche Verhaltensregeln
- Tool-Usage Regeln
- Skill-System
- Memory Recall
- Safety & Boundaries
- Cron & Heartbeats
- ACP Harness

**Template**:
```markdown
### 7.1 Unveränderliche Verhaltensregeln

1. [Regel 1]
2. [Regel 2]

### 7.2 Tool-Usage Regeln

[Regeln]

### 7.3 Skill-System (Mandatory)

[Prozess]

### 7.4 Memory Recall (Mandatory)

[Prozess]

### 7.5 Safety & Boundaries

[Grenzen]

### 7.6 Cron & Heartbeats

[Erklärung]

### 7.7 ACP Harness

[Regeln]
```

---

### 8. TECHNISCHE SPEZIFIKATIONEN

**Quelle**: Runtime-Info, System-Status

**Template**:
```markdown
### 8.1 Runtime-Information

| Attribut | Wert |
|----------|------|
| Agent | [agent] |
| Host | [host] |
| OS | [os] |
| Node.js | [version] |
| Shell | [shell] |
| Channel | [channel] |

### 8.2 Hooks

| Hook | Trigger | Handler |
|------|---------|---------|
| [hook] | [trigger] | [handler] |

### 8.3 Rust Crates / Sonstige

| Crate | Zweck | Status |
|-------|-------|--------|
| [crate] | [zweck] | [status] |
```

---

### 9. REPLIKATIONS-CHECKLISTE

**Template**:
```markdown
### Phase 1: Basis-Setup
- [ ] OpenClaw Gateway installieren
- [ ] Workspace-Verzeichnis erstellen
- [ ] Basis-MD-Dateien erstellen

### Phase 2: Registry
- [ ] agents.yaml
- [ ] skills.yaml
- [ ] hooks.yaml

### Phase 3: Skills
- [ ] Alle Skills installieren

### Phase 4: Sub-Agenten
- [ ] Agent-Definitionen erstellen

### Phase 5: Second Brain (Optional)
- [ ] PARA-Struktur einrichten

### Phase 6: Testing
- [ ] Test-Session
- [ ] Skill-Trigger testen
```

---

### 10. CHANGELOG

**Template**:
```markdown
| Datum | Änderung |
|-------|----------|
| [YYYY-MM-DD] | [Änderung] |
```

---

## DATEINAMEN-KONVENTION

**Format**: `openclaw-manifest-YYYY-MM-DD-v[X.Y].md`

**Beispiele**:
- `openclaw-manifest-2026-04-02-v2.0.md`
- `openclaw-manifest-2026-04-15-v2.1.md`

**Speicherort**: `C:\Users\andre\.openclaw\workspace\Andre Versions Backup\`

---

## POST-CREATION CHECKLIST

Nach Erstellung des Manifests:

- [ ] Datei auf [REDACTED] für API-Keys durchsuchen
- [ ] Pfade verifizieren (echte Windows-Pfade?)
- [ ] Formatierung prüfen (Tabellen, Code-Blocks)
- [ ] Größe checken (< 100 KB ideal)
- [ ] Im Zielverzeichnis speichern
- [ ] In MEMORY.md das Backup dokumentieren

---

*Template zuletzt aktualisiert: 2026-04-02*