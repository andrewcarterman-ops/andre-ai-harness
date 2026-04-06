# Fort Knox - Nuclear Reset
# Loescht ALLES und baut sauber neu auf

param(
    [switch]$Force
)

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ERROR: