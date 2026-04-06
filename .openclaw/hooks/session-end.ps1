param($eventData)
Write-Host "`n[HOOK] Sync startet..." -ForegroundColor Cyan
$syncScript = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain\scripts\sync-simple.ps1"
if (Test-Path $syncScript) {
    & $syncScript
    Write-Host "[HOOK] Sync fertig`n" -ForegroundColor Green
} else {
    Write-Warning "Sync-Skript nicht gefunden!"
}
