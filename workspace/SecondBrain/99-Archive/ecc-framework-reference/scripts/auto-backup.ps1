#Requires -Version 7.0
<#
.SYNOPSIS
    Automatisches Backup für ECC Second Brain Vault
.DESCRIPTION
    Erstellt zeitstempelbasierte Backups vor jeder Session
    mit Retention-Management (30 Tage Standard)
.AUTHOR
    ECC Stability Engine
.VERSION
    1.0.0
#>

[CmdletBinding()]
param(
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    [string]$BackupPath = "$VaultPath\.backups",
    [string]$ConfigPath = "$PSScriptRoot\..\config\stability-config.yaml",
    [int]$RetentionDays = 30,
    [switch]$PreSession,
    [switch]$PostSession,
    [string]$SessionId = [Guid]::NewGuid().ToString().Substring(0, 8),
    [switch]$Restore,
    [string]$RestoreTimestamp,
    [switch]$ListBackups,
    [switch]$Silent
)

# ═══════════════════════════════════════════════════════════════
# KONFIGURATION & INITIALISIERUNG
# ═══════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Logging
function Write-BackupLog {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level,
        [Parameter(Mandatory)]
        [string]$Message,
        [string]$Component = "AutoBackup"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    if (-not $Silent) {
        switch ($Level) {
            "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
            "DEBUG"   { Write-Host $logEntry -ForegroundColor Gray }
            "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
            "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        }
    }
    
    # Persistente Logs
    $logDir = Join-Path $VaultPath ".obsidian\logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path (Join-Path $logDir "auto-backup.log") -Value $logEntry
}

# YAML-Parser
function ConvertFrom-Yaml {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) { return @{} }
    
    $content = Get-Content $Path -Raw
    $result = @{}
    $currentSection = $null
    $currentSubSection = $null
    
    foreach ($line in $content -split "`r?`n") {
        $line = $line -replace '#.*$', ''
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        $indent = if ($line -match "^(\s*)") { $matches[1].Length } else { 0 }
        $line = $line.Trim()
        
        if ($line -match "^(\w+):\s*(.*)$") {
            $key = $matches[1]
            $value = $matches[2].Trim()
            
            if ($value -eq "") {
                $result[$key] = @{}
                $currentSection = $key
                $currentSubSection = $null
            } else {
                $result[$key] = $value -replace '^"|"$' -replace "^'|'$"
            }
        }
        elseif ($indent -ge 2 -and $line -match "^(\w+):\s*(.*)$" -and $currentSection) {
            $subKey = $matches[1]
            $subValue = $matches[2].Trim()
            $result[$currentSection][$subKey] = $subValue -replace '^"|"$' -replace "^'|'$"
        }
    }
    
    return $result
}

# ═══════════════════════════════════════════════════════════════
# BACKUP-FUNKTIONEN
# ═══════════════════════════════════════════════════════════════

function Get-BackupConfig {
    param([string]$ConfigPath)
    
    $defaultConfig = @{
        backup_retention_days = 30
        compression_level = "Optimal"
        exclude_patterns = @('.git', '.obsidian/workspace', '.backups', 'reports', '*.tmp')
        max_backup_size_mb = 1024
        parallel_threads = 4
    }
    
    if (Test-Path $ConfigPath) {
        $yaml = ConvertFrom-Yaml -Path $ConfigPath
        if ($yaml['backup']) {
            $backup = $yaml['backup']
            if ($backup['retention_days']) { $defaultConfig.backup_retention_days = [int]$backup['retention_days'] }
            if ($backup['compression']) { $defaultConfig.compression_level = $backup['compression'] }
            if ($backup['max_size_mb']) { $defaultConfig.max_backup_size_mb = [int]$backup['max_size_mb'] }
        }
    }
    
    return $defaultConfig
}

function Get-BackupMetadata {
    param(
        [string]$VaultPath,
        [string]$SessionId
    )
    
    $vaultInfo = Get-Item $VaultPath
    $files = Get-ChildItem -Path $VaultPath -File -Recurse | 
        Where-Object { $_.FullName -notmatch '\.git|\.backups' }
    
    return @{
        version = "1.0.0"
        created = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        session_id = $SessionId
        vault_path = $VaultPath
        vault_name = Split-Path $VaultPath -Leaf
        file_count = $files.Count
        total_size_bytes = ($files | Measure-Object -Property Length -Sum).Sum
        hostname = $env:COMPUTERNAME
        username = $env:USERNAME
        powershell_version = $PSVersionTable.PSVersion.ToString()
        checksum_algorithm = "SHA256"
    }
}

function New-VaultBackup {
    param(
        [string]$VaultPath,
        [string]$BackupPath,
        [hashtable]$Config,
        [string]$SessionId
    )
    
    Write-BackupLog -Level "INFO" -Message "Starte Backup-Prozess..."
    
    # Backup-Verzeichnis erstellen
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = "backup_$($SessionId)_$timestamp"
    $backupDir = Join-Path $BackupPath $backupName
    
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    
    Write-BackupLog -Level "DEBUG" -Message "Backup-Ziel: $backupDir"
    
    # Metadaten sammeln
    $metadata = Get-BackupMetadata -VaultPath $VaultPath -SessionId $SessionId
    $metadataFile = Join-Path $backupDir "backup-metadata.json"
    $metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataFile -Encoding UTF8
    
    # Dateien kopieren mit Fortschritt
    $excludePatterns = $Config['exclude_patterns']
    $files = Get-ChildItem -Path $VaultPath -File -Recurse | Where-Object {
        $file = $_
        $shouldInclude = $true
        foreach ($pattern in $excludePatterns) {
            if ($file.FullName -like "*$pattern*") {
                $shouldInclude = $false
                break
            }
        }
        $shouldInclude
    }
    
    $totalFiles = $files.Count
    $processedFiles = 0
    $copiedBytes = 0
    $startTime = Get-Date
    
    Write-BackupLog -Level "INFO" -Message "Zu sichernde Dateien: $totalFiles"
    
    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($VaultPath.Length).TrimStart('\')
        $targetPath = Join-Path $backupDir $relativePath
        $targetDir = Split-Path $targetPath -Parent
        
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        Copy-Item -Path $file.FullName -Destination $targetPath -Force
        
        # Hash für Integrität
        $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
        $hashFile = "$targetPath.sha256"
        Set-Content -Path $hashFile -Value $hash -Encoding UTF8
        
        $processedFiles++
        $copiedBytes += $file.Length
        
        # Fortschritt alle 100 Dateien
        if ($processedFiles % 100 -eq 0) {
            $percent = [math]::Round(($processedFiles / $totalFiles) * 100, 1)
            $elapsed = (Get-Date) - $startTime
            $speed = if ($elapsed.TotalSeconds -gt 0) { [math]::Round($processedFiles / $elapsed.TotalSeconds, 1) } else { 0 }
            Write-BackupLog -Level "DEBUG" -Message "Fortschritt: $processedFiles/$totalFiles ($percent%) - $speed Dateien/s"
        }
    }
    
    # Komprimierung
    $archivePath = "$backupDir.zip"
    Write-BackupLog -Level "INFO" -Message "Komprimiere Backup..."
    
    $compressionLevel = switch ($Config['compression_level']) {
        "Fastest" { [System.IO.Compression.CompressionLevel]::Fastest }
        "NoCompression" { [System.IO.Compression.CompressionLevel]::NoCompression }
        default { [System.IO.Compression.CompressionLevel]::Optimal }
    }
    
    Compress-Archive -Path "$backupDir\*" -DestinationPath $archivePath -CompressionLevel $compressionLevel -Force
    
    # Cleanup unkomprimiertes Verzeichnis
    Remove-Item -Path $backupDir -Recurse -Force
    
    $archiveSize = (Get-Item $archivePath).Length
    $compressionRatio = if ($metadata.total_size_bytes -gt 0) { 
        [math]::Round((1 - ($archiveSize / $metadata.total_size_bytes)) * 100, 1) 
    } else { 0 }
    
    $duration = (Get-Date) - $startTime
    
    # Finale Metadaten
    $finalMetadata = @{
        metadata = $metadata
        backup_info = @{
            archive_path = $archivePath
            archive_size_bytes = $archiveSize
            compression_ratio_percent = $compressionRatio
            duration_seconds = [math]::Round($duration.TotalSeconds, 2)
            files_processed = $processedFiles
            status = "completed"
        }
    }
    
    $metadataFile = "$archivePath.metadata.json"
    $finalMetadata | ConvertTo-Json -Depth 10 | Set-Content $metadataFile -Encoding UTF8
    
    Write-BackupLog -Level "SUCCESS" -Message "Backup erstellt: $([math]::Round($archiveSize / 1MB, 2)) MB in $([math]::Round($duration.TotalSeconds, 1))s"
    Write-BackupLog -Level "SUCCESS" -Message "Komprimierung: $compressionRatio% kleiner"
    
    return @{
        ArchivePath = $archivePath
        MetadataPath = $metadataFile
        Size = $archiveSize
        Duration = $duration
    }
}

function Invoke-RetentionCleanup {
    param(
        [string]$BackupPath,
        [int]$RetentionDays
    )
    
    Write-BackupLog -Level "INFO" -Message "Prüfe Retention-Policy ($RetentionDays Tage)..."
    
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $backups = Get-ChildItem -Path $BackupPath -Filter "backup_*.zip" -File
    
    $deleted = 0
    $freedSpace = 0
    
    foreach ($backup in $backups) {
        if ($backup.CreationTime -lt $cutoffDate) {
            $metadataFile = "$($backup.FullName).metadata.json"
            
            try {
                Remove-Item $backup.FullName -Force
                if (Test-Path $metadataFile) { Remove-Item $metadataFile -Force }
                
                $deleted++
                $freedSpace += $backup.Length
                Write-BackupLog -Level "DEBUG" -Message "Altes Backup gelöscht: $($backup.Name)"
            }
            catch {
                Write-BackupLog -Level "WARN" -Message "Konnte Backup nicht löschen: $($backup.Name)"
            }
        }
    }
    
    if ($deleted -gt 0) {
        Write-BackupLog -Level "SUCCESS" -Message "$deleted alte Backups gelöscht, $([math]::Round($freedSpace / 1MB, 2)) MB freigegeben"
    } else {
        Write-BackupLog -Level "INFO" -Message "Keine alten Backups zum Löschen gefunden"
    }
}

function Restore-VaultBackup {
    param(
        [string]$BackupPath,
        [string]$RestoreTimestamp,
        [string]$TargetPath
    )
    
    Write-BackupLog -Level "INFO" -Message "Starte Restore-Prozess..."
    
    # Backup finden
    $backupPattern = if ($RestoreTimestamp) { "*_$RestoreTimestamp*.zip" } else { "backup_*.zip" }
    $backups = Get-ChildItem -Path $BackupPath -Filter $backupPattern | Sort-Object CreationTime -Descending
    
    if ($backups.Count -eq 0) {
        throw "Kein Backup gefunden mit Pattern: $backupPattern"
    }
    
    $selectedBackup = $backups[0]
    Write-BackupLog -Level "INFO" -Message "Verwende Backup: $($selectedBackup.Name)"
    
    # Metadaten prüfen
    $metadataFile = "$($selectedBackup.FullName).metadata.json"
    if (Test-Path $metadataFile) {
        $metadata = Get-Content $metadataFile | ConvertFrom-Json
        Write-BackupLog -Level "INFO" -Message "Backup vom $($metadata.metadata.created), $($metadata.backup_info.files_processed) Dateien"
    }
    
    # Extrahieren
    $extractPath = Join-Path $env:TEMP "ecc_restore_$(Get-Random)"
    Expand-Archive -Path $selectedBackup.FullName -DestinationPath $extractPath -Force
    
    Write-BackupLog -Level "INFO" -Message "Backup extrahiert nach: $extractPath"
    
    # Ziel-Verzeichnis vorbereiten
    if (-not $TargetPath) {
        $TargetPath = Read-Host "Ziel-Verzeichnis eingeben (Enter für Original-Pfad)"
        if ([string]::IsNullOrWhiteSpace($TargetPath)) {
            $TargetPath = $metadata.metadata.vault_path
        }
    }
    
    Write-BackupLog -Level "WARN" -Message "ACHTUNG: Dies überschreibt Dateien in: $TargetPath"
    $confirm = Read-Host "Fortfahren? (ja/NEIN)"
    
    if ($confirm -ne "ja") {
        Remove-Item $extractPath -Recurse -Force
        Write-BackupLog -Level "INFO" -Message "Restore abgebrochen"
        return
    }
    
    # Dateien kopieren
    $extractedFiles = Get-ChildItem -Path $extractPath -File -Recurse | Where-Object { $_.Extension -ne '.sha256' }
    $restored = 0
    
    foreach ($file in $extractedFiles) {
        $relativePath = $file.FullName.Substring($extractPath.Length).TrimStart('\')
        $targetFile = Join-Path $TargetPath $relativePath
        $targetDir = Split-Path $targetFile -Parent
        
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        Copy-Item -Path $file.FullName -Destination $targetFile -Force
        $restored++
    }
    
    # Cleanup
    Remove-Item $extractPath -Recurse -Force
    
    Write-BackupLog -Level "SUCCESS" -Message "$restored Dateien wiederhergestellt nach: $TargetPath"
}

function Get-BackupList {
    param([string]$BackupPath)
    
    $backups = Get-ChildItem -Path $BackupPath -Filter "backup_*.zip" -File | Sort-Object CreationTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-Host "Keine Backups gefunden in: $BackupPath" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n=== Verfügbare Backups ===" -ForegroundColor Cyan
    Write-Host ""
    
    $index = 1
    foreach ($backup in $backups) {
        $metadataFile = "$($backup.FullName).metadata.json"
        $size = [math]::Round($backup.Length / 1MB, 2)
        
        $info = "$index. $($backup.Name)"
        $info += "`n   Erstellt: $($backup.CreationTime)"
        $info += "`n   Größe: $size MB"
        
        if (Test-Path $metadataFile) {
            $metadata = Get-Content $metadataFile | ConvertFrom-Json
            $info += "`n   Dateien: $($metadata.backup_info.files_processed)"
            $info += "`n   Session: $($metadata.metadata.session_id)"
            $info += "`n   Dauer: $($metadata.backup_info.duration_seconds)s"
        }
        
        Write-Host $info -ForegroundColor White
        Write-Host ""
        $index++
    }
}

# ═══════════════════════════════════════════════════════════════
# HAUPTLOGIK
# ═══════════════════════════════════════════════════════════════

Write-BackupLog -Level "INFO" -Message "=== ECC Auto Backup gestartet ==="
Write-BackupLog -Level "INFO" -Message "Session ID: $SessionId"

# Konfiguration laden
$config = Get-BackupConfig -ConfigPath $ConfigPath
Write-BackupLog -Level "DEBUG" -Message "Retention: $($config['backup_retention_days']) Tage"

# Backup-Verzeichnis sicherstellen
if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    Write-BackupLog -Level "SUCCESS" -Message "Backup-Verzeichnis erstellt: $BackupPath"
}

# Modus-Auswahl
if ($ListBackups) {
    Get-BackupList -BackupPath $BackupPath
    exit 0
}

if ($Restore) {
    Restore-VaultBackup -BackupPath $BackupPath -RestoreTimestamp $RestoreTimestamp
    exit 0
}

# Backup erstellen
$backupResult = New-VaultBackup -VaultPath $VaultPath -BackupPath $BackupPath -Config $config -SessionId $SessionId

# Retention Cleanup
Invoke-RetentionCleanup -BackupPath $BackupPath -RetentionDays $config['backup_retention_days']

# Session-Marker für Pre-Session Backup
if ($PreSession) {
    $markerFile = Join-Path $BackupPath ".presession_$SessionId"
    @{
        session_id = $SessionId
        backup_path = $backupResult.ArchivePath
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    } | ConvertTo-Json | Set-Content $markerFile
    Write-BackupLog -Level "INFO" -Message "Pre-Session Marker gesetzt"
}

Write-BackupLog -Level "SUCCESS" -Message "=== Backup-Prozess abgeschlossen ==="

# Ergebnis zurückgeben
return @{
    Success = $true
    ArchivePath = $backupResult.ArchivePath
    SizeMB = [math]::Round($backupResult.Size / 1MB, 2)
    DurationSeconds = [math]::Round($backupResult.Duration.TotalSeconds, 1)
    SessionId = $SessionId
}
