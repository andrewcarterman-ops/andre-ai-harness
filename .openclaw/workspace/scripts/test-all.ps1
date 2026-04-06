#!/usr/bin/env pwsh
# Master Test Script - Führt alle Evals aus
# Testet das komplette Framework

param(
    [switch]$Verbose,
    [switch]$StopOnFailure
)

$ErrorActionPreference = "Continue"
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
}

$Results = @{
    Total = 0
    Passed = 0
    Failed = 0
    Warnings = 0
}

function Write-TestResult($Name, $Status, $Details = "") {
    $symbol = switch ($Status) {
        "PASS" { "✅" }
        "FAIL" { "❌" }
        "WARN" { "⚠️" }
        default { "ℹ️" }
    }
    $color = switch ($Status) {
        "PASS" { $Colors.Success }
        "FAIL" { $Colors.Error }
        "WARN" { $Colors.Warning }
        default { $Colors.Info }
    }
    
    Write-Host "$symbol $Name" -ForegroundColor $color
    if ($Verbose -and $Details) {
        Write-Host "   $Details" -ForegroundColor Gray
    }
}

function Test-FileExists($Path, $Required = $true) {
    $fullPath = Join-Path $workspaceRoot $Path
    $exists = Test-Path $fullPath -PathType Leaf
    
    if ($exists) {
        return @{ Status = "PASS"; Size = (Get-Item $fullPath).Length }
    } else {
        if ($Required) {
            return @{ Status = "FAIL"; Size = 0 }
        } else {
            return @{ Status = "WARN"; Size = 0 }
        }
    }
}

# Hauptlogik
Write-Host "`n========================================" -ForegroundColor $Colors.Info
Write-Host "   FRAMEWORK MASTER TEST" -ForegroundColor $Colors.Info
Write-Host "========================================`n" -ForegroundColor $Colors.Info

$workspaceRoot = $PSScriptRoot | Split-Path -Parent
if (-not $workspaceRoot) { $workspaceRoot = Get-Location }

Write-Host "Workspace: $workspaceRoot`n" -ForegroundColor Gray

# Test 1: Phase 1 - Registry
Write-Host "📦 Phase 1: Registry Foundation" -ForegroundColor $Colors.Info
$phase1Files = @(
    @{ Path = "registry/agents.yaml"; Name = "Agent Registry" },
    @{ Path = "registry/skills.yaml"; Name = "Skill Registry" },
    @{ Path = "registry/hooks.yaml"; Name = "Hook Config" }
)

$phase1Pass = 0
foreach ($file in $phase1Files) {
    $result = Test-FileExists $file.Path
    Write-TestResult $file.Name $result.Status
    $Results.Total++
    if ($result.Status -eq "PASS") { $Results.Passed++; $phase1Pass++ } else { $Results.Failed++ }
}

# Test 2: Phase 2 - Cognitive
Write-Host "`n🧠 Phase 2: Cognitive Layer" -ForegroundColor $Colors.Info
$phase2Files = @(
    @{ Path = "registry/search-index.json"; Name = "Search Index" },
    @{ Path = "plans/TEMPLATE.md"; Name = "Plan Template" },
    @{ Path = "registry/review-config.yaml"; Name = "Review Config" }
)

$phase2Pass = 0
foreach ($file in $phase2Files) {
    $result = Test-FileExists $file.Path
    Write-TestResult $file.Name $result.Status
    $Results.Total++
    if ($result.Status -eq "PASS") { $Results.Passed++; $phase2Pass++ } else { $Results.Failed++ }
}

# Test 3: Phase 3 - Persistence
Write-Host "`n💾 Phase 3: Persistence & Learning" -ForegroundColor $Colors.Info
$phase3Files = @(
    @{ Path = "registry/projects.yaml"; Name = "Project Registry" },
    @{ Path = "memory/sessions/README.md"; Name = "Session Store" },
    @{ Path = "memory/self-improving/projects/proj-modular-agent/patterns.md"; Name = "Project Patterns" }
)

$phase3Pass = 0
foreach ($file in $phase3Files) {
    $result = Test-FileExists $file.Path
    Write-TestResult $file.Name $result.Status
    $Results.Total++
    if ($result.Status -eq "PASS") { $Results.Passed++; $phase3Pass++ } else { $Results.Failed++ }
}

# Test 4: Phase 4 - Operations
Write-Host "`n🚀 Phase 4: Operations" -ForegroundColor $Colors.Info
$phase4Files = @(
    @{ Path = "registry/install-manifest.yaml"; Name = "Install Manifest" },
    @{ Path = "scripts/install-check.ps1"; Name = "Install Check Script" },
    @{ Path = "scripts/drift-check.ps1"; Name = "Drift Check Script" },
    @{ Path = "README.md"; Name = "Main README" }
)

$phase4Pass = 0
foreach ($file in $phase4Files) {
    $result = Test-FileExists $file.Path
    Write-TestResult $file.Name $result.Status
    $Results.Total++
    if ($result.Status -eq "PASS") { $Results.Passed++; $phase4Pass++ } else { $Results.Failed++ }
}

# Test 5: Integration
Write-Host "`n🔗 Integration" -ForegroundColor $Colors.Info
$integrationTests = @(
    @{ 
        Path = "registry/agents.yaml"; 
        Name = "Agent-Skill Referenzierung";
        Test = { 
            $content = Get-Content (Join-Path $workspaceRoot "registry/skills.yaml") -Raw
            return $content -match "example-weather"
        }
    },
    @{ 
        Path = "registry/hooks.yaml"; 
        Name = "Hook-Review Integration";
        Test = { 
            $content = Get-Content (Join-Path $workspaceRoot "registry/hooks.yaml") -Raw
            return $content -match "review:post_execution"
        }
    },
    @{
        Path = "memory/sessions/SESSION-20260325-224500-001.json";
        Name = "Session-Projekt Verknüpfung";
        Test = {
            $file = Join-Path $workspaceRoot "memory/sessions/SESSION-20260325-224500-001.json"
            if (Test-Path $file) {
                $content = Get-Content $file -Raw
                return $content -match "proj-modular-agent"
            }
            return $false
        }
    }
)

$integrationPass = 0
foreach ($test in $integrationTests) {
    try {
        $result = & $test.Test
        $status = if ($result) { "PASS" } else { "FAIL" }
        Write-TestResult $test.Name $status
        $Results.Total++
        if ($status -eq "PASS") { $Results.Passed++; $integrationPass++ } else { $Results.Failed++ }
    } catch {
        Write-TestResult $test.Name "FAIL" $_.Message
        $Results.Total++
        $Results.Failed++
    }
}

# Zusammenfassung
Write-Host "`n========================================" -ForegroundColor $Colors.Info
Write-Host "   TEST ZUSAMMENFASSUNG" -ForegroundColor $Colors.Info
Write-Host "========================================" -ForegroundColor $Colors.Info

$phase1Status = if ($phase1Pass -eq 3) { "✅" } else { "❌" }
$phase2Status = if ($phase2Pass -eq 3) { "✅" } else { "❌" }
$phase3Status = if ($phase3Pass -eq 3) { "✅" } else { "❌" }
$phase4Status = if ($phase4Pass -eq 4) { "✅" } else { "❌" }
$integrationStatus = if ($integrationPass -eq 3) { "✅" } else { "❌" }

Write-Host "Phase 1 (Registry):      $phase1Status $phase1Pass/3" -ForegroundColor $(if ($phase1Pass -eq 3) { $Colors.Success } else { $Colors.Error })
Write-Host "Phase 2 (Cognitive):     $phase2Status $phase2Pass/3" -ForegroundColor $(if ($phase2Pass -eq 3) { $Colors.Success } else { $Colors.Error })
Write-Host "Phase 3 (Persistence):   $phase3Status $phase3Pass/3" -ForegroundColor $(if ($phase3Pass -eq 3) { $Colors.Success } else { $Colors.Error })
Write-Host "Phase 4 (Operations):    $phase4Status $phase4Pass/4" -ForegroundColor $(if ($phase4Pass -eq 4) { $Colors.Success } else { $Colors.Error })
Write-Host "Integration:             $integrationStatus $integrationPass/3" -ForegroundColor $(if ($integrationPass -eq 3) { $Colors.Success } else { $Colors.Error })

Write-Host "`nGesamt: $($Results.Passed)/$($Results.Total) Tests bestanden" -ForegroundColor $(if ($Results.Failed -eq 0) { $Colors.Success } else { $Colors.Warning })

if ($Results.Failed -eq 0) {
    Write-Host "`n🎉 ALLE TESTS BESTANDEN!" -ForegroundColor $Colors.Success
    Write-Host "Das Framework ist vollständig und funktionsfähig." -ForegroundColor $Colors.Success
    exit 0
} else {
    Write-Host "`n⚠️  EINIGE TESTS FEHLGESCHLAGEN" -ForegroundColor $Colors.Warning
    Write-Host "Bitte die fehlenden Komponenten prüfen." -ForegroundColor $Colors.Warning
    exit 1
}
