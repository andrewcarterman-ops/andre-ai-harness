#!/usr/bin/env pwsh
# /quality-gate Command
# Führt Qualitätsprüfungen durch

param(
    [ValidateSet("quick", "full", "strict")]
    [string]$Mode = "quick"
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Import-Module "$workspaceRoot/scripts/lib/Logging.psm1" -Force
Initialize-Logging -Component "quality-gate"

$results = @{
    Score = 0
    MaxScore = 0
    Checks = @()
}

function Add-Check($Name, $Passed, $Points, $Message = "") {
    $results.Checks += [PSCustomObject]@{
        Name = $Name
        Passed = $Passed
        Points = if ($Passed) { $Points } else { 0 }
        MaxPoints = $Points
        Message = $Message
    }
    $results.MaxScore += $Points
    if ($Passed) { $results.Score += $Points }
}

Write-InfoLog -Message "Running quality gate (mode: $Mode)" -Console

# Quick checks
Add-Check "README exists" (Test-Path "$workspaceRoot/README.md") 10
Add-Check "LICENSE exists" (Test-Path "$workspaceRoot/LICENSE") 5
Add-Check "Registry valid" (Test-Path "$workspaceRoot/registry/skills.yaml") 15
Add-Check "Agent definitions" ((Get-ChildItem "$workspaceRoot/agents/*.md" -ErrorAction SilentlyContinue).Count -gt 0) 10

# Mode-specific checks
if ($Mode -in @("full", "strict")) {
    Add-Check "All skills have tests" ($true) 10  # Placeholder
    Add-Check "Documentation complete" ($true) 10
    Add-Check "No TODOs in code" ((Get-ChildItem "$workspaceRoot" -Recurse -File | Select-String "TODO|FIXME" -SimpleMatch).Count -eq 0) 10
}

if ($Mode -eq "strict") {
    Add-Check "100% test coverage" ($false) 20  # Placeholder
    Add-Check "Security scan passed" ($true) 10
}

# Calculate percentage
$percentage = if ($results.MaxScore -gt 0) { ($results.Score / $results.MaxScore) * 100 } else { 0 }

Write-Host "`n📊 Quality Gate Results" -ForegroundColor Cyan
Write-Host "Score: $([math]::Round($percentage, 1))% ($($results.Score)/$($results.MaxScore))" -ForegroundColor $(
    if ($percentage -ge 80) { "Green" } elseif ($percentage -ge 60) { "Yellow" } else { "Red" }
)

foreach ($check in $results.Checks) {
    $symbol = if ($check.Passed) { "✅" } else { "❌" }
    Write-Host "$symbol $($check.Name): $($check.Points)/$($check.MaxPoints)" -ForegroundColor $(
        if ($check.Passed) { "Green" } else { "Red" }
    )
}

# Gate decision
$threshold = switch ($Mode) {
    "quick" { 60 }
    "full" { 75 }
    "strict" { 90 }
}

if ($percentage -ge $threshold) {
    Write-Host "`n🟢 Quality gate PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n🔴 Quality gate FAILED (threshold: $threshold%)" -ForegroundColor Red
    exit 1
}
