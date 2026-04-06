---
name: grill-me
description: Relentlessly interview the user about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, mentions "grill me", or before starting implementation to catch edge cases.
---

# Grill Me

Interview me relentlessly about a plan or design until we reach shared understanding. Walk down each branch of the decision tree, resolving dependencies between decisions one-by-one.

## Quick Start

**You:** "Grill me on this plan: [paste plan]"

**Me:** [Asks one focused question at a time, with recommended answer]

**You:** [Respond, adjust plan]

[Repeat until all branches resolved]

## When to Use

| Situation | Why Grill? |
|-----------|------------|
| Before implementation | Catch edge cases early |
| Complex feature | Resolve interdependencies |
| Unclear requirements | Force specificity |
| Team alignment | Document decisions |
| After write-a-prd | Validate assumptions |
| Before plan-feature | Ensure slices are correct |

## Process

### 1. Present Your Plan

Paste:
- PRD
- Feature description
- Architecture idea
- Implementation approach

Or point me to a file.

### 2. Relentless Questions

I'll ask **one question at a time**. Each question:

- Explores one branch of the decision tree
- Includes my **recommended answer**
- Forces a specific decision

### 3. Question Patterns

I ask about:

| Category | Example Questions |
|----------|-------------------|
| **Scope** | "What happens if user cancels mid-flow?" |
| **Errors** | "What if the API returns 503?" |
| **State** | "Where is the source of truth for X?" |
| **Timing** | "What if two users edit simultaneously?" |
| **Boundaries** | "What if input exceeds max length?" |
| **Dependencies** | "Does Phase 2 need Phase 1 deployed first?" |
| **Permissions** | "Can admins see what regular users can't?" |

### 4. Decision Resolution

For each question, we resolve:

```
Question: What happens if email sending fails?

Options:
A) Retry 3 times, then queue for later
B) Fail the entire transaction
C) Log error, continue silently

Recommended: A

Your decision: ___
```

### 5. Shared Understanding

Continue until:
- All branches explored
- Edge cases documented
- Decisions recorded
- Plan updated

## Example Session

**You:** "Grill me on this: Users can reset passwords via email"

**Me:** "What happens if the email bounces?"

**You:** "We should notify the user to check their email address"

**Me:** "How many reset attempts allowed per hour?"

**You:** "Good catch, let's say 3 per hour"

**Me:** "What if user requests reset while already logged in?"

**You:** "Hmm, should we allow that or redirect to profile?"

**Me:** "Recommendation: Redirect to profile with message 'You're already logged in'"

**You:** "Done. Update the plan?"

**Me:** "Yes, I'll note these decisions. Continue?"

## Question Checklist

I'll work through:

### Scope & Flow
- [ ] Happy path defined
- [ ] Error paths identified
- [ ] Cancellation handling
- [ ] Partial completion handling
- [ ] Timeout scenarios

### Data & State
- [ ] Source of truth identified
- [ ] Data validation rules
- [ ] Migration strategy (if changing schema)
- [ ] Backward compatibility

### External Dependencies
- [ ] API failure handling
- [ ] Rate limiting
- [ ] Third-party downtime
- [ ] Network timeouts

### Security & Permissions
- [ ] Authentication required?
- [ ] Authorization rules
- [ ] Input sanitization
- [ ] Audit logging

### Performance & Scale
- [ ] Expected load
- [ ] Pagination needed?
- [ ] Caching strategy
- [ ] Async processing needed?

### Edge Cases
- [ ] Empty states
- [ ] Maximum limits
- [ ] Concurrent access
- [ ] Time-based issues (timezone, DST)

## Output

After grilling, I'll provide:

1. **Decision Log** – All resolved questions
2. **Updated Plan** – With edge cases noted
3. **Risk Assessment** – High-risk areas flagged
4. **Test Suggestions** – Critical test cases

## Tips for You

- **Don't defend** – The goal is finding gaps, not winning
- **Say "I don't know"** – That's valuable information
- **Ask for recommendations** – I'll suggest best practices
- **Update your plan** – Document decisions immediately

## Integration with Other Skills

| Sequence | Use Case |
|----------|----------|
| `write-a-prd` → `grill-me` | Validate PRD before planning |
| `grill-me` → `plan-feature` | Stress-test, then create plan |
| `plan-feature` → `grill-me` | Review plan before implementation |
| `grill-me` → `tdd-loop` | Clarify, then build with TDD |

## Checklist for Me

- [ ] Plan/document loaded
- [ ] Questions prepared (one at a time)
- [ ] Recommendations ready
- [ ] Decision log maintained
- [ ] All branches explored
- [ ] Output provided (decisions, risks, tests)
