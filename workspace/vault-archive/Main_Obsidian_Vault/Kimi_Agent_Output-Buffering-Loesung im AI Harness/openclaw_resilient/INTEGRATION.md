# OpenClaw Integration Guide

Diese Anleitung zeigt, wie du den Resilient Agent in dein bestehendes OpenClaw-Projekt integrierst.

## Voraussetzungen

- Python 3.8+
- OpenClaw installiert (`pip install openclaw`)
- API Keys für deine Provider

## Schritt-für-Schritt Integration

### Schritt 1: Dateien kopieren

```bash
# Erstelle die Ordnerstruktur in deinem Projekt
mkdir -p src/config src/core

# Kopiere die Dateien
cp openclaw_resilient/src/config/timeouts.py src/config/
cp openclaw_resilient/src/config/__init__.py src/config/
cp openclaw_resilient/src/core/model_router.py src/core/
cp openclaw_resilient/src/core/timeout_middleware.py src/core/
cp openclaw_resilient/src/core/resilient_agent.py src/core/
cp openclaw_resilient/src/core/__init__.py src/core/
cp openclaw_resilient/src/__init__.py src/
```

### Schritt 2: OpenClaw Integration anpassen

Öffne `src/core/resilient_agent.py` und passe die Methode `_create_llm_stream` an:

```python
async def _create_llm_stream(
    self,
    prompt: str,
    model: ModelCapabilities,
    system_prompt: Optional[str] = None
) -> AsyncIterator[str]:
    """
    Erstellt den tatsächlichen LLM Stream.
    
    HIER MUSST DU ANPASSEN!
    """
    if self._openclaw_available and self.openclaw_agent:
        
        # === DEINE OPENCLAW INTEGRATION ===
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        # Timeout Config zu OpenClaw Format
        config = model.timeout_profile.to_openclaw_config()
        config["model"] = model.full_id
        
        # WICHTIG: Passe dies an deine OpenClaw API an!
        # Hier sind die gängigsten Patterns:
        
        # === PATTERN 1: OpenClaw hat stream() Methode ===
        # stream = await self.openclaw_agent.stream(messages, config=config)
        # async for chunk in stream:
        #     yield chunk.content
        
        # === PATTERN 2: OpenClaw hat chat.completions.create() ===
        # response = await self.openclaw_agent.chat.completions.create(
        #     messages=messages,
        #     model=model.full_id,
        #     stream=True,
        #     **config
        # )
        # async for chunk in response:
        #     if chunk.choices[0].delta.content:
        #         yield chunk.choices[0].delta.content
        
        # === PATTERN 3: OpenClaw hat complete() mit Callback ===
        # queue = asyncio.Queue()
        # def on_chunk(chunk):
        #     queue.put_nowait(chunk)
        # await self.openclaw_agent.complete(messages, on_chunk=on_chunk)
        # while True:
        #     chunk = await queue.get()
        #     if chunk is None:
        #         break
        #     yield chunk
        
        # === DEIN CODE HIER ===
        raise NotImplementedError(
            "Passe _create_llm_stream an deine OpenClaw API an!"
        )
    
    else:
        # Mock-Modus für Testing
        async for chunk in self._mock_stream(prompt, model):
            yield chunk
```

### Schritt 3: Finde dein OpenClaw Pattern

Um die richtige Integration zu finden, teste dein aktuelles OpenClaw Setup:

```python
import asyncio
from openclaw import Agent

async def test_openclaw():
    agent = Agent()
    
    # Test 1: Hat OpenClaw eine stream() Methode?
    try:
        stream = await agent.stream(
            messages=[{"role": "user", "content": "Hallo"}],
            config={"model": "moonshot/kimi-k2"}
        )
        print("✓ stream() Methode gefunden")
        
        async for chunk in stream:
            print(f"Chunk type: {type(chunk)}")
            print(f"Chunk attrs: {dir(chunk)}")
            print(f"Chunk content: {getattr(chunk, 'content', 'N/A')}")
            break
            
    except AttributeError:
        print("✗ Keine stream() Methode")
    
    # Test 2: Hat OpenClaw chat.completions.create()?
    try:
        response = await agent.chat.completions.create(
            messages=[{"role": "user", "content": "Hallo"}],
            model="moonshot/kimi-k2",
            stream=True
        )
        print("✓ chat.completions.create() gefunden")
        
        async for chunk in response:
            print(f"Chunk type: {type(chunk)}")
            print(f"Chunk: {chunk}")
            break
            
    except AttributeError:
        print("✗ Keine chat.completions.create()")

asyncio.run(test_openclaw())
```

### Schritt 4: Typische OpenClaw Integrationen

#### Pattern A: Direkte stream() Methode

```python
async def _create_llm_stream(self, prompt, model, system_prompt=None):
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})
    
    config = model.timeout_profile.to_openclaw_config()
    config["model"] = model.full_id
    
    # OpenClaw stream()
    stream = await self.openclaw_agent.stream(messages, config=config)
    
    async for chunk in stream:
        # Versuche verschiedene Attribute
        if hasattr(chunk, 'content'):
            yield chunk.content
        elif hasattr(chunk, 'delta'):
            yield chunk.delta
        elif hasattr(chunk, 'text'):
            yield chunk.text
        elif isinstance(chunk, str):
            yield chunk
        elif isinstance(chunk, dict):
            yield chunk.get('content', '') or chunk.get('delta', '')
```

#### Pattern B: OpenAI-kompatibel

```python
async def _create_llm_stream(self, prompt, model, system_prompt=None):
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})
    
    # OpenAI-kompatibler Client
    response = await self.openclaw_agent.chat.completions.create(
        messages=messages,
        model=model.full_id,
        stream=True,
        timeout=model.timeout_profile.total_seconds
    )
    
    async for chunk in response:
        if chunk.choices and chunk.choices[0].delta:
            content = chunk.choices[0].delta.content
            if content:
                yield content
```

#### Pattern C: Callback-basiert

```python
async def _create_llm_stream(self, prompt, model, system_prompt=None):
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})
    
    queue = asyncio.Queue()
    
    def on_chunk(chunk):
        queue.put_nowait(chunk)
    
    def on_complete():
        queue.put_nowait(None)  # Signal Ende
    
    # Starte Completion
    asyncio.create_task(
        self.openclaw_agent.complete(
            messages,
            model=model.full_id,
            on_chunk=on_chunk,
            on_complete=on_complete
        )
    )
    
    # Yield Chunks
    while True:
        chunk = await queue.get()
        if chunk is None:
            break
        yield chunk.content if hasattr(chunk, 'content') else str(chunk)
```

### Schritt 5: Testen

```python
import asyncio
from src.core.resilient_agent import ResilientAgent
from src.core.model_router import TaskType

async def test():
    agent = ResilientAgent(preferred_provider="moonshot")
    
    print("Teste Streaming...")
    async for chunk in agent.stream(
        "Schreibe 'Hello World' in Python",
        task_type=TaskType.CODING
    ):
        print(chunk, end="", flush=True)
    
    print("\n\nTeste Non-Streaming...")
    response = await agent.run("Was ist 2+2?")
    print(f"Antwort: {response.content}")
    print(f"Modell: {response.model_used}")
    print(f"TTFT: {response.metrics.ttft:.2f}s")

asyncio.run(test())
```

### Schritt 6: openclaw.json aktualisieren

Füge zu deiner bestehenden `openclaw.json` hinzu:

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
        "fallbacks": [
          "moonshot/kimi-k2",
          "openai/gpt-5.2"
        ],
        "failover": {
          "enabled": true,
          "retryPrimaryAfterSeconds": 900,
          "on": ["rate_limit", "timeout", "stall"]
        }
      }
    }
  },
  "models": {
    "providers": {
      "moonshot": {
        "baseUrl": "https://api.moonshot.cn/v1",
        "apiKey": "${MOONSHOT_API_KEY}"
      }
    }
  }
}
```

## Troubleshooting

### "AttributeError: 'Agent' object has no attribute 'stream'"

Dein OpenClaw hat keine `stream()` Methode. Finde die richtige Methode:

```python
# Liste alle Methoden
print(dir(agent))

# Oder: Schau in die OpenClaw Doku
help(agent)
```

### "Chunk hat kein 'content' Attribut"

Finde heraus, wie deine Chunks strukturiert sind:

```python
async for chunk in stream:
    print(f"Type: {type(chunk)}")
    print(f"Dict: {chunk.__dict__ if hasattr(chunk, '__dict__') else 'N/A'}")
    print(f"Dir: {[attr for attr in dir(chunk) if not attr.startswith('_')]}")
    break
```

### "Timeout funktioniert nicht"

Prüfe, ob OpenClaw eigene Timeouts hat:

```python
# In openclaw.json
{
  "agents": {
    "defaults": {
      "timeoutSeconds": 900,  <-- Dieser Wert
      "llm": {
        "idleTimeoutSeconds": 120,  <-- Und dieser
        "stallTimeoutSeconds": 45   <-- Und dieser
      }
    }
  }
}
```

Die Resilient Agent Timeouts sollten **kürzer** sein als die OpenClaw Timeouts.

## Debugging

Aktiviere Logging:

```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

Du siehst dann:
- Welches Modell gewählt wurde
- Wann der erste Token ankommt
- Wenn ein Timeout auftritt
- Wenn ein Fallback stattfindet

## Nächste Schritte

1. **Passe `_create_llm_stream` an** deine OpenClaw API an
2. **Teste mit Mock-Modus** (ohne API Keys)
3. **Füge deine API Keys hinzu**
4. **Teste mit echten Requests**
5. **Optimiere Timeouts** basierend auf deinen Beobachtungen
