"""
Timeout-Profile für OpenClaw Resilient Agent
=============================================

Modellspezifische Timeouts basierend auf OpenClaw-Provider-Konfiguration.
"""

from dataclasses import dataclass
from typing import Dict, Any


@dataclass(frozen=True)
class TimeoutProfile:
    """
    Unveränderliches Timeout-Profil pro Modell.
    
    Attributes:
        first_token_seconds: Zeit bis zum ersten Token (TTFT)
        stall_seconds: Maximale Pause zwischen Stream-Chunks
        total_seconds: Absolute Obergrenze für den gesamten Request
        retry_attempts: Wie oft bei Pre-First-Token-Failures retryen
    """
    first_token_seconds: float
    stall_seconds: float
    total_seconds: float
    retry_attempts: int
    
    def to_openclaw_config(self) -> Dict[str, Any]:
        """Konvertiert zu OpenClaw-spezifischer Config"""
        return {
            "timeoutSeconds": int(self.total_seconds),
            "llm": {
                "idleTimeoutSeconds": int(self.first_token_seconds),
                "stallTimeoutSeconds": int(self.stall_seconds)
            }
        }


# =============================================================================
# MODELLSPEZIFISCHE TIMEOUTS
# =============================================================================
# Basierend auf realen Beobachtungen und Provider-Dokumentation
# Angepasst für OpenClaw-Setup mit kimi-coding als Hauptprovider

TIMEOUT_PROFILES: Dict[str, TimeoutProfile] = {
    # -------------------------------------------------------------------------
    # Moonshot Kimi Modelle - Hauptprovider in OpenClaw
    # -------------------------------------------------------------------------
    "kimi-k2-thinking": TimeoutProfile(
        first_token_seconds=120.0,  # Kann lange "nachdenken"
        stall_seconds=60.0,         # Reasoning-Pausen sind normal
        total_seconds=900.0,        # 15 Minuten für komplexe Tasks
        retry_attempts=2
    ),
    "kimi-k2": TimeoutProfile(
        first_token_seconds=60.0,
        stall_seconds=30.0,
        total_seconds=600.0,
        retry_attempts=3
    ),
    "kimi-k2-coding": TimeoutProfile(
        first_token_seconds=90.0,   # Code-Generierung braucht Zeit
        stall_seconds=45.0,
        total_seconds=600.0,
        retry_attempts=2
    ),
    # OpenClaw Alias
    "k2p5": TimeoutProfile(
        first_token_seconds=90.0,
        stall_seconds=45.0,
        total_seconds=600.0,
        retry_attempts=2
    ),
    
    # -------------------------------------------------------------------------
    # OpenAI - schneller und zuverlässiger
    # -------------------------------------------------------------------------
    "gpt-5.2": TimeoutProfile(
        first_token_seconds=30.0,
        stall_seconds=20.0,
        total_seconds=300.0,
        retry_attempts=3
    ),
    "gpt-5.2-coding": TimeoutProfile(
        first_token_seconds=45.0,
        stall_seconds=25.0,
        total_seconds=400.0,
        retry_attempts=2
    ),
    
    # -------------------------------------------------------------------------
    # Anthropic - mittlere Geschwindigkeit
    # -------------------------------------------------------------------------
    "claude-sonnet-4-6": TimeoutProfile(
        first_token_seconds=60.0,
        stall_seconds=30.0,
        total_seconds=600.0,
        retry_attempts=3
    ),
}


def get_timeout_profile(model_id: str) -> TimeoutProfile:
    """
    Holt Timeout-Profil mit Fallback auf sichere Defaults.
    
    Args:
        model_id: z.B. "kimi-k2-thinking" oder "k2p5"
        
    Returns:
        TimeoutProfile für das Modell oder Default-Werte
    """
    return TIMEOUT_PROFILES.get(
        model_id,
        TimeoutProfile(
            first_token_seconds=60.0,
            stall_seconds=30.0,
            total_seconds=600.0,
            retry_attempts=3
        )
    )


def get_timeout_for_openclaw_model(full_model_id: str) -> TimeoutProfile:
    """
    Extrahiert Timeout-Profil aus OpenClaw Model ID.
    
    Args:
        full_model_id: z.B. "kimi-coding/k2p5"
        
    Returns:
        TimeoutProfile für das Modell
    """
    # Extrahiere Modell-ID aus "provider/model"
    if "/" in full_model_id:
        _, model_id = full_model_id.split("/", 1)
    else:
        model_id = full_model_id
    
    return get_timeout_profile(model_id)
