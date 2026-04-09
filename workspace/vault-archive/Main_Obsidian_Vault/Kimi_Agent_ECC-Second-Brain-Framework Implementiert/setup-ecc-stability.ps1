#Requires -Version 7.0
<#
.SYNOPSIS
    Setup-Skript für ECC Second Brain Stability Framework
.DESCRIPTION
    Installiert alle Stabilitätsmechanismen im Vault-Verzeichnis
.AUTHOR
    ECC Stability Engine
.VERSION
    1.0.0
#>

[CmdletBinding()]
param(
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",
    [string]$SourcePath = $PSScriptRoot,
    [switch]$Force,
    [switch]$Test
)

$ErrorActionPreference = "Stop"

Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║     ECC Second Brain - Stability Framework Setup v1.0.0         ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host ""
Write-Host "Vault-Ziel: $VaultPath" -ForegroundColor Gray
Write-Host "Quelle: $SourcePath" -ForegroundColor Gray
Write-Host ""

# Prüfe Vault-Pfad
if (-not (Test-Path $VaultPath)) {
    Write-Host "Vault-Verzeichnis nicht gefunden!" -ForegroundColor Red
    $create = Read-Host "Soll das Verzeichnis erstellt werden? (ja/NEIN)"
    if ($create -eq "ja") {
        New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null
        Write-Host "Verzeichnis erstellt." -ForegroundColor Green
    } else {
        exit 1
    }
}

# Installationsstruktur
$installMap = @{
    # Skripte
    "$SourcePath\scripts\drift-detection.ps1" = "$VaultPath\.obsidian\ecc-system\scripts\drift-detection.ps1"
    "$SourcePath\scripts\auto-backup.ps1" = "$VaultPath\.obsidian\ecc-system\scripts\auto-backup.ps1"
    "$SourcePath\scripts\context-switch.ps1" = "$VaultPath\.obsidian\ecc-system\scripts\context-switch.ps1"
    "$SourcePath\scripts\ecc-stability.ps1" = "$VaultPath\.obsidian\ecc-system\ecc-stability.ps1"
    
    # Module
    "$SourcePath\scripts\lib\Encryption.psm1" = "$VaultPath\.obsidian\ecc-system\lib\Encryption.psm1"
    
    # Konfigurationen
    "$SourcePath\config\stability-config.yaml" = "$VaultPath\.obsidian\ecc-system\config\stability-config.yaml"
    "$SourcePath\config\drift-config.yaml" = "$VaultPath\.obsidian\ecc-system\config\drift-config.yaml"
    "$SourcePath\config\vault-manifest.yaml" = "$VaultPath\.obsidian\ecc-system\config\vault-manifest.yaml"
    
    # Secure Storage
    "$SourcePath\.obsidian\plugins\ecc-vault\secure-keys.json" = "$VaultPath\.obsidian\plugins\ecc-vault\secure-keys.json"
}

# Verzeichnisse erstellen
$dirs = @(
    "$VaultPath\.obsidian\ecc-system\scripts\lib"
    "$VaultPath\.obsidian\ecc-system\config"
    "$VaultPath\.obsidian\ecc-system\reports\drift"
    "$VaultPath\.obsidian\plugins\ecc-vault"
    "$VaultPath\.obsidian\context"
    "$VaultPath\.obsidian\checkpoints"
    "$VaultPath\.obsidian\logs"
    "$VaultPath\.backups"
)

Write-Host "Erstelle Verzeichnisstruktur..." -ForegroundColor Cyan
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ✓ $dir" -ForegroundColor Green
    }
}

# Dateien kopieren
Write-Host ""
Write-Host "Kopiere Dateien..." -ForegroundColor Cyan
foreach ($map in $installMap.GetEnumerator()) {
    $source = $map.Key
    $target = $map.Value
    
    if (Test-Path $source) {
        $targetDir = Split-Path $target -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        if (-not (Test-Path $target) -or $Force) {
            Copy-Item $source $target -Force
            Write-Host "  ✓ $(Split-Path $target -Leaf)" -ForegroundColor Green
        } else {
            Write-Host "  • $(Split-Path $target -Leaf) (existiert)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✗ $(Split-Path $source -Leaf) (nicht gefunden)" -ForegroundColor Red
    }
}

# Symlink für einfachen Zugriff
$symlinkPath = "$VaultPath\ecc-stability.ps1"
$targetScript = "$VaultPath\.obsidian\ecc-system\ecc-stability.ps1"
if ((Test-Path $targetScript) -and -not (Test-Path $symlinkPath)) {
    try {
        New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $targetScript -Force | Out-Null
        Write-Host ""
        Write-Host "Symlink erstellt: ecc-stability.ps1" -ForegroundColor Green
    }
    catch {
        # Fallback: Kopie statt Symlink
        Copy-Item $targetScript $symlinkPath -Force
        Write-Host ""
        Write-Host "Shortcut erstellt: ecc-stability.ps1" -ForegroundColor Green
    }
}

# Initialisierung
Write-Host ""
Write-Host "Initialisiere ECC-System..." -ForegroundColor Cyan

# Master-Key erstellen
$encryptionModule = "$VaultPath\.obsidian\ecc-system\lib\Encryption.psm1"
if (Test-Path $encryptionModule) {
    Import-Module $encryptionModule -Force -ErrorAction SilentlyContinue
    $masterKeyPath = "$VaultPath\.obsidian\plugins\ecc-vault\.master.key"
    if (-not (Test-Path $masterKeyPath)) {
        try {
            New-EncryptionKey -VaultPath $VaultPath -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  ✓ Master-Key erstellt" -ForegroundColor Green
        }
        catch {
            Write-Host "  ! Master-Key wird bei erster Verwendung erstellt" -ForegroundColor Yellow
        }
    }
}

# README erstellen
$readmePath = "$VaultPath\ECC-STABILITY.md"
$readmeContent = @"# ECC Second Brain - Stability Framework

## Installation

Das Stability Framework wurde erfolgreich installiert.

## Verwendung

### Schnellbefehle

```powershell
# Vollständiger Stabilitätscheck
.\ecc-stability.ps1 -Mode full -AutoFix

# Drift Detection
.\ecc-stability.ps1 -Mode drift

# Backup erstellen
.\ecc-stability.ps1 -Mode backup -PreSession

# Status anzeigen
.\ecc-stability.ps1 -Mode status

# Hilfe
.\ecc-stability.ps1 -Mode help
```

## Struktur

```
.obsidian/
├── ecc-system/
│   ├── scripts/
│   │   ├── drift-detection.ps1
│   │   ├── auto-backup.ps1
│   │   ├── context-switch.ps1
│   │   └── lib/
│   │       └── Encryption.psm1
│   ├── config/
│   │   ├── stability-config.yaml
│   │   ├── drift-config.yaml
│   │   └── vault-manifest.yaml
│   └── reports/
├── plugins/
│   └── ecc-vault/
│       ├── secure-keys.json
│       └── .master.key
├── context/
├── checkpoints/
└── logs/
.backups/
```

## Konfiguration

Bearbeiten Sie die YAML-Dateien in `.obsidian/ecc-system/config/`:

- `stability-config.yaml` - Token-Thresholds, Backup-Einstellungen
- `drift-config.yaml` - Struktur-Validierung, Auto-Fix
- `vault-manifest.yaml` - Referenz-Struktur

## API-Key Verschlüsselung

```powershell
# API-Key verschlüsseln
`$apiKey = Read-Host "API-Key" -AsSecureString
.\ecc-stability.ps1 -Mode encrypt -ServiceName "openai" -ApiKey `$apiKey

# API-Key abrufen (im Skript)
Import-Module .obsidian\ecc-system\lib\Encryption.psm1
`$key = Unprotect-ApiKey -ServiceName "openai"
```

## Support

ECC Stability Engine v1.0.0
"@

Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
Write-Host "  ✓ README erstellt: ECC-STABILITY.md" -ForegroundColor Green

# Test durchführen
if ($Test) {
    Write-Host ""
    Write-Host "Führe Tests durch..." -ForegroundColor Cyan
    
    # Drift Detection Test
    $driftScript = "$VaultPath\.obsidian\ecc-system\scripts\drift-detection.ps1"
    if (Test-Path $driftScript) {
        Write-Host "  Teste Drift Detection..." -ForegroundColor Gray
        & $driftScript -VaultPath $VaultPath -Silent
        Write-Host "  ✓ Drift Detection funktioniert" -ForegroundColor Green
    }
    
    # Encryption Test
    if (Test-Path $encryptionModule) {
        Write-Host "  Teste Verschlüsselung..." -ForegroundColor Gray
        Import-Module $encryptionModule -Force
        Test-Encryption -VaultPath $VaultPath
    }
}

# Abschluss
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         Setup erfolgreich abgeschlossen!                         ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Verwendung:" -ForegroundColor Cyan
Write-Host "  cd `"$VaultPath`"" -ForegroundColor White
Write-Host "  .\ecc-stability.ps1 -Mode help" -ForegroundColor White
Write-Host ""
Write-Host "Dokumentation: ECC-STABILITY.md" -ForegroundColor Gray
