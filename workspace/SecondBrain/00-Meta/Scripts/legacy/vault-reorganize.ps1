#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Vault-Reorganisierung: UUID-Dateien zu kompakten Entscheidungs-Notes

.DESCRIPTION
    Migriert den Obsidian Vault zu einer neuen PARA-Struktur:
    - UUID-Dateien werden zusammengefasst
    - Automatische WikiLinks-Generierung
    - Originale werden nach 99-Archive/ verschoben

.PARAMETER VaultPath
    Pfad zum Obsidian Vault

.PARAMETER DryRun
    Simuliert die Migration ohne Dateien zu ändern
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$VaultPath = "$env:USERPROFILE\.openclaw\workspace\obsidian-vault",

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# =============================================================================
# KONFIGURATION
# =============================================================================

$Config = @{
    VaultPath = $VaultPath
    BackupPath = Join-Path $VaultPath "99-Archive" "2026-04-migration"
    NewStructure = @{
        "00-Meta" = @("Dashboard", "MOCs", "Inbox")
        "01-Daily" = @()  # Tägliche Notes
        "02-Projects" = @("ECC-Framework", "Autoresearch", "Mission-Control")
        "03-Knowledge" = @("Code-Snippets", "Hardware", "Patterns", "Decisions")
        "99-Archive" = @("2026-04-migration")
    }
}

# =============================================================================
# FUNKTIONEN
# =============================================================================

function Test-UUIDFileName {
    param([string]$FileName)
    # UUID Pattern: 8-4-4-4-12 Hex chars
    return $FileName -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.md$'
}

function Get-YamlFrontMatter {
    param([string]$Content)
    
    if ($Content -match '^---\s*\n(.*?)\n---\s*\n') {
        $yamlText = $Matches[1]
        $result = @{}
        
        foreach ($line in $yamlText -split "`n") {
            if ($line -match '^(\w+):\s*(.*)$') {
                $key = $Matches[1].Trim()
                $value = $Matches[2].Trim()
                $result[$key] = $value
            }
        }
        return $result
    }
    return $null
}

function Extract-Decisions {
    param([string]$Content)
    
    $decisions = @()
    $todos = @()
    $codeBlocks = @()
    
    # Finde Entscheidungen
    if ($Content -match '##?\s*(?:Getroffene\s+)?Entscheidungen?\s*\n(.*?)(?=##|\Z)') {
        $decisionSection = $Matches[1]
        $decisions = $decisionSection -split "`n" | Where-Object { $_ -match '^\s*[-*]\s*\[.\]' } | ForEach-Object { $_.Trim() }
    }
    
    # Finde TODOs
    $todoMatches = [regex]::Matches($Content, '- \[ \] (.+)')
    foreach ($match in $todoMatches) {
        $todos += $match.Groups[1].Value.Trim()
    }
    
    # Finde Code-Blöcke mit Dateinamen/Keywords
    $codeBlockMatches = [regex]::Matches($Content, '```\w+\s*\n(.*?)```', 'Singleline')
    foreach ($match in $codeBlockMatches) {
        $code = $match.Groups[1].Value
        # Extrahiere Dateinamen oder Schlüsselwörter
        if ($code -match '(\w+[.-]\w+)\s*=') {
            $codeBlocks += $Matches[1]
        }
    }
    
    return @{
        Decisions = $decisions
        Todos = $todos
        CodeBlocks = $codeBlocks
    }
}

function New-CompactNote {
    param(
        [string]$OriginalFile,
        [hashtable]$YamlData,
        [string]$Content,
        [hashtable]$Extracted
    )
    
    $date = if ($YamlData.date) { $YamlData.date } else { "2026-04-10" }
    $title = if ($YamlData.title) { $YamlData.title } else { "Session $date" }
    $tags = if ($YamlData.tags) { $YamlData.tags } else { "[session]" }
    
    $sb = [System.Text.StringBuilder]::new()
    
    # YAML Front Matter
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("date: $date")
    [void]$sb.AppendLine("type: decision")
    [void]$sb.AppendLine("tags: $tags")
    [void]$sb.AppendLine("source: $(Split-Path $OriginalFile -Leaf)")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine()
    
    # Titel
    [void]$sb.AppendLine("# $title")
    [void]$sb.AppendLine()
    
    # Zusammenfassung (wird durch LLM generiert - Platzhalter)
    [void]$sb.AppendLine("## Zusammenfassung")
    [void]$sb.AppendLine("*Kompakte Zusammenfassung der Session...*")
    [void]$sb.AppendLine()
    
    # Entscheidungen
    if ($Extracted.Decisions.Count -gt 0) {
        [void]$sb.AppendLine("## Entscheidungen")
        foreach ($decision in $Extracted.Decisions) {
            [void]$sb.AppendLine($decision)
        }
        [void]$sb.AppendLine()
    }
    
    # Offene Punkte
    if ($Extracted.Todos.Count -gt 0) {
        [void]$sb.AppendLine("## Offen")
        foreach ($todo in $Extracted.Todos | Select-Object -First 5) {
            [void]$sb.AppendLine("- [ ] $todo")
        }
        [void]$sb.AppendLine()
    }
    
    # Code-Referenzen
    if ($Extracted.CodeBlocks.Count -gt 0) {
        [void]$sb.AppendLine("## Code-Referenzen")
        foreach ($code in $Extracted.CodeBlocks | Select-Object -First 3) {
            [void]$sb.AppendLine("- [[CodeBlock:$code]]")
        }
        [void]$sb.AppendLine()
    }
    
    # Related (Platzhalter für spätere WikiLinks)
    [void]$sb.AppendLine("## Verwandt")
    [void]$sb.AppendLine("- [[MOC-Startseite]]")
    [void]$sb.AppendLine()
    
    return $sb.ToString()
}

# =============================================================================
# HAUPTLOGIK
# =============================================================================

function Start-VaultMigration {
    Write-Host "🔄 Vault-Reorganisation wird gestartet..." -ForegroundColor Cyan
    Write-Host "   Vault: $VaultPath" -ForegroundColor Gray
    Write-Host "   DryRun: $DryRun" -ForegroundColor Gray
    Write-Host ""
    
    # 1. Prüfe Vault-Existenz
    if (-not (Test-Path $VaultPath)) {
        throw "Vault-Pfad nicht gefunden: $VaultPath"
    }
    
    # 2. Analyse: Alle .md Dateien finden
    Write-Host "📊 Phase 1: Analyse..." -ForegroundColor Yellow
    $allFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse
    $uuidFiles = $allFiles | Where-Object { Test-UUIDFileName $_.Name }
    $namedFiles = $allFiles | Where-Object { -not (Test-UUIDFileName $_.Name) }
    
    Write-Host "   Gefunden: $($allFiles.Count) Dateien total" -ForegroundColor Gray
    Write-Host "   - UUID-Dateien: $($uuidFiles.Count) (werden komprimiert)" -ForegroundColor Gray
    Write-Host "   - Benannte Dateien: $($namedFiles.Count) (werden analysiert)" -ForegroundColor Gray
    Write-Host ""
    
    # 3. Neue Struktur erstellen
    Write-Host "🏗️  Phase 2: Neue Verzeichnisstruktur..." -ForegroundColor Yellow
    foreach ($dir in $Config.NewStructure.Keys) {
        $fullPath = Join-Path $VaultPath $dir
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        }
        Write-Host "   ✅ $dir" -ForegroundColor Green
        
        foreach ($sub in $Config.NewStructure[$dir]) {
            $subPath = Join-Path $fullPath $sub
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $subPath -Force | Out-Null
            }
            Write-Host "      └─ $sub" -ForegroundColor Gray
        }
    }
    Write-Host ""
    
    # 4. Migration: UUID-Dateien verarbeiten
    Write-Host "📦 Phase 3: UUID-Dateien migrieren..." -ForegroundColor Yellow
    $migrationReport = @()
    
    foreach ($file in $uuidFiles) {
        Write-Host "   Verarbeite: $($file.Name)" -ForegroundColor Gray -NoNewline
        
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $yaml = Get-YamlFrontMatter $content
        $extracted = Extract-Decisions $content
        
        # Erstelle kompakte Note
        $compactContent = New-CompactNote -OriginalFile $file.FullName -YamlData $yaml -Content $content -Extracted $extracted
        
        # Zielpfad bestimmen (basierend auf Datum)
        $date = if ($yaml.date) { $yaml.date } else { "unknown" }
        $targetName = "Session-$date.md"
        $targetPath = Join-Path $VaultPath "01-Daily" $targetName
        
        # Prüfe auf Duplikate
        $counter = 1
        while (Test-Path $targetPath) {
            $targetName = "Session-$date-$counter.md"
            $targetPath = Join-Path $VaultPath "01-Daily" $targetName
            $counter++
        }
        
        if (-not $DryRun) {
            # Schreibe kompakte Note
            Set-Content -Path $targetPath -Value $compactContent -Encoding UTF8
            
            # Verschiebe Original ins Archiv
            $backupDir = Join-Path $Config.BackupPath "01-Sessions"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Move-Item -Path $file.FullName -Destination (Join-Path $backupDir $file.Name) -Force
        }
        
        Write-Host " → $targetName" -ForegroundColor Green
        
        $migrationReport += [PSCustomObject]@{
            Original = $file.Name
            NewName = $targetName
            Date = $date
            Decisions = $extracted.Decisions.Count
            Todos = $extracted.Todos.Count
        }
    }
    Write-Host ""
    
    # 5. Benannte Dateien analysieren
    Write-Host "📋 Phase 4: Benannte Dateien katalogisieren..." -ForegroundColor Yellow
    foreach ($file in $namedFiles) {
        $relativePath = $file.FullName.Substring($VaultPath.Length + 1)
        Write-Host "   📄 $relativePath" -ForegroundColor Gray
        # Hier könnte weitere Logik folgen
    }
    Write-Host ""
    
    # 6. Zusammenfassung
    Write-Host "✅ Migration abgeschlossen!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📊 Statistik:" -ForegroundColor White
    Write-Host "   UUID-Dateien migriert: $($uuidFiles.Count)" -ForegroundColor Gray
    Write-Host "   Benannte Dateien: $($namedFiles.Count)" -ForegroundColor Gray
    Write-Host "   Neue Struktur: $($Config.NewStructure.Count) Hauptordner" -ForegroundColor Gray
    Write-Host ""
    
    if ($DryRun) {
        Write-Host "⚠️  DRY RUN - Keine Dateien wurden verändert!" -ForegroundColor Yellow
        Write-Host "   Führe ohne -DryRun aus um zu migrieren." -ForegroundColor Gray
    } else {
        Write-Host "💾 Backup: $($Config.BackupPath)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "📝 Nächste Schritte:" -ForegroundColor Cyan
        Write-Host "   1. Vault in Obsidian öffnen" -ForegroundColor Gray
        Write-Host "   2. WikiLinks überprüfen" -ForegroundColor Gray
        Write-Host "   3. Index neu aufbauen" -ForegroundColor Gray
    }
    
    # Exportiere Report
    $reportPath = Join-Path $VaultPath "99-Archive" "migration-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    if (-not $DryRun -and $migrationReport.Count -gt 0) {
        $migrationReport | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
        Write-Host "   📄 Report: $reportPath" -ForegroundColor Gray
    }
}

# =============================================================================
# START
# =============================================================================

try {
    Start-VaultMigration
} catch {
    Write-Host "❌ FEHLER: $_" -ForegroundColor Red
    exit 1
}
