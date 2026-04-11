#Requires -Version 5.1
<#
.SYNOPSIS
    Drift Detection fuer SecondBrain Vault-Struktur
.DESCRIPTION
    Prueft die Vault-Struktur auf Abweichungen vom Referenz-Manifest
    und generiert Reports mit Auto-Fix-Option
.AUTHOR
    Parzival's Agent
.VERSION
    1.0.0
#>

[CmdletBinding()]
param(
    [string]$VaultPath = "C:\Users\andre\.openclaw\workspace\SecondBrain",
    [string]$ManifestPath = "$PSScriptRoot\..\..\..\00-Meta\Config\vault-manifest.yaml",
    [string]$ReportPath = "$PSScriptRoot\..\..\..\00-Meta\Backups\drift-reports",
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
    $logDir = Join-Path $VaultPath "00-Meta\Backups\logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path (Join-Path $logDir "drift-detection.log") -Value $logEntry
}

# Vault-Struktur scannen
function Get-VaultStructure {
    param([string]$Path)
    
    $structure = @{
        Directories = @()
        Files = @()
        Metadata = @{
            VaultPath = $Path
        }
    }
    
    if (-not (Test-Path $Path)) {
        throw "Vault-Pfad nicht gefunden: $Path"
    }
    
    # Alle Verzeichnisse
    $structure.Directories = Get-ChildItem -Path $Path -Directory -Recurse | 
        Where-Object { $_.FullName -notmatch '\.git|node_modules' } |
        ForEach-Object { $_.FullName.Substring($Path.Length).TrimStart('\') } |
        Sort-Object
    
    # Alle Dateien mit Groessen
    $fileList = Get-ChildItem -Path $Path -File -Recurse |
        Where-Object { $_.FullName -notmatch '\.git|node_modules' }
    
    $totalSize = 0
    $structure.Files = $fileList | ForEach-Object {
        $totalSize += $_.Length
        @{
            Path = $_.FullName.Substring($Path.Length).TrimStart('\')
            Size = $_.Length
            LastModified = $_.LastWriteTime
        }
    } | Sort-Object Path
    
    # Metadaten
    $structure.Metadata = @{
        ScanTime = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        TotalDirs = $structure.Directories.Count
        TotalFiles = $structure.Files.Count
        TotalSize = $totalSize
    }
    
    return $structure
}

# Drift-Analyse durchfuehren
function Test-Drift {
    param(
        [hashtable]$Current,
        [array]$RequiredDirs,
        [array]$RequiredFiles
    )
    
    $drifts = @()
    
    # Fehlende Verzeichnisse pruefen
    foreach ($dir in $RequiredDirs) {
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
    
    # Fehlende Dateien pruefen
    foreach ($file in $RequiredFiles) {
        $expectedPath = Join-Path $VaultPath $file
        if (-not (Test-Path $expectedPath)) {
            $drifts += @{
                Type = "MISSING_FILE"
                Severity = if ($file -match 'README|_MOC') { "CRITICAL" } else { "MEDIUM" }
                Path = $file
                Expected = "File exists"
                Actual = "Not found"
                AutoFixable = $true
            }
        }
    }
    
    return $drifts
}

# Auto-Fix durchfuehren
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
                    $template = Get-TemplateForFile -FileName $drift.Path
                    Set-Content -Path $targetPath -Value $template -Encoding UTF8
                    Write-DriftLog -Level "SUCCESS" -Message "Datei erstellt: $($drift.Path)"
                    $fixed++
                }
            }
        }
        catch {
            Write-DriftLog -Level "ERROR" -Message "Fehler bei Auto-Fix fuer $($drift.Path): $_"
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
    $date = Get-Date -Format "dd-MM-yyyy"
    
    if ($ext -eq ".md") {
        if ($FileName -match "\d{2}-\d{2}-\d{4}") {
            # Daily Note
            return "---`ndate: $date`ntype: daily`ntags: [daily]`n---`n`n# $date`n`n## Erledigt`n`n- [ ] `n`n## Notizen`n`n"
        }
        elseif ($FileName -match "README") {
            # README
            return "# $baseName`n`n> Beschreibung des Ordners`n`n## Inhalt`n`n- `n"
        }
        else {
            # Standard Note
            return "---`ndate: $date`ntype: note`ntags: []`n---`n`n# $baseName`n`n> Auto-generiert durch Drift Detection`n`n## Beschreibung`n`n[Inhalt einfuegen...]`n`n## Links`n`n- `n"
        }
    }
    else {
        return "# Auto-generated file`n# Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
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
    
    $severityTable = ($Drifts | Group-Object Severity | ForEach-Object { "| $($_.Name) | $($_.Count) |" }) -join "`n"
    
    $report = "# Drift Detection Report`n`n"
    $report += "**Scan Zeit:** $($Metadata.ScanTime)  `n"
    $report += "**Vault:** $($Metadata.VaultPath)  `n"
    $report += "**Gesamt Drifts:** $($Drifts.Count)`n`n"
    $report += "## Zusammenfassung`n`n"
    $report += "| Severity | Anzahl |`n"
    $report += "|----------|--------|`n"
    $report += "$severityTable`n`n"
    $report += "## Detaillierte Ergebnisse`n`n"

    foreach ($drift in $Drifts | Sort-Object Severity, Type) {
        $autoFixText = if ($drift.AutoFixable) { "Moeglich" } else { "Nicht moeglich" }
        $report += "### $($drift.Type) - $($drift.Severity)`n`n"
        $report += "- **Pfad:** $($drift.Path)`n"
        $report += "- **Erwartet:** $($drift.Expected)`n"
        $report += "- **Aktuell:** $($drift.Actual)`n"
        $report += "- **Auto-Fix:** $autoFixText`n`n"
    }

    $criticalText = if ($Drifts | Where-Object { $_.Severity -eq 'CRITICAL' }) { "KRITISCHE Drifts sofort beheben" } else { "Keine kritischen Drifts gefunden" }
    $highText = if ($Drifts | Where-Object { $_.Severity -eq 'HIGH' }) { "HIGH-Priority Drifts priorisieren" } else { "Keine High-Priority Drifts" }
    $fixText = if ($Drifts | Where-Object { $_.AutoFixable }) { "Auto-Fix fuer Drifts ausfuehren" } else { "Keine Auto-Fixes verfuegbar" }

    $report += "## Empfohlene Aktionen`n`n"
    $report += "1. $criticalText`n"
    $report += "2. $highText`n"
    $report += "3. $fixText`n`n"
    $report += "---`n"
    $report += "*Generiert durch Drift Detection v1.0.0*"

    Set-Content -Path $reportFile -Value $report -Encoding UTF8
    Write-DriftLog -Level "SUCCESS" -Message "Report gespeichert: $reportFile"
    
    return $reportFile
}

# ═══════════════════════════════════════════════════════════════
# HAUPTLOGIK
# ═══════════════════════════════════════════════════════════════

Write-DriftLog -Level "INFO" -Message "=== SecondBrain Drift Detection gestartet ==="
Write-DriftLog -Level "INFO" -Message "Vault: $VaultPath"

# Manifest laden
try {
    $manifestContent = Get-Content $ManifestPath -Raw
    Write-DriftLog -Level "SUCCESS" -Message "Manifest geladen: $ManifestPath"
    
    # Einfache YAML-Parsing
    $requiredDirs = @()
    $requiredFiles = @()
    $inDirs = $false
    $inFiles = $false
    
    foreach ($line in $manifestContent -split "`r?`n") {
        $line = $line.Trim()
        if ($line -match "^required_directories:") { $inDirs = $true; $inFiles = $false; continue }
        if ($line -match "^required_files:") { $inDirs = $false; $inFiles = $true; continue }
        if ($line -match "^allowed_extensions:") { $inDirs = $false; $inFiles = $false; continue }
        
        # Pruefe auf Listen-Elemente
        if ($line -match "^- `"(.+)`"") {
            $value = $matches[1]
            if ($inDirs) { $requiredDirs += $value }
            if ($inFiles) { $requiredFiles += $value }
        }
        elseif ($line -match "^- '(.+)'") {
            $value = $matches[1]
            if ($inDirs) { $requiredDirs += $value }
            if ($inFiles) { $requiredFiles += $value }
        }
    }
}
catch {
    Write-DriftLog -Level "ERROR" -Message "Manifest-Fehler: $_"
    exit 1
}

# Aktuelle Struktur scannen
Write-DriftLog -Level "INFO" -Message "Scanne Vault-Struktur..."
$current = Get-VaultStructure -Path $VaultPath
Write-DriftLog -Level "SUCCESS" -Message "Gefunden: $($current.Metadata.TotalDirs) Verzeichnisse, $($current.Metadata.TotalFiles) Dateien"

# Drift-Analyse
Write-DriftLog -Level "INFO" -Message "Analysiere Drifts..."
$drifts = Test-Drift -Current $current -RequiredDirs $requiredDirs -RequiredFiles $requiredFiles

if ($drifts.Count -eq 0) {
    Write-DriftLog -Level "SUCCESS" -Message "Keine Drifts gefunden! Vault ist konsistent."
    exit 0
}

Write-DriftLog -Level "WARN" -Message "$($drifts.Count) Drift(s) gefunden:"
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
