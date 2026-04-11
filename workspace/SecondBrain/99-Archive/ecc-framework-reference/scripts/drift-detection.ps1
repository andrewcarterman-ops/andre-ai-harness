#Requires -Version 7.0
<#
.SYNOPSIS
    Drift Detection für ECC Second Brain Vault-Struktur
.DESCRIPTION
    Prüft die Vault-Struktur auf Abweichungen vom Referenz-Manifest
    und generiert Reports mit Auto-Fix-Option
.AUTHOR
    ECC Stability Engine
.VERSION
    1.0.0
#>

[CmdletBinding()]
param(
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    [string]$ConfigPath = "$PSScriptRoot\..\config\drift-config.yaml",
    [string]$ReportPath = "$PSScriptRoot\..\reports\drift-reports",
    [switch]$AutoFix,
    [switch]$Silent
)

# Module-Import
$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Logging-Funktion
function Write-DriftLog {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [string]$Component = "DriftDetection"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    if (-not $Silent) {
        switch ($Level) {
            "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
            "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
            "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        }
    }
    
    # Log in Datei schreiben
    $logDir = Join-Path $VaultPath ".obsidian\logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path (Join-Path $logDir "drift-detection.log") -Value $logEntry
}

# YAML-Parser (einfache Implementierung)
function ConvertFrom-Yaml {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        throw "YAML-Config nicht gefunden: $Path"
    }
    
    $content = Get-Content $Path -Raw
    $result = @{}
    $currentSection = $null
    $indentLevel = 0
    
    foreach ($line in $content -split "`r?`n") {
        $line = $line -replace '#.*$', ''  # Kommentare entfernen
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        $indent = ($line -replace "^\s*", "").Length -eq $line.Length ? 0 : ($line -match "^(\s*)" | ForEach-Object { $matches[1].Length })
        $line = $line.Trim()
        
        if ($line -match "^(\w+):\s*(.*)$") {
            $key = $matches[1]
            $value = $matches[2].Trim()
            
            if ($value -eq "" -or $value -match "^- ") {
                $result[$key] = @()
                $currentSection = $key
            } else {
                $result[$key] = $value -replace '^"|"$' -replace "^'|'$"
            }
        }
        elseif ($line -match "^- (.+)$" -and $currentSection) {
            $result[$currentSection] += $matches[1].Trim() -replace '^"|"$' -replace "^'|'$"
        }
    }
    
    return $result
}

# Vault-Struktur scannen
function Get-VaultStructure {
    param([string]$Path)
    
    $structure = @{
        Directories = @()
        Files = @()
        Metadata = @{}
    }
    
    if (-not (Test-Path $Path)) {
        throw "Vault-Pfad nicht gefunden: $Path"
    }
    
    # Alle Verzeichnisse
    $structure.Directories = Get-ChildItem -Path $Path -Directory -Recurse | 
        Where-Object { $_.FullName -notmatch '\.git|\.obsidian|\.backups|reports' } |
        ForEach-Object { $_.FullName.Substring($Path.Length).TrimStart('\') } |
        Sort-Object
    
    # Alle Dateien
    $structure.Files = Get-ChildItem -Path $Path -File -Recurse |
        Where-Object { $_.FullName -notmatch '\.git|\.obsidian|\.backups|reports' } |
        ForEach-Object {
            @{
                Path = $_.FullName.Substring($Path.Length).TrimStart('\')
                Size = $_.Length
                Hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
                LastModified = $_.LastWriteTime
            }
        } | Sort-Object Path
    
    # Metadaten
    $structure.Metadata = @{
        ScanTime = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        TotalDirs = $structure.Directories.Count
        TotalFiles = $structure.Files.Count
        TotalSize = ($structure.Files | Measure-Object -Property Size -Sum).Sum
    }
    
    return $structure
}

# Drift-Analyse durchführen
function Test-Drift {
    param(
        [hashtable]$Current,
        [hashtable]$Reference,
        [hashtable]$Config
    )
    
    $drifts = @()
    $tolerance = [int]$Config['tolerance_percent']
    
    # Fehlende Verzeichnisse prüfen
    $refDirs = $Reference['required_directories']
    foreach ($dir in $refDirs) {
        $expectedPath = Join-Path $VaultPath $dir
        if (-not (Test-Path $expectedPath)) {
            $drifts += @{
                Type = "MISSING_DIRECTORY"
                Severity = "HIGH"
                Path = $dir
                Expected = "Directory exists"
                Actual = "Not found"
                AutoFixable = $true
            }
        }
    }
    
    # Fehlende Dateien prüfen
    $refFiles = $Reference['required_files']
    foreach ($file in $refFiles) {
        $expectedPath = Join-Path $VaultPath $file
        if (-not (Test-Path $expectedPath)) {
            $drifts += @{
                Type = "MISSING_FILE"
                Severity = if ($file -match 'README|index') { "CRITICAL" } else { "MEDIUM" }
                Path = $file
                Expected = "File exists"
                Actual = "Not found"
                AutoFixable = $true
            }
        }
    }
    
    # Verwaiste Dateien prüfen (optional)
    if ($Config['check_orphaned'] -eq 'true') {
        $allowedExtensions = $Reference['allowed_extensions']
        $orphaned = $Current.Files | Where-Object { 
            $ext = [System.IO.Path]::GetExtension($_.Path)
            $ext -notin $allowedExtensions -and $_.Path -notmatch '\.(md|txt|json|yaml|png|jpg)$'
        }
        
        foreach ($file in $orphaned) {
            $drifts += @{
                Type = "ORPHANED_FILE"
                Severity = "LOW"
                Path = $file.Path
                Expected = "Known file type"
                Actual = "Unknown extension"
                AutoFixable = $false
            }
        }
    }
    
    # Struktur-Integrität prüfen
    $maxDepth = [int]$Reference['max_directory_depth']
    $deepDirs = $Current.Directories | Where-Object { ($_ -split '\\').Count -gt $maxDepth }
    foreach ($dir in $deepDirs) {
        $drifts += @{
            Type = "DEEP_NESTING"
            Severity = "WARN"
            Path = $dir
            Expected = "Max depth: $maxDepth"
            Actual = "Depth: $(($dir -split '\\').Count)"
            AutoFixable = $false
        }
    }
    
    return $drifts
}

# Auto-Fix durchführen
function Repair-Drift {
    param(
        [array]$Drifts,
        [string]$VaultPath
    )
    
    $fixed = 0
    $failed = 0
    
    foreach ($drift in $Drifts | Where-Object { $_.AutoFixable }) {
        try {
            $targetPath = Join-Path $VaultPath $drift.Path
            
            switch ($drift.Type) {
                "MISSING_DIRECTORY" {
                    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                    Write-DriftLog -Level "SUCCESS" -Message "Verzeichnis erstellt: $($drift.Path)"
                    $fixed++
                }
                "MISSING_FILE" {
                    # Template-basierte Datei-Erstellung
                    $template = Get-TemplateForFile -FileName $drift.Path
                    Set-Content -Path $targetPath -Value $template -Encoding UTF8
                    Write-DriftLog -Level "SUCCESS" -Message "Datei erstellt: $($drift.Path)"
                    $fixed++
                }
            }
        }
        catch {
            Write-DriftLog -Level "ERROR" -Message "Fehler bei Auto-Fix für $($drift.Path): $_"
            $failed++
        }
    }
    
    return @{ Fixed = $fixed; Failed = $failed }
}

# Template-Generator
function Get-TemplateForFile {
    param([string]$FileName)
    
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $ext = [System.IO.Path]::GetExtension($FileName)
    
    switch ($ext) {
        ".md" {
            return @"---
created: $(Get-Date -Format "yyyy-MM-dd")
tags: [auto-generated]
status: draft
---

# $baseName

> Auto-generiert durch Drift Detection

## Beschreibung

[Inhalt einfügen...]

## Links

- 
"@
        }
        ".json" {
            return @"{
  "_meta": {
    "created": "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")",
    "autoGenerated": true
  },
  "data": {}
}"@
        }
        default {
            return "# Auto-generated file`n# Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
        }
    }
}

# Report generieren
function Export-DriftReport {
    param(
        [array]$Drifts,
        [hashtable]$Metadata,
        [string]$OutputPath
    )
    
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = Join-Path $OutputPath "drift-report_$timestamp.md"
    
    $report = @"# Drift Detection Report

**Scan Zeit:** $($Metadata.ScanTime)  
**Vault:** $($Metadata.VaultPath)  
**Gesamt Drifts:** $($Drifts.Count)

## Zusammenfassung

| Severity | Anzahl |
|----------|--------|
$(($Drifts | Group-Object Severity | ForEach-Object { "| $($_.Name) | $($_.Count) |" }) -join "`n")

## Detaillierte Ergebnisse

"@

    foreach ($drift in $Drifts | Sort-Object Severity, Type) {
        $report += @"

### $($drift.Type) - $($drift.Severity)

- **Pfad:** \`$($drift.Path)\`
- **Erwartet:** $($drift.Expected)
- **Aktuell:** $($drift.Actual)
- **Auto-Fix:** $(if ($drift.AutoFixable) { "✅ Möglich" } else { "❌ Nicht möglich" })

"@
    }

    $report += @"

## Empfohlene Aktionen

1. $(if ($Drifts | Where-Object { $_.Severity -eq 'CRITICAL' }) { "KRITISCHE Drifts sofort beheben" } else { "Keine kritischen Drifts gefunden ✅" })
2. $(if ($Drifts | Where-Object { $_.Severity -eq 'HIGH' }) { "HIGH-Priority Drifts priorisieren" } else { "Keine High-Priority Drifts ✅" })
3. $(if ($Drifts | Where-Object { $_.AutoFixable }) { "Auto-Fix für $($Drifts.AutoFixable.Count) Drifts ausführen" } else { "Keine Auto-Fixes verfügbar" })

---
*Generiert durch ECC Drift Detection v1.0.0*
"@

    Set-Content -Path $reportFile -Value $report -Encoding UTF8
    Write-DriftLog -Level "SUCCESS" -Message "Report gespeichert: $reportFile"
    
    return $reportFile
}

# ═══════════════════════════════════════════════════════════════
# HAUPTLOGIK
# ═══════════════════════════════════════════════════════════════

Write-DriftLog -Level "INFO" -Message "=== ECC Drift Detection gestartet ==="
Write-DriftLog -Level "INFO" -Message "Vault: $VaultPath"

# Konfiguration laden
try {
    $config = ConvertFrom-Yaml -Path $ConfigPath
    Write-DriftLog -Level "SUCCESS" -Message "Konfiguration geladen: $ConfigPath"
}
catch {
    Write-DriftLog -Level "ERROR" -Message "Konfigurationsfehler: $_"
    exit 1
}

# Referenz-Manifest laden
$manifestPath = Join-Path (Split-Path $ConfigPath) $config['reference_manifest']
if (-not (Test-Path $manifestPath)) {
    Write-DriftLog -Level "ERROR" -Message "Manifest nicht gefunden: $manifestPath"
    exit 1
}

$reference = ConvertFrom-Yaml -Path $manifestPath

# Aktuelle Struktur scannen
Write-DriftLog -Level "INFO" -Message "Scanne Vault-Struktur..."
$current = Get-VaultStructure -Path $VaultPath
Write-DriftLog -Level "SUCCESS" -Message "Gefunden: $($current.Metadata.TotalDirs) Verzeichnisse, $($current.Metadata.TotalFiles) Dateien"

# Drift-Analyse
Write-DriftLog -Level "INFO" -Message "Analysiere Drifts..."
$drifts = Test-Drift -Current $current -Reference $reference -Config $config

if ($drifts.Count -eq 0) {
    Write-DriftLog -Level "SUCCESS" -Message "✅ Keine Drifts gefunden! Vault ist konsistent."
    exit 0
}

Write-DriftLog -Level "WARN" -Message "⚠️  $($drifts.Count) Drift(s) gefunden:"
$drifts | Group-Object Severity | ForEach-Object {
    Write-DriftLog -Level $_.Name -Message "  - $($_.Name): $($_.Count)"
}

# Report generieren
$reportFile = Export-DriftReport -Drifts $drifts -Metadata $current.Metadata -OutputPath $ReportPath

# Auto-Fix
if ($AutoFix) {
    Write-DriftLog -Level "INFO" -Message "Starte Auto-Fix..."
    $result = Repair-Drift -Drifts $drifts -VaultPath $VaultPath
    Write-DriftLog -Level "SUCCESS" -Message "Auto-Fix abgeschlossen: $($result.Fixed) erfolgreich, $($result.Failed) fehlgeschlagen"
}

# Exit-Code basierend auf Severity
$criticalCount = ($drifts | Where-Object { $_.Severity -eq 'CRITICAL' }).Count
$highCount = ($drifts | Where-Object { $_.Severity -eq 'HIGH' }).Count

if ($criticalCount -gt 0) { exit 3 }
elseif ($highCount -gt 0) { exit 2 }
else { exit 1 }
