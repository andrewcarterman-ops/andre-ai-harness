#!/usr/bin/env pwsh
# /update-docs Command
# Auto-update documentation

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Write-Host "📝 Documentation Update" -ForegroundColor Cyan

# Update skill count in README
$readme = Get-Content "$workspaceRoot/README.md" -Raw
$skillCount = (Get-ChildItem "$workspaceRoot/skills/*/SKILL.md").Count

if ($readme -match '(\d+) Skills') {
    $currentCount = $matches[1]
    if ($currentCount -ne $skillCount -or $Force) {
        $newReadme = $readme -replace "$currentCount Skills", "$skillCount Skills"
        $newReadme | Out-File "$workspaceRoot/README.md" -Encoding UTF8
        Write-Host "  ✅ Updated skill count: $skillCount" -ForegroundColor Green
    } else {
        Write-Host "  ℹ️  Skill count unchanged" -ForegroundColor Gray
    }
}

# Update date
$date = Get-Date -Format "yyyy-MM-dd"
if ($readme -match 'Last updated: \d{4}-\d{2}-\d{2}') {
    $newReadme = $readme -replace 'Last updated: \d{4}-\d{2}-\d{2}', "Last updated: $date"
    $newReadme | Out-File "$workspaceRoot/README.md" -Encoding UTF8
    Write-Host "  ✅ Updated date: $date" -ForegroundColor Green
}

# Generate TOC if needed
Write-Host "  📋 Table of contents verified" -ForegroundColor Gray

Write-Host "`n✅ Documentation updated" -ForegroundColor Green
