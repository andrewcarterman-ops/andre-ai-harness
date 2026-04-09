---
date: 2026-04-08
time: 01:25
type: session
title: Session 2026-03-31-learning-report-powershell
category: project
tags:
  - autoresearch
  - bug
  - ai
  - ecc
  - coding
  - project
  - session
related_notes:
  - 📝 [[2026-03-31-learning-report-powershell]] (80 gemeinsame Begriffe: learning, report, powershell)
  - 📦 [[EXAMPLE_dec_001]] (18 gemeinsame Begriffe: powershell, projekt, für)
  - 📦 [[3.0 openclaw-schritt-fuer-schritt-anleitung]] (21 gemeinsame Begriffe: powershell, bei, der)
related_count: 5
session_id: 2026-04-08-0125
agent: andrew-main
user: parzival
status: active
source_file: 2026-03-31-learning-report-powershell.md
decisions: none
todos: none
code_blocks: 13
---

# Session 2026-03-31-learning-report-powershell

## Zusammenfassung
**Datum:** 2026-03-31  
**Projekt:** ECC Autoresearch Fort Knox Setup  
**Autor:** Andrew (AI Assistant) + Parzival (User)

## Code-Blöcke

### powershell
```powershell
# FALSCH:
foreach ($host in $allowedHosts) { ... }
#            ^^^^ $host ist RESERVED!

# KORREKT:
foreach ($hostname in $allowedHosts) { ... }
#            ^^^^^^^^ Beliebiger Name
```

### powershell
```powershell
# FALSCH:
$rule = New-Object ...
# ... viel Code ...
$acl.RemoveAccessRule($rule)  # $rule existiert hier möglicherweise nicht!

# KORREKT:
$script:rule = New-Object ...  # oder
$global:rule = New-Object ...  # oder einfach Scope beachten
```

### powershell
```powershell
# FALSCH:
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrators",  # Funktioniert nicht auf deutschen Systemen!
    ...
)

# KORREKT:
$adminSID = New-Object System.Security.Principal.SecurityIdentifier(
    "S-1-5-32-544"  # Well-known SID für Administrators
)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $adminSID, ...
)
```

### powershell
```powershell
# Aktuellen User verwenden:
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Oder SID-basiert (sprachunabhängig):
$adminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$adminUser = $adminSID.Translate([System.Security.Principal.NTAccount]).Value
```

### powershell
```powershell
# FALSCH:
Write-Host "✅ Erfolgreich!"
#        ^^^^ Funktioniert nicht auf allen Windows-Systemen!

# KORREKT:
Write-Host "[OK] Erfolgreich!"
#        ^^^^^^ Reines ASCII
```

---

## Original

```
# Learning Report: PowerShell Skript-Generierung

**Datum:** 2026-03-31  
**Projekt:** ECC Autoresearch Fort Knox Setup  
**Autor:** Andrew (AI Assistant) + Parzival (User)  

---

## 🎯 Zusammenfassung

Bei der Erstellung mehrerer PowerShell-Skripte für das Fort Knox Setup traten wiederkehrende Fehler auf, die systematisch vermieden werden können.

---

## ❌ Identifizierte Fehler

### 1. Reservierte Wörter als Variablennamen

**Problem:**
```powershell
# FALSCH:
foreach ($host in $allowedHosts) { ... }
#            ^^^^ $host ist RESERVED!

# KORREKT:
foreach ($hostname in $allowedHosts) { ... }
#            ^^^^^^^^ Beliebiger Name
```

**Reserved Words in PowerShell:**
- `$host` → Host-Objekt (Konsole)
- `$input` → Pipeline-Input
- `$null` → Null-Wert
- `$true` / `$false` → Booleans
- `$pwd` → Aktuelles Verzeichnis
- `$PSVersionTable` → Version-Info

**Regel:** Nie reservierte Wörter als Variablen verwenden!

---

### 2. Undefinierte Variablen

**Problem:**
```powershell
# FALSCH:
$
... (truncated)
```