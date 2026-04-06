#!/usr/bin/env pwsh
# /update-docs Command
# Auto-update documentation

param(
    [switch]$Force
)

$ErrorActionPreference = Stop
$workspaceRoot = $PSScriptRoot | Split-Path -Parent

Write-Host ðŸ“