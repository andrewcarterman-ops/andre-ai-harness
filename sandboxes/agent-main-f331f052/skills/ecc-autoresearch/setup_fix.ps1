# Fort Knox Setup - Fix Berechtigungen
# FÃ¼hrt fehlende Schritte nach

param()

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ERROR: