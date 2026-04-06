#Requires -Version 7.0
<#
.SYNOPSIS
    Sync-AutoresearchToObsidian - Integration von autoresearch mit ECC Second Brain

.DESCRIPTION
    Synchronisiert Experiment-Ergebnisse aus autoresearch automatisch in den Obsidian Vault.
    Erstellt strukturierte Notizen, Dashboards und Knowledge Graphs.

.PARAMETER VaultPath
    Pfad zum Obsidian Vault

.PARAMETER AutoresearchPath
    Pfad zum autoresearch Repository

.PARAMETER SyncMode
    Sync-Modus: Full, Incremental, DashboardOnly

.EXAMPLE
    Sync-AutoresearchToObsidian -VaultPath ~\Documents\SecondBrain -AutoresearchPath ~\autoresearch
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$VaultPath = $env:USERPROFILE\Documents\Andrew