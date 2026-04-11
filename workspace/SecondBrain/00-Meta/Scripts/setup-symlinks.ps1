<#
.SYNOPSIS
    Richtet Symlinks fuer externe Ressourcen im SecondBrain Vault ein.

.DESCRIPTION
    Dieses Skript erstellt symbolische Links (Symlinks) zu externen Ordnern
    (z.B. OpenClaw Skills), damit diese im Obsidian Vault verfuegbar sind.

.PARAMETER None
    Das Skript ermittelt Pfade automatisch relativ zur eigenen Position.

.EXAMPLE
    .\setup-symlinks.ps1
    Erstellt alle konfigurierten Symlinks.

.NOTES
    - Muss als Administrator ausgefuehrt werden
    - Obsidian muss nach Ausfuehrung neu gestartet werden
    - Bei Vault-Verschiebung muss das Skript neu ausgefuehrt werden

.LINK
    Dokumentation: ../vault-config.md
#>

[CmdletBinding()]
param()

# Fehleraktion: Bei Problemen sofort stoppen
$ErrorActionPreference = "Stop"

# Konfiguration
$scriptPath = $PSScriptRoot
$vaultPath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$workspacePath = Split-Path -Parent $vaultPath

# Zu erstellende Symlinks
$symlinks = @(
    @{
        Name = "skills"
        Source = Join-Path $workspacePath "skills"
        Description = "OpenClaw Skills"
    }
)

# Funktionen
function Test-AdminRights {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-SymlinkExists {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    $item = Get-Item $Path -ErrorAction SilentlyContinue
    if (-not $item) {
        return $false
    }
    return $item.Attributes -match "ReparsePoint"
}

function Test-SymlinkHealthy {
    param([string]$Path)
    
    if (-not (Test-SymlinkExists -Path $Path)) {
        return $false
    }
    
    $item = Get-Item $Path -ErrorAction SilentlyContinue
    if (-not $item) {
        return $false
    }
    
    # Pruefe ob Ziel existiert
    if ([string]::IsNullOrEmpty($item.Target)) {
        return $false
    }
    
    return Test-Path $item.Target
}

function New-VaultSymlink {
    param(
        [string]$Name,
        [string]$Source,
        [string]$VaultPath
    )
    
    $linkPath = Join-Path $VaultPath $Name
    
    Write-Host ""
    Write-Host "Verarbeite: $Name" -ForegroundColor Cyan
    Write-Host "   Quelle: $Source"
    Write-Host "   Ziel:   $linkPath"
    
    # Pruefe ob Quelle existiert
    if (-not (Test-Path $Source)) {
        Write-Host "   FEHLER: Quelle existiert nicht - ueberspringe" -ForegroundColor Red
        return @{ Success = $false; Status = "SourceMissing" }
    }
    
    # Pruefe ob bereits ein gesunder Symlink existiert
    if (Test-SymlinkExists -Path $linkPath) {
        if (Test-SymlinkHealthy -Path $linkPath) {
            $item = Get-Item $linkPath
            Write-Host "   OK: Bereits vorhanden und gesund" -ForegroundColor Green
            Write-Host "      -> $($item.Target)"
            return @{ Success = $true; Status = "AlreadyExists"; Action = "None" }
        } else {
            Write-Host "   WARNUNG: BROKEN Symlink gefunden - entferne..." -ForegroundColor Yellow
            try {
                Remove-Item -Path $linkPath -Force
                Write-Host "   OK: Broken Symlink entfernt" -ForegroundColor Green
                # Weiter zum Erstellen
            } catch {
                Write-Host "   FEHLER: Konnte broken Symlink nicht entfernen: $_" -ForegroundColor Red
                return @{ Success = $false; Status = "RemoveFailed" }
            }
        }
    } elseif (Test-Path $linkPath) {
        # Echter Ordner/Datei mit gleichem Namen
        Write-Host "   FEHLER: Konflikt - Es existiert bereits ein Ordner/Datei mit diesem Namen" -ForegroundColor Red
        return @{ Success = $false; Status = "Conflict" }
    }
    
    # Erstelle Symlink (entweder neu oder nach Entfernen eines broken links)
    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $Source | Out-Null
        Write-Host "   OK: Symlink erstellt" -ForegroundColor Green
        return @{ Success = $true; Status = "Created"; Action = "Created" }
    } catch {
        Write-Host "   FEHLER: $_" -ForegroundColor Red
        return @{ Success = $false; Status = "CreateFailed" }
    }
}

# Hauptlogik
Write-Host ""
Write-Host "============================================================" -ForegroundColor Blue
Write-Host "  SecondBrain Vault Symlink Setup" -ForegroundColor Blue
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

# Admin-Rechte pruefen
if (-not (Test-AdminRights)) {
    Write-Host "FEHLER: Dieses Skript muss als Administrator ausgefuehrt werden!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Bitte:" -ForegroundColor Yellow
    Write-Host "   1. PowerShell schliessen"
    Write-Host "   2. Rechtsklick auf PowerShell -> 'Als Administrator ausfuehren'"
    Write-Host "   3. Skript erneut starten"
    Write-Host ""
    exit 1
}

Write-Host "OK: Admin-Rechte bestaetigt"
Write-Host ""
Write-Host "Konfiguration:"
Write-Host "   Vault-Pfad:    $vaultPath"
Write-Host "   Workspace:     $workspacePath"
Write-Host "   Zu verlinken:  $($symlinks.Count) Ordner"
Write-Host ""

# Ergebnisse tracken
$results = @()

# Jedes Symlink erstellen
foreach ($symlink in $symlinks) {
    $result = New-VaultSymlink `
        -Name $symlink.Name `
        -Source $symlink.Source `
        -VaultPath $vaultPath
    
    $results += [PSCustomObject]@{
        Name = $symlink.Name
        Success = $result.Success
        Status = $result.Status
        Action = $result.Action
        Description = $symlink.Description
    }
}

# Zusammenfassung
$successful = @($results | Where-Object { $_.Success -eq $true })
$failed = @($results | Where-Object { $_.Success -eq $false })
$created = @($results | Where-Object { $_.Action -eq "Created" })
$existing = @($results | Where-Object { $_.Action -eq "None" })

Write-Host ""
Write-Host "============================================================" -ForegroundColor Blue
Write-Host "  Zusammenfassung" -ForegroundColor Blue
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

Write-Host "Gesamt: $($results.Count)" -ForegroundColor Cyan
Write-Host "   OK: $($successful.Count)" -ForegroundColor Green
if ($created.Count -gt 0) {
    Write-Host "      Neu erstellt: $($created.Count)" -ForegroundColor Green
}
if ($existing.Count -gt 0) {
    Write-Host "      Bereits vorhanden: $($existing.Count)" -ForegroundColor Green
}

if ($failed.Count -gt 0) {
    Write-Host "   Fehler: $($failed.Count)" -ForegroundColor Red
    foreach ($fail in $failed) {
        Write-Host "      X $($fail.Name) - $($fail.Description) [$($fail.Status)]" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

# Erfolgspruefung
if ($successful.Count -eq $results.Count -and $results.Count -gt 0) {
    if ($created.Count -eq $results.Count) {
        Write-Host "Alle Symlinks erfolgreich erstellt!" -ForegroundColor Green
    } elseif ($existing.Count -eq $results.Count) {
        Write-Host "Alle Symlinks bereits vorhanden und gesund!" -ForegroundColor Green
    } else {
        Write-Host "Alle Symlinks OK (Teilweise neu erstellt, teilweise vorhanden)!" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Naechste Schritte:" -ForegroundColor Yellow
    Write-Host "   1. Obsidian neu starten (damit Aenderungen erkannt werden)"
    Write-Host "   2. Im Vault: Du solltest jetzt einen 'skills' Ordner sehen"
    Write-Host "   3. WikiLinks testen: [[skills/security-review/SKILL]]"
    Write-Host ""
    Write-Host "   Tipp: Fuehre regelmaessig check-vault-health.ps1 aus"
    exit 0
} elseif ($results.Count -eq 0) {
    Write-Host "WARNUNG: Keine Symlinks zu erstellen (Liste war leer)" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "FEHLER: Einige Symlinks konnten nicht erstellt werden ($($failed.Count) von $($results.Count))." -ForegroundColor Red
    exit 1
}
