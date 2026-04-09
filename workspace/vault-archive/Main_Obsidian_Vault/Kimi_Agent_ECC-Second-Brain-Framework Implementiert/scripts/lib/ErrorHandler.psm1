# ============================================================================
# ECC-CORE ErrorHandler Module
# Second-Brain Framework - Robust Error Handling with Retry Logic
# ============================================================================
#Requires -Version 5.1

<#
.SYNOPSIS
    Invokes a script block with comprehensive error handling and retry logic.

.DESCRIPTION
    Executes the provided script block with try-catch error handling,
    exponential backoff retry logic, and detailed logging.

.PARAMETER ScriptBlock
    The script block to execute.

.PARAMETER MaxRetries
    Maximum number of retry attempts (default: 3).

.PARAMETER InitialDelayMs
    Initial delay in milliseconds before first retry (default: 1000).

.PARAMETER BackoffMultiplier
    Multiplier for exponential backoff (default: 2).

.PARAMETER OperationName
    Name of the operation for logging purposes.

.PARAMETER Critical
    If set, operation failure throws terminating error.

.PARAMETER ContinueOnError
    If set, non-critical errors are silently continued.

.EXAMPLE
    Invoke-WithErrorHandling -ScriptBlock { Get-Process } -OperationName "ProcessList"

.EXAMPLE
    Invoke-WithErrorHandling -ScriptBlock { Invoke-RestMethod $uri } -MaxRetries 5 -Critical
#>
function Invoke-WithErrorHandling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [int]$MaxRetries = 3,

        [Parameter()]
        [int]$InitialDelayMs = 1000,

        [Parameter()]
        [double]$BackoffMultiplier = 2,

        [Parameter()]
        [string]$OperationName = "UnnamedOperation",

        [Parameter()]
        [switch]$Critical,

        [Parameter()]
        [switch]$ContinueOnError
    )

    $attempt = 0
    $delay = $InitialDelayMs
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        $attempt++
        
        try {
            Write-Verbose "[$OperationName] Attempt $attempt of $MaxRetries"
            
            # Execute the script block
            $result = & $ScriptBlock
            
            # Log success on retry
            if ($attempt -gt 1) {
                Write-ECCLog -Level "INFO" -Message "[$OperationName] Succeeded on attempt $attempt" -Source "ErrorHandler"
            }
            
            return $result
        }
        catch {
            $lastError = $_
            $errorMessage = $_.Exception.Message
            $errorType = $_.Exception.GetType().Name
            
            # Log the error
            Write-ECCLog -Level "WARN" -Message "[$OperationName] Attempt $attempt failed: $errorType - $errorMessage" -Source "ErrorHandler"
            
            # Check if we should retry
            if ($attempt -lt $MaxRetries) {
                Write-Verbose "[$OperationName] Waiting $delay ms before retry..."
                Start-Sleep -Milliseconds $delay
                $delay = [math]::Round($delay * $BackoffMultiplier)
            }
        }
    }

    # All retries exhausted
    $finalMessage = "[$OperationName] Failed after $MaxRetries attempts. Last error: $($lastError.Exception.Message)"
    Write-ECCLog -Level "ERROR" -Message $finalMessage -Source "ErrorHandler" -ErrorRecord $lastError

    if ($Critical) {
        throw $lastError
    }
    elseif (-not $ContinueOnError) {
        Write-Error $finalMessage -ErrorAction Continue
    }

    return $null
}

<#
.SYNOPSIS
    Writes detailed error information to the log.

.DESCRIPTION
    Logs error details including stack trace, inner exceptions,
    and contextual information for debugging.

.PARAMETER ErrorRecord
    The ErrorRecord object to log.

.PARAMETER Context
    Additional context information about where the error occurred.

.PARAMETER AdditionalInfo
    Hashtable of additional key-value pairs to log.
#>
function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter()]
        [string]$Context = "",

        [Parameter()]
        [hashtable]$AdditionalInfo = @{}
    )

    process {
        $errorDetails = @{
            Timestamp       = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            Message         = $ErrorRecord.Exception.Message
            ExceptionType   = $ErrorRecord.Exception.GetType().FullName
            TargetObject    = $ErrorRecord.TargetObject
            Category        = $ErrorRecord.CategoryInfo.Category
            Reason          = $ErrorRecord.CategoryInfo.Reason
            Line            = $ErrorRecord.InvocationInfo.ScriptLineNumber
            ScriptName      = $ErrorRecord.InvocationInfo.ScriptName
            Position        = $ErrorRecord.InvocationInfo.PositionMessage
            StackTrace      = $ErrorRecord.ScriptStackTrace
            Context         = $Context
        }

        # Add inner exception if present
        if ($ErrorRecord.Exception.InnerException) {
            $errorDetails['InnerException'] = $ErrorRecord.Exception.InnerException.Message
        }

        # Merge additional info
        foreach ($key in $AdditionalInfo.Keys) {
            $errorDetails[$key] = $AdditionalInfo[$key]
        }

        # Convert to JSON for structured logging
        $jsonLog = $errorDetails | ConvertTo-Json -Depth 3 -Compress

        Write-ECCLog -Level "ERROR" -Message $jsonLog -Source "ErrorLog"
    }
}

<#
.SYNOPSIS
    Tests if an operation is critical and should halt execution on failure.

.DESCRIPTION
    Evaluates whether a failure in the specified operation should
    be treated as critical based on configuration or context.

.PARAMETER OperationName
    Name of the operation to test.

.PARAMETER DefaultCritical
    Default criticality if not configured.

.OUTPUTS
    System.Boolean
#>
function Test-CriticalOperation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName,

        [Parameter()]
        [bool]$DefaultCritical = $false
    )

    # Define critical operations
    $criticalOperations = @(
        'Backup-Vault',
        'Restore-Vault',
        'Database-Migrate',
        'Config-Write',
        'Git-Commit-Push'
    )

    # Check if operation is in critical list
    $isCritical = $criticalOperations -contains $OperationName

    # Check environment variable override
    $envCritical = $env:ECC_CRITICAL_OPERATIONS -split ',' | ForEach-Object { $_.Trim() }
    if ($envCritical -contains $OperationName) {
        $isCritical = $true
    }

    # Check for non-critical override
    $envNonCritical = $env:ECC_NON_CRITICAL_OPERATIONS -split ',' | ForEach-Object { $_.Trim() }
    if ($envNonCritical -contains $OperationName) {
        $isCritical = $false
    }

    return $isCritical -or $DefaultCritical
}

<#
.SYNOPSIS
    Wraps a function call with automatic error handling.

.DESCRIPTION
    Creates a wrapper around any function that automatically applies
    error handling and retry logic.

.PARAMETER FunctionName
    Name of the function to wrap.

.PARAMETER Arguments
    Arguments to pass to the function.

.PARAMETER MaxRetries
    Maximum retry attempts.
#>
function Invoke-FunctionWithHandling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FunctionName,

        [Parameter()]
        [hashtable]$Arguments = @{},

        [Parameter()]
        [int]$MaxRetries = 3
    )

    $scriptBlock = {
        param($fn, $args)
        & $fn @args
    }

    $params = @{
        ScriptBlock    = $scriptBlock
        ArgumentList   = $FunctionName, $Arguments
        MaxRetries     = $MaxRetries
        OperationName  = $FunctionName
        Critical       = (Test-CriticalOperation -OperationName $FunctionName)
    }

    return Invoke-WithErrorHandling @params
}

<#
.SYNOPSIS
    Gets retry configuration from environment or defaults.

.DESCRIPTION
    Retrieves retry configuration values from environment variables
    or returns default values.

.OUTPUTS
    PSCustomObject with retry configuration
#>
function Get-RetryConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    return [PSCustomObject]@{
        MaxRetries         = if ($env:ECC_MAX_RETRIES) { [int]$env:ECC_MAX_RETRIES } else { 3 }
        InitialDelayMs     = if ($env:ECC_RETRY_DELAY_MS) { [int]$env:ECC_RETRY_DELAY_MS } else { 1000 }
        BackoffMultiplier  = if ($env:ECC_BACKOFF_MULTIPLIER) { [double]$env:ECC_BACKOFF_MULTIPLIER } else { 2 }
        MaxDelayMs         = if ($env:ECC_MAX_RETRY_DELAY_MS) { [int]$env:ECC_MAX_RETRY_DELAY_MS } else { 30000 }
        RetryableErrors    = if ($env:ECC_RETRYABLE_ERRORS) { $env:ECC_RETRYABLE_ERRORS -split ',' } else { @('IOException', 'WebException', 'TimeoutException') }
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Invoke-WithErrorHandling',
    'Write-ErrorLog',
    'Test-CriticalOperation',
    'Invoke-FunctionWithHandling',
    'Get-RetryConfiguration'
)
