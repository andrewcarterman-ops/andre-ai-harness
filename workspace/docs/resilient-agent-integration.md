# Integration: Resilient Agent in OpenClaw

## Übersicht

Dieses Dokument beschreibt die Integration des **Resilient Agent** Packages in das OpenClaw-Projekt.

## Was ist der Resilient Agent?

Der Resilient Agent ist ein Python-Package, das robustes LLM-Streaming mit folgenden Features bietet:

- **3-Tier-Timeout-Handling**: First-Token, Stall, Total
- **Automatisches Failover**: Fallback zu alternativen Modellen
- **Task-basierte Modellauswahl**: Optimale Modelle für CODING, REASONING, etc.
- **Metriken**: TTFT (Time To First Token), Tokens/Sekunde

## Projektstruktur

```
.openclaw/workspace/
├── packages/
│   └── resilient-agent/          # Python-Package
│       ├── src/resilient_agent/
│       │   ├── __init__.py
│       │   ├── agent.py          # Hauptklasse
│       │   ├── model_router.py   # Modellauswahl
│       │   ├── timeout_middleware.py
│       │   ├── timeout_config.py
│       │   └── config_loader.py  # OpenClaw-Integration
│       ├── tests/
│       ├── examples/
│       └── README.md
├── registry/
│   └── skills.yaml               # Optional: Skill registrieren
└── openclaw.json                 # Konfiguration
```

## Installation

```bash
cd packages/resilient-agent
pip install -e .
```

## OpenClaw-Konfiguration

Die `openclaw.json` wurde angepasst:

```json
{
  "agents": {
    "defaults": {
      "timeoutSeconds": 900,
      "model": "kimi-coding/k2p5",
      "sandbox": {"mode": "non-main"},
      "workspace": "...",
      "compaction": {"mode": "safeguard"}
    }
  },
  "tools": {
    "exec": {
      "host": "gateway"
    }
  }
}
```

### Wichtige Änderungen

1. **timeoutSeconds**: Gesamt-Timeout für LLM-Requests
2. **sandbox.mode**: Aktiviert Sandbox für sichere Code-Ausführung
3. **tools.exec.host**: Erlaubt Tool-Ausführung im Gateway

## Verwendung

### Basic

```python
from resilient_agent import ResilientAgent, TaskType

agent = ResilientAgent()

# Streaming
async for chunk in agent.stream("Hallo"):
    print(chunk, end="")

# Non-Streaming
response = await agent.run("Frage?")
print(response.content)
```

### Mit OpenClaw-Config

```python
from resilient_agent import OpenClawConfigLoader

loader = OpenClawConfigLoader()
config = loader.get_agent_config()

print(f"Timeout: {config.timeout_seconds}s")
print(f"Model: {config.model}")
```

## Task-Typen

| TaskType | Beschreibung | Primäres Modell |
|----------|--------------|-----------------|
| CODING | Code-Generierung | k2p5 |
| REASONING | Komplexes Denken | kimi-k2-thinking |
| QUICK_CHAT | Schnelle Antworten | k2p5 |
| LONG_CONTEXT | Lange Dokumente | k2p5 (262k) |
| TOOL_HEAVY | Viele Tool-Calls | k2p5 |
| CREATIVE | Kreative Texte | claude-sonnet-4-6 |

## Timeout-Strategie

```
First-Token-Timeout:  Wartezeit bis erstes Token
                      → Retry bei Timeout (Verbindungsproblem)

Stall-Timeout:        Pause zwischen Tokens
                      → KEIN Retry (User hat schon Teile gesehen)

Total-Timeout:        Absolute Obergrenze
                      → KEIN Retry (harter Cutoff)
```

## Tests

Alle 26 Tests bestehen:

```bash
cd packages/resilient-agent
python -m pytest tests/ -v
```

## Troubleshooting

### Gateway startet nicht

**Problem**: Config-Validierung schlägt fehl

**Lösung**: Prüfe `openclaw.json`:
- `model` muss ein String sein (nicht Objekt)
- `sandbox` muss gesetzt sein
- `tools.exec.host` muss gesetzt sein

### Module nicht gefunden

**Problem**: Package nicht installiert

**Lösung**:
```bash
cd packages/resilient-agent
pip install -e .
```

### Timeouts zu kurz

**Problem**: Komplexe Requests werden abgebrochen

**Lösung**: Passe `timeoutSeconds` in `openclaw.json` an:
```json
{
  "agents": {
    "defaults": {
      "timeoutSeconds": 1200
    }
  }
}
```

## Nächste Schritte

- [ ] Echte OpenClaw-Stream-Integration (statt Mock)
- [ ] Fallback-Provider konfigurieren (OpenAI, Anthropic)
- [ ] Metriken in Logs/Memory speichern
- [ ] Performance-Optimierungen

## Referenzen

- Package: `packages/resilient-agent/`
- README: `packages/resilient-agent/README.md`
- Tests: `packages/resilient-agent/tests/`
- Demo: `packages/resilient-agent/examples/demo.py`
