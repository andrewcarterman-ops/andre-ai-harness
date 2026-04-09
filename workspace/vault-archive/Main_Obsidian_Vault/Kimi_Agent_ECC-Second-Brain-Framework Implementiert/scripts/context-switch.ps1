#Requires -Version 7.0
<#
.SYNOPSIS
    Context Switch Management für ECC Second Brain
.DESCRIPTION
    Überwacht Token-Usage und komprimiert Context bei 80% Threshold
    mit Session-Checkpointing und YAML-Config für Thresholds
.AUTHOR
    ECC Stability Engine
.VERSION
    1.0.0
#>

[CmdletBinding()]
param(
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    [string]$ConfigPath = "$PSScriptRoot\..\config\stability-config.yaml",
    [string]$SessionId = [Guid]::NewGuid().ToString().Substring(0, 8),
    [switch]$Monitor,
    [switch]$Compress,
    [switch]$Checkpoint,
    [switch]$Status,
    [int]$CurrentTokens = 0,
    [int]$MaxTokens = 8192,
    [switch]$Silent
)

# ═══════════════════════════════════════════════════════════════
# INITIALISIERUNG
# ═══════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Globale Statistik
$script:TokenStats = @{
    SessionId = $SessionId
    StartTime = Get-Date
    Checkpoints = @()
    CompressionEvents = @()
    PeakUsage = 0
    AverageUsage = 0
    Samples = 0
}

# Logging
function Write-ContextLog {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG", "TOKEN")]
        [string]$Level,
        [Parameter(Mandatory)]
        [string]$Message,
        [string]$Component = "ContextSwitch"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    if (-not $Silent) {
        switch ($Level) {
            "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
            "DEBUG"   { Write-Host $logEntry -ForegroundColor Gray }
            "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
            "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
            "TOKEN"   { Write-Host $logEntry -ForegroundColor Magenta }
        }
    }
    
    $logDir = Join-Path $VaultPath ".obsidian\logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path (Join-Path $logDir "context-switch.log") -Value $logEntry
}

# ═══════════════════════════════════════════════════════════════
# YAML-KONFIGURATION
# ═══════════════════════════════════════════════════════════════

function ConvertFrom-Yaml {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-ContextLog -Level "WARN" -Message "Config nicht gefunden, verwende Defaults: $Path"
        return $null
    }
    
    $content = Get-Content $Path -Raw
    $result = @{}
    $currentSection = $null
    
    foreach ($line in $content -split "`r?`n") {
        $line = $line -replace '#.*$', ''
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        $indent = if ($line -match "^(\s*)") { $matches[1].Length } else { 0 }
        $trimmed = $line.Trim()
        
        if ($trimmed -match "^(\w+):\s*(.*)$") {
            $key = $matches[1]
            $value = $matches[2].Trim()
            
            if ($value -eq "" -or $indent -eq 0) {
                if ($indent -eq 0) {
                    $result[$key] = @{}
                    $currentSection = $key
                }
            } else {
                if ($currentSection -and $indent -ge 2) {
                    $result[$currentSection][$key] = $value -replace '^"|"$' -replace "^'|'$"
                } else {
                    $result[$key] = $value -replace '^"|"$' -replace "^'|'$"
                }
            }
        }
    }
    
    return $result
}

function Get-ContextConfig {
    param([string]$ConfigPath)
    
    $defaults = @{
        thresholds = @{
            warning_percent = 70
            critical_percent = 80
            emergency_percent = 90
            compression_target_percent = 50
        }
        compression = @{
            strategy = "smart"
            preserve_recent_files = 5
            min_summary_length = 100
            max_summary_length = 500
        }
        checkpointing = @{
            auto_checkpoint_minutes = 10
            max_checkpoints = 10
            compress_checkpoints = $true
        }
        monitoring = @{
            sample_interval_seconds = 30
            log_usage = $true
            alert_on_threshold = $true
        }
    }
    
    $yaml = ConvertFrom-Yaml -Path $ConfigPath
    if ($yaml) {
        # Merge mit Defaults
        if ($yaml['context']) {
            $ctx = $yaml['context']
            foreach ($key in $ctx.Keys) {
                if ($defaults.ContainsKey($key)) {
                    foreach ($subKey in $ctx[$key].Keys) {
                        $defaults[$key][$subKey] = $ctx[$key][$subKey]
                    }
                }
            }
        }
    }
    
    return $defaults
}

# ═══════════════════════════════════════════════════════════════
# TOKEN-MONITORING
# ═══════════════════════════════════════════════════════════════

function Get-TokenStatus {
    param(
        [int]$Current,
        [int]$Maximum,
        [hashtable]$Config
    )
    
    $usagePercent = [math]::Round(($Current / $Maximum) * 100, 1)
    $remaining = $Maximum - $Current
    
    $status = @{
        Current = $Current
        Maximum = $Maximum
        Remaining = $remaining
        UsagePercent = $usagePercent
        Status = "normal"
        ActionRequired = $false
        CompressionRecommended = $false
    }
    
    $thresholds = $Config['thresholds']
    
    if ($usagePercent -ge [int]$thresholds['emergency_percent']) {
        $status.Status = "emergency"
        $status.ActionRequired = $true
        $status.CompressionRecommended = $true
    }
    elseif ($usagePercent -ge [int]$thresholds['critical_percent']) {
        $status.Status = "critical"
        $status.ActionRequired = $true
        $status.CompressionRecommended = $true
    }
    elseif ($usagePercent -ge [int]$thresholds['warning_percent']) {
        $status.Status = "warning"
        $status.ActionRequired = $false
        $status.CompressionRecommended = $false
    }
    
    return $status
}

function Show-TokenStatus {
    param([hashtable]$Status)
    
    $color = switch ($Status.Status) {
        "normal" { "Green" }
        "warning" { "Yellow" }
        "critical" { "Red" }
        "emergency" { "Magenta" }
    }
    
    $barLength = 50
    $filled = [math]::Round(($Status.UsagePercent / 100) * $barLength)
    $empty = $barLength - $filled
    
    $bar = "[" + ("█" * $filled) + ("░" * $empty) + "]"
    
    Write-Host ""
    Write-Host "=== Token Usage Status ===" -ForegroundColor Cyan
    Write-Host "Status: $($Status.Status.ToUpper())" -ForegroundColor $color
    Write-Host $bar -ForegroundColor $color
    Write-Host "$($Status.Current) / $($Status.Maximum) tokens ($($Status.UsagePercent)%)" -ForegroundColor White
    Write-Host "Verbleibend: $($Status.Remaining) tokens" -ForegroundColor Gray
    
    if ($Status.CompressionRecommended) {
        Write-Host ""
        Write-Host "⚠️  KOMPRESSION EMPFOHLEN" -ForegroundColor Yellow
        Write-Host "   Context-Switch oder Komprimierung erforderlich" -ForegroundColor Gray
    }
    Write-Host ""
}

function Start-TokenMonitor {
    param(
        [hashtable]$Config,
        [int]$MaxTokens
    )
    
    Write-ContextLog -Level "INFO" -Message "Starte Token-Monitor (Interval: $($Config['monitoring']['sample_interval_seconds'])s)"
    
    $interval = [int]$Config['monitoring']['sample_interval_seconds']
    
    while ($true) {
        # Simulierte Token-Abfrage (in echter Umgebung: API-Call)
        $currentTokens = Get-CurrentTokenCount
        
        $status = Get-TokenStatus -Current $currentTokens -Maximum $MaxTokens -Config $Config
        
        # Statistik aktualisieren
        $script:TokenStats.Samples++
        $script:TokenStats.AverageUsage = 
            (($script:TokenStats.AverageUsage * ($script:TokenStats.Samples - 1)) + $status.UsagePercent) / 
            $script:TokenStats.Samples
        
        if ($status.UsagePercent -gt $script:TokenStats.PeakUsage) {
            $script:TokenStats.PeakUsage = $status.UsagePercent
        }
        
        # Logging
        if ($Config['monitoring']['log_usage'] -eq $true) {
            Write-ContextLog -Level "TOKEN" -Message "Usage: $($status.UsagePercent)% ($currentTokens/$MaxTokens)"
        }
        
        # Threshold-Alert
        if ($status.ActionRequired -and $Config['monitoring']['alert_on_threshold'] -eq $true) {
            Write-ContextLog -Level "WARN" -Message "THRESHOLD ALERT: $($status.Status) - $($status.UsagePercent)%"
            
            if ($status.CompressionRecommended) {
                Write-ContextLog -Level "WARN" -Message "Automatische Komprimierung wird eingeleitet..."
                Invoke-ContextCompression -Config $Config -TargetPercent $Config['thresholds']['compression_target_percent']
            }
        }
        
        Start-Sleep -Seconds $interval
    }
}

function Get-CurrentTokenCount {
    # In echter Implementierung: API-Call zur Token-Abfrage
    # Dies ist ein Platzhalter für die tatsächliche Integration
    
    $stateFile = Join-Path $VaultPath ".obsidian\ecc-state.json"
    if (Test-Path $stateFile) {
        $state = Get-Content $stateFile | ConvertFrom-Json
        return $state.current_tokens
    }
    
    return 0
}

# ═══════════════════════════════════════════════════════════════
# CONTEXT-KOMPRESSION
# ═══════════════════════════════════════════════════════════════

function Invoke-ContextCompression {
    param(
        [hashtable]$Config,
        [int]$TargetPercent = 50
    )
    
    Write-ContextLog -Level "INFO" -Message "Starte Context-Komprimierung (Ziel: $TargetPercent%)"
    
    $compression = $Config['compression']
    $strategy = $compression['strategy']
    
    $compressionEvent = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Strategy = $strategy
        TargetPercent = $TargetPercent
        FilesCompressed = 0
        TokensSaved = 0
    }
    
    switch ($strategy) {
        "smart" {
            $result = Compress-SmartContext -Config $compression
        }
        "aggressive" {
            $result = Compress-AggressiveContext -Config $compression
        }
        "summary" {
            $result = Compress-SummaryContext -Config $compression
        }
        default {
            $result = Compress-SmartContext -Config $compression
        }
    }
    
    $compressionEvent.FilesCompressed = $result.FilesCompressed
    $compressionEvent.TokensSaved = $result.TokensSaved
    $script:TokenStats.CompressionEvents += $compressionEvent
    
    Write-ContextLog -Level "SUCCESS" -Message "Komprimierung abgeschlossen: $($result.FilesCompressed) Dateien, $($result.TokensSaved) Tokens gespart"
    
    return $result
}

function Compress-SmartContext {
    param([hashtable]$Config)
    
    $contextDir = Join-Path $VaultPath ".obsidian\context"
    if (-not (Test-Path $contextDir)) {
        return @{ FilesCompressed = 0; TokensSaved = 0 }
    }
    
    $files = Get-ChildItem -Path $contextDir -Filter "*.md" | Sort-Object LastWriteTime -Descending
    $preserveCount = [int]$Config['preserve_recent_files']
    $filesToCompress = $files | Select-Object -Skip $preserveCount
    
    $compressed = 0
    $tokensSaved = 0
    
    foreach ($file in $filesToCompress) {
        $content = Get-Content $file.FullName -Raw
        $originalLength = $content.Length
        
        # Smarte Komprimierung
        $compressed = Compress-ContentSmart -Content $content -Config $Config
        
        if ($compressed.Length -lt $originalLength) {
            # Backup vor Komprimierung
            $backupPath = "$($file.FullName).full"
            Copy-Item $file.FullName $backupPath -Force
            
            # Komprimierte Version speichern
            Set-Content -Path $file.FullName -Value $compressed -Encoding UTF8
            
            $compressed++
            $tokensSaved += [math]::Round(($originalLength - $compressed.Length) / 4)  # ~4 chars per token
        }
    }
    
    return @{ FilesCompressed = $compressed; TokensSaved = $tokensSaved }
}

function Compress-ContentSmart {
    param(
        [string]$Content,
        [hashtable]$Config
    )
    
    $minLength = [int]$Config['min_summary_length']
    $maxLength = [int]$Config['max_summary_length']
    
    # Entferne redundante Leerzeilen
    $Content = $Content -replace "`n{3,}", "`n`n"
    
    # Kürze lange Code-Blöcke
    $Content = $Content -replace '(```[\s\S]{500,}?)```', "```...code compressed...```"
    
    # Entferne alte Versionshistorie
    $Content = $Content -replace '## Version History[\s\S]*?(?=##|$)', "## Version History`n... (compressed)"
    
    # Kürze lange Listen
    if ($Content.Length -gt $maxLength * 2) {
        $lines = $Content -split "`n"
        $summary = $lines[0..20] -join "`n"
        $summary += "`n`n... [Content compressed, original length: $($Content.Length) chars] ..."
        $Content = $summary
    }
    
    return $Content
}

function Compress-AggressiveContext {
    param([hashtable]$Config)
    # Aggressivere Komprimierung für Notfälle
    return Compress-SmartContext -Config $Config
}

function Compress-SummaryContext {
    param([hashtable]$Config)
    # Nur Zusammenfassungen behalten
    return Compress-SmartContext -Config $Config
}

# ═══════════════════════════════════════════════════════════════
# SESSION-CHECKPOINTING
# ═══════════════════════════════════════════════════════════════

function New-SessionCheckpoint {
    param(
        [hashtable]$Config,
        [string]$Label = ""
    )
    
    $checkpointDir = Join-Path $VaultPath ".obsidian\checkpoints"
    if (-not (Test-Path $checkpointDir)) {
        New-Item -ItemType Directory -Path $checkpointDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $checkpointId = "chk_$($script:TokenStats.SessionId)_$timestamp"
    $checkpointPath = Join-Path $checkpointDir $checkpointId
    
    New-Item -ItemType Directory -Path $checkpointPath -Force | Out-Null
    
    $checkpoint = @{
        id = $checkpointId
        session_id = $script:TokenStats.SessionId
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        label = $Label
        token_stats = @{
            current = Get-CurrentTokenCount
            peak = $script:TokenStats.PeakUsage
            average = [math]::Round($script:TokenStats.AverageUsage, 1)
            samples = $script:TokenStats.Samples
        }
        compression_events = $script:TokenStats.CompressionEvents.Count
        context_files = @()
    }
    
    # Context-Dateien sichern
    $contextDir = Join-Path $VaultPath ".obsidian\context"
    if (Test-Path $contextDir) {
        $contextFiles = Get-ChildItem -Path $contextDir -Filter "*.md"
        foreach ($file in $contextFiles) {
            $dest = Join-Path $checkpointPath $file.Name
            Copy-Item $file.FullName $dest -Force
            $checkpoint.context_files += $file.Name
        }
    }
    
    # Checkpoint-Metadaten speichern
    $metaPath = "$checkpointPath.json"
    $checkpoint | ConvertTo-Json -Depth 10 | Set-Content $metaPath -Encoding UTF8
    
    $script:TokenStats.Checkpoints += $checkpoint
    
    # Alte Checkpoints bereinigen
    $maxCheckpoints = [int]$Config['max_checkpoints']
    $allCheckpoints = Get-ChildItem -Path $checkpointDir -Directory | Sort-Object CreationTime -Descending
    if ($allCheckpoints.Count -gt $maxCheckpoints) {
        $toDelete = $allCheckpoints | Select-Object -Skip $maxCheckpoints
        foreach ($old in $toDelete) {
            Remove-Item $old.FullName -Recurse -Force
            $jsonFile = "$($old.FullName).json"
            if (Test-Path $jsonFile) { Remove-Item $jsonFile -Force }
        }
    }
    
    Write-ContextLog -Level "SUCCESS" -Message "Checkpoint erstellt: $checkpointId"
    
    return $checkpoint
}

function Restore-SessionCheckpoint {
    param([string]$CheckpointId)
    
    $checkpointDir = Join-Path $VaultPath ".obsidian\checkpoints"
    $checkpointPath = Join-Path $checkpointDir $CheckpointId
    
    if (-not (Test-Path $checkpointPath)) {
        Write-ContextLog -Level "ERROR" -Message "Checkpoint nicht gefunden: $CheckpointId"
        return $null
    }
    
    $metaPath = "$checkpointPath.json"
    $checkpoint = Get-Content $metaPath | ConvertFrom-Json
    
    # Context wiederherstellen
    $contextDir = Join-Path $VaultPath ".obsidian\context"
    if (-not (Test-Path $contextDir)) {
        New-Item -ItemType Directory -Path $contextDir -Force | Out-Null
    }
    
    $contextFiles = Get-ChildItem -Path $checkpointPath -Filter "*.md"
    foreach ($file in $contextFiles) {
        $dest = Join-Path $contextDir $file.Name
        Copy-Item $file.FullName $dest -Force
    }
    
    Write-ContextLog -Level "SUCCESS" -Message "Checkpoint wiederhergestellt: $CheckpointId"
    
    return $checkpoint
}

function Get-CheckpointList {
    $checkpointDir = Join-Path $VaultPath ".obsidian\checkpoints"
    if (-not (Test-Path $checkpointDir)) {
        Write-Host "Keine Checkpoints gefunden" -ForegroundColor Yellow
        return
    }
    
    $checkpoints = Get-ChildItem -Path $checkpointDir -Filter "*.json" | Sort-Object LastWriteTime -Descending
    
    Write-Host "`n=== Verfügbare Checkpoints ===" -ForegroundColor Cyan
    foreach ($cp in $checkpoints) {
        $data = Get-Content $cp.FullName | ConvertFrom-Json
        Write-Host ""
        Write-Host "ID: $($data.id)" -ForegroundColor White
        Write-Host "  Zeit: $($data.timestamp)" -ForegroundColor Gray
        Write-Host "  Label: $($data.label)" -ForegroundColor Gray
        Write-Host "  Tokens: $($data.token_stats.current) (Peak: $($data.token_stats.peak)%)" -ForegroundColor Gray
    }
}

# ═══════════════════════════════════════════════════════════════
# STATUS & REPORTING
# ═══════════════════════════════════════════════════════════════

function Get-ContextStatus {
    $status = @{
        SessionId = $script:TokenStats.SessionId
        Runtime = (Get-Date) - $script:TokenStats.StartTime
        PeakUsage = $script:TokenStats.PeakUsage
        AverageUsage = [math]::Round($script:TokenStats.AverageUsage, 1)
        Samples = $script:TokenStats.Samples
        Checkpoints = $script:TokenStats.Checkpoints.Count
        CompressionEvents = $script:TokenStats.CompressionEvents.Count
    }
    
    $current = Get-CurrentTokenCount
    $status.CurrentTokens = $current
    $status.UsagePercent = if ($MaxTokens -gt 0) { [math]::Round(($current / $MaxTokens) * 100, 1) } else { 0 }
    
    return $status
}

function Show-ContextStatus {
    $status = Get-ContextStatus
    
    Write-Host ""
    Write-Host "=== ECC Context Switch Status ===" -ForegroundColor Cyan
    Write-Host "Session ID: $($status.SessionId)" -ForegroundColor White
    Write-Host "Laufzeit: $([math]::Round($status.Runtime.TotalMinutes, 1)) Minuten" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Token-Usage:" -ForegroundColor White
    Write-Host "  Aktuell: $($status.CurrentTokens) ($($status.UsagePercent)%)" -ForegroundColor Gray
    Write-Host "  Peak: $($status.PeakUsage)%" -ForegroundColor Gray
    Write-Host "  Durchschnitt: $($status.AverageUsage)%" -ForegroundColor Gray
    Write-Host "  Samples: $($status.Samples)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Events:" -ForegroundColor White
    Write-Host "  Checkpoints: $($status.Checkpoints)" -ForegroundColor Gray
    Write-Host "  Komprimierungen: $($status.CompressionEvents)" -ForegroundColor Gray
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════
# HAUPTLOGIK
# ═══════════════════════════════════════════════════════════════

Write-ContextLog -Level "INFO" -Message "=== ECC Context Switch gestartet ==="
Write-ContextLog -Level "INFO" -Message "Session ID: $SessionId"

# Konfiguration laden
$config = Get-ContextConfig -ConfigPath $ConfigPath

# Modus-Auswahl
if ($Status) {
    Show-ContextStatus
    exit 0
}

if ($Checkpoint) {
    $cp = New-SessionCheckpoint -Config $config['checkpointing'] -Label "Manual Checkpoint"
    Write-Output $cp | ConvertTo-Json -Depth 5
    exit 0
}

if ($Compress) {
    $result = Invoke-ContextCompression -Config $config -TargetPercent $config['thresholds']['compression_target_percent']
    Write-Output $result | ConvertTo-Json
    exit 0
}

if ($Monitor) {
    # Token-Status anzeigen
    $current = if ($CurrentTokens -gt 0) { $CurrentTokens } else { Get-CurrentTokenCount }
    $status = Get-TokenStatus -Current $current -Maximum $MaxTokens -Config $config
    Show-TokenStatus -Status $status
    
    # Monitoring starten
    Start-TokenMonitor -Config $config -MaxTokens $MaxTokens
    exit 0
}

# Standard: Nur Status anzeigen
$current = if ($CurrentTokens -gt 0) { $CurrentTokens } else { Get-CurrentTokenCount }
$status = Get-TokenStatus -Current $current -Maximum $MaxTokens -Config $config
Show-TokenStatus -Status $status

Write-ContextLog -Level "INFO" -Message "=== Context Switch abgeschlossen ==="

# Rückgabe
return @{
    Success = $true
    SessionId = $SessionId
    TokenStatus = $status
    ConfigLoaded = ($config -ne $null)
}
