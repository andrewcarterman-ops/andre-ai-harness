#!/usr/bin/env pwsh
# /verify Command
# Verifiziert Installation und Konfiguration

param(
    [switch]$Fix,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Import-Module "$workspaceRoot/scripts/lib/Logging.psm1" -Force
Initialize-Logging -Component "verify"

$checks = @{
    Passed = 0
    Failed = 0
    Warnings = 0
}

function Write-CheckResult($Name, $Status, $Message = "") {
    $symbol = switch ($Status) {
        "PASS" { "✅" }
        "FAIL" { "❌" }
        "WARN" { "⚠️" }
    }
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
    }
    
    Write-Host "$symbol $Name" -ForegroundColor $color
    if ($Message -and $Verbose) {
        Write-Host "   $Message" -ForegroundColor Gray
    }
    
    $checks[$Status.ToLower() + "ed"]++
}

Write-InfoLog -Message "Starting verification" -Console

# Check 1: Registry files
Write-Host "`n📋 Registry Files:" -ForegroundColor Cyan
$registryFiles = @(
    "registry/agents.yaml",
    "registry/skills.yaml",
    "registry/hooks.yaml",
    "registry/projects.yaml",
    "registry/search-index.json"
)

foreach ($file in $registryFiles) {
    $path = Join-Path $workspaceRoot $file
    if (Test-Path $path) {
        Write-CheckResult $file "PASS"
    } else {
        Write-CheckResult $file "FAIL" "File missing"
    }
}

# Check 2: YAML validity
Write-Host "`n📄 YAML Validity:" -ForegroundColor Cyan
$yamlFiles = Get-ChildItem "$workspaceRoot/registry/*.yaml"
foreach ($file in $yamlFiles) {
    try {
        $content = Get-Content $file.FullName -Raw
        # Simple check
        if ($content -match "^\s*\w+:") {
            Write-CheckResult $file.Name "PASS"
        } else {
            Write-CheckResult $file.Name "WARN" "May be invalid"
        }
    } catch {
        Write-CheckResult $file.Name "FAIL" $_.Exception.Message
    }
}

# Check 3: Skills exist
Write-Host "`n🎯 Skills:" -ForegroundColor Cyan
$skillsYaml = Get-Content "$workspaceRoot/registry/skills.yaml" -Raw
$skillMatches = [regex]::Matches($skillsYaml, 'id:\s*"([^"]+)"')
$skillIds = $skillMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

foreach ($skillId in $skillIds) {
    $skillPath = Join-Path $workspaceRoot "skills/$skillId/SKILL.md"
    if (Test-Path $skillPath) {
        Write-CheckResult $skillId "PASS"
    } else {
        Write-CheckResult $skillId "FAIL" "SKILL.md not found"
    }
}

# Check 4: Agents exist
Write-Host "`n👤 Agents:" -ForegroundColor Cyan
$agentFiles = Get-ChildItem "$workspaceRoot/agents/*.md" -ErrorAction SilentlyContinue
if ($agentFiles) {
    foreach ($agent in $agentFiles) {
        Write-CheckResult $agent.Name "PASS"
    }
} else {
    Write-CheckResult "agents/" "WARN" "No agents found"
}

# Check 5: Scripts executable
Write-Host "`n🔧 Scripts:" -ForegroundColor Cyan
$scripts = Get-ChildItem "$workspaceRoot/scripts/*.ps1" -ErrorAction SilentlyContinue
if ($scripts.Count -gt 0) {
    Write-CheckResult "Scripts directory" "PASS" "$($scripts.Count) scripts found"
} else {
    Write-CheckResult "Scripts directory" "WARN" "No scripts found"
}

# Summary
Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "Passed:  $($checks.passed)" -ForegroundColor Green
Write-Host "Failed:  $($checks.failed)" -ForegroundColor Red
Write-Host "Warnings: $($checks.warnings)" -ForegroundColor Yellow

if ($checks.failed -gt 0) {
    Write-ErrorLog -Message "Verification failed with $($checks.failed) errors"
    exit 1
} else {
    Write-InfoLog -Message "Verification completed successfully" -Console
    exit 0
}
