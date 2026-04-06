---
name: python-patterns
description: |
  Python best practices and patterns. Use when: (1) writing Python code, 
  (2) reviewing Python, (3) debugging Python issues, (4) structuring Python projects.
  
trigger_phrases:
  - "python"
  - "pythonic"
  - "python pattern"
  - "py"
  
category: language
tags:
  - python
  - backend
  - scripting
  
metadata:
  version: "1.0"
  author: "adapted-from-ecc"
  requires: []
---

# Python Patterns

## Project Structure

```
project/
├── src/
│   └── project_name/
│       ├── __init__.py
│       ├── module.py
│       └── utils/
├── tests/
│   ├── __init__.py
│   └── test_module.py
├── docs/
├── pyproject.toml
├── README.md
└── .gitignore
```

## Code Patterns

### Error Handling
```python
# ✅ Do: Specific exceptions
try:
    result = process_data(data)
except ValueError as e:
    logger.error(f"Invalid data: {e}")
    raise CustomError("Processing failed") from e

# ❌ Don't: Bare except
except:  # Never do this
    pass
```

### Context Managers
```python
# ✅ Do: Use context managers
with open("file.txt", "r") as f:
    content = f.read()

# ✅ Do: Custom context managers
from contextlib import contextmanager

@contextmanager
def managed_resource():
    resource = acquire()
    try:
        yield resource
    finally:
        resource.release()
```

### Type Hints
```python
from typing import Optional, List, Dict, Union
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str
    email: Optional[str] = None

def get_users(active_only: bool = True) -> List[User]:
    ...
```

### Async Patterns
```python
import asyncio
from typing import AsyncGenerator

async def fetch_items(urls: List[str]) -> AsyncGenerator[Item, None]:
    async with aiohttp.ClientSession() as session:
        for url in urls:
            async with session.get(url) as response:
                yield await response.json()
```

## Testing

```python
import pytest
from unittest.mock import Mock, patch

def test_user_creation():
    user = User(name="Test", email="test@example.com")
    assert user.name == "Test"
    assert user.id is not None

@pytest.mark.asyncio
async def test_async_fetch():
    with patch("module.http_client") as mock:
        mock.get.return_value = Mock(json=lambda: {"data": []})
        result = await fetch_data()
        assert result == []
```

## Anti-Patterns to Avoid

- ❌ Mutable default arguments
- ❌ `from module import *`
- ❌ Bare `except:` clauses
- ❌ `__del__` for cleanup
- ❌ Circular imports

## Tools

- **ruff**: Fast Python linter
- **black**: Code formatter
- **mypy**: Type checker
- **pytest**: Testing framework
