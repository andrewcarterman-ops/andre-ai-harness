#!/usr/bin/env pwsh
# /resume-session Command
# Resume a previous session

param(
    [string]$SessionId,
    [switch]$List,
    [switch]$Last
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

$sessionsDir = "$workspaceRoot/memory/sessions"

if ($List) {
    Write-Host "`n📚 Available Sessions:" -ForegroundColor Cyan
    
    $sessions = Get-ChildItem "$sessionsDir/SESSION-*.json" -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending |
        ForEach-Object {
            $data = Get-Content $_.FullName | ConvertFrom-Json
            [PSCustomObject]@{
                Id = $data.session_id
                Date = $data.timeline.start_time
                Status = $data.timeline.status
                Duration = if ($data.timeline.duration_seconds) { "$([math]::Round($data.timeline.duration_seconds/60, 1)) min" } else { "N/A" }
            }
        }
    
    if ($sessions) {
        $sessions | Format-Table -AutoSize
    } else {
        Write-Host "No sessions found" -ForegroundColor Yellow
    }
    exit 0
}

if ($Last) {
    $latest = Get-ChildItem "$sessionsDir/SESSION-*.json" -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    
    if ($latest) {
        $SessionId = [System.IO.Path]::GetFileNameWithoutExtension($latest.Name)
    } else {
        Write-Error "No sessions found"
        exit 1
    }
}

if (-not $SessionId) {
    Write-Error "Specify -SessionId, -List, or -Last"
    exit 1
}

$sessionFile = "$sessionsDir/$SessionId.json"

if (-not (Test-Path $sessionFile)) {
    Write-Error "Session not found: $SessionId"
    exit 1
}

$session = Get-Content $sessionFile | ConvertFrom-Json

Write-Host "`n🔄 Resuming Session: $SessionId" -ForegroundColor Cyan
Write-Host "Started: $($session.timeline.start_time)" -ForegroundColor Gray
Write-Host "Status: $($session.timeline.status)" -ForegroundColor Gray

if ($session.activity_summary.phases_completed) {
    Write-Host "`nCompleted Phases: $($session.activity_summary.phases_completed -join ', ')" -ForegroundColor Green
}

if ($session.references.next_step) {
    Write-Host "`n👉 Next Step: $($session.references.next_step)" -ForegroundColor Yellow
}

Write-Host "`n💡 To continue, use skills: $($session.system_state.skills_loaded -join ', ')" -ForegroundColor Gray
