#Requires -Version 7.0
<#
.SYNOPSIS
    OpenClaw → Obsidian Sync Script
    Synchronisiert OpenClaw-Sessions in Obsidian-Vault

.DESCRIPTION
    Dieses Skript liest OpenClaw-Sessions aus dem Registry-Pfad,
    generiert Obsidian-Notes mit YAML-Frontmatter, erstellt Mermaid-Diagramme,
    extrahiert Code-Blocks und verwaltet Backlinks zu vorherigen Sessions.

.PARAMETER VaultPath
    Pfad zum Obsidian Vault

.PARAMETER SessionId
    Optional: Spezifische Session-ID zum Synchronisieren

.PARAMETER Force
    Erzwingt Neusynchronisierung bestehender Notes

.EXAMPLE
    .\sync-openclaw-to-obsidian.ps1 -VaultPath "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain"

.EXAMPLE
    .\sync-openclaw-to-obsidian.ps1 -SessionId "sess_abc123" -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    
    [Parameter(Mandatory = $false)]
    [string]$SessionId = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxRetries = 3,
    
    [Parameter(Mandatory = $false)]
    [int]$RetryDelaySeconds = 2
)

# ============================================================================
# KONFIGURATION
# ============================================================================

$script:Config = @{
    VaultPath = $VaultPath
    RegistryPath = "HKCU:\Software\OpenClaw\Sessions"
    SessionsFolder = "01-Sessions"
    CodeBlocksFolder = "03-Resources/CodeBlocks"
    DecisionsFolder = "02-Areas/Decisions"
    TemplatesFolder = "05-Templates"
    MaxRetries = $MaxRetries
    RetryDelaySeconds = $RetryDelaySeconds
    LogPath = Join-Path $VaultPath ".obsidian/logs/sync.log"
}

# ============================================================================
# LOGGING
# ============================================================================

function Write-SyncLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Konsole ausgeben
    $colorMap = @{
        "INFO" = "White"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
        "DEBUG" = "Cyan"
    }
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
    
    # In Log-Datei schreiben
    $logDir = Split-Path $script:Config.LogPath -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $script:Config.LogPath -Value $logEntry -ErrorAction SilentlyContinue
}

# ============================================================================
# RETRY-LOGIK
# ============================================================================

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [string]$OperationName = "Operation",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = $script:Config.MaxRetries
    )
    
    $attempt = 1
    $lastError = $null
    
    while ($attempt -le $MaxRetries) {
        try {
            Write-SyncLog "Executing $OperationName (Attempt $attempt/$MaxRetries)..." -Level "DEBUG"
            $result = & $ScriptBlock
            if ($attempt -gt 1) {
                Write-SyncLog "$OperationName succeeded on attempt $attempt" -Level "SUCCESS"
            }
            return $result
        }
        catch {
            $lastError = $_
            Write-SyncLog "$OperationName failed on attempt ${attempt}: $($_.Exception.Message)" -Level "WARN"
            
            if ($attempt -lt $MaxRetries) {
                $delay = $script:Config.RetryDelaySeconds * $attempt
                Write-SyncLog "Waiting $delay seconds before retry..." -Level "DEBUG"
                Start-Sleep -Seconds $delay
            }
        }
        $attempt++
    }
    
    throw "$OperationName failed after $MaxRetries attempts. Last error: $($lastError.Exception.Message)"
}

# ============================================================================
# REGISTRY-OPERATIONEN
# ============================================================================

function Get-OpenClawSessionsFromRegistry {
    param(
        [Parameter(Mandatory = $false)]
        [string]$SpecificSessionId = ""
    )
    
    Invoke-WithRetry -OperationName "Registry Read" -ScriptBlock {
        if (!(Test-Path $script:Config.RegistryPath)) {
            Write-SyncLog "Registry path not found: $($script:Config.RegistryPath)" -Level "WARN"
            return @()
        }
        
        $sessions = @()
        $sessionKeys = Get-ChildItem -Path $script:Config.RegistryPath -ErrorAction Stop
        
        foreach ($key in $sessionKeys) {
            try {
                $sessionData = Get-ItemProperty -Path $key.PSPath -ErrorAction Stop
                
                if ($SpecificSessionId -and $sessionData.SessionId -ne $SpecificSessionId) {
                    continue
                }
                
                $session = @{
                    SessionId = $sessionData.SessionId
                    Title = $sessionData.Title
                    Description = $sessionData.Description
                    CreatedAt = $sessionData.CreatedAt
                    UpdatedAt = $sessionData.UpdatedAt
                    TokenUsage = $sessionData.TokenUsage
                    Cost = $sessionData.Cost
                    Model = $sessionData.Model
                    Project = $sessionData.Project
                    Tags = @($sessionData.Tags -split ',')
                    Status = $sessionData.Status
                    Content = $sessionData.Content
                    Decisions = @($sessionData.Decisions -split '`n')
                    Todos = @($sessionData.Todos -split '`n')
                    CodeBlocks = $sessionData.CodeBlocks
                    PreviousSessionId = $sessionData.PreviousSessionId
                    RelatedSessions = @($sessionData.RelatedSessions -split ',')
                }
                
                $sessions += $session
            }
            catch {
                Write-SyncLog "Error reading session from $($key.PSPath): $($_.Exception.Message)" -Level "WARN"
            }
        }
        
        return $sessions
    }
}

# ============================================================================
# YAML-FRONTMATTER GENERIERUNG
# ============================================================================

function ConvertTo-YamlFrontmatter {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Session
    )
    
    $yaml = @"`
---
session_id: $($Session.SessionId)
title: "$($Session.Title -replace '"', '\"')"
description: "$($Session.Description -replace '"', '\"')"
created: $($Session.CreatedAt)
updated: $($Session.UpdatedAt)
token_usage: $($Session.TokenUsage)
cost: $($Session.Cost)
model: $($Session.Model)
project: $($Session.Project)
tags: [$(($Session.Tags | ForEach-Object { '"' + $_ + '"' }) -join ', ')]
status: $($Session.Status)
previous_session: $(if ($Session.PreviousSessionId) { $Session.PreviousSessionId } else { "null" })
related_sessions: [$(($Session.RelatedSessions | ForEach-Object { '"' + $_ + '"' }) -join ', ')]
synced_at: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
---

"@
    
    return $yaml
}

# ============================================================================
# CODE-BLOCK EXTRAKTION
# ============================================================================

function Extract-CodeBlocks {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string]$SessionId
    )
    
    $codeBlocks = @()
    $pattern = '```(\w+)?\s*\n([\s\S]*?)```'
    $matches = [regex]::Matches($Content, $pattern)
    
    $blockIndex = 0
    foreach ($match in $matches) {
        $language = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { "text" }
        $code = $match.Groups[2].Value.Trim()
        
        # Generiere eindeutigen Dateinamen
        $sanitizedTitle = ($Session.Title -replace '[^\w\s-]', '').Trim() -replace '\s+', '_'
        $filename = "${sanitizedTitle}_block${blockIndex}.${language}"
        $filepath = Join-Path $script:Config.VaultPath $script:Config.CodeBlocksFolder $filename
        
        $codeBlockInfo = @{
            Index = $blockIndex
            Language = $language
            Filename = $filename
            Filepath = $filepath
            Code = $code
            SessionId = $SessionId
        }
        
        $codeBlocks += $codeBlockInfo
        $blockIndex++
    }
    
    return $codeBlocks
}

function Save-CodeBlock {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$CodeBlock
    )
    
    Invoke-WithRetry -OperationName "Save CodeBlock $($CodeBlock.Filename)" -ScriptBlock {
        $dir = Split-Path $CodeBlock.Filepath -Parent
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        $header = @"
// ============================================================================
// Code Block from Session: $($CodeBlock.SessionId)
// Language: $($CodeBlock.Language)
// Extracted: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
// ============================================================================

"@
        
        $content = $header + $CodeBlock.Code
        Set-Content -Path $CodeBlock.Filepath -Value $content -Encoding UTF8 -ErrorAction Stop
        
        return $CodeBlock.Filepath
    }
}

# ============================================================================
# BACKLINKS GENERIERUNG
# ============================================================================

function Get-BacklinksSection {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Session,
        
        [Parameter(Mandatory = $true)]
        [string]$SessionsFolder
    )
    
    $backlinks = @"
## Backlinks

"@
    
    # Vorherige Session
    if ($Session.PreviousSessionId) {
        $prevLink = "../$SessionsFolder/$($Session.PreviousSessionId).md"
        $backlinks += @"
### Vorherige Session
- [[$($Session.PreviousSessionId)|Zur vorherigen Session]]

"@
    }
    
    # Verwandte Sessions
    if ($Session.RelatedSessions -and $Session.RelatedSessions.Count -gt 0) {
        $backlinks += @"
### Verwandte Sessions
"@
        foreach ($relatedId in $Session.RelatedSessions) {
            if ($relatedId) {
                $backlinks += "- [[$relatedId|Verwandte Session]]`n"
            }
        }
        $backlinks += "`n"
    }
    
    # Projekt-Backlink
    if ($Session.Project) {
        $backlinks += @"
### Projekt
- [[../../02-Areas/Projects/$($Session.Project)|Projekt: $($Session.Project)]]

"@
    }
    
    return $backlinks
}

# ============================================================================
# ENTSCHEIDUNGEN VERARBEITEN
# ============================================================================

function New-DecisionNote {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Decision,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Session
    )
    
    Invoke-WithRetry -OperationName "Create Decision Note" -ScriptBlock {
        $decisionId = "dec_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
        $sanitizedDecision = ($Decision -replace '[^\w\s-]', '').Trim() -replace '\s+', '_'
        $filename = "$decisionId`_$sanitizedDecision.md"
        $filepath = Join-Path $script:Config.VaultPath $script:Config.DecisionsFolder $filename
        
        $dir = Split-Path $filepath -Parent
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        $content = @"
---
decision_id: $decisionId
decision: "$($Decision -replace '"', '\"')"
session_id: $($Session.SessionId)
created: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
status: proposed
tags: [decision, $($Session.Project)]
---

# Entscheidung: $Decision

## Kontext
Diese Entscheidung wurde in Session [[$($Session.SessionId)]] getroffen.

## Details
**Projekt:** $($Session.Project)

**Session:** [[$($Session.SessionId)|$($Session.Title)]]

**Entschieden am:** $(Get-Date -Format "yyyy-MM-dd HH:mm")

## Status
- [ ] Vorgeschlagen
- [ ] Genehmigt
- [ ] Implementiert
- [ ] Verworfen

## Konsequenzen
*Zu dokumentieren...*

## Alternativen
*Zu dokumentieren...*
"@
        
        Set-Content -Path $filepath -Value $content -Encoding UTF8 -ErrorAction Stop
        
        return @{
            DecisionId = $decisionId
            Filepath = $filepath
            Filename = $filename
        }
    }
}

# ============================================================================
# HAUPT-NOTE GENERIERUNG
# ============================================================================

function New-SessionNote {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Session
    )
    
    Invoke-WithRetry -OperationName "Create Session Note" -ScriptBlock {
        $filename = "$($Session.SessionId).md"
        $filepath = Join-Path $script:Config.VaultPath $script:Config.SessionsFolder $filename
        
        # Prüfe ob Datei existiert und Force nicht gesetzt ist
        if ((Test-Path $filepath) -and -not $Force) {
            Write-SyncLog "Note already exists: $filename (use -Force to overwrite)" -Level "INFO"
            return $filepath
        }
        
        # Verzeichnis erstellen
        $dir = Split-Path $filepath -Parent
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        # YAML Frontmatter
        $frontmatter = ConvertTo-YamlFrontmatter -Session $Session
        
        # Code-Blocks extrahieren
        $codeBlocks = Extract-CodeBlocks -Content $Session.Content -SessionId $Session.SessionId
        $savedCodeBlocks = @()
        
        foreach ($codeBlock in $codeBlocks) {
            if (-not $DryRun) {
                $savedPath = Save-CodeBlock -CodeBlock $codeBlock
                $savedCodeBlocks += $savedPath
            }
        }
        
        # Code-Block Referenzen
        $codeBlockSection = "## Code-Blocks`n`n"
        if ($savedCodeBlocks.Count -gt 0) {
            foreach ($cb in $codeBlocks) {
                $codeBlockSection += "- [[../../$($script:Config.CodeBlocksFolder)/$($cb.Filename)|Code-Block $($cb.Index) ($($cb.Language))]]`n"
            }
        }
        else {
            $codeBlockSection += "*Keine Code-Blocks in dieser Session*"
        }
        $codeBlockSection += "`n"
        
        # TODOs Section
        $todosSection = "## TODOs`n`n"
        if ($Session.Todos -and $Session.Todos.Count -gt 0) {
            foreach ($todo in $Session.Todos) {
                if ($todo) {
                    $todosSection += "- [ ] $todo`n"
                }
            }
        }
        else {
            $todosSection += "*Keine offenen TODOs*"
        }
        $todosSection += "`n"
        
        # Entscheidungen verarbeiten
        $decisionsSection = "## Entscheidungen`n`n"
        $decisionLinks = @()
        if ($Session.Decisions -and $Session.Decisions.Count -gt 0) {
            foreach ($decision in $Session.Decisions) {
                if ($decision) {
                    if (-not $DryRun) {
                        $decResult = New-DecisionNote -Decision $decision -Session $Session
                        $decisionLinks += $decResult
                        $decisionsSection += "- [[../../$($script:Config.DecisionsFolder)/$($decResult.Filename)|$decision]]`n"
                    }
                    else {
                        $decisionsSection += "- $decision`n"
                    }
                }
            }
        }
        else {
            $decisionsSection += "*Keine Entscheidungen dokumentiert*"
        }
        $decisionsSection += "`n"
        
        # Backlinks
        $backlinks = Get-BacklinksSection -Session $Session -SessionsFolder $script:Config.SessionsFolder
        
        # Mermaid-Diagramm für Session-Architektur
        $mermaidSection = @"
## Session-Architektur

```mermaid
flowchart TD
    S[$($Session.Title)] --> C[Content]
    S --> D[Entscheidungen]
    S --> T[TODOs]
    S --> CB[Code-Blocks]
    
"@
        if ($Session.PreviousSessionId) {
            $mermaidSection += "    P[$($Session.PreviousSessionId)] --> S`n"
        }
        $mermaidSection += "```\n\n"
        
        # Hauptinhalt
        $content = @"
$frontmatter
# $($Session.Title)

$($Session.Description)

## Zusammenfassung

**Token Usage:** $($Session.TokenUsage) | **Cost:** `$($Session.Cost)` | **Model:** $($Session.Model)

## Inhalt

$($Session.Content)

$todosSection
$decisionsSection
$codeBlockSection
$mermaidSection
$backlinks
---
*Automatisch synchronisiert von OpenClaw am $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@
        
        if (-not $DryRun) {
            Set-Content -Path $filepath -Value $content -Encoding UTF8 -ErrorAction Stop
            Write-SyncLog "Created session note: $filename" -Level "SUCCESS"
        }
        else {
            Write-SyncLog "[DRY RUN] Would create: $filename" -Level "INFO"
        }
        
        return @{
            Filepath = $filepath
            Filename = $filename
            CodeBlocks = $savedCodeBlocks.Count
            Decisions = $decisionLinks.Count
        }
    }
}

# ============================================================================
# SYNC-STATUS VERWALTEN
# ============================================================================

function Get-SyncStatus {
    $statusPath = Join-Path $script:Config.VaultPath ".obsidian/sync-status.json"
    
    if (Test-Path $statusPath) {
        try {
            $content = Get-Content -Path $statusPath -Raw -ErrorAction Stop
            return $content | ConvertFrom-Json
        }
        catch {
            Write-SyncLog "Error reading sync status: $($_.Exception.Message)" -Level "WARN"
            return @{}
        }
    }
    
    return @{
        lastSync = $null
        syncedSessions = @()
        failedSessions = @()
    }
}

function Save-SyncStatus {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Status
    )
    
    $statusPath = Join-Path $script:Config.VaultPath ".obsidian/sync-status.json"
    $dir = Split-Path $statusPath -Parent
    
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    $Status.lastSync = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $Status | ConvertTo-Json -Depth 10 | Set-Content -Path $statusPath -Encoding UTF8
}

# ============================================================================
# HAUPTPROGRAMM
# ============================================================================

function Start-Sync {
    Write-SyncLog "========================================" -Level "INFO"
    Write-SyncLog "OpenClaw → Obsidian Sync Started" -Level "INFO"
    Write-SyncLog "Vault Path: $($script:Config.VaultPath)" -Level "INFO"
    Write-SyncLog "Dry Run: $DryRun" -Level "INFO"
    Write-SyncLog "Force: $Force" -Level "INFO"
    Write-SyncLog "========================================" -Level "INFO"
    
    # Sync-Status laden
    $syncStatus = Get-SyncStatus
    
    # Sessions aus Registry lesen
    Write-SyncLog "Reading sessions from registry..." -Level "INFO"
    $sessions = Get-OpenClawSessionsFromRegistry -SpecificSessionId $SessionId
    
    if ($sessions.Count -eq 0) {
        Write-SyncLog "No sessions found to sync" -Level "WARN"
        return
    }
    
    Write-SyncLog "Found $($sessions.Count) session(s) to process" -Level "INFO"
    
    # Statistik
    $stats = @{
        processed = 0
        created = 0
        updated = 0
        failed = 0
        codeBlocks = 0
        decisions = 0
    }
    
    foreach ($session in $sessions) {
        try {
            Write-SyncLog "Processing session: $($session.SessionId) - $($session.Title)" -Level "INFO"
            
            $result = New-SessionNote -Session $session
            
            $stats.processed++
            $stats.codeBlocks += $result.CodeBlocks
            $stats.decisions += $result.Decisions
            
            if ($syncStatus.syncedSessions -contains $session.SessionId) {
                $stats.updated++
            }
            else {
                $stats.created++
                $syncStatus.syncedSessions += $session.SessionId
            }
        }
        catch {
            Write-SyncLog "Failed to process session $($session.SessionId): $($_.Exception.Message)" -Level "ERROR"
            $stats.failed++
            $syncStatus.failedSessions += @{
                sessionId = $session.SessionId
                error = $_.Exception.Message
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
            }
        }
    }
    
    # Sync-Status speichern
    if (-not $DryRun) {
        Save-SyncStatus -Status $syncStatus
    }
    
    # Zusammenfassung
    Write-SyncLog "========================================" -Level "INFO"
    Write-SyncLog "Sync Complete!" -Level "SUCCESS"
    Write-SyncLog "Processed: $($stats.processed)" -Level "INFO"
    Write-SyncLog "Created: $($stats.created)" -Level "INFO"
    Write-SyncLog "Updated: $($stats.updated)" -Level "INFO"
    Write-SyncLog "Failed: $($stats.failed)" -Level "INFO"
    Write-SyncLog "Code Blocks: $($stats.codeBlocks)" -Level "INFO"
    Write-SyncLog "Decisions: $($stats.decisions)" -Level "INFO"
    Write-SyncLog "========================================" -Level "INFO"
}

# ============================================================================
# EINSTIEGSPUNKT
# ============================================================================

# Module laden
$modulePath = Join-Path $PSScriptRoot "lib"
if (Test-Path $modulePath) {
    Get-ChildItem -Path $modulePath -Filter "*.psm1" | ForEach-Object {
        Write-SyncLog "Loading module: $($_.Name)" -Level "DEBUG"
        Import-Module $_.FullName -Force
    }
}

# Sync starten
Start-Sync
