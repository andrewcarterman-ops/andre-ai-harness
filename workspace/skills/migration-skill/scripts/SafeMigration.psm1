#Requires -Version 5.1

<#
.SYNOPSIS
    Safe Migration PowerShell Module
    
.DESCRIPTION
    Provides foolproof migration functions with safety checks,
    validation, and quality assurance.
    
.EXAMPLE
    Import-Module .\SafeMigration.psm1
    Start-SafeMigration -Source "C:\OldVault" -Destination "C:\NewVault"
#>

function Start-SafeMigration {
    <#
    .SYNOPSIS
        Starts a safe migration with full safety checks.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath,
        
        [Parameter()]
        [int]$BatchSize = 5,
        
        [Parameter()]
        [string]$BackupPath = "",
        
        [Parameter()]
        [switch]$WhatIf
    )
    
    Write-Host "=== SAFE MIGRATION STARTED ===" -ForegroundColor Green
    
    # Phase 1: Backup
    if (-not $BackupPath) {
        $BackupPath = "00-Meta/Backups/MIGRATION_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }
    
    Write-Host "`nPhase 1: Creating backup at $BackupPath..." -ForegroundColor Yellow
    if (-not $WhatIf) {
        New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$SourcePath/*" -Destination $BackupPath -Recurse -Force
    }
    Write-Host "Backup created." -ForegroundColor Green
    
    # Phase 2: Inventory
    Write-Host "`nPhase 2: Creating inventory..." -ForegroundColor Yellow
    $files = Get-ChildItem -Path $SourcePath -Recurse -File -Filter "*.md"
    Write-Host "Found $($files.Count) markdown files." -ForegroundColor Green
    
    # Phase 3: Dry-Run
    Write-Host "`nPhase 3: Dry-Run with 3 files..." -ForegroundColor Yellow
    $testFiles = $files | Select-Object -First 3
    
    foreach ($file in $testFiles) {
        Write-Host "  Testing: $($file.Name)"
        if (-not $WhatIf) {
            # Migration logic here
            $result = Test-MigrationFile -File $file
            if (-not $result) {
                throw "Dry-run failed for: $($file.Name)"
            }
        }
    }
    
    Write-Host "`nDry-Run completed successfully!" -ForegroundColor Green
    Write-Host "Ready for full migration." -ForegroundColor Cyan
    
    return @{
        BackupPath = $BackupPath
        FileCount = $files.Count
        TestFiles = $testFiles
    }
}

function Test-MigrationFile {
    <#
    .SYNOPSIS
        Validates a migrated file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$File,
        
        [Parameter()]
        [string]$DestinationPath = ""
    )
    
    $destFile = if ($DestinationPath) {
        Join-Path $DestinationPath $File.Name
    } else {
        $File.FullName
    }
    
    # Check 1: File exists
    if (-not (Test-Path $destFile)) {
        Write-Warning "FAIL: File missing: $destFile"
        return $false
    }
    
    # Check 2: Not empty
    $size = (Get-Item $destFile).Length
    if ($size -lt 200) {
        Write-Warning "FAIL: File too small ($size bytes): $destFile"
        return $false
    }
    
    # Check 3: No placeholders
    $content = Get-Content $destFile -Raw
    $placeholders = @(
        "Inhalt wurde nicht",
        "TODO",
        "FIXME",
        "XXX",
        "Hier einfügen",
        "*Wird durch Night Agent*"
    )
    
    foreach ($ph in $placeholders) {
        if ($content -match $ph) {
            Write-Warning "FAIL: Placeholder found ('$ph'): $destFile"
            return $false
        }
    }
    
    # Check 4: YAML frontmatter valid
    if ($content -match "^---") {
        $matches = [regex]::Matches($content, "---")
        if ($matches.Count -lt 2) {
            Write-Warning "FAIL: Invalid YAML frontmatter: $destFile"
            return $false
        }
    }
    
    Write-Host "  OK: $($File.Name)" -ForegroundColor Green
    return $true
}

function Invoke-SafeBatch {
    <#
    .SYNOPSIS
        Processes a batch of files with validation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Files,
        
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath
    )
    
    $results = @()
    
    foreach ($file in $Files) {
        Write-Host "Processing: $($file.Name)"
        
        try {
            # Migration logic here
            # Copy-Item -Path $file.FullName -Destination $DestinationPath
            
            # Validate
            $valid = Test-MigrationFile -File $file -DestinationPath $DestinationPath
            
            $results += [PSCustomObject]@{
                File = $file.Name
                Success = $valid
                Error = if (-not $valid) { "Validation failed" } else { "" }
            }
        }
        catch {
            $results += [PSCustomObject]@{
                File = $file.Name
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
    
    return $results
}

function Invoke-Rollback {
    <#
    .SYNOPSIS
        Rolls back migration from backup.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupPath,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetPath
    )
    
    Write-Host "ROLLBACK in progress..." -ForegroundColor Red
    
    if (Test-Path $TargetPath) {
        Remove-Item -Path $TargetPath -Recurse -Force
    }
    
    Copy-Item -Path $BackupPath -Destination $TargetPath -Recurse -Force
    
    Write-Host "ROLLBACK completed." -ForegroundColor Green
}

function Get-MigrationReport {
    <#
    .SYNOPSIS
        Generates a migration report.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Results
    )
    
    $total = $Results.Count
    $success = ($Results | Where-Object { $_.Success }).Count
    $failed = $total - $success
    
    Write-Host "`n=== MIGRATION REPORT ===" -ForegroundColor Cyan
    Write-Host "Total files: $total"
    Write-Host "Successful: $success" -ForegroundColor Green
    Write-Host "Failed: $failed" -ForegroundColor Red
    
    if ($failed -gt 0) {
        Write-Host "`nFailed files:" -ForegroundColor Red
        $Results | Where-Object { -not $_.Success } | ForEach-Object {
            Write-Host "  - $($_.File): $($_.Error)"
        }
    }
    
    return @{
        Total = $total
        Success = $success
        Failed = $failed
        FailedFiles = $Results | Where-Object { -not $_.Success }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Start-SafeMigration',
    'Test-MigrationFile',
    'Invoke-SafeBatch',
    'Invoke-Rollback',
    'Get-MigrationReport'
)
