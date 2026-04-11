---
name: plan-feature
description: Turn a feature idea into a phased implementation plan using vertical slices (tracer bullets). Use when user wants to break down a feature, create an implementation plan, plan phases, or mentions "tracer bullets" or "vertical slices".
---

# Plan Feature

Transform a feature idea into a phased implementation plan using **vertical slices** (tracer bullets). Output is a Markdown file in `./plans/`.

## Quick Start

1. Describe your feature idea
2. I'll explore the codebase (if needed)
3. We'll identify durable architectural decisions
4. I'll propose vertical slices
5. You review and approve
6. Plan saved to `./plans/<feature-name>.md`

## What are Vertical Slices?

**Vertical slices** are thin, complete paths through ALL layers:

```
❌ HORIZONTAL (bad):
Phase 1: Write all tests
Phase 2: Build all API
Phase 3: Build all UI

✅ VERTICAL (tracer bullets):
Phase 1: ONE feature end-to-end (DB→API→UI→Tests)
Phase 2: NEXT feature end-to-end
Phase 3: NEXT feature end-to-end
```

Each slice is **demoable on its own**.

## Process

### Phase 0: Redundancy Check (NEW - Critical)

**Before starting any feature, check if it already exists:**

| Check | Location | Command/Method |
|-------|----------|----------------|
| Workarounds | `How-To/` | `memory_search "workaround"` |
| Skills | `skills/` + `registry/skills.yaml` | Read registry/skills.yaml |
| Scripts | `00-Meta/Scripts/` | List directory |
| Documentation | `MEMORY.md` + `_MOC-Knowledge.md` | Search memory |
| Projects | `02-Projects/` | Check _MOC-Projects.md |
| Tools | `TOOLS.md` | Read TOOLS.md |

**If unsure:** Ask user "Do we already have something for this?"

**Lesson Learned:** 11-04-2026 - Created duplicate SafeEdit.psm1 when edit-tool-workaround.md already existed.

---

### 1. Confirm Feature Scope

Tell me:
- What problem are you solving?
- Who is the user?
- What does "done" look like?

### 2. Explore Codebase

If needed, I'll explore to understand:
- Current architecture
- Existing patterns
- Integration points

### 3. Identify Durable Decisions

Before slicing, we'll lock in:

| Decision Type | Examples |
|--------------|----------|
| Routes | URL patterns, API endpoints |
| Schema | Database tables, data models |
| Auth | Authentication/authorization approach |
| Boundaries | Third-party service interfaces |

These go in the plan header.

### 4. Draft Vertical Slices

I'll break the feature into **tracer bullet phases**:

<vertical-slice-rules>
- Each slice: narrow but COMPLETE through all layers
- Each slice: demoable/verifiable on its own
- Prefer many thin slices over few thick ones
- NO specific filenames or function names (will change)
- YES durable decisions: routes, schema shapes, model names
</vertical-slice-rules>

### 5. Quiz You

I'll present phases as a numbered list:

| Phase | Title | User Stories Covered |
|-------|-------|---------------------|
| 1 | Basic user creation | #1, #2 |
| 2 | Email verification | #3 |
| 3 | Password reset | #4, #5 |

**You decide:**
- Granularity (too coarse / too fine?)
- Merge or split phases?
- Reordering?

### 6. Write Plan File

Creates `./plans/` if missing. Saves plan as Markdown.

## Plan Template

```markdown
# Plan: <Feature Name>

> Source: <brief description or link>

## Durable Architectural Decisions

| Decision | Choice |
|----------|--------|
| Routes | ... |
| Schema | ... |
| Key Models | ... |
| Auth | ... |

---

## Phase 1: <Title>

**User stories:** <list>

### What to Build

Concise description of this vertical slice. Describe end-to-end behavior, not layer-by-layer implementation.

### Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Technical Notes

- Durable decisions used
- Integration points
- Testing approach

---

## Phase 2: <Title>

...
```

## Example Session

**You:** "I want to add user authentication"

**Me:** [Explores codebase, identifies durable decisions]

**Me:** "Here's my proposed breakdown:

| Phase | Title | Stories |
|-------|-------|---------|
| 1 | Basic login form | User can enter credentials |
| 2 | Session management | User stays logged in |
| 3 | Registration flow | New user can sign up |

Does this granularity feel right? Should any phases be merged or split?"

**You:** "Split phase 3 into email verification and registration"

**Me:** [Updates plan, writes to `./plans/user-authentication.md`]

## Checklist for Me

### Phase 0: Pre-Flight
- [ ] **Redundancy check performed** - Verified no existing solution
- [ ] Searched: How-To/, skills/, Scripts/, MEMORY.md
- [ ] Asked user if unsure about existing solutions

### Phase 1-6: Planning
- [ ] Feature scope confirmed
- [ ] Codebase explored (if needed)
- [ ] Durable decisions identified
- [ ] Vertical slices drafted
- [ ] User approved breakdown
- [ ] Plan written to `./plans/`

## Redundancy Prevention

- [tdd-loop](tdd-loop/SKILL.md) – Execute phases with TDD
- [grill-me](grill-me/SKILL.md) – Stress-test the plan first
- Matt Pocock's prd-to-plan inspiration
te new?"
3. Document decision

**Example failure:** 11-04-2026 - Created SafeEdit.psm1 when edit-tool-workaround.md already existed in How-To/.

## See Also

- [tdd-loop](tdd-loop/SKILL.md) – Execute phases with TDD
- [grill-me](grill-me/SKILL.md) – Stress-test the plan first
- Matt Pocock's prd-to-plan inspiration
