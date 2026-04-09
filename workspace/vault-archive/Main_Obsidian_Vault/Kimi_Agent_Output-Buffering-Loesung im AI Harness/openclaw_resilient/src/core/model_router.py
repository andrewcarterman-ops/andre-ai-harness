"""
SCHRITT 2: Modell-Router
========================
Diese Datei implementiert die intelligente Modellauswahl.
Kopiere nach: src/core/model_router.py

Warum: Verschiedene Tasks brauchen verschiedene Modelle.
Coding -> kimi-coding, Reasoning -> kimi-k2-thinking, etc.
"""

from enum import Enum, auto
from typing import List, Optional, Dict
from dataclasses import dataclass

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from config.timeouts import TimeoutProfile, get_timeout_profile


class TaskType(Enum):
    """Task-Typen für Modellauswahl"""
    CODING = auto()        # Code-Generierung
    REASONING = auto()     # Komplexes Reasoning/Thinking
    QUICK_CHAT = auto()    # Schnelle Konversation
    LONG_CONTEXT = auto()  # Lange Dokumente (256k Kontext)
    TOOL_HEAVY = auto()    # Viele Tool-Calls
    CREATIVE = auto()      # Kreative Texte


@dataclass
class ModelCapabilities:
    """Fähigkeiten und Metadaten eines Modells"""
    id: str
    provider: str
    context_window: int
    supports_reasoning: bool
    supports_tools: bool
    supports_json_mode: bool
    cost_per_1k_input: float
    cost_per_1k_output: float
    timeout_profile: TimeoutProfile
    
    @property
    def full_id(self) -> str:
        """Vollständige ID z.B. 'moonshot/kimi-k2-thinking'"""
        return f"{self.provider}/{self.id}"


class ModelRegistry:
    """
    Zentrale Registry aller verfügbaren Modelle.
    
    Hier definierst du ALLE Modelle, die du nutzen möchtest.
    Füge einfach neue Einträge hinzu, um weitere Modelle zu unterstützen.
    """
    
    MODELS: Dict[str, ModelCapabilities] = {
        # =====================================================================
        # Moonshot Kimi Modelle
        # =====================================================================
        "kimi-k2-thinking": ModelCapabilities(
            id="kimi-k2-thinking",
            provider="moonshot",
            context_window=256000,
            supports_reasoning=True,
            supports_tools=True,
            supports_json_mode=True,
            cost_per_1k_input=0.015,
            cost_per_1k_output=0.015,
            timeout_profile=get_timeout_profile("kimi-k2-thinking")
        ),
        "kimi-k2": ModelCapabilities(
            id="kimi-k2",
            provider="moonshot",
            context_window=256000,
            supports_reasoning=False,
            supports_tools=True,
            supports_json_mode=True,
            cost_per_1k_input=0.008,
            cost_per_1k_output=0.008,
            timeout_profile=get_timeout_profile("kimi-k2")
        ),
        "kimi-k2-coding": ModelCapabilities(
            id="kimi-k2-coding",
            provider="moonshot",
            context_window=256000,
            supports_reasoning=True,
            supports_tools=True,
            supports_json_mode=True,
            cost_per_1k_input=0.012,
            cost_per_1k_output=0.012,
            timeout_profile=get_timeout_profile("kimi-k2-coding")
        ),
        
        # =====================================================================
        # OpenAI Modelle
        # =====================================================================
        "gpt-5.2": ModelCapabilities(
            id="gpt-5.2",
            provider="openai",
            context_window=128000,
            supports_reasoning=False,
            supports_tools=True,
            supports_json_mode=True,
            cost_per_1k_input=0.005,
            cost_per_1k_output=0.015,
            timeout_profile=get_timeout_profile("gpt-5.2")
        ),
        "gpt-5.2-coding": ModelCapabilities(
            id="gpt-5.2-coding",
            provider="openai",
            context_window=128000,
            supports_reasoning=False,
            supports_tools=True,
            supports_json_mode=True,
            cost_per_1k_input=0.007,
            cost_per_1k_output=0.021,
            timeout_profile=get_timeout_profile("gpt-5.2-coding")
        ),
        
        # =====================================================================
        # Anthropic Modelle
        # =====================================================================
        "claude-sonnet-4-6": ModelCapabilities(
            id="claude-sonnet-4-6-20251022",
            provider="anthropic",
            context_window=200000,
            supports_reasoning=True,
            supports_tools=True,
            supports_json_mode=True,
            cost_per_1k_input=0.003,
            cost_per_1k_output=0.015,
            timeout_profile=get_timeout_profile("claude-sonnet-4-6")
        ),
    }
    
    # =====================================================================
    # Task-zu-Modell-Mapping (Priorisierte Liste)
    # =====================================================================
    # Reihenfolge = Priorität. Erstes verfügbares Modell wird gewählt.
    
    TASK_MODELS: Dict[TaskType, List[str]] = {
        TaskType.CODING: [
            "kimi-k2-coding",
            "gpt-5.2-coding", 
            "claude-sonnet-4-6",
            "kimi-k2"
        ],
        TaskType.REASONING: [
            "kimi-k2-thinking",
            "claude-sonnet-4-6",
            "kimi-k2"
        ],
        TaskType.QUICK_CHAT: [
            "gpt-5.2",
            "kimi-k2",
            "claude-sonnet-4-6"
        ],
        TaskType.LONG_CONTEXT: [
            "kimi-k2",           # 256k Kontext
            "kimi-k2-thinking",  # 256k Kontext
            "claude-sonnet-4-6"  # 200k Kontext
        ],
        TaskType.TOOL_HEAVY: [
            "gpt-5.2",           # Beste Tool-Unterstützung
            "kimi-k2",
            "claude-sonnet-4-6"
        ],
        TaskType.CREATIVE: [
            "claude-sonnet-4-6",
            "kimi-k2-thinking",
            "gpt-5.2"
        ]
    }


class ModelRouter:
    """
    Intelligente Modellauswahl basierend auf Task und Constraints.
    
    Usage:
        router = ModelRouter()
        model = router.select_model(TaskType.CODING, context_length=50000)
        print(model.full_id)  # "moonshot/kimi-k2-coding"
    """
    
    def __init__(self):
        self.registry = ModelRegistry()
    
    def select_model(
        self,
        task_type: TaskType,
        context_length: int = 0,
        require_reasoning: bool = False,
        require_tools: bool = False,
        require_json: bool = False,
        preferred_provider: Optional[str] = None,
        excluded_models: Optional[List[str]] = None,
        max_cost_per_1k: Optional[float] = None
    ) -> ModelCapabilities:
        """
        Wählt das beste Modell für den gegebenen Task.
        
        Args:
            task_type: Art der Aufgabe (CODING, REASONING, etc.)
            context_length: Geschätzte Token-Anzahl des Kontexts
            require_reasoning: Ob Reasoning/Thinking benötigt wird
            require_tools: Ob Tool-Calls benötigt werden
            require_json: Ob JSON-Mode benötigt wird
            preferred_provider: Bevorzugter Provider ("moonshot", "openai", etc.)
            excluded_models: Liste auszuschließender Model-IDs
            max_cost_per_1k: Maximale Kosten pro 1k Tokens
            
        Returns:
            ModelCapabilities des besten verfügbaren Modells
            
        Raises:
            ValueError: Wenn kein passendes Modell gefunden wird
        """
        candidates = self.registry.TASK_MODELS.get(task_type, [])
        excluded = set(excluded_models or [])
        
        for model_id in candidates:
            if model_id in excluded:
                continue
                
            model = self.registry.MODELS.get(model_id)
            if not model:
                continue
            
            # === Constraint-Prüfungen ===
            
            # 1. Kontext-Fenster ausreichend? (15% Safety-Margin)
            if context_length > 0:
                max_safe_tokens = int(model.context_window * 0.85)
                if context_length > max_safe_tokens:
                    continue
            
            # 2. Reasoning unterstützt?
            if require_reasoning and not model.supports_reasoning:
                continue
            
            # 3. Tools unterstützt?
            if require_tools and not model.supports_tools:
                continue
                
            # 4. JSON-Mode unterstützt?
            if require_json and not model.supports_json_mode:
                continue
            
            # 5. Bevorzugter Provider?
            if preferred_provider and model.provider != preferred_provider:
                continue
            
            # 6. Kosten im Limit?
            if max_cost_per_1k and model.cost_per_1k_input > max_cost_per_1k:
                continue
            
            # Alle Checks bestanden - dieses Modell passt!
            return model
        
        # Fallback: Erstes verfügbares Modell ohne Constraints
        for model_id in candidates:
            if model_id not in excluded:
                model = self.registry.MODELS.get(model_id)
                if model:
                    return model
        
        # Ultimativer Fallback
        return self.registry.MODELS["kimi-k2"]
    
    def get_fallback_chain(
        self,
        task_type: TaskType,
        primary_model: Optional[str] = None,
        **kwargs
    ) -> List[ModelCapabilities]:
        """
        Gibt eine Kette von Fallback-Modellen zurück.
        
        Args:
            task_type: Art der Aufgabe
            primary_model: Optionales bevorzugtes Primärmodell
            **kwargs: Weitere Filter für select_model
            
        Returns:
            Liste von ModelCapabilities in Prioritätsreihenfolge
        """
        chain = []
        excluded = set()
        
        # Primary Model (wenn angegeben und verfügbar)
        if primary_model:
            model = self.registry.MODELS.get(primary_model)
            if model:
                chain.append(model)
                excluded.add(primary_model)
        
        # Weitere Modelle für den Task
        for _ in range(5):  # Max 5 Fallbacks
            try:
                model = self.select_model(
                    task_type=task_type,
                    excluded_models=list(excluded),
                    **kwargs
                )
                if model.id not in excluded:
                    chain.append(model)
                    excluded.add(model.id)
            except Exception:
                break
        
        return chain
    
    def list_available_models(self, task_type: Optional[TaskType] = None) -> List[str]:
        """
        Listet alle verfügbaren Modelle auf.
        
        Args:
            task_type: Optional - nur Modelle für diesen Task
            
        Returns:
            Liste von Modell-IDs
        """
        if task_type:
            return self.registry.TASK_MODELS.get(task_type, [])
        return list(self.registry.MODELS.keys())
