"""
OpenClaw Config Loader
======================

Lädt und validiert die OpenClaw-Konfiguration aus openclaw.json.
"""

import json
import os
from pathlib import Path
from typing import Dict, Any, Optional
from dataclasses import dataclass


@dataclass
class OpenClawAgentConfig:
    """Vereinfachte OpenClaw Agent-Konfiguration"""
    timeout_seconds: int = 900
    model: str = "kimi-coding/k2p5"
    sandbox_mode: str = "non-main"
    workspace: str = ""
    compaction_mode: str = "safeguard"


@dataclass  
class OpenClawToolsConfig:
    """OpenClaw Tools-Konfiguration"""
    exec_host: str = "gateway"
    profile: str = "full"


class OpenClawConfigLoader:
    """
    Lädt OpenClaw-Konfiguration aus openclaw.json.
    
    Die Konfiguration hat folgende Struktur:
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
            "exec": {"host": "gateway"},
            ...
        }
    }
    """
    
    DEFAULT_CONFIG_PATHS = [
        Path.home() / ".openclaw" / "openclaw.json",
        Path("openclaw.json"),
    ]
    
    def __init__(self, config_path: Optional[Path] = None):
        """
        Initialisiert den Config Loader.
        
        Args:
            config_path: Optional - Pfad zur openclaw.json
        """
        self.config_path = config_path
        self._config: Optional[Dict[str, Any]] = None
    
    def load(self) -> Dict[str, Any]:
        """
        Lädt die OpenClaw-Konfiguration.
        
        Returns:
            Komplette Konfiguration als Dictionary
            
        Raises:
            FileNotFoundError: Wenn keine Config gefunden wurde
            json.JSONDecodeError: Wenn JSON ungültig ist
        """
        if self._config is not None:
            return self._config
        
        # Suche Config-Datei
        paths = [self.config_path] if self.config_path else self.DEFAULT_CONFIG_PATHS
        
        for path in paths:
            if path and path.exists():
                with open(path, 'r', encoding='utf-8') as f:
                    self._config = json.load(f)
                return self._config
        
        raise FileNotFoundError(
            f"OpenClaw Konfiguration nicht gefunden. "
            f"Gesucht in: {[str(p) for p in paths]}"
        )
    
    def get_agent_config(self) -> OpenClawAgentConfig:
        """
        Extrahiert Agent-Konfiguration.
        
        Returns:
            OpenClawAgentConfig mit validierten Werten
        """
        config = self.load()
        defaults = config.get("agents", {}).get("defaults", {})
        
        # Extrahiere Werte mit Defaults
        timeout = defaults.get("timeoutSeconds", 900)
        model = defaults.get("model", "kimi-coding/k2p5")
        
        # Sandbox-Mode
        sandbox = defaults.get("sandbox", {})
        sandbox_mode = sandbox.get("mode", "non-main") if isinstance(sandbox, dict) else "non-main"
        
        # Workspace
        workspace = defaults.get("workspace", str(Path.home() / ".openclaw" / "workspace"))
        
        # Compaction
        compaction = defaults.get("compaction", {})
        compaction_mode = compaction.get("mode", "safeguard") if isinstance(compaction, dict) else "safeguard"
        
        return OpenClawAgentConfig(
            timeout_seconds=timeout,
            model=model,
            sandbox_mode=sandbox_mode,
            workspace=workspace,
            compaction_mode=compaction_mode
        )
    
    def get_tools_config(self) -> OpenClawToolsConfig:
        """
        Extrahiert Tools-Konfiguration.
        
        Returns:
            OpenClawToolsConfig mit validierten Werten
        """
        config = self.load()
        tools = config.get("tools", {})
        exec_config = tools.get("exec", {})
        
        return OpenClawToolsConfig(
            exec_host=exec_config.get("host", "gateway"),
            profile=tools.get("profile", "full")
        )
    
    def get_timeout_settings(self) -> Dict[str, float]:
        """
        Extrahiert Timeout-Einstellungen.
        
        Returns:
            Dictionary mit timeout_seconds
        """
        agent_config = self.get_agent_config()
        
        return {
            "total_seconds": float(agent_config.timeout_seconds),
            # Default-Werte für First-Token und Stall
            # Diese können aus dem Resilient Agent Package kommen
            "first_token_seconds": 120.0,
            "stall_seconds": 45.0,
        }
    
    def get_model_id(self) -> str:
        """
        Extrahiert die Modell-ID aus der Konfiguration.
        
        Returns:
            Vollständige Modell-ID (z.B. "kimi-coding/k2p5")
        """
        agent_config = self.get_agent_config()
        return agent_config.model
    
    def validate(self) -> list[str]:
        """
        Validiert die Konfiguration und gibt Warnungen zurück.
        
        Returns:
            Liste von Warnungen (leer wenn alles OK)
        """
        warnings = []
        
        try:
            config = self.load()
        except FileNotFoundError:
            return ["Konfigurationsdatei nicht gefunden"]
        except json.JSONDecodeError as e:
            return [f"Ungültiges JSON: {e}"]
        
        # Prüfe agents.defaults
        agents = config.get("agents", {})
        defaults = agents.get("defaults", {})
        
        if not defaults:
            warnings.append("agents.defaults fehlt")
        
        # Prüfe timeoutSeconds
        if "timeoutSeconds" not in defaults:
            warnings.append("timeoutSeconds nicht gesetzt (verwende Default: 900)")
        
        # Prüfe model
        model = defaults.get("model", "")
        if not model:
            warnings.append("model nicht gesetzt")
        elif not isinstance(model, str):
            warnings.append(f"model sollte ein String sein, ist: {type(model).__name__}")
        
        # Prüfe sandbox
        sandbox = defaults.get("sandbox", {})
        if not sandbox:
            warnings.append("sandbox nicht konfiguriert (empfohlen: mode=non-main)")
        
        # Prüfe tools.exec.host
        tools = config.get("tools", {})
        exec_config = tools.get("exec", {})
        if "host" not in exec_config:
            warnings.append("tools.exec.host nicht gesetzt (empfohlen: gateway)")
        
        return warnings
    
    def print_summary(self):
        """Druckt eine Zusammenfassung der Konfiguration"""
        print("=" * 50)
        print("OpenClaw Konfiguration")
        print("=" * 50)
        
        # Validierung
        warnings = self.validate()
        if warnings:
            print("\nWarnungen:")
            for w in warnings:
                print(f"  ⚠️  {w}")
        else:
            print("\n✅ Konfiguration valid")
        
        # Agent Config
        agent = self.get_agent_config()
        print(f"\nAgent:")
        print(f"  Model: {agent.model}")
        print(f"  Timeout: {agent.timeout_seconds}s")
        print(f"  Sandbox: {agent.sandbox_mode}")
        print(f"  Workspace: {agent.workspace}")
        
        # Tools Config
        tools = self.get_tools_config()
        print(f"\nTools:")
        print(f"  Exec Host: {tools.exec_host}")
        print(f"  Profile: {tools.profile}")
        
        print("\n" + "=" * 50)


def load_openclaw_config(config_path: Optional[Path] = None) -> OpenClawConfigLoader:
    """
    Hilfsfunktion zum Laden der OpenClaw-Konfiguration.
    
    Args:
        config_path: Optional - Pfad zur openclaw.json
        
    Returns:
        OpenClawConfigLoader-Instanz
    """
    return OpenClawConfigLoader(config_path)


if __name__ == "__main__":
    # Demo: Lade und zeige Konfiguration
    loader = load_openclaw_config()
    loader.print_summary()
