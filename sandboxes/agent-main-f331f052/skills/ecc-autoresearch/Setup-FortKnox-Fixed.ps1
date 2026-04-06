#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Fort Knox Setup - Working Version (Fixed)
    Based on lessons learned from debugging
    
.DESCRIPTION
    Sets up isolated autoresearch environment with proper permissions.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = Stop

$UserName = autoresearch
$BasePath = C:\Autoresearch
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ========================================
Write-Host FORT