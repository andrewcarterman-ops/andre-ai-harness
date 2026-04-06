#!/usr/bin/env pwsh
# CI Eval Runner
# Führt alle Eval-Konfigurationen aus und erzeugt Reports

param(
    [ValidateSet("all", "phase1", "phase2", "phase3", "phase4", "integration")]
    [string]$Suite = "all",
    
    [switch]$FailFast,
    [switch]$GenerateReport,
    [switch]$CI  # Im CI-Modus: Exit-Codes für Build-Status
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Import-Module "$workspaceRoot/scripts/lib/Logging.psm1" -Force
Import-Module "$workspaceRoot/scripts/lib/ErrorHandler.psm1" -Force

Initialize-Logging -Component "eval-runner"
Initialize-ErrorHandling

$results = @{
    startTime = Get-Date
    suites = @{}
    total = @{ passed = 0; failed = 0; skipped = 0 }
}

function Test-YamlValid($Path) {
    try {
        $content = Get-Content $Path -Raw
        # Einfache YAML-Prüfung
        return $content -match "^\s*\w+:\s*"
    } catch { return $false }
}

function Test-JsonValid($Path) {
    try {
        $content = Get-Content $Path -Raw
        $null = ConvertFrom-Json $content
        return $true
    } catch { return $false }
}

function Test-FileExists($Path, $Required = $true) {
    $fullPath = Join-Path $workspaceRoot $Path
    $exists = Test-Path $fullPath
    
    if ($exists) { return @{ status = "PASSED"; message = "File exists" } }
    if ($Required) { return @{ status = "FAILED"; message = "File missing: $Path" } }
    return @{ status = "SKIPPED"; message = "Optional file missing" }
}

function Test-RegistryConsistency {
    $issues = @()
    
    # Prüfe ob Skills in Registry existieren
    $skillsYaml = Get-Content (Join-Path $workspaceRoot "registry/skills.yaml") -Raw
    $skillsInRegistry = [regex]::Matches($skillsYaml, 'id:\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
    
    foreach ($skillId in $skillsInRegistry) {
        $skillPath = Join-Path $workspaceRoot "skills/$skillId/SKILL.md"
        if (-not (Test-Path $skillPath)) {
            $issues += "Skill '$skillId' in registry but file missing"
        }
    }
    
    return $issues
}

function Run-EvalSuite {
    param([string]$SuiteName)
    
    Write-InfoLog -Message "Running eval suite: $SuiteName" -Console
    
    $suiteResults = @{
        name = $SuiteName
        tests = @()
        passed = 0
        failed = 0
        skipped = 0
    }
    
    $tests = switch ($SuiteName) {
        "phase1" {
            @(
                @{ name = "agents.yaml exists"; test = { Test-FileExists "registry/agents.yaml" } },
                @{ name = "skills.yaml exists"; test = { Test-FileExists "registry/skills.yaml" } },
                @{ name = "hooks.yaml exists"; test = { Test-FileExists "registry/hooks.yaml" } },
                @{ name = "agents.yaml valid YAML"; test = { 
                    if (Test-YamlValid (Join-Path $workspaceRoot "registry/agents.yaml")) {
                        @{ status = "PASSED" }
                    } else { @{ status = "FAILED"; message = "Invalid YAML" } }
                }}
            )
        }
        "phase2" {
            @(
                @{ name = "search-index.json exists"; test = { Test-FileExists "registry/search-index.json" } },
                @{ name = "search-index valid JSON"; test = { 
                    if (Test-JsonValid (Join-Path $workspaceRoot "registry/search-index.json")) {
                        @{ status = "PASSED" }
                    } else { @{ status = "FAILED"; message = "Invalid JSON" } }
                }},
                @{ name = "plan template exists"; test = { Test-FileExists "plans/TEMPLATE.md" } },
                @{ name = "review config exists"; test = { Test-FileExists "registry/review-config.yaml" } }
            )
        }
        "phase3" {
            @(
                @{ name = "projects.yaml exists"; test = { Test-FileExists "registry/projects.yaml" } },
                @{ name = "sessions directory exists"; test = { Test-FileExists "memory/sessions/README.md" } },
                @{ name = "project patterns exist"; test = { Test-FileExists "memory/self-improving/projects/proj-modular-agent/patterns.md" } }
            )
        }
        "phase4" {
            @(
                @{ name = "install manifest exists"; test = { Test-FileExists "registry/install-manifest.yaml" } },
                @{ name = "audit config exists"; test = { Test-FileExists "registry/audit-config.yaml" } },
                @{ name = "drift config exists"; test = { Test-FileExists "registry/drift-config.yaml" } },
                @{ name = "targets registry exists"; test = { Test-FileExists "registry/targets.yaml" } }
            )
        }
        "integration" {
            @(
                @{ name = "Registry consistency"; test = { 
                    $issues = Test-RegistryConsistency
                    if ($issues.Count -eq 0) { @{ status = "PASSED" } }
                    else { @{ status = "FAILED"; message = $issues -join ", " } }
                }},
                @{ name = "All evals parseable"; test = {
                    $evals = Get-ChildItem (Join-Path $workspaceRoot "registry/eval-*.yaml") -ErrorAction SilentlyContinue
                    $failed = @()
                    foreach ($eval in $evals) {
                        if (-not (Test-YamlValid $eval.FullName)) {
                            $failed += $eval.Name
                        }
                    }
                    if ($failed.Count -eq 0) { @{ status = "PASSED" } }
                    else { @{ status = "FAILED"; message = "Failed: $($failed -join ', ')" } }
                }}
            )
        }
    }
    
    foreach ($test in $tests) {
        try {
            $result = & $test.test
            
            $testResult = @{
                name = $test.name
                status = $result.status
                message = $result.message
                duration = 0
            }
            
            $suiteResults.tests += $testResult
            
            switch ($result.status) {
                "PASSED" { $suiteResults.passed++; $results.total.passed++ }
                "FAILED" { $suiteResults.failed++; $results.total.failed++ }
                "SKIPPED" { $suiteResults.skipped++; $results.total.skipped++ }
            }
            
            $symbol = switch ($result.status) {
                "PASSED" { "✅" }
                "FAILED" { "❌" }
                "SKIPPED" { "⏭️" }
            }
            
            Write-Host "  $symbol $($test.name)" -ForegroundColor $(
                switch ($result.status) {
                    "PASSED" { "Green" }
                    "FAILED" { "Red" }
                    "SKIPPED" { "Yellow" }
                }
            )
            
            if ($result.status -eq "FAILED" -and $FailFast) {
                break
            }
        }
        catch {
            $suiteResults.tests += @{
                name = $test.name
                status = "ERROR"
                message = $_.Exception.Message
            }
            $suiteResults.failed++
            $results.total.failed++
            
            Write-Host "  💥 $($test.name) - ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    $results.suites[$SuiteName] = $suiteResults
    
    return $suiteResults.failed -eq 0
}

# Hauptlogik
Write-InfoLog -Message "Starting CI Eval Runner" -Console -Data @{ suite = $Suite }

$suitesToRun = if ($Suite -eq "all") { @("phase1", "phase2", "phase3", "phase4", "integration") } else { @($Suite) }

$allPassed = $true
foreach ($suiteName in $suitesToRun) {
    $passed = Run-EvalSuite -SuiteName $suiteName
    if (-not $passed) { $allPassed = $false }
    Write-Host ""
}

# Zusammenfassung
$duration = (Get-Date) - $results.startTime

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EVAL RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Host "Passed: $($results.total.passed)" -ForegroundColor Green
Write-Host "Failed: $($results.total.failed)" -ForegroundColor Red
Write-Host "Skipped: $($results.total.skipped)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if ($GenerateReport) {
    $reportPath = Join-Path $workspaceRoot "memory/evals/ci-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $results | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8
    Write-InfoLog -Message "Report saved: $reportPath" -Console
}

# Exit-Code für CI
if ($CI) {
    exit $(if ($allPassed) { 0 } else { 1 })
} else {
    exit 0
}
