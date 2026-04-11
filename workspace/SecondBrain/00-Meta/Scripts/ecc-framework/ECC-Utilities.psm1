#Requires -Version 5.1
<#
.SYNOPSIS
    ECC Utility Module - Logging, Validation & Error Handling
.DESCRIPTION
    Wiederverwendbare Funktionen für Logging, Validierung und Fehlerbehandlung
    Extrahiert aus Setup-SecondBrain.ps1 und angepasst für unseren Vault
.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    Location: SecondBrain/00-Meta/Scripts/ecc-framework/
#>

#region Logging Functions

<#
.SYNOPSIS
    Schreibt einen Log-Eintrag mit Zeitstempel
.DESCRIPTION
    Loggt Nachrichten in Konsole (mit Farben) und in Datei
.PARAMETER Message
    Die zu loggende Nachricht
.PARAMETER Level
    Log-Level: INFO, WARN, ERROR, SUCCESS, DEBUG
.PARAMETER LogFile
    Pfad zur Log-Datei (optional, default: .logs/utility-{datum}.log)
.EXAMPLE
    Write-ECCLog -Message "Migration gestartet" -Level "INFO"
.EXAMPLE
    Write-ECCLog -Message "Fehler aufgetreten" -Level "ERROR"
#>
function Write-ECCLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO",
        
        [string]$LogFile = $null
    )
    
    # Default Log-File
    if ([string]::IsNullOrEmpty($LogFile)) {
        $logDir = Join-Path $PSScriptRoot "..\..\..\.logs"
        if (!(Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        $LogFile = Join-Path $logDir "ecc-utility-$(Get-Date -Format 'yyyyMMdd').log"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Console Output with Colors
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG"   { Write-Host $logEntry -ForegroundColor Gray }
    }
    
    # File Logging
    $logDir = Split-Path $LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $LogFile -Value $logEntry
}

#endregion

#region Validation Functions

<#
.SYNOPSIS
    Validiert die Vault-Struktur
.DESCRIPTION
    Prüft ob alle erwarteten Ordner und Dateien existieren
.PARAMETER VaultPath
    Pfad zum Vault (default: ../../../)
.PARAMETER Detailed
    Zeigt detaillierte Ergebnisse an
.EXAMPLE
    Test-VaultStructure -VaultPath "C:\SecondBrain"
.EXAMPLE
    Test-VaultStructure -Detailed
#>
function Test-VaultStructure {
    [CmdletBinding()]
    param(
        [string]$VaultPath = (Join-Path $PSScriptRoot "..\..\.."),
        [switch]$Detailed
    )
    
    Write-ECCLog "Starte Vault-Validierung..." -Level "INFO"
    
    $checks = @(
        @{ Name = "00-Meta"; Path = "00-Meta"; Type = "Folder" },
        @{ Name = "01-Daily"; Path = "01-Daily"; Type = "Folder" },
        @{ Name = "02-Projects"; Path = "02-Projects"; Type = "Folder" },
        @{ Name = "03-Knowledge"; Path = "03-Knowledge"; Type = "Folder" },
        @{ Name = "04-Decisions"; Path = "04-Decisions"; Type = "Folder" },
        @{ Name = "99-Archive"; Path = "99-Archive"; Type = "Folder" },
        @{ Name = "Templates"; Path = "00-Meta\Templates"; Type = "Folder" },
        @{ Name = "Scripts"; Path = "00-Meta\Scripts"; Type = "Folder" },
        @{ Name = "MOCs"; Path = "00-Meta\MOCs"; Type = "Folder" },
        @{ Name = "Daily Template"; Path = "00-Meta\Templates\Daily.md"; Type = "File" },
        @{ Name = "Project Template"; Path = "00-Meta\Templates\Project.md"; Type = "File" },
        @{ Name = "MOC Startseite"; Path = "00-Meta\MOCs\_MOC-Startseite.md"; Type = "File" }
    )
    
    $passed = 0
    $failed = 0
    $results = @()
    
    foreach ($check in $checks) {
        $fullPath = Join-Path $VaultPath $check.Path
        $exists = Test-Path $fullPath
        
        $result = @{
            Name = $check.Name
            Path = $check.Path
            Exists = $exists
            Type = $check.Type
        }
        $results += $result
        
        if ($exists) {
            $passed++
            if ($Detailed) {
                Write-ECCLog "  [PASS] $($check.Name)" -Level "DEBUG"
            }
        }
        else {
            $failed++
            Write-ECCLog "  [FAIL] $($check.Name) nicht gefunden: $($check.Path)" -Level "WARN"
        }
    }
    
    # Summary
    $total = $checks.Count
    $percent = [math]::Round(($passed / $total) * 100, 1)
    
    if ($failed -eq 0) {
        Write-ECCLog "Validierung erfolgreich: $passed/$total ($percent%)" -Level "SUCCESS"
    }
    else {
        Write-ECCLog "Validierung unvollständig: $passed/$total ($percent%) - $failed Fehler" -Level "WARN"
    }
    
    return @{
        Success = ($failed -eq 0)
        Passed = $passed
        Failed = $failed
        Total = $total
        Percent = $percent
        Results = $results
    }
}

<#
.SYNOPSIS
    Prüft ob eine Datei migriert werden sollte
.DESCRIPTION
    Validierungs-Logik für Datei-Migrationen
.PARAMETER SourceFile
    Pfad zur Quell-Datei
.PARAMETER TargetFile
    Pfad zur Ziel-Datei
.EXAMPLE
    Test-MigrationCandidate -SourceFile "old.md" -TargetFile "new.md"
#>
function Test-MigrationCandidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceFile,
        
        [Parameter(Mandatory)]
        [string]$TargetFile
    )
    
    if (!(Test-Path $SourceFile)) {
        Write-ECCLog "Quelldatei nicht gefunden: $SourceFile" -Level "ERROR"
        return $false
    }
    
    $sourceInfo = Get-Item $SourceFile
    $sourceSize = $sourceInfo.Length
    $sourceModified = $sourceInfo.LastWriteTime
    
    # Check if target exists
    if (Test-Path $TargetFile) {
        $targetInfo = Get-Item $TargetFile
        $targetSize = $targetInfo.Length
        $targetModified = $targetInfo.LastWriteTime
        
        if ($sourceModified -lt $targetModified) {
            Write-ECCLog "Ziel neuer als Quelle - überspringe: $SourceFile" -Level "DEBUG"
            return $false
        }
        
        if ($sourceSize -eq $targetSize) {
            Write-ECCLog "Datei identisch - überspringe: $SourceFile" -Level "DEBUG"
            return $false
        }
    }
    
    Write-ECCLog "Migration empfohlen: $SourceFile -> $TargetFile" -Level "DEBUG"
    return $true
}

#endregion

#region Error Handling Functions

<#
.SYNOPSIS
    Führt einen Befehl mit Retry-Logik aus
.DESCRIPTION
    Versucht einen Befehl mehrmals bei Fehler
.PARAMETER ScriptBlock
    Der auszuführende Code
.PARAMETER MaxRetries
    Maximale Anzahl Versuche (default: 3)
.PARAMETER DelaySeconds
    Wartezeit zwischen Versuchen (default: 2)
.PARAMETER OperationName
    Name für Logging
.EXAMPLE
    Invoke-WithRetry -ScriptBlock { Copy-Item "a.txt" "b.txt" } -OperationName "Datei kopieren"
#>
function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 2,
        [string]$OperationName = "Operation"
    )
    
    $attempt = 0
    $success = $false
    $lastError = $null
    
    while ($attempt -lt $MaxRetries -and !$success) {
        $attempt++
        
        try {
            Write-ECCLog "$OperationName - Versuch $attempt/$MaxRetries..." -Level "DEBUG"
            $result = & $ScriptBlock
            $success = $true
            Write-ECCLog "$OperationName - Erfolg nach $attempt Versuch(en)" -Level "SUCCESS"
            return $result
        }
        catch {
            $lastError = $_
            Write-ECCLog "$OperationName - Fehler bei Versuch $attempt`: $_" -Level "WARN"
            
            if ($attempt -lt $MaxRetries) {
                Write-ECCLog "Warte $DelaySeconds Sekunden vor erneutem Versuch..." -Level "DEBUG"
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }
    
    if (!$success) {
        Write-ECCLog "$OperationName - Alle $MaxRetries Versuche fehlgeschlagen" -Level "ERROR"
        throw $lastError
    }
}

<#
.SYNOPSIS
    Sichere Datei-Operation mit Backup
.DESCRIPTION
    Führt Datei-Operationen durch und erstellt vorher ein Backup
.PARAMETER Operation
    'Copy', 'Move', oder 'Delete'
.PARAMETER Path
    Pfad zur Datei
.PARAMETER Destination
    Zielpfad (für Copy/Move)
.PARAMETER BackupDir
    Backup-Verzeichnis (default: ../../../.backups/)
.EXAMPLE
    Invoke-SafeFileOperation -Operation "Copy" -Path "file.md" -Destination "backup/file.md"
#>
function Invoke-SafeFileOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Copy", "Move", "Delete")]
        [string]$Operation,
        
        [Parameter(Mandatory)]
        [string]$Path,
        
        [string]$Destination = $null,
        
        [string]$BackupDir = $null
    )
    
    # Default Backup Directory
    if ([string]::IsNullOrEmpty($BackupDir)) {
        $BackupDir = Join-Path $PSScriptRoot "..\..\..\.backups"
    }
    
    if (!(Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    
    # Create backup if file exists
    if (Test-Path $Path) {
        $fileName = Split-Path $Path -Leaf
        $backupName = "{0}_{1}{2}" -f $fileName, (Get-Date -Format 'yyyyMMdd_HHmmss'), '.bak'
        $backupPath = Join-Path $BackupDir $backupName
        
        try {
            Copy-Item $Path $backupPath -Force
            Write-ECCLog "Backup erstellt: $backupPath" -Level "DEBUG"
        }
        catch {
            Write-ECCLog "Backup fehlgeschlagen: $_" -Level "WARN"
        }
    }
    
    # Execute operation
    try {
        switch ($Operation) {
            "Copy" {
                if ([string]::IsNullOrEmpty($Destination)) {
                    throw "Destination required for Copy operation"
                }
                Copy-Item $Path $Destination -Force
                Write-ECCLog "Kopiert: $Path -> $Destination" -Level "SUCCESS"
            }
            "Move" {
                if ([string]::IsNullOrEmpty($Destination)) {
                    throw "Destination required for Move operation"
                }
                Move-Item $Path $Destination -Force
                Write-ECCLog "Verschoben: $Path -> $Destination" -Level "SUCCESS"
            }
            "Delete" {
                Remove-Item $Path -Force
                Write-ECCLog "Gelöscht: $Path" -Level "SUCCESS"
            }
        }
    }
    catch {
        Write-ECCLog "Operation fehlgeschlagen: $_" -Level "ERROR"
        throw
    }
}

#endregion

#region Export

# Export functions when used as module
Export-ModuleMember -Function @(
    'Write-ECCLog',
    'Test-VaultStructure',
    'Test-MigrationCandidate',
    'Invoke-WithRetry',
    'Invoke-SafeFileOperation'
)

#endregion