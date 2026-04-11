# SecondBrain Migrationsskript
# Migriert verbleibende Dateien aus obsidian-vault/ nach SecondBrain/
# und löscht dann den alten Ordner

param(
    [string]$SourcePath = "C:\Users\andre\.openclaw\workspace\obsidian-vault",
    [string]$TargetPath = "C:\Users\andre\.openclaw\workspace\SecondBrain",
    [switch]$WhatIf = $false
)

Write-Host "=== SecondBrain Migration ===" -ForegroundColor Cyan
Write-Host "Quelle: $SourcePath" -ForegroundColor Gray
Write-Host "Ziel: $TargetPath" -ForegroundColor Gray
Write-Host ""

# Statistik
$stats = @{
    Migrated = 0
    Skipped = 0
    Errors = 0
}

# 1. Migriere verbleibende Daily Notes
Write-Host "1. Migriere Daily Notes..." -ForegroundColor Yellow
$dailySource = Join-Path $SourcePath "01-Daily"
$dailyTarget = Join-Path $TargetPath "01-Daily"

if (Test-Path $dailySource) {
    Get-ChildItem -Path $dailySource -Filter "*.md" | ForEach-Object {
        $targetFile = Join-Path $dailyTarget $_.Name
        if (-not (Test-Path $targetFile)) {
            Write-Host "  + $($_.Name)" -ForegroundColor Green
            if (-not $WhatIf) {
                Copy-Item $_.FullName $targetFile
                $stats.Migrated++
            }
        } else {
            Write-Host "  = $($_.Name) (existiert)" -ForegroundColor Gray
            $stats.Skipped++
        }
    }
}

# 2. Migriere Sessions (als Projekte oder Daily, je nach Inhalt)
Write-Host "`n2. Prüfe Sessions..." -ForegroundColor Yellow
$sessionsSource = Join-Path $SourcePath "01-Sessions"
if (Test-Path $sessionsSource) {
    $sessionCount = (Get-ChildItem -Path $sessionsSource -Filter "*.md").Count
    Write-Host "  $sessionCount Sessions gefunden" -ForegroundColor Cyan
    Write-Host "  [INFO] Sessions werden manuell klassifiziert (Projekt vs Daily)" -ForegroundColor Gray
}

# 3. Migriere Templates (falls neue/bessere)
Write-Host "`n3. Prüfe Templates..." -ForegroundColor Yellow
$templatesSource = Join-Path $SourcePath "05-Templates"
if (Test-Path $templatesSource) {
    Get-ChildItem -Path $templatesSource -Filter "*.md" | ForEach-Object {
        Write-Host "  ? $($_.Name) - manuell prüfen" -ForegroundColor Yellow
    }
}

# 4. Migriere Scripts
Write-Host "`n4. Migriere Scripts..." -ForegroundColor Yellow
$scriptsSource = Join-Path $SourcePath "scripts"
$scriptsTarget = Join-Path $TargetPath "00-Meta\Scripts\legacy"
if (Test-Path $scriptsSource) {
    if (-not $WhatIf) {
        New-Item -ItemType Directory -Path $scriptsTarget -Force | Out-Null
        Get-ChildItem -Path $scriptsSource -Filter "*.ps1" | ForEach-Object {
            $targetFile = Join-Path $scriptsTarget $_.Name
            if (-not (Test-Path $targetFile)) {
                Write-Host "  + $($_.Name)" -ForegroundColor Green
                Copy-Item $_.FullName $targetFile
                $stats.Migrated++
            } else {
                Write-Host "  = $($_.Name) (existiert)" -ForegroundColor Gray
                $stats.Skipped++
            }
        }
    }
}

# 5. Archiviere 99-Archive (lösche, da Backup in vault-archive existiert)
Write-Host "`n5. Bereinige 99-Archive..." -ForegroundColor Yellow
$archivePath = Join-Path $SourcePath "99-Archive"
if (Test-Path $archivePath) {
    $archiveSize = [math]::Round((Get-ChildItem $archivePath -Recurse | Measure-Object Length -Sum).Sum / 1MB, 2)
    Write-Host "  ! Lösche $archiveSize MB Backup-Dateien" -ForegroundColor Red
    if (-not $WhatIf) {
        Remove-Item -Path $archivePath -Recurse -Force
        Write-Host "  ✓ Gelöscht" -ForegroundColor Green
    }
}

# Zusammenfassung
Write-Host "`n=== Zusammenfassung ===" -ForegroundColor Cyan
Write-Host "Migriert: $($stats.Migrated)" -ForegroundColor Green
Write-Host "Übersprungen: $($stats.Skipped)" -ForegroundColor Gray
Write-Host "Fehler: $($stats.Errors)" -ForegroundColor Red

# Lösche obsidian-vault (nur wenn alles erfolgreich)
if (-not $WhatIf -and $stats.Errors -eq 0) {
    Write-Host "`n6. Lösche obsidian-vault..." -ForegroundColor Red
    Write-Host "  WARNUNG: Dies löscht den gesamten Ordner!" -ForegroundColor Yellow
    Write-Host "  Drücke ENTER zum Bestätigen oder STRG+C zum Abbrechen..." -ForegroundColor Yellow
    Read-Host
    
    Remove-Item -Path $SourcePath -Recurse -Force
    Write-Host "  ✓ obsidian-vault gelöscht" -ForegroundColor Green
} elseif ($WhatIf) {
    Write-Host "`n[WhatIf] Ordner würde gelöscht werden: $SourcePath" -ForegroundColor Magenta
}

Write-Host "`n=== Migration abgeschlossen ===" -ForegroundColor Cyan
