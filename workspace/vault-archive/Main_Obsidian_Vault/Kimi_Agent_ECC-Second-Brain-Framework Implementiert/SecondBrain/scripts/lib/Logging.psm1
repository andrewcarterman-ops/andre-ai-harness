#Requires -Version 5.1
<#
.SYNOPSIS
    ECC Logging Module - Winston-ähnliches Logging mit Datei-Rotation

.DESCRIPTION
    Strukturiertes Logging-Modul für das ECC Second Brain Framework.
    Unterstützt 5 Log-Levels, Datei-Rotation und JSON-Format.

.EXAMPLE
    Write-ECCLog "Operation completed" -Level "INFO"
    Write-ECCLog "Warning message" -Level "WARN" -Metadata @{ context = "test" }

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    ECC Framework: Logging
#>

# Module Variables
$script:ModuleVersion = "1.0.0"
$script:DefaultLogPath = Join-Path $PSScriptRoot "..\..\.logs"
$script:MaxLogSizeMB = 10
$script:MaxLogFiles = 10
$script:LogLevel = "INFO"

# Log Levels (Ordered by severity)
$script:LogLevels = @{
    "DEBUG" = 0
    "INFO" = 1
    "WARN" = 2
    "ERROR" = 3
    "FATAL" = 4
}

#region Public Functions

<#
.SYNOPSIS
    Schreibt einen Log-Eintrag

.PARAMETER Message
    Die Log-Nachricht

.PARAMETER Level
    Log-Level (DEBUG, INFO, WARN, ERROR, FATAL)

.PARAMETER Metadata
    Zusätzliche Metadaten als Hashtable

.PARAMETER LogFile
    Pfad zur Log-Datei (optional)
#>
function Write-ECCLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile = $null
    )
    
    # Check if we should log this level
    if ($script:LogLevels[$Level] -lt $script:LogLevels[$script:LogLevel]) {
        return
    }
    
    # Determine log file
    if ([string]::IsNullOrEmpty($LogFile)) {
        $LogFile = Get-CurrentLogFile
    }
    
    # Ensure log directory exists
    $logDir = Split-Path $LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Create log entry
    $logEntry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        level = $Level
        message = $Message
        pid = $PID
        metadata = $Metadata
    }
    
    # Check rotation
    Test-LogRotation -LogFile $LogFile
    
    # Write to file (JSON format)
    $jsonEntry = $logEntry | ConvertTo-Json -Compress
    Add-Content -Path $LogFile -Value $jsonEntry -Encoding UTF8
    
    # Console output with colors
    $consoleMessage = "[$($logEntry.timestamp)] [$Level] $Message"
    switch ($Level) {
        "DEBUG" { Write-Verbose $consoleMessage }
        "INFO"  { Write-Host $consoleMessage -ForegroundColor Cyan }
        "WARN"  { Write-Host $consoleMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $consoleMessage -ForegroundColor Red }
        "FATAL" { Write-Host $consoleMessage -ForegroundColor Magenta }
    }
}

<#
.SYNOPSIS
    Setzt das Log-Level

.PARAMETER Level
    Neues Log-Level
#>
function Set-ECCLogLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$Level
    )
    
    $script:LogLevel = $Level
    Write-ECCLog "Log level changed to: $Level" -Level "INFO"
}

<#
.SYNOPSIS
    Gibt das aktuelle Log-Level zurück

.OUTPUTS
    String
#>
function Get-ECCLogLevel {
    return $script:LogLevel
}

<#
.SYNOPSIS
    Rotiert Log-Dateien

.PARAMETER LogFile
    Pfad zur Log-Datei
#>
function Invoke-LogRotation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LogFile = $null
    )
    
    if ([string]::IsNullOrEmpty($LogFile)) {
        $LogFile = Get-CurrentLogFile
    }
    
    if (!(Test-Path $LogFile)) {
        return
    }
    
    $logFileInfo = Get-Item $LogFile
    $logSizeMB = $logFileInfo.Length / 1MB
    
    if ($logSizeMB -ge $script:MaxLogSizeMB) {
        Write-ECCLog "Rotating log file: $LogFile" -Level "INFO"
        
        # Rotate existing backups
        for ($i = $script:MaxLogFiles - 1; $i -ge 1; $i--) {
            $oldFile = "$LogFile.$i"
            $newFile = "$LogFile.$($i + 1)"
            
            if (Test-Path $oldFile) {
                if ($i -eq $script:MaxLogFiles) {
                    Remove-Item $oldFile -Force
                }
                else {
                    Move-Item $oldFile $newFile -Force
                }
            }
        }
        
        # Move current log
        Move-Item $LogFile "$LogFile.1" -Force
        
        Write-ECCLog "Log rotation completed" -Level "INFO"
    }
}

<#
.SYNOPSIS
    Liest Log-Einträge

.PARAMETER LogFile
    Pfad zur Log-Datei

.PARAMETER Level
    Filter nach Log-Level

.PARAMETER Tail
    Anzahl der letzten Einträge

.PARAMETER StartTime
    Startzeit für Filter

.PARAMETER EndTime
    Endzeit für Filter

.OUTPUTS
    PSCustomObject[]
#>
function Get-ECCLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LogFile = $null,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$Level = $null,
        
        [Parameter(Mandatory = $false)]
        [int]$Tail = 0,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime = $null,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndTime = $null
    )
    
    if ([string]::IsNullOrEmpty($LogFile)) {
        $LogFile = Get-CurrentLogFile
    }
    
    if (!(Test-Path $LogFile)) {
        Write-Warning "Log file not found: $LogFile"
        return @()
    }
    
    $logs = Get-Content $LogFile | ForEach-Object {
        try {
            $_ | ConvertFrom-Json
        }
        catch {
            $null
        }
    } | Where-Object { $_ -ne $null }
    
    # Apply filters
    if ($Level) {
        $logs = $logs | Where-Object { $_.level -eq $Level }
    }
    
    if ($StartTime) {
        $logs = $logs | Where-Object { [DateTime]$_.timestamp -ge $StartTime }
    }
    
    if ($EndTime) {
        $logs = $logs | Where-Object { [DateTime]$_.timestamp -le $EndTime }
    }
    
    if ($Tail -gt 0) {
        $logs = $logs | Select-Object -Last $Tail
    }
    
    return $logs
}

<#
.SYNOPSIS
    Löscht alte Log-Dateien

.PARAMETER DaysToKeep
    Anzahl der Tage, die Logs aufbewahrt werden sollen

.PARAMETER LogPath
    Pfad zum Log-Verzeichnis
#>
function Clear-OldLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$DaysToKeep = 30,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = $script:DefaultLogPath
    )
    
    if (!(Test-Path $LogPath)) {
        return
    }
    
    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
    $logFiles = Get-ChildItem $LogPath -Filter "*.log*" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    foreach ($file in $logFiles) {
        Remove-Item $file.FullName -Force
        Write-ECCLog "Deleted old log: $($file.Name)" -Level "DEBUG"
    }
    
    Write-ECCLog "Cleared $($logFiles.Count) old log files" -Level "INFO"
}

#endregion

#region Private Functions

function Get-CurrentLogFile {
    $date = Get-Date -Format "yyyy-MM-dd"
    $logFileName = "ecc-second-brain-$date.log"
    return Join-Path $script:DefaultLogPath $logFileName
}

function Test-LogRotation {
    param([string]$LogFile)
    
    if (Test-Path $LogFile) {
        $fileInfo = Get-Item $LogFile
        if ($fileInfo.Length / 1MB -ge $script:MaxLogSizeMB) {
            Invoke-LogRotation -LogFile $LogFile
        }
    }
}

#endregion

# Export Module Members
Export-ModuleMember -Function @(
    'Write-ECCLog',
    'Set-ECCLogLevel',
    'Get-ECCLogLevel',
    'Invoke-LogRotation',
    'Get-ECCLog',
    'Clear-OldLogs'
)
