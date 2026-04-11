#Requires -Version 5.1
<#
.SYNOPSIS
    Context Switch für SecondBrain - Vereinfachte Version

.DESCRIPTION
    Überwacht Token-Usage und erstellt bei Bedarf eine komprimierte Zusammenfassung.
    Vereinfachte Version ohne komplexe YAML-Config.

.PARAMETER CurrentUsage
    Aktuelle Token-Usage in Prozent (0-100)

.PARAMETER Force
    Zusammenfassung sofort erstellen

.EXAMPLE
    .\context-switch.ps1 -CurrentUsage 85
    .\context-switch.ps1 -Force

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0-simplified
    Location: SecondBrain/00-Meta/Scripts/ecc-framework/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 100)]
    [int]$CurrentUsage = 0,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Einfache Thresholds (fest codiert für Einfachheit)
$ThresholdWarning = 70
$ThresholdCompression = 80
$ThresholdEmergency = 90

#region Functions

function Write-ContextLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
}

function Get-RecentSessions {
    # Hole die letzten 5 Daily Notes
    $dailyPath = "01-Daily"
    if (!(Test-Path $dailyPath)) {
        return @()
    }
    
    return Get-ChildItem $dailyPath -Filter "*.md" -File | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 5
}

function Extract-KeyInfo {
    param([array]$Sessions)
    
    $info = @{
        Decisions = @()
        TODOs = @()
        Insights = @()
    }
    
    foreach ($session in $Sessions) {
        $content = Get-Content $session.FullName -Raw -ErrorAction SilentlyContinue
        if (!$content) { continue }
        
        # Suche nach Entscheidungen (einfache Heuristik)
        if ($content -match "(?m)^#{1,3}.*?(?:Entscheidung|Decision).*?$(.*?)(?=^#{1,3}|\z)") {
            $lines = $Matches[1] -split "`n" | Where-Object { $_ -match "^- " }
            $info.Decisions += $lines
        }
        
        # Suche nach TODOs
        if ($content -match "(?m)^#{1,3}.*?(?:TODO|Nächste Schritte).*?$(.*?)(?=^#{1,3}|\z)") {
            $lines = $Matches[1] -split "`n" | Where-Object { $_ -match "^- \[ \]" }
            $info.TODOs += $lines
        }
        
        # Suche nach Insights/Erkenntnissen
        if ($content -match "(?m)^#{1,3}.*?(?:Erkenntnis|Insight|Gedanke).*?$(.*?)(?=^#{1,3}|\z)") {
            $lines = $Matches[1] -split "`n" | Where-Object { $_ -match "^- " }
            $info.Insights += $lines
        }
    }
    
    return $info
}

function New-ContextSummary {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $summaryFile = "01-Daily\CONTEXT_SUMMARY_$timestamp.md"
    
    Write-ContextLog "Erstelle Context-Zusammenfassung..." -Level "INFO"
    
    # Sammle Infos
    $sessions = Get-RecentSessions
    $info = Extract-KeyInfo -Sessions $sessions
    
    # Erstelle Summary
    $summary = @"---
date: $(Get-Date -Format "dd-MM-yyyy")
type: context_summary
source_sessions: $($sessions.Count)
---

# Context Zusammenfassung ($(Get-Date -Format "dd-MM-yyyy HH:mm"))

## Aktive Projekte
*Siehe [[../02-Projects/|Projekte]]*

## Offene TODOs
$(if ($info.TODOs) { $info.TODOs -join "`n" } else { "- Keine offenen TODOs gefunden" })

## Wichtige Entscheidungen
$(if ($info.Decisions) { $info.Decisions -join "`n" } else { "- Keine Entscheidungen gefunden" })

## Erkenntnisse
$(if ($info.Insights) { $info.Insights -join "`n" } else { "- Keine Erkenntnisse gefunden" })

---
*Automatisch generiert bei hoher Token-Auslastung*
"@
    
    $summary | Set-Content $summaryFile -Encoding UTF8
    Write-ContextLog "Zusammenfassung erstellt: $summaryFile" -Level "SUCCESS"
    
    return $summaryFile
}

#endregion

#region Main

Write-ContextLog "=== SecondBrain Context Switch (Vereinfacht) ===" -Level "INFO"

# Prüfe Usage
if ($Force) {
    Write-ContextLog "Manuelle Context-Zusammenfassung angefordert" -Level "WARN"
    New-ContextSummary
}
elseif ($CurrentUsage -gt 0) {
    if ($CurrentUsage -lt $ThresholdWarning) {
        Write-ContextLog "Token-Auslastung normal: $CurrentUsage%" -Level "INFO"
    }
    elseif ($CurrentUsage -lt $ThresholdCompression) {
        Write-ContextLog "Token-Auslastung hoch: $CurrentUsage% - Bald Zusammenfassung empfohlen" -Level "WARN"
    }
    elseif ($CurrentUsage -lt $ThresholdEmergency) {
        Write-ContextLog "Token-Auslastung kritisch: $CurrentUsage% - Erstelle Zusammenfassung..." -Level "WARN"
        New-ContextSummary
    }
    else {
        Write-ContextLog "Token-Auslastung EMERGENCY: $CurrentUsage% - Sofortmaßnahme!" -Level "ERROR"
        New-ContextSummary
        Write-ContextLog "Bitte neue Session starten oder Kontext manuell bereinigen" -Level "WARN"
    }
}
else {
    Write-ContextLog "Keine Usage-Daten. Nutzung: .\context-switch.ps1 -CurrentUsage 75" -Level "INFO"
}

#endregion