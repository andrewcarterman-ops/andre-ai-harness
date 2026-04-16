---
date: 14-04-2026
type: reference
tags: [reference, ai-research, asi-evolve, autoresearch, gair-nlp]
---

# ASI-Evolve (GAIR-NLP)

**Quelle:** GAIR-NLP, SJTU / SII
**Repository:** <https://github.com/GAIR-NLP/ASI-Evolve.git>
**Paper:** <https://github.com/GAIR-NLP/ASI-Evolve/blob/main/assets/paper.pdf>
**arXiv:** <https://arxiv.org/abs/2603.29640>

---

## Kurzbeschreibung

Generalisiertes agentisches Framework für autonome Forschung. Schließt den Loop zwischen Wissen → Hypothese → Experiment → Analyse und wiederholt diesen autonom.

## Kern-Loop

1. **LEARN** → Prior knowledge retrieval
2. **DESIGN** → Next candidate proposal
3. **EXPERIMENT** → Execution + metrics
4. **ANALYZE** → Lessons learned distillation

## Agenten

- **Researcher** → Liest DB + Cognition Store, schlägt vor
- **Engineer** → Führt Code aus, sammelt Metriken
- **Analyzer** → Schreibt transferable Lessons

## Memory-Systeme

- **Cognition Store** → FAISS + `sentence-transformers/all-MiniLM-L6-v2` (Domain Knowledge)
- **Experiment Database** → FAISS + UCB1 / Island Sampling ( alle Trials mit Motivation, Code, Resultat, Analyse)

## Technischer Stack

- Python 3.10+
- OpenAI-compatible API (oder local sglang)
- FAISS-CPU
- sentence-transformers
- Optional: Weights & Biases

## Bekannte Resultate

| Domain | Gain |
|--------|------|
| Neural Architecture Design | +0.97 pts über DeltaNet |
| Pretraining Data Curation | +3.96 pts avg, +18 pts MMLU |
| RL Algorithm Design | +12.5 pts AMC32 vs GRPO |
| Biomedical (DTI) | +6.94 AUROC |

## Relevanz für unser System

**Direkte Integration:** Nicht empfohlen (Overengineering, Domänen-Mismatch)
**Konzeptioneller Wert:** Hoch — Loop-Architektur, Cognition Store, Experiment-Tracking
**Hardware-Fit:** API-basiert machbar, lokaler sglang auf GTX 980M grenzwertig

## Verwandte Projekte

- [[asi-evolve-analyse-integration|Projekt: ASI-Evolve Analyse & Integration]]
- [[mcp-sequential-thinking|MCP Sequential Thinking]]
- [[openclaw-renovation|OpenClaw Renovierung]]
