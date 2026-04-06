#!/usr/bin/env pwsh
# /context Command
# Zeigt oder wechselt Context

param(
    [string]$Target
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent
$contextFile = "$workspaceRoot/memory/current-context.md"

# Verfügbare Contexts
$contexts = @{
    "dev" = "💻 Development"
    "research" = "🔍 Research"
    "review" = "👁️ Review"
}

if (-not $Target) {
    # Aktuellen Context anzeigen
    Write-Host "🎯 Aktueller Context" -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Path $contextFile) {
        $current = Get-Content $contextFile -Raw
        Write-Host $current -ForegroundColor Green
    } else {
        Write-Host "Kein Context gesetzt. Verfügbar:" -ForegroundColor Yellow
        $contexts.GetEnumerator() | ForEach-Object {
            Write-Host "  - $($_.Key): $($_.Value)"
        }
    }
} else {
    # Context wechseln
    if ($contexts.ContainsKey($Target)) {
        "# Current Context`n`n**Context:** $($contexts[$Target])`n**Switched:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-File $contextFile -Encoding UTF8
        
        Write-Host "✅ Context gewechselt zu: $($contexts[$Target])" -ForegroundColor Green
    } else {
        Write-Host "❌ Unbekannter Context: $Target" -ForegroundColor Red
        Write-Host "Verfügbar: dev, research, review"
        exit 1
    }
}
