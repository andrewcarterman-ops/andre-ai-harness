#!/usr/bin/env pwsh
# Drift Doctor Check Script
# Vergleicht Ist-Zustand mit Install-Manifest

param(
    [string]$ManifestPath = registry/install-manifest.yaml,
    [string]$OutputPath = memory/drift/,
    [switch]$Fix,
    [switch]$Verbose
)

$ErrorActionPreference = Stop
$timestamp = Get-Date -Format yyyyMMdd-HHmmss
$driftReport = @{
    timestamp = $timestamp
    drifts = @()
    summary = @{
        critical = 0
        warning = 0
        info = 0
        total = 0
    }
}

# Farben
$Colors = @{
    Success = Green
    Warning = Yellow
    Error = Red
    Info = Cyan
}

function Write-Drift($Type, $Path, $Expected, $Actual, $Severity) {
    $symbol = switch ($Severity) {
        critical { âŒ }
        warning { âš ï¸ }
        info { â„¹ï¸ }
        default { â€¢ }
    }
    
    $color = switch ($Severity) {
        critical { $Colors.Error }
        warning { $Colors.Warning }
        info { $Colors.Info }
        default { White }
    }
    
    Write-Host $symbol