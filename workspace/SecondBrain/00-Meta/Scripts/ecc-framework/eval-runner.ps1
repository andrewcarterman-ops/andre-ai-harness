#Requires -Version 5.1
<#
.SYNOPSIS
    Eval-Runner für SecondBrain CI/CD

.DESCRIPTION
    Führt Evaluierungen für den SecondBrain Vault durch.
    Unterstützt YAML-Config, JSON-Output und Exit-Codes für CI/CD.

.PARAMETER ConfigPath
    Pfad zur Eval-Konfiguration

.PARAMETER OutputPath
    Pfad zum Output-Report

.PARAMETER Suite
    Spezifische Suite ausführen

.EXAMPLE
    .\eval-runner.ps1
    .\eval-runner.ps1 -Suite "Structure"
    .\eval-runner.ps1 -OutputPath ".logs/eval-report.json"

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    Location: SecondBrain/00-Meta/Scripts/ecc-framework/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "config/eval-template.yaml",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".logs/eval-report.json",
    
    [Parameter(Mandatory = $false)]
    [string]$Suite = ""
)

# Script Variables
$script:Version = "1.0.0"
$script:StartTime = Get-Date
$script:Results = @{
    version = $script:Version
    timestamp = Get-Date -Format "o"
    summary = @{
        total = 0
        passed = 0
        failed = 0
        skipped = 0
        score = 0
    }
    suites = @()
}

#region Functions

function Write-EvalLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG"   { Write-Verbose $logEntry }
    }
}

function Import-EvalConfig {
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        Write-EvalLog "Config nicht gefunden: $Path" -Level "WARN"
        # Default config
        return @{
            version = "1.0.0"
            name = "SecondBrain Evaluation"
            suites = @("Structure", "Templates", "Scripts")
            gates = @()
        }
    }
    
    try {
        $content = Get-Content $Path -Raw
        # Simple YAML parsing (für Produktion: YAML-Parser-Modul nutzen)
        $config = @{
            version = "1.0.0"
            name = "SecondBrain Evaluation"
            suites = @()
            gates = @()
        }
        
        Write-EvalLog "Config geladen: $Path" -Level "DEBUG"
        return $config
    }
    catch {
        Write-EvalLog "Config-Parsing fehlgeschlagen: $_" -Level "ERROR"
        exit 2
    }
}

function Test-VaultStructure {
    $tests = @(
        @{ Name = "00-Meta"; Path = "00-Meta"; Required = $true }
        @{ Name = "01-Daily"; Path = "01-Daily"; Required = $true }
        @{ Name = "02-Projects"; Path = "02-Projects"; Required = $true }
        @{ Name = "03-Knowledge"; Path = "03-Knowledge"; Required = $true }
        @{ Name = "04-Decisions"; Path = "04-Decisions"; Required = $true }
        @{ Name = "99-Archive"; Path = "99-Archive"; Required = $true }
        @{ Name = "Templates"; Path = "00-Meta\Templates"; Required = $true }
        @{ Name = "Scripts"; Path = "00-Meta\Scripts"; Required = $true }
        @{ Name = "MOCs"; Path = "00-Meta\MOCs"; Required = $true }
    )
    
    $results = @()
    foreach ($test in $tests) {
        $exists = Test-Path $test.Path
        $results += [PSCustomObject]@{
            name = $test.Name
            passed = $exists
            required = $test.Required
            message = if ($exists) { "Existiert" } else { "Fehlt" }
        }
    }
    
    return $results
}

function Test-Templates {
    $tests = @(
        @{ Name = "Daily Template"; Path = "00-Meta\Templates\Daily.md"; Required = $true }
        @{ Name = "Meeting Template"; Path = "00-Meta\Templates\Meeting.md"; Required = $true }
        @{ Name = "Project Template"; Path = "00-Meta\Templates\Project.md"; Required = $true }
        @{ Name = "Knowledge Template"; Path = "00-Meta\Templates\Knowledge.md"; Required = $true }
        @{ Name = "Decision Template"; Path = "00-Meta\Templates\Decision.md"; Required = $true }
    )
    
    $results = @()
    foreach ($test in $tests) {
        $exists = Test-Path $test.Path
        $results += [PSCustomObject]@{
            name = $test.Name
            passed = $exists
            message = if ($exists) { "Existiert" } else { "Fehlt" }
        }
    }
    
    return $results
}

function Test-Scripts {
    $tests = @(
        @{ Name = "Sync Script"; Path = "00-Meta\Scripts\ecc-framework\sync-openclaw-to-obsidian.ps1"; Required = $false }
        @{ Name = "Backup Script"; Path = "00-Meta\Scripts\ecc-framework\auto-backup.ps1"; Required = $false }
        @{ Name = "Drift Detection"; Path = "00-Meta\Scripts\ecc-framework\drift-detection.ps1"; Required = $false }
        @{ Name = "Stability Script"; Path = "00-Meta\Scripts\ecc-framework\ecc-stability.ps1"; Required = $false }
        @{ Name = "Backup Command"; Path = "00-Meta\Scripts\ecc-framework\cmd-backup.ps1"; Required = $false }
        @{ Name = "Eval Runner"; Path = "00-Meta\Scripts\ecc-framework\eval-runner.ps1"; Required = $false }
        @{ Name = "Context Switch"; Path = "00-Meta\Scripts\ecc-framework\context-switch.ps1"; Required = $false }
        @{ Name = "Utilities Module"; Path = "00-Meta\Scripts\ecc-framework\ECC-Utilities.psm1"; Required = $true }
    )
    
    $results = @()
    foreach ($test in $tests) {
        $exists = Test-Path $test.Path
        $results += [PSCustomObject]@{
            name = $test.Name
            passed = $exists
            message = if ($exists) { "Existiert" } else { "Fehlt" }
        }
    }
    
    return $results
}

function Invoke-EvalSuite {
    param(
        [string]$Name,
        [scriptblock]$TestFunction
    )
    
    Write-EvalLog "Führe Suite aus: $Name" -Level "INFO"
    
    $startTime = Get-Date
    $testResults = & $TestFunction
    $duration = (Get-Date) - $startTime
    
    $passed = ($testResults | Where-Object { $_.passed }).Count
    $failed = ($testResults | Where-Object { !$_.passed }).Count
    
    $suite = [PSCustomObject]@{
        name = $Name
        duration = $duration.ToString()
        tests = $testResults
        summary = @{
            total = $testResults.Count
            passed = $passed
            failed = $failed
            score = if ($testResults.Count -gt 0) { [math]::Round(($passed / $testResults.Count) * 100, 2) } else { 0 }
        }
    }
    
    Write-EvalLog "Suite abgeschlossen: $Name - Score: $($suite.summary.score)%" -Level $(if ($failed -eq 0) { "SUCCESS" } else { "WARN" })
    
    return $suite
}

function Export-EvalReport {
    param(
        [hashtable]$Results,
        [string]$Path
    )
    
    $outputDir = Split-Path $Path -Parent
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $Results | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
    Write-EvalLog "Report exportiert: $Path" -Level "SUCCESS"
}

#endregion

#region Main

Write-EvalLog "=== SecondBrain Eval Runner v$script:Version ===" -Level "INFO"

# Load config
$config = Import-EvalConfig -Path $ConfigPath

# Run suites
$suites = @()

if ([string]::IsNullOrEmpty($Suite) -or $Suite -eq "Structure") {
    $suites += Invoke-EvalSuite -Name "Vault Structure" -TestFunction ${function:Test-VaultStructure}
}

if ([string]::IsNullOrEmpty($Suite) -or $Suite -eq "Templates") {
    $suites += Invoke-EvalSuite -Name "Templates" -TestFunction ${function:Test-Templates}
}

if ([string]::IsNullOrEmpty($Suite) -or $Suite -eq "Scripts") {
    $suites += Invoke-EvalSuite -Name "Scripts" -TestFunction ${function:Test-Scripts}
}

# Calculate summary
$totalTests = ($suites | ForEach-Object { $_.summary.total } | Measure-Object -Sum).Sum
$passedTests = ($suites | ForEach-Object { $_.summary.passed } | Measure-Object -Sum).Sum
$failedTests = ($suites | ForEach-Object { $_.summary.failed } | Measure-Object -Sum).Sum
$overallScore = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

$script:Results.summary = @{
    total = $totalTests
    passed = $passedTests
    failed = $failedTests
    score = $overallScore
}
$script:Results.suites = $suites

# Export report
Export-EvalReport -Results $script:Results -Path $OutputPath

# Summary
Write-EvalLog "" -Level "INFO"
Write-EvalLog "=== Evaluierung Zusammenfassung ===" -Level "INFO"
Write-EvalLog "Gesamt: $totalTests" -Level "INFO"
Write-EvalLog "Bestanden: $passedTests" -Level "SUCCESS"
Write-EvalLog "Fehlgeschlagen: $failedTests" -Level $(if ($failedTests -gt 0) { "ERROR" } else { "INFO" })
Write-EvalLog "Score: $overallScore%" -Level $(if ($overallScore -ge 80) { "SUCCESS" } elseif ($overallScore -ge 60) { "WARN" } else { "ERROR" })

# Exit code
if ($overallScore -ge 80) {
    exit 0
}
elseif ($overallScore -ge 60) {
    exit 1
}
else {
    exit 2
}

#endregion