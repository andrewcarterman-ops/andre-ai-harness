# Logging Library
# Strukturiertes Logging für alle Framework-Komponenten

$script:LogConfig = @{
    BasePath = "memory/logs"
    CurrentLogFile = $null
    SessionId = $null
    MinLevel = "INFO"  # DEBUG, INFO, WARNING, ERROR, FATAL
}

$script:LogLevels = @{
    DEBUG = 0
    INFO = 1
    WARNING = 2
    ERROR = 3
    FATAL = 4
}

function Initialize-Logging {
    param(
        [string]$Component = "framework",
        [string]$Level = "INFO",
        [string]$CustomPath = $null
    )
    
    $script:LogConfig.SessionId = [Guid]::NewGuid().ToString().Substring(0, 8)
    $script:LogConfig.MinLevel = $Level
    
    # Log-Pfad bestimmen
    if ($CustomPath) {
        $logPath = $CustomPath
    } else {
        $date = Get-Date -Format "yyyy-MM-dd"
        $logPath = Join-Path $script:LogConfig.BasePath "$date-$Component.log"
    }
    
    $script:LogConfig.CurrentLogFile = Join-Path $workspaceRoot $logPath
    
    # Verzeichnis erstellen
    $logDir = Split-Path $script:LogConfig.CurrentLogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Header schreiben
    $header = @"
# Log Session
**Started:** $(Get-Date -Format "o")
**Session ID:** $($script:LogConfig.SessionId)
**Component:** $Component
**Level:** $Level

---

"@
    $header | Out-File $script:LogConfig.CurrentLogFile -Encoding UTF8
    
    Write-Log -Level "INFO" -Message "Logging initialized" -Component $Component
    
    return $script:LogConfig.CurrentLogFile
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "FATAL")]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [string]$Component = "general",
        [hashtable]$Data = @{},
        [switch]$Console
    )
    
    # Level-Prüfung
    if ($script:LogLevels[$Level] -lt $script:LogLevels[$script:LogConfig.MinLevel]) {
        return
    }
    
    $entry = @{
        timestamp = Get-Date -Format "o"
        level = $Level
        component = $Component
        message = $Message
        session_id = $script:LogConfig.SessionId
        data = $Data
    }
    
    # Format: [TIMESTAMP] [LEVEL] [COMPONENT] Message
    $logLine = "[{0}] [{1}] [{2}] {3}" -f 
        (Get-Date -Format "HH:mm:ss"),
        $Level.PadRight(7),
        $Component.PadRight(15),
        $Message
    
    # In Datei schreiben
    if ($script:LogConfig.CurrentLogFile) {
        $logLine | Out-File $script:LogConfig.CurrentLogFile -Append -Encoding UTF8
    }
    
    # Console-Output (optional oder bei ERROR/FATAL)
    if ($Console -or $Level -in @("ERROR", "FATAL") -or $script:LogLevels[$Level] -ge 2) {
        $color = switch ($Level) {
            "DEBUG" { "Gray" }
            "INFO" { "White" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "FATAL" { "Magenta" }
        }
        Write-Host $logLine -ForegroundColor $color
    }
}

# Convenience-Funktionen
function Write-DebugLog { param($Message, $Component="general", $Data=@{}) Write-Log -Level "DEBUG" -Message $Message -Component $Component -Data $Data }
function Write-InfoLog { param($Message, $Component="general", $Data=@{}) Write-Log -Level "INFO" -Message $Message -Component $Component -Data $Data }
function Write-WarningLog { param($Message, $Component="general", $Data=@{}) Write-Log -Level "WARNING" -Message $Message -Component $Component -Data $Data -Console }
function Write-ErrorLog { param($Message, $Component="general", $Data=@{}) Write-Log -Level "ERROR" -Message $Message -Component $Component -Data $Data -Console }
function Write-FatalLog { param($Message, $Component="general", $Data=@{}) Write-Log -Level "FATAL" -Message $Message -Component $Component -Data $Data -Console }

function Get-LogStats {
    param([string]$LogFile = $null)
    
    if (-not $LogFile) {
        $LogFile = $script:LogConfig.CurrentLogFile
    }
    
    if (-not (Test-Path $LogFile)) {
        return @{ error = "Log file not found" }
    }
    
    $lines = Get-Content $LogFile
    $stats = @{
        totalLines = $lines.Count
        byLevel = @{}
        components = @{}
    }
    
    foreach ($line in $lines) {
        if ($line -match '\[(\w+)\].*\[(\w+)\]') {
            $level = $matches[1]
            $comp = $matches[2]
            
            if (-not $stats.byLevel[$level]) { $stats.byLevel[$level] = 0 }
            $stats.byLevel[$level]++
            
            if (-not $stats.components[$comp]) { $stats.components[$comp] = 0 }
            $stats.components[$comp]++
        }
    }
    
    return $stats
}

function Rotate-Logs {
    param([int]$KeepDays = 30)
    
    $logDir = Join-Path $workspaceRoot $script:LogConfig.BasePath
    if (-not (Test-Path $logDir)) { return }
    
    $cutoff = (Get-Date).AddDays(-$KeepDays)
    
    Get-ChildItem $logDir -Filter "*.log" | Where-Object {
        $_.LastWriteTime -lt $cutoff
    } | Remove-Item -Force
    
    Write-InfoLog -Message "Log rotation completed, removed files older than $KeepDays days"
}

# Export
Export-ModuleMember -Function Initialize-Logging, Write-Log, Write-DebugLog, Write-InfoLog, Write-WarningLog, Write-ErrorLog, Write-FatalLog, Get-LogStats, Rotate-Logs
