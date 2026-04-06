"""
Tests für den OpenClaw Resilient Agent
=====================================

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

# Füge src zum Pfad hinzu
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from resilient_agent import (
    ResilientAgent,
    AgentResponse,
    ModelRouter,
    TaskType,
    TimeoutProfile,
    get_timeout_profile,
    StreamingTimeoutMiddleware,
    FirstTokenTimeoutError,
    StallTimeoutError,
    TotalTimeoutError,
    StreamMetrics,
)


# =============================================================================
# TESTS: Timeout Profile
# =============================================================================

class TestTimeoutProfile:
    """Tests für Timeout-Profile"""
    
    def test_get_timeout_profile_existing(self):
        """Test: Timeout-Profile für bekannte Modelle"""
        profile = get_timeout_profile("kimi-k2-thinking")
        assert profile.first_token_seconds == 120.0
        assert profile.stall_seconds == 60.0
        assert profile.total_seconds == 900.0
        assert profile.retry_attempts == 2
    
    def test_get_timeout_profile_k2p5(self):
        """Test: Timeout-Profile für OpenClaw k2p5"""
        profile = get_timeout_profile("k2p5")
        assert profile.first_token_seconds == 90.0
        assert profile.stall_seconds == 45.0
        assert profile.total_seconds == 600.0
    
    def test_get_timeout_profile_unknown(self):
        """Test: Fallback für unbekannte Modelle"""
        profile = get_timeout_profile("unknown-model")
        assert profile.first_token_seconds == 60.0  # Default
        assert profile.stall_seconds == 30.0
        assert profile.total_seconds == 600.0
        assert profile.retry_attempts == 3
    
    def test_timeout_profile_to_openclaw_config(self):
        """Test: Konvertierung zu OpenClaw Config"""
        profile = TimeoutProfile(
            first_token_seconds=60.0,
            stall_seconds=30.0,
            total_seconds=600.0,
            retry_attempts=3
        )
        config = profile.to_openclaw_config()
        
        assert config["timeoutSeconds"] == 600
        assert config["llm"]["idleTimeoutSeconds"] == 60
        assert config["llm"]["stallTimeoutSeconds"] == 30


# =============================================================================
# TESTS: Model Router
# =============================================================================

class TestModelRouter:
    """Tests für Model Router"""
    
    def test_model_router_select_coding(self):
        """Test: Modellauswahl für Coding-Task"""
        router = ModelRouter()
        model = router.select_model(TaskType.CODING)
        
        assert model.id == "k2p5"  # OpenClaw Standard
        assert model.provider == "kimi-coding"
        assert model.supports_tools is True
    
    def test_model_router_select_reasoning(self):
        """Test: Modellauswahl für Reasoning-Task"""
        router = ModelRouter()
        model = router.select_model(
            TaskType.REASONING,
            require_reasoning=True
        )
        
        assert model.supports_reasoning is True
        assert model.id in ["kimi-k2-thinking", "k2p5"]
    
    def test_model_router_long_context(self):
        """Test: Modellauswahl für Long Context"""
        router = ModelRouter()
        model = router.select_model(
            TaskType.LONG_CONTEXT,
            context_length=150000
        )
        
        # Muss mindestens 200k Kontext haben (mit 15% Margin)
        assert model.context_window >= 200000
    
    def test_model_router_preferred_provider(self):
        """Test: Bevorzugter Provider"""
        router = ModelRouter()
        model = router.select_model(
            TaskType.QUICK_CHAT,
            preferred_provider="openai"
        )
        
        assert model.provider == "openai"
    
    def test_model_router_fallback_chain(self):
        """Test: Fallback-Kette erstellen"""
        router = ModelRouter()
        chain = router.get_fallback_chain(TaskType.CODING)
        
        assert len(chain) >= 2
        assert chain[0].id == "k2p5"
        
        # Alle Modelle sollten unterschiedlich sein
        ids = [m.id for m in chain]
        assert len(ids) == len(set(ids))
    
    def test_model_router_list_available(self):
        """Test: Verfügbare Modelle auflisten"""
        router = ModelRouter()
        models = router.list_available_models(TaskType.CODING)
        
        assert "k2p5" in models
        assert len(models) >= 3
    
    def test_model_router_get_model_info(self):
        """Test: Modell-Info abrufen"""
        router = ModelRouter()
        info = router.get_model_info("k2p5")
        
        assert info is not None
        assert info.id == "k2p5"
        assert info.provider == "kimi-coding"


# =============================================================================
# TESTS: Timeout Middleware
# =============================================================================

@pytest.mark.asyncio
class TestTimeoutMiddleware:
    """Tests für Timeout Middleware"""
    
    async def test_middleware_successful_stream(self):
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
    
    async def test_middleware_first_token_timeout(self):
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
    
    async def test_middleware_stall_timeout(self):
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
    
    async def test_middleware_metrics(self):
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
    
    async def test_middleware_retry_success(self):
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
    
    async def test_middleware_no_retry_on_stall(self):
        """Test: Kein Retry bei Stall nach erstem Token"""
        
        async def stalling_stream():
            yield "first"
            await asyncio.sleep(10)
            yield "second"
        
        middleware = StreamingTimeoutMiddleware(
            first_token_timeout=5.0,
            stall_timeout=0.1,
            total_timeout=10.0
        )
        
        with pytest.raises(StallTimeoutError):
            async for chunk in middleware.wrap_with_retry(
                stalling_stream,
                max_retries=3
            ):
                pass
    
    async def test_middleware_total_timeout(self):
        """Test: Total-Timeout"""
        
        async def slow_stream():
            yield "start"
            await asyncio.sleep(10)
            yield "end"
        
        middleware = StreamingTimeoutMiddleware(
            first_token_timeout=5.0,
            stall_timeout=30.0,
            total_timeout=0.1  # Sehr kurz
        )
        
        with pytest.raises(TotalTimeoutError):
            async for chunk in middleware.wrap_stream(slow_stream):
                pass


# =============================================================================
# TESTS: Resilient Agent
# =============================================================================

@pytest.mark.asyncio
class TestResilientAgent:
    """Tests für Resilient Agent"""
    
    async def test_agent_initialization(self):
        """Test: Agent Initialisierung"""
        agent = ResilientAgent(
            default_task_type=TaskType.CODING,
            preferred_provider="kimi-coding"
        )
        
        assert agent.default_task_type == TaskType.CODING
        assert agent.preferred_provider == "kimi-coding"
    
    async def test_agent_mock_stream(self):
        """Test: Mock Stream funktioniert"""
        agent = ResilientAgent()
        
        # Mock-Modus (kein OpenClaw)
        chunks = []
        async for chunk in agent.stream("Test prompt"):
            chunks.append(chunk)
        
        assert len(chunks) > 0
        # Sollte Modell-Namen enthalten
        assert any("k2p5" in chunk or "kimi" in chunk.lower() for chunk in chunks)
    
    async def test_agent_run_non_streaming(self):
        """Test: Non-streaming Ausführung"""
        agent = ResilientAgent()
        
        response = await agent.run("Test prompt")
        
        assert isinstance(response, AgentResponse)
        assert len(response.content) > 0
        assert response.model_used != "unknown"
    
    async def test_agent_with_callbacks(self):
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
    
    async def test_agent_task_type_coding(self):
        """Test: Coding Task wählt richtiges Modell"""
        agent = ResilientAgent()
        
        response = await agent.run(
            "Schreibe Python Code",
            task_type=TaskType.CODING
        )
        
        assert response.model_used is not None
        assert "kimi-coding" in response.model_used or "k2p5" in response.model_used
    
    async def test_agent_model_override(self):
        """Test: Spezifisches Modell erzwingen"""
        agent = ResilientAgent()
        
        response = await agent.run(
            "Test",
            model_override="k2p5"
        )
        
        assert "k2p5" in response.model_used


# =============================================================================
# INTEGRATION TESTS
# =============================================================================

@pytest.mark.asyncio
class TestIntegration:
    """Integration Tests"""
    
    async def test_full_flow_router_to_middleware(self):
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
    
    async def test_end_to_end_mock(self):
        """Test: End-to-End mit Mock"""
        agent = ResilientAgent(
            preferred_provider="kimi-coding"
        )
        
        response = await agent.run(
            "Erkläre Rekursion",
            task_type=TaskType.REASONING
        )
        
        assert response.content
        assert response.metrics.ttft is not None
        assert response.metrics.total_duration > 0


# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    # Führe alle Tests aus
    pytest.main([__file__, "-v"])
