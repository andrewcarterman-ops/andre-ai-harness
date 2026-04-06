# 🚀 Mission Control v2 — Linear Edition

A **Linear-inspired** tool factory for building custom OpenClaw skills. Dark, minimal, and incredibly clean.

![Mission Control](https://img.shields.io/badge/Mission-Control-v2.0-purple)
![Next.js](https://img.shields.io/badge/Next.js-14-black)
![Linear Inspired](https://img.shields.io/badge/Design-Linear-5E6AD2)

## ✨ Features

🎨 **Linear-Inspired Design**
- Dark, minimal aesthetic
- Subtle borders and glassmorphism
- Smooth animations and transitions
- Purple accent color scheme

🛠️ **Tool Creation**
- Create custom tools with 6 templates
- Beautiful form interface
- Real-time validation

📦 **Tool Management**
- Clean list view
- Status badges
- Quick actions

📚 **Template Gallery**
- Visual template cards
- Detailed information
- One-click creation

💬 **Built-in Chat**
- Linear-style chat interface
- Quick responses
- Command palette ready

## 🎨 Design Philosophy

Inspired by [Linear](https://linear.app):
- **Dark first** — Easy on the eyes
- **Minimal** — No visual clutter
- **Fast** — Instant feedback
- **Keyboard-first** — ⌘K command palette

## 📋 Requirements

- Node.js 18+
- Python 3.8+ (for backend)
- npm

## 🚀 Quick Start

### 1. Navigate to project
```bash
cd C:\Users\andre\.openclaw\workspace\skills\mission-control-v2
```

### 2. Install dependencies
```bash
npm install
```

### 3. Run development server
```bash
npm run dev
```

### 4. Open browser
Go to **http://localhost:3000**

## 🎨 The Linear Look

```
┌─────────────────────────────────────────────┐
│  ◆ Mission Control      [⌘K Search...]  [👤]│
├─────────┬───────────────────────────────────┤
│         │                                     │
│  ◆ MC   │   Welcome back, Parzival          │
│  Parzi..│                                     │
│         │   ┌─────────┐ ┌─────────┐ ┌─────┐ │
│  —————  │   │ Create  │ │ My Tools│ │Temp │ │
│         │   │  Tool   │ │   12    │ │lates│ │
│  Dashboard│   └─────────┘ └─────────┘ └─────┘ │
│  Create │                                     │
│  Tools  │   QUICK START TEMPLATES             │
│  Templ..│                                     │
│  Chat   │   [🔗] [📁] [🔄] [⚙️] [🔌] [🎨]   │
│  Settings│                                     │
│         │   RECENT TOOLS                      │
│         │   ┌─────────────────────────────┐   │
│  ⌘K     │   │ ⚡ weather-checker    2h    │   │
│         │   │ ⚡ pdf-processor       1d    │   │
│         │   └─────────────────────────────┘   │
│         │                                     │
└─────────┴─────────────────────────────────────┘
```

## 🎯 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘K` | Open command palette |
| `⌘N` | Create new tool |
| `⌘T` | Go to templates |
| `⌘/` | Show shortcuts |

## 🛠️ Templates

| Template | Icon | Best For |
|----------|------|----------|
| API Connector | 🔗 | REST APIs, GraphQL |
| File Processor | 📁 | PDFs, Images, Docs |
| Data Transformer | 🔄 | JSON ↔ CSV, XML |
| Automation | ⚙️ | Scheduled tasks |
| Integration | 🔌 | Slack, GitHub |
| Custom | 🎨 | Anything |

## 📝 Development

```bash
# Development
npm run dev

# Build
npm run build

# Production
npm start

# Lint
npm run lint
```

## 🎨 Customization

### Colors
Edit `tailwind.config.ts`:
```typescript
colors: {
  primary: {
    DEFAULT: "hsl(252 100% 69%)", // Purple
  }
}
```

### Background
The dark background is `#0a0a0a` — almost black.

## 🔧 Troubleshooting

**"Cannot find module"**
```bash
npm install
```

**"Port 3000 in use"**
```bash
npm run dev -- --port 3001
```

## 🚢 Deployment

### Vercel
1. Push to GitHub
2. Import to Vercel
3. Deploy

### Self-hosted
```bash
npm run build
npm start
```

## 📝 License

MIT — Built with ❤️ for Parzival

## 🔗 Links

- [OpenClaw Docs](https://docs.openclaw.ai)
- [Linear Design](https://linear.app)
- [Next.js](https://nextjs.org)

---

**Design System:** Linear-inspired
**Colors:** Purple (#8B5CF6) on Dark (#0A0A0A)
**Typography:** Inter
**Animation:** 150ms transitions

**v2.0.0 — Linear Edition**
