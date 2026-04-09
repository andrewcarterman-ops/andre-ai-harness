#Requires -Version 7.0
<#
.SYNOPSIS
    Update-Skript für OpenClaw-Obsidian Integration

.DESCRIPTION
    Dieses Skript aktualisiert die OpenClaw-Obsidian Integration
    auf die neueste Version.

.PARAMETER VaultPath
    Pfad zum Obsidian Vault

.PARAMETER Backup
    Erstellt ein Backup vor dem Update

.EXAMPLE
    .\update.ps1

.EXAMPLE
    .\update.ps1 -Backup
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    
    [Parameter(Mandatory = $false)]
    [switch]$Backup,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# ============================================================================
# KONFIGURATION
# ============================================================================

$script:Config = @{
    Version = "1.0.0"
    VaultPath = $VaultPath
    BackupPath = Join-Path $VaultPath ".obsidian/backups"
    ScriptPath = $PSScriptRoot
}

# ============================================================================
# LOGGING
# ============================================================================

function Write-UpdateLog {
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
# BACKUP
# ============================================================================

function New-Backup {
    Write-UpdateLog "Creating backup..." -Level "INFO"
    
    $backupDir = Join-Path $script:Config.BackupPath (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")
    
    try {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        $itemsToBackup = @(
            "scripts",
            ".obsidian/plugins/ecc-vault/sync-config.json",
            "05-Templates"
        )
        
        foreach ($item in $itemsToBackup) {
            $sourcePath = Join-Path $script:Config.VaultPath $item
            if (Test-Path $sourcePath) {
                $targetPath = Join-Path $backupDir $item
                Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
                Write-UpdateLog "Backed up: $item" -Level "SUCCESS"
            }
        }
        
        Write-UpdateLog "Backup created: $backupDir" -Level "SUCCESS"
        return $backupDir
    }
    catch {
        Write-UpdateLog "Backup failed: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

# ============================================================================
# UPDATE
# ============================================================================

function Update-Files {
    param([string]$BackupDir)
    
    Write-UpdateLog "Updating files..." -Level "INFO"
    
    $files = @(
        @{ Source = "scripts/sync-openclaw-to-obsidian.ps1"; Target = "scripts/sync-openclaw-to-obsidian.ps1"; Critical = $true }
        @{ Source = "scripts/sync.bat"; Target = "scripts/sync.bat"; Critical = $true }
        @{ Source = "scripts/lib/MermaidGenerator.psm1"; Target = "scripts/lib/MermaidGenerator.psm1"; Critical = $false }
        @{ Source = "scripts/lib/DataviewQuery.psm1"; Target = "scripts/lib/DataviewQuery.psm1"; Critical = $false }
        @{ Source = "scripts/lib/SecureCredential.psm1"; Target = "scripts/lib/SecureCredential.psm1"; Critical = $false }
        @{ Source = "05-Templates/Session Template.md"; Target = "05-Templates/Session Template.md"; Critical = $false }
        @{ Source = "05-Templates/Decision Template.md"; Target = "05-Templates/Decision Template.md"; Critical = $false }
        @{ Source = "05-Templates/Project Template.md"; Target = "05-Templates/Project Template.md"; Critical = $false }
    )
    
    $updated = 0
    $failed = 0
    
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
                Write-UpdateLog "Updated: $($file.Source)" -Level "SUCCESS"
                $updated++
            }
            catch {
                Write-UpdateLog "Failed to update $($file.Source) : $($_.Exception.Message)" -Level "ERROR"
                $failed++
                
                if ($file.Critical -and $BackupDir) {
                    Write-UpdateLog "Restoring from backup..." -Level "WARN"
                    $backupFile = Join-Path $BackupDir $file.Target
                    if (Test-Path $backupFile) {
                        Copy-Item -Path $backupFile -Destination $targetPath -Force
                        Write-UpdateLog "Restored: $($file.Source)" -Level "SUCCESS"
                    }
                }
            }
        }
        else {
            Write-UpdateLog "Source not found: $sourcePath" -Level "WARN"
        }
    }
    
    return @{
        Updated = $updated
        Failed = $failed
    }
}

# ============================================================================
# KONFIGURATION MIGRIEREN
# ============================================================================

function Update-Configuration {
    Write-UpdateLog "Checking configuration..." -Level "INFO"
    
    $configPath = Join-Path $script:Config.VaultPath ".obsidian/plugins/ecc-vault/sync-config.json"
    
    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            
            # Version aktualisieren
            $config.version = $script:Config.Version
            
            # Neue Felder hinzufügen falls nicht vorhanden
            if (!$config.PSObject.Properties["encryption"]) {
                $config | Add-Member -NotePropertyName "encryption" -NotePropertyValue @{
                    enabled = $false
                    method = "DPAPI"
                    encryptedFields = @("api_key", "api_secret", "password")
                }
                Write-UpdateLog "Added encryption configuration" -Level "SUCCESS"
            }
            
            if (!$config.PSObject.Properties["notifications"]) {
                $config | Add-Member -NotePropertyName "notifications" -NotePropertyValue @{
                    enabled = $true
                    onSuccess = $false
                    onError = $true
                    onWarning = $true
                    sound = $false
                    toast = $true
                }
                Write-UpdateLog "Added notifications configuration" -Level "SUCCESS"
            }
            
            # Speichern
            $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
            Write-UpdateLog "Configuration updated" -Level "SUCCESS"
        }
        catch {
            Write-UpdateLog "Failed to update configuration: $($_.Exception.Message)" -Level "ERROR"
        }
    }
    else {
        Write-UpdateLog "Configuration not found, skipping update" -Level "WARN"
    }
}

# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================

function Show-Summary {
    param(
        [hashtable]$Results,
        [string]$BackupDir
    )
    
    Write-UpdateLog "========================================" -Level "INFO"
    Write-UpdateLog "Update Complete!" -Level "SUCCESS"
    Write-UpdateLog "========================================" -Level "INFO"
    Write-UpdateLog "Version: $($script:Config.Version)" -Level "INFO"
    Write-UpdateLog "Files updated: $($Results.Updated)" -Level "INFO"
    Write-UpdateLog "Files failed: $($Results.Failed)" -Level "INFO"
    
    if ($BackupDir) {
        Write-UpdateLog "Backup: $BackupDir" -Level "INFO"
    }
    
    if ($Results.Failed -gt 0) {
        Write-UpdateLog "" -Level "INFO"
        Write-UpdateLog "Some files failed to update. Check the log for details." -Level "WARN"
    }
}

# ============================================================================
# HAUPTPROGRAMM
# ============================================================================

Write-UpdateLog "========================================"
Write-UpdateLog "OpenClaw-Obsidian Integration Update"
Write-UpdateLog "Version: $($script:Config.Version)"
Write-UpdateLog "========================================"
Write-UpdateLog ""

# Prüfen ob Vault existiert
if (!(Test-Path $script:Config.VaultPath)) {
    Write-UpdateLog "Vault not found: $($script:Config.VaultPath)" -Level "ERROR"
    exit 1
}

# Backup erstellen
$backupDir = $null
if ($Backup) {
    $backupDir = New-Backup
    if (!$backupDir -and !$Force) {
        Write-UpdateLog "Backup failed. Use -Force to update without backup." -Level "ERROR"
        exit 1
    }
}

# Dateien aktualisieren
$results = Update-Files -BackupDir $backupDir

# Konfiguration migrieren
Update-Configuration

# Zusammenfassung
Show-Summary -Results $results -BackupDir $backupDir

Write-UpdateLog ""
Write-UpdateLog "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
