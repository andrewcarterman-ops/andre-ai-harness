#Requires -Version 7.0
<#
.SYNOPSIS
    Registry-Setup für OpenClaw-Obsidian Sync

.DESCRIPTION
    Dieses Skript erstellt die Registry-Struktur für OpenClaw-Sessions
    und kann Test-Daten einfügen.

.PARAMETER CreateTestData
    Erstellt Test-Sessions in der Registry

.PARAMETER ClearExisting
    Löscht bestehende Registry-Einträge

.EXAMPLE
    .\setup-registry.ps1 -CreateTestData
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$CreateTestData,
    
    [Parameter(Mandatory = $false)]
    [switch]$ClearExisting,
    
    [Parameter(Mandatory = $false)]
    [string]$RegistryPath = "HKCU:\Software\OpenClaw\Sessions"
)

function Write-SetupLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $colorMap = @{ "INFO" = "White"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green" }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

# Registry-Pfad erstellen
function Initialize-RegistryPath {
    param([string]$Path)
    
    $parts = $Path -split '\\'
    $currentPath = ""
    
    foreach ($part in $parts) {
        if ($currentPath -eq "") {
            $currentPath = $part
        }
        else {
            $currentPath = "$currentPath\$part"
        }
        
        if (!(Test-Path $currentPath)) {
            try {
                New-Item -Path $currentPath -Force | Out-Null
                Write-SetupLog "Created: $currentPath" -Level "SUCCESS"
            }
            catch {
                Write-SetupLog "Failed to create $currentPath : $($_.Exception.Message)" -Level "ERROR"
                return $false
            }
        }
    }
    
    return $true
}

# Test-Session erstellen
function New-TestSession {
    param(
        [string]$SessionId,
        [string]$Title,
        [string]$Project = "Default",
        [string]$PreviousSessionId = ""
    )
    
    $sessionPath = "$RegistryPath\$SessionId"
    
    try {
        New-Item -Path $sessionPath -Force | Out-Null
        
        $properties = @{
            SessionId = $SessionId
            Title = $Title
            Description = "Test session for $Title"
            CreatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            UpdatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            TokenUsage = Get-Random -Minimum 1000 -Maximum 10000
            Cost = [math]::Round((Get-Random -Minimum 0.1 -Maximum 5.0), 2)
            Model = @("gpt-4", "gpt-4-turbo", "claude-3-opus") | Get-Random
            Project = $Project
            Tags = "ai,sync,test,$Project"
            Status = @("active", "completed") | Get-Random
            Content = @"
# $Title

Dies ist ein Test-Inhalt für die Session.

## Code-Beispiel

```powershell
Write-Host "Hello from $Title"
Get-Process | Select-Object -First 5
```

## TODOs
- [ ] Task 1 für $Title
- [ ] Task 2 für $Title
- [x] Abgeschlossener Task

## Entscheidungen
- Entscheidung A: Wir verwenden PowerShell
- Entscheidung B: Integration mit Obsidian
"@
            Decisions = "Entscheidung A: PowerShell verwenden`nEntscheidung B: Obsidian Integration"
            Todos = "Task 1 erledigen`nTask 2 erledigen`nDokumentation aktualisieren"
            CodeBlocks = "1"
            PreviousSessionId = $PreviousSessionId
            RelatedSessions = ""
        }
        
        foreach ($prop in $properties.GetEnumerator()) {
            Set-ItemProperty -Path $sessionPath -Name $prop.Key -Value $prop.Value
        }
        
        Write-SetupLog "Created test session: $SessionId" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-SetupLog "Failed to create session $SessionId : $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Hauptprogramm
Write-SetupLog "========================================"
Write-SetupLog "OpenClaw Registry Setup"
Write-SetupLog "========================================"
Write-SetupLog "Registry Path: $RegistryPath"

# Löschen falls gewünscht
if ($ClearExisting -and (Test-Path $RegistryPath)) {
    Write-SetupLog "Clearing existing registry entries..."
    Remove-Item -Path $RegistryPath -Recurse -Force
    Write-SetupLog "Registry cleared" -Level "SUCCESS"
}

# Registry-Pfad initialisieren
Write-SetupLog "Initializing registry path..."
if (!(Initialize-RegistryPath -Path $RegistryPath)) {
    Write-SetupLog "Failed to initialize registry path" -Level "ERROR"
    exit 1
}

# Test-Daten erstellen
if ($CreateTestData) {
    Write-SetupLog "Creating test data..."
    
    $testSessions = @(
        @{ Id = "sess_001"; Title = "Initial Setup"; Project = "Infrastructure"; Prev = "" }
        @{ Id = "sess_002"; Title = "API Integration"; Project = "Backend"; Prev = "sess_001" }
        @{ Id = "sess_003"; Title = "Frontend Design"; Project = "Frontend"; Prev = "sess_002" }
        @{ Id = "sess_004"; Title = "Database Schema"; Project = "Backend"; Prev = "sess_002" }
        @{ Id = "sess_005"; Title = "Testing Strategy"; Project = "QA"; Prev = "sess_003" }
    )
    
    foreach ($session in $testSessions) {
        New-TestSession `
            -SessionId $session.Id `
            -Title $session.Title `
            -Project $session.Project `
            -PreviousSessionId $session.Prev
    }
    
    Write-SetupLog "Test data created successfully" -Level "SUCCESS"
}

# Zusammenfassung
Write-SetupLog "========================================"
Write-SetupLog "Setup Complete!"
Write-SetupLog "========================================"

if (Test-Path $RegistryPath) {
    $sessions = Get-ChildItem -Path $RegistryPath
    Write-SetupLog "Sessions in registry: $($sessions.Count)"
}
