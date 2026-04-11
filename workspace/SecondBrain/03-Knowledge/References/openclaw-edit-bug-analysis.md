---
date: 03-04-2026
type: reference
status: active
tags: [openclaw, bugfix, edit-tool, analysis, root-cause]
source: vault-archive/Main_Obsidian_Vault/Kimi_Agent_OpenClaw Prompt Execution/bugfix-edit-failed-analysis.md
overlap_checked: true
overlap_with: [edit-tool-workaround.md]
overlap_percentage: 10%
migration_strategy: ADD
reason: Technische Root-Cause-Analyse ergänzt den praktischen Workaround
---

# OpenClaw Edit-Tool Bug: Root Cause Analysis

> **Schweregrad**: Medium-High  
> **Typ**: Parameter Naming Mismatch (Dokumentation vs. Implementation)  
> **Impact**: Tool calls fail when parameter name doesn't match expected schema

---

## Das Kernproblem

Fehlermeldung: `[tools] edit failed: Missing required parameter: newText`

**Mismatch zwischen:**
| Quelle | Parameter Name | Kontext |
|--------|---------------|---------|
| **Manifest Dokumentation** | `new_string` | Section 5.3 |
| **Error Message** | `newText` | Runtime validation |
| **Tool Schema (impliziert)** | Likely `new_string` | Based on convention |

---

## Root Cause Hypotheses

### 1. Schema Translation Layer Issue (Wahrscheinlichst)
- Tool schema definiert Parameter als `new_string` (snake_case)
- Middleware konvertiert zu camelCase für Consumer
- Error validation erwartet `newText`, aber Tool caller sendet `new_string`

### 2. Inconsistent Schema Versions
- Dokumentation referenziert eine Version (`new_string`)
- Runtime nutzt andere Version (`newText`)
- Könnte während Migration/API Update passiert sein

### 3. Hook Interference
- `review:post_execution` hook oder andere Middleware transformiert Parameter

---

## Evidence

**Aus Manifest (Line 233):**
```markdown
**NIE**: `edit` ohne `new_string` Parameter
```

**Aus multi-agent-analysis-prompt.md:**
- Line 403: Scope erwähnt explizit: `Diagnose '[tools] edit failed: Missing required parameter: newText'`
- Line 409: "Identify where `new_string` parameter is missing"

---

## Implementierungsvorschlag

**Option C (Empfohlen): Support beide mit Deprecation**

```typescript
interface EditFileParams {
  file_path: string;
  old_string: string;
  new_string?: string;
  newText?: string;  // Deprecated
}

function validateEditParams(params: EditFileParams) {
  const newContent = params.new_string ?? params.newText;
  
  if (!newContent) {
    throw new Error('Missing required parameter: new_string (or deprecated newText)');
  }
  
  if (params.newText && !params.new_string) {
    console.warn('Deprecation warning: newText is deprecated, use new_string');
  }
  
  return { ...params, new_string: newContent };
}
```

---

## Verwandte Dokumente

- [[edit-tool-workaround|Praktischer Workaround]] → Was User JETZT tun können
- [[openclaw-renovation|Renovierung]] → Langfristige Fix-Planung
- [[openclaw-action-checklist|Action Checklist]] → Konkrete Fix-Tasks

---

**Original:** bugfix-edit-failed-analysis.md (9 KB)  
**Status**: Root-Cause identifiziert, Fix pending