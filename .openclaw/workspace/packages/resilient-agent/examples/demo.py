"""
OpenClaw Resilient Agent - Demo
================================

Zeigt die Integration des Resilient Agent Packages mit OpenClaw.
"""

import asyncio
from pathlib import Path

# Importiere Resilient Agent
from resilient_agent import (
    ResilientAgent,
    TaskType,
    OpenClawConfigLoader,
)


async def demo_basic_streaming():
    """Demo: Einfaches Streaming"""
    print("\n" + "="*50)
    print("DEMO 1: Basic Streaming")
    print("="*50)
    
    agent = ResilientAgent(preferred_provider="kimi-coding")
    
    prompt = "Erkläre das Konzept von Rekursion."
    print(f"\nPrompt: {prompt}\n")
    print("Antwort:\n")
    
    async for chunk in agent.stream(prompt):
        print(chunk, end="", flush=True)
    
    print("\n")


async def demo_with_task_type():
    """Demo: Task-basierte Modellauswahl"""
    print("\n" + "="*50)
    print("DEMO 2: Task-basierte Modellauswahl")
    print("="*50)
    
    agent = ResilientAgent(preferred_provider="kimi-coding")
    
    # Coding Task
    prompt = "Schreibe eine Python-Funktion für Fibonacci."
    print(f"\nPrompt: {prompt}")
    print("TaskType: CODING\n")
    
    async for chunk in agent.stream(prompt, task_type=TaskType.CODING):
        print(chunk, end="", flush=True)
    
    print("\n")


async def demo_with_metrics():
    """Demo: Mit Metriken"""
    print("\n" + "="*50)
    print("DEMO 3: Mit Metriken")
    print("="*50)
    
    agent = ResilientAgent(preferred_provider="kimi-coding")
    
    prompt = "Was ist 2+2?"
    print(f"\nPrompt: {prompt}\n")
    
    metrics_data = {}
    
    def on_metrics(m):
        metrics_data['ttft'] = m.ttft
        metrics_data['tokens'] = m.total_tokens
        metrics_data['duration'] = m.total_duration
        metrics_data['tps'] = m.tokens_per_second
    
    async for chunk in agent.stream(prompt, on_metrics=on_metrics):
        print(chunk, end="", flush=True)
    
    print("\n")
    print("-" * 40)
    print(f"Metriken:")
    print(f"  TTFT: {metrics_data.get('ttft', 0):.2f}s")
    print(f"  Tokens: {metrics_data.get('tokens', 0)}")
    print(f"  Dauer: {metrics_data.get('duration', 0):.2f}s")
    print(f"  TPS: {metrics_data.get('tps', 0):.1f}")
    print("-" * 40)


async def demo_non_streaming():
    """Demo: Non-Streaming"""
    print("\n" + "="*50)
    print("DEMO 4: Non-Streaming")
    print("="*50)
    
    agent = ResilientAgent(preferred_provider="kimi-coding")
    
    prompt = "Was sind die 3 größten Städte Deutschlands?"
    print(f"\nPrompt: {prompt}\n")
    
    response = await agent.run(prompt, task_type=TaskType.QUICK_CHAT)
    
    print(f"Antwort:\n{response.content}\n")
    print(f"Modell: {response.model_used}")
    print(f"TTFT: {response.metrics.ttft:.2f}s")


async def demo_config_loader():
    """Demo: OpenClaw Config laden"""
    print("\n" + "="*50)
    print("DEMO 5: OpenClaw Config Loader")
    print("="*50)
    
    loader = OpenClawConfigLoader()
    loader.print_summary()


async def main():
    """Hauptfunktion"""
    print("\n" + "="*50)
    print("OpenClaw Resilient Agent - Demo")
    print("="*50)
    print("\nHinweis: Verwendet Mock-Streams für Demo")
    
    try:
        await demo_config_loader()
        await demo_basic_streaming()
        await demo_with_task_type()
        await demo_with_metrics()
        await demo_non_streaming()
        
    except Exception as e:
        print(f"\nFehler: {e}")
        raise
    
    print("\n" + "="*50)
    print("Alle Demos abgeschlossen!")
    print("="*50)


if __name__ == "__main__":
    asyncio.run(main())
