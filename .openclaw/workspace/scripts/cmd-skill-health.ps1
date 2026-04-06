#!/usr/bin/env pwsh
# /skill-health Command
# Check health of all skills

param(
    [switch]$Fix,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Write-Host "🏥 Skill Health Check" -ForegroundColor Cyan

$skillsDir = "$workspaceRoot/skills"
$issues = @()

Get-ChildItem $skillsDir -Directory | ForEach-Object {
    $skillName = $_.Name
    $skillPath = $_.FullName
    $skillFile = "$skillPath/SKILL.md"
    
    Write-Host "`n  Checking: $skillName" -ForegroundColor Gray
    
    # Check SKILL.md exists
    if (-not (Test-Path $skillFile)) {
        $issues += [PSCustomObject]@{ Skill = $skillName; Issue = "Missing SKILL.md"; Severity = "Error" }
        Write-Host "    ❌ Missing SKILL.md" -ForegroundColor Red
        return
    }
    
    $content = Get-Content $skillFile -Raw
    
    # Check frontmatter
    if (-not ($content -match "^---")) {
        $issues += [PSCustomObject]@{ Skill = $skillName; Issue = "No frontmatter"; Severity = "Warning" }
        Write-Host "    ⚠️  No frontmatter" -ForegroundColor Yellow
    } else {
        Write-Host "    ✅ Has frontmatter" -ForegroundColor Green
    }
    
    # Check required sections
    $required = @("description", "trigger")
    foreach ($req in $required) {
        if (-not ($content -match $req)) {
            $issues += [PSCustomObject]@{ Skill = $skillName; Issue = "Missing $req"; Severity = "Warning" }
            Write-Host "    ⚠️  Missing: $req" -ForegroundColor Yellow
        }
    }
    
    # Check examples
    if ($content -match "```") {
        Write-Host "    ✅ Has code examples" -ForegroundColor Green
    } else {
        Write-Host "    ⚠️  No code examples" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n📊 Health Report:" -ForegroundColor Cyan

$errors = $issues | Where-Object { $_.Severity -eq "Error" }
$warnings = $issues | Where-Object { $_.Severity -eq "Warning" }

Write-Host "  Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { "Red" } else { "Green" })
Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -gt 0) { "Yellow" } else { "Green" })

if ($issues -and $Verbose) {
    Write-Host "`n  Issues:" -ForegroundColor Yellow
    $issues | Format-Table -AutoSize
}

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "`n✅ All skills healthy!" -ForegroundColor Green
    exit 0
} elseif ($errors.Count -eq 0) {
    Write-Host "`n⚠️  Some warnings (non-critical)" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n❌ Errors found" -ForegroundColor Red
    exit 1
}
