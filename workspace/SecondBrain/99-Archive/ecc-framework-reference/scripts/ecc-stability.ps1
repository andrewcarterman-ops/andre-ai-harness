#Requires -Version 7.0
<#
.SYNOPSIS
    ECC Stability Orchestrator - Hauptsteuerung für alle Stabilitätsmechanismen
.DESCRIPTION
    Zentrale Steuerung für:
    - Drift Detection
    - Auto-Backup
    - Context Switch Management
    - Verschlüsselte API-Key-Verwaltung
.AUTHOR
    ECC Stability Engine
.VERSION
    1.0.0
#>

[CmdletBinding()]
param(
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    [string]$ConfigPath = "$PSScriptRoot\..\config\stability-config.yaml",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("full", "drift", "backup", "context", "encrypt", "status", "init", "help")]
    [string]$Mode = "status",
    
    [switch]$AutoFix,
    [switch]$Silent,
    [switch]$PreSession,
    [switch]$PostSession,
    [string]$SessionId = [Guid]::NewGuid().ToString().Substring(0, 8),
    [string]$ServiceName,
    [SecureString]$ApiKey
)

# ═══════════════════════════════════════════════════════════════
# INITIALISIERUNG
# ═══════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"
$script:Version = "1.0.0"
$script:StartTime = Get-Date

# Logging
function Write-EccLog {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG", "HEADER")]
        [string]$Level,
        [Parameter(Mandatory)]
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if (-not $Silent) {
        switch ($Level) {
            "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
            "DEBUG"   { Write-Host $logEntry -ForegroundColor Gray }
            "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
            "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
            "HEADER"  { Write-Host "`n$Message" -ForegroundColor Magenta }
        }
    }
    
    $logDir = Join-Path $VaultPath ".obsidian\logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path (Join-Path $logDir "ecc-stability.log") -Value $logEntry
}

# ═══════════════════════════════════════════════════════════════
# HILFSFUNKTIONEN
# ═══════════════════════════════════════════════════════════════

function Test-Prerequisites {
    Write-EccLog -Level "INFO" -Message "Prüfe Voraussetzungen..."
    
    $prereqs = @{
        PowerShell7 = $PSVersionTable.PSVersion.Major -ge 7
        VaultPath = Test-Path $VaultPath
        ConfigPath = Test-Path $ConfigPath
        ScriptsPath = Test-Path "$PSScriptRoot\drift-detection.ps1"
    }
    
    $allOk = $true
    foreach ($prereq in $prereqs.GetEnumerator()) {
        $status = if ($prereq.Value) { "✓" } else { "✗" }
        $color = if ($prereq.Value) { "Green" } else { "Red" }
        if (-not $Silent) {
            Write-Host "  $($prereq.Key): " -NoNewline
            Write-Host $status -ForegroundColor $color
        }
        if (-not $prereq.Value) { $allOk = $false }
    }
    
    return $allOk
}

function Show-Help {
    $help = @"
╔══════════════════════════════════════════════════════════════════╗
║           ECC Stability Orchestrator v$script:Version              ║
╚══════════════════════════════════════════════════════════════════╝

VERWENDUNG:
    .\ecc-stability.ps1 -Mode <Modus> [Optionen]

MODI:
    full      - Führt alle Stabilitätschecks aus
    drift     - Drift Detection für Vault-Struktur
    backup    - Automatisches Backup erstellen
    context   - Token-Usage Monitoring
    encrypt   - API-Key Verschlüsselung
    status    - Status anzeigen (Standard)
    init      - Initialisierung der ECC-Umgebung
    help      - Diese Hilfe anzeigen

OPTIONEN:
    -VaultPath <Pfad>     - Pfad zur Vault (Standard: SecondBrain)
    -AutoFix               - Automatische Korrektur aktivieren
    -Silent                - Keine Konsolenausgabe
    -PreSession            - Pre-Session Backup
    -PostSession           - Post-Session Backup
    -SessionId <ID>        - Session-ID festlegen
    -ServiceName <Name>    - Dienstname für API-Key
    -ApiKey <SecureString> - Zu verschlüsselnder API-Key

BEISPIELE:
    # Vollständiger Check
    .\ecc-stability.ps1 -Mode full -AutoFix

    # Nur Drift Detection
    .\ecc-stability.ps1 -Mode drift

    # Backup vor Session
    .\ecc-stability.ps1 -Mode backup -PreSession

    # API-Key verschlüsseln
    .\ecc-stability.ps1 -Mode encrypt -ServiceName "openai" -ApiKey (Read-Host -AsSecureString)

    # Status anzeigen
    .\ecc-stability.ps1 -Mode status
"@
    Write-Host $help -ForegroundColor White
}

function Show-Status {
    Write-EccLog -Level "HEADER" -Message "=== ECC Stability Status ==="
    
    # Vault-Info
    Write-EccLog -Level "INFO" -Message "Vault: $VaultPath"
    
    if (Test-Path $VaultPath) {
        $vaultInfo = Get-Item $VaultPath
        $files = Get-ChildItem -Path $VaultPath -File -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.FullName -notmatch '\.git|\.backups' }
        $dirs = Get-ChildItem -Path $VaultPath -Directory -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.FullName -notmatch '\.git|\.backups' }
        
        Write-EccLog -Level "INFO" -Message "  Verzeichnisse: $($dirs.Count)"
        Write-EccLog -Level "INFO" -Message "  Dateien: $($files.Count)"
        Write-EccLog -Level "INFO" -Message "  Größe: $([math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB"
    }
    
    # Backups
    $backupPath = Join-Path $VaultPath ".backups"
    if (Test-Path $backupPath) {
        $backups = Get-ChildItem -Path $backupPath -Filter "backup_*.zip" -ErrorAction SilentlyContinue
        Write-EccLog -Level "INFO" -Message "Backups: $($backups.Count) verfügbar"
    }
    
    # Checkpoints
    $checkpointPath = Join-Path $VaultPath ".obsidian\checkpoints"
    if (Test-Path $checkpointPath) {
        $checkpoints = Get-ChildItem -Path $checkpointPath -Directory -ErrorAction SilentlyContinue
        Write-EccLog -Level "INFO" -Message "Checkpoints: $($checkpoints.Count) verfügbar"
    }
    
    # API-Keys
    $keysPath = Join-Path $VaultPath ".obsidian\plugins\ecc-vault\secure-keys.json"
    if (Test-Path $keysPath) {
        $keys = Get-Content $keysPath | ConvertFrom-Json -ErrorAction SilentlyContinue
        $keyCount = ($keys.PSObject.Properties | Where-Object { -not $_.Name.StartsWith('_') }).Count
        Write-EccLog -Level "INFO" -Message "API-Keys: $keyCount gespeichert"
    }
    
    # Logs
    $logPath = Join-Path $VaultPath ".obsidian\logs"
    if (Test-Path $logPath) {
        $logs = Get-ChildItem -Path $logPath -Filter "*.log" -ErrorAction SilentlyContinue
        Write-EccLog -Level "INFO" -Message "Log-Dateien: $($logs.Count)"
    }
}

# ═══════════════════════════════════════════════════════════════
# MODUS-FUNKTIONEN
# ═══════════════════════════════════════════════════════════════

function Invoke-FullCheck {
    Write-EccLog -Level "HEADER" -Message "=== Vollständiger Stabilitätscheck ==="
    
    $results = @{
        Drift = $null
        Backup = $null
        Context = $null
        Success = $true
    }
    
    # 1. Drift Detection
    try {
        Write-EccLog -Level "INFO" -Message "[1/3] Führe Drift Detection durch..."
        $driftScript = "$PSScriptRoot\drift-detection.ps1"
        $driftArgs = @{
            VaultPath = $VaultPath
            Silent = $Silent
        }
        if ($AutoFix) { $driftArgs['AutoFix'] = $true }
        
        & $driftScript @driftArgs
        $results.Drift = $LASTEXITCODE -eq 0
        Write-EccLog -Level "SUCCESS" -Message "Drift Detection abgeschlossen"
    }
    catch {
        Write-EccLog -Level "ERROR" -Message "Drift Detection fehlgeschlagen: $_"
        $results.Drift = $false
        $results.Success = $false
    }
    
    # 2. Backup
    try {
        Write-EccLog -Level "INFO" -Message "[2/3] Erstelle Backup..."
        $backupScript = "$PSScriptRoot\auto-backup.ps1"
        & $backupScript -VaultPath $VaultPath -SessionId $SessionId -Silent:$Silent
        $results.Backup = $true
        Write-EccLog -Level "SUCCESS" -Message "Backup erstellt"
    }
    catch {
        Write-EccLog -Level "ERROR" -Message "Backup fehlgeschlagen: $_"
        $results.Backup = $false
        $results.Success = $false
    }
    
    # 3. Context Status
    try {
        Write-EccLog -Level "INFO" -Message "[3/3] Prüfe Context-Status..."
        $contextScript = "$PSScriptRoot\context-switch.ps1"
        & $contextScript -VaultPath $VaultPath -Status -Silent:$Silent
        $results.Context = $true
    }
    catch {
        Write-EccLog -Level "ERROR" -Message "Context-Check fehlgeschlagen: $_"
        $results.Context = $false
    }
    
    # Zusammenfassung
    Write-EccLog -Level "HEADER" -Message "=== Zusammenfassung ==="
    Write-EccLog -Level "INFO" -Message "Drift: $(if ($results.Drift) { 'OK ✓' } else { 'WARN ✗' })"
    Write-EccLog -Level "INFO" -Message "Backup: $(if ($results.Backup) { 'OK ✓' } else { 'WARN ✗' })"
    Write-EccLog -Level "INFO" -Message "Context: $(if ($results.Context) { 'OK ✓' } else { 'WARN ✗' })"
    
    return $results
}

function Invoke-DriftMode {
    $driftScript = "$PSScriptRoot\drift-detection.ps1"
    $args = @{
        VaultPath = $VaultPath
        Silent = $Silent
    }
    if ($AutoFix) { $args['AutoFix'] = $true }
    
    & $driftScript @args
}

function Invoke-BackupMode {
    $backupScript = "$PSScriptRoot\auto-backup.ps1"
    $args = @{
        VaultPath = $VaultPath
        SessionId = $SessionId
        Silent = $Silent
    }
    if ($PreSession) { $args['PreSession'] = $true }
    if ($PostSession) { $args['PostSession'] = $true }
    
    & $backupScript @args
}

function Invoke-ContextMode {
    $contextScript = "$PSScriptRoot\context-switch.ps1"
    & $contextScript -VaultPath $VaultPath -Monitor -SessionId $SessionId -Silent:$Silent
}

function Invoke-EncryptMode {
    if (-not $ServiceName) {
        $ServiceName = Read-Host "Dienstname eingeben (z.B. openai, anthropic)"
    }
    
    if (-not $ApiKey) {
        $ApiKey = Read-Host "API-Key eingeben" -AsSecureString
    }
    
    # Encryption-Modul laden
    $encryptionModule = "$PSScriptRoot\lib\Encryption.psm1"
    if (-not (Test-Path $encryptionModule)) {
        throw "Encryption-Modul nicht gefunden: $encryptionModule"
    }
    
    Import-Module $encryptionModule -Force
    
    # Prüfe/Master-Key erstellen
    $masterKeyPath = Join-Path $VaultPath ".obsidian\plugins\ecc-vault\.master.key"
    if (-not (Test-Path $masterKeyPath)) {
        Write-EccLog -Level "INFO" -Message "Erstelle neuen Master-Key..."
        New-EncryptionKey -VaultPath $VaultPath -Force
    }
    
    # API-Key verschlüsseln
    $result = Protect-ApiKey -ApiKey $ApiKey -ServiceName $ServiceName -VaultPath $VaultPath
    
    Write-EccLog -Level "SUCCESS" -Message "API-Key für '$ServiceName' verschlüsselt"
    return $result
}

function Initialize-EccEnvironment {
    Write-EccLog -Level "HEADER" -Message "=== ECC Environment Initialisierung ==="
    
    # Verzeichnisstruktur erstellen
    $directories = @(
        ".obsidian",
        ".obsidian\snippets",
        ".obsidian\plugins",
        ".obsidian\plugins\ecc-vault",
        ".obsidian\themes",
        ".obsidian\context",
        ".obsidian\checkpoints",
        ".obsidian\logs",
        ".backups",
        "reports\drift"
    )
    
    foreach ($dir in $directories) {
        $fullPath = Join-Path $VaultPath $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-EccLog -Level "INFO" -Message "Verzeichnis erstellt: $dir"
        }
    }
    
    # Konfigurationsdateien kopieren
    $configSource = "$PSScriptRoot\..\config"
    $configTarget = Join-Path $VaultPath ".obsidian\ecc-config"
    
    if (-not (Test-Path $configTarget)) {
        New-Item -ItemType Directory -Path $configTarget -Force | Out-Null
    }
    
    $configFiles = @("stability-config.yaml", "drift-config.yaml", "vault-manifest.yaml")
    foreach ($file in $configFiles) {
        $source = Join-Path $configSource $file
        $target = Join-Path $configTarget $file
        if ((Test-Path $source) -and -not (Test-Path $target)) {
            Copy-Item $source $target -Force
            Write-EccLog -Level "INFO" -Message "Konfiguration kopiert: $file"
        }
    }
    
    # secure-keys.json Template kopieren
    $keysSource = "$PSScriptRoot\..\.obsidian\plugins\ecc-vault\secure-keys.json"
    $keysTarget = Join-Path $VaultPath ".obsidian\plugins\ecc-vault\secure-keys.json"
    if ((Test-Path $keysSource) -and -not (Test-Path $keysTarget)) {
        Copy-Item $keysSource $keysTarget -Force
        Write-EccLog -Level "INFO" -Message "secure-keys.json Template kopiert"
    }
    
    # Master-Key erstellen
    $encryptionModule = "$PSScriptRoot\lib\Encryption.psm1"
    if (Test-Path $encryptionModule) {
        Import-Module $encryptionModule -Force
        $masterKeyPath = Join-Path $VaultPath ".obsidian\plugins\ecc-vault\.master.key"
        if (-not (Test-Path $masterKeyPath)) {
            New-EncryptionKey -VaultPath $VaultPath
        }
    }
    
    Write-EccLog -Level "SUCCESS" -Message "ECC Environment initialisiert"
}

# ═══════════════════════════════════════════════════════════════
# HAUPTLOGIK
# ═══════════════════════════════════════════════════════════════

Write-EccLog -Level "INFO" -Message "=== ECC Stability Orchestrator v$script:Version ==="
Write-EccLog -Level "INFO" -Message "Session ID: $SessionId"

# Modus-Verarbeitung
switch ($Mode) {
    "help" {
        Show-Help
        exit 0
    }
    
    "status" {
        Show-Status
        exit 0
    }
    
    "init" {
        Initialize-EccEnvironment
        exit 0
    }
    
    "full" {
        if (-not (Test-Prerequisites)) {
            Write-EccLog -Level "ERROR" -Message "Voraussetzungen nicht erfüllt"
            exit 1
        }
        $result = Invoke-FullCheck
        exit ($result.Success ? 0 : 1)
    }
    
    "drift" {
        Invoke-DriftMode
        exit $LASTEXITCODE
    }
    
    "backup" {
        Invoke-BackupMode
        exit 0
    }
    
    "context" {
        Invoke-ContextMode
        exit 0
    }
    
    "encrypt" {
        Invoke-EncryptMode
        exit 0
    }
    
    default {
        Show-Help
        exit 1
    }
}
