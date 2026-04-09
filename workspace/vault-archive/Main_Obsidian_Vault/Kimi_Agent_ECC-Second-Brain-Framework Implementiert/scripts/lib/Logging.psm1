# ============================================================================
# ECC-CORE Logging Module
# Second-Brain Framework - Winston-style Logging with Rotation
# ============================================================================
#Requires -Version 5.1

# Module-level variables
$script:LogConfig = @{
    BasePath       = $null
    CurrentLogFile = $null
    MaxSizeBytes   = 10MB
    MaxBackupFiles = 10
    MinLevel       = 'DEBUG'
    ConsoleOutput  = $true
    FileOutput     = $true
    Initialized    = $false
}

$script:LogLevels = @{
    'DEBUG' = 0
    'INFO'  = 1
    'WARN'  = 2
    'ERROR' = 3
    'FATAL' = 4
}

<#
.SYNOPSIS
    Initializes the logging system.

.DESCRIPTION
    Sets up log directory, determines log file path with date stamp,
    and configures rotation settings.

.PARAMETER BasePath
    Base directory for the Second-Brain installation.

.PARAMETER MaxSizeMB
    Maximum log file size in MB before rotation (default: 10).

.PARAMETER MinLevel
    Minimum log level to record (default: DEBUG).

.PARAMETER ConsoleOutput
    Enable console output (default: true).

.PARAMETER FileOutput
    Enable file output (default: true).
#>
function Initialize-ECCLogging {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BasePath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",

        [Parameter()]
        [int]$MaxSizeMB = 10,

        [Parameter()]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')]
        [string]$MinLevel = 'DEBUG',

        [Parameter()]
        [bool]$ConsoleOutput = $true,

        [Parameter()]
        [bool]$FileOutput = $true
    )

    $script:LogConfig.BasePath = $BasePath
    $script:LogConfig.MaxSizeBytes = $MaxSizeMB * 1MB
    $script:LogConfig.MinLevel = $MinLevel
    $script:LogConfig.ConsoleOutput = $ConsoleOutput
    $script:LogConfig.FileOutput = $FileOutput

    # Ensure log directory exists
    $logDir = Join-Path $BasePath ".logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    # Set current log file with date stamp
    $dateStamp = Get-Date -Format "yyyy-MM-dd"
    $script:LogConfig.CurrentLogFile = Join-Path $logDir "ecc-second-brain-$dateStamp.log"

    # Clean up old log files
    Invoke-LogRotation

    $script:LogConfig.Initialized = $true

    Write-ECCLog -Level 'INFO' -Message 'ECC Logging System Initialized' -Source 'Logging'
}

<#
.SYNOPSIS
    Writes a log entry with specified level.

.DESCRIPTION
    Main logging function supporting DEBUG, INFO, WARN, ERROR, and FATAL levels.
    Handles log rotation and outputs to both console and file.

.PARAMETER Level
    Log level: DEBUG, INFO, WARN, ERROR, FATAL.

.PARAMETER Message
    The message to log.

.PARAMETER Source
    Source component or module name.

.PARAMETER ErrorRecord
    Optional ErrorRecord for error-level logs.

.PARAMETER Metadata
    Additional metadata as hashtable.
#>
function Write-ECCLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [string]$Source = 'ECC',

        [Parameter()]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter()]
        [hashtable]$Metadata = @{}
    )

    # Auto-initialize if not done
    if (-not $script:LogConfig.Initialized) {
        Initialize-ECCLogging
    }

    # Check minimum level
    if ($script:LogLevels[$Level] -lt $script:LogLevels[$script:LogConfig.MinLevel]) {
        return
    }

    # Build log entry
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $processId = $PID
    $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId

    $logEntry = [PSCustomObject]@{
        Timestamp  = $timestamp
        Level      = $Level.PadRight(5)
        Source     = $Source.PadRight(20)
        ProcessId  = $processId
        ThreadId   = $threadId
        Message    = $Message
    }

    # Add metadata if provided
    if ($Metadata.Count -gt 0) {
        $logEntry | Add-Member -NotePropertyName 'Metadata' -NotePropertyValue $Metadata
    }

    # Add error details if provided
    if ($ErrorRecord) {
        $logEntry | Add-Member -NotePropertyName 'Error' -NotePropertyValue @{
            Message      = $ErrorRecord.Exception.Message
            ExceptionType = $ErrorRecord.Exception.GetType().Name
            StackTrace   = $ErrorRecord.ScriptStackTrace
        }
    }

    # Format for output
    $consoleOutput = "[$timestamp] [$Level] [$Source] $Message"
    $fileOutput = $logEntry | ConvertTo-Json -Compress

    # Console output with colors
    if ($script:LogConfig.ConsoleOutput) {
        $color = switch ($Level) {
            'DEBUG' { 'Gray' }
            'INFO'  { 'White' }
            'WARN'  { 'Yellow' }
            'ERROR' { 'Red' }
            'FATAL' { 'Magenta' }
        }
        Write-Host $consoleOutput -ForegroundColor $color
    }

    # File output
    if ($script:LogConfig.FileOutput -and $script:LogConfig.CurrentLogFile) {
        # Check rotation before writing
        Test-LogRotation
        
        # Append to log file
        $fileOutput | Out-File -FilePath $script:LogConfig.CurrentLogFile -Append -Encoding UTF8
    }
}

<#
.SYNOPSIS
    Tests if log rotation is needed.

.DESCRIPTION
    Checks current log file size and triggers rotation if needed.
#>
function Test-LogRotation {
    [CmdletBinding()]
    param()

    if (Test-Path $script:LogConfig.CurrentLogFile) {
        $fileInfo = Get-Item $script:LogConfig.CurrentLogFile
        if ($fileInfo.Length -ge $script:LogConfig.MaxSizeBytes) {
            Invoke-LogRotation
        }
    }
}

<#
.SYNOPSIS
    Performs log file rotation.

.DESCRIPTION
    Rotates log files when size limit is reached and cleans up old logs.
#>
function Invoke-LogRotation {
    [CmdletBinding()]
    param()

    $logDir = Join-Path $script:LogConfig.BasePath ".logs"
    
    if (-not (Test-Path $logDir)) {
        return
    }

    # Get all log files
    $logFiles = Get-ChildItem -Path $logDir -Filter "ecc-second-brain-*.log*" | 
                Sort-Object LastWriteTime -Descending

    # Rotate current log if it exists and is too large
    if (Test-Path $script:LogConfig.CurrentLogFile) {
        $currentFile = Get-Item $script:LogConfig.CurrentLogFile
        if ($currentFile.Length -ge $script:LogConfig.MaxSizeBytes) {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $rotatedName = "ecc-second-brain-$(Get-Date -Format 'yyyy-MM-dd')-$timestamp.log"
            $rotatedPath = Join-Path $logDir $rotatedName
            
            Move-Item -Path $script:LogConfig.CurrentLogFile -Destination $rotatedPath -Force
        }
    }

    # Clean up old log files (keep only MaxBackupFiles)
    $logFiles = Get-ChildItem -Path $logDir -Filter "ecc-second-brain-*.log*" | 
                Sort-Object LastWriteTime -Descending
    
    if ($logFiles.Count -gt $script:LogConfig.MaxBackupFiles) {
        $filesToRemove = $logFiles | Select-Object -Skip $script:LogConfig.MaxBackupFiles
        foreach ($file in $filesToRemove) {
            Remove-Item -Path $file.FullName -Force
            Write-Verbose "Removed old log file: $($file.Name)"
        }
    }
}

<#
.SYNOPSIS
    Writes a debug log entry.
#>
function Write-DebugLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [string]$Source = 'ECC'
    )
    Write-ECCLog -Level 'DEBUG' -Message $Message -Source $Source
}

<#
.SYNOPSIS
    Writes an info log entry.
#>
function Write-InfoLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [string]$Source = 'ECC'
    )
    Write-ECCLog -Level 'INFO' -Message $Message -Source $Source
}

<#
.SYNOPSIS
    Writes a warning log entry.
#>
function Write-WarnLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [string]$Source = 'ECC'
    )
    Write-ECCLog -Level 'WARN' -Message $Message -Source $Source
}

<#
.SYNOPSIS
    Writes an error log entry.
#>
function Write-ErrorLogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [string]$Source = 'ECC',

        [Parameter()]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    Write-ECCLog -Level 'ERROR' -Message $Message -Source $Source -ErrorRecord $ErrorRecord
}

<#
.SYNOPSIS
    Writes a fatal log entry.
#>
function Write-FatalLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [string]$Source = 'ECC',

        [Parameter()]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    Write-ECCLog -Level 'FATAL' -Message $Message -Source $Source -ErrorRecord $ErrorRecord
}

<#
.SYNOPSIS
    Gets current log file path.

.OUTPUTS
    String path to current log file.
#>
function Get-CurrentLogPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    return $script:LogConfig.CurrentLogFile
}

<#
.SYNOPSIS
    Gets recent log entries.

.PARAMETER Lines
    Number of lines to retrieve (default: 50).

.PARAMETER Level
    Filter by log level.
#>
function Get-RecentLogs {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Lines = 50,

        [Parameter()]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')]
        [string]$Level
    )

    if (-not (Test-Path $script:LogConfig.CurrentLogFile)) {
        return @()
    }

    $logs = Get-Content -Path $script:LogConfig.CurrentLogFile -Tail $Lines | 
            ForEach-Object { 
                try { $_ | ConvertFrom-Json } catch { $null }
            } | 
            Where-Object { $_ -ne $null }

    if ($Level) {
        $logs = $logs | Where-Object { $_.Level.Trim() -eq $Level }
    }

    return $logs
}

# Export module members
Export-ModuleMember -Function @(
    'Initialize-ECCLogging',
    'Write-ECCLog',
    'Write-DebugLog',
    'Write-InfoLog',
    'Write-WarnLog',
    'Write-ErrorLogEntry',
    'Write-FatalLog',
    'Get-CurrentLogPath',
    'Get-RecentLogs',
    'Test-LogRotation',
    'Invoke-LogRotation'
)
