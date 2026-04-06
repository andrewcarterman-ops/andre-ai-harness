"""
Timeout Middleware für OpenClaw Resilient Agent
================================================

3-Tier-Timeout-Handling für robustes LLM-Streaming.

Warum 3 Tiers?
  1. First-Token-Timeout: Verbindungsprobleme erkennen
  2. Stall-Timeout: Hängende Streams erkennen
  3. Total-Timeout: Harte Obergrenze
"""

import asyncio
import time
from typing import AsyncIterator, Callable, Optional, Any
from dataclasses import dataclass, field
import logging

logger = logging.getLogger(__name__)


# =============================================================================
# EXCEPTIONS
# =============================================================================

class TimeoutError(Exception):
    """Basis-Timeout-Exception"""
    pass


class FirstTokenTimeoutError(TimeoutError):
    """
    Kein erstes Token innerhalb der erwarteten Zeit.
    
    Dies deutet auf:
    - Verbindungsprobleme
    - Überlasteten Provider
    - Lange Queue-Wartezeit
    
    Retry ist erlaubt!
    """
    pass


class StallTimeoutError(TimeoutError):
    """
    Stream hat aufgehört, Chunks zu liefern.
    
    Dies deutet auf:
    - Provider-Idle-Timeout
    - Netzwerk-Unterbrechung
    - Modell hat "gehängt"
    
    WICHTIG: Kein Retry, wenn bereits Tokens geliefert wurden!
    """
    pass


class TotalTimeoutError(TimeoutError):
    """
    Gesamt-Timeout überschritten.
    
    Harter Cutoff - kein Retry!
    """
    pass


# =============================================================================
# METRICS
# =============================================================================

@dataclass
class StreamMetrics:
    """Metriken für einen Stream"""
    start_time: float = field(default_factory=time.monotonic)
    first_token_time: Optional[float] = None
    total_tokens: int = 0
    stall_count: int = 0
    end_time: Optional[float] = None
    
    @property
    def ttft(self) -> Optional[float]:
        """Time To First Token in Sekunden"""
        if self.first_token_time:
            return self.first_token_time - self.start_time
        return None
    
    @property
    def total_duration(self) -> float:
        """Gesamtdauer des Streams"""
        end = self.end_time or time.monotonic()
        return end - self.start_time
    
    @property
    def tokens_per_second(self) -> float:
        """Durchschnittliche Tokens pro Sekunde"""
        duration = self.total_duration
        if duration > 0 and self.total_tokens > 0:
            return self.total_tokens / duration
        return 0.0
    
    def __str__(self) -> str:
        ttft_str = f"{self.ttft:.2f}s" if self.ttft else "N/A"
        return (
            f"StreamMetrics(ttft={ttft_str}, "
            f"tokens={self.total_tokens}, "
            f"duration={self.total_duration:.2f}s, "
            f"tps={self.tokens_per_second:.1f})"
        )


# =============================================================================
# MIDDLEWARE
# =============================================================================

class StreamingTimeoutMiddleware:
    """
    Middleware für robustes Streaming-Timeout-Handling.
    
    Wrappt beliebige Async Generators (OpenClaw Streams, etc.)
    mit 3-Tier-Timeout-Logik.
    
    Usage:
        middleware = StreamingTimeoutMiddleware(
            first_token_timeout=60.0,
            stall_timeout=30.0,
            total_timeout=600.0
        )
        
        async for chunk in middleware.wrap_stream(stream_factory):
            print(chunk)
    """
    
    def __init__(
        self,
        first_token_timeout: float = 60.0,
        stall_timeout: float = 30.0,
        total_timeout: float = 600.0
    ):
        self.first_token_timeout = first_token_timeout
        self.stall_timeout = stall_timeout
        self.total_timeout = total_timeout
    
    async def wrap_stream(
        self,
        stream_factory: Callable[[], AsyncIterator[str]],
        on_metrics: Optional[Callable[[StreamMetrics], None]] = None,
        on_stall: Optional[Callable[[], None]] = None,
        on_first_token: Optional[Callable[[float], None]] = None
    ) -> AsyncIterator[str]:
        """
        Wrappt einen Stream mit 3-Tier-Timeout-Logik.
        
        Args:
            stream_factory: Factory-Funktion, die den Stream erzeugt.
                           Wichtig: Wird bei Retry neu aufgerufen!
            on_metrics: Callback mit Metriken nach Stream-Ende
            on_stall: Callback bei Stall-Erkennung (vor Exception)
            on_first_token: Callback mit TTFT nach erstem Token
            
        Yields:
            Stream-Chunks mit Timeout-Überwachung
            
        Raises:
            FirstTokenTimeoutError: Kein Token innerhalb first_token_timeout
            StallTimeoutError: Kein Chunk innerhalb stall_timeout
            TotalTimeoutError: Gesamt-Timeout überschritten
        """
        metrics = StreamMetrics()
        first_token_received = False
        last_chunk_time = metrics.start_time
        
        # Erstelle den Stream
        stream = stream_factory()
        
        try:
            while True:
                # === Check 1: Gesamt-Timeout ===
                elapsed_total = time.monotonic() - metrics.start_time
                if elapsed_total > self.total_timeout:
                    metrics.end_time = time.monotonic()
                    if on_metrics:
                        on_metrics(metrics)
                    raise TotalTimeoutError(
                        f"Gesamt-Timeout nach {elapsed_total:.1f}s "
                        f"(Limit: {self.total_timeout}s)"
                    )
                
                # === Check 2: Aktuellen Timeout berechnen ===
                if not first_token_received:
                    # Phase 1: Warte auf ersten Token
                    elapsed = time.monotonic() - metrics.start_time
                    remaining = self.first_token_timeout - elapsed
                    if remaining <= 0:
                        metrics.end_time = time.monotonic()
                        if on_metrics:
                            on_metrics(metrics)
                        raise FirstTokenTimeoutError(
                            f"Kein Token nach {elapsed:.1f}s "
                            f"(Erwartet: {self.first_token_timeout}s)"
                        )
                    current_timeout = remaining
                else:
                    # Phase 2: Prüfe auf Stall
                    elapsed_since_chunk = time.monotonic() - last_chunk_time
                    remaining = self.stall_timeout - elapsed_since_chunk
                    if remaining <= 0:
                        metrics.stall_count += 1
                        if on_stall:
                            on_stall()
                        metrics.end_time = time.monotonic()
                        if on_metrics:
                            on_metrics(metrics)
                        raise StallTimeoutError(
                            f"Kein Chunk für {elapsed_since_chunk:.1f}s "
                            f"(Limit: {self.stall_timeout}s)"
                        )
                    current_timeout = remaining
                
                # === Versuche, nächsten Chunk zu holen ===
                try:
                    chunk = await asyncio.wait_for(
                        self._safe_anext(stream),
                        timeout=current_timeout
                    )
                    
                    # Erster Token?
                    if not first_token_received:
                        first_token_received = True
                        metrics.first_token_time = time.monotonic()
                        ttft = metrics.ttft
                        logger.debug(f"First token nach {ttft:.2f}s")
                        if on_first_token:
                            on_first_token(ttft)
                    
                    last_chunk_time = time.monotonic()
                    metrics.total_tokens += 1
                    yield chunk
                    
                except asyncio.TimeoutError:
                    # Sollte nicht passieren, da wir oben prüfen
                    continue
                    
        except StopAsyncIteration:
            # Normaler Stream-Ende
            pass
            
        finally:
            # Metriken zurückgeben
            metrics.end_time = time.monotonic()
            if on_metrics:
                on_metrics(metrics)
    
    async def _safe_anext(self, stream: AsyncIterator) -> Any:
        """Sicheres async next mit Propagierung von Exceptions"""
        return await stream.__anext__()
    
    async def wrap_with_retry(
        self,
        stream_factory: Callable[[], AsyncIterator[str]],
        max_retries: int = 3,
        on_retry: Optional[Callable[[int, Exception], None]] = None,
        **kwargs
    ) -> AsyncIterator[str]:
        """
        Wrappt Stream mit Retry-Logik NUR für Pre-First-Token-Failures.
        
        WICHTIGE REGELN:
        - FirstTokenTimeoutError: Retry erlaubt (Verbindungsproblem)
        - StallTimeoutError: KEIN Retry (User hat bereits Teile gesehen)
        - TotalTimeoutError: KEIN Retry (harter Cutoff)
        
        Args:
            stream_factory: Factory-Funktion für den Stream
            max_retries: Maximale Anzahl Retries
            on_retry: Callback(attempt_number, exception) bei jedem Retry
            **kwargs: Weitere Argumente für wrap_stream
            
        Yields:
            Stream-Chunks
        """
        attempt = 0
        last_error = None
        
        while attempt < max_retries:
            try:
                async for chunk in self.wrap_stream(stream_factory, **kwargs):
                    yield chunk
                return  # Erfolg!
                
            except FirstTokenTimeoutError as e:
                # === Retry erlaubt - Verbindungsproblem ===
                last_error = e
                attempt += 1
                
                if attempt >= max_retries:
                    logger.error(
                        f"Max retries ({max_retries}) exceeded for FirstTokenTimeout"
                    )
                    break
                
                # Exponential Backoff mit Jitter
                import random
                base_wait = min(2 ** attempt, 30)  # 2, 4, 8, 16, 30...
                jitter = random.uniform(0, 1)
                wait_time = base_wait + jitter
                
                logger.warning(
                    f"First token timeout, retry {attempt}/{max_retries} "
                    f"in {wait_time:.1f}s..."
                )
                
                if on_retry:
                    on_retry(attempt, e)
                
                await asyncio.sleep(wait_time)
                
            except StallTimeoutError:
                # === KEIN Retry - Stream hat begonnen! ===
                # User hat bereits Teile der Antwort gesehen.
                # Ein Retry würde den Stream von vorne starten = Chaos.
                logger.error(
                    "Stream stall nach erstem Token - kein Retry möglich! "
                    "Stream wird abgebrochen."
                )
                raise
                
            except TotalTimeoutError:
                # === KEIN Retry - harter Cutoff ===
                logger.error("Total timeout erreicht - kein Retry!")
                raise
        
        # Alle Retries erschöpft
        raise FirstTokenTimeoutError(
            f"Failed after {max_retries} attempts. "
            f"Last error: {last_error}"
        )


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def create_middleware_for_model(
    model_id: str,
    custom_timeouts: Optional[dict] = None
) -> StreamingTimeoutMiddleware:
    """
    Erstellt eine Middleware-Instanz mit modellspezifischen Timeouts.
    
    Args:
        model_id: z.B. "k2p5" oder "kimi-k2-thinking"
        custom_timeouts: Optional - überschreibt Default-Timeouts
        
    Returns:
        Konfigurierte StreamingTimeoutMiddleware
    """
    from .timeout_config import get_timeout_profile
    
    profile = get_timeout_profile(model_id)
    
    if custom_timeouts:
        return StreamingTimeoutMiddleware(
            first_token_timeout=custom_timeouts.get(
                "first_token", profile.first_token_seconds
            ),
            stall_timeout=custom_timeouts.get(
                "stall", profile.stall_seconds
            ),
            total_timeout=custom_timeouts.get(
                "total", profile.total_seconds
            )
        )
    
    return StreamingTimeoutMiddleware(
        first_token_timeout=profile.first_token_seconds,
        stall_timeout=profile.stall_seconds,
        total_timeout=profile.total_seconds
    )
