#Requires -Version 5.1
<#
.SYNOPSIS
    Backup/Restore Kommando für ECC Second Brain

.DESCRIPTION
    Erstellt und verwaltet Backups des ECC Second Brain Vaults.
    Unterstützt ZIP-Kompression, Retention-Management und Verifizierung.

.PARAMETER Action
    Aktion: Backup, Restore, List, Clean, Verify

.PARAMETER VaultPath
    Pfad zum Vault

.PARAMETER BackupPath
    Pfad zum Backup-Verzeichnis

.PARAMETER BackupName
    Name des Backups (für Restore)

.PARAMETER RetentionDays
    Aufbewahrungsdauer in Tagen

.EXAMPLE
    .\cmd-backup.ps1 -Action Backup
    .\cmd-backup.ps1 -Action Restore -BackupName "backup_20260326_120000"
    .\cmd-backup.ps1 -Action List

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    ECC Framework: Backup/Restore
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Backup", "Restore", "List", "Clean", "Verify")]
    [string]$Action = "Backup",
    
    [Parameter(Mandatory = $false)]
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    
    [Parameter(Mandatory = $false)]
    [string]$BackupPath = "",
    
    [Parameter(Mandatory = $false)]
    [string]$BackupName = "",
    
    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 30
)

# Script Variables
$script:Version = "1.0.0"
$script:StartTime = Get-Date

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

function Invoke-Backup {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFileName = "backup_$timestamp.zip"
    $backupFilePath = Join-Path $BackupPath $backupFileName
    
    # Ensure backup directory exists
    if (!(Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    }
    
    Write-BackupLog "Creating backup: $backupFileName" -Level "INFO"
    
    # Create manifest
    $manifest = @{
        version = $script:Version
        timestamp = Get-Date -Format "o"
        vaultPath = $VaultPath
        files = @()
    }
    
    # Get files to backup
    $files = Get-ChildItem $VaultPath -Recurse -File | Where-Object {
        $_.FullName -notlike "*$BackupPath*" -and
        $_.FullName -notlike "*.backups*" -and
        $_.FullName -notlike "*.logs*" -and
        $_.FullName -notlike "*node_modules*"
    }
    
    # Create temporary directory for manifest
    $tempDir = Join-Path $env:TEMP "ecc-backup-$timestamp"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Copy files to temp directory
    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($VaultPath.Length + 1)
        $targetPath = Join-Path $tempDir $relativePath
        $targetDir = Split-Path $targetPath -Parent
        
        if (!(Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        Copy-Item $file.FullName $targetPath -Force
        $manifest.files += $relativePath
    }
    
    # Save manifest
    $manifest | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $tempDir "manifest.json") -Encoding UTF8
    
    # Create ZIP
    Compress-Archive -Path "$tempDir\*" -DestinationPath $backupFilePath -Force
    
    # Cleanup temp directory
    Remove-Item $tempDir -Recurse -Force
    
    Write-BackupLog "Backup created: $backupFileName ($([math]::Round((Get-Item $backupFilePath).Length / 1MB, 2)) MB)" -Level "SUCCESS"
    
    return $backupFileName
}

function Invoke-Restore {
    param([string]$Name)
    
    $backupFilePath = Join-Path $BackupPath "$Name.zip"
    
    if (!(Test-Path $backupFilePath)) {
        Write-BackupLog "Backup not found: $Name" -Level "ERROR"
        return $false
    }
    
    Write-BackupLog "Restoring backup: $Name" -Level "INFO"
    
    # Create pre-restore backup
    Write-BackupLog "Creating pre-restore backup..." -Level "INFO"
    Invoke-Backup | Out-Null
    
    # Extract backup
    $tempDir = Join-Path $env:TEMP "ecc-restore-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Expand-Archive -Path $backupFilePath -DestinationPath $tempDir -Force
    
    # Read manifest
    $manifestPath = Join-Path $tempDir "manifest.json"
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    
    # Restore files
    foreach ($file in $manifest.files) {
        $sourcePath = Join-Path $tempDir $file
        $targetPath = Join-Path $VaultPath $file
        $targetDir = Split-Path $targetPath -Parent
        
        if (!(Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        Copy-Item $sourcePath $targetPath -Force
    }
    
    # Cleanup
    Remove-Item $tempDir -Recurse -Force
    
    Write-BackupLog "Restore completed: $Name" -Level "SUCCESS"
    return $true
}

function Get-BackupList {
    if (!(Test-Path $BackupPath)) {
        return @()
    }
    
    $backups = Get-ChildItem $BackupPath -Filter "backup_*.zip" -File | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        $date = $_.CreationTime
        
        [PSCustomObject]@{
            Name = $_.BaseName
            Date = $date
            SizeMB = $size
            AgeDays = [math]::Round(((Get-Date) - $date).TotalDays, 1)
        }
    }
    
    return $backups | Sort-Object Date -Descending
}

function Clear-OldBackups {
    param([int]$Days)
    
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $backups = Get-ChildItem $BackupPath -Filter "backup_*.zip" -File | Where-Object {
        $_.CreationTime -lt $cutoffDate
    }
    
    $count = 0
    foreach ($backup in $backups) {
        Remove-Item $backup.FullName -Force
        $count++
    }
    
    Write-BackupLog "Deleted $count old backups (older than $Days days)" -Level "SUCCESS"
}

function Test-BackupIntegrity {
    param([string]$Name)
    
    $backupFilePath = Join-Path $BackupPath "$Name.zip"
    
    if (!(Test-Path $backupFilePath)) {
        Write-BackupLog "Backup not found: $Name" -Level "ERROR"
        return $false
    }
    
    try {
        # Test ZIP integrity
        $tempDir = Join-Path $env:TEMP "ecc-verify-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Expand-Archive -Path $backupFilePath -DestinationPath $tempDir -Force
        
        # Check manifest
        $manifestPath = Join-Path $tempDir "manifest.json"
        if (!(Test-Path $manifestPath)) {
            Write-BackupLog "Manifest missing in backup: $Name" -Level "ERROR"
            return $false
        }
        
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
        
        # Verify files
        $missingFiles = @()
        foreach ($file in $manifest.files) {
            $filePath = Join-Path $tempDir $file
            if (!(Test-Path $filePath)) {
                $missingFiles += $file
            }
        }
        
        # Cleanup
        Remove-Item $tempDir -Recurse -Force
        
        if ($missingFiles.Count -eq 0) {
            Write-BackupLog "Backup integrity verified: $Name" -Level "SUCCESS"
            return $true
        }
        else {
            Write-BackupLog "Backup integrity failed: $Name - Missing files: $($missingFiles -join ', ')" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-BackupLog "Backup integrity check failed: $Name - $_" -Level "ERROR"
        return $false
    }
}

#endregion

#region Main

switch ($Action) {
    "Backup" {
        Invoke-Backup
    }
    "Restore" {
        if ([string]::IsNullOrEmpty($BackupName)) {
            Write-BackupLog "BackupName required for Restore action" -Level "ERROR"
            exit 1
        }
        Invoke-Restore -Name $BackupName
    }
    "List" {
        $backups = Get-BackupList
        if ($backups.Count -eq 0) {
            Write-BackupLog "No backups found" -Level "WARN"
        }
        else {
            Write-BackupLog "Available backups:" -Level "INFO"
            $backups | Format-Table -AutoSize
        }
    }
    "Clean" {
        Clear-OldBackups -Days $RetentionDays
    }
    "Verify" {
        if ([string]::IsNullOrEmpty($BackupName)) {
            # Verify all backups
            $backups = Get-BackupList
            foreach ($backup in $backups) {
                Test-BackupIntegrity -Name $backup.Name
            }
        }
        else {
            Test-BackupIntegrity -Name $BackupName
        }
    }
}

#endregion
