@echo off
chcp 65001 >nul
title OpenClaw → Obsidian Sync

echo ========================================
echo OpenClaw → Obsidian Sync
echo ========================================
echo.

REM PowerShell 7 prüfen
where pwsh >nul 2>&1
if %errorlevel% == 0 (
    set POWERSHELL=pwsh
    echo Using PowerShell 7
) else (
    set POWERSHELL=powershell
    echo Using Windows PowerShell
)

echo.

REM Parameter verarbeiten
set PARAMS=
if "%~1"=="--dry-run" set PARAMS=%PARAMS% -DryRun
if "%~1"=="-d" set PARAMS=%PARAMS% -DryRun
if "%~1"=="--force" set PARAMS=%PARAMS% -Force
if "%~1"=="-f" set PARAMS=%PARAMS% -Force

REM Sync ausführen
echo Starting sync...
echo.

%POWERSHELL% -ExecutionPolicy Bypass -File "%~dp0sync-openclaw-to-obsidian.ps1"%PARAMS%

if %errorlevel% == 0 (
    echo.
    echo ========================================
    echo Sync completed successfully!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Sync failed with error code: %errorlevel%
    echo ========================================
)

echo.
pause
