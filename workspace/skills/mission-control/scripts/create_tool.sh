#!/bin/bash
# Mission Control - Tool Creator Script
# Usage: create_tool.sh <tool-name> [--type <type>] [--path <path>]

set -e

TOOL_NAME="${1:-}"
TOOL_TYPE="${2:-custom}"
OUTPUT_PATH="${3:-.}"

if [ -z "$TOOL_NAME" ]; then
    echo "Usage: create_tool.sh <tool-name> [--type <type>] [--path <path>]"
    echo ""
    echo "Available types:"
    echo "  api-connector   - Connect to external APIs"
    echo "  file-processor  - Process files (PDF, images, docs)"
    echo "  data-transformer - Transform data formats"
    echo "  automation      - Automate repetitive tasks"
    echo "  integration     - Integrate with services"
    echo "  custom          - Blank slate (default)"
    exit 1
fi

# Create directory structure
SKILL_DIR="$OUTPUT_PATH/$TOOL_NAME"
mkdir -p "$SKILL_DIR/scripts"
mkdir -p "$SKILL_DIR/references"
mkdir -p "$SKILL_DIR/assets"

# Generate SKILL.md based on type
case $TOOL_TYPE in
    api-connector)
        cat > "$SKILL_DIR/SKILL.md" << 'EOF'
---
name: ${TOOL_NAME}
description: Connect to ${TOOL_NAME} API. Use when: (1) fetching data from ${TOOL_NAME}, (2) sending data to ${TOOL_NAME}, (3) authenticating with ${TOOL_NAME} API, (4) handling rate limits and errors for ${TOOL_NAME}.
---

# ${TOOL_NAME}

API connector for ${TOOL_NAME}.

## Authentication

Set API key in environment:
```bash
export ${TOOL_NAME_UPPER}_API_KEY="your-key"
```

## Usage

### Fetch Data

```python
scripts/fetch_data.py --endpoint /resource --params key=value
```

### Send Data

```python
scripts/send_data.py --endpoint /resource --data '{"key": "value"}'
```

## Rate Limits

- 100 requests/minute
- Handle 429 errors with exponential backoff

## Error Handling

- 401: Check API key
- 404: Resource not found
- 429: Rate limited, retry after delay
- 500: Server error, retry with backoff
EOF
        ;;
    file-processor)
        cat > "$SKILL_DIR/SKILL.md" << 'EOF'
---
name: ${TOOL_NAME}
description: Process and manipulate files. Use when: (1) reading file contents, (2) converting file formats, (3) extracting data from files, (4) modifying file properties.
---

# ${TOOL_NAME}

File processing toolkit.

## Supported Formats

- PDF: extract, merge, rotate, compress
- Images: resize, convert, optimize
- Documents: read, convert, extract
- Archives: extract, create

## Usage

### Extract Content

```python
scripts/extract.py --input file.pdf --output text.txt
```

### Convert Format

```python
scripts/convert.py --input file.docx --output file.pdf
```

### Batch Process

```python
scripts/batch.py --input-dir ./files --operation extract
```
EOF
        ;;
    *)
        cat > "$SKILL_DIR/SKILL.md" << 'EOF'
---
name: ${TOOL_NAME}
description: Custom tool for ${TOOL_NAME}. Use when tasks involve ${TOOL_NAME} operations.
---

# ${TOOL_NAME}

Custom tool description here.

## Usage

Describe how to use this tool.

## Scripts

- `scripts/main.py` - Main operation

## References

See `references/` for detailed documentation.
EOF
        ;;
esac

# Create placeholder scripts
cat > "$SKILL_DIR/scripts/main.py" << 'EOF'
#!/usr/bin/env python3
"""
Main script for ${TOOL_NAME}
"""
import sys
import argparse

def main():
    parser = argparse.ArgumentParser(description='${TOOL_NAME} tool')
    parser.add_argument('--input', '-i', help='Input file/path')
    parser.add_argument('--output', '-o', help='Output file/path')
    args = parser.parse_args()
    
    # TODO: Implement your logic here
    print(f"Processing: {args.input}")
    print(f"Output: {args.output}")
    
if __name__ == "__main__":
    main()
EOF

# Create reference template
cat > "$SKILL_DIR/references/README.md" << 'EOF'
# ${TOOL_NAME} Reference

## Overview

Add detailed documentation here.

## API Documentation

Document any APIs used.

## Examples

Provide usage examples.

## Configuration

Document configuration options.
EOF

echo "✅ Created $TOOL_TYPE tool: $SKILL_DIR"
echo ""
echo "Next steps:"
echo "  1. Edit $SKILL_DIR/SKILL.md"
echo "  2. Implement scripts in $SKILL_DIR/scripts/"
echo "  3. Add references in $SKILL_DIR/references/"
echo "  4. Test the tool"
echo "  5. Package: mission-control package $TOOL_NAME"
