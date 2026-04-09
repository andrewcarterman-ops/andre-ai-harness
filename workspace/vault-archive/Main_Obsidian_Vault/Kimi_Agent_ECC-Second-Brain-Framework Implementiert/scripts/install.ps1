#Requires -Version 7.0
<#
.SYNOPSIS
    Installationsskript für OpenClaw-Obsidian Integration

.DESCRIPTION
    Dieses Skript installiert die OpenClaw-Obsidian Integration
    und konfiguriert alle notwendigen Komponenten.

.PARAMETER VaultPath
    Pfad zum Obsidian Vault

.PARAMETER CreateShortcuts
    Erstellt Desktop-Verknüpfungen

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -VaultPath "D:\MeinVault" -CreateShortcuts
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateShortcuts,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipDependencyCheck
)

# ============================================================================
# KONFIGURATION
# ============================================================================

$script:Config = @{
    Version = "1.0.0"
    RequiredPSVersion = "7.0"
    VaultPath = $VaultPath
    ScriptPath = $PSScriptRoot
}

# ============================================================================
# LOGGING
# ============================================================================

function Write-InstallLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $colorMap = @{
        "INFO" = "White"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

# ============================================================================
# VORAUSSETZUNGEN PRÜFEN
# ============================================================================

function Test-Prerequisites {
    Write-InstallLog "Checking prerequisites..." -Level "INFO"
    
    $results = @{
        PowerShell7 = $false
        Obsidian = $false
        DataviewPlugin = $false
        VaultExists = $false
    }
    
    # PowerShell 7 prüfen
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $results.PowerShell7 = $true
        Write-InstallLog "PowerShell 7+ found: $($PSVersionTable.PSVersion)" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "PowerShell 7+ required but not found" -Level "ERROR"
        Write-InstallLog "Current version: $($PSVersionTable.PSVersion)" -Level "WARN"
        Write-InstallLog "Download from: https://github.com/PowerShell/PowerShell/releases" -Level "INFO"
    }
    
    # Obsidian prüfen
    $obsidianPaths = @(
        "${env:LOCALAPPDATA}\Obsidian\Obsidian.exe",
        "${env:ProgramFiles}\Obsidian\Obsidian.exe",
        "${env:ProgramFiles(x86)}\Obsidian\Obsidian.exe"
    )
    
    foreach ($path in $obsidianPaths) {
        if (Test-Path $path) {
            $results.Obsidian = $true
            Write-InstallLog "Obsidian found: $path" -Level "SUCCESS"
            break
        }
    }
    
    if (!$results.Obsidian) {
        Write-InstallLog "Obsidian not found in standard locations" -Level "WARN"
        Write-InstallLog "Download from: https://obsidian.md/download" -Level "INFO"
    }
    
    # Vault prüfen
    if (Test-Path $script:Config.VaultPath) {
        $results.VaultExists = $true
        Write-InstallLog "Vault found: $($script:Config.VaultPath)" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Vault not found: $($script:Config.VaultPath)" -Level "WARN"
    }
    
    return $results
}

# ============================================================================
# VERZEICHNISSTRUKTUR ERSTELLEN
# ============================================================================

function Initialize-DirectoryStructure {
    Write-InstallLog "Creating directory structure..." -Level "INFO"
    
    $directories = @(
        "01-Sessions",
        "02-Areas/Decisions",
        "02-Areas/Projects",
        "03-Resources/CodeBlocks",
        "03-Resources/Dataview",
        "04-Archive",
        "05-Templates",
        "00-Dashboard",
        ".obsidian/logs",
        ".obsidian/plugins/ecc-vault"
    )
    
    foreach ($dir in $directories) {
        $fullPath = Join-Path $script:Config.VaultPath $dir
        if (!(Test-Path $fullPath)) {
            try {
                New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                Write-InstallLog "Created: $dir" -Level "SUCCESS"
            }
            catch {
                Write-InstallLog "Failed to create $dir : $($_.Exception.Message)" -Level "ERROR"
            }
        }
        else {
            Write-InstallLog "Exists: $dir" -Level "INFO"
        }
    }
}

# ============================================================================
# DATEIEN KOPIEREN
# ============================================================================

function Copy-InstallationFiles {
    Write-InstallLog "Copying installation files..." -Level "INFO"
    
    $files = @(
        @{ Source = "scripts/sync-openclaw-to-obsidian.ps1"; Target = "scripts/sync-openclaw-to-obsidian.ps1" }
        @{ Source = "scripts/sync.bat"; Target = "scripts/sync.bat" }
        @{ Source = "scripts/README.md"; Target = "scripts/README.md" }
        @{ Source = "scripts/setup-registry.ps1"; Target = "scripts/setup-registry.ps1" }
        @{ Source = "scripts/lib/MermaidGenerator.psm1"; Target = "scripts/lib/MermaidGenerator.psm1" }
        @{ Source = "scripts/lib/DataviewQuery.psm1"; Target = "scripts/lib/DataviewQuery.psm1" }
        @{ Source = "scripts/lib/SecureCredential.psm1"; Target = "scripts/lib/SecureCredential.psm1" }
        @{ Source = ".obsidian/plugins/ecc-vault/sync-config.json"; Target = ".obsidian/plugins/ecc-vault/sync-config.json" }
        @{ Source = "03-Resources/Dataview/queries.md"; Target = "03-Resources/Dataview/queries.md" }
        @{ Source = "05-Templates/Session Template.md"; Target = "05-Templates/Session Template.md" }
        @{ Source = "05-Templates/Decision Template.md"; Target = "05-Templates/Decision Template.md" }
        @{ Source = "05-Templates/Project Template.md"; Target = "05-Templates/Project Template.md" }
        @{ Source = "00-Dashboard/Dashboard.md"; Target = "00-Dashboard/Dashboard.md" }
        @{ Source = "README.md"; Target = "README.md" }
    )
    
    foreach ($file in $files) {
        $sourcePath = Join-Path $script:Config.ScriptPath ".." $file.Source
        $targetPath = Join-Path $script:Config.VaultPath $file.Target
        
        if (Test-Path $sourcePath) {
            try {
                $targetDir = Split-Path $targetPath -Parent
                if (!(Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                
                Copy-Item -Path $sourcePath -Destination $targetPath -Force
                Write-InstallLog "Copied: $($file.Source)" -Level "SUCCESS"
            }
            catch {
                Write-InstallLog "Failed to copy $($file.Source) : $($_.Exception.Message)" -Level "ERROR"
            }
        }
        else {
            Write-InstallLog "Source not found: $sourcePath" -Level "WARN"
        }
    }
}

# ============================================================================
# VERKNÜPFUNGEN ERSTELLEN
# ============================================================================

function New-DesktopShortcuts {
    Write-InstallLog "Creating desktop shortcuts..." -Level "INFO"
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    
    # Sync-Verknüpfung
    $syncWsh = New-Object -ComObject WScript.Shell
    $syncShortcut = $syncWsh.CreateShortcut("$desktopPath\OpenClaw Sync.lnk")
    $syncShortcut.TargetPath = Join-Path $script:Config.VaultPath "scripts\sync.bat"
    $syncShortcut.WorkingDirectory = Join-Path $script:Config.VaultPath "scripts"
    $syncShortcut.IconLocation = "%SystemRoot%\System32\shell32.dll,14"
    $syncShortcut.Description = "Synchronisiert OpenClaw mit Obsidian"
    $syncShortcut.Save()
    
    Write-InstallLog "Created: OpenClaw Sync.lnk" -Level "SUCCESS"
    
    # Obsidian Vault-Verknüpfung
    $vaultWsh = New-Object -ComObject WScript.Shell
    $vaultShortcut = $vaultWsh.CreateShortcut("$desktopPath\SecondBrain Vault.lnk")
    $vaultShortcut.TargetPath = "obsidian://open?vault=SecondBrain"
    $vaultShortcut.IconLocation = "%LocalAppData%\Obsidian\Obsidian.exe,0"
    $vaultShortcut.Description = "Öffnet das SecondBrain Obsidian Vault"
    $vaultShortcut.Save()
    
    Write-InstallLog "Created: SecondBrain Vault.lnk" -Level "SUCCESS"
}

# ============================================================================
# REGISTRY INITIALISIEREN
# ============================================================================

function Initialize-Registry {
    Write-InstallLog "Initializing registry..." -Level "INFO"
    
    $registryPath = "HKCU:\Software\OpenClaw\Sessions"
    
    if (!(Test-Path $registryPath)) {
        try {
            New-Item -Path $registryPath -Force | Out-Null
            Write-InstallLog "Created registry path: $registryPath" -Level "SUCCESS"
        }
        catch {
            Write-InstallLog "Failed to create registry path: $($_.Exception.Message)" -Level "WARN"
        }
    }
    else {
        Write-InstallLog "Registry path exists: $registryPath" -Level "INFO"
    }
}

# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================

function Show-Summary {
    Write-InstallLog "========================================" -Level "INFO"
    Write-InstallLog "Installation Complete!" -Level "SUCCESS"
    Write-InstallLog "========================================" -Level "INFO"
    Write-InstallLog "Version: $($script:Config.Version)" -Level "INFO"
    Write-InstallLog "Vault Path: $($script:Config.VaultPath)" -Level "INFO"
    Write-InstallLog "" -Level "INFO"
    Write-InstallLog "Next Steps:" -Level "INFO"
    Write-InstallLog "1. Open Obsidian and load the vault" -Level "INFO"
    Write-InstallLog "2. Install Dataview plugin (Community Plugins)" -Level "INFO"
    Write-InstallLog "3. Run sync: .\scripts\sync.bat" -Level "INFO"
    Write-InstallLog "4. Open Dashboard: 00-Dashboard\Dashboard.md" -Level "INFO"
    Write-InstallLog "" -Level "INFO"
    Write-InstallLog "Documentation: scripts\README.md" -Level "INFO"
}

# ============================================================================
# HAUPTPROGRAMM
# ============================================================================

Write-InstallLog "========================================"
Write-InstallLog "OpenClaw-Obsidian Integration Setup"
Write-InstallLog "Version: $($script:Config.Version)"
Write-InstallLog "========================================"
Write-InstallLog ""

# Voraussetzungen prüfen
if (!$SkipDependencyCheck) {
    $prereqs = Test-Prerequisites
    
    if (!$prereqs.PowerShell7) {
        Write-InstallLog "PowerShell 7+ is required. Installation aborted." -Level "ERROR"
        exit 1
    }
}

# Verzeichnisstruktur erstellen
Initialize-DirectoryStructure

# Dateien kopieren
Copy-InstallationFiles

# Registry initialisieren
Initialize-Registry

# Verknüpfungen erstellen
if ($CreateShortcuts) {
    New-DesktopShortcuts
}

# Zusammenfassung
Show-Summary

Write-InstallLog ""
Write-InstallLog "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
