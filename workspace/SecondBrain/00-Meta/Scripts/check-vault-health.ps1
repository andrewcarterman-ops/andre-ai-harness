<#
.SYNOPSIS
    Ueberprueft die Gesundheit des SecondBrain Vaults.

.DESCRIPTION
    Dieses Skript prueft:
    - Symlinks auf Integritaet
    - Pfad-Konfigurationen
    - Fehlende externe Ressourcen

.EXAMPLE
    .\check-vault-health.ps1
    Fuehrt einen vollstaendigen Health-Check durch.

.EXAMPLE
    .\check-vault-health.ps1 -Fix
    Versucht automatisch Probleme zu beheben.

.NOTES
    Muss nicht als Administrator ausgefuehrt werden (nur lesend).

.LINK
    Dokumentation: ../vault-config.md
#>

[CmdletBinding()]
param(
    [switch]$Fix
)

$ErrorActionPreference = "Continue"

$scriptPath = $PSScriptRoot
$vaultPath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$workspacePath = Split-Path -Parent $vaultPath

$issues = @()
$warnings = @()
$healthy = @()

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Blue
    Write-Host "  $Text" -ForegroundColor Blue
    Write-Host "============================================================" -ForegroundColor Blue
}

function Test-SymlinkHealth {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return @{ Status = "Missing"; Details = "Existiert nicht" }
    }
    
    $item = Get-Item $Path -ErrorAction SilentlyContinue
    if (-not ($item.Attributes -match "ReparsePoint")) {
        return @{ Status = "NotSymlink"; Details = "Ist kein Symlink (echter Ordner/Datei)" }
    }
    
    if (-not (Test-Path $item.Target)) {
        return @{ Status = "Broken"; Details = "Ziel existiert nicht: $($item.Target)" }
    }
    
    return @{ Status = "Healthy"; Details = "-> $($item.Target)" }
}

# Hauptlogik
Write-Header "SecondBrain Vault Health Check"

Write-Host ""
Write-Host "Pfade:"
Write-Host "   Vault:    $vaultPath"
Write-Host "   Workspace: $workspacePath"
Write-Host ""

# Symlinks pruefen
Write-Header "Pruefe Symlinks"

$expectedSymlinks = @(
    @{ Name = "skills"; ExpectedTarget = Join-Path $workspacePath "skills" }
)

foreach ($expected in $expectedSymlinks) {
    $linkPath = Join-Path $vaultPath $expected.Name
    $health = Test-SymlinkHealth -Path $linkPath
    
    switch ($health.Status) {
        "Healthy" {
            Write-Host "OK $($expected.Name) - Gesund" -ForegroundColor Green
            Write-Host "   $($health.Details)" -ForegroundColor Gray
            $healthy += $expected.Name
        }
        "Missing" {
            Write-Host "X $($expected.Name) - Fehlt" -ForegroundColor Red
            Write-Host "   Erwartet: $($expected.ExpectedTarget)" -ForegroundColor Gray
            $issues += @{
                Type = "Symlink"
                Name = $expected.Name
                Severity = "Error"
                FixCommand = ".\00-Meta\Scripts\setup-symlinks.ps1"
            }
        }
        "NotSymlink" {
            Write-Host "! $($expected.Name) - Ist kein Symlink" -ForegroundColor Yellow
            Write-Host "   $($health.Details)" -ForegroundColor Gray
            $warnings += @{
                Type = "Symlink"
                Name = $expected.Name
                Severity = "Warning"
                Message = "Ein echter Ordner existiert - Symlink kann nicht erstellt werden"
            }
        }
        "Broken" {
            Write-Host "X $($expected.Name) - BROKEN" -ForegroundColor Red
            Write-Host "   $($health.Details)" -ForegroundColor Gray
            $issues += @{
                Type = "Symlink"
                Name = $expected.Name
                Severity = "Error"
                FixCommand = ".\00-Meta\Scripts\setup-symlinks.ps1"
            }
        }
    }
}

# Externe Ressourcen pruefen
Write-Header "Pruefe externe Ressourcen"

$externalResources = @(
    @{ Path = Join-Path $workspacePath "skills"; Name = "OpenClaw Skills"; Required = $true }
    @{ Path = Join-Path $workspacePath "docs"; Name = "OpenClaw Docs"; Required = $false }
)

foreach ($resource in $externalResources) {
    if (Test-Path $resource.Path) {
        $count = (Get-ChildItem $resource.Path -Directory).Count
        Write-Host "OK $($resource.Name) - Verfuegbar ($count Ordner)" -ForegroundColor Green
    } else {
        if ($resource.Required) {
            Write-Host "X $($resource.Name) - NICHT GEFUNDEN" -ForegroundColor Red
            Write-Host "   Erwartet: $($resource.Path)" -ForegroundColor Gray
            $issues += @{
                Type = "External"
                Name = $resource.Name
                Severity = "Error"
            }
        } else {
            Write-Host "~ $($resource.Name) - Nicht gefunden (optional)" -ForegroundColor Gray
        }
    }
}

# Vault-Struktur pruefen
Write-Header "Pruefe Vault-Struktur"

$expectedFolders = @("00-Meta", "01-Daily", "02-Projects", "03-Knowledge", "04-Decisions")

foreach ($folder in $expectedFolders) {
    $folderPath = Join-Path $vaultPath $folder
    if (Test-Path $folderPath) {
        Write-Host "OK $folder - OK" -ForegroundColor Green
    } else {
        Write-Host "! $folder - Fehlt" -ForegroundColor Yellow
        $warnings += @{
            Type = "Structure"
            Name = $folder
            Severity = "Warning"
            Message = "Erwarteter Ordner nicht vorhanden"
        }
    }
}

# Zusammenfassung
Write-Header "Zusammenfassung"

Write-Host ""
Write-Host "Status:" -ForegroundColor Cyan
Write-Host "   OK:        $($healthy.Count)" -ForegroundColor Green
Write-Host "   Warnungen: $($warnings.Count)" -ForegroundColor Yellow
Write-Host "   Probleme:  $($issues.Count)" -ForegroundColor Red
Write-Host ""

if ($issues.Count -gt 0) {
    Write-Host "Probleme die behoben werden muessen:" -ForegroundColor Red
    Write-Host ""
    foreach ($issue in $issues) {
        Write-Host "   X [$($issue.Type)] $($issue.Name)" -ForegroundColor Red
        if ($issue.FixCommand) {
            Write-Host "      -> Behebung: $($issue.FixCommand)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-Host "Warnungen (optional):" -ForegroundColor Yellow
    Write-Host ""
    foreach ($warning in $warnings) {
        Write-Host "   ! [$($warning.Type)] $($warning.Name)" -ForegroundColor Yellow
        Write-Host "      -> $($warning.Message)" -ForegroundColor Gray
    }
    Write-Host ""
}

# Automatische Behebung
if ($Fix -and $issues.Count -gt 0) {
    Write-Host "Versuche automatische Behebung..." -ForegroundColor Cyan
    Write-Host ""
    
    $symlinkIssues = $issues | Where-Object { $_.Type -eq "Symlink" }
    if ($symlinkIssues.Count -gt 0) {
        Write-Host "Rufe setup-symlinks.ps1 auf..." -ForegroundColor Yellow
        $setupScript = Join-Path $scriptPath "setup-symlinks.ps1"
        if (Test-Path $setupScript) {
            & $setupScript
        } else {
            Write-Host "   FEHLER: setup-symlinks.ps1 nicht gefunden" -ForegroundColor Red
        }
    }
}

Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "Vault ist vollstaendig gesund!" -ForegroundColor Green
    exit 0
} elseif ($issues.Count -eq 0) {
    Write-Host "Keine kritischen Probleme, nur Warnungen." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Es gibt Probleme die behoben werden sollten." -ForegroundColor Yellow
    Write-Host "   Siehe Details oben oder fuehre mit -Fix aus." -ForegroundColor Gray
    exit 1
}
