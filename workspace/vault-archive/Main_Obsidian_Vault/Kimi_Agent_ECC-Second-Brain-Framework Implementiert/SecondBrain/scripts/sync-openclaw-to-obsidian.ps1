#Requires -Version 5.1
<#
.SYNOPSIS
    Sync-Skript für OpenClaw → Obsidian Integration

.DESCRIPTION
    Synchronisiert OpenClaw-Sessions mit dem ECC Second Brain Obsidian Vault.
    Generiert Daily Notes, Mermaid-Diagramme, Code-Blocks und Backlinks.

.PARAMETER SessionId
    Spezifische Session-ID zum Syncen

.PARAMETER VaultPath
    Pfad zum Obsidian Vault

.PARAMETER DryRun
    Zeigt an, was synchronisiert würde, ohne Änderungen vorzunehmen

.PARAMETER Force
    Überschreibt existierende Dateien

.EXAMPLE
    .\sync-openclaw-to-obsidian.ps1
    .\sync-openclaw-to-obsidian.ps1 -SessionId "sess_abc123" -DryRun

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    ECC Framework: Sync Integration
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SessionId = $null,
    
    [Parameter(Mandatory = $false)]
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Script Variables
$script:Version = "1.0.0"
$script:StartTime = Get-Date
$script:LogFile = Join-Path $VaultPath ".logs" "sync-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$script:OpenClawPath = "C:\Users\andre\.openclaw\workspace"
$script:RetryCount = 3
$script:RetryDelay = 2

# Import Modules
$modulePath = Join-Path $PSScriptRoot "lib"
Import-Module (Join-Path $modulePath "ErrorHandler.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $modulePath "Logging.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $modulePath "MermaidGenerator.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $modulePath "DataviewQuery.psm1") -Force -ErrorAction SilentlyContinue

#region Logging

function Write-SyncLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG"   { Write-Verbose $logEntry }
    }
    
    $logDir = Split-Path $script:LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $script:LogFile -Value $logEntry
}

#endregion

#region Core Functions

function Get-OpenClawSessions {
    [CmdletBinding()]
    param()
    
    $sessionsPath = Join-Path $script:OpenClawPath "memory\sessions"
    
    if (!(Test-Path $sessionsPath)) {
        Write-SyncLog "OpenClaw sessions path not found: $sessionsPath" -Level "ERROR"
        return @()
    }
    
    $sessionFiles = Get-ChildItem $sessionsPath -Filter "*.json" -File
    $sessions = @()
    
    foreach ($file in $sessionFiles) {
        try {
            $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $sessions += [PSCustomObject]@{
                Id = $content.session_id
                FileName = $file.Name
                FilePath = $file.FullName
                Data = $content
            }
        }
        catch {
            Write-SyncLog "Failed to parse session file: $($file.Name)" -Level "WARN"
        }
    }
    
    Write-SyncLog "Found $($sessions.Count) OpenClaw sessions" -Level "INFO"
    return $sessions
}

function Convert-SessionToNote {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session
    )
    
    $data = $Session.Data
    $date = if ($data.date) { $data.date } else { (Get-Date -Format "yyyy-MM-dd") }
    $sessionId = $data.session_id
    $tokensUsed = if ($data.tokens_used) { $data.tokens_used } else { 0 }
    $agentMode = if ($data.agent_mode) { $data.agent_mode } else { "unknown" }
    $keyDecisions = if ($data.key_decisions) { $data.key_decisions } else { @() }
    
    # Generate Mermaid diagram if architecture data exists
    $mermaidDiagram = ""
    if ($data.architecture) {
        $components = $data.architecture.components | ForEach-Object {
            @{
                Id = $_.id
                Name = $_.name
                Type = $_.type
                Technology = $_.technology
            }
        }
        
        $relationships = $data.architecture.relationships | ForEach-Object {
            @{
                From = $_.from
                To = $_.to
                Label = $_.label
            }
        }
        
        $mermaidDiagram = New-ArchitectureDiagram -Title "Session Architecture" -Components $components -Relationships $relationships
    }
    
    # Extract code blocks
    $codeBlocks = ""
    if ($data.code_blocks) {
        $codeBlocks = "## Code Implementations`n`n"
        foreach ($block in $data.code_blocks) {
            $codeBlocks += "### $($block.filename)`n"
            $codeBlocks += "```$($block.language)`n"
            $codeBlocks += $block.code
            $codeBlocks += "`n````n`n"
        }
    }
    
    # Build note content
    $noteContent = @"
---
session_id: "$sessionId"
date: "$date"
tokens_used: $tokensUsed
agent_mode: "$agentMode"
key_decisions:
$(($keyDecisions | ForEach-Object { "  - `"$_`"" }) -join "`n")
tags:
  - session
  - openclaw-sync
status: "synced"
source_file: "$($Session.FileName)"
synced_at: "$(Get-Date -Format "o")"
---

# Session: $sessionId

## Metadata

| Property | Value |
|----------|-------|
| **Session ID** | `$sessionId` |
| **Date** | $date |
| **Tokens Used** | $tokensUsed |
| **Agent Mode** | $agentMode |

---

## Key Decisions #decision

$(if ($keyDecisions.Count -gt 0) {
    ($keyDecisions | ForEach-Object { "- [[$_]]" }) -join "`n"
} else {
    "- No key decisions recorded"
})

---

$mermaidDiagram

---

$codeBlocks

---

## Backlinks

```dataview
LIST
FROM [[$sessionId]]
WHERE file.name != "$sessionId"
```

---

*Synced from OpenClaw by ECC Second Brain Framework*
*Source: $($Session.FileName)*
"@
    
    return $noteContent
}

function Sync-Session {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session
    )
    
    $noteContent = Convert-SessionToNote -Session $Session
    $date = $Session.Data.date
    $noteFileName = "$date.md"
    $notePath = Join-Path $VaultPath "05-Daily" $noteFileName
    
    if (Test-Path $notePath -and !$Force) {
        Write-SyncLog "Note already exists: $noteFileName (use -Force to overwrite)" -Level "WARN"
        return $false
    }
    
    if ($DryRun) {
        Write-SyncLog "[DRY RUN] Would create: $notePath" -Level "INFO"
        return $true
    }
    
    try {
        $noteContent | Set-Content -Path $notePath -Encoding UTF8
        Write-SyncLog "Created note: $noteFileName" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-SyncLog "Failed to create note: $noteFileName - $_" -Level "ERROR"
        return $false
    }
}

function Sync-AllSessions {
    [CmdletBinding()]
    param()
    
    $sessions = Get-OpenClawSessions
    $results = @{
        Total = $sessions.Count
        Synced = 0
        Failed = 0
        Skipped = 0
    }
    
    foreach ($session in $sessions) {
        if ($SessionId -and $session.Id -ne $SessionId) {
            continue
        }
        
        $attempt = 0
        $success = $false
        
        do {
            $attempt++
            try {
                $success = Sync-Session -Session $session
                if ($success) {
                    $results.Synced++
                }
                else {
                    $results.Skipped++
                }
                break
            }
            catch {
                if ($attempt -lt $script:RetryCount) {
                    Write-SyncLog "Retry $attempt/$script:RetryCount for session: $($session.Id)" -Level "WARN"
                    Start-Sleep -Seconds ($script:RetryDelay * $attempt)
                }
                else {
                    Write-SyncLog "Failed to sync session after $script:RetryCount attempts: $($session.Id)" -Level "ERROR"
                    $results.Failed++
                }
            }
        } while ($attempt -lt $script:RetryCount)
    }
    
    return $results
}

function Update-Backlinks {
    [CmdletBinding()]
    param()
    
    $dailyPath = Join-Path $VaultPath "05-Daily"
    
    if (!(Test-Path $dailyPath)) {
        return
    }
    
    $notes = Get-ChildItem $dailyPath -Filter "*.md" -File
    
    foreach ($note in $notes) {
        $content = Get-Content $note.FullName -Raw
        
        # Find decision references and create backlinks
        if ($content -match "decision_id:\s*\"(DEC-\d+-\d+)\"") {
            $decisionId = $Matches[1]
            $decisionFile = Join-Path $VaultPath "01-Projects" "$decisionId.md"
            
            if (Test-Path $decisionFile) {
                $decisionContent = Get-Content $decisionFile -Raw
                $backlink = "- [[$($note.BaseName)]]"
                
                if ($decisionContent -notcontains $backlink) {
                    $decisionContent += "`n$backlink"
                    $decisionContent | Set-Content $decisionFile -Encoding UTF8
                    Write-SyncLog "Updated backlink in: $decisionId.md" -Level "DEBUG"
                }
            }
        }
    }
}

function Generate-SessionIndex {
    [CmdletBinding()]
    param()
    
    $indexContent = @"
---
tags:
  - index
  - sessions
---

# Session Index

> Auto-generated index of all synced sessions

## Statistics

```dataview
TABLE session_id, date, tokens_used, agent_mode
FROM "05-Daily"
WHERE source_file
SORT date DESC
```

## Token Usage Over Time

```dataview
TABLE sum(tokens_used) as "Total Tokens"
FROM "05-Daily"
GROUP BY dateformat(date, "yyyy-MM") as Month
SORT Month DESC
```

## Agent Mode Distribution

```dataview
TABLE length(rows) as Sessions
FROM "05-Daily"
WHERE agent_mode
GROUP BY agent_mode
SORT length(rows) DESC
```
"@
    
    $indexPath = Join-Path $VaultPath "05-Daily" "README.md"
    $indexContent | Set-Content $indexPath -Encoding UTF8
    Write-SyncLog "Generated session index" -Level "SUCCESS"
}

#endregion

#region Main Execution

function Start-Sync {
    Write-SyncLog "=== ECC Second Brain Sync v$script:Version ===" -Level "INFO"
    Write-SyncLog "Vault Path: $VaultPath" -Level "INFO"
    Write-SyncLog "OpenClaw Path: $script:OpenClawPath" -Level "INFO"
    
    if ($DryRun) {
        Write-SyncLog "DRY RUN MODE - No changes will be made" -Level "WARN"
    }
    
    if ($SessionId) {
        Write-SyncLog "Filtering for Session ID: $SessionId" -Level "INFO"
    }
    
    Write-SyncLog ""
    
    # Pre-flight checks
    if (!(Test-Path $VaultPath)) {
        Write-SyncLog "Vault path not found: $VaultPath" -Level "ERROR"
        exit 1
    }
    
    # Sync sessions
    $results = Sync-AllSessions
    
    # Update backlinks
    if (!$DryRun) {
        Update-Backlinks
        Generate-SessionIndex
    }
    
    # Summary
    Write-SyncLog ""
    Write-SyncLog "=== Sync Summary ===" -Level "INFO"
    Write-SyncLog "Total Sessions: $($results.Total)" -Level "INFO"
    Write-SyncLog "Synced: $($results.Synced)" -Level "SUCCESS"
    Write-SyncLog "Skipped: $($results.Skipped)" -Level "WARN"
    Write-SyncLog "Failed: $($results.Failed)" -Level $(if ($results.Failed -gt 0) { "ERROR" } else { "INFO" })
    
    $duration = (Get-Date) - $script:StartTime
    Write-SyncLog "Duration: $($duration.ToString('mm\:ss'))" -Level "INFO"
    
    if ($results.Failed -gt 0) {
        exit 1
    }
}

#endregion

# Execute
Start-Sync
