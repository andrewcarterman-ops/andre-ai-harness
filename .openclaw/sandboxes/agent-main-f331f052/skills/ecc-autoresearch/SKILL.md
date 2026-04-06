---
name: ecc-autoresearch
description: |
  Sichere autonome Forschung mit ECC-Framework.
  Wie autoresearch, aber mit ECC-Sicherheitsgarantien und Human-in-Loop.
  
  Use WHEN: Running autonomous AI research experiments with safety constraints.
  
version: "1.0.0"
author: "Andrew (ECC Framework)"
requires:
  - python >= 3.10
  - git
  - ecc-security-module
safety_level: "guarded_autonomy"
---

# ECC-Autoresearch: Guarded Autonomy

> **Prinzip:** Autonome Forschung mit ECC-Sicherheitsgarantien  
> **Motto:** "Trust but verify. Automate but monitor."

---

## 🚀 Quick Start

```bash
# 1. Initialisierung
python ecc-autoresearch.py --init --project "my-experiment"

# 2. Human-Approval für Plan einholen
# (Agent wartet auf Bestätigung)

# 3. Autonomer Loop starten
python ecc-autoresearch.py --run --max-iterations 100
```

---

## 📋 Setup Phase

### Voraussetzungen prüfen

```powershell
# ECC-Module müssen geladen sein
Import-Module SecureCredential.psm1
Import-Module Logging.psm1
Import-Module ErrorHandler.psm1
```

### Schritt-für-Schritt

1. **Projekt-Tag definieren**
   ```bash
   TAG=$(date +%b%d | tr '[:upper:]' '[:lower:]')  # z.B. "mar31"
   BRANCH="ecc-autoresearch/${TAG}"
   ```

2. **Sandbox initialisieren**
   ```bash
   git checkout -b "${BRANCH}"
   
   # Safety-Config erstellen
   cat > .ecc-safety.yaml << EOF
   allowed_imports:
     - torch
     - numpy
     - pandas
   forbidden_patterns:
     - eval\s*\(
     - exec\s*\(
     - __import__
     - subprocess
   resource_limits:
     max_runtime_minutes: 5
     max_memory_gb: 50
     max_disk_gb: 10
   network_policy:
     allowed_hosts:
       - huggingface.co
       - download.pytorch.org
   EOF
   ```

3. **Daten prüfen**
   ```bash
   if [ ! -d "~/.cache/autoresearch" ]; then
       echo "⚠️  Daten nicht gefunden. Running prepare.py..."
       uv run prepare.py
   fi
   ```

4. **Initialen Plan vom Menschen bestätigen lassen**
   ```markdown
   ## 📝 Experiment-Plan
   
   **Ziel:** [val_bpb minimieren]
   **Strategie:** [Hyperparameter-Tuning / Architektur / Optimizer]
   **Erwartung:** [Was sollte passieren?]
   **Risiko:** [Was könnte schiefgehen?]
   
   👉 **Bitte bestätigen mit:** `ecc-autoresearch --approve-plan`
   ```

5. **Results-Tracking initialisieren**
   ```bash
   cat > results.tsv << EOF
   commit	val_bpb	memory_gb	status	description	safety_score
   EOF
   ```

---

## 🔄 Der Guarded Experiment-Loop

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    GUARDED EXPERIMENT LOOP                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────┐                                                         │
│  │ 1. ANALYZE  │ ← Current State (Git, Results, Metrics)                │
│  └──────┬──────┘                                                         │
│         │                                                                │
│  ┌──────▼──────┐                                                         │
│  │ 2. HYPOTHESIS│ ← Generate experimental idea                          │
│  │   GENERATE  │   "What could improve val_bpb?"                        │
│  └──────┬──────┘                                                         │
│         │                                                                │
│  ┌──────▼──────┐     ┌─────────────────────────────────────────────┐    │
│  │ 3. SAFETY   │────→│ 🔒 SECURITY CHECKPOINT                      │    │
│  │    CHECK    │     │                                              │    │
│  └──────┬──────┘     │ ✓ Code Analysis: Forbidden patterns?        │    │
│         │            │ ✓ Import Check: Only allowed modules?       │    │
│  ┌──────▼──────┐     │ ✓ Path Check: Within sandbox?               │    │
│  │ 4. CODE     │     │ ✓ Network Check: Whitelisted hosts only?    │    │
│  │   MODIFY    │     │                                              │    │
│  └──────┬──────┘     │ IF FAIL:                                    │    │
│         │            │   → Log violation                           │    │
│  ┌──────▼──────┐     │   → Skip to next hypothesis                 │    │
│  │ 5. COMMIT   │     │   → Alert human if critical                │    │
│  │   (Git)     │     └─────────────────────────────────────────────┘    │
│  └──────┬──────┘                                                         │
│         │                                                                │
│  ┌──────▼──────┐                                                         │
│  │ 6. EXECUTE  │ ← uv run train.py (Sandboxed)                          │
│  │   (5 min)   │                                                          │
│  └──────┬──────┘                                                         │
│         │                                                                │
│  ┌──────▼──────┐     ┌─────────────────────────────────────────────┐    │
│  │ 7. RESULTS  │────→│ ⏱️  RESOURCE GUARD                          │    │
│  │   EXTRACT   │     │                                              │    │
│  └──────┬──────┘     │ ✓ Runtime > 10min? → KILL & CRASH          │    │
│         │            │ ✓ Memory > 50GB? → KILL & CRASH             │    │
│     ┌───┴───┐        │ ✓ Disk > 10GB? → KILL & CRASH               │    │
│     │       │        │                                              │    │
│     ▼       ▼        └─────────────────────────────────────────────┘    │
│ ┌───────┐ ┌───────┐                                                      │
│ │BETTER?│ │CRASH? │                                                      │
│ │KEEP ✓ │ │RESET ✗│                                                      │
│ │       │ │       │                                                      │
│ │Advance│ │Log &  │                                                      │
│ │Branch │ │Skip   │                                                      │
│ └───────┘ └───────┘                                                      │
│                                                                          │
│  ┌─────────────┐                                                         │
│  │ 8. OBSIDIAN │ ← Sync to Second Brain                                  │
│  │    SYNC     │   (Experiment-Note + Dashboard)                         │
│  └─────────────┘                                                         │
│                                                                          │
│  🔁 LOOP (max 100 iterations OR 8 hours OR manual stop)                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🛡️ Safety-Rules (HART)

### 🔴 VERBOTEN (Auto-Reset bei Verstoß)

```yaml
forbidden_patterns:
  code_execution:
    - eval\s*\(
    - exec\s*\(
    - compile\s*\(
    - __import__\s*\(
    
  system_access:
    - subprocess
    - os\.system
    - os\.popen
    - os\.spawn
    
  network:
    - socket\.socket
    - urllib\.request
    - requests\.(get|post|put|delete)
    - http\.client
    
  filesystem:
    - open\s*\([^)]*['"]~\/\.
    - shutil\.rmtree\s*\(['"]~\/\.
    - os\.remove\s*\(['"]~\/\.
    
  injection:
    - f["'].*\{.*user.*\}.*["']
    - \$\{.*user.*\}
```

### 🟡 ERLAUBT (Monitored)

```yaml
allowed_operations:
  - torch.*          # PyTorch-Operationen
  - numpy.*          # Numerische Berechnungen
  - pandas.*         # Datenverarbeitung
  - json.*           # JSON-Handling
  - re.*             # Regex
  - math.*           # Mathematik
  - os.path.join     # Pfad-Konstruktion (safe)
  - open()           # File-IO (sandboxed paths only)
```

### 🟢 SICHER (Unrestricted)

```yaml
safe_operations:
  - Lokale Mathematik
  - Tensor-Operationen
  - Logging
  - Git-Operationen (im Repo)
  - TSV-Datei-Updates
```

---

## 🚨 Human-in-Loop Trigger

Der Agent PAUSIERT und fragt den Menschen bei:

| Situation | Aktion |
|-----------|--------|
| **Erstes Experiment** | ✋ Warte auf Plan-Bestätigung |
| **Safety Violation** | 🚨 Sofort-Alert + Pause |
| **10 Iterationen erreicht** | 📋 Zusammenfassung + Frage: Weiter? |
| **8 Stunden Laufzeit** | ⏰ Timeout + Zusammenfassung |
| **Neue Dependency nötig** | 🚫 VERBOTEN - Workaround finden |
| **Crash nach 3 Versuchen** | 🔄 Skip + Mensch informieren |
| **Drastische Änderung** (>100 Zeilen) | ⚠️ Bestätigung einholen |

---

## 📝 Logging & Audit

### Strukturiertes Logging

```python
# Jede Aktion wird geloggt:
{
  "timestamp": "2026-03-31T01:45:00Z",
  "level": "INFO|WARN|ERROR|SAFETY",
  "component": "ExperimentLoop|SafetyCheck|Git|Execution",
  "action": "code_modify|safety_check|experiment_run",
  "details": {
    "commit_hash": "a1b2c3d",
    "val_bpb": 0.9979,
    "safety_score": 100,
    "forbidden_patterns_found": []
  },
  "git_state": {
    "branch": "ecc-autoresearch/mar31",
    "commit": "a1b2c3d"
  }
}
```

### Audit-Trail

```bash
# Alle Aktionen nachvollziehbar:
~/.ecc-autoresearch/
├── audit/
│   ├── 2026-03-31-experiments.jsonl
│   ├── safety-violations.log
│   └── resource-usage.csv
├── experiments/
│   ├── exp-001-a1b2c3d/
│   ├── exp-002-b2c3d4e/
│   └── ...
└── snapshots/
    ├── train.py.baseline
    ├── train.py.best
    └── train.py.latest
```

---

## 🎯 Never-Stop Policy (Modified)

> **Original autoresearch:** "Never stop until manually interrupted"

> **ECC-Version:** "Continue autonomously UNLESS:"

```yaml
stop_conditions:
  hard_limits:
    max_iterations: 100
    max_runtime_hours: 8
    max_consecutive_crashes: 5
    
  safety_violations:
    any_forbidden_pattern_detected: true
    unauthorized_network_access: true
    filesystem_escape_attempt: true
    
  human_signals:
    stop_command_received: true
    pause_command_received: true
    
  resource_exhaustion:
    disk_space_low: "< 5GB free"
    memory_pressure: "system unstable"
```

---

## 📊 Results Format (Erweitert)

```tsv
commit	val_bpb	memory_gb	status	description	safety_score	iteration	timestamp	duration_sec
a1b2c3d	0.997900	44.0	keep	baseline	100	1	2026-03-31T01:00:00	300
b2c3d4e	0.993200	44.2	keep	increase LR to 0.04	100	2	2026-03-31T01:05:00	300
c3d4e5f	0.000000	0.0	crash	OOM - too wide	95	3	2026-03-31T01:10:00	45
d4e5f6g	0.994500	43.8	discard	minor change	100	4	2026-03-31T01:15:00	300
```

**Neue Spalten:**
- `safety_score`: 0-100 (Code-Safety-Bewertung)
- `iteration`: Laufende Nummer
- `timestamp`: ISO-8601
- `duration_sec`: Tatsächliche Laufzeit

---

## 🔧 Integration mit ECC

### ECC-Module Nutzung

```powershell
# In jedem Experiment:
Import-Module SecureCredential.psm1  # API-Key Management
Import-Module Logging.psm1           # Structured Logging
Import-Module Encryption.psm1        # Experiment-Verschlüsselung
Import-Module ErrorHandler.psm1      # Graceful Degradation
```

### ECC-Health-Check vor Start

```powershell
# Prüft:
✓ Vault-Zugriff
✓ Git-Status
✓ Sicherheits-Module geladen
✓ Netzwerk-Konnektivität (nur Whitelist)
✓ Ressourcen-Verfügbarkeit
```

---

## 🎓 Best Practices

### Für den Agent:

1. **Einfachheit vor Komplexität**
   - 0.001 Verbesserung mit 20 Zeilen hacky Code → **discard**
   - 0.001 Verbesserung durch Löschen von Code → **keep!**

2. **Inkrementelle Änderungen**
   - Lieber 10 kleine Experimente als 1 großes
   - Jede Änderung isoliert testen

3. **Dokumentation**
   - Jede Änderung im Git-Commit erklären
   - TSV-Beschreibung aussagekräftig halten

4. **Respektiere Constraints**
   - prepare.py ist HEILIG (read-only)
   - 5 Minuten sind 5 Minuten (nicht 6)
   - VRAM-Limit ist Soft, aber beachten

### Für den Menschen:

1. **Regelmäßige Checks**
   - Dashboard täglich prüfen
   - Bei Safety-Alerts sofort reagieren

2. **Review wichtiger Änderungen**
   - Beste Experimente manuell verifizieren
   - Code-Qualität bewerten

3. **Backup-Strategie**
   - Git-Branch regelmäßig pushen
   - Vault-Backup nicht vergessen

---

## 🚦 Schnellreferenz

```bash
# Start
python ecc-autoresearch.py --init --project "mar31-gpt"

# Plan bestätigen
python ecc-autoresearch.py --approve-plan

# Loslegen
python ecc-autoresearch.py --run --max-iterations 50

# Status checken
python ecc-autoresearch.py --status

# Pausieren
python ecc-autoresearch.py --pause

# Fortsetzen
python ecc-autoresearch.py --resume

# Stoppen
python ecc-autoresearch.py --stop

# Dashboard öffnen
python ecc-autoresearch.py --dashboard
```

---

## 📚 Referenzen

- **Original:** https://github.com/karpathy/autoresearch
- **ECC Framework:** `~/Documents/Andrew Openclaw/Kimi_Agent_ECC-Second-Brain-Framework/`
- **Safety Module:** `~/.openclaw/workspace/skills/security-review/`

---

*Version: 1.0.0*  
*Last Updated: 2026-03-31*  
*Author: Andrew (ECC Framework)*
