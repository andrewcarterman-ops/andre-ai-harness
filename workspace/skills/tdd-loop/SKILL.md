---
name: tdd-loop
description: Test-driven development with active red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", "write a test first", or wants integration tests through public interfaces.
---

# TDD Loop

Active test-driven development with **red-green-refactor** cycles. Build features one vertical slice at a time.

## Quick Start

```
You: "TDD this: User can add items to cart"

Me: [Planning]
   "We'll test: cart accepts item, updates total"

Me: [RED]
   "Test: cart.add(item) increases cart.items.length"

Me: [GREEN]
   "Minimal code: cart.add = (item) => this.items.push(item)"

Me: [REFACTOR]
   "Extract: validateItem(), updateTotal()"

[Repeat for next behavior]
```

## Philosophy

**Test behavior, not implementation.**

Good tests verify through **public interfaces** and survive refactors. They describe _what_ the system does, not _how_ it does it.

| Good Tests | Bad Tests |
|------------|-----------|
| Integration-style | Mock internal collaborators |
| Public API only | Test private methods |
| Survive refactors | Break when renaming |
| Describe WHAT | Describe HOW |

## Anti-Pattern: Horizontal Slicing

```
❌ WRONG (horizontal):
  RED:   Write ALL tests
  GREEN: Write ALL code
  
  Result: Tests imagine behavior, not verify it

✅ RIGHT (vertical/tracer bullets):
  RED→GREEN: Test 1 → Impl 1
  RED→GREEN: Test 2 → Impl 2
  RED→GREEN: Test 3 → Impl 3
  
  Result: Each test responds to actual code
```

## Workflow

### 1. Planning (Before Any Code)

Confirm with you:

- [ ] What does the public interface look like?
- [ ] Which behaviors are most important?
- [ ] What are the integration points?

**Ask:** "What should the public interface be? Which behavior should we test first?"

**You can't test everything.** We focus on critical paths and complex logic.

### 2. Tracer Bullet (First RED→GREEN)

Write **ONE** test for **ONE** behavior:

```
RED:   Write test → WATCH IT FAIL
GREEN: Minimal code to pass → WATCH IT PASS
```

This proves the path works end-to-end.

### 3. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → WATCH IT FAIL
GREEN: Minimal code to pass → WATCH IT PASS
```

Rules:
- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 4. Refactor (Only When GREEN)

After all tests pass:

- [ ] Extract duplication
- [ ] Deepen modules (hide complexity)
- [ ] Apply SOLID principles naturally
- [ ] Run tests after each change

**Never refactor when RED.**

## Cycle Checklist

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
[ ] Tests pass before refactoring
```

## Example Session

**You:** "TDD a password validator"

**Me:** "Planning: Interface could be `validatePassword(password): Result`. Key behaviors: min length, has number, has special char. Which first?"

**You:** "Start with min length"

**Me:** "RED: Writing test 'rejects passwords under 8 chars'"

```typescript
// RED
expect(validatePassword("short").valid).toBe(false);
expect(validatePassword("short").error).toBe("min length 8");
```

**Me:** "Test fails. GREEN: Minimal implementation"

```typescript
// GREEN
function validatePassword(pwd) {
  if (pwd.length < 8) return { valid: false, error: "min length 8" };
  return { valid: true };
}
```

**Me:** "Test passes. Next behavior: requires number. RED:"

```typescript
expect(validatePassword("longpassword").valid).toBe(false);
expect(validatePassword("longpassword1").valid).toBe(true);
```

**Me:** "GREEN: Minimal addition"

```typescript
if (pwd.length < 8) return { valid: false, error: "min length 8" };
if (!/\d/.test(pwd)) return { valid: false, error: "needs number" };
return { valid: true };
```

**Me:** "All tests pass. REFACTOR: Extract validators?"

```typescript
const validators = [
  { test: p => p.length >= 8, error: "min length 8" },
  { test: p => /\d/.test(p), error: "needs number" },
];
```

**Me:** "Tests still pass. Continue with special char?"

## Test Design Principles

### Test Through Public Interface

```typescript
// GOOD: Tests behavior
const user = await createUser({ name: "Alice" });
const retrieved = await getUser(user.id);
expect(retrieved.name).toBe("Alice");

// BAD: Bypasses interface
test("createUser saves to DB", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users...");
  expect(row).toBeDefined();
});
```

### Mock Only System Boundaries

Mock at boundaries only:
- External APIs (payment, email)
- Databases (prefer test DB)
- Time/randomness

Don't mock:
- Your own modules
- Internal collaborators

See [Mocking Guide](mocking.md) for details.

### Deep Modules

Design small interfaces with lots of implementation hidden:

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
└─────────────────────┘
```

See [Deep Modules](deep-modules.md) from "A Philosophy of Software Design".

## Integration with Other Skills

| Sequence | Use Case |
|----------|----------|
| `plan-feature` → `tdd-loop` | Plan phases, then TDD each |
| `grill-me` → `tdd-loop` | Clarify edge cases, then build |
| `tdd-loop` → `refactoring` | After TDD, deeper refactoring |

## Multi-File References

For detailed guidance, see:

- [tests.md](tests.md) – Good vs bad test examples
- [mocking.md](mocking.md) – When and how to mock
- [deep-modules.md](deep-modules.md) – Interface design philosophy
- [interface-design.md](interface-design.md) – Testable interfaces
- [refactoring.md](refactoring.md) – Refactor candidates

## Checklist for Me (Per Cycle)

- [ ] Planning complete (interface, priorities)
- [ ] RED: Test written, watched it fail
- [ ] GREEN: Minimal code, watched it pass
- [ ] No speculative code added
- [ ] Test describes behavior, not implementation
- [ ] Continue to next behavior OR refactor
- [ ] If refactor: tests pass before AND after
