# AutoResearch Pattern Demo

This demonstrates the **Instructions + Sandbox** pattern from karpathy/autoresearch.

## The Core Idea

Separate **WHAT to do** (program.md) from **HOW it's done** (train.py).

## Files

| File | Purpose | Who Edits |
|------|---------|-----------|
| `program.md` | Agent instructions | Human (you) |
| `train.py` | Training code | Agent |
| `experiments.md` | Experiment log | Both |

## How to Use This Pattern for Your Skills

1. **Write clear SKILL.md** = your program.md
   - Define boundaries
   - Set success criteria
   - Document constraints

2. **Create sandbox files** = your train.py
   - One file the agent can freely edit
   - Clear inputs/outputs
   - Automated evaluation

3. **Iterate on instructions**
   - Watch what the agent does
   - Update SKILL.md based on failures
   - Improve the "research org"

## Example: Applying to Documentation

**SKILL.md:**
```markdown
## Task
Improve documentation clarity

## Constraints
- One file at a time
- Run readability check after each change
- Keep changes minimal
```

**Sandbox:**
- Input: Current docs
- Process: Agent edits
- Output: Readability score
- Loop: Iterate until score improves

## Why This Matters

Most skills fail because:
- Instructions are vague
- No clear success criteria
- Agent has no feedback loop

This pattern fixes all three.