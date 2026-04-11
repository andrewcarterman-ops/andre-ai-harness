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
$rule = New-Object ...
# ... viel Code ...
$acl.RemoveAccessRule($rule)  # $rule existiert hier möglicherweise nicht!

# KORREKT:
$script:rule = New-Object ...  # oder
$global:rule = New-Object ...  # oder einfach Scope beachten
```

**Lösung:**
- Variablen im richtigen Scope definieren
- Am Anfang des Skripts alle Variablen deklarieren
- `$script:Variable` für Script-Scope verwenden

---

### 3. ACL/IdentityNotMappedException

**Problem:**
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

**Alternative (sicherer):**
```powershell
# Aktuellen User verwenden:
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Oder SID-basiert (sprachunabhängig):
$adminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$adminUser = $adminSID.Translate([System.Security.Principal.NTAccount]).Value
```

---

### 4. Emoji/Unicode-Probleme in Windows

**Problem:**
```powershell
# FALSCH:
Write-Host "✅ Erfolgreich!"
#        ^^^^ Funktioniert nicht auf allen Windows-Systemen!

# KORREKT:
Write-Host "[OK] Erfolgreich!"
#        ^^^^^^ Reines ASCII
```

**Lösung:**
- Keine Unicode-Zeichen (Emojis, Sonderzeichen) in PS-Skripten
- ASCII-only für maximale Kompatibilität
- Oder explizite Encoding-Angabe: `Write-Host "..." -Encoding UTF8`

---

### 5. Verzeichnis-Berechtigungen (Chicken-Egg-Problem)

**Problem:**
1. Verzeichnis mit Berechtigungen für User A erstellen
2. User B (Admin) kann nicht mehr schreiben
3. Berechtigungen ändern geht nicht, weil kein Zugriff

**Lösung - Immer in dieser Reihenfolge:**
```powershell
# 1. Erstellen als Admin
New-Item -Path $Path -ItemType Directory

# 2. Eigentum übernehmen
takeown /F $Path /R

# 3. Berechtigungen setzen (VOR dem Kopieren)
icacls $Path /grant "$env:USERNAME:(OI)(CI)F"

# 4. Dateien kopieren
copy ...

# 5. Erst DANN finale Berechtigungen setzen
icacls $Path /grant "TargetUser:(OI)(CI)F"
icacls $Path /remove "$env:USERNAME"
```

---

### 6. PolicyAppId / Firewall-Regeln

**Problem:**
```powershell
# FALSCH:
New-NetFirewallRule -LocalUser $UserName ...
#                    ^^^^^^^^^^^^^^^^^^^^ IdentityNotMappedException

# KORREKT:
# User existiert, aber Firewall kann SID nicht auflösen
# Lösung: Ohne -LocalUser arbeiten, stattdessen:
New-NetFirewallRule -DisplayName "Block-Outbound" -Direction Outbound -Action Block
# Dann im Guardian Netzwerk-Verbindungen prüfen
```

**Alternative:**
- Firewall global konfigurieren (nicht user-spezifisch)
- Oder: Windows Firewall komplett umgehen, stattdessen im Guardian überwachen

---

## ✅ Best Practices für zukünftige PS-Skripte

### 1. Variablen-Namenskonventionen
```powershell
# Prefixe verwenden:
$cfgUserName      # Config-Variable
$tmpFilePath      # Temporär
$strInput         # String
$arrHosts         # Array
$hashtableConfig  # Hashtable
$boolIsAdmin      # Boolean
```

### 2. Fehlerbehandlung
```powershell
try {
    $acl.SetAccessRule($rule)
} catch [System.Security.Principal.IdentityNotMappedException] {
    Write-Warning "User nicht gefunden, versuche SID..."
    # Fallback-Logik
} catch {
    Write-Error "Unbekannter Fehler: $_"
    exit 1
}
```

### 3. Verbose Output
```powershell
[CmdletBinding()]
param()

Write-Verbose "Starte Setup..."
Write-Verbose "User: $UserName"
Write-Verbose "Path: $BasePath"
```

### 4. Test-Mode
```powershell
param([switch]$WhatIf)

if ($WhatIf) {
    Write-Host "Was würde passieren:"
    Write-Host "  - Verzeichnis: $BasePath"
    Write-Host "  - User: $UserName"
    return
}
```

### 5. ASCII-Only Output
```powershell
# Statt:
Write-Host "✅ Success"

# Besser:
Write-Host "[OK] Success"
Write-Host "[WARN] Warning"
Write-Host "[ERR] Error"
Write-Host "[INFO] Info"
```

---

## 🔧 Verbesserte Skript-Struktur (Template)

```powershell
#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Kurze Beschreibung
.DESCRIPTION
    Lange Beschreibung
.PARAMETER ParamName
    Parameter-Beschreibung
.EXAMPLE
    .\Script.ps1 -ParamName Value
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$UserName = "defaultuser",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Konfiguration am Anfang
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

$script:Config = @{
    BasePath = "C:\Example"
    UserName = $UserName
}

# Funktionen definieren
function Test-Prerequisites {
    # ...
}

function Initialize-Directory {
    # ...
}

# Hauptlogik
try {
    Test-Prerequisites
    Initialize-Directory
    # ...
    Write-Host "[OK] Complete" -ForegroundColor Green
} catch {
    Write-Host "[ERR] $_" -ForegroundColor Red
    exit 1
}
```

---

## 📊 Bewertung: Was funktionierte / Was nicht

| Aspekt | Bewertung | Kommentar |
|--------|-----------|-----------|
| Skript-Struktur | ⭐⭐⭐ | Gut, aber zu komplex |
| Fehlerbehandlung | ⭐⭐ | Unzureichend für ACL-Fehler |
| Unicode/Encoding | ⭐ | Emojis verursachten Probleme |
| Berechtigungen | ⭐ | Chicken-Egg-Problem nicht gelöst |
| Dokumentation | ⭐⭐⭐⭐ | Gut kommentiert |

---

## 🎯 Empfehlungen für zukünftige Projekte

### Sofort umsetzen:
1. ✅ Keine Emojis in PS-Skripten
2. ✅ Keine reservierten Wörter als Variablen
3. ✅ Fehlerbehandlung für ACL-Operationen
4. ✅ Test-Mode (-WhatIf) implementieren

### Bei komplexen Berechtigungen:
1. 📋 Manuelle Schritte dokumentieren statt automatisieren
2. 📋 Mehrere kleine Skripte statt eines großen
3. 📋 Berechtigungen separat, Installation separat

### Testing:
1. 🧪 In frischer VM testen
2. 🧪 Auf deutschem UND englischem Windows testen
3. 🧪 Mit `-WhatIf` trocken laufen

---

## 📚 Referenzen

- PowerShell Reserved Words: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_reserved_words
- ACL Best Practices: https://docs.microsoft.com/en-us/windows/win32/secauthz/access-control-lists
- PowerShell Error Handling: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally

---

## 📝 Changelog

| Version | Datum | Änderung |
|---------|-------|----------|
| 1.0 | 2026-03-31 | Initial erstellt nach Fort Knox Setup Erfahrung |

---

**Nächster Schritt:** Diese Learnings in ein **PS-Skript-Template** umsetzen für zukünftige Projekte!
