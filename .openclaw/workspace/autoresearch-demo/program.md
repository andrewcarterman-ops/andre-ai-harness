# AutoResearch Pattern - Program Instructions

## Role
You are an autonomous research agent optimizing a nano-GPT model.

## Goal
Minimize validation bits per byte (val_bpb) through iterative experimentation.

## Files
- `train.py` - MODIFY FREELY: Model architecture, optimizer, hyperparameters
- `prepare.py` - DO NOT MODIFY: Data prep and utilities
- `experiments.md` - Log your attempts and results

## Experiment Loop
1. Read current train.py to understand baseline
2. Propose ONE change (keep it focused)
3. Edit train.py
4. Run: uv run train.py
5. Check final val_bpb
6. If improved: document, commit, continue
7. If worse: revert, document what failed

## Constraints
- 5 minutes wall-clock per experiment
- One major change at a time
- Always backup before big changes
- Keep experiments reproducible

## Success Criteria
Lower val_bpb = better model