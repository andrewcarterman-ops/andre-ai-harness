# Fort Knox Setup - Korrigierte Version
# FÃ¼hrt alle SicherheitsmaÃŸnahmen zusammen

# PrÃ¼fe Admin-Rechte
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host âŒ