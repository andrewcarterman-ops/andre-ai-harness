# Git Workflow Rules

## Branch Naming
- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Urgent production fixes
- `refactor/description` - Code refactoring

## Commit Messages
Format: `type(scope): description`

Types:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting
- `refactor:` Code restructuring
- `test:` Tests
- `chore:` Maintenance

Examples:
```
feat(registry): add agent validation
fix(scripts): correct error handling
docs(readme): update installation steps
```

## Before Push Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No secrets in code
- [ ] Commit message follows format

## Pull Request Rules
- PR describes WHAT and WHY
- Link related issues
- Request review from relevant agents
- Address all feedback before merge
