---
date: 07-04-2026
type: project
status: in-progress
tags: [project, openclaw, renovation, architecture]
---

# Projekt: OpenClaw Renovierung

## Zusammenfassung

Transformation von 175k LOC Chaos zu einem stabilen Multi-Agent AI Harness mit Markdown-basiertem State Management und Obsidian-RAG-Integration.

## Ausgangssituation ("Frankenstein-System")

| Problem | Auswirkung |
|---------|-----------|
| Dateikorruption bei Überschreiben | Datenverlust |
| 175k LOC Monolith | Unwartbar |
| Keine atomaren Schreiboperationen | Inkonsistente Zustände |
| Spärliche Dokumentation (0,8%) | Kein Wissenstransfer |

## Ziel-Architektur (Erweitert basierend auf Harness Redesign Spec)

| Layer | Technologie | Zweck |
|-------|-------------|-------|
| Core | Rust | Atomare Dateioperationen |
| AI Layer | Python | Embeddings, Agents |
| Automation | PowerShell | Windows-Integration |
| Daten | Markdown + YAML | PARA-Struktur |

### Key Innovations (aus Harness Redesign Spec)

**1. 3-Tier Context System**
- **Immediate (Hot):** Aktive Session, schneller Zugriff
- **Retrievable (Warm):** Vector DB, <2s Zugriff
- **Archived (Cold):** Langfristiges Wissen, Second Brain

**2. Token Budget Manager**
- Dynamische Token-Allokation
- LRU Eviction bei 70/80/90% Thresholds
- Ziel: 85%+ Effizienz (40% Reduktion Waste)

**3. Vector Knowledge Store**
- ChromaDB oder sqlite-vec
- Hybrid Search (semantisch + keyword)
- Integration mit Obsidian Second Brain

**4. Parallel Tool Execution**
- Thread Pool mit 2-8 Workers
- 30% schnellere Response-Zeiten

**5. Obsidian Bridge**
- Bidirektionaler Sync mit Second Brain
- Automatisches Knowledge Capture
- Ziel: 80%+ Learning Capture (8x Verbesserung)

**Referenz:** [[harness-redesign-specification|Harness Redesign Specification (39 KB Detail-Plan)]]

## Projekt-Status

**Aktuelle Phase:** 0.3 (Stabilisierung - Atomic Writes)
**Gesamt-Phasen:** 0-6

| Phase | Status | Beschreibung |
|-------|--------|--------------|
| 0.1 | ✅ | Git Setup |
| 0.2 | ✅ | Cargo Workspace |
| 0.3 | 🔄 | Atomic Writes |
| 1 | ⏳ | Modularisierung |
| 2 | ⏳ | State-Management |
| 3 | ⏳ | RAG |
| 4 | ⏳ | Code-Analyse |
| 5 | ⏳ | Workflow |
| 6 | ⏳ | Integration |

## Verwandte Dokumente

### Interne Dokumente
- [[ADR-004-openclaw-architecture|ADR-004: Architektur-Entscheidungen]]
- [[openclaw-implementations-plan|Implementations-Plan (How-To)]]

### Externe Referenzen (Claw-Code)
- [[claw-code-integration-index|Claw-Code Integration Index]] → Übersicht aller Specs
- [[claw-code-masterplan|MASTERPLAN]] → Komplette Integrationsstrategie
- [[claw-code-sse-streaming|SSE Streaming]] → Echtzeit-API (Tier 1)
- [[claw-code-runtime-spec|Runtime Spec]] → Agent Loop mit Safety (Tier 1)
- [[claw-code-permissions-spec|Permissions]] → Risk-basierte Security (Tier 1)
- [[claw-code-compaction-spec|Compaction]] → Memory Management (Tier 2)
- [[claw-code-quick-reference|Quick Reference]] → Konstanten & Checklisten

**Hinweis:** Die claw-code Specs sind aus dem alten Vault extrahiert und bieten produktionsreife Rust-Komponenten für die Integration.

## Phase 0: Sofortmaßnahmen (Aus Recommendations extrahiert)

### P0-1: Edit-Tool Parameter Fix
**Problem**: `new_string` vs `newText` mismatch
**Lösung**: Beide Parameter akzeptieren mit Deprecation-Warning

```typescript
interface EditFileParams {
  file_path: string;
  old_string: string;
  new_string?: string;
  newText?: string;  // Deprecated
}

function validateEditParams(params: EditFileParams) {
  const newContent = params.new_string ?? params.newText;
  
  if (!newContent) {
    throw new Error('Missing required parameter: new_string');
  }
  
  if (params.newText && !params.new_string) {
    console.warn('Deprecation: newText is deprecated, use new_string');
  }
  
  return { ...params, new_string: newContent };
}
```

### P0-2: Hook System Dokumentation
**Status**: Hooks sind MANUELLE PROTOKOLLE, nicht automatisch
**Aktion**: 
- `hooks/session-start.md` - Protokoll beim Session-Start lesen
- `hooks/session-end.md` - Protokoll beim Session-Ende lesen
- `hooks/review-post-execution.md` - Post-Execution Review

### P0-3: YAML Schema Validation
**Vorschlag**: Zod-Schema für Registry-Validierung
- Skills, Agents, Hooks validieren
- Frühe Fehlererkennung

**Quelle**: Detaillierte Empfehlungen aus [[openclaw-system-architecture|System Architecture Analysis]]

**Verwandte Checkliste**: [[openclaw-action-checklist|Prioritized Action Checklist]]
- [[openclaw-code-referenz|Code-Referenz]]
- [[harness-redesign-specification|Harness Redesign Specification]] (Detaillierter Architektur-Plan)
- [[openclaw-harness-diagnosis-part1|OpenClaw Diagnose Teil 1]] (Problem-Analyse)
- [[openclaw-edit-tool-developer-fix|Developer Fix Guide]] (Lösungen & Workarounds)

## Quellen

- **Harness Redesign Spec:** Detaillierter 39 KB Architektur-Plan
- **Diagnosis Docs:** Umfassende Fehleranalyse (58 KB)
- **ECC Framework:** Bestehende Implementierungen und Tools

## Erstellt
07-04-2026

## Letzte Aktualisierung
10-04-2026 (erweitert mit Harness Redesign Spec Details)
