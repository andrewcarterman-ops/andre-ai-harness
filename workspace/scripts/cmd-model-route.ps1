#!/usr/bin/env pwsh
# /model-route Command
# Wählt das optimale Model für die aktuelle Aufgabe

param(
    [string]$Task,
    [switch]$List
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Import-Module "$workspaceRoot/scripts/lib/Logging.psm1" -Force
Initialize-Logging -Component "model-route"

# Model-Profile
$models = @{
    fast = @{
        name = "kimi-coding/k2p5"
        description = "Fast responses, lower cost"
        bestFor = @("simple queries", "file operations", "quick checks")
        contextWindow = 128000
    }
    thinking = @{
        name = "kimi-coding/kimi-k2-thinking"
        description = "Deep reasoning, complex tasks"
        bestFor = @("architecture", "planning", "debugging", "analysis")
        contextWindow = 128000
    }
    coding = @{
        name = "kimi-coding/k2p5"
        description = "Code generation and review"
        bestFor = @("code writing", "refactoring", "code review")
        contextWindow = 128000
    }
}

if ($List) {
    Write-Host "`n🤖 Available Models:" -ForegroundColor Cyan
    $models.GetEnumerator() | ForEach-Object {
        Write-Host "`n  $($_.Key):" -ForegroundColor Yellow
        Write-Host "    Model: $($_.Value.name)" -ForegroundColor White
        Write-Host "    $($_.Value.description)" -ForegroundColor Gray
        Write-Host "    Best for: $($_.Value.bestFor -join ', ')" -ForegroundColor Gray
    }
    exit 0
}

# Auto-routing basierend auf Task
$recommended = "thinking"  # Default

if ($Task) {
    $taskLower = $Task.ToLower()
    
    if ($taskLower -match "quick|fast|simple|check") {
        $recommended = "fast"
    }
    elseif ($taskLower -match "code|program|script|function") {
        $recommended = "coding"
    }
    elseif ($taskLower -match "architecture|design|plan|analyze|debug") {
        $recommended = "thinking"
    }
    
    Write-Host "`n🎯 Task: $Task" -ForegroundColor Cyan
    Write-Host "📌 Recommended: $recommended ($($models[$recommended].name))" -ForegroundColor Green
    Write-Host "💡 $($models[$recommended].description)" -ForegroundColor Gray
}
else {
    Write-Host "`nCurrent: thinking" -ForegroundColor Cyan
    Write-Host "Use -Task 'description' for recommendation" -ForegroundColor Gray
}
