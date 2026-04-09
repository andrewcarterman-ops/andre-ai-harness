# Domain: YAML/Registry System

## Analysis Scope
Configuration files in `registry/` directory:
- `agents.yaml` - Agent registry definitions
- `skills.yaml` - Skill catalog registry
- `hooks.yaml` - Event trigger registry

---

## Intention vs. Reality

### What the System SHOULD Do (Based on Manifest)

The registry system is designed to be a **centralized configuration hub** that:

1. **Agent Registry (`agents.yaml`)**: Define 6 sub-agents with their triggers, purposes, and metadata
2. **Skill Registry (`skills.yaml`)**: Catalog 18 skills with categories, triggers, and workflow chains
3. **Hook Registry (`hooks.yaml`)**: Define event triggers (`session:start`, `session:end`, `review:post_execution`) mapped to handler files

### What the Manifest Actually Describes

| Component | Claimed | Issues Identified |
|-----------|---------|-------------------|
| **agents.yaml** | 6 sub-agent definitions | No schema validation described; trigger phrases may conflict |
| **skills.yaml** | 18 skills cataloged | Only 17 skill directories listed; `safe-file-ops` is orphaned |
| **hooks.yaml** | 3 active hooks | No hook ENGINE described - just markdown files |

---

## Logical Errors Found

### Error 1: Orphaned Skill Directory
- **Location**: `skills/safe-file-ops/SKILL.md`
- **Current behavior**: Directory exists but skill is NOT listed in the 18-skill catalog
- **Expected behavior**: Either included in skills.yaml OR removed if deprecated
- **Why it's a problem**: Dead code that may be referenced but never activated; creates maintenance burden
- **Severity**: Medium
- **Suggested fix**: 
  - Option A: Add `safe-file-ops` to skills.yaml with appropriate category/trigger
  - Option B: Remove directory if intentionally deprecated
  - **Recommendation**: Add to skills.yaml under `tooling` category with trigger "safe file operations"

### Error 2: Skill Count Mismatch
- **Location**: `registry/skills.yaml` (implied) vs `skills/` directory
- **Current behavior**: Manifest claims 18 skills, lists 17 in section 3.1 table, but filesystem shows 18 directories (including safe-file-ops)
- **Expected behavior**: Consistent count across documentation, registry, and filesystem
- **Why it's a problem**: Indicates documentation drift; operators cannot trust the manifest as source of truth
- **Severity**: Medium
- **Manifest evidence**:
  ```
  Section 3.1: "18 Skills installiert" in header
  Table lists: 17 skills (write-a-prd through write-a-prd, missing safe-file-ops)
  Section 3.2 categories: Lists 18 skills (includes safe-file-ops in tooling)
  Section 6.1 filesystem: Shows 18 skill directories including safe-file-ops
  ```

### Error 3: Hook Engine Not Defined
- **Location**: `registry/hooks.yaml` and `hooks/` directory
- **Current behavior**: Hooks are defined in YAML and handler files exist, but NO ENGINE is described to actually trigger them
- **Expected behavior**: Either:
  - A hook engine that reads hooks.yaml and executes handlers
  - OR hooks are manually invoked from code with clear call sites
- **Why it's a problem**: The manifest describes hooks as "active" but provides no mechanism for activation. This is a hallucinated implementation.
- **Severity**: High
- **Key question**: Does the OpenClaw runtime actually:
  1. Read hooks.yaml at startup?
  2. Monitor for trigger events?
  3. Execute handler markdown files?
  
  Or are hooks just documentation that the operator manually invokes?

### Error 4: Agent Trigger Overlap
- **Location**: `registry/agents.yaml` (implied) and agent definitions
- **Current behavior**: Multiple agents may respond to similar triggers based on manifest description:
  - "review code" → could trigger `code-reviewer` OR `python-reviewer`
  - "security" → could trigger `security-reviewer` OR `ecc-autoresearch` skill
- **Expected behavior**: Clear, non-overlapping trigger definitions with priority/ordering
- **Why it's a problem**: Ambiguous routing leads to unpredictable agent selection
- **Severity**: Medium
- **Manifest evidence** (Section 2.4):
  ```
  code-reviewer: "review code", "quality check"
  python-reviewer: "python review", "pep8"
  # But what happens with "review python code"?
  ```

---

## Inefficiencies Identified

### Inefficiency 1: YAML-Code Duality
- **Description**: Skills are defined in BOTH skills.yaml AND individual SKILL.md files
- **Impact**: Maintenance
- **Current pattern**:
  1. Skill metadata in skills.yaml (name, category, trigger)
  2. Skill implementation in SKILL.md (instructions, patterns)
- **Problem**: Two sources of truth; changing a skill requires editing two files
- **Suggestion**: Consider if skills.yaml should be auto-generated from SKILL.md frontmatter, OR if SKILL.md should be the single source with skills.yaml as an index

### Inefficiency 2: Hook Handler Format
- **Description**: Hook handlers are markdown files (`.md`) not executable code
- **Impact**: Performance/Maintenance
- **Current behavior**: `hooks/session-start.md` contains instructions
- **Question**: How is this executed? Options:
  1. **Interpreted**: Runtime reads markdown and executes embedded commands (complex, error-prone)
  2. **Documentation**: Hooks are just docs; operator manually follows (not truly "active")
  3. **Code-backed**: There's a corresponding `.js`/`.ts` file not shown in manifest
- **Recommendation**: Clarify the execution model in documentation

### Inefficiency 3: Redundant Skill Categories
- **Description**: Skills are categorized in skills.yaml but also have implicit categories via directory structure
- **Impact**: Maintenance
- **Manifest evidence**: Section 3.2 shows categories that don't match directory structure
- **Example**: `testing-patterns` and `refactoring` are both "quality" category but in separate directories
- **Suggestion**: Either:
  - Use directory structure as category (filesystem as config)
  - OR remove categories from skills.yaml if not used by runtime

---

## Missing Connections

### Connection 1: Registry to Runtime
- **Expected**: `registry/*.yaml` should be read by OpenClaw runtime at startup
- **Reality**: No evidence in manifest that these files are actually loaded
- **Missing**: Configuration loader, schema validation, runtime binding

### Connection 2: Agent Definitions to Agent Code
- **Expected**: `agents.yaml` entries should map to executable agent implementations
- **Reality**: Manifest shows `agents/*.md` files (markdown definitions)
- **Missing**: The actual agent runtime - are these:
  - Prompt templates for LLM sub-agent spawning?
  - Documentation only?
  - Configuration for some agent framework?

### Connection 3: Hooks.yaml to Hook Triggers
- **Expected**: hooks.yaml defines triggers that are monitored by the system
- **Reality**: No hook monitoring system described
- **Missing**: Event bus, trigger detection, handler invocation

### Connection 4: Skill Triggers to Skill Activation
- **Expected**: "write prd" trigger should activate `write-a-prd` skill
- **Reality**: No trigger matching system described in manifest
- **Missing**: Intent recognition, skill routing, context injection

---

## Hallucinated Implementations

### Hallucination 1: "Active" Hooks
- **Claim**: Section 8.2: "Hooks (Aktiv)" with 3 hooks listed
- **Reality**: Only markdown handler files exist; no execution mechanism described
- **Evidence**: 
  - `hooks/session-start.md` - likely contains instructions, not code
  - `hooks/session-end.md` - same
  - `hooks/review-post-execution.md` - same
- **Assessment**: The hooks are DEFINED but not necessarily ACTIVE. The manifest conflates "defined" with "active".

### Hallucination 2: Automatic Skill Selection
- **Claim**: Section 7.3 "Skill-System (Mandatory)" describes automatic skill selection:
  ```
  1. `<available_skills>` scannen
  2. Genau einen Skill wählen, der passt
  3. Nur diesen einen SKILL.md lesen
  ```
- **Reality**: No `<available_skills>` context variable or scanning mechanism is described elsewhere
- **Question**: Is this implemented in the OpenClaw runtime, or is this a convention for manual operation?

### Hallucination 3: Agent Trigger Phrases
- **Claim**: Section 2.4 lists trigger phrases for each agent
- **Reality**: No trigger matching system is described
- **Question**: How do "architect" or "design system" phrases route to the architect agent? Is there:
  - A keyword matcher?
  - An LLM-based intent classifier?
  - Manual operator selection?

---

## Configuration Schema Analysis

### agents.yaml (Inferred Schema)
```yaml
# Hypothetical structure based on manifest Section 2.4
agents:
  - id: architect
    emoji: "🏗️"
    purpose: "System-Design, ADRs"
    triggers: ["architect", "design system"]
    definition_file: "agents/architect.md"
  
  - id: planner
    emoji: "📋"
    purpose: "Task-Zerlegung, Roadmaps"
    triggers: ["plan", "break down", "roadmap"]
    definition_file: "agents/planner.md"
  
  # ... 4 more agents
```

**Issues**:
- No schema version
- No priority/ordering for overlapping triggers
- No disabled/enabled flag
- No model override (all use default?)

### skills.yaml (Inferred Schema)
```yaml
# Hypothetical structure based on manifest Section 3
skills:
  - id: write-a-prd
    category: planning
    function: "Produktanforderungen erstellen"
    trigger: ["write prd", "product requirements"]
    workflow_chain: "start"
  
  - id: grill-me
    category: planning
    function: "Pläne stress-testen"
    trigger: ["grill me", "review plan"]
    workflow_chain: "middle"
  
  # ... 16 more skills
```

**Issues**:
- `safe-file-ops` missing from catalog
- `mission-control-v2` has different directory structure (no SKILL.md shown)
- No version field for skill compatibility
- No dependencies between skills

### hooks.yaml (Inferred Schema)
```yaml
# Hypothetical structure based on manifest Section 8.2
hooks:
  - event: session:start
    handler: hooks/session-start.md
    enabled: true
  
  - event: session:end
    handler: hooks/session-end.md
    enabled: true
  
  - event: review:post_execution
    handler: hooks/review-post-execution.md
    enabled: true
    condition: "critical_ops"  # implied
```

**Issues**:
- No event bus definition
- No handler execution order
- No error handling for failed hooks
- No conditional hook triggering (when should `review:post_execution` fire?)

---

## Hardcoded Values That Should Be Config

### Finding 1: Sync Frequency
- **Location**: Section 7.6 "Aktive Cron-Jobs"
- **Hardcoded**: "obsidian-sync-pipeline: Alle 5 Minuten"
- **Should be**: `registry/cron.yaml` with configurable interval

### Finding 2: Model Defaults
- **Location**: Section 2.3, 8.1
- **Hardcoded**: "Default Model: kimi-coding/kimi-k2-thinking"
- **Should be**: `registry/models.yaml` with agent-specific overrides

### Finding 3: Memory Paths
- **Location**: Section 5.1, 5.4
- **Hardcoded**: `memory/YYYY-MM-DD.md`, `MEMORY.md`
- **Should be**: `registry/paths.yaml` for customizable directory structure

### Finding 4: Workflow Chains
- **Location**: Section 3.3
- **Hardcoded**: `write-a-prd → grill-me → plan-feature → tdd-loop`
- **Should be**: `registry/workflows.yaml` for customizable pipelines

---

## Analyzer Notes

### Critical Concerns

1. **The Hook Problem**: The most significant issue is the disconnect between `hooks.yaml` definitions and actual hook execution. The manifest describes hooks as "active" but provides no mechanism. This suggests either:
   - The hook system is not yet implemented
   - The hook system is implemented but not documented in the manifest
   - "Active" means "available for manual use" not "automatically triggered"

2. **Registry-Runtime Gap**: There's no clear evidence that `registry/*.yaml` files are actually read by the OpenClaw runtime. They may be:
   - Documentation for operator reference
   - Configuration for a system that doesn't exist yet
   - Actually used but not described in the manifest

3. **Skill Activation Ambiguity**: The skill trigger system is described as mandatory (Section 7.3) but the mechanism is unclear. Is this:
   - LLM-based intent classification?
   - Keyword matching?
   - Manual operator selection guided by prompts?

### Recommendations for Operator Review

1. **Verify hook execution**: Does the OpenClaw runtime actually execute hooks automatically? If so, how?

2. **Confirm registry usage**: Are `agents.yaml`, `skills.yaml`, `hooks.yaml` actually loaded at runtime, or are they documentation?

3. **Clarify skill selection**: How does "write prd" actually route to the `write-a-prd` skill? Is this automated or manual?

4. **Resolve safe-file-ops**: Is this skill active or deprecated? If active, add to skills.yaml catalog.

5. **Document the execution model**: The manifest needs a section explaining HOW configurations translate to runtime behavior.

---

## Summary

| Issue Type | Count | Severity |
|------------|-------|----------|
| Logical Errors | 4 | 1 High, 3 Medium |
| Inefficiencies | 3 | All Maintenance |
| Missing Connections | 4 | Architecture |
| Hallucinated Implementations | 3 | Documentation |
| Hardcoded Values | 4 | Configurability |

**Overall Assessment**: The YAML/Registry System appears to be a **configuration-as-documentation** approach rather than a true configuration-driven runtime. The registry files likely serve as structured documentation that operators manually follow, rather than active configuration loaded by the system. This is a valid design choice but should be explicitly documented to avoid confusion.


---

## Critic Review (Agent C2)

**Review Date**: 2026-04-02  
**Critic**: Agent C2 (Logic Critic)  
**Purpose**: Challenge Configuration Analyzer's findings for accuracy

---

### Review Methodology

As the Logic Critic, I applied the following challenges to each finding:
1. **Is this actually a problem** or could there be a valid reason?
2. **What context might the analyzer have missed?**
3. **Could the design be intentional** even if it looks wrong?
4. **Are there edge cases** not considered?

---

### Consensus Findings (Both Analyzer and Critic Agree)

| Finding | Severity | Agreement Notes |
|---------|----------|-----------------|
| **Skill Count Mismatch** | Medium | Both agree: Section 3.1 table lists 17 skills while claiming 18. This is a documentation formatting error. |
| **YAML-Code Duality** | Maintenance | Both agree: Two sources of truth (skills.yaml + SKILL.md) creates maintenance burden. Design may be intentional but has tradeoffs. |
| **Hardcoded Values** | Configurability | Both agree: Sync frequency, model defaults, paths are hardcoded. These *could* be configurable but aren't necessarily problems. |
| **Agent-to-Code Connection Missing** | Architecture | Both agree: No clear evidence how agents.yaml maps to runtime behavior. |

---

### Disputed Findings (Critic Disagrees with Analyzer)

#### Dispute 1: "Orphaned" Skill safe-file-ops

**Analyzer's Position**: `safe-file-ops` is orphaned - exists in filesystem but not in 18-skill catalog.

**Critic's Challenge**: **PARTIALLY DISPUTED**

**Evidence from Manifest**:
- Section 3.1 table: Lists 17 skills (missing safe-file-ops) ❌
- Section 3.2 categories: **INCLUDES safe-file-ops in tooling category** ✅
- Section 6.1 filesystem: Shows 18 directories including safe-file-ops ✅

**Critic's Analysis**:
The skill is **NOT orphaned** - it's intentionally categorized in section 3.2. The issue is:
1. **Documentation inconsistency**: Table in 3.1 is missing one row
2. **Formatting error**: Not an architectural problem
3. **The skill IS documented** in the categories section

**Revised Severity**: Low (documentation formatting, not system issue)

**Recommendation**: Add safe-file-ops to section 3.1 table for consistency

---

#### Dispute 2: Hook Engine "Missing"

**Analyzer's Position**: HIGH severity - hooks defined but no execution mechanism, calling it "hallucinated implementation"

**Critic's Challenge**: **DISPUTED - Severity should be LOWER**

**Key Insight**: The German word **"Aktiv"** in Section 8.2 "Hooks (Aktiv)" means **"enabled/available"** NOT **"automatically executing"**.

**Alternative Interpretation**:
The hooks may be **manual protocols** rather than automated triggers:
- `session-start.md` = Protocol to follow when starting a session
- `session-end.md` = Protocol to follow when ending a session  
- `review-post-execution.md` = Protocol for post-execution review

**Evidence Supporting Manual Protocol Interpretation**:
1. Section 5.1 "Session Startup" describes a manual sequence - hooks aren't mentioned
2. Handler files are `.md` (documentation), not `.js`/`.ts` (code)
3. No event bus or trigger detection system is described anywhere
4. The manifest describes *what to do* not *what automatically happens*

**Critic's Assessment**:
The analyzer assumed hooks should be automatic, but they may be **intentionally manual**. This is a **design choice**, not a missing implementation.

**Revised Severity**: Low-Medium (documentation clarity needed, not missing engine)

**Recommendation**: Clarify in manifest whether hooks are automatic or manual protocols

---

#### Dispute 3: Agent Trigger Overlap is a Problem

**Analyzer's Position**: MEDIUM severity - overlapping triggers create ambiguous routing

**Critic's Challenge**: **PARTIALLY DISPUTED**

**Alternative Interpretation**:
Trigger overlap may be **intentional** with specificity-based resolution:

| Trigger | Agents | Specificity |
|---------|--------|-------------|
| "review code" | code-reviewer | General |
| "python review" | python-reviewer | Specific |
| "review python code" | ??? | Ambiguous |

**Possible Resolution Strategies** (not documented but possibly implemented):
1. **Most specific wins**: "python review" > "review code"
2. **Order matters**: First match in agents.yaml wins
3. **LLM classification**: Triggers are hints, LLM decides
4. **Manual selection**: Operator chooses when ambiguous

**Critic's Assessment**:
The analyzer identified a potential issue, but **we don't know if it's actually a problem** without seeing:
- The actual agents.yaml content
- How the runtime resolves conflicts
- Whether conflicts have occurred

**Revised Severity**: Low (potential issue, not confirmed problem)

**Recommendation**: Document trigger resolution strategy in manifest

---

### Additional Findings (Critic Only)

The analyzer missed these issues:

#### Finding C1: mission-control-v2 Structure Anomaly

**Location**: Section 6.1 filesystem listing

**Issue**: `mission-control-v2/` is listed without `SKILL.md` while ALL other skills show `SKILL.md`

**Questions**:
- Is mission-control-v2 a directory-only skill?
- Does it have a different structure intentionally?
- Is this a documentation omission?

**Severity**: Low (needs clarification)

---

#### Finding C2: "Mandatory" Skill System Without Mechanism

**Location**: Section 7.3 "Skill-System (Mandatory)"

**Issue**: The manifest claims skill scanning is mandatory and describes the process:
```
1. `<available_skills>` scannen
2. Genau einen Skill wählen, der passt
3. Nur diesen einen SKILL.md lesen
```

**Missing**: 
- What populates `<available_skills>`?
- How is the skill "chosen"? (LLM? Keyword? Operator?)
- What happens if no skill matches?

**Severity**: Medium (claimed feature without implementation evidence)

---

#### Finding C3: Registry Files May Be Documentation-Only

**Issue**: No evidence that `registry/*.yaml` files are actually read at runtime

**Evidence**:
- Section 5.1 mentions reading `registry/agents.yaml` but this may be descriptive, not prescriptive
- No configuration loader described
- No schema validation mentioned
- YAML files could be "documentation-as-code" for human operators

**Implication**: The entire "registry" system may be **structured documentation** not **runtime configuration**

**Severity**: Low (if documented clearly) to Medium (if operators expect automation)

---

#### Finding C4: Agent Count Actually Matches

**Observation**: While the analyzer focused on skill count mismatch, they missed that **agent count is consistent**:

| Source | Count | Details |
|--------|-------|---------|
| Section 2.4 table | 6 agents | Listed with triggers |
| Section 6.1 filesystem | 6 files | architect.md through security-reviewer.md |
| Replication checklist | 6 agents | "agents/*.md Dateien für alle 6 Sub-Agenten" |

**Assessment**: The agent registry is internally consistent. This is a **positive finding** the analyzer missed.

---

### Summary of Disputes

| Finding | Analyzer Severity | Critic's View | Revised Severity |
|---------|------------------|---------------|------------------|
| Orphaned safe-file-ops | Medium | Documentation inconsistency, not orphaned | Low |
| Hook Engine Missing | High | May be intentional manual protocols | Low-Medium |
| Agent Trigger Overlap | Medium | May be intentional with specificity rules | Low |
| Skill Count Mismatch | Medium | Accurate - documentation error | Medium |

### Net Assessment

**Analyzer was correct about**: Documentation inconsistencies, hardcoded values, missing connection documentation

**Analyzer may have overestimated**: Hook engine "missing" (may be intentional), skill "orphaned" (it's documented elsewhere)

**Analyzer missed**: mission-control-v2 structure anomaly, "mandatory" skill system without mechanism, agent count actually matches

**Overall**: The YAML/Registry System is likely **documentation-as-code** rather than a true runtime configuration system. The "issues" are mostly documentation clarity problems, not architectural failures.

---

*Review completed by Agent C2 (Logic Critic)*
