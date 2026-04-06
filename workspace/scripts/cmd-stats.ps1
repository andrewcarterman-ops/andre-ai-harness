#!/usr/bin/env pwsh
# /stats Command
# Show framework statistics

param(
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Write-Host "`n📊 Framework Statistics" -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan

# Registry stats
Write-Host "Registry:" -ForegroundColor Yellow
$registryFiles = Get-ChildItem "$workspaceRoot/registry/*.yaml" -ErrorAction SilentlyContinue
Write-Host "  YAML files: $($registryFiles.Count)"

$skills = Get-Content "$workspaceRoot/registry/skills.yaml" -Raw
$skillCount = ([regex]::Matches($skills, '^\s+- id:')).Count
Write-Host "  Skills defined: $skillCount"

# Agents
$agentCount = (Get-ChildItem "$workspaceRoot/agents/*.md" -ErrorAction SilentlyContinue).Count
Write-Host "  Agents: $agentCount"

# Code stats
Write-Host "`nCode:" -ForegroundColor Yellow
$scripts = Get-ChildItem "$workspaceRoot/scripts/*.ps1" -Recurse -ErrorAction SilentlyContinue
Write-Host "  PowerShell scripts: $($scripts.Count)"

$totalLines = ($scripts | Get-Content | Measure-Object).Count
Write-Host "  Total lines: $totalLines"

# Skills
Write-Host "`nSkills:" -ForegroundColor Yellow
$skillDirs = Get-ChildItem "$workspaceRoot/skills/*" -Directory -ErrorAction SilentlyContinue
Write-Host "  Skill directories: $($skillDirs.Count)"

# Documentation
Write-Host "`nDocumentation:" -ForegroundColor Yellow
$docs = Get-ChildItem "$workspaceRoot/*.md" -ErrorAction SilentlyContinue
Write-Host "  Root docs: $($docs.Count)"

# Memory usage
Write-Host "`nStorage:" -ForegroundColor Yellow
$size = (Get-ChildItem $workspaceRoot -Recurse -File -ErrorAction SilentlyContinue | 
    Measure-Object -Property Length -Sum).Sum
Write-Host "  Total size: $([math]::Round($size/1KB, 2)) KB"

# Sessions
$sessions = Get-ChildItem "$workspaceRoot/memory/sessions/SESSION-*.json" -ErrorAction SilentlyContinue
Write-Host "  Sessions: $($sessions.Count)"

# Backups
$backups = Get-ChildItem "$workspaceRoot/memory/backups" -Directory -ErrorAction SilentlyContinue
Write-Host "  Backups: $($backups.Count)"

if ($Detailed) {
    Write-Host "`nDetailed Skill Breakdown:" -ForegroundColor Yellow
    $skillDirs | ForEach-Object {
        $hasReadme = Test-Path "$($_.FullName)/SKILL.md"
        $status = if ($hasReadme) { "✅" } else { "❌" }
        Write-Host "  $status $($_.Name)"
    }
}

Write-Host "`n========================" -ForegroundColor Cyan
