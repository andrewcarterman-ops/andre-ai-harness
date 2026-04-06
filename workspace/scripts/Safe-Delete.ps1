#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [string]$Path,
    [switch]$Permanent
)

process {
    $ResolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    if (-not (Test-Path $ResolvedPath)) { Write-Warning "Nicht gefunden: $ResolvedPath"; return }
    
    if ($Permanent) { Remove-Item $ResolvedPath -Force; Write-Host "✓ Permanent geloescht" -ForegroundColor Yellow; return }
    
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceDir = Split-Path -Parent $scriptDir
    $RustBinary = Join-Path $workspaceDir "target\release\openclaw-core.exe"
    
    if (Test-Path $RustBinary) {
        $Output = & $RustBinary delete "$ResolvedPath" 2>&1
        if ($LASTEXITCODE -eq 0) { Write-Host $Output -ForegroundColor Green; return }
    }
    
    # Fallback
    $DeletedDir = Join-Path (Split-Path $ResolvedPath) ".deleted"
    if (-not (Test-Path $DeletedDir)) { New-Item -ItemType Directory $DeletedDir -Force | Out-Null; (Get-Item $DeletedDir -Force).Attributes = 'Hidden' }
    $DeletedName = ([System.IO.Path]::GetFileName($ResolvedPath) + "." + (Get-Date -Format "yyyyMMdd-HHmmss"))
    Move-Item $ResolvedPath (Join-Path $DeletedDir $DeletedName) -Force
    Write-Host "✓ Sicher geloescht → .deleted/" -ForegroundColor Green
}
