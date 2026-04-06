#!/usr/bin/env pwsh
# Drift Doctor Check Script
# Vergleicht Ist-Zustand mit Install-Manifest

param(
    [string]$ManifestPath = "registry/install-manifest.yaml",
    [string]$OutputPath = "memory/drift/",
    [switch]$Fix,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$driftReport = @{
    timestamp = $timestamp
    drifts = @()
    summary = @{
        critical = 0
        warning = 0
        info = 0
        total = 0
    }
}

# Farben
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
}

function Write-Drift($Type, $Path, $Expected, $Actual, $Severity) {
    $symbol = switch ($Severity) {
        "critical" { "❌" }
        "warning" { "⚠️" }
        "info" { "ℹ️" }
        default { "•" }
    }
    
    $color = switch ($Severity) {
        "critical" { $Colors.Error }
        "warning" { $Colors.Warning }
        "info" { $Colors.Info }
        default { "White" }
    }
    
    Write-Host "$symbol [$Severity] $Type`: $Path" -ForegroundColor $color
    if ($Verbose) {
        Write-Host "   Expected: $Expected" -ForegroundColor Gray
        Write-Host "   Actual:   $Actual" -ForegroundColor Gray
    }
    
    $driftReport.drifts += @{
        type = $Type
        path = $Path
        expected = $Expected
        actual = $Actual
        severity = $Severity
        timestamp = Get-Date -Format "o"
    }
    
    $driftReport.summary[$Severity]++
    $driftReport.summary.total++
}

function Get-FileChecksum($Path) {
    if (Test-Path $Path -PathType Leaf) {
        $hash = Get-FileHash $Path -Algorithm SHA256
        return $hash.Hash.Substring(0, 16)  # Kurzer Hash für Vergleich
    }
    return $null
}

# Hauptlogik
Write-Host "`n=== Drift Doctor ===" -ForegroundColor $Colors.Info
Write-Host "Prüfe System gegen Manifest...`n"

$workspaceRoot = $PSScriptRoot | Split-Path -Parent
if (-not $workspaceRoot) { $workspaceRoot = Get-Location }

# Manifest laden (vereinfacht - in voller Version YAML parsen)
$manifestPath = Join-Path $workspaceRoot $ManifestPath
if (-not (Test-Path $manifestPath)) {
    Write-Host "❌ Manifest nicht gefunden: $manifestPath" -ForegroundColor $Colors.Error
    exit 1
}

Write-Host "✅ Manifest geladen`n" -ForegroundColor $Colors.Success

# Prüfung 1: Kern-Dateien aus Manifest
$coreFiles = @(
    @{ Path = "registry/agents.yaml"; Required = $true },
    @{ Path = "registry/skills.yaml"; Required = $true },
    @{ Path = "registry/hooks.yaml"; Required = $true },
    @{ Path = "registry/projects.yaml"; Required = $true },
    @{ Path = "registry/search-index.json"; Required = $true },
    @{ Path = "registry/review-config.yaml"; Required = $true },
    @{ Path = "registry/install-manifest.yaml"; Required = $true },
    @{ Path = "registry/audit-config.yaml"; Required = $true },
    @{ Path = "registry/drift-config.yaml"; Required = $true },
    @{ Path = "hooks/session-start.md"; Required = $true },
    @{ Path = "hooks/session-end.md"; Required = $true },
    @{ Path = "hooks/review-post-execution.md"; Required = $true },
    @{ Path = "plans/TEMPLATE.md"; Required = $true },
    @{ Path = "memory/sessions/README.md"; Required = $true },
    @{ Path = "scripts/install-check.ps1"; Required = $true }
)

Write-Host "📁 Prüfe Kern-Dateien..." -ForegroundColor $Colors.Info

foreach ($file in $coreFiles) {
    $fullPath = Join-Path $workspaceRoot $file.Path
    $exists = Test-Path $fullPath -PathType Leaf
    
    if ($file.Required -and -not $exists) {
        Write-Drift -Type "file_missing" -Path $file.Path -Expected "present" -Actual "missing" -Severity "critical"
    } elseif ($exists) {
        $size = (Get-Item $fullPath).Length
        Write-Host "   ✅ $($file.Path) ($size bytes)" -ForegroundColor $Colors.Success
    }
}

# Prüfung 2: Verzeichnisse
Write-Host "`n📂 Prüfe Verzeichnisse..." -ForegroundColor $Colors.Info

$dirs = @("registry/", "hooks/", "plans/", "memory/sessions/", "scripts/", "docs/")
foreach ($dir in $dirs) {
    $fullPath = Join-Path $workspaceRoot $dir
    if (-not (Test-Path $fullPath -PathType Container)) {
        Write-Drift -Type "directory_missing" -Path $dir -Expected "present" -Actual "missing" -Severity "warning"
    } else {
        $fileCount = (Get-ChildItem $fullPath -Recurse -File -ErrorAction SilentlyContinue).Count
        Write-Host "   ✅ $dir ($fileCount Dateien)" -ForegroundColor $Colors.Success
    }
}

# Prüfung 3: Untracked Files (Dateien die nicht im Manifest sind)
Write-Host "`n🔍 Prüfe auf untracked Dateien..." -ForegroundColor $Colors.Info

$expectedFiles = $coreFiles | ForEach-Object { $_.Path }
$allRegistryFiles = Get-ChildItem (Join-Path $workspaceRoot "registry") -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name

foreach ($file in $allRegistryFiles) {
    $relativePath = "registry/$file"
    if ($expectedFiles -notcontains $relativePath) {
        Write-Drift -Type "file_untracked" -Path $relativePath -Expected "not in manifest" -Actual "present" -Severity "info"
    }
}

# Zusammenfassung
Write-Host "`n=== Zusammenfassung ===" -ForegroundColor $Colors.Info
Write-Host "Kritisch:  $($driftReport.summary.critical)" -ForegroundColor $(if ($driftReport.summary.critical -gt 0) { $Colors.Error } else { $Colors.Success })
Write-Host "Warnungen: $($driftReport.summary.warning)" -ForegroundColor $(if ($driftReport.summary.warning -gt 0) { $Colors.Warning } else { $Colors.Success })
Write-Host "Info:      $($driftReport.summary.info)" -ForegroundColor $Colors.Info
Write-Host "Gesamt:    $($driftReport.summary.total) Drifts erkannt"

# Report speichern
$reportDir = Join-Path $workspaceRoot $OutputPath
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$reportFile = Join-Path $reportDir "DRIFT-$timestamp.md"
$reportContent = @"
# Drift Report - $timestamp

**Datum:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Manifest:** $ManifestPath

## Zusammenfassung

| Schwere | Anzahl |
|---------|--------|
| ❌ Kritisch | $($driftReport.summary.critical) |
| ⚠️ Warnung | $($driftReport.summary.warning) |
| ℹ️ Info | $($driftReport.summary.info) |
| **Gesamt** | **$($driftReport.summary.total)** |

## Details

"@

foreach ($drift in $driftReport.drifts) {
    $icon = switch ($drift.severity) {
        "critical" { "❌" }
        "warning" { "⚠️" }
        "info" { "ℹ️" }
        default { "•" }
    }
    
    $reportContent += @"
### $icon $($drift.type) - $($drift.severity)
**Datei:** $($drift.path)
**Erwartet:** $($drift.expected)
**Tatsächlich:** $($drift.actual)

"@
}

$reportContent += @"
## Empfohlene Aktionen

"@

if ($driftReport.summary.critical -gt 0) {
    $reportContent += "- [ ] Kritische Drifts beheben (fehlende Dateien wiederherstellen)`n"
}
if ($driftReport.summary.warning -gt 0) {
    $reportContent += "- [ ] Warnungen prüfen (Verzeichnisse erstellen)`n"
}
if ($driftReport.summary.info -gt 0) {
    $reportContent += "- [ ] Untracked Dateien: Zum Manifest hinzufügen oder löschen`n"
}

$reportContent += "- [ ] Manifest aktualisieren falls Änderungen beabsichtigt waren`n"

$reportContent | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "`n📝 Report gespeichert: $reportFile" -ForegroundColor $Colors.Success

# Exit-Code
if ($driftReport.summary.critical -gt 0) { exit 2 }
if ($driftReport.summary.warning -gt 0) { exit 1 }
exit 0
