# Simple OpenClaw Sync - Minimal & Robust
param([switch]$DryRun)

$source = "C:\Users\andre\.openclaw\workspace\second-brain\01-Sessions"
$target = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain\03 Resources\Sessions"

Write-Host "=== OpenClaw Sync ===" -ForegroundColor Cyan
Write-Host "Source: $source"
Write-Host "Target: $target"
if ($DryRun) { Write-Host "[DRY RUN]" -ForegroundColor Yellow }

# Pruefe Quelle
if (!(Test-Path $source)) {
    Write-Error "Quelle nicht gefunden: $source"
    exit 1
}

# Erstelle Ziel
if (!(Test-Path $target)) {
    if (!$DryRun) {
        New-Item -ItemType Directory -Force -Path $target | Out-Null
    }
    Write-Host "Ziel erstellt: $target" -ForegroundColor Green
}

# Finde Sessions
$sessions = Get-ChildItem -Path $source -Filter "Session-*.md" | Sort-Object LastWriteTime -Descending

Write-Host "Gefunden: $($sessions.Count) Sessions" -ForegroundColor Cyan

$synced = 0
$skipped = 0

foreach ($session in $sessions) {
    $date = $session.BaseName -replace 'Session-', ''
    $destFile = Join-Path $target "$date.md"
    
    if (Test-Path $destFile) {
        Write-Host "  SKIP: $date (existiert)" -ForegroundColor Gray
        $skipped++
        continue
    }
    
    Write-Host "  SYNC: $date" -ForegroundColor Green
    
    if (!$DryRun) {
        Copy-Item -Path $session.FullName -Destination $destFile -Force
    }
    
    $synced++
}

Write-Host ""
Write-Host "=== Fertig ===" -ForegroundColor Cyan
Write-Host "Synchronisiert: $synced" -ForegroundColor Green
Write-Host "Uebersprungen: $skipped" -ForegroundColor Gray

if ($DryRun) {
    Write-Host ""
    Write-Host "Ohne -DryRun ausfuehren zum wirklichen Sync:" -ForegroundColor Yellow
    Write-Host ".\sync-simple.ps1"
}