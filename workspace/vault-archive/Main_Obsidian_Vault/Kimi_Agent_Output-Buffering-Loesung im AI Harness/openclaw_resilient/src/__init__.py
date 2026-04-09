"""
OpenClaw Resilient Agent

Ein robuster Wrapper für OpenClaw mit:
- Intelligenter Modellauswahl
- 3-Tier-Timeout-Handling
- Automatischem Failover
"""

from src.core.resilient_agent import ResilientAgent, AgentResponse
from src.core.model_router import ModelRouter, TaskType, ModelCapabilities
from src.core.timeout_middleware import (
    StreamingTimeoutMiddleware,
    StreamMetrics,
    FirstTokenTimeoutError,
    StallTimeoutError,
    TotalTimeoutError,
)
from src.config.timeouts import TimeoutProfile, get_timeout_profile

__version__ = "1.0.0"

__all__ = [
    # Hauptklassen
    "ResilientAgent",
    "AgentResponse",
    # Model Routing
    "ModelRouter",
    "TaskType",
    "ModelCapabilities",
    # Timeout Handling
    "StreamingTimeoutMiddleware",
    "StreamMetrics",
    "FirstTokenTimeoutError",
    "StallTimeoutError",
    "TotalTimeoutError",
    # Config
    "TimeoutProfile",
    "get_timeout_profile",
]
