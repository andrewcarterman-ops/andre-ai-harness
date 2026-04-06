#!/usr/bin/env pwsh
# /checkpoint Command
# Erstellt einen Checkpoint

param(
    [string]$Message = "Checkpoint"
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "📍 /checkpoint - Session Checkpoint" -ForegroundColor Cyan
Write-Host ""

# Checkpoint erstellen
$checkpointDir = "$workspaceRoot/memory/checkpoints"
if (-not (Test-Path $checkpointDir)) {
    New-Item -ItemType Directory -Path $checkpointDir -Force | Out-Null
}

$checkpointFile = "$checkpointDir/CHECKPOINT-$timestamp.json"

$checkpoint = @{
    timestamp = Get-Date -Format "o"
    message = $Message
    session_id = "SESSION-$timestamp"
    files_modified = @()
    git_commit = $null
}

# Aktive Session finden
$sessionFile = Get-ChildItem "$workspaceRoot/memory/sessions/SESSION-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($sessionFile) {
    $checkpoint.session_id = $sessionFile.BaseName
}

$checkpoint | ConvertTo-Json | Out-File $checkpointFile -Encoding UTF8

Write-Host "✅ Checkpoint erstellt: $checkpointFile" -ForegroundColor Green
Write-Host "   Nachricht: $Message" -ForegroundColor Gray
