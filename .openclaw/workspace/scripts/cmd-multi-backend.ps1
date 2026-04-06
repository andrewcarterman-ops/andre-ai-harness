#!/usr/bin/env pwsh
# /multi-backend Command
# Multi-Backend Execution (simuliert parallel execution)

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,
    
    [string[]]$Backends = @("local"),
    [switch]$Parallel
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Write-Host "🌐 Multi-Backend Execution" -ForegroundColor Cyan
Write-Host "Command: $Command" -ForegroundColor Gray
Write-Host "Backends: $($Backends -join ', ')" -ForegroundColor Gray
Write-Host "Parallel: $Parallel`n" -ForegroundColor Gray

$results = @{}

foreach ($backend in $Backends) {
    Write-Host "[$backend] Executing..." -ForegroundColor Yellow
    
    # Simulierte Ausführung (in echtem Szenario: SSH, Docker, etc.)
    $start = Get-Date
    
    try {
        if ($backend -eq "local") {
            $output = Invoke-Expression $Command 2>&1
            $exitCode = $LASTEXITCODE
        } else {
            # Placeholder für remote execution
            Write-Host "  Remote execution to $backend would happen here" -ForegroundColor Gray
            $output = "Simulated: $Command on $backend"
            $exitCode = 0
        }
        
        $duration = (Get-Date) - $start
        
        $results[$backend] = @{
            success = ($exitCode -eq 0)
            output = $output
            duration = $duration.TotalSeconds
            exitCode = $exitCode
        }
        
        if ($exitCode -eq 0) {
            Write-Host "  ✅ Success ($([math]::Round($duration.TotalSeconds, 2))s)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Failed (exit $exitCode)" -ForegroundColor Red
        }
    }
    catch {
        $results[$backend] = @{
            success = $false
            output = $_.Exception.Message
            duration = 0
            exitCode = 1
        }
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n📊 Results:" -ForegroundColor Cyan
$results.GetEnumerator() | ForEach-Object {
    $status = if ($_.Value.success) { "✅" } else { "❌" }
    Write-Host "  $status $($_.Key): $([math]::Round($_.Value.duration, 2))s"
}

$successCount = ($results.Values | Where-Object { $_.success }).Count
Write-Host "`nTotal: $successCount/$($results.Count) succeeded" -ForegroundColor $(
    if ($successCount -eq $results.Count) { "Green" } elseif ($successCount -gt 0) { "Yellow" } else { "Red" }
)
