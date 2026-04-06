#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Fort Knox Setup - Final Working Version
    Based on lessons learned from 4 hours of debugging on 2026-03-31
    
.DESCRIPTION
    Sets up isolated autoresearch environment with proper permissions.
    Tested on German Windows systems.
    
.EXAMPLE
    .\Setup-FortKnox-Final.ps1
#>

[CmdletBinding()]
param()

# Error handling
$ErrorActionPreference = Stop

# Configuration
$UserName = autoresearch
$BasePath = C:\Autoresearch
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ========================================
Write-Host FORT