"""
SCHRITT 4: Resilient Agent (Hauptklasse)
========================================
Diese Datei bindet alles zusammen.
Kopiere nach: src/core/resilient_agent.py

Das ist deine Haupt-API. Alles andere ist intern.
"""

import asyncio
import os
import logging
from typing import AsyncIterator, Optional, Callable, List, Any
from dataclasses import dataclass

# Logger setup
logger = logging.getLogger(__name__)

# Importe aus diesem Projekt
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from config.timeouts import TimeoutProfile, get_timeout_profile
from core.model_router import ModelRouter, TaskType, ModelCapabilities
from core.timeout_middleware import (
    StreamingTimeoutMiddleware,
    StreamMetrics,
    FirstTokenTimeoutError,
    StallTimeoutError,
    TotalTimeoutError
)


# =============================================================================
# DATA CLASSES
# =============================================================================

@dataclass
class AgentResponse:
    """Strukturierte Antwort des Agents"""
    content: str
    model_used: str
    metrics: StreamMetrics
    fallback_used: bool = False
    retry_count: int = 0
    errors: List[str] = None
    
    def __post_init__(self):
        if self.errors is None:
            self.errors = []


@dataclass  
class StreamEvent:
    """Event aus dem Stream"""
    type: str  # "chunk", "error", "model_switch", "complete"
    data: Any
    model_id: Optional[str] = None


# =============================================================================
# RESILIENT AGENT
# =============================================================================

class ResilientAgent:
    """
    Produktionsreifer OpenClaw-Wrapper mit:
    - Intelligenter Modellauswahl
    - 3-Tier-Timeout-Handling
    - Automatischem Failover
    - Retry nur für Pre-First-Token-Failures
    
    Usage:
        agent = ResilientAgent(default_task_type=TaskType.CODING)
        
        # Streaming
        async for chunk in agent.stream("Schreibe eine Fibonacci-Funktion"):
            print(chunk, end="")
        
        # Non-streaming
        response = await agent.run("Erkläre Quantum Computing")
        print(response.content)
        print(f"Model: {response.model_used}")
        print(f"TTFT: {response.metrics.ttft:.2f}s")
    """
    
    def __init__(
        self,
        default_task_type: TaskType = TaskType.QUICK_CHAT,
        preferred_provider: Optional[str] = "moonshot",
        openclaw_config_path: Optional[str] = None
    ):
        """
        Initialisiert den Resilient Agent.
        
        Args:
            default_task_type: Standard-Task-Typ wenn nicht angegeben
            preferred_provider: Bevorzugter Provider ("moonshot", "openai", etc.)
            openclaw_config_path: Pfad zur openclaw.json (optional)
        """
        self.router = ModelRouter()
        self.default_task_type = default_task_type
        self.preferred_provider = preferred_provider
        self.openclaw_config_path = openclaw_config_path
        
        # OpenClaw Integration (lazy)
        self._openclaw_agent = None
        self._openclaw_available = False
        
        # Versuche OpenClaw zu importieren
        try:
            import openclaw
            self._openclaw_available = True
            logger.info("OpenClaw verfügbar")
        except ImportError:
            logger.warning(
                "OpenClaw nicht installiert. "
                "Verwende Mock-Modus für Testing."
            )
    
    @property
    def openclaw_agent(self):
        """Lazy initialization des OpenClaw Agents"""
        if self._openclaw_agent is None and self._openclaw_available:
            try:
                from openclaw import Agent
                self._openclaw_agent = Agent()
                logger.info("OpenClaw Agent initialisiert")
            except Exception as e:
                logger.error(f"Fehler bei OpenClaw Initialisierung: {e}")
                self._openclaw_available = False
        return self._openclaw_agent
    
    # =====================================================================
    # PUBLIC API: STREAMING
    # =====================================================================
    
    async def stream(
        self,
        prompt: str,
        task_type: Optional[TaskType] = None,
        context_length: int = 0,
        require_reasoning: bool = False,
        require_tools: bool = False,
        model_override: Optional[str] = None,
        system_prompt: Optional[str] = None,
        on_chunk: Optional[Callable[[str], None]] = None,
        on_metrics: Optional[Callable[[StreamMetrics], None]] = None,
        on_model_switch: Optional[Callable[[str, str], None]] = None
    ) -> AsyncIterator[str]:
        """
        Streaming-Ausführung mit automatischem Failover.
        
        Args:
            prompt: Der Prompt für das LLM
            task_type: Art der Aufgabe (CODING, REASONING, etc.)
            context_length: Geschätzte Token-Anzahl
            require_reasoning: Ob Reasoning benötigt wird
            require_tools: Ob Tool-Calls benötigt werden
            model_override: Spezifisches Modell erzwingen
            system_prompt: Optionaler System-Prompt
            on_chunk: Callback für jeden Chunk
            on_metrics: Callback mit Metriken nach Stream-Ende
            on_model_switch: Callback(old_model, new_model) bei Fallback
            
        Yields:
            Einzelne Text-Chunks
        """
        task = task_type or self.default_task_type
        
        # Fallback-Kette erstellen
        if model_override:
            # Spezifisches Modell erzwungen
            model = self.router.registry.MODELS.get(model_override)
            fallback_chain = [model] if model else []
            logger.info(f"Modell override: {model_override}")
        else:
            fallback_chain = self.router.get_fallback_chain(
                task_type=task,
                preferred_provider=self.preferred_provider
            )
            logger.info(
                f"Fallback-Kette für {task.name}: "
                f"{[m.full_id for m in fallback_chain]}"
            )
        
        if not fallback_chain:
            raise ValueError("Keine Modelle für den Task verfügbar")
        
        # Versuche jedes Modell in der Kette
        errors = []
        
        for idx, model in enumerate(fallback_chain):
            try:
                if idx > 0:
                    old_model = fallback_chain[idx-1].full_id
                    new_model = model.full_id
                    logger.warning(f"Fallback: {old_model} -> {new_model}")
                    if on_model_switch:
                        on_model_switch(old_model, new_model)
                
                async for chunk in self._try_stream_with_model(
                    prompt=prompt,
                    model=model,
                    system_prompt=system_prompt,
                    on_chunk=on_chunk,
                    on_metrics=on_metrics
                ):
                    yield chunk
                
                return  # Erfolg!
                
            except (FirstTokenTimeoutError, StallTimeoutError, TotalTimeoutError) as e:
                error_msg = f"{model.full_id}: {type(e).__name__}: {str(e)}"
                errors.append(error_msg)
                logger.error(error_msg)
                
                # Entscheide, ob wir zum nächsten Fallback gehen
                if isinstance(e, StallTimeoutError):
                    # Stream hat begonnen - nicht retryen
                    logger.error("Stream-Stall nach erstem Token - Abbruch!")
                    raise
                    
                if idx < len(fallback_chain) - 1:
                    logger.info(f"Versuche nächstes Modell...")
                    continue
                else:
                    logger.error("Alle Modelle failed!")
                    raise
                    
            except Exception as e:
                error_msg = f"{model.full_id}: Unexpected: {type(e).__name__}: {str(e)}"
                errors.append(error_msg)
                logger.exception(error_msg)
                
                if idx < len(fallback_chain) - 1:
                    continue
                raise
        
        # Sollte nie hier ankommen
        raise RuntimeError(f"Alle Modelle failed: {errors}")
    
    # =====================================================================
    # PUBLIC API: NON-STREAMING
    # =====================================================================
    
    async def run(
        self,
        prompt: str,
        task_type: Optional[TaskType] = None,
        context_length: int = 0,
        require_reasoning: bool = False,
        require_tools: bool = False,
        model_override: Optional[str] = None,
        system_prompt: Optional[str] = None
    ) -> AgentResponse:
        """
        Nicht-streaming Ausführung - sammelt alle Chunks.
        
        Returns:
            AgentResponse mit content, model_used, metrics, etc.
        """
        chunks = []
        final_metrics = None
        model_used = None
        fallback_used = False
        retry_count = 0
        errors = []
        
        async for chunk in self.stream(
            prompt=prompt,
            task_type=task_type,
            context_length=context_length,
            require_reasoning=require_reasoning,
            require_tools=require_tools,
            model_override=model_override,
            system_prompt=system_prompt,
            on_chunk=lambda c: chunks.append(c),
            on_metrics=lambda m: setattr(self, '_last_metrics', m),
            on_model_switch=lambda old, new: setattr(self, '_fallback_used', True)
        ):
            pass
        
        # Extrahiere Metadaten
        content = "".join(chunks)
        
        # Versuche, das tatsächlich verwendete Modell zu ermitteln
        if hasattr(self, '_last_model'):
            model_used = self._last_model
        
        if hasattr(self, '_fallback_used'):
            fallback_used = self._fallback_used
        
        if hasattr(self, '_last_metrics'):
            final_metrics = self._last_metrics
        else:
            final_metrics = StreamMetrics()
        
        return AgentResponse(
            content=content,
            model_used=model_used or "unknown",
            metrics=final_metrics,
            fallback_used=fallback_used,
            retry_count=retry_count,
            errors=errors
        )
    
    # =====================================================================
    # INTERNAL METHODS
    # =====================================================================
    
    async def _try_stream_with_model(
        self,
        prompt: str,
        model: ModelCapabilities,
        system_prompt: Optional[str] = None,
        on_chunk: Optional[Callable[[str], None]] = None,
        on_metrics: Optional[Callable[[StreamMetrics], None]] = None
    ) -> AsyncIterator[str]:
        """
        Versucht einen Stream mit einem spezifischen Modell.
        """
        logger.info(f"Versuche Stream mit {model.full_id}")
        
        # Speichere für spätere Referenz
        self._last_model = model.full_id
        
        # Timeout Middleware konfigurieren
        timeout_middleware = StreamingTimeoutMiddleware(
            first_token_timeout=model.timeout_profile.first_token_seconds,
            stall_timeout=model.timeout_profile.stall_seconds,
            total_timeout=model.timeout_profile.total_timeout_seconds
        )
        
        # Stream Factory erstellen
        def create_stream():
            return self._create_llm_stream(
                prompt=prompt,
                model=model,
                system_prompt=system_prompt
            )
        
        # Stream mit Timeout und Retry
        collected_metrics = None
        
        def capture_metrics(m):
            nonlocal collected_metrics
            collected_metrics = m
            self._last_metrics = m
            if on_metrics:
                on_metrics(m)
        
        async for chunk in timeout_middleware.wrap_with_retry(
            stream_factory=create_stream,
            max_retries=model.timeout_profile.retry_attempts,
            on_metrics=capture_metrics,
            on_first_token=lambda ttft: logger.info(
                f"{model.full_id}: First token nach {ttft:.2f}s"
            )
        ):
            if on_chunk:
                on_chunk(chunk)
            yield chunk
    
    async def _create_llm_stream(
        self,
        prompt: str,
        model: ModelCapabilities,
        system_prompt: Optional[str] = None
    ) -> AsyncIterator[str]:
        """
        Erstellt den tatsächlichen LLM Stream.
        
        HIER IST DER INTEGRATIONSPUNKT ZU OPENCLAW!
        
        Passe diese Methode an deine OpenClaw-Version an.
        """
        if self._openclaw_available and self.openclaw_agent:
            # === ECHTE OPENCLAW INTEGRATION ===
            # Passe dies an deine OpenClaw API an
            
            messages = []
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": prompt})
            
            # OpenClaw-spezifische Config
            config = model.timeout_profile.to_openclaw_config()
            config["model"] = model.full_id
            
            try:
                # Annahme: OpenClaw hat eine stream-Methode
                # Passe dies an deine tatsächliche API an!
                stream = await self.openclaw_agent.stream(
                    messages=messages,
                    config=config
                )
                
                async for chunk in stream:
                    # Extrahiere Text aus Chunk
                    # Passe an dein Chunk-Format an!
                    if hasattr(chunk, 'content'):
                        yield chunk.content
                    elif hasattr(chunk, 'delta'):
                        yield chunk.delta
                    elif isinstance(chunk, str):
                        yield chunk
                    elif isinstance(chunk, dict):
                        yield chunk.get('content', '') or chunk.get('delta', '')
                    else:
                        yield str(chunk)
                        
            except Exception as e:
                logger.error(f"OpenClaw Stream Fehler: {e}")
                raise
        
        else:
            # === MOCK MODUS (für Testing) ===
            logger.debug(f"Mock Stream für {model.full_id}")
            async for chunk in self._mock_stream(prompt, model):
                yield chunk
    
    async def _mock_stream(
        self,
        prompt: str,
        model: ModelCapabilities
    ) -> AsyncIterator[str]:
        """
        Mock-Stream für Testing ohne OpenClaw.
        
        Simuliert realistisches Verhalten mit Delays.
        """
        import random
        
        # Simuliere First-Token-Delay basierend auf Modell
        first_token_delay = {
            "kimi-k2-thinking": (1.0, 3.0),
            "kimi-k2": (0.5, 1.5),
            "kimi-k2-coding": (0.8, 2.0),
            "gpt-5.2": (0.3, 0.8),
            "gpt-5.2-coding": (0.4, 1.0),
            "claude-sonnet-4-6": (0.6, 1.5),
        }.get(model.id, (0.5, 1.0))
        
        await asyncio.sleep(random.uniform(*first_token_delay))
        
        # Simuliere Antwort
        words = [
            "Hier", "ist", "eine", "Antwort", "vom",
            model.id.replace("-", " ").title(),
            "Modell.", "Es", "kann", "Code,", "Reasoning",
            "und", "mehr."
        ]
        
        for word in words:
            await asyncio.sleep(random.uniform(0.05, 0.15))
            yield word + " "
        
        yield f"\n\n[Generated by {model.full_id}]"
    
    # =====================================================================
    # UTILITY METHODS
    # =====================================================================
    
    def get_available_models(self, task_type: Optional[TaskType] = None) -> List[str]:
        """Listet verfügbare Modelle auf"""
        return self.router.list_available_models(task_type)
    
    def get_model_info(self, model_id: str) -> Optional[ModelCapabilities]:
        """Gibt Info zu einem Modell"""
        return self.router.registry.MODELS.get(model_id)
