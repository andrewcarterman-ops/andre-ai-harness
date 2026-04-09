# AI Agent Work Instruction: OpenClaw Edit-Tool Fix

> **Task:** Fix the systematic `new_string` parameter filtering issue  
> **Priority:** CRITICAL - Blocks file editing functionality  
> **Estimated Time:** 2-3 hours  

---

## 1. PROBLEM SUMMARY

### Symptoms
- `edit` tool fails with: `Missing required parameter: newText (newText or new_string)`
- Gateway fix already applied (splice idx, 1, alias)
- **Root cause:** Kimi K2.5 systematically filters out `new_string`/`newText` parameters
- `write` tool works fine with `content` parameter

### Evidence
```javascript
// LLM tries to send:
{ "file_path": "test.txt", "old_string": "alt", "new_string": "neu" }

// Actually sent:
{ "file_path": "test.txt", "old_string": "alt" }
// → new_string MISSING!
```

### Hypothesis
Keyword-based filter in system prompt or model behavior. "new_" prefix may be flagged.

---

## 2. SOLUTION STRATEGY

**Approach:** Rename parameter to avoid filter
- **OLD:** `new_string` (filtered)
- **NEW:** `replacement` (should work - similar to `content` in write tool)

---

## 3. IMPLEMENTATION STEPS

### Step 1: Locate Files

Find these files in the OpenClaw installation:
```
C:\Users\[USERNAME]\AppData\Roaming\npm\node_modules\openclaw\dist\
  ├── auth-profiles-*.js
  ├── discord-*.js
  ├── gateway-cli-*.js
  └── plugin-sdk\thread-bindings-*.js
```

Also check source (if available):
```
C:\Users\[USERNAME]\Documents\GitHub\openclaw-temp-fix\
  └── src\agents\pi-tools.params.ts
```

### Step 2: Identify Edit Tool Schema

Search for edit tool schema definition:
```javascript
// Look for patterns like:
const editToolSchema = {
  name: "edit",
  parameters: {
    properties: {
      path: {type: "string"},
      file_path: {type: "string"},
      oldText: {type: "string"},
      old_string: {type: "string"},
      newText: {type: "string"},
      new_string: {type: "string"}  // ← THIS IS THE PROBLEM
    },
    required: ["file_path", "old_string", "new_string"]
  }
};
```

### Step 3: Modify Parameter Names

**Option A: Add `replacement` as primary name (RECOMMENDED)**

Change the schema to use `replacement` instead of `new_string`:

```javascript
// BEFORE:
properties: {
  path: {type: "string"},
  file_path: {type: "string"},
  oldText: {type: "string"},
  old_string: {type: "string"},
  newText: {type: "string"},
  new_string: {type: "string"}
},
required: ["file_path", "old_string", "new_string"]

// AFTER:
properties: {
  path: {type: "string"},
  file_path: {type: "string"},
  search: {type: "string"},        // ← NEW: replaces old_string/oldText
  old_string: {type: "string"},    // Keep as alias
  oldText: {type: "string"},       // Keep as alias
  replacement: {type: "string"},   // ← NEW: replaces new_string/newText
  new_string: {type: "string"},    // Keep as alias
  newText: {type: "string"}        // Keep as alias
},
required: ["file_path", "search", "replacement"]  // ← Use new names
```

### Step 4: Update Parameter Normalization

Find the `normalizeToolParams` function and add mappings:

```javascript
// Add to normalizeToolParams() function:

function normalizeToolParams(toolName, params) {
  const normalized = { ...params };
  
  if (toolName === "edit") {
    // Map new parameter names to internal format
    
    // replacement → new_string (internal)
    if (params.replacement !== undefined && params.new_string === undefined) {
      normalized.new_string = params.replacement;
    }
    
    // content → new_string (internal) - for compatibility with write tool
    if (params.content !== undefined && params.new_string === undefined) {
      normalized.new_string = params.content;
    }
    
    // search → old_string (internal)
    if (params.search !== undefined && params.old_string === undefined) {
      normalized.old_string = params.search;
    }
    
    // Keep existing mappings
    if (params.file_path !== undefined && params.path === undefined) {
      normalized.path = params.file_path;
    }
    if (params.old_string !== undefined && params.oldText === undefined) {
      normalized.oldText = params.old_string;
    }
    if (params.new_string !== undefined && params.newText === undefined) {
      normalized.newText = params.new_string;
    }
  }
  
  return normalized;
}
```

### Step 5: Update Tool Description

Change the tool description to guide the LLM:

```javascript
// BEFORE:
description: "Edit a file by replacing text. Use old_string to find and new_string to replace."

// AFTER:
description: "Edit a file by replacing text. Use 'search' to find the text and 'replacement' to replace it."
```

### Step 6: Update Parameter Groups (if exists)

Find `CLAUDE_PARAM_GROUPS` or similar:

```javascript
// BEFORE:
const paramGroups = [
  {keys:["path","file_path"]},
  {keys:["oldText","old_string"]},
  {keys:["newText","new_string"], allowEmpty:true}
];

// AFTER:
const paramGroups = [
  {keys:["path","file_path"]},
  {keys:["search","old_string","oldText"]},  // Add "search"
  {keys:["replacement","new_string","newText","content"], allowEmpty:true}  // Add "replacement" and "content"
];
```

---

## 4. FILES TO MODIFY

### Primary Files (in compiled dist/)

| File | Pattern to Find | Change |
|------|-----------------|--------|
| `auth-profiles-*.js` | `new_string` in edit schema | Add `replacement` as primary |
| `discord-*.js` | `new_string` in edit schema | Add `replacement` as primary |
| `gateway-cli-*.js` | `new_string` in edit schema | Add `replacement` as primary |
| `thread-bindings-*.js` | `new_string` in paramGroups | Add `replacement` and `search` |

### Source Files (if editing source)

| File | Function/Variable | Change |
|------|-------------------|--------|
| `pi-tools.params.ts` | `CLAUDE_PARAM_GROUPS` | Add new aliases |
| `pi-tools.params.ts` | `normalizeToolParams()` | Add mapping logic |
| Tool definition file | Edit tool schema | Update required params |

---

## 5. TESTING PROCEDURE

### Test 1: Verify Schema Change

```javascript
// Check that the schema now includes "replacement"
const schema = getToolSchema("edit");
console.log(schema.parameters.properties);
// Should show: replacement, search, and all aliases
```

### Test 2: Test with replacement parameter

Ask the AI to edit a file using the new parameter names:

```
User: "Edit test.txt and change 'hello' to 'world'"

Expected AI tool call:
{
  "path": "test.txt",
  "search": "hello",
  "replacement": "world"
}

Expected result: SUCCESS
```

### Test 3: Test backward compatibility

```
User: "Edit test.txt using old_string and new_string"

Expected: Should still work (aliases preserved)
```

### Test 4: Test with content parameter

```
User: "Edit test.txt with search 'hello' and content 'world'"

Expected: Should work (content mapped to new_string internally)
```

---

## 6. ROLLBACK PLAN

If changes break functionality:

1. Restore original files from backup
2. Or revert changes in each file
3. Restart OpenClaw gateway

---

## 7. SUCCESS CRITERIA

- [ ] `edit` tool accepts `replacement` parameter
- [ ] `edit` tool accepts `search` parameter  
- [ ] `edit` tool still accepts `new_string`/`old_string` (backward compatible)
- [ ] File edits complete successfully
- [ ] No "Missing required parameter" errors

---

## 8. ADDITIONAL NOTES

### Why this should work
- `write` tool uses `content` parameter without issues
- `replacement` is semantically similar but different keyword
- Avoids potential "new_" prefix filter

### Alternative approaches (if this fails)
1. Use `content` as primary name (like write tool)
2. Use `text` as primary name
3. Investigate system prompt for filter keywords
4. Test with different model (Claude, GPT-4)

### Related files for context
- `OpenClaw_Harness_Diagnosis.md` - Full technical analysis
- `edit-tool-problem-analysis.md` - Detailed problem documentation

---

## 9. QUICK REFERENCE: Code Patterns

### Pattern 1: Adding alias to schema
```javascript
properties: {
  replacement: {type: "string"},  // Add this
  new_string: {type: "string"},   // Keep for compatibility
  newText: {type: "string"}       // Keep for compatibility
}
```

### Pattern 2: Mapping in normalizer
```javascript
if (params.replacement !== undefined) {
  normalized.new_string = params.replacement;
}
```

### Pattern 3: Updating required array
```javascript
required: ["path", "search", "replacement"]  // Use new names
```

---

**END OF INSTRUCTION**

*This document provides complete instructions for an AI agent to fix the OpenClaw edit-tool parameter filtering issue.*
