# OpenClaw Resilient Agent

Ein robuster Wrapper für OpenClaw mit intelligentem Modell-Routing, 3-Tier-Timeout-Handling und automatischem Failover.

## Features

- **Intelligente Modellauswahl**: Wählt automatisch das beste Modell für den Task (Coding, Reasoning, etc.)
- **3-Tier-Timeout-Handling**: Separater Timeout für First-Token, Stall-Erkennung und Gesamt-Timeout
- **Automatisches Failover**: Wechselt bei Problemen zu Fallback-Modellen
- **Retry-Logik**: Nur für Pre-First-Token-Failures (kein Chaos im Stream)
- **Modellspezifische Timeouts**: Kimi-K2-Thinking braucht mehr Geduld als GPT-5.2

## Schnellstart

### 1. Dateien kopieren

```bash
# Kopiere die src/ Dateien in dein Projekt
cp -r openclaw_resilient/src /pfad/zu/deinem/projekt/

# Oder: Füge den Ordner zu deinem Python-Path hinzu
export PYTHONPATH="/pfad/zu/openclaw_resilient:$PYTHONPATH"
```

### 2. API Keys setzen

```bash
export MOONSHOT_API_KEY="sk-your-key"
export OPENAI_API_KEY="sk-your-key"
export ANTHROPIC_API_KEY="sk-your-key"
```

### 3. Testen

```bash
cd openclaw_resilient
python example_usage.py
```

## Schritt-für-Schritt Integration

### Schritt 1: Timeout-Profile (src/config/timeouts.py)

Diese Datei definiert modellspezifische Timeouts.

```python
from src.config.timeouts import get_timeout_profile

profile = get_timeout_profile("kimi-k2-thinking")
print(profile.first_token_seconds)  # 120.0
print(profile.stall_seconds)        # 60.0
```

**Wann anpassen?**
- Wenn du neue Modelle hinzufügst
- Wenn du Timeouts für deine Infrastruktur optimieren willst

### Schritt 2: Model Router (src/core/model_router.py)

Wählt das beste Modell basierend auf Task-Typ.

```python
from src.core.model_router import ModelRouter, TaskType

router = ModelRouter()
model = router.select_model(
    task_type=TaskType.CODING,
    context_length=50000
)
print(model.full_id)  # "moonshot/kimi-k2-coding"
```

**Wann anpassen?**
- Wenn du neue Modelle hinzufügst (ModelRegistry.MODELS)
- Wenn du Task-Prioritäten ändern willst (TASK_MODELS)

### Schritt 3: Timeout Middleware (src/core/timeout_middleware.py)

Das Herzstück - 3-Tier-Timeout-Handling für Streams.

```python
from src.core.timeout_middleware import StreamingTimeoutMiddleware

middleware = StreamingTimeoutMiddleware(
    first_token_timeout=60.0,   # TTFT
    stall_timeout=30.0,         # Zwischen Chunks
    total_timeout=600.0         # Gesamt
)

async for chunk in middleware.wrap_stream(stream_factory):
    print(chunk)
```

**Wichtige Regeln:**
- `FirstTokenTimeoutError`: Retry erlaubt
- `StallTimeoutError`: Kein Retry (Stream hat begonnen!)
- `TotalTimeoutError`: Kein Retry (harter Cutoff)

### Schritt 4: Resilient Agent (src/core/resilient_agent.py)

Die Hauptklasse - bindet alles zusammen.

```python
from src.core.resilient_agent import ResilientAgent
from src.core.model_router import TaskType

agent = ResilientAgent(preferred_provider="moonshot")

# Streaming
async for chunk in agent.stream(
    "Schreibe eine Fibonacci-Funktion",
    task_type=TaskType.CODING
):
    print(chunk, end="")

# Non-Streaming
response = await agent.run("Erkläre Rekursion")
print(response.content)
print(f"Model: {response.model_used}")
print(f"TTFT: {response.metrics.ttft:.2f}s")
```

## OpenClaw Integration

### Wichtig: Passe `_create_llm_stream` an!

In `src/core/resilient_agent.py` findest du diese Methode:

```python
async def _create_llm_stream(self, prompt, model, system_prompt=None):
    """HIER IST DER INTEGRATIONSPUNKT ZU OPENCLAW!"""
    
    if self._openclaw_available and self.openclaw_agent:
        # === DEINE OPENCLAW INTEGRATION ===
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        # OpenClaw Config
        config = model.timeout_profile.to_openclaw_config()
        config["model"] = model.full_id
        
        # Passe dies an deine OpenClaw API an!
        stream = await self.openclaw_agent.stream(messages, config=config)
        
        async for chunk in stream:
            # Passe an dein Chunk-Format an!
            yield chunk.content if hasattr(chunk, 'content') else str(chunk)
```

**Typische OpenClaw Chunk-Formate:**

```python
# Format 1: chunk.content
yield chunk.content

# Format 2: chunk.delta
yield chunk.delta

# Format 3: Dict
yield chunk.get('content', '') or chunk.get('delta', '')

# Format 4: Pydantic Model
yield chunk.choices[0].delta.content
```

## Konfiguration

### openclaw.json

Die `openclaw.json` definiert Agent-Konfigurationen:

```json
{
  "agents": {
    "defaults": {
      "timeoutSeconds": 900,
      "llm": {
        "idleTimeoutSeconds": 120,
        "stallTimeoutSeconds": 45
      },
      "model": {
        "primary": "moonshot/kimi-k2-thinking",
        "fallbacks": ["moonshot/kimi-k2", "openai/gpt-5.2"]
      }
    }
  }
}
```

**Wichtige Felder:**
- `timeoutSeconds`: Gesamt-Timeout
- `idleTimeoutSeconds`: Zeit bis erstem Token
- `stallTimeoutSeconds`: Zeit zwischen Chunks
- `fallbacks`: Liste der Fallback-Modelle

## Timeout-Profile anpassen

### Für neue Modelle

Füge in `src/config/timeouts.py` hinzu:

```python
TIMEOUT_PROFILES = {
    # ... bestehende Modelle ...
    
    "mein-neues-modell": TimeoutProfile(
        first_token_seconds=45.0,
        stall_seconds=25.0,
        total_seconds=400.0,
        retry_attempts=3
    ),
}
```

### Für bestehende Modelle

```python
# Override beim Erstellen der Middleware
from src.core.timeout_middleware import create_middleware_for_model

middleware = create_middleware_for_model(
    "kimi-k2-thinking",
    custom_timeouts={
        "first_token": 180.0,  # Länger warten
        "stall": 90.0
    }
)
```

## Task-Typen

| TaskType | Verwendung | Bevorzugtes Modell |
|----------|------------|-------------------|
| `CODING` | Code-Generierung | kimi-k2-coding |
| `REASONING` | Komplexes Denken | kimi-k2-thinking |
| `QUICK_CHAT` | Schnelle Antworten | gpt-5.2 |
| `LONG_CONTEXT` | Lange Dokumente | kimi-k2 (256k) |
| `TOOL_HEAVY` | Viele Tool-Calls | gpt-5.2 |
| `CREATIVE` | Kreative Texte | claude-sonnet-4-6 |

## Beispiele

### Einfaches Streaming

```python
async for chunk in agent.stream("Hallo Welt"):
    print(chunk, end="")
```

### Mit Metriken

```python
def on_metrics(m):
    print(f"TTFT: {m.ttft:.2f}s")
    print(f"Tokens: {m.total_tokens}")
    print(f"TPS: {m.tokens_per_second:.1f}")

async for chunk in agent.stream(prompt, on_metrics=on_metrics):
    print(chunk, end="")
```

### Mit Fallback-Tracking

```python
def on_switch(old, new):
    print(f"Fallback: {old} -> {new}")

async for chunk in agent.stream(
    prompt,
    on_model_switch=on_switch
):
    print(chunk, end="")
```

### Spezifisches Modell erzwingen

```python
async for chunk in agent.stream(
    prompt,
    model_override="kimi-k2-thinking"
):
    print(chunk, end="")
```

## Troubleshooting

### "OpenClaw nicht verfügbar"

```bash
pip install openclaw
```

Oder: Der Agent funktioniert im Mock-Modus für Testing.

### "FirstTokenTimeoutError"

- Prüfe API Key
- Prüfe Netzwerk-Verbindung
- Erhöhe `first_token_seconds` für langsame Modelle

### "StallTimeoutError"

- Provider hat Idle-Timeout (typisch: 60s)
- Stream wurde unterbrochen
- **Kein Retry möglich** - User hat bereits Teile gesehen

### "TotalTimeoutError"

- Prompt zu komplex
- Erhöhe `total_seconds` oder vereinfache Prompt

## Tests

```bash
# Alle Beispiele ausführen
python example_usage.py

# Einzelnes Beispiel
python -c "
import asyncio
from example_usage import example_1_basic_streaming
asyncio.run(example_1_basic_streaming())
"
```

## Architektur

```
┌─────────────────────────────────────────────────────────────┐
│  Dein Code                                                  │
│  agent.stream(prompt)                                       │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│  ResilientAgent                                             │
│  - Wählt Modell basierend auf TaskType                      │
│  - Verwaltet Fallback-Kette                                 │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│  StreamingTimeoutMiddleware                                 │
│  - 3-Tier-Timeout-Handling                                  │
│  - Retry nur für Pre-First-Token                            │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│  OpenClaw / LLM Provider                                    │
└─────────────────────────────────────────────────────────────┘
```

## Lizenz

MIT
