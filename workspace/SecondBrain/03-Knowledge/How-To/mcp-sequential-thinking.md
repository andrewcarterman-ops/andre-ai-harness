# MCP Sequential Thinking Server

**Quelle:** [GitHub - modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking)
**Installations-Guide für:** Claude Desktop, VS Code, Codex CLI

---

## Features

- Break down complex problems into manageable steps
- Revise and refine thoughts as understanding deepens
- Branch into alternative paths of reasoning
- Adjust the total number of thoughts dynamically
- Generate and verify solution hypotheses

## Tool: sequential_thinking

Facilitates a detailed, step-by-step thinking process for problem-solving and analysis.

### Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `thought` | string | Ja | The current thinking step |
| `nextThoughtNeeded` | boolean | Ja | Whether another thought step is needed |
| `thoughtNumber` | integer | Ja | Current thought number |
| `totalThoughts` | integer | Ja | Estimated total thoughts needed |
| `isRevision` | boolean | Nein | Whether this revises previous thinking |
| `revisesThought` | integer | Nein | Which thought is being reconsidered |
| `branchFromThought` | integer | Nein | Branching point thought number |
| `branchId` | string | Nein | Branch identifier |
| `needsMoreThoughts` | boolean | Nein | If more thoughts are needed |

## Usage

The Sequential Thinking tool is designed for:
- Breaking down complex problems into steps
- Planning and design with room for revision
- Analysis that might need course correction
- Problems where the full scope might not be clear initially
- Tasks that need to maintain context over multiple steps
- Situations where irrelevant information needs to be filtered out

---

## Configuration

### Option 1: Codex CLI (Empfohlen für uns)

```bash
codex mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking
```

### Option 2: Claude Desktop

Add to `claude_desktop_config.json`:

**npx:**
```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

**Docker:**
```json
{
  "mcpServers": {
    "sequentialthinking": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "mcp/sequentialthinking"]
    }
  }
}
```

To disable logging: Set env var `DISABLE_THOUGHT_LOGGING=true`

### Option 3: VS Code

**User Configuration (Recommended):**
Open Command Palette (`Ctrl + Shift + P`) → `MCP: Open User Configuration` → Edit `mcp.json`:

**npx:**
```json
{
  "servers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

**Docker:**
```json
{
  "servers": {
    "sequential-thinking": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "mcp/sequentialthinking"]
    }
  }
}
```

---

## Building (Docker)

```bash
docker build -t mcp/sequentialthinking -f src/sequentialthinking/Dockerfile .
```

---

## License

MIT License - Siehe LICENSE file im Repository.

---

**Related:** [[MCP|Model Context Protocol Overview]]
