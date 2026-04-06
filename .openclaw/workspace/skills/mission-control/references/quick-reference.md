# Mission Control Quick Reference

## Commands

### Create New Tool

```bash
# Python (cross-platform)
python scripts/mission_control.py create my-tool --type api-connector

# Bash (Unix/Mac)
./scripts/create_tool.sh my-tool --type file-processor
```

### Tool Types

| Type | Use For | Scripts Included |
|------|---------|------------------|
| `api-connector` | API integrations | fetch.py, post.py, auth.py |
| `file-processor` | File operations | extract.py, convert.py, batch.py |
| `data-transformer` | Data conversion | transform.py, validate.py, map.py |
| `automation` | Scheduled tasks | schedule.py, task.py, notify.py |
| `integration` | Service connections | connect.py, sync.py, webhook.py |
| `custom` | Anything else | main.py |

### List All Tools

```bash
python scripts/mission_control.py list --path ./skills
```

### Package Tool

```bash
# Coming soon
python scripts/mission_control.py package my-tool
```

## Directory Structure

```
my-tool/
├── SKILL.md           # Required - Tool documentation
├── scripts/           # Python/Bash scripts
│   ├── __init__.py
│   └── main.py        # Main script
├── references/        # Documentation
│   ├── api.md
│   ├── examples.md
│   └── config.md
└── assets/            # Templates, images, etc.
```

## SKILL.md Template

```markdown
---
name: my-tool
description: What this tool does. Use when: (1) situation 1, (2) situation 2, (3) situation 3.
---

# My Tool

## Overview

Brief description.

## Usage

```bash
python scripts/main.py --input file.txt --output result.txt
```

## Scripts

- `scripts/main.py` - Main operation

## Configuration

Environment variables:
- `MY_TOOL_API_KEY` - API authentication

## References

- `references/api.md` - API docs
- `references/examples.md` - Usage examples
```

## Quick Tips

1. **Start small** — Get the core working first
2. **Test scripts** — Run them manually before using
3. **Clear descriptions** — Good descriptions trigger usage
4. **Iterate** — Real use reveals improvements
5. **Document** — Future you will thank present you

## Common Patterns

### Read Environment Variable

```python
import os
api_key = os.getenv('MY_TOOL_API_KEY')
if not api_key:
    raise ValueError("MY_TOOL_API_KEY not set")
```

### Parse Arguments

```python
import argparse
parser = argparse.ArgumentParser()
parser.add_argument('--input', '-i', required=True)
parser.add_argument('--output', '-o')
parser.add_argument('--verbose', '-v', action='store_true')
args = parser.parse_args()
```

### Handle Errors

```python
try:
    result = process_data()
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
```

### JSON Output

```python
import json
output = {
    "status": "success",
    "data": result,
    "timestamp": datetime.now().isoformat()
}
print(json.dumps(output, indent=2))
```

## Troubleshooting

### Script won't run
- Check Python is installed: `python --version`
- Make script executable: `chmod +x script.py`
- Check file path is correct

### Import errors
- Ensure `__init__.py` exists in `scripts/`
- Use relative imports: `from . import module`
- Check Python path

### Config not loading
- Verify environment variable names
- Check file permissions
- Validate config file format

## Resources

- `references/workflow-patterns.md` - Design patterns
- `references/output-patterns.md` - Output formatting
- `references/tool-gallery.md` - Tool ideas

## Next Steps

1. Create your first tool
2. Test it thoroughly
3. Refine based on use
4. Package and share!
