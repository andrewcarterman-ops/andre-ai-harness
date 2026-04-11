#!/usr/bin/env pwsh
# Sync OpenClaw Sessions to Second Brain
# Kopiert Session-Daten ins PARA-System

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$workspaceRoot = "C:\Users\andre\.openclaw\workspace"
$secondBrainRoot = "$workspaceRoot\second-brain"
$memoryDir = "$workspaceRoot\memory"

Write-Host "🧠 Second Brain Sync" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

# Importiere Logging
Import-Module "$workspaceRoot/scripts/lib/Logging.psm1" -ErrorAction SilentlyContinue
if (Get-Command Initialize-Logging -ErrorAction SilentlyContinue) {
    Initialize-Logging -Component "second-brain-sync"
}

# Sync: Sessions
Write-Host "`n📄 Syncing Sessions..." -ForegroundColor Yellow

$sessions = Get-ChildItem "$memoryDir/2026-*.md" -ErrorAction SilentlyContinue | Sort-Object Name

foreach ($session in $sessions) {
    $content = Get-Content $session.FullName -Raw
    $sessionDate = $session.BaseName
    
    # Extrahiere Metadaten
    $metadata = @{}
    if ($content -match "Session:\s*(.+)") {
        $metadata.Session = $matches[1].Trim()
    }
    if ($content -match "Duration:\s*(.+)") {
        $metadata.Duration = $matches[1].Trim()
    }
    
    # Erstelle Second Brain Session
    $targetFile = "$secondBrainRoot/01-Sessions/Session-$sessionDate.md"
    
    if (-not $DryRun -and (-not (Test-Path $targetFile) -or $Force)) {
        $sbContent = @"
---
date: $sessionDate
type: session
source: $($session.FullName)
tags: [synced, session]
---

# Session $sessionDate

## Source
Original: [[$($session.FullName)|Session Log]]

## Content
$content
"@
        
        $sbContent | Out-File $targetFile -Encoding UTF8
        Write-Host "  ✅ $sessionDate" -ForegroundColor Green
    } elseif ($DryRun) {
        Write-Host "  Would sync: $sessionDate" -ForegroundColor Gray
    } else {
        Write-Host "  Skipped (exists): $sessionDate" -ForegroundColor Yellow
    }
}

# Sync: Decisions aus registry/decisions
Write-Host "`n🎯 Syncing Decisions..." -ForegroundColor Yellow
$decisionsFile = "$workspaceRoot/registry/ADRs.md"
if (Test-Path $decisionsFile) {
    # Parse and sync ADRs
    Write-Host "  ADRs found" -ForegroundColor Green
}

# Sync: Projects
Write-Host "`n📁 Syncing Projects..." -ForegroundColor Yellow
$projects = Get-ChildItem "$workspaceRoot/plans/*.md" -ErrorAction SilentlyContinue
foreach ($project in $projects) {
    $projectName = $project.BaseName
    $targetFile = "$secondBrainRoot/02-Areas/Projects/$projectName.md"
    
    if (-not (Test-Path $targetFile) -or $Force) {
        Copy-Item $project.FullName $targetFile -Force
        Write-Host "  ✅ $projectName" -ForegroundColor Green
    }
}

# Sync: Code Blocks (extrahiere aus Sessions)
Write-Host "`n💻 Extracting Code Blocks..." -ForegroundColor Yellow
$codeBlocksDir = "$secondBrainRoot/03-Resources/CodeBlocks"
$sessionFiles = Get-ChildItem "$secondBrainRoot/01-Sessions/*.md" -ErrorAction SilentlyContinue

$blockCount = 0
foreach ($sf in $sessionFiles) {
    $content = Get-Content $sf.FullName -Raw
    $codeBlocks = [regex]::Matches($content, '```(\w+)?\s*([\s\S]*?)```')
    
    foreach ($block in $codeBlocks) {
        $lang = $block.Groups[1].Value
        $code = $block.Groups[2].Value.Trim()
        
        if ($code.Length -gt 50) { # Nur signifikante Blöcke
            $hash = [System.BitConverter]::ToString(
                [System.Security.Cryptography.MD5]::Create().ComputeHash(
                    [System.Text.Encoding]::UTF8.GetBytes($code)
                )
            ).Replace("-", "").Substring(0, 8)
            
            $blockFile = "$codeBlocksDir/CodeBlock-$hash.md"
            if (-not (Test-Path $blockFile)) {
                $blockContent = @"
---
language: $lang
source: $($sf.Name)
date: $(Get-Date -Format "yyyy-MM-dd")
tags: [code, snippet]
---

# Code Block $hash

## Source
From: [[$($sf.Name)]]

## Code
```$lang
$code
```
"@
                $blockContent | Out-File $blockFile -Encoding UTF8
                $blockCount++
            }
        }
    }
}

Write-Host "  Extracted $blockCount code blocks" -ForegroundColor Green

# Update Dashboard
Write-Host "`n📊 Updating Dashboard..." -ForegroundColor Yellow
$dashboardFile = "$secondBrainRoot/00-Dashboard/Dashboard.md"
if (Test-Path $dashboardFile) {
    # Dashboard aktualisieren (Dataview aktualisiert sich automatisch)
    Write-Host "  Dashboard ready" -ForegroundColor Green
}

# Summary
Write-Host "`n✅ Sync Complete!" -ForegroundColor Green
Write-Host "Locations:" -ForegroundColor Gray
Write-Host "  Sessions: $secondBrainRoot/01-Sessions/" -ForegroundColor Gray
Write-Host "  Projects: $secondBrainRoot/02-Areas/Projects/" -ForegroundColor Gray
Write-Host "  CodeBlocks: $secondBrainRoot/03-Resources/CodeBlocks/" -ForegroundColor Gray
Write-Host "  Dashboard: $secondBrainRoot/00-Dashboard/Dashboard.md" -ForegroundColor Gray

# Write timestamp for heartbeat tracking
$timestampFile = "$secondBrainRoot/.last-sync"
Get-Date -Format "o" | Out-File $timestampFile -Encoding UTF8
Write-Host "  Timestamp: $timestampFile" -ForegroundColor Gray
