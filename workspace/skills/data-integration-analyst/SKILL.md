---
name: data-integration-analyst
version: "1.0.0"
description: |
  Forensic data analyst for integrating unstructured, messy, or seemingly unrelated data into existing OpenClaw systems with 100% precision.
  Performs systematic archaeology through 5 phases: Data Ingestion, System Archaeology, Comparative Analysis, Integration Decision, and Validation.
  Never assumes, always verifies against existing implementation. Read-only until Phase 5 approval.
author: Andrew
date: 11-04-2026
tags: [forensic, analysis, integration, data, archaeology, validation]
triggers:
  - "analyze data for integration"
  - "forensic data analysis"
  - "integrate unstructured data"
  - "data archaeology"
  - "chaotic data analysis"
  - "should i integrate this"
  - "compare with existing system"
allowed_tools:
  - file_read
  - file_write
  - exec
  - text_edit
  - git
constraints:
  - "NEVER modify existing skills during analysis - remain read-only until Phase 5 approval"
  - "NEVER assume tool availability - always check config.yaml or ask"
  - "ALWAYS complete all 5 phases for 100% thoroughness"
  - "Request schema definition when uncertain - never infer"
  - "Stop at 3 parsing failures and request cleaner data"
---

# Data Integration Analyst Skill

Forensic data analyst for 100% precision integration analysis of unstructured/messy data into OpenClaw systems.

## When to Use

- Analyzing unstructured, chaotic, or unclear data for system integration
- Determining if external data can/should be integrated
- Comparing new data against existing OpenClaw infrastructure
- Making integration decisions with full forensic evidence

## The 5 Phases (MUST complete all)

---

## Phase 1: Data Ingestion & Forensic Structuring

### 1.1 Raw Data Ingest
```
Read ALL source data into: tmp/raw-data-ingest.md
- NO filtering
- NO modification
- Preserve original formatting
- Document source path and timestamp
```

### 1.2 Normalize to Structured Format
```
Create: tmp/normalized-data.json

Format:
{
  "ingest_timestamp": "ISO8601",
  "source_path": "original/location",
  "files": [
    {
      "filename": "name",
      "type": "extension",
      "format": "detected_format",
      "size_bytes": 1234,
      "checksum_sha256": "abc123...",
      "structure": "ordered|chaotic",
      "parseable": true|false,
      "content_sample": "first_500_chars",
      "parsing_errors": []
    }
  ],
  "overall_assessment": {
    "total_files": N,
    "parseable_files": N,
    "failed_parses": N,
    "structure_quality": "ordered|mixed|chaotic"
  }
}
```

### 1.3 Error Handling
- **Track parsing failures**
- **STOP at 3 failures** → Request cleaner data
- Document each failure with:
  - File name
  - Error type
  - Suggested fix

### 1.4 Fuzzy Matching for Messy Data
- Use `ag` or `grep` for pattern detection
- Apply **Chunking** (100-line blocks) for large datasets
- **Noise Filtering** after normalization
- Assign **Confidence Scores** (0-100%)

---

## Phase 2: System Archaeology

### 2.1 Create Target System Inventory
```
Execute: find ~/.openclaw -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.md" \)

Create: tmp/system-archaeology-report.md
```

### 2.2 Analyze Existing Skills
```
For each discovered skill:
- Read SKILL.md
- Extract: name, purpose, triggers, constraints
- Identify: schema patterns, naming conventions
- Document: dependencies, tool requirements
```

### 2.3 Document System Gaps
```
In tmp/system-archaeology-report.md, document:

## Existing System Inventory

### Skills Found: N
| Skill | Category | Triggers | Schema | Dependencies |
|-------|----------|----------|--------|--------------|
| name | type | keywords | pattern | tools needed |

### Naming Conventions Detected
- Files: pattern_detected
- Directories: structure_pattern
- IDs: naming_pattern

### Tool Availability
| Tool | Status | Location |
|------|--------|----------|
| tool_name | available|config_path |

### Schema Patterns
- Frontmatter: fields_detected
- Structure: organizational_pattern

### Identified Gaps
- Missing functionality: ...
- Incomplete coverage: ...
- Tool gaps: ...
```

---

## Phase 3: Comparative Analysis Matrix

### 3.1 Create Comparison Matrix
```
Create: tmp/comparison-matrix.md

## Comparative Analysis Matrix

### Source Data Analysis
| Attribute | Source Data Value | Confidence |
|-----------|------------------|------------|
| Primary Function | detected_purpose | % |
| Data Format | format_detected | % |
| Schema Type | schema_pattern | % |
| Tool Dependencies | tools_required | % |
| Naming Pattern | naming_style | % |

### System Comparison
| Existing Skill | Functionality Match | Schema Match | Tool Match | Naming Match | Overall |
|----------------|-------------------|--------------|------------|--------------|---------|
| skill_name | 0-100% | 0-100% | 0-100% | 0-100% | AVG% |

### Classification Key
- **90-100%** = DUPLICATE (already exists)
- **50-89%** = MERGE_CANDIDATE (overlap, needs strategy)
- **0-49%** = NOVEL (new functionality)
```

### 3.2 Matching Criteria
| Criterion | Weight | How to Measure |
|-----------|--------|----------------|
| Functionality | 40% | Purpose alignment |
| Schema | 25% | Structure compatibility |
| Tools | 20% | Dependency overlap |
| Naming | 15% | Convention similarity |

---

## Phase 4: Integration Feasibility Decision

### Decision Matrix

#### Option A: REJECT
**Conditions:**
- Data unrepairably corrupt
- 100% DUPLICATE (already exists)
- Required tools not available
- Schema fundamentally incompatible

**Output Format:**
```markdown
## VERDICT: NOT INTEGRABLE

### Technical Why
- Specific reason 1
- Specific reason 2
- Evidence: file/link

### What Would Make It Work
- Required changes
- Alternative approaches

### Partial Usability
- [ ] Can salvage X%
- [ ] Component Y is usable
```

#### Option B: 100% ADD (PURE ADDITION)
**Conditions (ALL must be true):**
- Novel functionality (0% overlap)
- No naming collisions
- All required tools available
- Schema compatible
- No breaking changes

**Output Format:**
```markdown
## VERDICT: PURE ADDITION - NOVEL

### Integration Location
```
skills/new-skill-name/
├── SKILL.md
├── README.md
└── [optional] GUIDE.md
```

### Compatibility Score: 100%
- [x] No functionality overlap
- [x] Schema compatible
- [x] Tools available
- [x] Naming unique
- [x] No breaking changes

### Implementation Steps
1. Create directory structure
2. Write SKILL.md
3. Update registry/skills.yaml
4. Validate with health check
```

#### Option C: PARTIAL MERGE
**Conditions:**
- 40-80% overlap with existing
- Some compatibility
- Requires strategy decision

**Output Format:**
```markdown
## VERDICT: MERGE REQUIRED

### Collision Analysis
| Aspect | Source | Existing | Overlap % |
|--------|--------|----------|-----------|
| Function | X | Y | Z% |
| Schema | X | Y | Z% |
| Tools | X | Y | Z% |

### Recommended Strategy
Choose ONE:
- [ ] **Extension**: Add to existing skill
- [ ] **Refactor**: Restructure both
- [ ] **Specialization**: Create variant

### Diff Preview
```diff
- existing content
+ new content
```

### Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Breaking change | Low/Med/High | Severity | Strategy |
```

---

## Phase 5: Validation & Handoff

### 5.1 Self-Check
```
1. Re-read comparison-matrix.md
2. Verify with grep that no skills were overlooked
3. Confirm verdict aligns with evidence
4. Check for contradictions
```

### 5.2 Consistency Check
- Does verdict match data? → Yes/No
- Are confidence scores justified? → Verify
- Any assumptions made? → Document or remove

### 5.3 User Confirmation

#### For REJECT:
```
Present: Redacted sections showing WHY
Wait for: User acknowledgment
```

#### For 100% ADD:
```
Present: File tree of proposed addition
Show: Visual diff (new vs empty)
Wait for: Explicit approval
```

#### For PARTIAL MERGE:
```
Present: Detailed diff showing collisions
Explain: Recommended strategy with pros/cons
Ask: "Which strategy should I implement?"
Wait for: Strategy selection + approval
```

### 5.4 ONLY AFTER Approval
```
PHASE 5 APPROVAL RECEIVED → Proceed to filesystem modification

Implementation:
1. Create backup
2. Execute integration
3. Validate result
4. Update registry
5. Run health check
```

---

## Critical Constraints

| Constraint | Enforcement |
|------------|-------------|
| **Read-only until Phase 5** | Never write to skills/* during Phases 1-4 |
| **Tool verification** | Check config.yaml or ask before assuming |
| **Complete all phases** | Even if early rejection seems obvious |
| **Schema clarity** | Request definition, never infer |
| **3-strike parsing** | Stop at 3 failures, demand cleaner data |

## Evidence Standards

All claims MUST be backed by:
- File paths
- Line numbers
- Exact quotes
- Checksums
- Confidence scores

## Output Templates

### Final Report Structure
```
tmp/data-integration-report.md
├── Executive Summary (Verdict)
├── Phase 1: Data Analysis
├── Phase 2: System Archaeology
├── Phase 3: Comparative Matrix
├── Phase 4: Feasibility Decision
├── Phase 5: Validation
└── Appendix: Raw Evidence
```

---

## Related

- [[migration-best-practices|Safe Migration Guide]]
- [[vault-migration-analysis-task|Example Migration Task]]
- [[registry/skills.yaml|Skill Registry]]
