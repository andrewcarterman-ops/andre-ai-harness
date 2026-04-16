<#
.SYNOPSIS
    Startet den Mini-Evolve-Loop fuer semantic-memory-poc.py.
.DESCRIPTION
    PowerShell-Wrapper um evolve.py. Setzt Environment-Variablen,
    prueft Abhaengigkeiten und startet den Evolution-Loop.
#>

[CmdletBinding()]
param(
    [string]$ConfigPath = "config.yaml",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Mini-Evolve-Loop Launcher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Pruefe Python
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Error "Python wurde nicht gefunden. Bitte installiere Python 3.10+."
    exit 1
}
Write-Host "Python gefunden: $($python.Source)" -ForegroundColor Green

# 2. Pruefe Abhaengigkeiten
$requiredModules = @("openai", "yaml", "faiss", "sentence_transformers")
foreach ($mod in $requiredModules) {
    $result = python -c "import $mod" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Modul '$mod' nicht gefunden. Versuche Installation..."
        python -m pip install pyyaml openai faiss-cpu sentence-transformers
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Installation von '$mod' fehlgeschlagen."
            exit 1
        }
    }
}
Write-Host "Alle Abhaengigkeiten OK." -ForegroundColor Green

# 3. Pruefe API-Key
if (-not $env:KIMI_API_KEY) {
    Write-Warning "Umgebungsvariable KIMI_API_KEY ist nicht gesetzt!"
    Write-Host "Bitte setze den Key vor dem Start:" -ForegroundColor Yellow
    Write-Host '  $env:KIMI_API_KEY = "dein-api-key"' -ForegroundColor Yellow
    Write-Host "Oder fuege ihn permanent zur Umgebung hinzu."
    exit 1
}
Write-Host "KIMI_API_KEY ist gesetzt." -ForegroundColor Green

# 4. Pfade aufloesen
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

# 5. Config validieren
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config-Datei nicht gefunden: $ConfigPath"
    exit 1
}
Write-Host "Config: $ConfigPath" -ForegroundColor Green

# 6. Starte Evolve-Loop
if ($DryRun) {
    Write-Host "`n[DRY-RUN] Evolution-Loop wuerde jetzt starten." -ForegroundColor Magenta
    Write-Host "Rufe auf: python evolve.py" -ForegroundColor Magenta
} else {
    Write-Host "`nStarte Evolution-Loop..." -ForegroundColor Cyan
    python evolve.py
}

Write-Host "`nDone." -ForegroundColor Green
