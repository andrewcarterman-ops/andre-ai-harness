# MCP Configuration Guide

## Setup

1. **Install MCP client** (if not already installed)
2. **Copy desired servers** from `mcp-servers.json` to your MCP config
3. **Set environment variables** for servers that require them
4. **Restart** your MCP client

## Quick Start

### Essential (Recommended)
- `filesystem` - File operations
- `memory` - Persistent memory
- `fetch` - Web content

### Optional (As needed)
- `github` - GitHub integration (requires GITHUB_TOKEN)
- `web-search` - Search (requires BRAVE_API_KEY)
- `sequential-thinking` - Complex reasoning

## Environment Variables

```bash
# GitHub
export GITHUB_TOKEN=your_token_here

# Brave Search
export BRAVE_API_KEY=your_key_here
```

## Security Notes

- Never commit API keys to git
- Use `.env` files (already in .gitignore)
- Rotate keys regularly
