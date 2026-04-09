#Requires -Version 5.1
<#
.SYNOPSIS
    Drift Detection für ECC Second Brain Vault

.DESCRIPTION
    Erkennt Abweichungen in der Vault-Struktur vom Referenz-Manifest.
    Unterstützt Auto-Fix und Report-Generierung.

.PARAMETER VaultPath
    Pfad zum Vault

.PARAMETER ConfigPath
    Pfad zur Drift-Config

.PARAMETER AutoFix
    Automatisch korrigieren

.PARAMETER ReportPath
    Pfad zum Report

.EXAMPLE
    .\drift-detection.ps1
    .\drift-detection.ps1 -AutoFix
    .\drift-detection.ps1 -ReportPath ".logs/drift-report.md"

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
    [string]$ConfigPath = "config/drift-config.yaml",
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoFix,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = ".logs/drift-report.md"
)

# Script Variables
$script:Version = "1.0.0"
$script:DriftResults = @{
    timestamp = Get-Date -Format "o"
    vaultPath = $VaultPath
    issues = @()
    fixed = @()
    summary = @{
        total = 0
        critical = 0
        warning = 0
        fixed = 0
    }
}

#region Functions

function Write-DriftLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG"   { Write-Verbose $logEntry }
    }
}

function Import-DriftConfig {
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        Write-DriftLog "Config not found, using defaults: $Path" -Level "WARN"
        return @{
            required_folders = @()
            required_files = @()
        }
    }
    
    # Simple YAML parsing
    $config = @{
        required_folders = @(
            "00-Inbox", "01-Projects", "02-Areas", "03-Resources",
            "04-Archive", "05-Daily", "scripts", "config", ".obsidian"
        )
        required_files = @(
            "README.md", "Setup-SecondBrain.ps1",
            "scripts/lib/ErrorHandler.psm1",
            ".obsidian/plugins/ecc-vault/manifest.json"
        )
    }
    
    return $config
}

function Test-FolderStructure {
    param([array]$RequiredFolders)
    
    $issues = @()
    
    foreach ($folder in $RequiredFolders) {
        $fullPath = Join-Path $VaultPath $folder
        $exists = Test-Path $fullPath
        
        if (!$exists) {
            $issues += [PSCustomObject]@{
                type = "folder"
                path = $folder
                severity = "critical"
                message = "Missing required folder: $folder"
                fixable = $true
            }
        }
    }
    
    return $issues
}

function Test-RequiredFiles {
    param([array]$RequiredFiles)
    
    $issues = @()
    
    foreach ($file in $RequiredFiles) {
        $fullPath = Join-Path $VaultPath $file
        $exists = Test-Path $fullPath
        
        if (!$exists) {
            $issues += [PSCustomObject]@{
                type = "file"
                path = $file
                severity = "critical"
                message = "Missing required file: $file"
                fixable = $false
            }
        }
    }
    
    return $issues
}

function Invoke-AutoFix {
    param([array]$Issues)
    
    $fixed = @()
    
    foreach ($issue in $Issues) {
        if (!$issue.fixable) {
            Write-DriftLog "Cannot auto-fix: $($issue.message)" -Level "WARN"
            continue
        }
        
        switch ($issue.type) {
            "folder" {
                $fullPath = Join-Path $VaultPath $issue.path
                try {
                    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                    $fixed += $issue
                    Write-DriftLog "Created folder: $($issue.path)" -Level "SUCCESS"
                }
                catch {
                    Write-DriftLog "Failed to create folder: $($issue.path) - $_" -Level "ERROR"
                }
            }
            "file" {
                # Files typically cannot be auto-fixed
                Write-DriftLog "File issue requires manual fix: $($issue.path)" -Level "WARN"
            }
        }
    }
    
    return $fixed
}

function Export-DriftReport {
    param(
        [hashtable]$Results,
        [string]$Path
    )
    
    $outputDir = Split-Path $Path -Parent
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $report = @"
# Drift Detection Report

**Timestamp**: $($Results.timestamp)
**Vault Path**: $($Results.vaultPath)

## Summary

| Metric | Value |
|--------|-------|
| Total Issues | $($Results.summary.total) |
| Critical | $($Results.summary.critical) |
| Warning | $($Results.summary.warning) |
| Fixed | $($Results.summary.fixed) |

## Issues

"@
    
    if ($Results.issues.Count -eq 0) {
        $report += "`n✅ No drift detected!`n"
    }
    else {
        foreach ($issue in $Results.issues) {
            $icon = if ($issue.severity -eq "critical") { "🔴" } else { "🟡" }
            $report += "`n### $icon $($issue.type): $($issue.path)`n`n"
            $report += "- **Severity**: $($issue.severity)`n"
            $report += "- **Message**: $($issue.message)`n"
            $report += "- **Fixable**: $($issue.fixable)`n"
        }
    }
    
    if ($Results.fixed.Count -gt 0) {
        $report += "`n## Fixed Issues`n`n"
        foreach ($fixed in $Results.fixed) {
            $report += "- ✅ $($fixed.path)`n"
        }
    }
    
    $report += "`n---`n`n*Generated by ECC Drift Detection v$script:Version*"
    
    $report | Set-Content $Path -Encoding UTF8
    Write-DriftLog "Report exported: $Path" -Level "SUCCESS"
}

#endregion

#region Main

Write-DriftLog "=== ECC Drift Detection v$script:Version ===" -Level "INFO"
Write-DriftLog "Vault: $VaultPath" -Level "INFO"

# Load config
$config = Import-DriftConfig -Path $ConfigPath

# Check folder structure
Write-DriftLog "Checking folder structure..." -Level "INFO"
$folderIssues = Test-FolderStructure -RequiredFolders $config.required_folders
$script:DriftResults.issues += $folderIssues

# Check required files
Write-DriftLog "Checking required files..." -Level "INFO"
$fileIssues = Test-RequiredFiles -RequiredFiles $config.required_files
$script:DriftResults.issues += $fileIssues

# Calculate summary
$script:DriftResults.summary.total = $script:DriftResults.issues.Count
$script:DriftResults.summary.critical = ($script:DriftResults.issues | Where-Object { $_.severity -eq "critical" }).Count
$script:DriftResults.summary.warning = ($script:DriftResults.issues | Where-Object { $_.severity -eq "warning" }).Count

# Auto-fix if requested
if ($AutoFix -and $script:DriftResults.issues.Count -gt 0) {
    Write-DriftLog "Auto-fixing issues..." -Level "INFO"
    $fixed = Invoke-AutoFix -Issues $script:DriftResults.issues
    $script:DriftResults.fixed = $fixed
    $script:DriftResults.summary.fixed = $fixed.Count
}

# Export report
Export-DriftReport -Results $script:DriftResults -Path $ReportPath

# Summary
Write-DriftLog "" -Level "INFO"
Write-DriftLog "=== Drift Detection Summary ===" -Level "INFO"
Write-DriftLog "Total Issues: $($script:DriftResults.summary.total)" -Level $(if ($script:DriftResults.summary.total -eq 0) { "SUCCESS" } else { "WARN" })
Write-DriftLog "Critical: $($script:DriftResults.summary.critical)" -Level $(if ($script:DriftResults.summary.critical -eq 0) { "SUCCESS" } else { "ERROR" })
Write-DriftLog "Fixed: $($script:DriftResults.summary.fixed)" -Level "SUCCESS"

# Exit code
if ($script:DriftResults.summary.critical -eq 0) {
    exit 0
}
else {
    exit 1
}

#endregion
