# Mission Control

Your command center for creating, managing, and deploying tools/skills. This skill provides workflows, templates, and automation for building anything you need.

## Quick Start

### Create a New Tool

```
mission-control create <tool-name> [--type <type>]
```

Types available:
- `api-connector` — Connect to external APIs
- `file-processor` — Process files (PDF, images, docs)
- `data-transformer` — Transform data formats
- `automation` — Automate repetitive tasks
- `integration` — Integrate with services
- `custom` — Blank slate

### Manage Existing Tools

```
mission-control list              # List all your tools
mission-control edit <tool-name>  # Edit a tool
mission-control test <tool-name>  # Test a tool
mission-control package <tool-name> # Package for sharing
mission-control publish <tool-name> # Publish to ClawHub
```

## Tool Templates

### API Connector Template
For tools that connect to external APIs:
- Authentication handling
- Rate limiting
- Error retry logic
- Response parsing

### File Processor Template  
For tools that work with files:
- Format detection
- Content extraction
- Transformation pipeline
- Output generation

### Data Transformer Template
For tools that convert data:
- Schema mapping
- Validation rules
- Batch processing
- Error reporting

### Automation Template
For tools that automate tasks:
- Trigger conditions
- Action sequences
- State management
- Logging/notification

## Creating a Tool Step-by-Step

### 1. Define the Tool

Ask yourself:
- What problem does it solve?
- What inputs does it need?
- What outputs does it produce?
- When should it be used?

### 2. Choose a Template

Use the closest matching template or start from scratch.

### 3. Implement Core Logic

Write scripts in `scripts/` for deterministic operations:
- Python for data processing
- Bash for system operations
- JavaScript for web tasks

### 4. Document in SKILL.md

Clear description of:
- When to use the tool
- How to use it
- Examples
- Configuration options

### 5. Add References (Optional)

Put detailed docs, schemas, or examples in `references/`.

### 6. Test and Iterate

Use the tool in real scenarios and refine.

## Examples

### Example: Creating a Weather Tool

```
mission-control create weather-checker --type api-connector
```

This creates:
```
weather-checker/
├── SKILL.md
├── scripts/
│   └── fetch_weather.py
└── references/
    └── api-docs.md
```

### Example: Creating a PDF Tool

```
mission-control create pdf-processor --type file-processor
```

This creates:
```
pdf-processor/
├── SKILL.md
├── scripts/
│   ├── extract_text.py
│   ├── merge_pdfs.py
│   └── rotate_pdf.py
└── references/
    └── pdf-spec.md
```

## Best Practices

1. **Start simple** — Build the core functionality first
2. **Test scripts** — Always test scripts before bundling
3. **Clear descriptions** — SKILL.md frontmatter triggers usage
4. **Progressive disclosure** — Keep SKILL.md lean, details in references
5. **Iterate** — Real usage reveals what needs improvement

## Advanced Features

### Tool Registry

View all available tools:
```
mission-control registry
```

### Tool Composition

Combine multiple tools:
```
mission-control compose tool1,tool2,new-tool
```

### Update Tools

Update tools to latest patterns:
```
mission-control update <tool-name>
```

## Tool Ideas Gallery

Stuck for ideas? Here are common tool categories:

**Productivity**
- Email processor/summarizer
- Calendar analyzer
- Task batch processor
- Document formatter

**Development**
- Code reviewer
- API tester
- Log analyzer
- Deployment helper

**Data**
- CSV cleaner
- JSON transformer
- Report generator
- Chart creator

**Media**
- Image resizer
- Video metadata extractor
- Audio transcriber
- Thumbnail generator

**Integration**
- Slack/Discord notifier
- GitHub/GitLab helper
- Database connector
- Cloud storage sync

## Getting Help

- Check `references/workflow-patterns.md` for design patterns
- See `references/output-patterns.md` for output formatting
- Look at existing skills for examples

## Publishing

Package your tool:
```
mission-control package my-tool
```

Publish to ClawHub:
```
mission-control publish my-tool
```

Share with others!
