#Requires -Version 5.1
<#
.SYNOPSIS
    Beispiel-Nutzung des ECC-Utilities Moduls
.DESCRIPTION
    Demonstriert alle Funktionen des ECC-Utilities PowerShell-Moduls
    mit praktischen Beispielen für den SecondBrain Vault.

.NOTES
    Pfad: SecondBrain/00-Meta/Scripts/ecc-framework/example-usage.ps1
    Modul: ECC-Utilities.psm1
#>

#region Modul importieren

$modulePath = Join-Path $PSScriptRoot "ECC-Utilities.psm1"

if (!(Test-Path $modulePath)) {
    Write-Host "FEHLER: Modul nicht gefunden: $modulePath" -ForegroundColor Red
    Write-Host "Stelle sicher, dass ECC-Utilities.psm1 im gleichen Ordner liegt." -ForegroundColor Yellow
    exit 1
}

Import-Module $modulePath -Force
Write-Host "✅ ECC-Utilities Modul erfolgreich geladen!" -ForegroundColor Green
Write-Host ""

#endregion

#region Beispiel 1: Logging

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BEISPIEL 1: Logging" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-ECCLog -Message "Demo gestartet" -Level "INFO"
Write-ECCLog -Message "Das ist eine Warnung" -Level "WARN"
Write-ECCLog -Message "Das ist ein Fehler (nur Demo)" -Level "ERROR"
Write-ECCLog -Message "Operation erfolgreich!" -Level "SUCCESS"
Write-ECCLog -Message "Debug-Information (nur sichtbar im Log-File)" -Level "DEBUG"

Write-Host ""
Write-Host "Log-Datei wurde erstellt in: .logs/" -ForegroundColor Gray
Write-Host ""

#endregion

#region Beispiel 2: Vault-Validierung

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BEISPIEL 2: Vault-Struktur validieren" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-ECCLog "Prüfe Vault-Struktur..." -Level "INFO"

$vaultPath = Join-Path $PSScriptRoot "..\..\.."
$validation = Test-VaultStructure -VaultPath $vaultPath

Write-Host ""
Write-Host "Ergebnis:" -ForegroundColor Cyan
Write-Host "  Erfolg: $($validation.Success)"
Write-Host "  Bestanden: $($validation.Passed)/$($validation.Total) ($($validation.Percent)%)"
Write-Host "  Fehler: $($validation.Failed)"

if ($validation.Failed -gt 0) {
    Write-Host ""
    Write-Host "Fehlende Elemente:" -ForegroundColor Yellow
    $validation.Results | Where-Object { $_.Exists -eq $false } | ForEach-Object {
        Write-Host "  ❌ $($_.Name) ($($_.Path))" -ForegroundColor Red
    }
}

Write-Host ""

#endregion

#region Beispiel 3: Retry-Logik

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BEISPIEL 3: Operation mit Retry" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-ECCLog "Simuliere fehleranfällige Operation..." -Level "INFO"

# Diese Operation könnte z.B. ein Netzwerk-Request oder Datei-Zugriff sein
$counter = 0
try {
    $result = Invoke-WithRetry -ScriptBlock {
        $counter++
        if ($counter -lt 3) {
            throw "Simulierter Fehler (Versuch $counter)"
        }
        return "Erfolg nach $counter Versuchen!"
    } -MaxRetries 3 -DelaySeconds 1 -OperationName "Demo-Operation"
    
    Write-ECCLog "Ergebnis: $result" -Level "SUCCESS"
}
catch {
    Write-ECCLog "Alle Versuche fehlgeschlagen: $_" -Level "ERROR"
}

Write-Host ""

#endregion

#region Beispiel 4: Sichere Datei-Operation

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BEISPIEL 4: Sichere Datei-Operation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Erstelle eine Test-Datei
$testFile = Join-Path $PSScriptRoot "example-test-file.txt"
"Das ist der originale Inhalt" | Set-Content $testFile

Write-ECCLog "Test-Datei erstellt: $testFile" -Level "INFO"

# Führe sichere Operation durch (mit automatischem Backup)
Write-ECCLog "Führe sichere Datei-Operation durch..." -Level "INFO"

Invoke-SafeFileOperation -Operation "Copy" -Path $testFile -Destination "$testFile.copy"

# Zeige Backup-Verzeichnis
$backupDir = Join-Path $PSScriptRoot "..\..\..\.backups"
if (Test-Path $backupDir) {
    $backups = Get-ChildItem $backupDir -Filter "*.bak" | Select-Object -Last 3
    if ($backups) {
        Write-Host ""
        Write-Host "Letzte Backups:" -ForegroundColor Cyan
        $backups | ForEach-Object {
            Write-Host "  📦 $($_.Name) ($([math]::Round($_.Length/1KB,2)) KB)" -ForegroundColor Gray
        }
    }
}

# Cleanup
Remove-Item $testFile -ErrorAction SilentlyContinue
Remove-Item "$testFile.copy" -ErrorAction SilentlyContinue
Write-ECCLog "Test-Dateien aufgeräumt" -Level "DEBUG"

Write-Host ""

#endregion

#region Beispiel 5: Migrations-Check

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BEISPIEL 5: Prüfe ob Migration nötig" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Erstelle temporäre Test-Dateien
$sourceFile = Join-Path $PSScriptRoot "source-demo.txt"
$targetFile = Join-Path $PSScriptRoot "target-demo.txt"

"Quell-Inhalt" | Set-Content $sourceFile
Start-Sleep -Milliseconds 100  # Kleine Pause für unterschiedliche Zeitstempel
"Ziel-Inhalt" | Set-Content $targetFile

$shouldMigrate = Test-MigrationCandidate -SourceFile $sourceFile -TargetFile $targetFile

Write-Host ""
Write-Host "Migration empfohlen: $shouldMigrate" -ForegroundColor $(if ($shouldMigrate) { "Green" } else { "Yellow" })

# Cleanup
Remove-Item $sourceFile -ErrorAction SilentlyContinue
Remove-Item $targetFile -ErrorAction SilentlyContinue

#endregion

#region Zusammenfassung

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DEMO ABGESCHLOSSEN!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Alle Funktionen des ECC-Utilities Moduls wurden demonstriert:" -ForegroundColor White
Write-Host ""
Write-Host "  ✅ Write-ECCLog      - Logging mit Zeitstempel und Farben"
Write-Host "  ✅ Test-VaultStructure - Vault-Validierung"
Write-Host "  ✅ Invoke-WithRetry    - Retry-Logik für fehleranfällige Ops"
Write-Host "  ✅ Invoke-SafeFileOperation - Sichere Datei-Ops mit Backup"
Write-Host "  ✅ Test-MigrationCandidate - Prüft ob Migration nötig"
Write-Host ""
Write-Host "Modul-Pfad: $modulePath" -ForegroundColor Gray
Write-Host ""
Write-Host "Nutze diese Funktionen in deinen eigenen Skripten:" -ForegroundColor Cyan
Write-Host '  Import-Module "Pfad\zu\ECC-Utilities.psm1"' -ForegroundColor Yellow
Write-Host ""

#endregion