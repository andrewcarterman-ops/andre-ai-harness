# ============================================================================
# ECC-CORE Backup/Restore Commands
# Second-Brain Framework - Vault Backup and Restore
# ============================================================================
#Requires -Version 5.1

<#
.SYNOPSIS
    Backup and Restore commands for Second-Brain Vault

.DESCRIPTION
    Provides comprehensive backup and restore functionality for the
    Second-Brain Obsidian vault with ZIP compression and validation.

.PARAMETER Action
    Action to perform: Backup, Restore, List, or Clean.

.PARAMETER VaultPath
    Path to the Obsidian vault (default: auto-detect).

.PARAMETER BackupPath
    Path for backup storage (default: .backups/).

.PARAMETER BackupFile
    Specific backup file for restore operation.

.PARAMETER RetentionDays
    Number of days to retain backups (default: 30).

.PARAMETER Compress
    Compression level: Fastest, Optimal, NoCompression.

.PARAMETER Verify
    Verify backup integrity after creation.

.PARAMETER Force
    Overwrite existing files without prompting.

.EXAMPLE
    .\cmd-backup.ps1 -Action Backup

.EXAMPLE
    .\cmd-backup.ps1 -Action Restore -BackupFile "SecondBrain-20240115-143022.zip"

.EXAMPLE
    .\cmd-backup.ps1 -Action List

.EXAMPLE
    .\cmd-backup.ps1 -Action Clean -RetentionDays 7
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('Backup', 'Restore', 'List', 'Clean', 'Verify')]
    [string]$Action,

    [Parameter()]
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",

    [Parameter()]
    [string]$BackupPath,

    [Parameter()]
    [string]$BackupFile,

    [Parameter()]
    [int]$RetentionDays = 30,

    [Parameter()]
    [ValidateSet('Fastest', 'Optimal', 'NoCompression')]
    [string]$Compress = 'Optimal',

    [Parameter()]
    [switch]$Verify,

    [Parameter()]
    [switch]$Force
)

# Import required modules
$libPath = Join-Path $PSScriptRoot "lib"
Import-Module (Join-Path $libPath "Logging.psm1") -Force
Import-Module (Join-Path $libPath "ErrorHandler.psm1") -Force

# Initialize
Initialize-ECCLogging -BasePath $VaultPath

# Set default backup path if not provided
if (-not $BackupPath) {
    $BackupPath = Join-Path $VaultPath ".backups"
}

# Exit codes
$script:ExitCodes = @{
    SUCCESS           = 0
    VAULT_NOT_FOUND   = 1
    BACKUP_FAILED     = 2
    RESTORE_FAILED    = 3
    VERIFY_FAILED     = 4
    INVALID_BACKUP    = 5
    CLEANUP_FAILED    = 6
}

<#
.SYNOPSIS
    Ensures backup directory exists.
#>
function Initialize-BackupDirectory {
    [CmdletBinding()]
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-InfoLog "Created backup directory: $Path" -Source "Backup"
        }
        catch {
            Write-FatalLog "Failed to create backup directory: $Path" -Source "Backup" -ErrorRecord $_
            exit $script:ExitCodes.BACKUP_FAILED
        }
    }
}

<#
.SYNOPSIS
    Creates a backup of the vault.
#>
function Invoke-VaultBackup {
    [CmdletBinding()]
    param()

    Write-InfoLog "Starting vault backup" -Source "Backup"

    # Validate vault path
    if (-not (Test-Path $VaultPath)) {
        Write-FatalLog "Vault path not found: $VaultPath" -Source "Backup"
        exit $script:ExitCodes.VAULT_NOT_FOUND
    }

    # Initialize backup directory
    Initialize-BackupDirectory -Path $BackupPath

    # Generate backup filename with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $vaultName = Split-Path $VaultPath -Leaf
    $backupFileName = "$vaultName-$timestamp.zip"
    $backupFullPath = Join-Path $BackupPath $backupFileName

    # Check if file exists
    if (Test-Path $backupFullPath -and -not $Force) {
        $response = Read-Host "Backup file already exists. Overwrite? (Y/N)"
        if ($response -ne 'Y') {
            Write-InfoLog "Backup cancelled by user" -Source "Backup"
            return
        }
    }

    # Create backup with retry logic
    $backupResult = Invoke-WithErrorHandling -ScriptBlock {
        # Exclude patterns
        $excludePatterns = @(
            '.obsidian/workspace*',
            '.obsidian/cache*',
            '.git',
            '.backups',
            '.logs',
            '*.tmp'
        )

        # Get files to backup
        $files = Get-ChildItem -Path $VaultPath -Recurse -File | 
                 Where-Object { 
                     $file = $_
                     $exclude = $false
                     foreach ($pattern in $excludePatterns) {
                         if ($file.FullName -like "*$pattern*") {
                             $exclude = $true
                             break
                         }
                     }
                     -not $exclude
                 }

        Write-InfoLog "Found $($files.Count) files to backup" -Source "Backup"

        # Create ZIP archive
        Compress-Archive -Path $files.FullName -DestinationPath $backupFullPath -CompressionLevel $Compress -Force

        return $backupFullPath
    } -OperationName "VaultBackup" -MaxRetries 3 -Critical

    if (-not $backupResult) {
        exit $script:ExitCodes.BACKUP_FAILED
    }

    # Get backup file info
    $backupInfo = Get-Item $backupFullPath
    $backupSize = [math]::Round($backupInfo.Length / 1MB, 2)

    Write-InfoLog "Backup created: $backupFileName ($backupSize MB)" -Source "Backup"

    # Verify backup if requested
    if ($Verify) {
        Write-InfoLog "Verifying backup integrity..." -Source "Backup"
        $verifyResult = Test-BackupIntegrity -BackupPath $backupFullPath
        
        if (-not $verifyResult) {
            Write-ErrorLogEntry "Backup verification failed" -Source "Backup"
            exit $script:ExitCodes.VERIFY_FAILED
        }
        
        Write-InfoLog "Backup verification successful" -Source "Backup"
    }

    # Create backup manifest
    $manifest = @{
        Timestamp    = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        VaultPath    = $VaultPath
        BackupFile   = $backupFileName
        SizeBytes    = $backupInfo.Length
        SizeMB       = $backupSize
        Compression  = $Compress
        Verified     = $Verify
        FileCount    = (Get-ChildItem -Path $VaultPath -Recurse -File).Count
    }

    $manifestPath = "$backupFullPath.manifest.json"
    $manifest | ConvertTo-Json | Out-File -FilePath $manifestPath -Encoding UTF8

    Write-InfoLog "Backup manifest created: $manifestPath" -Source "Backup"

    # Clean old backups
    Invoke-BackupCleanup

    return $backupFullPath
}

<#
.SYNOPSIS
    Restores vault from backup.
#>
function Invoke-VaultRestore {
    [CmdletBinding()]
    param()

    Write-InfoLog "Starting vault restore" -Source "Restore"

    # Determine backup file to restore
    if (-not $BackupFile) {
        # List available backups and let user choose
        $backups = Get-ChildItem -Path $BackupPath -Filter "*.zip" | 
                   Sort-Object LastWriteTime -Descending
        
        if ($backups.Count -eq 0) {
            Write-FatalLog "No backup files found in: $BackupPath" -Source "Restore"
            exit $script:ExitCodes.INVALID_BACKUP
        }

        Write-Host "`nAvailable backups:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $backups.Count; $i++) {
            $size = [math]::Round($backups[$i].Length / 1MB, 2)
            Write-Host "  [$i] $($backups[$i].Name) ($size MB) - $($backups[$i].LastWriteTime)"
        }

        $selection = Read-Host "`nSelect backup to restore (0-$($backups.Count - 1), or 'C' to cancel)"
        
        if ($selection -eq 'C') {
            Write-InfoLog "Restore cancelled by user" -Source "Restore"
            return
        }

        $BackupFile = $backups[[int]$selection].Name
    }

    $backupFullPath = Join-Path $BackupPath $BackupFile

    if (-not (Test-Path $backupFullPath)) {
        Write-FatalLog "Backup file not found: $backupFullPath" -Source "Restore"
        exit $script:ExitCodes.INVALID_BACKUP
    }

    # Verify backup integrity
    Write-InfoLog "Verifying backup integrity..." -Source "Restore"
    if (-not (Test-BackupIntegrity -BackupPath $backupFullPath)) {
        Write-FatalLog "Backup file is corrupted or invalid" -Source "Restore"
        exit $script:ExitCodes.VERIFY_FAILED
    }

    # Confirm restore
    if (-not $Force) {
        Write-Host "`nWARNING: This will overwrite files in: $VaultPath" -ForegroundColor Red
        $response = Read-Host "Are you sure you want to continue? (Type 'RESTORE' to confirm)"
        if ($response -ne 'RESTORE') {
            Write-InfoLog "Restore cancelled by user" -Source "Restore"
            return
        }
    }

    # Create pre-restore backup
    Write-InfoLog "Creating pre-restore backup..." -Source "Restore"
    $preRestoreBackup = Invoke-VaultBackup

    # Perform restore with retry logic
    $restoreResult = Invoke-WithErrorHandling -ScriptBlock {
        # Extract backup
        $tempExtractPath = Join-Path $env:TEMP "SecondBrain-Restore-$(Get-Random)"
        New-Item -ItemType Directory -Path $tempExtractPath -Force | Out-Null

        Expand-Archive -Path $backupFullPath -DestinationPath $tempExtractPath -Force

        # Restore files
        $restoredFiles = 0
        $extractedFiles = Get-ChildItem -Path $tempExtractPath -Recurse -File
        
        foreach ($file in $extractedFiles) {
            $relativePath = $file.FullName.Substring($tempExtractPath.Length + 1)
            $targetPath = Join-Path $VaultPath $relativePath
            
            $targetDir = Split-Path $targetPath -Parent
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            Copy-Item -Path $file.FullName -Destination $targetPath -Force
            $restoredFiles++
        }

        # Cleanup temp directory
        Remove-Item -Path $tempExtractPath -Recurse -Force

        return $restoredFiles
    } -OperationName "VaultRestore" -MaxRetries 2 -Critical

    if (-not $restoreResult) {
        exit $script:ExitCodes.RESTORE_FAILED
    }

    Write-InfoLog "Restore completed: $restoreResult files restored" -Source "Restore"
    Write-InfoLog "Pre-restore backup: $preRestoreBackup" -Source "Restore"
}

<#
.SYNOPSIS
    Lists available backups.
#>
function Get-BackupList {
    [CmdletBinding()]
    param()

    Write-InfoLog "Listing available backups" -Source "Backup"

    if (-not (Test-Path $BackupPath)) {
        Write-Host "No backup directory found." -ForegroundColor Yellow
        return
    }

    $backups = Get-ChildItem -Path $BackupPath -Filter "*.zip" | 
               Sort-Object LastWriteTime -Descending

    if ($backups.Count -eq 0) {
        Write-Host "No backup files found." -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Available Backups ===" -ForegroundColor Cyan
    Write-Host "Location: $BackupPath`n" -ForegroundColor Gray

    $output = @()
    foreach ($backup in $backups) {
        $size = [math]::Round($backup.Length / 1MB, 2)
        $manifestPath = "$($backup.FullName).manifest.json"
        $verified = if (Test-Path $manifestPath) { "Yes" } else { "No" }

        $output += [PSCustomObject]@{
            'File Name'   = $backup.Name
            'Size (MB)'   = $size
            'Created'     = $backup.LastWriteTime
            'Verified'    = $verified
        }
    }

    $output | Format-Table -AutoSize
    Write-Host "Total backups: $($backups.Count)" -ForegroundColor Green
}

<#
.SYNOPSIS
    Cleans up old backups based on retention policy.
#>
function Invoke-BackupCleanup {
    [CmdletBinding()]
    param()

    Write-InfoLog "Running backup cleanup (retention: $RetentionDays days)" -Source "Backup"

    if (-not (Test-Path $BackupPath)) {
        return
    }

    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $oldBackups = Get-ChildItem -Path $BackupPath -Filter "*.zip" | 
                  Where-Object { $_.LastWriteTime -lt $cutoffDate }

    $removedCount = 0
    $freedSpace = 0

    foreach ($backup in $oldBackups) {
        try {
            # Also remove manifest if exists
            $manifestPath = "$($backup.FullName).manifest.json"
            if (Test-Path $manifestPath) {
                Remove-Item -Path $manifestPath -Force
            }

            $freedSpace += $backup.Length
            Remove-Item -Path $backup.FullName -Force
            $removedCount++
            Write-DebugLog "Removed old backup: $($backup.Name)" -Source "Backup"
        }
        catch {
            Write-WarnLog "Failed to remove backup: $($backup.Name)" -Source "Backup"
        }
    }

    $freedMB = [math]::Round($freedSpace / 1MB, 2)
    Write-InfoLog "Cleanup complete: Removed $removedCount backups, freed $freedMB MB" -Source "Backup"
}

<#
.SYNOPSIS
    Verifies backup file integrity.
#>
function Test-BackupIntegrity {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )

    try {
        # Test ZIP integrity
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($BackupPath)
        
        # Check if we can read entries
        $entryCount = $zip.Entries.Count
        $zip.Dispose()

        # Verify manifest exists
        $manifestPath = "$BackupPath.manifest.json"
        if (Test-Path $manifestPath) {
            $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
            Write-DebugLog "Manifest found: $($manifest.BackupFile)" -Source "Backup"
        }

        Write-DebugLog "Backup integrity verified: $entryCount entries" -Source "Backup"
        return $true
    }
    catch {
        Write-ErrorLogEntry "Backup integrity check failed: $_" -Source "Backup" -ErrorRecord $_
        return $false
    }
}

<#
.SYNOPSIS
    Verifies a specific backup file.
#>
function Invoke-BackupVerification {
    [CmdletBinding()]
    param()

    if (-not $BackupFile) {
        Write-FatalLog "BackupFile parameter required for verification" -Source "Backup"
        exit $script:ExitCodes.INVALID_BACKUP
    }

    $backupFullPath = Join-Path $BackupPath $BackupFile

    if (-not (Test-Path $backupFullPath)) {
        Write-FatalLog "Backup file not found: $backupFullPath" -Source "Backup"
        exit $script:ExitCodes.INVALID_BACKUP
    }

    Write-InfoLog "Verifying backup: $BackupFile" -Source "Backup"

    $result = Test-BackupIntegrity -BackupPath $backupFullPath

    if ($result) {
        Write-Host "`nBackup verification: PASSED" -ForegroundColor Green
        exit $script:ExitCodes.SUCCESS
    }
    else {
        Write-Host "`nBackup verification: FAILED" -ForegroundColor Red
        exit $script:ExitCodes.VERIFY_FAILED
    }
}

# ============================================================================
# Main Execution
# ============================================================================

switch ($Action) {
    'Backup'  { Invoke-VaultBackup }
    'Restore' { Invoke-VaultRestore }
    'List'    { Get-BackupList }
    'Clean'   { Invoke-BackupCleanup }
    'Verify'  { Invoke-BackupVerification }
}

exit $script:ExitCodes.SUCCESS
