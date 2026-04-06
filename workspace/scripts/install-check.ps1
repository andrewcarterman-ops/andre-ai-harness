#!/usr/bin/env pwsh
# Install Check Script - Phase 4 Minimal
# Prüft ob das System dem Install-Manifest entspricht

param(
    [string]$ManifestPath = "registry/install-manifest.yaml",
    [switch]$Verbose,
    [switch]$Fix  # Nicht implementiert - nur Report
)

$ErrorActionPreference = "Stop"

# Farben für Output
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "Cyan"

function Write-Status($Message, $Status, $Color) {
    $symbol = switch ($Status) {
        "OK" { "✅" }
        "WARN" { "⚠️" }
        "ERROR" { "❌" }
        "INFO" { "ℹ️" }
        default { "•" }
    }
    Write-Host "$symbol $Message" -ForegroundColor $Color
}

function Test-FileExists($Path, $Description, $Required = $true) {
    $fullPath = Join-Path $workspaceRoot $Path
    $exists = Test-Path $fullPath -PathType Leaf
    
    if ($exists) {
        $size = (Get-Item $fullPath).Length
        Write-Status "$Description ($($size) bytes)" "OK" $ColorSuccess
        return @{ Exists = $true; Size = $size }
    } else {
        if ($Required) {
            Write-Status "$Description (FEHLT)" "ERROR" $ColorError
        } else {
            Write-Status "$Description (optional, fehlt)" "WARN" $ColorWarning
        }
        return @{ Exists = $false; Size = 0 }
    }
}

function Test-DirectoryExists($Path, $Description, $MinFiles = 0) {
    $fullPath = Join-Path $workspaceRoot $Path
    $exists = Test-Path $fullPath -PathType Container
    
    if ($exists) {
        $fileCount = (Get-ChildItem $fullPath -Recurse -File).Count
        if ($fileCount -ge $MinFiles) {
            Write-Status "$Description ($fileCount Dateien)" "OK" $ColorSuccess
            return @{ Exists = $true; FileCount = $fileCount }
        } else {
            Write-Status "$Description (nur $fileCount Dateien, min $MinFiles)" "WARN" $ColorWarning
            return @{ Exists = $true; FileCount = $fileCount }
        }
    } else {
        Write-Status "$Description (FEHLT)" "ERROR" $ColorError
        return @{ Exists = $false; FileCount = 0 }
    }
}

# Hauptlogik
Write-Host "`n=== Install Check ===" -ForegroundColor $ColorInfo
Write-Host "Prüfe System gegen Manifest: $ManifestPath`n"

# Workspace Root bestimmen
$workspaceRoot = $PSScriptRoot | Split-Path -Parent
if (-not $workspaceRoot) {
    $workspaceRoot = Get-Location
}

Write-Status "Workspace: $workspaceRoot" "INFO" $ColorInfo

# Manifest laden
$manifestFullPath = Join-Path $workspaceRoot $ManifestPath
if (-not (Test-Path $manifestFullPath)) {
    Write-Status "Manifest nicht gefunden: $manifestFullPath" "ERROR" $ColorError
    exit 1
}

# YAML parsen (einfacher Ansatz für das Skript)
# In einer vollständigen Implementierung würde man ein YAML-Modul nutzen
$manifestContent = Get-Content $manifestFullPath -Raw

Write-Status "Manifest geladen" "OK" $ColorSuccess
Write-Host ""

# Statistik
$stats = @{
    TotalComponents = 0
    OkComponents = 0
    WarnComponents = 0
    ErrorComponents = 0
    TotalFiles = 0
    MissingFiles = 0
}

# Komponenten prüfen (vereinfacht - in voller Version aus YAML geparst)
$components = @(
    @{ Name = "Core Registry"; Files = @("registry/agents.yaml", "registry/skills.yaml", "registry/hooks.yaml") },
    @{ Name = "Core Hooks"; Files = @("hooks/session-start.md", "hooks/session-end.md", "hooks/review-post-execution.md") },
    @{ Name = "Search Index"; Files = @("registry/search-index.json") },
    @{ Name = "Planner"; Files = @("plans/TEMPLATE.md"); Dirs = @("plans/") },
    @{ Name = "Reviewer"; Files = @("registry/review-config.yaml") },
    @{ Name = "Session Store"; Files = @("memory/sessions/README.md"); Dirs = @("memory/sessions/") },
    @{ Name = "Project Registry"; Files = @("registry/projects.yaml"); Dirs = @("memory/self-improving/projects/") }
)

foreach ($component in $components) {
    Write-Host "`n📦 $($component.Name)" -ForegroundColor $ColorInfo
    $stats.TotalComponents++
    
    $componentOk = $true
    
    # Dateien prüfen
    foreach ($file in $component.Files) {
        $result = Test-FileExists $file (Split-Path $file -Leaf)
        $stats.TotalFiles++
        if (-not $result.Exists) {
            $componentOk = $false
            $stats.MissingFiles++
        }
    }
    
    # Verzeichnisse prüfen
    if ($component.Dirs) {
        foreach ($dir in $component.Dirs) {
            $result = Test-DirectoryExists $dir $dir
            if (-not $result.Exists) {
                $componentOk = $false
            }
        }
    }
    
    if ($componentOk) {
        $stats.OkComponents++
    } else {
        $stats.ErrorComponents++
    }
}

# Zusammenfassung
Write-Host "`n=== Zusammenfassung ===" -ForegroundColor $ColorInfo
Write-Status "Komponenten: $($stats.OkComponents)/$($stats.TotalComponents) OK" $(if ($stats.ErrorComponents -eq 0) { "OK" } else { "WARN" }) $(if ($stats.ErrorComponents -eq 0) { $ColorSuccess } else { $ColorWarning })
Write-Status "Dateien: $($stats.TotalFiles - $stats.MissingFiles)/$($stats.TotalFiles) vorhanden" $(if ($stats.MissingFiles -eq 0) { "OK" } else { "WARN" }) $(if ($stats.MissingFiles -eq 0) { $ColorSuccess } else { $ColorWarning })

if ($stats.ErrorComponents -eq 0) {
    Write-Host "`n✅ System ist vollständig installiert!" -ForegroundColor $ColorSuccess
    exit 0
} else {
    Write-Host "`n⚠️  System ist unvollständig. Fehlende Komponenten: $($stats.ErrorComponents)" -ForegroundColor $ColorWarning
    exit 1
}
