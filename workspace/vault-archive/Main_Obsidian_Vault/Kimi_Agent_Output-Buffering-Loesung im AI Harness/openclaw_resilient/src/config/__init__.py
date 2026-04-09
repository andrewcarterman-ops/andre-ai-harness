"""Config-Modul für Timeout-Profile und Model-Konfigurationen."""

from .timeouts import TimeoutProfile, TIMEOUT_PROFILES, get_timeout_profile

__all__ = ["TimeoutProfile", "TIMEOUT_PROFILES", "get_timeout_profile"]
