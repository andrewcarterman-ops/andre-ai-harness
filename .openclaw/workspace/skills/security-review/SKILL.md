---
name: security-review
description: |
  Automated security analysis skill for code repositories (Python, PowerShell, JavaScript, and more).
  
  Use WHEN: Analyzing code for security vulnerabilities, reviewing repositories
  for security risks, auditing dependencies, or assessing execution safety.
  
  Trigger phrases: "security audit", "analyze security", "security review",
  "check for vulnerabilities", "is this code safe", "security analysis",
  "audit repository", "security check"

category: security
tags:
  - security
  - audit
  - review
  - vulnerability
  - code-analysis
  - powershell
  - python
  - javascript

metadata:
  version: "2.0"
  author: "Andrew"
  requires: [read, write, web_fetch, web_search, exec]
---

# Security Review Skill

Automated security analysis for code repositories with intelligent language detection.

## ⚡ Quick Start

```yaml
security_review:
  target: "path/to/project"
  mode: quick          # quick | standard | deep
  max_files: 10        # Prevent timeout on large repos
```

## 🔍 Pre-Flight Check (AUTOMATIC)

**BEFORE** analysis, the skill automatically:

1. **Detects Primary Language** - Counts files by extension
2. **Estimates Scope** - Checks file count and total size
3. **Selects Strategy** - Adapts analysis depth

### Language Detection

| Extension | Language | Detection Pattern |
|-----------|----------|-------------------|
| `.py` | Python | Primary if >50% of code files |
| `.ps1`, `.psm1` | PowerShell | Primary if >50% of code files |
| `.js`, `.ts` | JavaScript/TypeScript | Primary if >50% of code files |
| `.go` | Go | Primary if >50% of code files |
| `.rs` | Rust | Primary if >50% of code files |

### Scope Assessment

| Files Found | Recommended Mode | Max Files | Estimated Time |
|-------------|------------------|-----------|----------------|
| 1-5 | deep | all | 2-3 min |
| 6-20 | standard | 10 | 5-8 min |
| 21-50 | quick | 10 | 3-5 min |
| 50+ | quick | 5 | 2-3 min |

## 🛡️ Security Patterns by Language

### Python

| Risk Category | Dangerous Patterns | Safe Alternatives |
|--------------|-------------------|-------------------|
| Code Injection | `eval()`, `exec()`, `compile()` | `ast.literal_eval()`, parsers |
| Command Execution | `os.system()`, `subprocess.call()` | `subprocess.run()` with validation |
| Dynamic Import | `__import__()` | Static imports |
| Deserialization | `pickle.load()`, `yaml.load()` | `json.load()`, `yaml.safe_load()` |
| Path Traversal | `open("/data/" + user_input)` | `pathlib.Path` with validation |

### PowerShell

| Risk Category | Dangerous Patterns | Safe Alternatives |
|--------------|-------------------|-------------------|
| Code Injection | `Invoke-Expression`, `iex` | Direct cmdlet calls |
| Command Execution | `Start-Process` without validation | Validated parameters |
| Script Block | `[ScriptBlock]::Create()` | Static script blocks |
| Download & Execute | `IEX (Invoke-WebRequest)` | Download + verify + execute separately |
| Dynamic Loading | `Import-Module` with paths | Module name validation |

### JavaScript/TypeScript

| Risk Category | Dangerous Patterns | Safe Alternatives |
|--------------|-------------------|-------------------|
| Code Injection | `eval()`, `new Function()` | JSON.parse(), static functions |
| Command Execution | `child_process.exec()` | `child_process.spawn()` with validation |
| Prototype Pollution | `obj[key] = value` unchecked | Key validation |
| Path Traversal | `fs.readFile(path)` | Path validation with `path.resolve()` |

## 📊 Risk Levels

| Level | Description | Action Required |
|-------|-------------|-----------------|
| 🟢 NONE | No security concerns | None |
| 🟢 LOW | Minor concerns, well-controlled | Document |
| 🟡 MEDIUM | Moderate risk, needs attention | Review |
| 🟠 HIGH | Significant security risk | Fix before use |
| 🔴 CRITICAL | Immediate security threat | Do not use |

## 🔧 Usage Modes

### Mode: quick (DEFAULT)

```yaml
security_review:
  target: "path/to/project"
  mode: quick
  max_files: 10
```

- Analyzes only entry points and largest files
- Focuses on high-risk patterns
- **Time: 2-5 minutes**

### Mode: standard

```yaml
security_review:
  target: "path/to/project"
  mode: standard
  max_files: 20
```

- Analyzes top 20 files by size/importance
- Checks all security categories
- **Time: 5-10 minutes**

### Mode: deep

```yaml
security_review:
  target: "path/to/project"
  mode: deep
  max_files: 50
```

- Analyzes up to 50 files
- Full dependency audit
- **Time: 10-30 minutes**

## ✅ Security Checklists

### Python Checklist

- [ ] No `eval()` or `exec()` usage
- [ ] No `os.system()` or unvalidated `subprocess` calls
- [ ] No dynamic `__import__()` with user input
- [ ] All file paths validated (no traversal)
- [ ] All network requests have timeouts
- [ ] No hardcoded secrets or credentials
- [ ] Pickle/yaml usage reviewed
- [ ] No infinite loops without safeguards

### PowerShell Checklist

- [ ] No `Invoke-Expression` or `iex` with user input
- [ ] No `Start-Process` with unsanitized arguments
- [ ] No `[ScriptBlock]::Create()` with dynamic content
- [ ] No `IEX (Invoke-WebRequest)` patterns
- [ ] Execution policy considerations documented
- [ ] No hardcoded credentials in scripts
- [ ] Paths validated before use

### JavaScript Checklist

- [ ] No `eval()` or `new Function()` usage
- [ ] No `child_process.exec()` with concatenated strings
- [ ] No `__proto__` or `constructor` manipulation
- [ ] All `require()`/`import()` validated
- [ ] No prototype pollution vulnerabilities
- [ ] No hardcoded API keys or secrets

## 📋 Analysis Report Format

```markdown
## Security Analysis: {target}

### Pre-Flight Summary
- **Primary Language:** {detected_language}
- **Files Analyzed:** {count}/{total}
- **Analysis Mode:** {mode}
- **Overall Risk:** {LEVEL}

### Executive Summary
- Critical Issues: {count}
- High Issues: {count}
- Medium Issues: {count}
- Low Issues: {count}

### Language-Specific Findings

#### {File} (Risk: {LEVEL})
**Lines:** {start}-{end}
**Issue:** {description}
**Pattern:** `{dangerous_code}`
**Recommendation:** {safe_alternative}

### Safe Patterns Found
- ✅ {pattern_description}

### Recommendations
1. {priority_recommendation}
```

## 🚀 Best Practices

### To Prevent Timeouts

1. **Always use `mode: quick` first** on unknown repositories
2. **Set `max_files`** explicitly (default: 10)
3. **Use subagent with timeout** for large repos:
   ```yaml
   timeoutSeconds: 180  # 3 minutes
   ```

### Pre-Check Commands

```powershell
# PowerShell - Check what files exist before analysis
Get-ChildItem -Recurse | Group-Object Extension | Sort-Object Count

# Python example - Quick file count
python -c "import os; files=[f for r,_,fs in os.walk('.') for f in fs if f.endswith('.py')]; print(len(files))"
```

## 🔄 Workflow

```
1. USER: "Analyze security of X"
2. AGENT: Pre-flight check (detect language, count files)
3. AGENT: Report detected language + recommended mode
4. AGENT: Run analysis with appropriate limits
5. AGENT: Deliver structured report
```

## 📝 Examples

### Example 1: Python Quick Scan

```yaml
Target: "~/projects/myapp"
Detected: Python (85% of 23 files)
Mode: quick
Max Files: 10

Findings:
  - ⚠️  pickle.load() in utils.py:42
  - ✅  All network calls have timeouts
  - ✅  No eval/exec found
```

### Example 2: PowerShell Detected

```yaml
Target: "~/projects/ecc-framework"
Detected: PowerShell (92% of 30 files)
Mode: quick
Max Files: 10

⚠️  Language mismatch: Expected Python, found PowerShell
Analysis adapted for PowerShell patterns.

Findings:
  - ⚠️  Invoke-Expression in deploy.ps1:15
  - ✅  No hardcoded credentials
```

## 🎯 Quick Reference: Dangerous Patterns

### Python
```python
# ❌ NEVER
eval(user_input)
exec(code)
os.system(f"rm {user_path}")
pickle.loads(untrusted_data)

# ✅ SAFE
ast.literal_eval(safe_input)
subprocess.run(["rm", validated_path], check=True)
json.loads(trusted_data)
```

### PowerShell
```powershell
# ❌ NEVER
Invoke-Expression $userInput
IEX (Invoke-WebRequest $url).Content
Start-Process "cmd.exe" "/c $args"

# ✅ SAFE
& $validatedCommand @validatedArgs
Invoke-WebRequest $url -OutFile $tempPath
# Validate before execution
```

### JavaScript
```javascript
// ❌ NEVER
eval(userInput)
child_process.exec("ls " + userPath)
obj[userKey] = value  // Without validation

// ✅ SAFE
JSON.parse(userInput)
child_process.spawn("ls", [validatedPath])
if (isValidKey(userKey)) obj[userKey] = value
```

## 📚 References

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- CWE/SANS Top 25: https://cwe.mitre.org/top25/
- Python Security: https://python-security.readthedocs.io/
- PowerShell Security: https://docs.microsoft.com/en-us/powershell/scripting/security/
- Node.js Security: https://nodejs.org/en/docs/guides/security/
