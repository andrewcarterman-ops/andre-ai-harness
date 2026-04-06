#!/usr/bin/env pwsh
# /whoami Command
# Show current agent context and capabilities

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Write-Host "`n🤖 Agent Identity" -ForegroundColor Cyan
Write-Host "==================`n" -ForegroundColor Cyan

# Read agent config
$agentsYaml = Get-Content "$workspaceRoot/registry/agents.yaml" -Raw

# Current agent
if ($agentsYaml -match 'id:\s*"(andrew-main)"') {
    Write-Host "Name: Andrew" -ForegroundColor Green
    Write-Host "ID: andrew-main" -ForegroundColor Gray
    Write-Host "Type: Main Agent" -ForegroundColor Gray
}

# Capabilities
if ($agentsYaml -match 'capabilities:\s*([\s\S]+?)(?=\n\w|\Z)') {
    $caps = $matches[1] -split '\n' | 
        Where-Object { $_ -match '-\s*(\w+)' } | 
        ForEach-Object { $matches[1] }
    
    Write-Host "`nCapabilities:" -ForegroundColor Yellow
    $caps | ForEach-Object { Write-Host "  • $_" }
}

# Context
$contextFile = "$workspaceRoot/memory/current-context.md"
if (Test-Path $contextFile) {
    $context = Get-Content $contextFile -Raw
    if ($context -match 'Context:\s*\*\*(.+?)\*\*') {
        Write-Host "`nCurrent Context: $($matches[1])" -ForegroundColor Yellow
    }
}

# Available skills
Write-Host "`nAvailable Skills:" -ForegroundColor Yellow
$skills = Get-Content "$workspaceRoot/registry/skills.yaml" -Raw
$skillMatches = [regex]::Matches($skills, 'id:\s*"([^"]+)"')
$skillMatches | ForEach-Object { 
    $name = $_.Groups[1].Value
    if ($name -notmatch '-') {  # Filter out sub-matches
        Write-Host "  • $name" -ForegroundColor Gray
    }
}

# System status
Write-Host "`nSystem Status:" -ForegroundColor Yellow
Write-Host "  Registry: ✅ Loaded" -ForegroundColor Green
Write-Host "  Session: ✅ Active" -ForegroundColor Green

Write-Host "`n==================" -ForegroundColor Cyan
