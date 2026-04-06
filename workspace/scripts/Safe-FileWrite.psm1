function Safe-FileWrite {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [string]$Content,
        
        [Parameter()]
        [string]$Encoding = "UTF8"
    )

    begin {
        $scriptDir = Split-Path -Parent $PSScriptRoot
        $RustBinary = Join-Path $scriptDir "target\release\openclaw-core.exe"
        $AllContent = @()
    }

    process { $AllContent += $Content }

    end {
        $FullContent = $AllContent -join "`n"
        $ResolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $Directory = Split-Path -Parent $ResolvedPath
        
        if ($Directory -and -not (Test-Path $Directory)) {
            New-Item -ItemType Directory -Path $Directory -Force | Out-Null
        }
        
        if (Test-Path $RustBinary) {
            $Output = & $RustBinary write "$ResolvedPath" "$FullContent" 2>&1
            if ($LASTEXITCODE -eq 0) { 
                Write-Host $Output -ForegroundColor Green
                return 
            }
        }
        
        # Fallback
        $TempPath = "$ResolvedPath.tmp"
        if (Test-Path $ResolvedPath) {
            $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $FileName = [System.IO.Path]::GetFileNameWithoutExtension($ResolvedPath)
            $Ext = [System.IO.Path]::GetExtension($ResolvedPath).TrimStart('.')
            $BackupPath = Join-Path (Split-Path $ResolvedPath) "$FileName.$Timestamp.$Ext"
            Copy-Item $ResolvedPath $BackupPath -Force
        }
        $FullContent | Out-File $TempPath -Encoding $Encoding -Force
        if (Test-Path $ResolvedPath) { Remove-Item $ResolvedPath -Force }
        Move-Item $TempPath $ResolvedPath -Force
        Write-Host "✓ Atomar geschrieben: $ResolvedPath" -ForegroundColor Green
    }
}
