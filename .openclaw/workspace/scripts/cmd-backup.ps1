#!/usr/bin/env pwsh
# Backup/Restore Command
# Erstellt und verwaltet Backups des Frameworks

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("create", "restore", "list", "prune")]
    [string]$Action,
    
    [string]$Name,
    [string]$BackupDir = "memory/backups",
    [switch]$Force,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

# Logging importieren
Import-Module "$workspaceRoot/scripts/lib/Logging.psm1" -Force
Initialize-Logging -Component "backup"

$fullBackupDir = Join-Path $workspaceRoot $BackupDir
if (-not (Test-Path $fullBackupDir)) {
    New-Item -ItemType Directory -Path $fullBackupDir -Force | Out-Null
}

function Get-BackupName {
    if ($Name) { return $Name }
    return "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

function Create-Backup {
    $backupName = Get-BackupName
    $backupPath = Join-Path $fullBackupDir $backupName
    
    if ((Test-Path $backupPath) -and -not $Force) {
        Write-ErrorLog -Message "Backup '$backupName' already exists. Use -Force to overwrite."
        exit 1
    }
    
    Write-InfoLog -Message "Creating backup: $backupName" -Console
    
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    
    # Zu sichernde Dateien
    $itemsToBackup = @(
        "registry/*.yaml",
        "registry/*.json",
        "hooks/*.md",
        "plans/*.md",
        "skills/*/SKILL.md",
        "memory/self-improving/**/*.md",
        "AGENTS.md",
        "README.md"
    )
    
    $manifest = @{
        created_at = Get-Date -Format "o"
        name = $backupName
        items = @()
    }
    
    foreach ($pattern in $itemsToBackup) {
        $files = Get-ChildItem (Join-Path $workspaceRoot $pattern) -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($workspaceRoot.Length + 1)
            $targetPath = Join-Path $backupPath $relativePath
            $targetDir = Split-Path $targetPath -Parent
            
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            
            Copy-Item $file.FullName $targetPath -Force
            $manifest.items += $relativePath
            
            if ($Verbose) {
                Write-DebugLog -Message "Backed up: $relativePath"
            }
        }
    }
    
    # Manifest speichern
    $manifest | ConvertTo-Json | Out-File (Join-Path $backupPath "manifest.json") -Encoding UTF8
    
    # Metadaten
    $stats = @{
        files = $manifest.items.Count
        size = (Get-ChildItem $backupPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
    }
    
    Write-InfoLog -Message "Backup created: $backupName ($($stats.files) files, $([math]::Round($stats.size/1KB, 2)) KB)" -Console -Data $stats
}

function Restore-Backup {
    if (-not $Name) {
        Write-ErrorLog -Message "Backup name required for restore"
        exit 1
    }
    
    $backupPath = Join-Path $fullBackupDir $Name
    if (-not (Test-Path $backupPath)) {
        Write-ErrorLog -Message "Backup '$Name' not found"
        exit 1
    }
    
    $manifestPath = Join-Path $backupPath "manifest.json"
    if (-not (Test-Path $manifestPath)) {
        Write-ErrorLog -Message "Backup manifest not found"
        exit 1
    }
    
    $manifest = Get-Content $manifestPath | ConvertFrom-Json
    
    Write-InfoLog -Message "Restoring backup: $Name (created: $($manifest.created_at))" -Console
    
    if (-not $Force) {
        Write-WarningLog -Message "This will overwrite current files. Use -Force to proceed."
        exit 1
    }
    
    foreach ($item in $manifest.items) {
        $source = Join-Path $backupPath $item
        $target = Join-Path $workspaceRoot $item
        $targetDir = Split-Path $target -Parent
        
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        Copy-Item $source $target -Force
        
        if ($Verbose) {
            Write-DebugLog -Message "Restored: $item"
        }
    }
    
    Write-InfoLog -Message "Restore completed" -Console
}

function List-Backups {
    $backups = Get-ChildItem $fullBackupDir -Directory | ForEach-Object {
        $manifestPath = Join-Path $_.FullName "manifest.json"
        if (Test-Path $manifestPath) {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            $size = (Get-ChildItem $_.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
            
            [PSCustomObject]@{
                Name = $_.Name
                Created = $manifest.created_at
                Files = $manifest.items.Count
                SizeKB = [math]::Round($size / 1KB, 2)
            }
        }
    } | Sort-Object Created -Descending
    
    if ($backups.Count -eq 0) {
        Write-InfoLog -Message "No backups found" -Console
        return
    }
    
    Write-Host "`n📦 Available Backups:" -ForegroundColor Cyan
    $backups | Format-Table -AutoSize
}

function Prune-Backups {
    $keep = 10
    $allBackups = Get-ChildItem $fullBackupDir -Directory | Sort-Object CreationTime -Descending
    
    if ($allBackups.Count -le $keep) {
        Write-InfoLog -Message "No old backups to prune (keeping $keep)" -Console
        return
    }
    
    $toDelete = $allBackups | Select-Object -Skip $keep
    
    foreach ($backup in $toDelete) {
        Remove-Item $backup.FullName -Recurse -Force
        Write-InfoLog -Message "Pruned: $($backup.Name)" -Console
    }
    
    Write-InfoLog -Message "Pruned $($toDelete.Count) old backups" -Console
}

# Hauptlogik
switch ($Action) {
    "create" { Create-Backup }
    "restore" { Restore-Backup }
    "list" { List-Backups }
    "prune" { Prune-Backups }
}
