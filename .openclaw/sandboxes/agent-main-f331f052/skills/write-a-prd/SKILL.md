---
name: write-a-prd
description: Create a Product Requirements Document through interactive user interview, codebase exploration, and module design. Use when user wants to write a PRD, create product requirements, or plan a new feature from scratch.
---

# Write a PRD

Create a Product Requirements Document through structured interview, codebase exploration, and collaborative design.

## Quick Start

```
You: "Write a PRD for user authentication"

Me: [Interview] "Tell me about the problem..."

Me: [Explore] [Checks existing auth code]

Me: [Grill] "What if email bounces? What about rate limiting?"

Me: [Modules] "We'll need: SessionManager, EmailService, Validator"

Me: [Write PRD] [Outputs structured document]
```

## Process

### 1. Gather Requirements

I'll ask for a **long, detailed description** of:

- The problem you're solving
- Who the users are
- Any solution ideas you have
- Constraints or requirements
- Success criteria

**Your job:** Brain dump everything. Don't filter.

### 2. Explore Codebase

I verify your assumptions and understand:

- Current architecture
- Existing patterns
- Similar features
- Technical constraints

This prevents designing something incompatible.

### 3. Relentless Interview

Using [grill-me](grill-me/SKILL.md) approach:

- One question at a time
- Walk down each decision branch
- Resolve dependencies
- I provide recommended answers

Continue until we have **shared understanding**.

### 4. Design Modules

Sketch major modules needed:

- What to build vs modify
- Look for **deep modules** (simple interface, complex implementation)
- Identify testable boundaries
- Check with you before finalizing

**Deep module example:**
```
SessionManager
├── Interface: create(), validate(), destroy()
└── Implementation: Token gen, expiry, rotation, storage
```

### 5. Write PRD

Output structured document:

## PRD Template

```markdown
# PRD: <Feature Name>

## Problem Statement

From the user's perspective: What problem exists? Why does it matter?

## Solution

From the user's perspective: How does this feature solve the problem?

## User Stories

Long, numbered list. Format: "As a [actor], I want [feature], so that [benefit]"

1. As a new user, I want to create an account, so that I can access the platform
2. As a returning user, I want to log in with email/password, so that I can access my data
3. As a forgetful user, I want to reset my password, so that I can regain access
4. ...

## Implementation Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Auth method | JWT tokens | Stateless, scalable |
| Password storage | bcrypt | Industry standard |
| Session duration | 7 days | Balance security/UX |
| Rate limiting | 5 attempts/min | Prevent brute force |

### Modules

| Module | Responsibility | Interface |
|--------|----------------|-----------|
| AuthController | HTTP handling | login(), register(), reset() |
| TokenService | JWT management | create(), validate(), refresh() |
| UserRepository | User persistence | findByEmail(), create(), update() |

## Testing Decisions

- **Test approach**: Integration tests through public APIs
- **Modules to test**: TokenService (complex logic), AuthController (integration)
- **Prior art**: See existing auth tests in `tests/auth/`

## Out of Scope

Explicitly NOT included:
- OAuth/Social login (Phase 2)
- 2FA/MFA (Phase 3)
- Admin user management (separate feature)

## Further Notes

- Security audit required before launch
- Consider adding login notifications
- Monitor for unusual patterns
```

## Example Session

**You:** "I need user authentication for my app"

**Me:** "Tell me everything. Who are the users? What problem does auth solve? Any specific requirements?"

**You:** [Brain dump about users, security needs, existing code]

**Me:** [Explores codebase] "I see you have a basic User model. No auth yet. What happens if someone tries to register with an existing email?"

**You:** "Good question. Probably show an error?"

**Me:** "Recommendation: Show generic 'Check your email' message (security through obscurity). Agreed?"

**You:** "Yes, that's better"

**Me:** "Rate limiting on login attempts?"

**You:** "5 per minute?"

**Me:** "Good. Modules I'm seeing: AuthController, TokenService, UserRepository, EmailService. Which need tests?"

**You:** "TokenService definitely, it's complex"

**Me:** "Agreed. Let me write the PRD..."

[Writes structured PRD following template]

## Integration with Other Skills

| Sequence | Use Case |
|----------|----------|
| `write-a-prd` (solo) | Start from scratch |
| `write-a-prd` → `grill-me` | Write, then stress-test |
| `write-a-prd` → `plan-feature` | PRD → phased plan |
| `grill-me` → `write-a-prd` | Validate first, then document |

## Output Options

### Option A: Save to File
```
./prd/<feature-name>.md
```

### Option B: GitHub Issue
(Create if user requests)

### Option C: Memory
(Update MEMORY.md with decisions)

## Checklist for Me

- [ ] Requirements gathered (brain dump complete)
- [ ] Codebase explored (assumptions verified)
- [ ] Relentless interview complete (all branches explored)
- [ ] Modules designed (deep modules identified)
- [ ] Testing approach agreed
- [ ] PRD written (all sections filled)
- [ ] User reviewed PRD
- [ ] Saved to appropriate location

## Quality Criteria

A good PRD has:

- [ ] Clear problem statement (user perspective)
- [ ] Comprehensive user stories (10+ for complex features)
- [ ] Durable implementation decisions documented
- [ ] Out of scope explicitly defined
- [ ] Testing strategy outlined
- [ ] No specific file paths (those change)
- [ ] No code snippets (outdate quickly)
