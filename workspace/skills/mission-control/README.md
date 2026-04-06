# Mission Control

**Your command center for creating tools and skills.**

Mission Control provides templates, workflows, and automation for building any tool you need. It's a meta-skill that makes skill creation effortless.

## What You Get

✨ **6 Tool Templates** — API connectors, file processors, data transformers, automation, integrations, and custom

📚 **Reference Library** — Design patterns, output formats, and 50+ tool ideas

🚀 **Quick Start** — Create a new tool in seconds

🔧 **Management Tools** — List, edit, package, and publish your tools

## Quick Start

### Create Your First Tool

```bash
python skills/mission-control/scripts/mission_control.py create my-api-tool --type api-connector
```

This creates:
```
my-api-tool/
├── SKILL.md              # Tool documentation
├── scripts/
│   ├── __init__.py
│   ├── fetch.py          # GET requests
│   ├── post.py           # POST requests
│   └── auth.py           # Authentication
└── references/
    ├── api.md            # API documentation
    ├── examples.md       # Usage examples
    └── config.md         # Configuration guide
```

### List Your Tools

```bash
python skills/mission-control/scripts/mission_control.py list --path ./skills
```

## Available Templates

| Template | Best For | Includes |
|----------|----------|----------|
| **api-connector** | API integrations | fetch, post, auth scripts |
| **file-processor** | File operations | extract, convert, batch scripts |
| **data-transformer** | Data conversion | transform, validate, map scripts |
| **automation** | Scheduled tasks | schedule, task, notify scripts |
| **integration** | Service connections | connect, sync, webhook scripts |
| **custom** | Unique needs | Starter template |

## Documentation

- **SKILL.md** — How to create and use tools
- **references/workflow-patterns.md** — Design patterns for tools
- **references/output-patterns.md** — Output formatting best practices
- **references/tool-gallery.md** — 50+ tool ideas to inspire you
- **references/quick-reference.md** — Command cheat sheet

## Example: Building a Weather Tool

1. **Create the tool:**
```bash
python scripts/mission_control.py create weather-checker --type api-connector
```

2. **Edit SKILL.md** — Add your description and usage

3. **Implement scripts/weather.py:**
```python
import requests
import os

def get_weather(city):
    api_key = os.getenv('WEATHER_API_KEY')
    url = f"https://api.weather.com/v1/current?city={city}&appid={api_key}"
    return requests.get(url).json()
```

4. **Test it:**
```bash
python scripts/weather.py --city "Berlin"
```

5. **Use it!** — Ask me: "What's the weather in Berlin?"

## Tool Ideas

Stuck for inspiration? Check `references/tool-gallery.md` for ideas like:

- 📧 Email processor and summarizer
- 📅 Calendar analyzer
- 📊 Report generator
- 🖼️ Image batch processor
- 📝 Meeting summarizer
- 🔗 Bookmark manager
- ✅ Habit tracker
- 💰 Finance tracker
- 🗂️ File organizer
- 🔍 Log analyzer

## Best Practices

1. **Start simple** — Core functionality first
2. **Test scripts** — Run them manually first
3. **Clear descriptions** — Good SKILL.md triggers usage
4. **Iterate** — Real use reveals improvements
5. **Document** — Save future-you time

## Workflow

```
Idea → Template → Edit → Test → Refine → Package → Use
```

## Advanced

### Custom Templates

Modify the templates in `scripts/mission_control.py` to match your style.

### Tool Registry

Keep a registry of all your tools:
```bash
python scripts/mission_control.py list --path ./my-tools
```

### Tool Composition

Combine multiple tools:
```
Tool A → Tool B → Tool C = Super Tool
```

## Getting Help

1. Check `references/quick-reference.md`
2. Read `references/workflow-patterns.md`
3. Browse `references/tool-gallery.md`
4. Look at example tools

## Next Steps

1. Pick a tool idea from the gallery
2. Create it with the appropriate template
3. Implement and test
4. Use it in your workflow!

---

**Ready to build?** Run:
```bash
python skills/mission-control/scripts/mission_control.py --help
```
