---
id: ecc-2026-04-03-001
created: 2026-04-03T02:38:00
tags: [bug, edit-tool, workaround, openclaw, ecc, critical]
source: memory-flush
importance: critical
---

# Critical Bug Discovery: `edit` Tool Parameter Issue

## Problem Identified

The `edit` tool has a **fundamental bug** in tool-call generation. The `new_string` (or `newText`) parameter cannot be correctly passed to the gateway.

**Error Pattern:**
```
Missing required parameter: newText (newText or new_string). Supply correct parameters before retrying.
```

## Evidence from Testing

- Gateway logs confirm the parameter never arrives: `[tools] edit failed: Missing required parameter: newText...`
- Tested with both `new_string` and `newText` parameter names - neither works
- The parameter validation happens at the gateway level (thread-bindings-SYAnWHuW.js)
- Schema shows: `{ keys: ["newText", "new_string"], label: "newText (newText or new_string)", allowEmpty: true }`

## Workaround Solution

**Use `read` + `write` instead of `edit`** for file modifications:

1. `read` the file content
2. `write` the modified content back

Example:
```
read file.txt          # Get current content
write file.txt "new"   # Write modified content
```

## Impact

- All file edits must use the read+write pattern
- Cannot use precise `edit` for surgical changes
- More verbose but functional workaround exists

## Next Steps

- [ ] Consider creating a skill that wraps read+write as an `edit` replacement
- [ ] Document this limitation in TOOLS.md
- [ ] Monitor for gateway updates that might fix this

---
*Synced from: memory/2026-04-03.md*
*Auto-classified: Critical*
