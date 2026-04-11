# Vault Reorganizer - PowerShell 5.1 Compatible
param([switch]$DryRun)

$VaultPath = "$env:USERPROFILE\.openclaw\workspace\obsidian-vault"
$BackupPath = Join-Path (Join-Path $VaultPath "99-Archive") "2026-04-migration"

Write-Host "Vault-Reorganisation (DryRun: $DryRun)" -ForegroundColor Cyan
Write-Host "Vault: $VaultPath" -ForegroundColor Gray
Write-Host ""

# 1. Analyse
Write-Host "Phase 1: Analyse..." -ForegroundColor Yellow
$allFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse
$uuidFiles = @()
$namedFiles = @()

foreach ($file in $allFiles) {
    if ($file.Name -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.md$') {
        $uuidFiles += $file
    } else {
        $namedFiles += $file
    }
}

Write-Host "  Gefunden: $($allFiles.Count) Dateien" -ForegroundColor Gray
Write-Host "  - UUID-Dateien: $($uuidFiles.Count)" -ForegroundColor Gray
Write-Host "  - Benannte: $($namedFiles.Count)" -ForegroundColor Gray
Write-Host ""

# 2. Neue Struktur
Write-Host "Phase 2: Verzeichnisse erstellen..." -ForegroundColor Yellow
$dirs = @("00-Meta", "00-Meta\Inbox", "01-Daily", "02-Projects\ECC-Framework", "02-Projects\Autoresearch", "03-Knowledge\Code-Snippets", "99-Archive\2026-04-migration")

foreach ($dir in $dirs) {
    $fullPath = Join-Path $VaultPath $dir
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
    Write-Host "  + $dir" -ForegroundColor Green
}
Write-Host ""

# 3. UUID-Dateien migrieren
Write-Host "Phase 3: UUID-Dateien migrieren..." -ForegroundColor Yellow
$migrated = 0

foreach ($file in $uuidFiles) {
    Write-Host "  $($file.Name)" -ForegroundColor Gray -NoNewline
    
    $content = Get-Content -Path $file.FullName -Raw
    
    $date = "unknown"
    if ($content -match 'date:\s*(\d{4}-\d{2}-\d{2})') {
        $date = $Matches[1]
    }
    
    # Kompakte Note erstellen
    $lines = @()
    $lines += "---"
    $lines += "date: $date"
    $lines += "type: decision"
    $lines += "tags: [session, migrated]"
    $lines += "source: $($file.Name)"
    $lines += "---"
    $lines += ""
    $lines += "# Session $date"
    $lines += ""
    $lines += "## Zusammenfassung"
    $lines += "*Wird durch Night Agent generiert...*"
    $lines += ""
    $lines += "## Verwandt"
    $lines += "- [[MOC-Startseite]]"
    $lines += ""
    
    $newContent = $lines -join "`n"
    
    $targetName = "Session-$date.md"
    $dailyPath = Join-Path $VaultPath "01-Daily"
    $targetPath = Join-Path $dailyPath $targetName
    
    $counter = 1
    while (Test-Path $targetPath) {
        $targetName = "Session-$date-$counter.md"
        $targetPath = Join-Path $dailyPath $targetName
        $counter++
    }
    
    if (-not $DryRun) {
        Set-Content -Path $targetPath -Value $newContent -Encoding UTF8
        $backupDir = Join-Path $BackupPath "01-Sessions"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        $destPath = Join-Path $backupDir $file.Name
        Move-Item -Path $file.FullName -Destination $destPath -Force
    }
    
    Write-Host " -> 01-Daily\$targetName" -ForegroundColor Green
    $migrated++
}
Write-Host ""

Write-Host "Fertig!" -ForegroundColor Cyan
Write-Host "  Migriert: $migrated UUID-Dateien" -ForegroundColor Gray
if ($DryRun) {
    Write-Host "  DRY RUN - Nichts wurde veraendert" -ForegroundColor Yellow
} else {
    Write-Host "  Backup: $BackupPath" -ForegroundColor Gray
}
