# CONTEXT_TOOLS.md

## Available Tools

### Core File Operations

| Tool | Purpose | Parameters | Status |
|------|---------|------------|--------|
| `read` | Read file contents | `file_path`, `path` | ✅ Stable |
| `write` | Write file contents | `file_path`, `path`, `content` | ✅ Stable |
| `edit` | Edit file contents | `file_path`, `old_string`, `new_string` | ✅ **FIXED** |

**Edit Tool Fix:**
- Old: `splice(idx, 1)` - Removed without replacement
- New: `splice(idx, 1, alias)` - Proper replacement

### Execution Tools

| Tool | Purpose | Parameters |
|------|---------|------------|
| `exec` | Execute command | `command`, `timeout`, `workdir` |
| `process` | Manage processes | `action`, `sessionId` |

### Web Tools

| Tool | Purpose | Configuration |
|------|---------|---------------|
| `web_search` | Search web | Provider: `gemini` |
| `web_fetch` | Fetch URL | `url`, `extractMode` |

### Session Tools

| Tool | Purpose | Parameters |
|------|---------|------------|
| `sessions_list` | List sessions | `activeMinutes`, `limit` |
| `sessions_history` | Get history | `sessionKey`, `limit` |
| `sessions_send` | Send message | `sessionKey`, `message` |
| `subagents` | Control subagents | `action`, `target` |
| `session_status` | Show status | - |

### Model Tools

| Tool | Purpose | Restrictions |
|------|---------|--------------|
| `image` | Analyze image | - |
| `pdf` | Analyze PDF | - |
| `cron` | Manage cron jobs | - |
| `apply_patch` | Apply patches | ⚠️ OpenAI/Codex only |

### Usage Patterns

#### Read-Modify-Write (Recommended)
```javascript
// Instead of edit (unreliable):
const content = read({file_path: "test.txt"});
const modified = content.replace("old", "new");
write({file_path: "test.txt", content: modified});
```

---

*Tools Reference Document*
*Version: 1.0.0*
