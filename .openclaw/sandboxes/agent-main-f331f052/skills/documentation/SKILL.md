---
name: documentation
description: |
  Documentation best practices and patterns. Use when: (1) writing documentation,
  (2) reviewing docs, (3) creating READMEs, (4) API documentation.
  
trigger_phrases:
  - "document"
  - "readme"
  - "docs"
  - "documentation"
  - "explain"
  
category: communication
tags:
  - docs
  - communication
  - markdown
  
metadata:
  version: "1.0"
  author: "adapted-from-ecc"
  requires: []
---

# Documentation Patterns

## README Structure

```markdown
# Project Name

One-line description.

## Quick Start

```bash
npm install
npm start
```

## Features

- Feature 1
- Feature 2

## Installation

### Requirements
- Node.js 16+

### Setup
```bash
git clone ...
cd project
npm install
```

## Usage

```javascript
import { myLib } from 'my-lib';

const result = myLib.doSomething();
```

## API Reference

See [API.md](./API.md)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

MIT
```

## Code Documentation

### Function Documentation
```python
def fetch_user(user_id: int, include_deleted: bool = False) -> User:
    """
    Fetch a user by ID.
    
    Args:
        user_id: The unique user identifier
        include_deleted: Whether to include soft-deleted users
        
    Returns:
        User object if found, None otherwise
        
    Raises:
        ValueError: If user_id is negative
        PermissionError: If current user lacks read permission
        
    Example:
        >>> user = fetch_user(123)
        >>> print(user.name)
        'John Doe'
    """
```

### Architecture Decision Records

```markdown
# ADR-001: Use PostgreSQL for main database

## Status
Accepted

## Context
We need a relational database for user data...

## Decision
We will use PostgreSQL...

## Consequences
- ✅ ACID compliance
- ✅ JSON support
- ❌ Operational complexity
```

## Writing Principles

1. **Know your audience**
   - Beginners need more context
   - Experts want quick reference

2. **Show, don't tell**
   ```markdown
   ❌ Bad: "Use the function to get data"
   ✅ Good: "Use `fetchData()` to retrieve records"
   ```

3. **Keep it current**
   - Update docs with code
   - Version your documentation

4. **Examples first**
   - Start with working example
   - Explain afterwards

## Documentation Types

| Type | Purpose | Audience |
|------|---------|----------|
| README | Quick start | Everyone |
| API Reference | Function details | Developers |
| Tutorials | Learning | Beginners |
| ADRs | Decisions | Team |
| Runbooks | Operations | DevOps |
