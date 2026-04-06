#!/usr/bin/env pwsh
# /learn Command
# Extrahiert Patterns aus der aktuellen Session

param(
    [string]$Name,
    [switch]$Auto
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Write-Host "🎓 /learn - Pattern Extraktion" -ForegroundColor Cyan
Write-Host ""

# Session-Info laden
$sessionFile = Get-ChildItem "$workspaceRoot/memory/sessions/SESSION-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $sessionFile) {
    Write-Host "❌ Keine Session gefunden" -ForegroundColor Red
    exit 1
}

Write-Host "📄 Session: $($sessionFile.Name)" -ForegroundColor Gray

# Pattern extrahieren (vereinfacht)
$pattern = @"
# Pattern: $Name
**Extrahiert:** $(Get-Date -Format "yyyy-MM-dd HH:mm")
**Session:** $($sessionFile.Name)

## Kontext
$(if ($Auto) { "Automatisch extrahiert" } else { "Manuell erstellt" })

## Pattern
{Pattern-Description}

## Beispiel
```
{Example-Code}
```

## Anwendung
- Wann: {When-to-use}
- Warum: {Why-useful}
"@

# Speichern
$patternsFile = "$workspaceRoot/memory/self-improving/learned-patterns.md"
if (-not (Test-Path $patternsFile)) {
    "# Gelernte Patterns`n`n" | Out-File $patternsFile -Encoding UTF8
}

$pattern | Out-File $patternsFile -Append -Encoding UTF8

Write-Host "✅ Pattern gespeichert in: $patternsFile" -ForegroundColor Green
Write-Host "`n💡 Tipp: Bearbeite das Pattern und fülle die Platzhalter aus." -ForegroundColor Yellow
