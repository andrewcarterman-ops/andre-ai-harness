---
name: testing-patterns
description: |
  Testing best practices and patterns. Use when: (1) writing tests, 
  (2) designing test strategy, (3) debugging test failures, (4) setting up test infrastructure.
  
trigger_phrases:
  - "test"
  - "testing"
  - "pytest"
  - "unittest"
  - "tdd"
  - "coverage"
  
category: quality
tags:
  - testing
  - quality
  - tdd
  
metadata:
  version: "1.0"
  author: "adapted-from-ecc"
  requires: []
---

# Testing Patterns

## Test Structure (AAA)

```python
def test_user_authentication():
    # Arrange
    user = User(username="test", password="secret")
    
    # Act
    result = user.authenticate("secret")
    
    # Assert
    assert result is True
    assert user.is_authenticated
```

## Test Types

### Unit Tests
```python
# Test single unit in isolation
def test_calculate_total():
    items = [Item(price=10), Item(price=20)]
    assert calculate_total(items) == 30
```

### Integration Tests
```python
# Test component interaction
@pytest.mark.integration
def test_database_connection():
    db = Database()
    db.connect()
    result = db.query("SELECT 1")
    assert result == [(1,)]
```

### Property-Based Tests
```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers()))
def test_sort_idempotent(numbers):
    assert sorted(sorted(numbers)) == sorted(numbers)
```

## Fixtures

```python
import pytest

@pytest.fixture
def database():
    db = Database("test.db")
    db.create_tables()
    yield db
    db.drop_tables()

@pytest.fixture
def authenticated_user():
    user = User.create(username="test")
    user.authenticate("password")
    return user
```

## Mocking

```python
from unittest.mock import Mock, patch, MagicMock

def test_external_api_call():
    with patch("module.http_client") as mock_client:
        # Arrange
        mock_response = Mock()
        mock_response.json.return_value = {"status": "ok"}
        mock_client.get.return_value = mock_response
        
        # Act
        result = fetch_data()
        
        # Assert
        assert result["status"] == "ok"
        mock_client.get.assert_called_once_with("/api/data")
```

## Parameterized Tests

```python
@pytest.mark.parametrize("input,expected", [
    ("hello", 5),
    ("world", 5),
    ("", 0),
    ("a", 1),
])
def test_string_length(input, expected):
    assert len(input) == expected
```

## Test Coverage

### What to Test
- ✅ Business logic
- ✅ Edge cases
- ✅ Error handling
- ✅ Boundary conditions

### What Not to Test
- ❌ Simple getters/setters
- ❌ Third-party libraries
- ❌ Framework internals

## TDD Cycle

```
1. Write failing test
2. Write minimal code to pass
3. Refactor
4. Repeat
```

## Assertions Best Practices

```python
# ✅ Do: Specific assertions
assert user.is_active is True
assert len(items) == 3
assert "error" in response.text.lower()

# ✅ Do: Custom messages
assert user.age >= 18, f"User age {user.age} is below minimum"
```

## Continuous Testing

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
      - run: pip install -r requirements-dev.txt
      - run: pytest --cov=src --cov-report=xml
      - uses: codecov/codecov-action@v1
```
