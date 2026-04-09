#!/usr/bin/env pwsh
# Second Brain Sync - Safe Version (no Here-Strings)
# Kopiert OpenClaw Sessions ins PARA-System

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Pfade
$workspaceRoot = "C:\Users\andre\.openclaw\workspace"
$secondBrainRoot = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain"
$sessionsSourcePath = "$workspaceRoot\second-brain\01-Sessions"
$memoryDir = "$workspaceRoot\memory"

Write-Host "Second Brain Sync" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host "Source: $sessionsSourcePath" -ForegroundColor Gray
Write-Host "Target: $secondBrainRoot" -ForegroundColor Gray
Write-Host ""

# Pruefe Quellpfad
if (!(Test-Path $sessionsSourcePath)) {
    Write-Host "Source path not found: $sessionsSourcePath" -ForegroundColor Red
    Write-Host "Trying memory directory instead..." -ForegroundColor Yellow
    $sessionsSourcePath = $memoryDir
    if (!(Test-Path $sessionsSourcePath)) {
        Write-Error "Neither sessions nor memory path found!"
        exit 1
    }
}

# Pruefe/Ziele Zielpfad
if (!(Test-Path $secondBrainRoot)) {
    Write-Host "Creating SecondBrain directory..." -ForegroundColor Yellow
    if (!$DryRun) {
        New-Item -ItemType Directory -Path $secondBrainRoot -Force | Out-Null
    }
}

# Erstelle Unterverzeichnisse
$targetDirs = @(
    "$secondBrainRoot\01-Sessions",
    "$secondBrainRoot\02-Areas\Projects",
    "$secondBrainRoot\03-Resources\CodeBlocks"
)
foreach ($dir in $targetDirs) {
    if (!(Test-Path $dir)) {
        if (!$DryRun) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
}

# Sync: Sessions
Write-Host "Syncing Sessions..." -ForegroundColor Yellow

$sessionFiles = Get-ChildItem "$sessionsSourcePath\*.md" -ErrorAction SilentlyContinue | Sort-Object Name

$synced = 0
$skipped = 0

foreach ($session in $sessionFiles) {
    $content = Get-Content $session.FullName -Raw
    $sessionName = $session.BaseName
    $targetFile = "$secondBrainRoot\01-Sessions\$sessionName.md"
    
    if (Test-Path $targetFile) {
        if (!$Force) {
            Write-Host "  Skipped (exists): $sessionName" -ForegroundColor Yellow
            $skipped++
            continue
        }
    }
    
    if ($DryRun) {
        Write-Host "  Would sync: $sessionName" -ForegroundColor Gray
        $synced++
        continue
    }
    
    # String ohne Here-String, mit Interpolation
    $sbContent = "---" + "`n" +
        "date: $sessionName" + "`n" +
        "type: session" + "`n" +
        "source: $($session.FullName)" + "`n" +
        "tags: [synced, session]" + "`n" +
        "---" + "`n" +
        "`n" +
        "# Session $sessionName" + "`n" +
        "`n" +
        "## Source" + "`n" +
        "Original: $($session.FullName)" + "`n" +
        "`n" +
        "## Content" + "`n" +
        $content
    
    $sbContent | Out-File $targetFile -Encoding UTF8
    Write-Host "  Synced: $sessionName" -ForegroundColor Green
    $synced++
}

Write-Host ""
Write-Host "Session sync complete. Synced: $synced, Skipped: $skipped" -ForegroundColor Green

# Code Blocks extrahieren
Write-Host ""
Write-Host "Extracting Code Blocks..." -ForegroundColor Yellow

$codeBlocksDir = "$secondBrainRoot\03-Resources\CodeBlocks"
$syncedSessions = Get-ChildItem "$secondBrainRoot\01-Sessions\*.md" -ErrorAction SilentlyContinue
$blockCount = 0

foreach ($sf in $syncedSessions) {
    $content = Get-Content $sf.FullName -Raw
    
    # Suche Code-Blocks mit Regex
    $codeBlocks = [regex]::Matches($content, '```(\w+)?\s*([\s\S]*?)```')
    
    foreach ($block in $codeBlocks) {
        $lang = $block.Groups[1].Value
        $code = $block.Groups[2].Value.Trim()
        
        # Nur signifikante Bloecke (mehr als 50 Zeichen)
        if ($code.Length -gt 50) {
            $hash = [System.BitConverter]::ToString(
                [System.Security.Cryptography.MD5]::Create().ComputeHash(
                    [System.Text.Encoding]::UTF8.GetBytes($code)
                )
            ).Replace("-", "").Substring(0, 8)
            
            $blockFile = "$codeBlocksDir\CodeBlock-$hash.md"
            if (!(Test-Path $blockFile)) {
                # String ohne Here-String
                $blockContent = "---" + "`n" +
                    "language: $lang" + "`n" +
                    "source: $($sf.Name)" + "`n" +
                    "date: $(Get-Date -Format 'yyyy-MM-dd')" + "`n" +
                    "tags: [code, snippet]" + "`n" +
                    "---" + "`n" +
                    "`n" +
                    "# Code Block $hash" + "`n" +
                    "`n" +
                    "## Source" + "`n" +
                    "From: [[$($sf.Name)]]" + "`n" +
                    "`n" +
                    "## Code" + "`n" +
                    "```$lang" + "`n" +
                    $code + "`n" +
                    "```"
                
                $blockContent | Out-File $blockFile -Encoding UTF8
                $blockCount++
            }
        }
    }
}

Write-Host "Extracted $blockCount code blocks" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "Sync Complete!" -ForegroundColor Green
Write-Host "Locations:" -ForegroundColor Gray
Write-Host "  Sessions: $secondBrainRoot\01-Sessions\" -ForegroundColor Gray
Write-Host "  CodeBlocks: $secondBrainRoot\03-Resources\CodeBlocks\" -ForegroundColor Gray
Write-Host "  Dashboard: $secondBrainRoot\00-Dashboard\Dashboard.md" -ForegroundColor Gray

# Timestamp
if (!$DryRun) {
    $timestampFile = "$secondBrainRoot\.last-sync"
    Get-Date -Format "o" | Out-File $timestampFile -Encoding UTF8
}
