---
date: 06-04-2026
type: knowledge
category: reference
tags: [reference, project-vision, openclaw, architecture, requirements]
---

# Projekt-Vision: Multi-Agent AI Harness

## Ursprüngliche Anfrage (06-04-2026)

**Ziel:** Mehrere AI-Agenten, die ein GitHub Repo analysieren und Verbesserungsvorschläge machen (Struktur, Pfad, Logik), da alles "vibe coded" ist.

**Anforderungen:**
- Effiziente, schnelle AI Harness
- Kurzfristig: Schneller Zugriff auf letzte Sessions
- Langfristig: Daten aus Obsidian Second Brain ziehen
- Professioneller Ansatz nach Industrie-Standard

---

## Referenz-Repositories

Das Projekt basiert auf Code aus drei Quellen:

| Repo | Stars | Zweck | URL |
|------|-------|-------|-----|
| **andre-ai-harness** | - | Mein "Frankenstein"-Merge | https://github.com/andrewcarterman-ops/andre-ai-harness.git |
| **everything-claude-code** | 142k | Agent Harness mit Skills-System | https://github.com/affaan-m/everything-claude-code.git |
| **claw-code** | 173k | Rust-basierter Claude-Code-Clone | https://github.com/ultraworkers/claw-code |

**Das Problem:** Beide Systeme haben unterschiedliche Philosophien:
- ECC: JavaScript/Skill-basiert, erweiterbar
- Claw: Rust-zentriert, monolithisch

→ Gemerged ohne Adapter-Layer → **Architektonischer Konflikt**

---

## Technologie-Stack (Ist-Zustand)

```
Rust:        53.8%  (51k LOC, nur 439 Kommentare = 0,8% Dokumentation!)
Python:      14.7%  (11k LOC - vermutlich für RAG/Embeddings)
Shell:       10.0%
PowerShell:   9.5%  (8.7k LOC, gut kommentiert)
TypeScript:   8.3%  (8.4k LOC Frontend)
JavaScript:   2.0%
Other:        1.7%
```

**Gesamt:** 175.430 Zeilen (119k Code, 33k Kommentare, 23k Leer)

**Kritische Befunde:**
1. **Spärliche Dokumentation** (0,8% in Rust) → Kein Wissenstransfer möglich
2. **Massiver JSON-Anteil** (24k Zeilen) → Vermutlich Embeddings ohne Versionierung
3. **Keine klare Trennung** zwischen Core (Rust) und AI-Layer (Python)

---

## Identifizierte Probleme

### 1. Frankenstein-Architektur
- Code aus 3 Repos zusammengeführt ohne klare Integrationsstrategie
- 175k LOC Monolith, unwartbar

### 2. Datei-Zerstörung beim Überschreiben
- Keine Atomic Writes
- Wenn Prozess abbricht → Datei korrupt
- Muss neu wiederhergestellt werden

### 3. Kein State Management
- Sessions werden nicht versioniert
- Kein "Zurück" möglich
- Erinnerungsqualität sinkt mit der Zeit

### 4. Instabiles Harness
- Logikfehler beim Überschreiben
- Dateien werden unbrauchbar
- System bricht ab

---

## Architektur-Entscheidungen

### Multi-Agent Pattern: "Subagents with Sequential Workflow"

**Warum sequentiell?**
- Hardware kann nicht gut parallel skalieren (GTX 980M, 32GB RAM)
- Einfacheres Debugging
- Weniger Race Conditions

**Agenten-Struktur:**
```
Orchestrator (Rust)
    ├── Analyzer Agent   → Code-Struktur analysieren
    ├── Planner Agent    → Planung
    ├── Executor Agent   → Ausführung
    └── Report Agent     → Markdown-Report mit Obsidian-Kontext
```

### State Management: Git als State Machine

**Konzept:** Jede Session als Markdown mit YAML Frontmatter

Vorteile:
- Jede Änderung ist versioniert (`git log`)
- Rollback möglich (`git checkout`)
- Obsidian kann direkt lesen/schreiben
- Menschenlesbar, keine Binärdateien

### Obsidian RAG Stack

| Komponente | Technologie | Begründung |
|------------|-------------|------------|
| Embeddings | BGE-M3 | Lokal, 1024 Dimensionen, beste Qualität |
| Vector DB | LanceDB/Chroma | Lokal, datei-basiert |
| Chunking | Markdown-aware | Respektiert Überschriften, Code-Blöcke |
| Graph | 2-Hop-Tiefe | Verlinkte Notizen einbeziehen |

### Code-Analyse: Tree-sitter

**Warum nicht Regex?**
- Versteht Code-Struktur (AST)
- Multi-Language (Rust, Python, TypeScript)
- Inkrementelles Parsing (schnell bei großen Dateien)
- Präzise Extraktion: Funktionen, Klassen, Dependencies

---

## Anforderungen im Detail

| Bereich | Anforderung |
|---------|-------------|
| **Tech-Stack** | Keine Präferenz, aber Industrie-Standard |
| **Deployment** | Zuerst lokal, später Web-Service (Brücke ermöglichen) |
| **Repos** | Eigenes analysieren (3 Referenz-Repos als Basis) |
| **Analyse-Tiefe** | Beides: Oberflächlich (Struktur) + Tief (AST, Komplexität) |
| **Vault-Zugriff** | Direkt auf Dateisystem (RAG) |
| **Vault-Größe** | 97MB, unstrukturiert, bessere Verknüpfung nötig |
| **Agenten** | Spezialisiert: Struktur, Quality, Security, Report |
| **Orchestrierung** | Sequentiell (besser für begrenzte Hardware) |
| **Schreib-/Lese-Rechte** | Beides: Lesen für Kontext, Schreiben für neue Notizen |
| **Session-Daten** | Chat-Verläufe mit LLM, abgespeichert |
| **Ausgabeformat** | Markdown (versionierbar, diff-bar, Obsidian-kompatibel) |
| **Priorität** | Perfekte Architektur wichtiger als schnelles MVP |
| **Budget** | Kein Limit für Plan, Harness selbst soll kosteneffizient sein |
| **State Management** | Markdown in Obsidian mit Git-Versionierung |

---

## 12-Wochen-Renovierungs-Roadmap

| Phase | Woche | Fokus | Status |
|-------|-------|-------|--------|
| 0 | 1 | Stabilisierung (Atomic Writes) | 🔄 |
| 1 | 2-3 | Modularisierung (Cargo Workspace) | ⏳ |
| 2 | 4 | State Management (Markdown + YAML) | ⏳ |
| 3 | 5-6 | Obsidian RAG (LanceDB + BGE-M3) | ⏳ |
| 4 | 7-8 | Code-Analyse (Tree-sitter) | ⏳ |
| 5 | 9-10 | Sequential Workflow | ⏳ |
| 6 | 11-12 | Integration & Polishing | ⏳ |

---

## Verwandte Dokumente

- [[openclaw-renovation|Projekt: OpenClaw Renovierung]]
- [[ADR-004-openclaw-architecture|ADR-004: Architektur-Entscheidungen]]
- [[openclaw-implementations-plan|How-To: Implementations-Plan]]
- [[openclaw-code-referenz|Code-Referenz]]

---

*Dieses Dokument fasst den ursprünglichen Chat-Verlauf zusammen, der die Geburtstunde des Projekts dokumentiert.*
*Quelle: GitHub-Analyse & Obsidian RAG.txt (06-04-2026)*
*Letzte Aktualisierung: 10-04-2026*
