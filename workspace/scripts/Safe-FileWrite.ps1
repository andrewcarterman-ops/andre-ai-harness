#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,
    
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
    [string]$Content,
    
    [Parameter()]
    [string]$Encoding = UTF8
)

begin {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceDir = Split-Path -Parent $scriptDir
    $RustBinary = Join-Path $workspaceDir target\release\openclaw-core.exe
    $AllContent = @()
}

process { $AllContent += $Content }

end {
    $FullContent = $AllContent -join `n
    $ResolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $Directory = Split-Path -Parent $ResolvedPath
    
    if ($Directory -and -not (Test-Path $Directory)) {
        New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    }
    
    if (Test-Path $RustBinary) {
        $Output = & $RustBinary write $ResolvedPath $FullContent 2>&1
        if ($LASTEXITCODE -eq 0) { Write-Host $Output -ForegroundColor Green; return }
    }
    
    # Fallback
    $TempPath = $ResolvedPath.tmp
    if (Test-Path $ResolvedPath) {
        $Timestamp = Get-Date -Format yyyyMMdd-HHmmss
        $BackupName = ([System.IO.Path]::GetFileNameWithoutExtension($ResolvedPath) + .$Timestamp. + [System.IO.Path]::GetExtension($ResolvedPath).TrimStart('.'))
        Copy-Item $ResolvedPath (Join-Path (Split-Path $ResolvedPath) $BackupName) -Force
    }
    $FullContent | Safe-FileWrite -Path $TempPath -Encoding $Encoding -Force
    if (Test-Path $ResolvedPath) { Remove-Item $ResolvedPath -Force }
    Move-Item $TempPath $ResolvedPath -Force
    Write-Host ✓