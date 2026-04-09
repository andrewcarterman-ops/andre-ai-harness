# Quickstart: OpenClaw Resilient Agent

## In 5 Minuten zum laufenden System

### 1. Kopiere die Dateien

```bash
# In dein Projektverzeichnis
cp -r /mnt/okcomputer/output/openclaw_resilient/src ./
cp /mnt/okcomputer/output/openclaw_resilient/openclaw.json ./
cp /mnt/okcomputer/output/openclaw_resilient/.env.example ./.env
```

### 2. API Key eintragen

```bash
# .env Datei bearbeiten
MOONSHOT_API_KEY=sk-dein-moonshot-key
```

### 3. Teste den Mock-Modus

```bash
python -c "
import asyncio
from src.core.resilient_agent import ResilientAgent

async def test():
    agent = ResilientAgent()
    async for chunk in agent.stream('Hallo Welt'):
        print(chunk, end='')

asyncio.run(test())
"
```

### 4. Passe die OpenClaw Integration an

Öffne `src/core/resilient_agent.py` und suche nach:

```python
# === DEIN CODE HIER ===
raise NotImplementedError("Passe _create_llm_stream an!")
```

Ersetze durch deine OpenClaw Integration (siehe `INTEGRATION.md`).

### 5. Fertig!

```python
from src.core.resilient_agent import ResilientAgent
from src.core.model_router import TaskType

agent = ResilientAgent()

# Streaming
async for chunk in agent.stream("Dein Prompt", task_type=TaskType.CODING):
    print(chunk, end="")

# Mit Metriken
response = await agent.run("Dein Prompt")
print(f"TTFT: {response.metrics.ttft:.2f}s")
print(f"Model: {response.model_used}")
```

## Dateien im Überblick

| Datei | Zweck | Anpassen? |
|-------|-------|-----------|
| `src/config/timeouts.py` | Timeout-Profile pro Modell | Optional |
| `src/core/model_router.py` | Modell-Auswahl-Logik | Optional |
| `src/core/timeout_middleware.py` | 3-Tier-Timeout-Handling | Nein |
| `src/core/resilient_agent.py` | Hauptklasse | **Ja - OpenClaw Integration** |
| `openclaw.json` | Agent-Konfiguration | Optional |

## Wichtigste Konzepte

1. **3-Tier-Timeouts**: First-Token / Stall / Total
2. **Retry nur Pre-First-Token**: Kein Chaos im Stream
3. **Automatisches Failover**: Fallback-Kette bei Problemen
4. **Task-basierte Modellauswahl**: Coding → kimi-coding, Reasoning → kimi-thinking

## Hilfe

- `README.md` - Vollständige Dokumentation
- `INTEGRATION.md` - OpenClaw Integrations-Guide
- `example_usage.py` - 7 Beispiele
- `tests/test_resilient_agent.py` - Unit Tests
