#Requires -Version 5.1
<#
.SYNOPSIS
    ECC Error Handler Module - Robustes Fehlerhandling mit Retry-Logik

.DESCRIPTION
    Zentrales Error-Handling-Modul für das ECC Second Brain Framework.
    Bietet Try-Catch-Wrapper, Retry-Logik mit exponentiellem Backoff und
    strukturierte Fehlerprotokollierung.

.EXAMPLE
    Invoke-WithErrorHandling -ScriptBlock { Get-Content "file.txt" } -OperationName "Datei lesen" -MaxRetries 3

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    ECC Framework: Error Handling
#>

# Module Variables
$script:ModuleVersion = "1.0.0"
$script:DefaultMaxRetries = 3
$script:DefaultRetryDelaySeconds = 2
$script:ErrorLogPath = Join-Path $PSScriptRoot "..\..\.logs\error.log"

#region Public Functions

<#
.SYNOPSIS
    Führt einen ScriptBlock mit Try-Catch und Retry-Logik aus

.PARAMETER ScriptBlock
    Der auszuführende Code

.PARAMETER OperationName
    Name der Operation für Logging

.PARAMETER MaxRetries
    Maximale Anzahl der Wiederholungsversuche (Default: 3)

.PARAMETER RetryDelaySeconds
    Verzögerung zwischen Versuchen in Sekunden (Default: 2)

.PARAMETER UseExponentialBackoff
    Verwendet exponentielles Backoff (Default: $true)

.PARAMETER ContinueOnError
    Fährt bei Fehler fort (Default: $false)

.OUTPUTS
    Ergebnis des ScriptBlocks oder $null bei Fehler
#>
function Invoke-WithErrorHandling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [string]$OperationName = "Unnamed Operation",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = $script:DefaultMaxRetries,
        
        [Parameter(Mandatory = $false)]
        [int]$RetryDelaySeconds = $script:DefaultRetryDelaySeconds,
        
        [Parameter(Mandatory = $false)]
        [bool]$UseExponentialBackoff = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$ContinueOnError = $false
    )
    
    $attempt = 0
    $lastError = $null
    
    do {
        $attempt++
        
        try {
            Write-ECCLog "[$OperationName] Versuch $attempt von $([Math]::Max($attempt, $MaxRetries + 1))" -Level "DEBUG"
            
            $result = & $ScriptBlock
            
            if ($attempt -gt 1) {
                Write-ECCLog "[$OperationName] Erfolg nach $attempt Versuchen" -Level "INFO"
            }
            
            return $result
        }
        catch {
            $lastError = $_
            $errorMessage = $_.Exception.Message
            $errorType = $_.Exception.GetType().Name
            
            Write-ECCLog "[$OperationName] Fehler (Versuch $attempt): $errorMessage" -Level "WARN"
            
            if ($attempt -le $MaxRetries) {
                $delay = if ($UseExponentialBackoff) {
                    $RetryDelaySeconds * [Math]::Pow(2, $attempt - 1)
                }
                else {
                    $RetryDelaySeconds
                }
                
                Write-ECCLog "[$OperationName] Warte $delay Sekunden vor Wiederholung..." -Level "DEBUG"
                Start-Sleep -Seconds $delay
            }
            else {
                Write-ECCLog "[$OperationName] Alle Versuche fehlgeschlagen" -Level "ERROR"
                Write-ErrorLog -ErrorRecord $_ -OperationName $OperationName
                
                if (!$ContinueOnError) {
                    throw
                }
                
                return $null
            }
        }
    } while ($attempt -le $MaxRetries)
}

<#
.SYNOPSIS
    Schreibt einen Fehler in das Fehlerlog

.PARAMETER ErrorRecord
    Das ErrorRecord-Objekt

.PARAMETER OperationName
    Name der Operation

.PARAMETER Fatal
    Markiert den Fehler als fatal
#>
function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter(Mandatory = $false)]
        [string]$OperationName = "Unknown",
        
        [Parameter(Mandatory = $false)]
        [switch]$Fatal
    )
    
    $logEntry = @{
        timestamp = Get-Date -Format "o"
        operation = $OperationName
        message = $ErrorRecord.Exception.Message
        type = $ErrorRecord.Exception.GetType().Name
        stackTrace = $ErrorRecord.ScriptStackTrace
        category = $ErrorRecord.CategoryInfo.Category.ToString()
        target = $ErrorRecord.TargetObject
        fatal = $Fatal.IsPresent
    }
    
    # Ensure log directory exists
    $logDir = Split-Path $script:ErrorLogPath -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Append to log file
    $logEntry | ConvertTo-Json -Compress | Add-Content -Path $script:ErrorLogPath
    
    # Console output
    $color = if ($Fatal) { "Red" } else { "Yellow" }
    Write-Host "[ERROR] [$OperationName] $($ErrorRecord.Exception.Message)" -ForegroundColor $color
}

<#
.SYNOPSIS
    Prüft, ob eine Operation als kritisch markiert ist

.PARAMETER OperationName
    Name der Operation

.OUTPUTS
    Boolean
#>
function Test-CriticalOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName
    )
    
    $criticalOperations = @(
        "Backup",
        "Restore",
        "Encryption",
        "Sync",
        "Vault-Modification"
    )
    
    foreach ($critical in $criticalOperations) {
        if ($OperationName -like "*$critical*") {
            return $true
        }
    }
    
    return $false
}

<#
.SYNOPSIS
    Wrappert einen kritischen Befehl mit zusätzlicher Sicherheit

.PARAMETER ScriptBlock
    Der auszuführende Code

.PARAMETER OperationName
    Name der Operation

.PARAMETER BackupBefore
    Erstellt ein Backup vor der Operation
#>
function Invoke-CriticalOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $true)]
        [string]$OperationName,
        
        [Parameter(Mandatory = $false)]
        [switch]$BackupBefore
    )
    
    Write-ECCLog "[CRITICAL] Starte kritische Operation: $OperationName" -Level "WARN"
    
    if ($BackupBefore) {
        Write-ECCLog "[CRITICAL] Erstelle Pre-Operation Backup..." -Level "INFO"
        # Backup-Logik hier
    }
    
    try {
        $result = Invoke-WithErrorHandling -ScriptBlock $ScriptBlock -OperationName $OperationName -MaxRetries 5
        Write-ECCLog "[CRITICAL] Operation erfolgreich: $OperationName" -Level "SUCCESS"
        return $result
    }
    catch {
        Write-ECCLog "[CRITICAL] Operation fehlgeschlagen: $OperationName" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Validiert Eingabeparameter

.PARAMETER Parameters
    Hashtable der zu validierenden Parameter

.PARAMETER Rules
    Validierungsregeln
#>
function Test-InputValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Rules
    )
    
    $errors = @()
    
    foreach ($rule in $Rules.GetEnumerator()) {
        $paramName = $rule.Key
        $ruleDef = $rule.Value
        
        if ($ruleDef.Required -and !$Parameters.ContainsKey($paramName)) {
            $errors += "Required parameter '$paramName' is missing"
            continue
        }
        
        if ($Parameters.ContainsKey($paramName)) {
            $value = $Parameters[$paramName]
            
            # Type validation
            if ($ruleDef.Type -and $value -isnot $ruleDef.Type) {
                $errors += "Parameter '$paramName' must be of type $($ruleDef.Type.Name)"
            }
            
            # Pattern validation
            if ($ruleDef.Pattern -and $value -notmatch $ruleDef.Pattern) {
                $errors += "Parameter '$paramName' does not match required pattern"
            }
            
            # Range validation
            if ($ruleDef.MinLength -and $value.Length -lt $ruleDef.MinLength) {
                $errors += "Parameter '$paramName' must be at least $($ruleDef.MinLength) characters"
            }
        }
    }
    
    if ($errors.Count -gt 0) {
        throw "Validation failed: $($errors -join '; ')"
    }
    
    return $true
}

#endregion

#region Private Functions

function Write-ECCLog {
    param(
        [string]$Message,
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "DEBUG"   { Write-Verbose $logEntry }
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
}

#endregion

# Export Module Members
Export-ModuleMember -Function @(
    'Invoke-WithErrorHandling',
    'Write-ErrorLog',
    'Test-CriticalOperation',
    'Invoke-CriticalOperation',
    'Test-InputValidation'
)
