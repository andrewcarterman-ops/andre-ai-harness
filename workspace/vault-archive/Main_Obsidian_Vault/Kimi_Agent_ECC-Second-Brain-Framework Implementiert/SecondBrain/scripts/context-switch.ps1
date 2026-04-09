#Requires -Version 5.1
<#
.SYNOPSIS
    Context Switch für ECC Second Brain

.DESCRIPTION
    Überwacht Token-Usage und führt Context-Komprimierung durch.
    Unterstützt Session-Checkpointing und Smart Context-Compression.

.PARAMETER VaultPath
    Pfad zum Vault

.PARAMETER ConfigPath
    Pfad zur Config

.PARAMETER CurrentUsage
    Aktuelle Token-Usage in Prozent

.PARAMETER Force
    Context-Switch erzwingen

.EXAMPLE
    .\context-switch.ps1 -CurrentUsage 85
    .\context-switch.ps1 -Force

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
    [string]$ConfigPath = "config/stability-config.yaml",
    
    [Parameter(Mandatory = $false)]
    [int]$CurrentUsage = 0,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Script Variables
$script:Version = "1.0.0"
$script:Thresholds = @{
    warning = 70
    compression = 80
    emergency = 90
}

#region Functions

function Write-ContextLog {
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

function Import-ContextConfig {
    param([string]$Path)
    
    if (Test-Path $Path) {
        # Load from YAML
        return @{
            thresholds = $script:Thresholds
            compression = @{
                enabled = $true
                ratio = 0.5
            }
        }
    }
    
    return @{
        thresholds = $script:Thresholds
        compression = @{
            enabled = $true
            ratio = 0.5
        }
    }
}

function Test-ContextThreshold {
    param(
        [int]$Usage,
        [hashtable]$Thresholds
    )
    
    if ($Usage -ge $Thresholds.emergency) {
        return "emergency"
    }
    elseif ($Usage -ge $Thresholds.compression) {
        return "compression"
    }
    elseif ($Usage -ge $Thresholds.warning) {
        return "warning"
    }
    
    return "normal"
}

function Invoke-ContextCompression {
    param([string]$VaultPath)
    
    Write-ContextLog "Compressing context..." -Level "INFO"
    
    # Create checkpoint
    $checkpointDir = Join-Path $VaultPath ".checkpoints"
    if (!(Test-Path $checkpointDir)) {
        New-Item -ItemType Directory -Path $checkpointDir -Force | Out-Null
    }
    
    $checkpointFile = Join-Path $checkpointDir "checkpoint_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    
    # Get recent sessions
    $dailyPath = Join-Path $VaultPath "05-Daily"
    $sessions = Get-ChildItem $dailyPath -Filter "*.md" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    
    $checkpoint = @{
        timestamp = Get-Date -Format "o"
        sessions = $sessions.Name
        decisions = @()
        todos = @()
        insights = @()
    }
    
    # Extract key information
    foreach ($session in $sessions) {
        $content = Get-Content $session.FullName -Raw
        
        # Extract decisions
        if ($content -match "## Key Decisions.*?(?=##|\z)") {
            $decisions = $Matches[0] -split "`n" | Where-Object { $_ -match "^- \*\*Decision\*\*" }
            $checkpoint.decisions += $decisions
        }
        
        # Extract TODOs
        if ($content -match "## Open TODOs.*?(?=##|\z)") {
            $todos = $Matches[0] -split "`n" | Where-Object { $_ -match "^- \[ \]" }
            $checkpoint.todos += $todos
        }
        
        # Extract insights
        if ($content -match "## Insights & Learnings.*?(?=##|\z)") {
            $insights = $Matches[0] -split "`n" | Where-Object { $_ -match "^- " }
            $checkpoint.insights += $insights
        }
    }
    
    # Save checkpoint
    $checkpoint | ConvertTo-Json -Depth 10 | Set-Content $checkpointFile -Encoding UTF8
    
    Write-ContextLog "Context compressed to: $checkpointFile" -Level "SUCCESS"
    
    return $checkpoint
}

function Invoke-EmergencyContextSwitch {
    param([string]$VaultPath)
    
    Write-ContextLog "EMERGENCY: Token usage critical!" -Level "ERROR"
    
    # Create emergency checkpoint
    $checkpoint = Invoke-ContextCompression -VaultPath $VaultPath
    
    # Create session summary
    $summaryFile = Join-Path $VaultPath "05-Daily" "EMERGENCY_SUMMARY_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    $summary = @"
---
type: "emergency_summary"
date: "$(Get-Date -Format "o")"
---

# Emergency Context Summary

## Key Decisions
$($checkpoint.decisions -join "`n")

## Open TODOs
$($checkpoint.todos -join "`n")

## Insights
$($checkpoint.insights -join "`n")

---
*Emergency context switch triggered*
"@
    
    $summary | Set-Content $summaryFile -Encoding UTF8
    
    Write-ContextLog "Emergency summary created: $summaryFile" -Level "SUCCESS"
}

#endregion

#region Main

Write-ContextLog "=== ECC Context Switch v$script:Version ===" -Level "INFO"

# Load config
$config = Import-ContextConfig -Path $ConfigPath

# Check thresholds
if ($Force) {
    Write-ContextLog "Force context switch triggered" -Level "WARN"
    Invoke-ContextCompression -VaultPath $VaultPath
}
elseif ($CurrentUsage -gt 0) {
    $status = Test-ContextThreshold -Usage $CurrentUsage -Thresholds $config.thresholds
    
    switch ($status) {
        "normal" {
            Write-ContextLog "Token usage normal: $CurrentUsage%" -Level "INFO"
        }
        "warning" {
            Write-ContextLog "Token usage warning: $CurrentUsage% - Consider context switch soon" -Level "WARN"
        }
        "compression" {
            Write-ContextLog "Token usage high: $CurrentUsage% - Compressing context" -Level "WARN"
            Invoke-ContextCompression -VaultPath $VaultPath
        }
        "emergency" {
            Invoke-EmergencyContextSwitch -VaultPath $VaultPath
        }
    }
}
else {
    Write-ContextLog "No usage data provided, monitoring mode" -Level "INFO"
}

#endregion
