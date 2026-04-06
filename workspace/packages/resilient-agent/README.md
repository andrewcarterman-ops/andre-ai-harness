# OpenClaw Resilient Agent

Resiliente LLM-Agent mit 3-Tier-Timeout-Handling und automatischem Failover für OpenClaw.

## Features

- **3-Tier-Timeout-Handling**: First-Token (TTFT), Stall, Total
- **Automatisches Failover**: Fallback-Kette bei Problemen
- **Task-basierte Modellauswahl**: CODING, REASONING, QUICK_CHAT, etc.
- **Retry-Logik**: Nur für Pre-First-Token-Failures
- **Metriken**: TTFT, Tokens/Sekunde, Gesamtdauer
- **OpenClaw-Integration**: Automatisches Laden der Konfiguration

## Installation

```bash
cd packages/resilient-agent
pip install -e .
```

## Schnellstart

### Basis-Verwendung

```python
import asyncio
from resilient_agent import ResilientAgent, TaskType

async def main():
    agent = ResilientAgent()
    
    # Streaming
    async for chunk in agent.stream("Hallo Welt"):
        print(chunk, end="")
    
    # Non-Streaming
    response = await agent.run("Was ist 2+2?")
    print(response.content)
    print(f"TTFT: {response.metrics.ttft:.2f}s")

asyncio.run(main())
```

### Mit Task-Typ

```python
from resilient_agent import TaskType

# Coding-Task
async for chunk in agent.stream(
    "Schreibe eine Fibonacci-Funktion",
    task_type=TaskType.CODING
):
    print(chunk, end="")
```

### OpenClaw Config laden

```python
from resilient_agent import OpenClawConfigLoader

# Lade Konfiguration aus openclaw.json
loader = OpenClawConfigLoader()
config = loader.get_agent_config()

print(f"Model: {config.model}")
print(f"Timeout: {config.timeout_seconds}s")
print(f"Sandbox: {config.sandbox_mode}")

# Validierung
warnings = loader.validate()
if warnings:
    for w in warnings:
        print(f"⚠️  {w}")
```

## Architektur

```
┌─────────────────────────────────────────────────────────┐
│  ResilientAgent                                         │
│  - Task-basierte Modellauswahl                          │
│  - Fallback-Ketten-Verwaltung                           │
└─────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────┐
│  StreamingTimeoutMiddleware                             │
│  - 3-Tier-Timeout (First-Token, Stall, Total)          │
│  - Retry-Logik (nur Pre-First-Token)                   │
└─────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────┐
│  ModelRouter                                            │
│  - TaskType → Modell-Mapping                            │
│  - Constraint-Prüfung (Context, Reasoning, Tools)      │
└─────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────┐
│  OpenClawConfigLoader                                   │
│  - Lädt openclaw.json                                   │
│  - Extrahiert Timeouts & Modelle                        │
└─────────────────────────────────────────────────────────┘
```

## Timeout-Konfiguration

### Modellspezifische Timeouts

| Modell | First-Token | Stall | Total | Retries |
|--------|-------------|-------|-------|---------|
| k2p5 | 90s | 45s | 600s | 2 |
| kimi-k2-thinking | 120s | 60s | 900s | 2 |
| gpt-5.2 | 30s | 20s | 300s | 3 |
| claude-sonnet-4-6 | 60s | 30s | 600s | 3 |

### OpenClaw-Integration

Die Timeouts werden automatisch aus `openclaw.json` geladen:

```json
{
  "agents": {
    "defaults": {
      "timeoutSeconds": 900
    }
  }
}
```

## Task-Typen

| TaskType | Verwendung | Bevorzugtes Modell |
|----------|------------|-------------------|
| `CODING` | Code-Generierung | k2p5 |
| `REASONING` | Komplexes Denken | kimi-k2-thinking |
| `QUICK_CHAT` | Schnelle Antworten | k2p5 |
| `LONG_CONTEXT` | Lange Dokumente | k2p5 (262k) |
| `TOOL_HEAVY` | Viele Tool-Calls | k2p5 |
| `CREATIVE` | Kreative Texte | claude-sonnet-4-6 |

## Retry-Regeln

```
FirstTokenTimeoutError  → ✅ Retry erlaubt (Verbindungsproblem)
StallTimeoutError       → ❌ KEIN Retry (User hat Teile gesehen)
TotalTimeoutError       → ❌ KEIN Retry (harter Cutoff)
```

## Tests

```bash
# Alle Tests ausführen
python -m pytest tests/ -v

# Mit Coverage
python -m pytest tests/ --cov=resilient_agent
```

## Demo

```bash
# Demo-Skript ausführen
python examples/demo.py
```

Zeigt:
- Basic Streaming
- Task-basierte Modellauswahl
- Metriken (TTFT, TPS)
- OpenClaw Config-Loader

## Projekt-Integration

### In OpenClaw-Projekt einbinden

```python
# In deinem OpenClaw-Code
from resilient_agent import ResilientAgent, TaskType

agent = ResilientAgent(preferred_provider="kimi-coding")

async def process_prompt(prompt: str):
    async for chunk in agent.stream(
        prompt,
        task_type=TaskType.CODING
    ):
        yield chunk
```

### Config-Validierung

```python
from resilient_agent import OpenClawConfigLoader

loader = OpenClawConfigLoader()
loader.print_summary()
```

Ausgabe:
```
==================================================
OpenClaw Konfiguration
==================================================

✅ Konfiguration valid

Agent:
  Model: kimi-coding/k2p5
  Timeout: 900s
  Sandbox: non-main
  Workspace: C:\Users\...\.openclaw\workspace

Tools:
  Exec Host: gateway
  Profile: full

==================================================
```

## Lizenz

MIT
