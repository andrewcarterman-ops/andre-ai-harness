---
name: refactoring
description: |
  Code refactoring patterns and techniques. Use when: (1) improving existing code,
  (2) technical debt reduction, (3) code modernization, (4) performance optimization.
  
trigger_phrases:
  - "refactor"
  - "rewrite"
  - "clean up"
  - "modernize"
  - "optimize"
  - "technical debt"
  
category: quality
tags:
  - refactoring
  - quality
  - maintenance
  
metadata:
  version: "1.0"
  author: "adapted-from-ecc"
  requires: []
---

# Refactoring Patterns

## When to Refactor

✅ **Do refactor:**
- Code is hard to understand
- Duplication exists
- Adding features is difficult
- Tests are hard to write

❌ **Don't refactor:**
- Code works and is stable
- No tests exist (write tests first!)
- Deadline is imminent
- You don't understand the domain

## Common Refactorings

### Extract Function
```python
# Before
def process_order(order):
    # Validate
    if not order.items:
        raise ValueError("Empty order")
    if order.total < 0:
        raise ValueError("Invalid total")
    
    # Calculate
    tax = order.total * 0.2
    total_with_tax = order.total + tax
    
    # Save
    order.total = total_with_tax
    order.save()

# After
def process_order(order):
    validate_order(order)
    total_with_tax = calculate_total_with_tax(order)
    save_order(order, total_with_tax)

def validate_order(order):
    if not order.items:
        raise ValueError("Empty order")
    if order.total < 0:
        raise ValueError("Invalid total")

def calculate_total_with_tax(order):
    tax = order.total * 0.2
    return order.total + tax

def save_order(order, total):
    order.total = total
    order.save()
```

### Rename Variable
```python
# Before
d = 30  # days

# After
DAYS_IN_MONTH = 30
```

### Replace Magic Numbers
```python
# Before
if status == 3:
    process_error()

# After
ERROR_STATUS = 3
if status == ERROR_STATUS:
    process_error()
```

## Refactoring Workflow

1. **Ensure tests pass** ✅
2. **Make small changes**
3. **Run tests frequently**
4. **Commit often**
5. **Review the result**

## Code Smells

| Smell | Solution |
|-------|----------|
| Long function | Extract functions |
| Duplicate code | Extract common code |
| Large class | Extract classes |
| Long parameter list | Introduce parameter object |
| Feature envy | Move method to appropriate class |
| Switch statements | Use polymorphism |

## Boy Scout Rule

> "Leave the code better than you found it"

Small improvements compound over time.
