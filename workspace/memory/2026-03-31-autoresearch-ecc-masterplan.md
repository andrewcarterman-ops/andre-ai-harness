# Autoresearch × ECC Integration Masterplan

**Datum:** 2026-03-31  
**Vision:** Die Stärken von autoresearch (autonome Forschung) mit der Sicherheit des ECC-Frameworks verbinden

---

## TEIL 1: Sichere program.md für ECC-Agenten

### Konzept: "Guarded Autonomy"
> Wie autoresearch, aber mit ECC-Sicherheitsgarantien

```markdown
# ecc-autoresearch.md
## Sichere Autonome Forschung mit ECC-Framework

### 1. Setup Phase
- [ ] Vault-Status prüfen (ECC-Health-Check)
- [ ] Sandbox initialisieren ( isolierter Git-Branch )
- [ ] Safety-Module laden (SecureCredential, Encryption)
- [ ] Human-Approval für initialen Plan einholen

### 2. Experiment-Loop (GUARDED)
Jede Iteration durchläuft:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   IDEEN     │────→│   SAFETY    │────→│   EXEC      │
│  Generieren │     │    CHECK    │     │   (sandbox) │
└─────────────┘     └──────┬──────┘     └──────┬──────┘
                           │                    │
                    ┌──────▼──────┐     ┌──────▼──────┐
                    │  Forbidden? │     │  Timeout    │
                    │  • eval()   │     │  • 5min     │
                    │  • exec()   │     │  • Rollback │
                    │  • network  │     │  • Log      │
                    └─────────────┘     └─────────────┘
```

### 3. Safety-Rules (HART)
#### VERBOTEN (Auto-Reset):
- `eval()`, `exec()`, `compile()`
- `__import__()` mit dynamischen Strings
- `subprocess`, `os.system`
- Netzwerk-Requests ohne Whitelist
- Dateizugriff außerhalb ~/.cache/
- Shell-Injection Patterns

#### ERLAUBT (Monitored):
- Lokale Datei-Operationen
- PyTorch-Training
- Lokale Git-Operationen
- TSV-Logging

### 4. Human-in-Loop
- Bei erstem Experiment: ✋ Bestätigung
- Bei jeder Verbesserung: 📊 Notification
- Bei Crash: 🚨 Alert
- Nach 10 Iterationen: 📋 Zusammenfassung

### 5. Integration mit ECC
```powershell
# ECC-Module nutzen:
- Logging.psm1          → Structured Logging
- SecureCredential.psm1 → API-Key Management
- Encryption.psm1       → Experiment-Verschlüsselung
- ErrorHandler.psm1     → Graceful Degradation
```

### 6. Never-Stop (Modified)
> "Continue autonomously UNLESS:
> - Safety violation detected
> - Human sent stop signal
> - 100 iterations reached
> - 8 hours elapsed"

---

## TEIL 2: Safety-Mechanismen (die autoresearch fehlt)

### Aktuell in autoresearch:
```
✅ Zeit-Limit (5min)
✅ VRAM-Soft-Limit
✅ TSV-Logging
✅ Git-Versioning
```

### Fehlend / Zu ergänzen:

#### A. Code-Sandboxing
```python
# forbidden_patterns.py
FORBIDDEN_PATTERNS = [
    r'eval\s*\(',
    r'exec\s*\(',
    r'__import__\s*\(',
    r'subprocess',
    r'os\.system',
    r'os\.popen',
    r'socket\.',
    r'urllib\.request',
    r'requests\.(get|post)',
]

def safety_check(code: str) -> bool:
    for pattern in FORBIDDEN_PATTERNS:
        if re.search(pattern, code):
            return False, f"Forbidden pattern: {pattern}"
    return True, "OK"
```

#### B. Filesystem-Sandbox
```python
# allowed_paths.py
ALLOWED_PATHS = [
    "~/.cache/autoresearch/",
    "./results.tsv",
    "./run.log",
    "./train.py",
]

BLACKLISTED_PATHS = [
    "~/.ssh/",
    "~/.aws/",
    "~/.config/",
    "/etc/",
    "/usr/",
]

def validate_path(path: str) -> bool:
    resolved = Path(path).resolve()
    # Must be in allowed, not in blacklisted
    return any(resolved.startswith(a) for a in ALLOWED_PATHS) and \
           not any(resolved.startswith(b) for b in BLACKLISTED_PATHS)
```

#### C. Network-Isolation
```python
# network_policy.py
ALLOWED_HOSTS = [
    "huggingface.co",
    "download.pytorch.org",
]

def validate_url(url: str) -> bool:
    parsed = urlparse(url)
    return parsed.netloc in ALLOWED_HOSTS
```

#### D. Resource-Limits
```python
# resource_guard.py
import resource

def set_limits():
    # CPU time: 10 minutes max
    resource.setrlimit(resource.RLIMIT_CPU, (600, 600))
    # Memory: 50GB max
    resource.setrlimit(resource.RLIMIT_AS, (50 * 1024**3, 50 * 1024**3))
    # File size: 10GB max
    resource.setrlimit(resource.RLIMIT_FSIZE, (10 * 1024**3, 10 * 1024**3))
    # No core dumps
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
```

#### E. Audit-Logging
```python
# audit_logger.py
import json
from datetime import datetime

def log_action(action_type, details, result):
    audit_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "action": action_type,
        "details": details,
        "result": result,
        "git_commit": get_current_commit(),
        "git_branch": get_current_branch(),
    }
    with open("~/.cache/autoresearch/audit.log", "a") as f:
        f.write(json.dumps(audit_entry) + "\n")
```

### Implementation-Roadmap:

| Phase | Mechanismus | Aufwand | Risiko-Reduktion |
|-------|-------------|---------|------------------|
| 1 | Code-Sandboxing | 2h | 🔴→🟡 |
| 2 | Filesystem-Sandbox | 1h | 🟡→🟢 |
| 3 | Network-Isolation | 1h | 🟡→🟢 |
| 4 | Resource-Limits | 30min | 🟢→🟢 |
| 5 | Audit-Logging | 1h | 🟢→🟢 |

---

## TEIL 3: Second Brain Integration

### Vision:
> Jedes Experiment wird automatisch in Obsidian dokumentiert

### Datenfluss:
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   AUTORESEARCH  │────→│  ECC Framework   │────→│   OBSIDIAN      │
│   (Experiment)  │     │  (Processing)    │     │   (Vault)       │
└────────┬────────┘     └──────────────────┘     └─────────────────┘
         │
         ├── results.tsv ───→ PARA/Projects/Autoresearch/Results/
         │
         ├── run.log ───────→ PARA/Projects/Autoresearch/Logs/
         │
         ├── git diff ──────→ PARA/Projects/Autoresearch/Changes/
         │
         ├── val_bpb ───────→ PARA/Projects/Autoresearch/Metrics/
         │
         └── code ──────────→ PARA/Projects/Autoresearch/Snapshots/
```

### Automatische Dokumentation:

#### A. Experiment-Note (pro Run)
```markdown
---
date: 2026-03-31T01:30:00
type: experiment
status: {{keep|discard|crash}}
val_bpb: {{0.9979}}
commit: {{a1b2c3d}}
tags: autoresearch, experiment, {{architecture|optimizer|hyperparams}}
---

# Experiment {{index}}: {{description}}

## Hypothese
{{Warum wurde diese Änderung gemacht?}}

## Änderungen
```diff
{{git diff hier einfügen}}
```

## Ergebnis
- val_bpb: {{value}} ({{delta}} vs. baseline)
- memory_gb: {{value}}
- duration: {{value}}

## Analyse
{{Automatische Analyse durch Agent}}

## Nächste Schritte
{{Vorschläge für Folge-Experimente}}
```

#### B. Dashboard (täglich aktualisiert)
```markdown
---
date: 2026-03-31
type: dashboard
tags: autoresearch, overview
---

# Autoresearch Dashboard

## Fortschritt
- Total Experiments: {{count}}
- Successful: {{count}} ({{percent}}%)
- Best val_bpb: {{value}} (commit: {{hash}})
- Improvement: {{delta}} since baseline

## Trend
```mermaid
xychart-beta
    title "val_bpb over time"
    x-axis [experiment_1, experiment_2, ...]
    y-axis "val_bpb" 0.9 --> 1.1
    line [0.997, 0.993, 0.994, 0.991, ...]
```

## Aktiver Branch
- Branch: {{autoresearch/mar5}}
- Running since: {{timestamp}}
- Last commit: {{hash}}
- Status: {{running|paused|completed}}

## Insights (AI-Generated)
{{Zusammenfassung der wichtigsten Erkenntnisse}}
```

#### C. Knowledge Graph
```markdown
Jedes Experiment verlinkt:
- ← Vorheriges Experiment
- → Nächstes Experiment
- ↗ Ähnliche Experimente (gleiche Kategorie)
- ↘ Paper/Referenzen (aus program.md)
```

### Integration-Module:

```powershell
# Sync-AutoresearchToObsidian.ps1
param(
    [string]$VaultPath = "$env:USERPROFILE\Documents\Andrew Openclaw\SecondBrain",
    [string]$AutoresearchPath = "$env:USERPROFILE\Documents\Andrew Openclaw\autoresearch"
)

# 1. Parse results.tsv
$results = Import-Csv "$AutoresearchPath\results.tsv" -Delimiter "`t"

# 2. Generate Obsidian notes
foreach ($result in $results) {
    $note = Convert-ResultToMarkdown $result
    $notePath = "$VaultPath\PARA\Projects\Autoresearch\Experiments\$($result.commit).md"
    Set-Content $notePath $note
}

# 3. Update Dashboard
$dashboard = Generate-Dashboard $results
Set-Content "$VaultPath\PARA\Projects\Autoresearch\Dashboard.md" $dashboard

# 4. Update Knowledge Graph
Update-GraphLinks $results

# 5. Sync git state
Sync-GitStateToObsidian $AutoresearchPath $VaultPath
```

### Vorteile der Integration:

| Vorteil | Beschreibung |
|---------|-------------|
| **Persistenz** | Experimente überleben Git-Reset |
| **Kontext** | Historie bleibt sichtbar |
| **Insights** | AI kann Muster in Obsidian erkennen |
| **Collaboration** | Mensch kann Notizen ergänzen |
| **Search** | Volltextsuche über alle Experimente |
| **Visualization** | Mermaid-Diagramme, Dataview |

---

## ZUSAMMENFASSUNG

### Was wir bauen:
1. **Sichere program.md** → Autonomie + Sicherheit
2. **Safety-Module** → Schutz vor gefährlichem Code
3. **Obsidian-Integration** → Wissen persistieren

### Zeitaufwand:
- Teil 1: 3-4 Stunden
- Teil 2: 5-6 Stunden
- Teil 3: 4-5 Stunden
- **Gesamt: ~15 Stunden**

### Impact:
- 🔴 Risk-Reduction: Hoch
- 🟡 Knowledge Preservation: Hoch
- 🟢 Practical Utility: Sehr Hoch

---

## NÄCHSTE SCHRITTE

Wähle die Reihenfolge:
1. Sichere program.md zuerst (Foundation)
2. Safety-Mechanismen zuerst (Protection)
3. Obsidian-Integration zuerst (Value)
4. Alles parallel (Schnellster Gesamt-Impact)

Was bevorzugst du? 🎯
