#!/usr/bin/env pwsh
# /learn Command
# Extrahiert Patterns aus der aktuellen Session

param(
    [string]$Name,
    [switch]$Auto
)

$ErrorActionPreference = Stop
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Write-Host ðŸŽ“