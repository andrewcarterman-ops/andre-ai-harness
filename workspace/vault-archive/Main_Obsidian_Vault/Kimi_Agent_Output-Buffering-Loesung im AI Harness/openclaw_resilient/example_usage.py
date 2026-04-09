"""
SCHRITT 5: Beispiel-Verwendung
==============================
Zeigt, wie du den Resilient Agent nutzt.
Kopiere und passe an deine Bedürfnisse an.
"""

import asyncio
import logging

# Logging aktivieren (optional)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Importe
from src.core.resilient_agent import ResilientAgent
from src.core.model_router import TaskType


async def example_1_basic_streaming():
    """
    Beispiel 1: Einfaches Streaming
    ===============================
    Der Agent wählt automatisch das beste Modell für den Task.
    """
    print("\n" + "="*60)
    print("BEISPIEL 1: Basic Streaming")
    print("="*60)
    
    agent = ResilientAgent(
        default_task_type=TaskType.QUICK_CHAT,
        preferred_provider="moonshot"
    )
    
    prompt = "Erkläre das Konzept von Rekursion in der Programmierung."
    
    print(f"\nPrompt: {prompt}\n")
    print("Antwort:\n")
    
    async for chunk in agent.stream(prompt):
        print(chunk, end="", flush=True)
    
    print("\n")


async def example_2_coding_task():
    """
    Beispiel 2: Coding-Task mit spezifischem Modell
    ================================================
    Der Agent wählt kimi-coding oder ein Fallback.
    """
    print("\n" + "="*60)
    print("BEISPIEL 2: Coding Task")
    print("="*60)
    
    agent = ResilientAgent(preferred_provider="moonshot")
    
    prompt = """
    Schreibe eine Python-Funktion, die prüft, ob eine Zahl eine Primzahl ist.
    Die Funktion soll effizient sein und auch für große Zahlen funktionieren.
    """
    
    print(f"\nPrompt: {prompt.strip()}\n")
    print("Antwort:\n")
    
    async for chunk in agent.stream(
        prompt=prompt,
        task_type=TaskType.CODING
    ):
        print(chunk, end="", flush=True)
    
    print("\n")


async def example_3_reasoning_task():
    """
    Beispiel 3: Reasoning-Task (komplexes Denken)
    =============================================
    Nutzt kimi-k2-thinking für komplexe Reasoning-Aufgaben.
    """
    print("\n" + "="*60)
    print("BEISPIEL 3: Reasoning Task")
    print("="*60)
    
    agent = ResilientAgent(preferred_provider="moonshot")
    
    prompt = """
    Ein Bauer hat 17 Schafe. Alle außer 9 sterben.
    Wie viele Schafe hat der Farmer noch?
    
    Denke Schritt für Schritt.
    """
    
    print(f"\nPrompt: {prompt.strip()}\n")
    print("Antwort (mit Reasoning):\n")
    
    async for chunk in agent.stream(
        prompt=prompt,
        task_type=TaskType.REASONING,
        require_reasoning=True
    ):
        print(chunk, end="", flush=True)
    
    print("\n")


async def example_4_with_callbacks():
    """
    Beispiel 4: Mit Callbacks für Metriken
    =======================================
    Zeigt TTFT (Time To First Token) und andere Metriken.
    """
    print("\n" + "="*60)
    print("BEISPIEL 4: Mit Metriken")
    print("="*60)
    
    agent = ResilientAgent(preferred_provider="moonshot")
    
    prompt = "Schreibe ein kurzes Gedicht über KI."
    
    metrics_data = {}
    
    def on_metrics(m):
        metrics_data['ttft'] = m.ttft
        metrics_data['tokens'] = m.total_tokens
        metrics_data['duration'] = m.total_duration
        metrics_data['tps'] = m.tokens_per_second
    
    print(f"\nPrompt: {prompt}\n")
    
    async for chunk in agent.stream(
        prompt=prompt,
        on_metrics=on_metrics
    ):
        print(chunk, end="", flush=True)
    
    print("\n")
    print("-" * 40)
    print(f"Metriken:")
    print(f"  TTFT (Time To First Token): {metrics_data.get('ttft', 0):.2f}s")
    print(f"  Gesamte Tokens: {metrics_data.get('tokens', 0)}")
    print(f"  Gesamtdauer: {metrics_data.get('duration', 0):.2f}s")
    print(f"  Tokens/Sekunde: {metrics_data.get('tps', 0):.1f}")
    print("-" * 40)


async def example_5_non_streaming():
    """
    Beispiel 5: Non-Streaming (komplette Antwort)
    =============================================
    Sammelt alle Chunks und gibt komplette Antwort zurück.
    """
    print("\n" + "="*60)
    print("BEISPIEL 5: Non-Streaming")
    print("="*60)
    
    agent = ResilientAgent(preferred_provider="moonshot")
    
    prompt = "Was sind die 3 größten Städte Deutschlands?"
    
    print(f"\nPrompt: {prompt}\n")
    
    response = await agent.run(
        prompt=prompt,
        task_type=TaskType.QUICK_CHAT
    )
    
    print(f"Antwort:\n{response.content}\n")
    print(f"Verwendetes Modell: {response.model_used}")
    print(f"Fallback verwendet: {response.fallback_used}")
    print(f"TTFT: {response.metrics.ttft:.2f}s")


async def example_6_long_context():
    """
    Beispiel 6: Long Context Task
    =============================
    Nutzt Modelle mit großem Kontext-Fenster (256k).
    """
    print("\n" + "="*60)
    print("BEISPIEL 6: Long Context")
    print("="*60)
    
    agent = ResilientAgent(preferred_provider="moonshot")
    
    # Simuliere einen langen Kontext
    long_text = "Dies ist ein wichtiger Satz. " * 100
    
    prompt = f"""
    Hier ist ein langer Text:
    
    {long_text}
    
    Fasse den Text in 3 Sätzen zusammen.
    """
    
    context_length = len(long_text.split())  # Grobe Schätzung
    
    print(f"\nPrompt-Länge: ~{context_length} Tokens\n")
    
    async for chunk in agent.stream(
        prompt=prompt,
        task_type=TaskType.LONG_CONTEXT,
        context_length=context_length
    ):
        print(chunk, end="", flush=True)
    
    print("\n")


async def example_7_specific_model():
    """
    Beispiel 7: Spezifisches Modell erzwingen
    ==========================================
    Überschreibt die automatische Modellauswahl.
    """
    print("\n" + "="*60)
    print("BEISPIEL 7: Spezifisches Modell")
    print("="*60)
    
    agent = ResilientAgent(preferred_provider="moonshot")
    
    prompt = "Erkläre Docker in einfachen Worten."
    
    print(f"\nPrompt: {prompt}\n")
    print("Erzwinge kimi-k2-thinking:\n")
    
    async for chunk in agent.stream(
        prompt=prompt,
        model_override="kimi-k2-thinking"  # Spezifisches Modell
    ):
        print(chunk, end="", flush=True)
    
    print("\n")


async def main():
    """Führt alle Beispiele aus"""
    
    print("\n" + "="*60)
    print("RESILIENT AGENT - BEISPIELE")
    print("="*60)
    print("\nHinweis: Wenn OpenClaw nicht installiert ist,")
    print("werden Mock-Streams verwendet.")
    
    try:
        await example_1_basic_streaming()
        await example_2_coding_task()
        await example_3_reasoning_task()
        await example_4_with_callbacks()
        await example_5_non_streaming()
        await example_6_long_context()
        await example_7_specific_model()
        
    except Exception as e:
        print(f"\nFehler: {e}")
        raise
    
    print("\n" + "="*60)
    print("ALLE BEISPIELE ABGESCHLOSSEN")
    print("="*60)


if __name__ == "__main__":
    asyncio.run(main())
