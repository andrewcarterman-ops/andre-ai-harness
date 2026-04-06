#!/usr/bin/env pwsh
# /prune Command
# Cleanup and maintenance tasks

param(
    [ValidateSet("logs", "backups", "sessions", "all")]
    [string]$Target = "all",
    
    [int]$KeepDays = 30,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

$cutoff = (Get-Date).AddDays(-$KeepDays)
$totalFreed = 0

Write-Host "🧹 Pruning: $Target (older than $KeepDays days)" -ForegroundColor Cyan
if ($DryRun) { Write-Host "DRY RUN - No actual deletion" -ForegroundColor Yellow }

function Prune-Directory($Path, $Pattern, $Description) {
    if (-not (Test-Path $Path)) { return }
    
    $items = Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -lt $cutoff -and ($Pattern -eq "*" -or $_.Name -like $Pattern) }
    
    if (-not $items) {
        Write-Host "  $Description: Nothing to prune" -ForegroundColor Gray
        return
    }
    
    $size = ($items | Measure-Object -Property Length -Sum).Sum
    $count = $items.Count
    
    Write-Host "  $Description: $count items ($([math]::Round($size/1MB, 2)) MB)" -ForegroundColor $(if ($DryRun) { "Gray" } else { "Yellow" })
    
    if (-not $DryRun) {
        $items | Remove-Item -Force
        Write-Host "    ✅ Deleted" -ForegroundColor Green
    }
    
    return $size
}

if ($Target -in @("logs", "all"]) {
    $totalFreed += Prune-Directory "$workspaceRoot/memory/logs" "*" "Logs"
}

if ($Target -in @("backups", "all"]) {
    $totalFreed += Prune-Directory "$workspaceRoot/memory/backups" "*" "Backups"
}

if ($Target -in @("sessions", "all"]) {
    # Keep session index, only archive old ones
    $oldSessions = Get-ChildItem "$workspaceRoot/memory/sessions/SESSION-*.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
    
    if ($oldSessions -and -not $DryRun) {
        $archiveDir = "$workspaceRoot/memory/sessions/archive"
        if (-not (Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null }
        
        $oldSessions | Move-Item -Destination $archiveDir -Force
        Write-Host "  Sessions: $($oldSessions.Count) archived" -ForegroundColor Green
    }
}

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "Would free: $([math]::Round($totalFreed/1MB, 2)) MB" -ForegroundColor Yellow
} else {
    Write-Host "Freed: $([math]::Round($totalFreed/1MB, 2)) MB" -ForegroundColor Green
}
