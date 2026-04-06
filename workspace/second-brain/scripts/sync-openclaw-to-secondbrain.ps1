#!/usr/bin/env pwsh
# Sync OpenClaw Sessions to Second Brain
# Kopiert Session-Daten ins PARA-System

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = Stop
$workspaceRoot = C:\Users\andre\.openclaw\workspace
$secondBrainRoot = $workspaceRoot\second-brain
$memoryDir = $workspaceRoot\memory

Write-Host ðŸ§ 