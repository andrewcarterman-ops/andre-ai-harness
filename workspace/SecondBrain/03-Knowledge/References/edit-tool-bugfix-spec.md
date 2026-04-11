---
date: 11-04-2026
time: 03:45
type: technical-spec
status: pending
priority: critical
tags: [bugfix, gateway, core, edit-tool, rust]
---

# BUGFIX SPEC: Edit-Tool Parameter Validation

## Problem
Das `edit` Tool im OpenClaw Gateway validiert Parameter inkorrekt.

**Fehlermeldung:**
```
[tools] edit failed: Missing required parameters: 
  oldText (oldText or old_string), 
  newText (newText or new_string)
```

## Root Cause

**Location:** OpenClaw Gateway Core (Rust)  
**File:** Vermutlich `src/tools/edit_file.rs` oder ähnlich  
**Issue:** Parameter-Validierung akzeptiert weder camelCase noch snake_case korrekt.

## Analyse

### Aktuelles Verhalten (FEHLERHAFT)
```rust
// Pseudocode der aktuellen Implementation
fn validate_edit_params(params: &Value) -> Result<()> {
    // Versucht beide Varianten zu validieren, aber logisch falsch
    if !params.has("oldText") && !params.has("old_string") {
        return Err("Missing oldText (oldText or old_string)");
    }
    // Aber: Es wird nicht normalisiert!
    // Die eigentliche Verarbeitung erwartet nur eine Variante
}
```

### Gewünschtes Verhalten
```rust
// Korrekte Implementation
fn normalize_and_validate(params: &mut Value) -> Result<()> {
    // 1. Normalisierung: Beide Varianten akzeptieren
    let old_text = params.get("oldText")
        .or_else(|| params.get("old_string"))
        .ok_or("Missing old_text parameter")?;
    
    let new_text = params.get("newText")
        .or_else(|| params.get("new_string"))
        .ok_or("Missing new_text parameter")?;
    
    // 2. Intern nur eine Variante verwenden
    params["old_string"] = old_text;
    params["new_string"] = new_text;
    
    // 3. Optional: Deprecation Warning für camelCase
    if params.has("oldText") {
        log::warn!("oldText is deprecated, use old_string");
    }
    
    Ok(())
}
```

## Fix-Optionen

### Option A: Normalisierung (Empfohlen)
**Aufwand:** Klein  
**Risiko:** Minimal  
**Implementation:**
- Akzeptiere beide Varianten
- Konvertiere zu canonical (snake_case)
- Führe Operation aus

### Option B: Schema-Update
**Aufwand:** Mittel  
**Risiko:** Mittel  
**Implementation:**
- Ändere Tool-Schema zu nur einer Variante
- Update alle bestehenden Aufrufe
- Breaking Change!

### Option C: Alias-System
**Aufwand:** Mittel  
**Risiko:** Niedrig  
**Implementation:**
- Definiere Parameter-Aliase im Schema
- "oldText" → Alias für "old_string"
- Keine Code-Änderung nötig, nur Config

## Temporärer Workaround (AKTIV)

Bis der Core-Fix implementiert ist:

```powershell
# Statt:
edit file.txt old_string: "x" new_string: "y"

# Nutze:
Import-Module SafeEdit.psm1
Edit-FileSafe -Path "file.txt" -OldString "x" -NewString "y"
```

**Modul:** `00-Meta/Scripts/SafeEdit.psm1`

## Implementierungs-Checklist

- [ ] Gateway-Code lokalisieren (edit_file.rs)
- [ ] Parameter-Normalisierung implementieren
- [ ] Tests schreiben (beide Varianten)
- [ ] Integrationstest
- [ ] Dokumentation aktualisieren
- [ ] Deprecation-Warnung hinzufügen

## Verwandte Dokumente

- [[openclaw-edit-bug-analysis|Root-Cause Analysis]]
- [[INCIDENT-2026-04-11-edit-tool-error|Live Incident]]
- [[openclaw-action-checklist|Action Checklist P1-1]]

---

**Status:** Warte auf Gateway-Core Update  
**Workaround:** SafeEdit.psm1 aktiv