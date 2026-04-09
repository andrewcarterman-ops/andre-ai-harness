"""
Tests für den Resilient Agent
=============================

Ausführen mit:
    python -m pytest tests/test_resilient_agent.py -v
    
Oder:
    python tests/test_resilient_agent.py
"""

import asyncio
import pytest
from unittest.mock import AsyncMock, MagicMock, patch

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.core.resilient_agent import ResilientAgent, AgentResponse
from src.core.model_router import TaskType, ModelRouter
from src.core.timeout_middleware import (
    StreamingTimeoutMiddleware,
    FirstTokenTimeoutError,
    StallTimeoutError,
    TotalTimeoutError,
    StreamMetrics
)
from src.config.timeouts import get_timeout_profile


# =============================================================================
# TESTS: Timeout Profile
# =============================================================================

def test_get_timeout_profile_existing():
    """Test: Timeout-Profile für bekannte Modelle"""
    profile = get_timeout_profile("kimi-k2-thinking")
    assert profile.first_token_seconds == 120.0
    assert profile.stall_seconds == 60.0
    assert profile.total_seconds == 900.0


def test_get_timeout_profile_unknown():
    """Test: Fallback für unbekannte Modelle"""
    profile = get_timeout_profile("unknown-model")
    assert profile.first_token_seconds == 60.0  # Default
    assert profile.stall_seconds == 30.0


# =============================================================================
# TESTS: Model Router
# =============================================================================

def test_model_router_select_coding():
    """Test: Modellauswahl für Coding-Task"""
    router = ModelRouter()
    model = router.select_model(TaskType.CODING)
    
    assert model.id == "kimi-k2-coding"
    assert model.supports_tools is True


def test_model_router_select_reasoning():
    """Test: Modellauswahl für Reasoning-Task"""
    router = ModelRouter()
    model = router.select_model(
        TaskType.REASONING,
        require_reasoning=True
    )
    
    assert model.supports_reasoning is True


def test_model_router_long_context():
    """Test: Modellauswahl für Long Context"""
    router = ModelRouter()
    model = router.select_model(
        TaskType.LONG_CONTEXT,
        context_length=150000
    )
    
    # Muss mindestens 200k Kontext haben (mit 15% Margin)
    assert model.context_window >= 200000


def test_model_router_preferred_provider():
    """Test: Bevorzugter Provider"""
    router = ModelRouter()
    model = router.select_model(
        TaskType.QUICK_CHAT,
        preferred_provider="openai"
    )
    
    assert model.provider == "openai"


def test_model_router_fallback_chain():
    """Test: Fallback-Kette erstellen"""
    router = ModelRouter()
    chain = router.get_fallback_chain(TaskType.CODING)
    
    assert len(chain) >= 2
    assert chain[0].id == "kimi-k2-coding"


# =============================================================================
# TESTS: Timeout Middleware
# =============================================================================

@pytest.mark.asyncio
async def test_middleware_successful_stream():
    """Test: Erfolgreicher Stream"""
    
    async def mock_stream():
        yield "Hello"
        yield " "
        yield "World"
    
    middleware = StreamingTimeoutMiddleware(
        first_token_timeout=5.0,
        stall_timeout=5.0,
        total_timeout=10.0
    )
    
    chunks = []
    async for chunk in middleware.wrap_stream(mock_stream):
        chunks.append(chunk)
    
    assert chunks == ["Hello", " ", "World"]


@pytest.mark.asyncio
async def test_middleware_first_token_timeout():
    """Test: First-Token-Timeout"""
    
    async def slow_stream():
        await asyncio.sleep(10)  # Zu langsam
        yield "too late"
    
    middleware = StreamingTimeoutMiddleware(
        first_token_timeout=0.1,  # Sehr kurz für Test
        stall_timeout=5.0,
        total_timeout=10.0
    )
    
    with pytest.raises(FirstTokenTimeoutError):
        async for chunk in middleware.wrap_stream(slow_stream):
            pass


@pytest.mark.asyncio
async def test_middleware_stall_timeout():
    """Test: Stall-Timeout"""
    
    async def stalling_stream():
        yield "first"
        await asyncio.sleep(10)  # Stall
        yield "second"
    
    middleware = StreamingTimeoutMiddleware(
        first_token_timeout=5.0,
        stall_timeout=0.1,  # Sehr kurz für Test
        total_timeout=10.0
    )
    
    chunks = []
    with pytest.raises(StallTimeoutError):
        async for chunk in middleware.wrap_stream(stalling_stream):
            chunks.append(chunk)
    
    # Erster Chunk sollte durchgekommen sein
    assert chunks == ["first"]


@pytest.mark.asyncio
async def test_middleware_metrics():
    """Test: Metriken werden gesammelt"""
    
    async def mock_stream():
        yield "a"
        yield "b"
        yield "c"
    
    middleware = StreamingTimeoutMiddleware(
        first_token_timeout=5.0,
        stall_timeout=5.0,
        total_timeout=10.0
    )
    
    collected_metrics = None
    def on_metrics(m):
        nonlocal collected_metrics
        collected_metrics = m
    
    async for chunk in middleware.wrap_stream(mock_stream, on_metrics=on_metrics):
        pass
    
    assert collected_metrics is not None
    assert collected_metrics.total_tokens == 3
    assert collected_metrics.ttft is not None


@pytest.mark.asyncio
async def test_middleware_retry_success():
    """Test: Retry nach FirstTokenTimeout funktioniert"""
    
    attempt = 0
    
    def stream_factory():
        nonlocal attempt
        attempt += 1
        
        async def stream():
            if attempt == 1:
                await asyncio.sleep(10)  # Fail first
                yield "fail"
            else:
                yield "success"
        
        return stream()
    
    middleware = StreamingTimeoutMiddleware(
        first_token_timeout=0.1,
        stall_timeout=5.0,
        total_timeout=10.0
    )
    
    chunks = []
    async for chunk in middleware.wrap_with_retry(
        stream_factory,
        max_retries=2
    ):
        chunks.append(chunk)
    
    assert attempt == 2  # Retry hat funktioniert
    assert chunks == ["success"]


# =============================================================================
# TESTS: Resilient Agent
# =============================================================================

@pytest.mark.asyncio
async def test_agent_initialization():
    """Test: Agent Initialisierung"""
    agent = ResilientAgent(
        default_task_type=TaskType.CODING,
        preferred_provider="moonshot"
    )
    
    assert agent.default_task_type == TaskType.CODING
    assert agent.preferred_provider == "moonshot"


@pytest.mark.asyncio
async def test_agent_mock_stream():
    """Test: Mock Stream funktioniert"""
    agent = ResilientAgent()
    
    # Mock-Modus (kein OpenClaw)
    chunks = []
    async for chunk in agent.stream("Test prompt"):
        chunks.append(chunk)
    
    assert len(chunks) > 0
    assert any("kimi" in chunk.lower() for chunk in chunks)


@pytest.mark.asyncio
async def test_agent_run_non_streaming():
    """Test: Non-streaming Ausführung"""
    agent = ResilientAgent()
    
    response = await agent.run("Test prompt")
    
    assert isinstance(response, AgentResponse)
    assert len(response.content) > 0
    assert response.model_used != "unknown"


@pytest.mark.asyncio
async def test_agent_with_callbacks():
    """Test: Callbacks werden aufgerufen"""
    agent = ResilientAgent()
    
    chunks_received = []
    metrics_received = None
    
    def on_chunk(chunk):
        chunks_received.append(chunk)
    
    def on_metrics(m):
        nonlocal metrics_received
        metrics_received = m
    
    async for chunk in agent.stream(
        "Test",
        on_chunk=on_chunk,
        on_metrics=on_metrics
    ):
        pass
    
    assert len(chunks_received) > 0
    assert metrics_received is not None


# =============================================================================
# INTEGRATION TESTS
# =============================================================================

@pytest.mark.asyncio
async def test_full_flow():
    """Test: Kompletter Flow von Router zu Middleware"""
    
    # 1. Modell wählen
    router = ModelRouter()
    model = router.select_model(TaskType.CODING)
    
    # 2. Timeout Profile holen
    profile = get_timeout_profile(model.id)
    
    # 3. Middleware erstellen
    middleware = StreamingTimeoutMiddleware(
        first_token_timeout=profile.first_token_seconds,
        stall_timeout=profile.stall_seconds,
        total_timeout=profile.total_seconds
    )
    
    # 4. Stream simulieren
    async def mock_stream():
        yield "def fib(n):"
        yield "\n    "
        yield "if n <= 1:"
        yield " return n"
    
    chunks = []
    async for chunk in middleware.wrap_stream(mock_stream):
        chunks.append(chunk)
    
    result = "".join(chunks)
    assert "def fib" in result


# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    # Führe alle Tests aus
    pytest.main([__file__, "-v"])
