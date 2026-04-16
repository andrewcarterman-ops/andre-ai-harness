# OpenClaw Voice Bridge - Installationsskript
# Führt alle Installationsschritte automatisch aus

param(
    [string]$InstallDir = "C:\openclaw-voice"
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  OpenClaw Voice Bridge - Installation" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Prüfe Admin-Rechte
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Dieses Skript sollte als Administrator ausgeführt werden!"
    Write-Host "Starte neu mit Admin-Rechten..."
    Start-Process powershell -Verb runAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

# Erstelle Installationsverzeichnis
Write-Host "📁 Erstelle Verzeichnis: $InstallDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Set-Location $InstallDir

# Prüfe Python
Write-Host "🐍 Prüfe Python..." -ForegroundColor Yellow
$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Python nicht gefunden! Bitte installiere Python 3.10+ von python.org"
    exit 1
}
Write-Host "   Gefunden: $pythonVersion" -ForegroundColor Green

# Virtuelle Umgebung
Write-Host "🌐 Erstelle virtuelle Umgebung..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Remove-Item -Recurse -Force "venv"
}
python -m venv venv

# Aktiviere Umgebung
Write-Host "⚡ Aktiviere Umgebung..." -ForegroundColor Yellow
& .\venv\Scripts\Activate.ps1

# Installiere Abhängigkeiten
Write-Host "📦 Installiere Python-Pakete..." -ForegroundColor Yellow
pip install --upgrade pip
pip install pyaudio keyboard numpy requests

# Erstelle Ordnerstruktur
Write-Host "📂 Erstelle Ordnerstruktur..." -ForegroundColor Yellow
@("whisper", "llama", "piper", "models") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path $_ | Out-Null
}

# Lade Binaries herunter
Write-Host "⬇️  Lade Whisper.cpp..." -ForegroundColor Yellow
$whisperUrl = "https://github.com/ggerganov/whisper.cpp/releases/download/v1.6.2/whisper-bin-x64.zip"
Invoke-WebRequest -Uri $whisperUrl -OutFile "whisper-temp.zip" -UseBasicParsing
Expand-Archive -Path "whisper-temp.zip" -DestinationPath "whisper-temp" -Force
Copy-Item "whisper-temp\main.exe" "whisper\" -Force
Remove-Item -Recurse -Force "whisper-temp"
Remove-Item "whisper-temp.zip"

Write-Host "⬇️  Lade llama.cpp..." -ForegroundColor Yellow
$llamaUrl = "https://github.com/ggerganov/llama.cpp/releases/download/b3571/llama-b3571-bin-win-avx2-x64.zip"
Invoke-WebRequest -Uri $llamaUrl -OutFile "llama-temp.zip" -UseBasicParsing
Expand-Archive -Path "llama-temp.zip" -DestinationPath "llama-temp" -Force
Copy-Item "llama-temp\llama-server.exe" "llama\" -Force
Remove-Item -Recurse -Force "llama-temp"
Remove-Item "llama-temp.zip"

Write-Host "⬇️  Lade Piper TTS..." -ForegroundColor Yellow
$piperUrl = "https://github.com/rhasspy/piper/releases/download/v1.2.0/piper_windows_amd64.zip"
Invoke-WebRequest -Uri $piperUrl -OutFile "piper-temp.zip" -UseBasicParsing
Expand-Archive -Path "piper-temp.zip" -DestinationPath "piper" -Force
Remove-Item "piper-temp.zip"

# Lade Modelle herunter
Write-Host "🤖 Lade Whisper-Modell (1.5 GB)..." -ForegroundColor Yellow
$whisperModelUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"
if (-not (Test-Path "models\ggml-medium.bin")) {
    Invoke-WebRequest -Uri $whisperModelUrl -OutFile "models\ggml-medium.bin" -UseBasicParsing
}

Write-Host "🧠 Lade LLM-Modell (4.7 GB)..." -ForegroundColor Yellow
$llmUrl = "https://huggingface.co/bartowski/Llama-3.1-8B-Instruct-GGUF/resolve/main/Llama-3.1-8B-Instruct-Q4_K_M.gguf"
if (-not (Test-Path "models\Llama-3.1-8B-Instruct-Q4_K_M.gguf")) {
    Invoke-WebRequest -Uri $llmUrl -OutFile "models\Llama-3.1-8B-Instruct-Q4_K_M.gguf" -UseBasicParsing
}

Write-Host "🔊 Lade Piper-Stimme (100 MB)..." -ForegroundColor Yellow
$piperModelUrl = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/de/de_DE/thorsten/high/de_DE-thorsten-high.onnx"
$piperJsonUrl = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/de/de_DE/thorsten/high/de_DE-thorsten-high.onnx.json"
if (-not (Test-Path "models\de_DE-thorsten-high.onnx")) {
    Invoke-WebRequest -Uri $piperModelUrl -OutFile "models\de_DE-thorsten-high.onnx" -UseBasicParsing
    Invoke-WebRequest -Uri $piperJsonUrl -OutFile "models\de_DE-thorsten-high.onnx.json" -UseBasicParsing
}

# Kopiere Python-Skripte (falls im gleichen Ordner)
Write-Host "📝 Kopiere Skripte..." -ForegroundColor Yellow
$scriptDir = Split-Path -Parent $PSCommandPath
if (Test-Path "$scriptDir\voice_bridge.py") {
    Copy-Item "$scriptDir\voice_bridge.py" "." -Force
}
if (Test-Path "$scriptDir\voice_config.json") {
    Copy-Item "$scriptDir\voice_config.json" "." -Force
}

# Erstelle Start-Skript
Write-Host "🚀 Erstelle Start-Skript..." -ForegroundColor Yellow
$startScript = @"
@echo off
cd /d "$InstallDir"
call venv\Scripts\activate.bat
python voice_bridge.py
pause
"@
$startScript | Out-File -FilePath "start-voice.bat" -Encoding ASCII

# Erstelle Desktop-Verknüpfung
Write-Host "🔗 Erstelle Desktop-Verknüpfung..." -ForegroundColor Yellow
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\OpenClaw Voice.lnk")
$Shortcut.TargetPath = "$InstallDir\start-voice.bat"
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.IconLocation = "%SystemRoot%\System32\SHELL32.dll, 13"
$Shortcut.Save()

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  Installation abgeschlossen!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Starte mit: $InstallDir\start-voice.bat" -ForegroundColor Cyan
Write-Host "Oder doppelklicke: OpenClaw Voice (Desktop)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tasten:" -ForegroundColor Yellow
Write-Host "  F12 - Starte/Stoppe Aufnahme" -ForegroundColor White
Write-Host "  ESC - Beende Programm" -ForegroundColor White
Write-Host ""
Read-Host "Drücke Enter zum Beenden"
