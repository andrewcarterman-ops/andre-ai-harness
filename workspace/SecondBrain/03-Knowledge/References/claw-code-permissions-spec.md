---
date: 06-04-2026
type: reference
status: active
tags: [claw-code, permissions, security, safety, risk-analysis]
source: vault-archive/Main_Obsidian_Vault/Kimi_Agent_OpenClaw GitHub/
topics: [permissions, security, risk-scoring, audit-logging]
projects: [openclaw-renovation]
tier: 1
priority: high
---

# Claw-Code: Permissions Specification

> Risk-basiertes Permission-System mit 3-Stufen: Allow / Deny / Prompt.
> **Original:** SUBAGENT_PERMISSIONS_SPEC.md (10 KB)

---

## PermissionMode

```rust
pub enum PermissionMode {
    Allow,   // Execute without prompting
    Deny,    // Always reject
    Prompt,  // Ask user for confirmation
}
```

## Risk-Scoring

### Tool Basis-Risiken
| Tool | Risiko |
|------|--------|
| read, glob, grep | Low |
| write, edit, web_fetch | Medium |
| bash | High |

### Argument-Analyse
| Pattern | Risiko |
|---------|--------|
| `rm -rf` | Critical |
| `git push` | High |
| `.env` Zugriff | Critical |
| `.key` Dateien | High |

### Auto-Entscheidungen
- **Low Risk** + Non-Interactive → Auto-Allow
- **Critical Risk** → Auto-Deny
- **Medium/High** → Prompt User

---

## Audit-Logging

Alle Permission-Events werden protokolliert:
- Allowed (mit Risk Score)
- Denied (mit Grund)
- Prompted (mit User Response)

---

## Integration: Security Review

**Ziel:** `skills/security-review/permissions.rs`

Verstärkt bestehenden Security Review Skill mit:
- Granularem Permission System
- Risk-basierter Analyse
- Audit-Logging

---

## Nutzen für OpenClaw

| Feature | Vorteil |
|---------|---------|
| 3-Stufen System | Flexible Kontrolle |
| Risk-Scoring | Kontext-sensitive Entscheidungen |
| Auto-Allow/Deny | Effizienz bei klaren Fällen |
| Audit-Log | Compliance, Debugging |

---

## Verwandte Dokumente

- [[claw-code-masterplan|MASTERPLAN]] → Überblick
- [[claw-code-runtime-spec|RUNTIME]] → SafetyGuard Integration
- [[openclaw-renovation|Renovierung]] → Phase 4: Security

---

*Kuratierte Version. Vollständige Implementierung im Original.*