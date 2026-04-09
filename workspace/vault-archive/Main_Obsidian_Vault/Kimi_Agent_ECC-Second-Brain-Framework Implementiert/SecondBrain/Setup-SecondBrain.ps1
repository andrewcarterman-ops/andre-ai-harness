#Requires -Version 5.1
<#
.SYNOPSIS
    Setup-Skript für das ECC Second Brain Framework

.DESCRIPTION
    Installiert und konfiguriert das ECC Second Brain Framework mit Obsidian-Integration.
    Erstellt Ordnerstruktur, konfiguriert Plugins und validiert die Installation.

.PARAMETER VaultPath
    Pfad zum Obsidian Vault. Default: C:\Users\andre\Documents\Andrew Openclaw\SecondBrain

.PARAMETER SkipValidation
    Überspringt die abschließende Validierung

.PARAMETER Force
    Überschreibt existierende Dateien

.EXAMPLE
    .\Setup-SecondBrain.ps1
    Führt das Standard-Setup durch

.EXAMPLE
    .\Setup-SecondBrain.ps1 -VaultPath "D:\MeinVault" -Force
    Installiert in benutzerdefinierten Pfad mit Überschreiben

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    ECC Framework: Second Brain Integration
#>

[CmdletBinding()]
param(
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    [switch]$SkipValidation,
    [switch]$Force
)

# Error Action Preference
$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Script Variables
$script:Version = "1.0.0"
$script:StartTime = Get-Date
$script:LogFile = Join-Path $VaultPath ".logs" "setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

#region Logging Functions

function Write-SetupLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Console Output with Colors
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG"   { Write-Host $logEntry -ForegroundColor Gray }
    }
    
    # File Logging
    $logDir = Split-Path $script:LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $script:LogFile -Value $logEntry
}

#endregion

#region Setup Functions

function Initialize-VaultStructure {
    Write-SetupLog "Initialisiere Vault-Struktur..." -Level "INFO"
    
    $folders = @(
        "00-Inbox",
        "01-Projects",
        "02-Areas",
        "03-Resources\Skills",
        "03-Resources\Patterns",
        "03-Resources\Snippets",
        "04-Archive",
        "05-Daily",
        "scripts\lib",
        "config",
        ".logs",
        ".backups",
        ".obsidian\plugins\ecc-vault",
        ".obsidian\snippets",
        ".obsidian\templates",
        "00-Dashboard",
        "05-Templates"
    )
    
    foreach ($folder in $folders) {
        $fullPath = Join-Path $VaultPath $folder
        if (!(Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-SetupLog "  Erstellt: $folder" -Level "DEBUG"
        }
    }
    
    Write-SetupLog "Vault-Struktur initialisiert" -Level "SUCCESS"
}

function Install-PowerShellModules {
    Write-SetupLog "Installiere PowerShell-Module..." -Level "INFO"
    
    $modules = @(
        @{ Name = "ErrorHandler"; Path = "scripts\lib\ErrorHandler.psm1" },
        @{ Name = "Logging"; Path = "scripts\lib\Logging.psm1" },
        @{ Name = "MermaidGenerator"; Path = "scripts\lib\MermaidGenerator.psm1" },
        @{ Name = "DataviewQuery"; Path = "scripts\lib\DataviewQuery.psm1" },
        @{ Name = "Encryption"; Path = "scripts\lib\Encryption.psm1" }
    )
    
    foreach ($module in $modules) {
        $modulePath = Join-Path $VaultPath $module.Path
        if (Test-Path $modulePath) {
            try {
                Import-Module $modulePath -Force -ErrorAction Stop
                Write-SetupLog "  Geladen: $($module.Name)" -Level "DEBUG"
            }
            catch {
                Write-SetupLog "  Fehler beim Laden: $($module.Name) - $_" -Level "WARN"
            }
        }
    }
    
    Write-SetupLog "PowerShell-Module installiert" -Level "SUCCESS"
}

function Initialize-ObsidianConfig {
    Write-SetupLog "Konfiguriere Obsidian..." -Level "INFO"
    
    # Check if Obsidian config exists
    $obsidianDir = Join-Path $VaultPath ".obsidian"
    
    if (!(Test-Path $obsidianDir)) {
        New-Item -ItemType Directory -Path $obsidianDir -Force | Out-Null
    }
    
    # Enable CSS Snippet
    $appearanceFile = Join-Path $obsidianDir "appearance.json"
    $appearance = @{
        accentColor = "#6366f1"
        cssTheme = ""
        enabledCssSnippets = @("ecc-second-brain")
        interfaceFontFamily = ""
        monospaceFontFamily = ""
        nativeMenus = $false
        showViewHeader = $true
        textFontFamily = ""
        theme = "obsidian"
        translucency = $false
    }
    
    $appearance | ConvertTo-Json -Depth 10 | Set-Content $appearanceFile -Encoding UTF8
    
    Write-SetupLog "Obsidian konfiguriert" -Level "SUCCESS"
}

function Initialize-NodeJS {
    Write-SetupLog "Prüfe Node.js..." -Level "INFO"
    
    $nodeVersion = $null
    try {
        $nodeVersion = node --version 2>$null
    }
    catch {
        Write-SetupLog "Node.js nicht gefunden" -Level "WARN"
    }
    
    if ($nodeVersion) {
        Write-SetupLog "Node.js gefunden: $nodeVersion" -Level "DEBUG"
        
        $packageJsonPath = Join-Path $VaultPath "package.json"
        if (Test-Path $packageJsonPath) {
            Write-SetupLog "Installiere Node-Dependencies..." -Level "INFO"
            Push-Location $VaultPath
            try {
                npm install 2>&1 | ForEach-Object { Write-SetupLog "  $_" -Level "DEBUG" }
                Write-SetupLog "Node-Dependencies installiert" -Level "SUCCESS"
            }
            catch {
                Write-SetupLog "Fehler bei npm install: $_" -Level "WARN"
            }
            finally {
                Pop-Location
            }
        }
    }
    else {
        Write-SetupLog "Node.js nicht installiert - Logging-Features eingeschränkt" -Level "WARN"
        Write-SetupLog "Download: https://nodejs.org/" -Level "INFO"
    }
}

function Initialize-Encryption {
    Write-SetupLog "Initialisiere Verschlüsselung..." -Level "INFO"
    
    $secureKeysPath = Join-Path $VaultPath ".obsidian\plugins\ecc-vault\secure-keys.json"
    
    if (!(Test-Path $secureKeysPath) -or $Force) {
        $secureKeysTemplate = @{
            version = "1.0"
            lastUpdated = (Get-Date -Format "o")
            keys = @{}
            metadata = @{
                encryption = "AES-256-GCM"
                keyDerivation = "PBKDF2"
            }
        }
        
        $secureKeysTemplate | ConvertTo-Json -Depth 10 | Set-Content $secureKeysPath -Encoding UTF8
        Write-SetupLog "Verschlüsselungs-Template erstellt" -Level "SUCCESS"
    }
}

function Invoke-Validation {
    Write-SetupLog "Führe Validierung durch..." -Level "INFO"
    
    $checks = @(
        @{ Name = "Vault-Verzeichnis"; Test = { Test-Path $VaultPath } },
        @{ Name = "00-Inbox"; Test = { Test-Path (Join-Path $VaultPath "00-Inbox") } },
        @{ Name = "01-Projects"; Test = { Test-Path (Join-Path $VaultPath "01-Projects") } },
        @{ Name = "02-Areas"; Test = { Test-Path (Join-Path $VaultPath "02-Areas") } },
        @{ Name = "03-Resources"; Test = { Test-Path (Join-Path $VaultPath "03-Resources") } },
        @{ Name = "04-Archive"; Test = { Test-Path (Join-Path $VaultPath "04-Archive") } },
        @{ Name = "05-Daily"; Test = { Test-Path (Join-Path $VaultPath "05-Daily") } },
        @{ Name = "scripts/lib"; Test = { Test-Path (Join-Path $VaultPath "scripts\lib") } },
        @{ Name = "config"; Test = { Test-Path (Join-Path $VaultPath "config") } },
        @{ Name = ".logs"; Test = { Test-Path (Join-Path $VaultPath ".logs") } },
        @{ Name = ".backups"; Test = { Test-Path (Join-Path $VaultPath ".backups") } },
        @{ Name = "Obsidian-Config"; Test = { Test-Path (Join-Path $VaultPath ".obsidian") } },
        @{ Name = "Plugin-Manifest"; Test = { Test-Path (Join-Path $VaultPath ".obsidian\plugins\ecc-vault\manifest.json") } }
    )
    
    $passed = 0
    $failed = 0
    
    foreach ($check in $checks) {
        try {
            $result = & $check.Test
            if ($result) {
                Write-SetupLog "  [PASS] $($check.Name)" -Level "DEBUG"
                $passed++
            }
            else {
                Write-SetupLog "  [FAIL] $($check.Name)" -Level "WARN"
                $failed++
            }
        }
        catch {
            Write-SetupLog "  [FAIL] $($check.Name) - $_" -Level "WARN"
            $failed++
        }
    }
    
    Write-SetupLog "Validierung abgeschlossen: $passed/$($checks.Count) bestanden" -Level $(if ($failed -eq 0) { "SUCCESS" } else { "WARN" })
    
    return $failed -eq 0
}

#endregion

#region Main Execution

function Start-Setup {
    Write-SetupLog "=== ECC Second Brain Framework Setup v$script:Version ===" -Level "INFO"
    Write-SetupLog "Vault-Pfad: $VaultPath" -Level "INFO"
    Write-SetupLog "Log-Datei: $script:LogFile" -Level "DEBUG"
    Write-SetupLog ""
    
    # Pre-Flight Checks
    Write-SetupLog "Pre-Flight Checks..." -Level "INFO"
    
    if (!(Test-Path $VaultPath)) {
        Write-SetupLog "Erstelle Vault-Verzeichnis..." -Level "INFO"
        New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null
    }
    
    # Execute Setup Steps
    try {
        Initialize-VaultStructure
        Install-PowerShellModules
        Initialize-ObsidianConfig
        Initialize-NodeJS
        Initialize-Encryption
        
        if (!$SkipValidation) {
            $validationResult = Invoke-Validation
            
            if (!$validationResult) {
                Write-SetupLog ""
                Write-SetupLog "Validierung fehlgeschlagen!" -Level "ERROR"
                Write-SetupLog "Führe Setup erneut mit -Force aus oder prüfe die Logs" -Level "INFO"
                exit 1
            }
        }
        
        # Success
        $duration = (Get-Date) - $script:StartTime
        Write-SetupLog ""
        Write-SetupLog "=== Setup erfolgreich abgeschlossen ===" -Level "SUCCESS"
        Write-SetupLog "Dauer: $($duration.ToString('mm\:ss'))" -Level "INFO"
        Write-SetupLog ""
        Write-SetupLog "Nächste Schritte:" -Level "INFO"
        Write-SetupLog "  1. Öffne Obsidian" -Level "INFO"
        Write-SetupLog "  2. File → Open Vault → Open folder as vault" -Level "INFO"
        Write-SetupLog "  3. Wähle: $VaultPath" -Level "INFO"
        Write-SetupLog "  4. Aktiviere das ECC Second Brain Plugin" -Level "INFO"
        Write-SetupLog ""
        Write-SetupLog "Hilfe: .\Setup-SecondBrain.ps1 -Mode help" -Level "INFO"
    }
    catch {
        Write-SetupLog "Setup fehlgeschlagen: $_" -Level "ERROR"
        Write-SetupLog "Stack Trace: $($_.ScriptStackTrace)" -Level "DEBUG"
        exit 1
    }
}

#endregion

# Execute
Start-Setup
