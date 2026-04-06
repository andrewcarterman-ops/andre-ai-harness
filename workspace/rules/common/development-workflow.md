# Development Workflow Rules

## Code-First Approach
1. Write working code first
2. Explain after (if needed)
3. Prefer solutions that work over perfect solutions

## Commit Discipline
- Atomic commits: one logical change per commit
- Clear commit messages describing WHY not WHAT
- Commit frequently, push regularly

## Testing Before Commit
- Run relevant tests before committing
- No "commit and hope"
- Fix failures immediately

## Red-Green-Refactor
1. **Red**: Write failing test
2. **Green**: Make it pass (minimal code)
3. **Refactor**: Clean up while green

## Documentation
- Update docs with code changes
- README reflects current state
- ADRs for architectural decisions
