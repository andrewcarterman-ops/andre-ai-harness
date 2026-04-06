#!/usr/bin/env python3
"""
Mission Control - Python version for Windows compatibility
Creates new tools/skills with templates
"""
import argparse
import os
import sys
from pathlib import Path

TEMPLATES = {
    'api-connector': {
        'description': 'Connect to external APIs. Use when: (1) fetching data from APIs, (2) sending data to APIs, (3) handling authentication, (4) managing rate limits.',
        'scripts': ['fetch.py', 'post.py', 'auth.py'],
    },
    'file-processor': {
        'description': 'Process and manipulate files. Use when: (1) reading file contents, (2) converting formats, (3) extracting data, (4) batch processing files.',
        'scripts': ['extract.py', 'convert.py', 'batch.py'],
    },
    'data-transformer': {
        'description': 'Transform data between formats. Use when: (1) converting data types, (2) cleaning/normalizing data, (3) schema mapping, (4) batch transformations.',
        'scripts': ['transform.py', 'validate.py', 'map.py'],
    },
    'automation': {
        'description': 'Automate repetitive tasks. Use when: (1) scheduled operations, (2) batch processing, (3) workflow automation, (4) notifications.',
        'scripts': ['schedule.py', 'task.py', 'notify.py'],
    },
    'integration': {
        'description': 'Integrate with external services. Use when: (1) connecting services, (2) syncing data, (3) webhook handling, (4) service orchestration.',
        'scripts': ['connect.py', 'sync.py', 'webhook.py'],
    },
    'custom': {
        'description': 'Custom tool for specialized tasks. Use when specific operations are needed that don\'t fit other categories.',
        'scripts': ['main.py'],
    },
}

def create_skill_md(name, tool_type, skill_dir):
    """Create SKILL.md with proper frontmatter"""
    template = TEMPLATES.get(tool_type, TEMPLATES['custom'])
    
    content = f'''---
name: {name}
description: {template['description']}
---

# {name.title()}

## Overview

{name} is a {tool_type} tool designed to [describe purpose].

## When to Use

Use this tool when you need to:
1. [Specific use case 1]
2. [Specific use case 2]
3. [Specific use case 3]

## Quick Start

### Basic Usage

```bash
# Example command
python scripts/{template['scripts'][0]} --input <input> --output <output>
```

### Advanced Options

See `references/` for detailed documentation.

## Scripts

'''
    
    for script in template['scripts']:
        content += f'- `scripts/{script}` - [Description]\n'
    
    content += f'''
## Configuration

Set required environment variables:
```bash
export {name.upper().replace("-", "_")}_API_KEY="your-key"  # If needed
```

## Error Handling

- Common errors and solutions
- Retry logic
- Fallback options

## References

- `references/api.md` - API documentation
- `references/examples.md` - Usage examples
- `references/config.md` - Configuration guide
'''
    
    with open(skill_dir / 'SKILL.md', 'w') as f:
        f.write(content)

def create_script(script_name, skill_dir):
    """Create a Python script template"""
    script_content = f'''#!/usr/bin/env python3
"""
{script_name.replace('.py', '').title()} script for {skill_dir.name}
"""
import argparse
import sys
import json
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description='{script_name} operation')
    parser.add_argument('--input', '-i', help='Input file or data')
    parser.add_argument('--output', '-o', help='Output file')
    parser.add_argument('--config', '-c', help='Config file')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # TODO: Implement your logic here
    if args.verbose:
        print(f"Input: {{args.input}}")
        print(f"Output: {{args.output}}")
    
    # Example processing
    result = {{"status": "success", "data": None}}
    
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
        print(f"Result saved to {{args.output}}")
    else:
        print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
'''
    
    with open(skill_dir / 'scripts' / script_name, 'w') as f:
        f.write(script_content)

def create_references(skill_dir):
    """Create reference documentation files"""
    refs_dir = skill_dir / 'references'
    
    # API docs
    with open(refs_dir / 'api.md', 'w') as f:
        f.write('''# API Reference

## Endpoints

Document API endpoints here.

## Authentication

Describe authentication methods.

## Rate Limits

Document rate limiting.

## Error Codes

List error codes and meanings.
''')
    
    # Examples
    with open(refs_dir / 'examples.md', 'w') as f:
        f.write('''# Usage Examples

## Example 1: Basic Usage

```bash
python scripts/main.py --input data.json --output result.json
```

## Example 2: Advanced Options

```bash
python scripts/main.py --input data.json --config config.yaml --verbose
```

## Example 3: Batch Processing

```bash
for file in *.json; do
    python scripts/main.py --input "$file" --output "out/$file"
done
```
''')
    
    # Config guide
    with open(refs_dir / 'config.md', 'w') as f:
        f.write('''# Configuration Guide

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| API_KEY | API authentication | Yes |
| BASE_URL | API base URL | No |

## Config File Format

```yaml
# config.yaml
api:
  key: your-api-key
  timeout: 30
options:
  verbose: true
```
''')

def create_tool(name, tool_type, output_path):
    """Create a complete tool/skill structure"""
    
    if tool_type not in TEMPLATES:
        print(f"Unknown type: {tool_type}")
        print(f"Available types: {', '.join(TEMPLATES.keys())}")
        sys.exit(1)
    
    skill_dir = Path(output_path) / name
    
    if skill_dir.exists():
        print(f"Error: {skill_dir} already exists")
        sys.exit(1)
    
    # Create directories
    (skill_dir / 'scripts').mkdir(parents=True)
    (skill_dir / 'references').mkdir(parents=True)
    (skill_dir / 'assets').mkdir(parents=True)
    
    # Create SKILL.md
    create_skill_md(name, tool_type, skill_dir)
    
    # Create scripts
    template = TEMPLATES[tool_type]
    for script in template['scripts']:
        create_script(script, skill_dir)
    
    # Create references
    create_references(skill_dir)
    
    # Create __init__.py for scripts
    with open(skill_dir / 'scripts' / '__init__.py', 'w') as f:
        f.write('# Scripts package\n')
    
    print(f"✅ Created {tool_type} tool: {skill_dir}")
    print("")
    print("Next steps:")
    print(f"  1. Edit {skill_dir}/SKILL.md")
    print(f"  2. Implement scripts in {skill_dir}/scripts/")
    print(f"  3. Add references in {skill_dir}/references/")
    print(f"  4. Test the tool")
    print(f"  5. Package: mission-control package {name}")

def list_tools(skills_path):
    """List all tools in the skills directory"""
    skills_dir = Path(skills_path)
    
    if not skills_dir.exists():
        print(f"Skills directory not found: {skills_path}")
        return
    
    print("📦 Available Tools:")
    print("-" * 50)
    
    for item in sorted(skills_dir.iterdir()):
        if item.is_dir() and (item / 'SKILL.md').exists():
            # Try to read description from SKILL.md
            try:
                with open(item / 'SKILL.md', 'r') as f:
                    lines = f.readlines()
                    for line in lines:
                        if line.startswith('description:'):
                            desc = line.split(':', 1)[1].strip()
                            print(f"  • {item.name:20} - {desc[:50]}...")
                            break
                    else:
                        print(f"  • {item.name}")
            except:
                print(f"  • {item.name}")

def main():
    parser = argparse.ArgumentParser(description='Mission Control - Tool Creator')
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # Create command
    create_parser = subparsers.add_parser('create', help='Create a new tool')
    create_parser.add_argument('name', help='Tool name')
    create_parser.add_argument('--type', default='custom', 
                               choices=list(TEMPLATES.keys()),
                               help='Tool template type')
    create_parser.add_argument('--path', default='.',
                               help='Output directory (default: current)')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List all tools')
    list_parser.add_argument('--path', default='.',
                            help='Skills directory path')
    
    # Package command placeholder
    package_parser = subparsers.add_parser('package', help='Package a tool')
    package_parser.add_argument('name', help='Tool name')
    
    args = parser.parse_args()
    
    if args.command == 'create':
        create_tool(args.name, args.type, args.path)
    elif args.command == 'list':
        list_tools(args.path)
    elif args.command == 'package':
        print(f"Packaging {args.name}...")
        print("Use: python -m openclaw.skills.skill-creator.scripts.package_skill")
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
