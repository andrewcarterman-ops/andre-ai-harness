#!/usr/bin/env pwsh
# Knowledge Curator Analysis Tool
# Analyzes Second Brain vault for connections, orphans, and quality

param(
    [string]$VaultPath = "C:\Users\andre\.openclaw\workspace\second-brain",
    [switch]$Detailed,
    [switch]$AutoDecide,
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"

Write-Host "Knowledge Curator Analysis" -ForegroundColor Cyan
Write-Host "Vault: $VaultPath" -ForegroundColor Gray
Write-Host ""

# Initialize results
$analysis = @{
    timestamp = Get-Date -Format "o"
    vault_path = $VaultPath
    total_notes = 0
    connected_notes = 0
    orphaned_notes = 0
    broken_links = 0
    notes = @()
    hubs = @()
    orphans = @()
}

# Get all markdown files
$allFiles = Get-ChildItem $VaultPath -Recurse -Filter "*.md" -ErrorAction SilentlyContinue
$analysis.total_notes = $allFiles.Count

Write-Host "Found $($allFiles.Count) notes" -ForegroundColor Green

if ($allFiles.Count -eq 0) {
    Write-Host "No markdown files found in vault!" -ForegroundColor Red
    exit 1
}

# Analyze each note
$counter = 0
foreach ($file in $allFiles) {
    $counter++
    if ($counter % 10 -eq 0) {
        Write-Host "  Processing... $counter/$($allFiles.Count)" -ForegroundColor Gray
    }
    
    $relativePath = $file.FullName.Substring($VaultPath.Length + 1)
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
    if (-not $content) { continue }
    
    # Count backlinks (other files linking to this)
    $backlinks = 0
    $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    
    foreach ($otherFile in $allFiles) {
        if ($otherFile.FullName -eq $file.FullName) { continue }
        $otherContent = Get-Content $otherFile.FullName -Raw -ErrorAction SilentlyContinue
        if ($otherContent -and ($otherContent -match "\[\[.*?$fileNameWithoutExt.*?\]\]")) {
            $backlinks++
        }
    }
    
    # Count outgoing links
    $outgoingLinks = ([regex]::Matches($content, "\[\[(.*?)\]\]")).Count
    
    # Check for tags
    $tags = @()
    if ($content -match "tags:\s*\[(.*?)\]") {
        $tags = $matches[1] -split "," | ForEach-Object { $_.Trim() -replace '"', '' }
    }
    
    # Detect broken links
    $brokenLinksInFile = 0
    $linkMatches = [regex]::Matches($content, "\[\[(.*?)\]\]")
    foreach ($match in $linkMatches) {
        $linkedFile = $match.Groups[1].Value -replace "\|.*", ""
        $linkedFile = $linkedFile.Trim()
        $possiblePaths = @(
            "$VaultPath\$linkedFile.md",
            "$VaultPath\01-Sessions\$linkedFile.md",
            "$VaultPath\02-Areas\$linkedFile.md"
        )
        $found = $false
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) { $found = $true; break }
        }
        if (-not $found) { $brokenLinksInFile++ }
    }
    $analysis.broken_links += $brokenLinksInFile
    
    # Evaluate importance
    $importanceScore = 0
    if ($backlinks -ge 5) { $importanceScore += 3 }
    elseif ($backlinks -ge 2) { $importanceScore += 2 }
    
    if ($tags -contains "decision" -or $tags -contains "adr") { $importanceScore += 2 }
    if ($content -match "type:\s*session") { $importanceScore += 1 }
    if ($content.Length -gt 2000) { $importanceScore += 1 }
    
    # Determine if orphaned (except dashboards)
    $isDashboard = $content -match "type:\s*dashboard|Dashboard"
    $isOrphan = ($backlinks -eq 0) -and (-not $isDashboard)
    if ($isOrphan) { $analysis.orphaned_notes++ }
    else { $analysis.connected_notes++ }
    
    # Recommendation
    $recommendation = "KEEP"
    $reason = "Active knowledge"
    
    if ($isOrphan) {
        if ($content.Length -lt 500) {
            $recommendation = "DELETE"
            $reason = "Orphaned, short content"
        } else {
            $recommendation = "REVIEW"
            $reason = "Orphaned but has content"
        }
    }
    
    $noteInfo = [PSCustomObject]@{
        file = $relativePath
        name = $file.BaseName
        backlinks = $backlinks
        outgoing_links = $outgoingLinks
        tags = ($tags -join ", ")
        size = $content.Length
        importance_score = $importanceScore
        is_orphan = $isOrphan
        broken_links = $brokenLinksInFile
        recommendation = $recommendation
        reason = $reason
    }
    
    $analysis.notes += $noteInfo
}

# Identify hubs (top 10 by backlinks)
$analysis.hubs = $analysis.notes | Sort-Object backlinks -Descending | Select-Object -First 10 | Select-Object name, backlinks

# Identify orphans
$analysis.orphans = $analysis.notes | Where-Object { $_.is_orphan -eq $true } | Select-Object name, size, recommendation, reason

# Display Results
Write-Host "`nANALYSIS RESULTS" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

$pctConnected = if ($analysis.total_notes -gt 0) { [math]::Round($analysis.connected_notes/$analysis.total_notes*100, 1) } else { 0 }
$pctOrphaned = if ($analysis.total_notes -gt 0) { [math]::Round($analysis.orphaned_notes/$analysis.total_notes*100, 1) } else { 0 }

Write-Host "Total Notes: $($analysis.total_notes)" -ForegroundColor White
Write-Host "Connected: $($analysis.connected_notes) ($pctConnected %)" -ForegroundColor Green
Write-Host "Orphaned: $($analysis.orphaned_notes) ($pctOrphaned %)" -ForegroundColor Yellow
Write-Host "Broken Links: $($analysis.broken_links)" -ForegroundColor $(if($analysis.broken_links -eq 0){"Green"}else{"Red"})

Write-Host "`nTOP 10 HUB NOTES" -ForegroundColor Cyan
$analysis.hubs | Format-Table -AutoSize

if ($analysis.orphans.Count -gt 0) {
    Write-Host "`nORPHANED NOTES" -ForegroundColor Cyan
    $analysis.orphans | Format-Table -AutoSize
}

# Recommendations
$toDelete = $analysis.notes | Where-Object { $_.recommendation -eq "DELETE" }
$toReview = $analysis.notes | Where-Object { $_.recommendation -eq "REVIEW" }

Write-Host "`nRECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "DELETE ($($toDelete.Count) notes):" -ForegroundColor Red
$toDelete | ForEach-Object { Write-Host "  - $($_.file)" -ForegroundColor Gray }

Write-Host "`nREVIEW ($($toReview.Count) notes):" -ForegroundColor Yellow
$toReview | ForEach-Object { Write-Host "  - $($_.file)" -ForegroundColor Gray }

# Save report
if (-not $OutputPath) {
    $OutputPath = "$VaultPath/../analysis-report-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
}
$analysis | ConvertTo-Json -Depth 5 | Out-File $OutputPath -Encoding UTF8
Write-Host "`nReport saved: $OutputPath" -ForegroundColor Green

Write-Host "`nAnalysis complete!" -ForegroundColor Green
