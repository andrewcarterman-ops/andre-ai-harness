"""
OpenClaw Resilient Agent Package
=================================

Robustes LLM-Streaming mit 3-Tier-Timeout-Handling und automatischem Failover.
Integriert nahtlos mit OpenClaw und dem ECC-Framework.
"""

__version__ = "1.0.0"
__author__ = "Andrew (OpenClaw Integration)"

# Haupt-Exports
from .agent import ResilientAgent, AgentResponse
from .model_router import ModelRouter, TaskType, ModelCapabilities
from .timeout_middleware import (
    StreamingTimeoutMiddleware,
    StreamMetrics,
    FirstTokenTimeoutError,
    StallTimeoutError,
    TotalTimeoutError,
)
from .timeout_config import TimeoutProfile, get_timeout_profile
from .config_loader import OpenClawConfigLoader

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
    "OpenClawConfigLoader",
]
