# Bugfix Analysis: `[tools] edit failed: Missing required parameter: newText`

## Executive Summary

**Severity**: Medium-High  
**Type**: Parameter Naming Mismatch (Documentation vs. Implementation)  
**Impact**: Tool calls fail when parameter name doesn't match expected schema  

---

## 1. Root Cause Analysis

### 1.1 The Core Problem

The error message `Missing required parameter: newText` reveals a **parameter naming mismatch** between:

| Source | Parameter Name | Context |
|--------|---------------|---------|
| **Manifest Documentation** | `new_string` | Section 5.3: "NIE: `edit` ohne `new_string` Parameter" |
| **Error Message** | `newText` | Runtime validation error |
| **Tool Schema (implied)** | Likely `new_string` | Based on convention |

### 1.2 Evidence from Source Files

**From `/mnt/okcomputer/upload/openclaw-complete-manifest.md` (Line 233):**
```markdown
**NIE**: `edit` ohne `new_string` Parameter
```

**From `/mnt/okcomputer/upload/openclaw-multi-agent-analysis-prompt.md`:**
- Line 403: Scope explicitly mentions: `Diagnose '[tools] edit failed: Missing required parameter: newText'`
- Line 409: Investigation path says: "Identify where `new_string` parameter is missing"

### 1.3 Root Cause Hypothesis

The most likely explanations for this mismatch are:

1. **Schema Translation Layer Issue**: 
   - The tool schema defines the parameter as `new_string` (snake_case, following conventions)
   - A middleware/transformation layer converts snake_case to camelCase for some consumer
   - The error validation occurs AFTER this transformation, expecting `newText`
   - But the tool caller provides `new_string`, causing validation failure

2. **Inconsistent Schema Versions**:
   - Documentation references one version of the tool schema (`new_string`)
   - Runtime uses a different version expecting `newText`
   - This could happen during a migration or API update

3. **Hook Interference** (as suggested in analysis prompt):
   - The `review:post_execution` hook or another middleware may transform parameters
   - Hook at `hooks/review-post-execution.md` mentioned in manifest Section 8.2
   - Transformation happens before validation, causing mismatch

---

## 2. Files and Components Involved

### 2.1 Primary Documentation Files

| File | Role | Relevant Content |
|------|------|------------------|
| `openclaw-complete-manifest.md` | System documentation | Section 5.3: EDIT vs WRITE rules with `new_string` parameter |
| `openclaw-multi-agent-analysis-prompt.md` | Analysis instructions | Explicitly mentions both `newText` (error) and `new_string` (expected) |

### 2.2 Suspected Runtime Components

Based on manifest structure, the following components may be involved:

```
openclaw-workspace/
├── hooks/
│   └── review-post-execution.md    # Suspected: Parameter transformation
├── registry/
│   ├── hooks.yaml                  # Hook configuration
│   └── skills.yaml                 # Skill definitions
└── crates/
    └── tool-registry/              # Tool registry (11 tests) - Parameter validation
```

### 2.3 Hook System (Section 8.2 of Manifest)

| Hook | Trigger | Handler | Suspicion Level |
|------|---------|---------|-----------------|
| `session:start` | Session-Start | `hooks/session-start.md` | Low |
| `session:end` | Session-End | `hooks/session-end.md` | Low |
| `review:post_execution` | Nach kritischen Ops | `hooks/review-post-execution.md` | **HIGH** |

The `review:post_execution` hook is triggered "after critical operations" which likely includes file edit operations.

---

## 3. Detailed Analysis

### 3.1 Parameter Naming Convention Conflict

**Standard Convention in OpenClaw (from manifest):**
- Tool names: Case-sensitive (`read`, not `Read`) - Section 7.2
- Parameters: Likely snake_case (`new_string`)

**Error Message Convention:**
- Uses camelCase (`newText`)
- This suggests either:
  a) JavaScript/TypeScript runtime layer
  b) API gateway transformation
  c) Validation occurring after case conversion

### 3.2 Tool Call Flow Analysis

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Agent Code    │────▶│  Hook/Middleware │────▶│  Tool Registry  │
│  (uses          │     │  (transforms?)   │     │  (validates)    │
│  new_string)    │     │                  │     │  (expects       │
└─────────────────┘     └──────────────────┘     │  newText?)      │
                                                 └─────────────────┘
                                                          │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │   ERROR:        │
                                                 │  Missing        │
                                                 │  newText        │
                                                 └─────────────────┘
```

### 3.3 The "edit" Tool Requirements

From manifest Section 5.3:

| Situation | Tool | Required Parameters |
|-----------|------|---------------------|
| Neue Datei | `write` | `file_path`, `content` |
| Kleine Änderung (<10 Zeilen) | `edit` | `file_path`, `old_string`, `new_string` |
| Große Änderung / Unsicher | `write` | `file_path`, `content` |
| Kritische Dateien | Backup + `write` | - |

**Critical Rule**: "NIE: `edit` ohne `new_string` Parameter"

---

## 4. Suggested Fixes

### 4.1 Fix Option 1: Standardize on snake_case (Recommended)

**Action**: Ensure the entire pipeline uses `new_string`

**Steps**:
1. Update validation schema to expect `new_string`
2. Remove any camelCase transformation in hooks
3. Update error messages to reference `new_string`

**Files to modify**:
- `registry/hooks.yaml` - Check for parameter transformation rules
- `hooks/review-post-execution.md` - Remove or fix transformation
- Tool registry validation code (in `crates/tool-registry/`)

### 4.2 Fix Option 2: Standardize on camelCase

**Action**: Change documentation and tool calls to use `newText`

**Steps**:
1. Update manifest Section 5.3 to reference `newText`
2. Update all skill documentation using `edit` tool
3. Ensure tool registry expects `newText`

**Risk**: Breaking change for existing skills and agent code

### 4.3 Fix Option 3: Support Both (Backward Compatible)

**Action**: Accept both `new_string` and `newText` as aliases

**Steps**:
1. Modify validation to accept either parameter name
2. Log deprecation warning for non-preferred name
3. Document the preferred name

**Benefit**: No breaking changes

---

## 5. Prevention Measures

### 5.1 Schema Validation Testing

```rust
// Suggested test for tool-registry crate
#[test]
fn test_edit_tool_parameter_names() {
    let schema = ToolRegistry::get_schema("edit");
    assert!(schema.has_parameter("new_string"));
    // OR if using camelCase:
    // assert!(schema.has_parameter("newText"));
}
```

### 5.2 Documentation Synchronization Check

Create a CI/CD check that:
1. Extracts parameter names from tool schemas
2. Compares with documentation
3. Fails build on mismatch

### 5.3 Hook Testing

For each hook in `hooks/`:
1. Test parameter transformation (if any)
2. Verify parameter names are preserved correctly
3. Add regression test for this specific bug

### 5.4 Convention Enforcement

Establish and document:
- **Parameter naming convention**: snake_case vs camelCase
- **When to transform**: Never, at gateway, or at tool boundary
- **Error message format**: Should match expected parameter name

---

## 6. Investigation Checklist

To fully resolve this issue, the following should be investigated:

- [ ] Check `registry/hooks.yaml` for parameter transformation rules
- [ ] Read `hooks/review-post-execution.md` for transformation logic
- [ ] Examine `crates/tool-registry/` validation code
- [ ] Review actual tool schema definition (likely in Rust or TypeScript)
- [ ] Check if `new_string` vs `newText` appears in other tool parameters
- [ ] Verify all 60+ tests in Rust crates pass (mentioned in manifest Section 8.3)
- [ ] Search logs for actual occurrences of this error

---

## 7. Related Findings from Multi-Agent Analysis

The analysis prompt (Section "For the 'edit failed' Bug") explicitly calls out:

> **Dedicated Agent**: `bugfix-investigator`  
> **Scope**: Diagnose `[tools] edit failed: Missing required parameter: newText`

This suggests:
1. The bug is known and has been observed
2. It's significant enough to warrant dedicated investigation
3. The mismatch between `new_string` (documentation) and `newText` (error) is the key clue

---

## 8. Conclusion

The `edit failed: Missing required parameter: newText` bug is caused by a **parameter naming mismatch** between:
- **Documentation/Manifest**: Uses `new_string` (snake_case)
- **Runtime Validation**: Expects `newText` (camelCase)

**Most Likely Root Cause**: A transformation layer (possibly in hooks or middleware) converts parameter names from snake_case to camelCase, but the validation layer expects the original name or vice versa.

**Recommended Fix**: Standardize on one naming convention throughout the entire pipeline (preferably snake_case to match existing documentation) and remove any unnecessary transformation layers.

**Immediate Action**: Investigate `hooks/review-post-execution.md` and `registry/hooks.yaml` for parameter transformation logic.

---

*Analysis completed by: Bugfix Investigator Agent*  
*Based on: openclaw-complete-manifest.md and openclaw-multi-agent-analysis-prompt.md*
