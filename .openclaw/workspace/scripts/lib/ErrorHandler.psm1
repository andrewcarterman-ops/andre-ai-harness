# Error Handler Library
# Zentrale Fehlerbehandlung für alle Framework-Skripte

$script:ErrorLogFile = $null
$script:ErrorContext = @{}

function Initialize-ErrorHandling {
    param(
        [string]$LogFile = "memory/logs/error.log",
        [string]$ScriptName = $MyInvocation.ScriptName
    )
    
    $script:ErrorLogFile = Join-Path $workspaceRoot $LogFile
    $script:ErrorContext.ScriptName = Split-Path $ScriptName -Leaf
    $script:ErrorContext.StartTime = Get-Date
    $script:ErrorContext.ErrorCount = 0
    
    # Log-Verzeichnis erstellen
    $logDir = Split-Path $script:ErrorLogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Error-Action-Preference setzen
    $ErrorActionPreference = "Stop"
    
    # Global Error-Handler registrieren
    $Global:ErrorActionPreference = "Stop"
}

function Write-ErrorLog {
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [string]$Severity = "ERROR",  # ERROR, WARNING, INFO
        [hashtable]$Context = @{},
        [switch]$Fatal
    )
    
    $script:ErrorContext.ErrorCount++
    
    $errorEntry = @{
        timestamp = Get-Date -Format "o"
        severity = $Severity
        script = $script:ErrorContext.ScriptName
        message = $ErrorRecord.Exception.Message
        category = $ErrorRecord.CategoryInfo.Category.ToString()
        target = $ErrorRecord.TargetObject
        stacktrace = $ErrorRecord.ScriptStackTrace
        line = $ErrorRecord.InvocationInfo.ScriptLineNumber
        context = $Context
        fatal = $Fatal.IsPresent
    } | ConvertTo-Json -Compress
    
    # In Log-Datei schreiben
    $errorEntry | Out-File $script:ErrorLogFile -Append -Encoding UTF8
    
    # Console-Output
    $color = switch ($Severity) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "❌ [$Severity] $($ErrorRecord.Exception.Message)" -ForegroundColor $color
    
    if ($Fatal) {
        Write-Host "   Fatal error. Exiting." -ForegroundColor Red
        Write-Host "   Log: $($script:ErrorLogFile)" -ForegroundColor Gray
        exit 1
    }
}

function Invoke-WithErrorHandling {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [string]$OperationName = "operation",
        [int]$MaxRetries = 0,
        [int]$RetryDelaySeconds = 1,
        [switch]$FatalOnError
    )
    
    $attempt = 0
    $lastError = $null
    
    do {
        $attempt++
        
        try {
            Write-Host "   Attempt $attempt/$(if($MaxRetries -gt 0){$MaxRetries+1}else{1}): $OperationName..." -ForegroundColor Gray
            
            $result = & $ScriptBlock
            
            if ($attempt -gt 1) {
                Write-Host "   ✅ Success after retry" -ForegroundColor Green
            }
            
            return $result
        }
        catch {
            $lastError = $_
            
            $context = @{
                operation = $OperationName
                attempt = $attempt
                maxRetries = $MaxRetries
            }
            
            if ($attempt -le $MaxRetries) {
                Write-ErrorLog -ErrorRecord $_ -Severity "WARNING" -Context $context
                Write-Host "   ⚠️  Failed, retrying in ${RetryDelaySeconds}s..." -ForegroundColor Yellow
                Start-Sleep -Seconds $RetryDelaySeconds
            }
            else {
                Write-ErrorLog -ErrorRecord $_ -Severity "ERROR" -Context $context -Fatal:$FatalOnError
                
                if (-not $FatalOnError) {
                    return $null
                }
            }
        }
    } while ($attempt -le $MaxRetries)
    
    # Sollte nie erreicht werden
    if ($FatalOnError) {
        exit 1
    }
    return $null
}

function Get-ErrorSummary {
    param([int]$LastMinutes = 60)
    
    if (-not (Test-Path $script:ErrorLogFile)) {
        return @{ count = 0; errors = @() }
    }
    
    $cutoff = (Get-Date).AddMinutes(-$LastMinutes)
    $errors = Get-Content $script:ErrorLogFile | ForEach-Object {
        try {
            $entry = $_ | ConvertFrom-Json
            if ([DateTime]$entry.timestamp -gt $cutoff) {
                $entry
            }
        } catch {}
    }
    
    return @{
        count = $errors.Count
        errors = $errors
        bySeverity = $errors | Group-Object -Property severity
        byScript = $errors | Group-Object -Property script
    }
}

# Export
Export-ModuleMember -Function Initialize-ErrorHandling, Write-ErrorLog, Invoke-WithErrorHandling, Get-ErrorSummary
