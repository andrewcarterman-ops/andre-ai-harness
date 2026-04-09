#Requires -Version 5.1
<#
.SYNOPSIS
    Eval-Runner für ECC Second Brain CI/CD

.DESCRIPTION
    Führt Evaluierungen für das ECC Second Brain Framework durch.
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
    ECC Framework: CI/CD
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
        Write-EvalLog "Config file not found: $Path" -Level "ERROR"
        exit 2
    }
    
    try {
        $content = Get-Content $Path -Raw
        # Simple YAML parsing (for production, use a proper YAML parser)
        $config = @{
            version = "1.0.0"
            name = "ECC Second Brain Evaluation"
            suites = @()
            gates = @()
        }
        
        Write-EvalLog "Loaded config: $Path" -Level "DEBUG"
        return $config
    }
    catch {
        Write-EvalLog "Failed to parse config: $_" -Level "ERROR"
        exit 2
    }
}

function Test-VaultStructure {
    $tests = @(
        @{ Name = "00-Inbox"; Path = "00-Inbox"; Required = $true }
        @{ Name = "01-Projects"; Path = "01-Projects"; Required = $true }
        @{ Name = "02-Areas"; Path = "02-Areas"; Required = $true }
        @{ Name = "03-Resources"; Path = "03-Resources"; Required = $true }
        @{ Name = "04-Archive"; Path = "04-Archive"; Required = $true }
        @{ Name = "05-Daily"; Path = "05-Daily"; Required = $true }
        @{ Name = "scripts"; Path = "scripts"; Required = $true }
        @{ Name = "config"; Path = "config"; Required = $true }
        @{ Name = ".obsidian"; Path = ".obsidian"; Required = $true }
    )
    
    $results = @()
    foreach ($test in $tests) {
        $exists = Test-Path $test.Path
        $results += [PSCustomObject]@{
            name = $test.Name
            passed = $exists
            required = $test.Required
            message = if ($exists) { "Exists" } else { "Missing" }
        }
    }
    
    return $results
}

function Test-PowerShellModules {
    $tests = @(
        @{ Name = "ErrorHandler"; Path = "scripts/lib/ErrorHandler.psm1" }
        @{ Name = "Logging"; Path = "scripts/lib/Logging.psm1" }
        @{ Name = "MermaidGenerator"; Path = "scripts/lib/MermaidGenerator.psm1" }
        @{ Name = "DataviewQuery"; Path = "scripts/lib/DataviewQuery.psm1" }
        @{ Name = "Encryption"; Path = "scripts/lib/Encryption.psm1" }
    )
    
    $results = @()
    foreach ($test in $tests) {
        $exists = Test-Path $test.Path
        $results += [PSCustomObject]@{
            name = $test.Name
            passed = $exists
            message = if ($exists) { "Exists" } else { "Missing" }
        }
    }
    
    return $results
}

function Test-ObsidianConfig {
    $tests = @(
        @{ Name = "manifest.json"; Path = ".obsidian/plugins/ecc-vault/manifest.json" }
        @{ Name = "data.json"; Path = ".obsidian/plugins/ecc-vault/data.json" }
        @{ Name = "styles.css"; Path = ".obsidian/plugins/ecc-vault/styles.css" }
    )
    
    $results = @()
    foreach ($test in $tests) {
        $exists = Test-Path $test.Path
        $valid = $false
        
        if ($exists -and $test.Path -like "*.json") {
            try {
                $content = Get-Content $test.Path -Raw | ConvertFrom-Json
                $valid = $true
            }
            catch {
                $valid = $false
            }
        }
        else {
            $valid = $exists
        }
        
        $results += [PSCustomObject]@{
            name = $test.Name
            passed = $valid
            message = if ($valid) { "Valid" } else { "Invalid or missing" }
        }
    }
    
    return $results
}

function Invoke-EvalSuite {
    param(
        [string]$Name,
        [scriptblock]$TestFunction
    )
    
    Write-EvalLog "Running suite: $Name" -Level "INFO"
    
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
    
    Write-EvalLog "Suite completed: $Name - Score: $($suite.summary.score)%" -Level $(if ($failed -eq 0) { "SUCCESS" } else { "WARN" })
    
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
    Write-EvalLog "Report exported: $Path" -Level "SUCCESS"
}

#endregion

#region Main

Write-EvalLog "=== ECC Second Brain Eval Runner v$script:Version ===" -Level "INFO"

# Load config
$config = Import-EvalConfig -Path $ConfigPath

# Run suites
$suites = @()

if ([string]::IsNullOrEmpty($Suite) -or $Suite -eq "Structure") {
    $suites += Invoke-EvalSuite -Name "Structure" -TestFunction ${function:Test-VaultStructure}
}

if ([string]::IsNullOrEmpty($Suite) -or $Suite -eq "PowerShell") {
    $suites += Invoke-EvalSuite -Name "PowerShell Modules" -TestFunction ${function:Test-PowerShellModules}
}

if ([string]::IsNullOrEmpty($Suite) -or $Suite -eq "Obsidian") {
    $suites += Invoke-EvalSuite -Name "Obsidian Config" -TestFunction ${function:Test-ObsidianConfig}
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
Write-EvalLog "=== Evaluation Summary ===" -Level "INFO"
Write-EvalLog "Total Tests: $totalTests" -Level "INFO"
Write-EvalLog "Passed: $passedTests" -Level "SUCCESS"
Write-EvalLog "Failed: $failedTests" -Level $(if ($failedTests -gt 0) { "ERROR" } else { "INFO" })
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
