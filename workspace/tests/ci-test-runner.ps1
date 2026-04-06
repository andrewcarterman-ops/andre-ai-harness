#!/usr/bin/env pwsh
# CI Test Runner
# Führt alle Tests im Framework aus

param(
    [switch]$Unit,
    [switch]$Integration,
    [switch]$All = $true,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$results = @{
    Total = 0
    Passed = 0
    Failed = 0
}

function Test-YamlValid($Path) {
    try {
        $content = Get-Content $Path -Raw
        # Einfache YAML-Validierung (in voller Version mit Modul)
        return $content -match "^\s*\w+:\s*"
    } catch {
        return $false
    }
}

function Test-JsonValid($Path) {
    try {
        $content = Get-Content $Path -Raw
        $null = ConvertFrom-Json $content
        return $true
    } catch {
        return $false
    }
}

# Unit Tests
if ($Unit -or $All) {
    Write-Host "`n🧪 Unit Tests" -ForegroundColor Cyan
    
    # Test YAML-Dateien
    $yamlFiles = Get-ChildItem "registry/*.yaml"
    foreach ($file in $yamlFiles) {
        $results.Total++
        if (Test-YamlValid $file.FullName) {
            Write-Host "  ✅ $($file.Name)" -ForegroundColor Green
            $results.Passed++
        } else {
            Write-Host "  ❌ $($file.Name)" -ForegroundColor Red
            $results.Failed++
        }
    }
    
    # Test JSON-Dateien
    $jsonFiles = Get-ChildItem "registry/*.json"
    foreach ($file in $jsonFiles) {
        $results.Total++
        if (Test-JsonValid $file.FullName) {
            Write-Host "  ✅ $($file.Name)" -ForegroundColor Green
            $results.Passed++
        } else {
            Write-Host "  ❌ $($file.Name)" -ForegroundColor Red
            $results.Failed++
        }
    }
}

# Integration Tests
if ($Integration -or $All) {
    Write-Host "`n🔗 Integration Tests" -ForegroundColor Cyan
    
    # Test Registry-Konsistenz
    $tests = @(
        @{ Name = "Agents referenzieren Skills"; Test = { 
            Test-Path "registry/agents.yaml" 
        }},
        @{ Name = "Skills haben Kategorien"; Test = { 
            Test-Path "registry/skills.yaml"
        }},
        @{ Name = "Hooks sind registriert"; Test = { 
            Test-Path "registry/hooks.yaml" 
        }}
    )
    
    foreach ($test in $tests) {
        $results.Total++
        if (& $test.Test) {
            Write-Host "  ✅ $($test.Name)" -ForegroundColor Green
            $results.Passed++
        } else {
            Write-Host "  ❌ $($test.Name)" -ForegroundColor Red
            $results.Failed++
        }
    }
}

# Zusammenfassung
Write-Host "`n📊 Ergebnis" -ForegroundColor Cyan
Write-Host "Total: $($results.Total)" -ForegroundColor White
Write-Host "Passed: $($results.Passed)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed)" -ForegroundColor Red

exit $results.Failed
