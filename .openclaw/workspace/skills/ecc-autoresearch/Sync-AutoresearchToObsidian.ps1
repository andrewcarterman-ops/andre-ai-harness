#Requires -Version 7.0
<#
.SYNOPSIS
    Sync-AutoresearchToObsidian - Integration von autoresearch mit ECC Second Brain

.DESCRIPTION
    Synchronisiert Experiment-Ergebnisse aus autoresearch automatisch in den Obsidian Vault.
    Erstellt strukturierte Notizen, Dashboards und Knowledge Graphs.

.PARAMETER VaultPath
    Pfad zum Obsidian Vault

.PARAMETER AutoresearchPath
    Pfad zum autoresearch Repository

.PARAMETER SyncMode
    Sync-Modus: Full, Incremental, DashboardOnly

.EXAMPLE
    Sync-AutoresearchToObsidian -VaultPath "~\Documents\SecondBrain" -AutoresearchPath "~\autoresearch"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$VaultPath = "$env:USERPROFILE\Documents\Andrew Openclaw\SecondBrain",
    
    [Parameter(Mandatory = $false)]
    [string]$AutoresearchPath = "$env:USERPROFILE\Documents\Andrew Openclaw\autoresearch",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Full", "Incremental", "DashboardOnly", "ExperimentOnly")]
    [string]$SyncMode = "Incremental",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateGraph,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# ============================================================================
# KONFIGURATION
# ============================================================================

$script:Config = @{
    VaultPath = $VaultPath
    AutoresearchPath = $AutoresearchPath
    TargetDir = "PARA\Projects\Autoresearch"
    ExperimentsDir = "PARA\Projects\Autoresearch\Experiments"
    DashboardFile = "PARA\Projects\Autoresearch\Dashboard.md"
    InsightsFile = "PARA\Projects\Autoresearch\Insights.md"
    ArchiveDir = "PARA\Archive\Autoresearch"
    
    # Templates
    ExperimentTemplate = @'
---
date: {{DATE}}
type: experiment
status: {{STATUS}}
val_bpb: {{VAL_BPB}}
commit: {{COMMIT}}
iteration: {{ITERATION}}
tags: autoresearch, experiment, {{TAGS}}
---

# Experiment {{ITERATION}}: {{DESCRIPTION}}

## Metriken
| Metrik | Wert |
|--------|------|
| val_bpb | {{VAL_BPB}} |
| Memory | {{MEMORY_GB}} GB |
| Status | {{STATUS}} |
| Dauer | {{DURATION}} |
| Safety Score | {{SAFETY_SCORE}} |

## Änderungen
```diff
{{GIT_DIFF}}
```

## Hypothese
{{HYPOTHESIS}}

## Ergebnisanalyse
{{ANALYSIS}}

## Verwandte Experimente
{{RELATED_EXPERIMENTS}}

---
*Automatisch generiert von ECC-Autoresearch Sync*
'@

    DashboardTemplate = @'
---
date: {{DATE}}
type: dashboard
tags: autoresearch, overview, dashboard
---

# 🤖 Autoresearch Dashboard

> Letzte Aktualisierung: {{TIMESTAMP}}

## 📊 Zusammenfassung

| Metrik | Wert |
|--------|------|
| **Gesamt Experimente** | {{TOTAL_EXPERIMENTS}} |
| **Erfolgreich** | {{SUCCESS_COUNT}} ({{SUCCESS_RATE}}%) |
| **Bestes val_bpb** | {{BEST_VAL_BPB}} |
| **Baseline** | {{BASELINE_VAL_BPB}} |
| **Verbesserung** | {{IMPROVEMENT}} |
| **Aktiver Branch** | {{ACTIVE_BRANCH}} |
| **Laufzeit** | {{RUNTIME}} |

## 📈 Trend (letzte 20 Experimente)

```mermaid
xychart-beta
    title "val_bpb über Zeit"
    x-axis [{{X_AXIS_LABELS}}]
    y-axis "val_bpb" {{Y_MIN}} --> {{Y_MAX}}
    line [{{VAL_BPB_VALUES}}]
```

## 🏆 Top 5 Experimente

| Rang | Commit | val_bpb | Δ | Beschreibung |
|------|--------|---------|---|--------------|
{{TOP_EXPERIMENTS}}

## 📋 Letzte 10 Experimente

| # | Datum | Status | val_bpb | Beschreibung |
|---|-------|--------|---------|--------------|
{{RECENT_EXPERIMENTS}}

## 🔍 Insights (KI-generiert)

{{AI_INSIGHTS}}

## 🎯 Nächste Schritte

{{NEXT_STEPS}}

---

## Verknüpfungen

- [[Insights]] - Detaillierte Analysen
- [[Experiments]] - Alle Experimente
- [[Safety Log]] - Sicherheitsberichte

'@
}

# ============================================================================
# HILFSFUNKTIONEN
# ============================================================================

function Initialize-ObsidianStructure {
    <#
    .SYNOPSIS
        Erstellt die Verzeichnisstruktur im Obsidian Vault
    #>
    param([string]$BasePath)
    
    $directories = @(
        "$BasePath\$($script:Config.ExperimentsDir)",
        "$BasePath\$($script:Config.TargetDir)\Safety",
        "$BasePath\$($script:Config.TargetDir)\Snapshots",
        "$BasePath\$($script:Config.ArchiveDir)"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "✓ Verzeichnis erstellt: $dir" -ForegroundColor Green
        }
    }
}

function Read-ResultsTsv {
    <#
    .SYNOPSIS
        Liest die results.tsv Datei aus autoresearch
    #>
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        Write-Warning "results.tsv nicht gefunden: $Path"
        return @()
    }
    
    $results = Import-Csv -Path $Path -Delimiter "`t"
    return $results
}

function Get-GitDiff {
    <#
    .SYNOPSIS
        Holt den Git-Diff für einen bestimmten Commit
    #>
    param(
        [string]$CommitHash,
        [string]$RepoPath
    )
    
    Push-Location $RepoPath
    try {
        # Diff zum Parent
        $diff = git diff "${CommitHash}^..${CommitHash}" --stat 2>$null
        if ($LASTEXITCODE -ne 0) {
            return "(Diff nicht verfügbar)"
        }
        return $diff
    }
    finally {
        Pop-Location
    }
}

function Get-CommitMessage {
    <#
    .SYNOPSIS
        Holt die Commit-Message für einen Hash
    #>
    param(
        [string]$CommitHash,
        [string]$RepoPath
    )
    
    Push-Location $RepoPath
    try {
        $msg = git log -1 --pretty=format:"%s" $CommitHash 2>$null
        return $msg
    }
    finally {
        Pop-Location
    }
}

function ConvertTo-ObsidianNote {
    <#
    .SYNOPSIS
        Konvertiert ein Experiment-Ergebnis in eine Obsidian-Notiz
    #>
    param(
        [PSCustomObject]$Experiment,
        [string]$RepoPath,
        [int]$Iteration
    )
    
    $template = $script:Config.ExperimentTemplate
    
    # Daten sammeln
    $date = [DateTime]::Parse($Experiment.timestamp).ToString("yyyy-MM-dd")
    $diff = Get-GitDiff -CommitHash $Experiment.commit -RepoPath $RepoPath
    $commitMsg = Get-CommitMessage -CommitHash $Experiment.commit -RepoPath $RepoPath
    
    # Tags basierend auf Beschreibung
    $tags = @()
    $desc = $Experiment.description.ToLower()
    if ($desc -match "lr|learning|rate") { $tags += "hyperparameters" }
    if ($desc -match "layer|depth|width|attention") { $tags += "architecture" }
    if ($desc -match "adam|muon|optimizer") { $tags += "optimizer" }
    if ($desc -match "batch|size") { $tags += "batch-size" }
    if ($desc -match "baseline|default") { $tags += "baseline" }
    if ($tags.Count -eq 0) { $tags += "other" }
    
    # Template ersetzen
    $note = $template `
        -replace "{{DATE}}", $date `
        -replace "{{STATUS}}", $Experiment.status `
        -replace "{{VAL_BPB}}", $Experiment.val_bpb `
        -replace "{{COMMIT}}", $Experiment.commit `
        -replace "{{ITERATION}}", $Iteration `
        -replace "{{TAGS}}", ($tags -join ", ") `
        -replace "{{DESCRIPTION}}", $Experiment.description `
        -replace "{{MEMORY_GB}}", $Experiment.memory_gb `
        -replace "{{DURATION}}", (if ($Experiment.duration_sec) { "$($Experiment.duration_sec)s" } else { "300s" }) `
        -replace "{{SAFETY_SCORE}}", (if ($Experiment.safety_score) { $Experiment.safety_score } else { "N/A" }) `
        -replace "{{GIT_DIFF}}", $diff `
        -replace "{{HYPOTHESIS}}", $commitMsg `
        -replace "{{ANALYSIS}}", "(Automatische Analyse folgt...)" `
        -replace "{{RELATED_EXPERIMENTS}}", "- [[Experiment $($Iteration-1)]]"
    
    return $note
}

function Update-Dashboard {
    <#
    .SYNOPSIS
        Aktualisiert das Dashboard mit aktuellen Statistiken
    #>
    param(
        [array]$Results,
        [string]$RepoPath
    )
    
    $template = $script:Config.DashboardTemplate
    
    # Statistiken berechnen
    $total = $Results.Count
    $successful = ($Results | Where-Object { $_.status -eq "keep" }).Count
    $successRate = if ($total -gt 0) { [math]::Round(($successful / $total) * 100, 1) } else { 0 }
    
    $best = $Results | Where-Object { $_.val_bpb -gt 0 } | Sort-Object { [double]$_.val_bpb } | Select-Object -First 1
    $baseline = $Results | Where-Object { $_.description -match "baseline" } | Select-Object -First 1
    
    $improvement = if ($baseline -and $best) {
        $diff = [double]$baseline.val_bpb - [double]$best.val_bpb
        "+$([math]::Round($diff, 4))"
    } else { "N/A" }
    
    # Aktiver Branch
    Push-Location $RepoPath
    $activeBranch = git branch --show-current 2>$null
    Pop-Location
    
    # Top 5
    $top5 = $Results | Where-Object { $_.val_bpb -gt 0 } | Sort-Object { [double]$_.val_bpb } | Select-Object -First 5
    $topTable = $top5 | ForEach-Object -Begin { $i = 1 } {
        "| $i | $($_.commit) | $($_.val_bpb) | $([math]::Round([double]$baseline.val_bpb - [double]$_.val_bpb, 4)) | $($_.description) |"
        $i++
    }
    
    # Letzte 10
    $recent = $Results | Select-Object -Last 10
    $recentTable = $recent | ForEach-Object -Begin { $i = $Results.Count - 9 } {
        $date = if ($_.timestamp) { ([DateTime]::Parse($_.timestamp)).ToString("MM-dd") } else { "?" }
        "| $i | $date | $($_.status) | $($_.val_bpb) | $($_.description.Substring(0, [Math]::Min(40, $_.description.Length)))... |"
        $i++
    }
    
    # Mermaid-Daten (letzte 20)
    $last20 = $Results | Select-Object -Last 20
    $valBpbValues = ($last20 | ForEach-Object { $_.val_bpb }) -join ", "
    $xLabels = (1..20 | ForEach-Object { "$_" }) -join ", "
    $yMin = [math]::Floor(($last20 | Measure-Object -Property { [double]$_.val_bpb } -Minimum).Minimum * 10) / 10
    $yMax = [math]::Ceiling(($last20 | Measure-Object -Property { [double]$_.val_bpb } -Maximum).Maximum * 10) / 10
    
    # Template ersetzen
    $dashboard = $template `
        -replace "{{DATE}}", (Get-Date -Format "yyyy-MM-dd") `
        -replace "{{TIMESTAMP}}", (Get-Date -Format "yyyy-MM-dd HH:mm:ss") `
        -replace "{{TOTAL_EXPERIMENTS}}", $total `
        -replace "{{SUCCESS_COUNT}}", $successful `
        -replace "{{SUCCESS_RATE}}", $successRate `
        -replace "{{BEST_VAL_BPB}}", ($best.val_bpb ?? "N/A") `
        -replace "{{BASELINE_VAL_BPB}}", ($baseline.val_bpb ?? "N/A") `
        -replace "{{IMPROVEMENT}}", $improvement `
        -replace "{{ACTIVE_BRANCH}}", ($activeBranch ?? "unknown") `
        -replace "{{RUNTIME}}", "$(if ($total -gt 0) { [math]::Round($total * 5 / 60, 1) } else { 0 })h" `
        -replace "{{X_AXIS_LABELS}}", $xLabels `
        -replace "{{Y_MIN}}", $yMin `
        -replace "{{Y_MAX}}", $yMax `
        -replace "{{VAL_BPB_VALUES}}", $valBpbValues `
        -replace "{{TOP_EXPERIMENTS}}", ($topTable -join "`n") `
        -replace "{{RECENT_EXPERIMENTS}}", ($recentTable -join "`n") `
        -replace "{{AI_INSIGHTS}}", "(KI-Analyse folgt...)" `
        -replace "{{NEXT_STEPS}}", "- Weitere Experimente durchführen`n- Beste Konfiguration verifizieren"
    
    return $dashboard
}

function Update-KnowledgeGraph {
    <#
    .SYNOPSIS
        Aktualisiert Knowledge Graph Links zwischen Experimenten
    #>
    param(
        [array]$Results,
        [string]$VaultPath
    )
    
    $experimentsDir = "$VaultPath\$($script:Config.ExperimentsDir)"
    $files = Get-ChildItem -Path $experimentsDir -Filter "*.md" | Sort-Object Name
    
    for ($i = 0; $i -lt $files.Count; $i++) {
        $file = $files[$i]
        $content = Get-Content $file.FullName -Raw
        
        # Links aktualisieren
        $links = @()
        
        # Vorheriges Experiment
        if ($i -gt 0) {
            $prev = $files[$i - 1].BaseName
            $links += "- ← [[$prev|Vorheriges Experiment]]"
        }
        
        # Nächstes Experiment
        if ($i -lt $files.Count - 1) {
            $next = $files[$i + 1].BaseName
            $links += "- → [[$next|Nächstes Experiment]]"
        }
        
        # Dashboard
        $links += "- ↑ [[Dashboard|Zurück zum Dashboard]]"
        
        # Verwandte Experimente (gleiche Tags)
        # (Vereinfacht - in echter Implementation: Tag-basierte Verknüpfung)
        
        $linksSection = "## Verknüpfungen`n`n" + ($links -join "`n")
        
        # Inhalt aktualisieren
        if ($content -match "## Verknüpfungen") {
            $content = $content -replace "## Verknüpfungen[\s\S]*?(?=## |$)", $linksSection
        } else {
            $content += "`n`n$linksSection"
        }
        
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
    }
    
    Write-Host "✓ Knowledge Graph aktualisiert" -ForegroundColor Green
}

# ============================================================================
# HAUPTFUNKTION
# ============================================================================

function Sync-AutoresearchToObsidian {
    [CmdletBinding()]
    param()
    
    Write-Host "`n🔄 ECC-Autoresearch → Obsidian Sync" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    
    # Pfade validieren
    if (!(Test-Path $script:Config.AutoresearchPath)) {
        Write-Error "Autoresearch-Pfad nicht gefunden: $($script:Config.AutoresearchPath)"
        return
    }
    
    if (!(Test-Path $script:Config.VaultPath)) {
        Write-Error "Vault-Pfad nicht gefunden: $($script:Config.VaultPath)"
        return
    }
    
    # Struktur initialisieren
    Write-Host "`n📁 Initialisiere Verzeichnisstruktur..." -ForegroundColor Gray
    Initialize-ObsidianStructure -BasePath $script:Config.VaultPath
    
    # Results laden
    Write-Host "`n📊 Lade Experiment-Daten..." -ForegroundColor Gray
    $results = Read-ResultsTsv -Path "$($script:Config.AutoresearchPath)\results.tsv"
    
    if ($results.Count -eq 0) {
        Write-Warning "Keine Experiment-Daten gefunden"
        return
    }
    
    Write-Host "   Gefunden: $($results.Count) Experimente" -ForegroundColor White
    
    # Experiments syncen
    if ($SyncMode -in @("Full", "Incremental", "ExperimentOnly")) {
        Write-Host "`n📝 Synchronisiere Experiment-Notizen..." -ForegroundColor Gray
        
        $iteration = 1
        foreach ($exp in $results) {
            $note = ConvertTo-ObsidianNote -Experiment $exp -RepoPath $script:Config.AutoresearchPath -Iteration $iteration
            $notePath = "$($script:Config.VaultPath)\$($script:Config.ExperimentsDir)\exp-$($iteration.ToString("000"))-$($exp.commit).md"
            
            # Nur schreiben wenn neu oder Force
            if ($Force -or !(Test-Path $notePath)) {
                Set-Content -Path $notePath -Value $note -Encoding UTF8
                Write-Host "   ✓ Experiment $iteration: $($exp.commit)" -ForegroundColor Green
            } else {
                Write-Host "   ⏭ Experiment $iteration: $($exp.commit) (übersprungen)" -ForegroundColor Gray
            }
            
            $iteration++
        }
    }
    
    # Dashboard aktualisieren
    if ($SyncMode -in @("Full", "Incremental", "DashboardOnly")) {
        Write-Host "`n📈 Aktualisiere Dashboard..." -ForegroundColor Gray
        
        $dashboard = Update-Dashboard -Results $results -RepoPath $script:Config.AutoresearchPath
        $dashboardPath = "$($script:Config.VaultPath)\$($script:Config.DashboardFile)"
        Set-Content -Path $dashboardPath -Value $dashboard -Encoding UTF8
        
        Write-Host "   ✓ Dashboard: $dashboardPath" -ForegroundColor Green
    }
    
    # Knowledge Graph
    if ($GenerateGraph) {
        Write-Host "`n🕸️  Aktualisiere Knowledge Graph..." -ForegroundColor Gray
        Update-KnowledgeGraph -Results $results -VaultPath $script:Config.VaultPath
    }
    
    # Zusammenfassung
    Write-Host "`n✅ Sync abgeschlossen!" -ForegroundColor Cyan
    Write-Host "   • Experimente: $($results.Count)" -ForegroundColor White
    Write-Host "   • Vault: $VaultPath" -ForegroundColor White
    Write-Host "   • Dashboard: [[Dashboard]]" -ForegroundColor White
}

# ============================================================================
# AUSFÜHRUNG
# ============================================================================

# Parameter an Funktion übergeben
Sync-AutoresearchToObsidian
