# Autoresearch Fort Knox - Master Setup Skript
# FÃ¼hrt alle SicherheitsmaÃŸnahmen zusammen

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = setup,  # setup, run, stop, status
    
    [Parameter(Mandatory=$false)]
    [string]$ExperimentName = overnight-test,
    
    [Parameter(Mandatory=$false)]
    [string]$AutoresearchPath = C:\Autoresearch\autoresearch,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxRuntimeHours = 6
)

# ============================================================================
# KONFIGURATION
# ============================================================================

$Config = @{
    UserName = autoresearch
    BasePath = C:\Autoresearch
    GuardianPath = $PSScriptRoot\autoresearch_guardian.py
    SafetyCheckerPath = $PSScriptRoot\ecc_safety_checker.py
    LogPath = C:\Autoresearch\logs
    BackupPath = C:\Autoresearch\backups
    
    # Limits (konservativer als nÃ¶tig)
    MaxRuntimeMinutes = $MaxRuntimeHours * 60
    MaxMemoryGB = 48
    MaxDiskGB = 8
    MaxCpuPercent = 80
}

# ============================================================================
# FARBDEFINITIONEN
# ============================================================================

$Colors = @{
    Success = Green
    Warning = Yellow
    Error = Red
    Info = Cyan
    Debug = Gray
}

function Write-Status {
    param([string]$Message, [string]$Level = Info)
    $color = $Colors[$Level]
    Write-Host $Message -ForegroundColor $color
}

# ============================================================================
# SETUP FUNKTIONEN
# ============================================================================

function Initialize-FortKnox {
    Write-Status ðŸ°