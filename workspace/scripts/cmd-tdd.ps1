#!/usr/bin/env pwsh
# /tdd Command
# Test-Driven Development workflow helper

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "test", "implement", "refactor", "cycle")]
    [string]$Phase,
    
    [string]$Feature
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Write-Host "`n🔄 TDD Workflow: $Phase" -ForegroundColor Cyan

switch ($Phase) {
    "start" {
        Write-Host "`n📝 TDD Cycle Started" -ForegroundColor Green
        Write-Host "Feature: $Feature" -ForegroundColor Yellow
        Write-Host "`nNext: Write a failing test" -ForegroundColor Cyan
        
        # Create feature branch or plan
        $plan = @"
# TDD Plan: $Feature

## Red Phase 🟥
- [ ] Write failing test
- [ ] Run test, confirm it fails

## Green Phase 🟩  
- [ ] Write minimal code to pass
- [ ] Run test, confirm it passes

## Refactor Phase 🟨
- [ ] Clean up code
- [ ] Ensure tests still pass

## Cycle Complete ✅
"@
        
        Write-Host "`n$plan" -ForegroundColor Gray
    }
    
    "test" {
        Write-Host "`n🟥 RED Phase: Write failing test" -ForegroundColor Red
        Write-Host "Principles:" -ForegroundColor Yellow
        Write-Host "  • Test behavior, not implementation"
        Write-Host "  • Start with assertion"
        Write-Host "  • Keep test small and focused"
        Write-Host "`nTemplate:" -ForegroundColor Cyan
        Write-Host @"
def test_$Feature():
    # Arrange
    input = ...
    
    # Act
    result = function(input)
    
    # Assert
    assert result == expected
"@
    }
    
    "implement" {
        Write-Host "`n🟩 GREEN Phase: Make test pass" -ForegroundColor Green
        Write-Host "Principles:" -ForegroundColor Yellow
        Write-Host "  • Write minimal code"
        Write-Host "  • Hardcode if needed"
        Write-Host "  • Just get it green"
    }
    
    "refactor" {
        Write-Host "`n🟨 REFACTOR Phase: Clean code" -ForegroundColor Yellow
        Write-Host "Checklist:" -ForegroundColor Yellow
        Write-Host "  [ ] Remove duplication"
        Write-Host "  [ ] Improve names"
        Write-Host "  [ ] Extract functions"
        Write-Host "  [ ] Run all tests"
    }
    
    "cycle" {
        Write-Host "`n♻️ Complete TDD Cycle" -ForegroundColor Cyan
        Write-Host "1. 🟥 Red  - Write failing test"
        Write-Host "2. 🟩 Green - Make it pass"
        Write-Host "3. 🟨 Refactor - Clean up"
        Write-Host "4. ♻️  Repeat"
    }
}
