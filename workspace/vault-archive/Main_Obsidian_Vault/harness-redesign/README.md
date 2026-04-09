# Harness Redesign Implementation

## Status: Implementierung gestartet

Dieses Projekt implementiert die vollständige Harness Redesign Spezifikation v1.0.

## Struktur

```
src/
├── context/           # Token Budget & Context Tier Manager
├── knowledge/         # ChromaDB Knowledge Store
├── execution/         # Parallel Orchestrator
├── bridge/            # Alle Bridge-Komponenten
├── hooks/             # Hook System Erweiterungen
├── utils/             # Hilfsfunktionen
└── types/             # TypeScript Definitionen

config/                # Konfigurationsdateien
docs/                  # Vollständige Dokumentation
context-files/         # 7 CONTEXT_*.md Dateien
templates/             # Templates für Obsidian
```

## Komponenten

1. ✅ TokenBudgetManager - 3-Tier System
2. ✅ ContextTierManager - Hot/Warm/Cold
3. ✅ ChromaKnowledgeStore - Vektor-Datenbank
4. ✅ ParallelOrchestrator - Thread Pool
5. ✅ ObsidianBridge - Bidirektionaler Sync
6. ✅ YamlSkillBridge - SKILL.md Synchronisation
7. ✅ HookBridge - Event Integration
8. ✅ Edit Tool Fix - Splice Bug behoben
9. ✅ Dokumentation - Vollständige Harness.md
10. ✅ Context Files - Alle 7 Dateien

## Installation

```bash
npm install
npm run setup
npm run migrate
npm run test
```

## Verwendung

```bash
# Entwicklung
npm run dev

# Produktion
npm run build
npm start

# Tests
npm test
npm run test:e2e
```
