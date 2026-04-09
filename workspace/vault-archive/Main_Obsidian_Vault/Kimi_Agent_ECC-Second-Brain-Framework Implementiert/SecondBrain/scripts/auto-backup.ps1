#Requires -Version 5.1
<#
.SYNOPSIS
    Auto-Backup für ECC Second Brain

.DESCRIPTION
    Erstellt automatische Backups vor und nach Sessions.
    Unterstützt Retention-Management und Pre/Post-Session Marker.

.PARAMETER VaultPath
    Pfad zum Vault

.PARAMETER BackupPath
    Pfad zum Backup-Verzeichnis

.PARAMETER Mode
    Modus: PreSession, PostSession, Scheduled

.PARAMETER RetentionDays
    Aufbewahrungsdauer

.EXAMPLE
    .\auto-backup.ps1 -Mode PreSession
    .\auto-backup.ps1 -Mode PostSession
    .\auto-backup.ps1 -Mode Scheduled

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    ECC Framework: Stability
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    
    [Parameter(Mandatory = $false)]
    [string]$BackupPath = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("PreSession", "PostSession", "Scheduled")]
    [string]$Mode = "Scheduled",
    
    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 30
)

# Script Variables
$script:Version = "1.0.0"

if ([string]::IsNullOrEmpty($BackupPath)) {
    $BackupPath = Join-Path $VaultPath ".backups"
}

#region Functions

function Write-BackupLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
}

function Invoke-PreSessionBackup {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = "pre_session_$timestamp"
    
    Write-BackupLog "Creating pre-session backup: $backupName" -Level "INFO"
    
    # Create marker file
    $markerPath = Join-Path $VaultPath ".session_marker"
    "Pre-session backup created at $timestamp" | Set-Content $markerPath
    
    # Run backup
    & (Join-Path $PSScriptRoot "cmd-backup.ps1") -Action Backup -VaultPath $VaultPath -BackupPath $BackupPath
    
    Write-BackupLog "Pre-session backup completed" -Level "SUCCESS"
}

function Invoke-PostSessionBackup {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = "post_session_$timestamp"
    
    Write-BackupLog "Creating post-session backup: $backupName" -Level "INFO"
    
    # Check for pre-session marker
    $markerPath = Join-Path $VaultPath ".session_marker"
    $hasChanges = $false
    
    if (Test-Path $markerPath) {
        # Compare with pre-session state
        $hasChanges = $true
        Remove-Item $markerPath -Force
    }
    
    if ($hasChanges) {
        & (Join-Path $PSScriptRoot "cmd-backup.ps1") -Action Backup -VaultPath $VaultPath -BackupPath $BackupPath
        Write-BackupLog "Post-session backup completed" -Level "SUCCESS"
    }
    else {
        Write-BackupLog "No changes detected, skipping post-session backup" -Level "INFO"
    }
}

function Invoke-ScheduledBackup {
    Write-BackupLog "Running scheduled backup" -Level "INFO"
    
    # Create backup
    & (Join-Path $PSScriptRoot "cmd-backup.ps1") -Action Backup -VaultPath $VaultPath -BackupPath $BackupPath
    
    # Cleanup old backups
    & (Join-Path $PSScriptRoot "cmd-backup.ps1") -Action Clean -BackupPath $BackupPath -RetentionDays $RetentionDays
    
    Write-BackupLog "Scheduled backup completed" -Level "SUCCESS"
}

#endregion

#region Main

Write-BackupLog "=== ECC Auto-Backup v$script:Version ===" -Level "INFO"
Write-BackupLog "Mode: $Mode" -Level "INFO"

switch ($Mode) {
    "PreSession" {
        Invoke-PreSessionBackup
    }
    "PostSession" {
        Invoke-PostSessionBackup
    }
    "Scheduled" {
        Invoke-ScheduledBackup
    }
}

#endregion
