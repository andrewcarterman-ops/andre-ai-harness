# Autoresearch Fort Knox - Master Setup Skript
# Führt alle Sicherheitsmaßnahmen zusammen

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "setup",  # setup, run, stop, status
    
    [Parameter(Mandatory=$false)]
    [string]$ExperimentName = "overnight-test",
    
    [Parameter(Mandatory=$false)]
    [string]$AutoresearchPath = "C:\Autoresearch\autoresearch",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxRuntimeHours = 6
)

# ============================================================================
# KONFIGURATION
# ============================================================================

$Config = @{
    UserName = "autoresearch"
    BasePath = "C:\Autoresearch"
    GuardianPath = "$PSScriptRoot\autoresearch_guardian.py"
    SafetyCheckerPath = "$PSScriptRoot\ecc_safety_checker.py"
    LogPath = "C:\Autoresearch\logs"
    BackupPath = "C:\Autoresearch\backups"
    
    # Limits (konservativer als nötig)
    MaxRuntimeMinutes = $MaxRuntimeHours * 60
    MaxMemoryGB = 48
    MaxDiskGB = 8
    MaxCpuPercent = 80
}

# ============================================================================
# FARBDEFINITIONEN
# ============================================================================

$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Debug = "Gray"
}

function Write-Status {
    param([string]$Message, [string]$Level = "Info")
    $color = $Colors[$Level]
    Write-Host $Message -ForegroundColor $color
}

# ============================================================================
# SETUP FUNKTIONEN
# ============================================================================

function Initialize-FortKnox {
    Write-Status "🏰 Initialisiere Autoresearch Fort Knox..." "Info"
    Write-Status "============================================" "Info"
    
    # 1. Prüfe Admin-Rechte
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Status "❌ Dieses Skript benötigt Administrator-Rechte!" "Error"
        Write-Status "   Bitte als Administrator ausführen." "Error"
        exit 1
    }
    
    # 2. Erstelle Verzeichnisstruktur
    Write-Status "`n📁 Erstelle Verzeichnisse..." "Debug"
    @($Config.BasePath, $Config.LogPath, $Config.BackupPath, "$($Config.BasePath)\isolated") | ForEach-Object {
        if (!(Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-Status "   ✓ $_" "Success"
        }
    }
    
    # 3. Erstelle isolierten User (falls nicht existiert)
    Write-Status "`n👤 Erstelle isolierten User-Account..." "Debug"
    $user = Get-LocalUser -Name $Config.UserName -ErrorAction SilentlyContinue
    if (-not $user) {
        $password = -join ((33..126) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        New-LocalUser -Name $Config.UserName -Password $securePassword -Description "Isolated autoresearch account" | Out-Null
        Write-Status "   ✓ User '$($Config.UserName)' erstellt" "Success"
        Write-Status "   ⚠️  Passwort: $password (bitte notieren!)" "Warning"
    } else {
        Write-Status "   ℹ️  User existiert bereits" "Debug"
    }
    
    # 4. Setze Berechtigungen
    Write-Status "`n🔒 Setze Berechtigungen..." "Debug"
    $acl = Get-Acl $Config.BasePath
    $acl.SetAccessRuleProtection($true, $false)
    
    # Autoresearch-User darf alles
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Config.UserName, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $acl.SetAccessRule($rule)
    Set-Acl $Config.BasePath $acl
    Write-Status "   ✓ Berechtigungen gesetzt" "Success"
    
    # 5. Firewall-Regeln
    Write-Status "`n🧱 Konfiguriere Firewall..." "Debug"
    
    # Lösche alte Regeln
    Get-NetFirewallRule -DisplayName "Autoresearch-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    
    # Blockiere alles
    New-NetFirewallRule -DisplayName "Autoresearch-Block-All" `
        -Direction Outbound `
        -Action Block `
        -LocalUser "autoresearch" `
        -Enabled True | Out-Null
    
    # Erlaube nur spezifische Hosts
    $allowedHosts = @(
        "huggingface.co",
        "cdn.huggingface.co",
        "download.pytorch.org",
        "files.pythonhosted.org"
    )
    
    foreach ($host in $allowedHosts) {
        try {
            $ips = [System.Net.Dns]::GetHostAddresses($host) | Where-Object { $_.AddressFamily -eq "InterNetwork" }
            foreach ($ip in $ips) {
                New-NetFirewallRule -DisplayName "Autoresearch-Allow-$host" `
                    -Direction Outbound `
                    -RemoteAddress $ip.IPAddressToString `
                    -Action Allow `
                    -LocalUser "autoresearch" | Out-Null
            }
            Write-Status "   ✓ $host erlaubt" "Success"
        } catch {
            Write-Status "   ⚠️  $host konnte nicht konfiguriert werden" "Warning"
        }
    }
    
    # 6. Erstelle Guardian-Konfiguration
    Write-Status "`n⚙️  Erstelle Guardian-Konfiguration..." "Debug"
    $guardianConfig = @{
        max_runtime_minutes = $Config.MaxRuntimeMinutes
        max_memory_gb = $Config.MaxMemoryGB
        max_disk_gb = $Config.MaxDiskGB
        max_cpu_percent = $Config.MaxCpuPercent
        allowed_network_hosts = @("huggingface.co", "download.pytorch.org")
        check_interval_seconds = 10
        notification_webhook = $null  # Hier Discord/Slack webhook einfügen
    } | ConvertTo-Json -Depth 3
    
    $guardianConfig | Set-Content "$($Config.BasePath)\guardian_config.json" -Encoding UTF8
    Write-Status "   ✓ Guardian-Config erstellt" "Success"
    
    # 7. Kopiere Tools
    Write-Status "`n🛠️  Installiere Tools..." "Debug"
    Copy-Item $Config.GuardianPath "$($Config.BasePath)\autoresearch_guardian.py" -Force
    Copy-Item $Config.SafetyCheckerPath "$($Config.BasePath)\ecc_safety_checker.py" -Force
    Write-Status "   ✓ Tools kopiert" "Success"
    
    # 8. Erstelle Wrapper-Skript
    Write-Status "`n📝 Erstelle Wrapper-Skript..." "Debug"
    $wrapper = @"
# Autoresearch Fort Knox Wrapper
# Dieses Skript wird vom isolierten User ausgeführt

`$ErrorActionPreference = "Stop"

# Laufzeit-Tracking
`$startTime = Get-Date
`$maxRuntime = $($Config.MaxRuntimeMinutes)

Write-Host "🚀 Autoresearch Fort Knox gestartet"
Write-Host "   Experiment: $ExperimentName"
Write-Host "   Max Runtime: `$maxRuntime Minuten"
Write-Host "   Start: `$(`$startTime)"

# Pre-flight Safety Check
Write-Host "`n🔍 Führe Safety-Check durch..."
python.exe "$($Config.BasePath)\ecc_safety_checker.py" --file "$AutoresearchPath\train.py" --format json
if (`$LASTEXITCODE -ne 0) {
    Write-Error "❌ Safety-Check fehlgeschlagen! Experiment abgebrochen."
    exit 1
}
Write-Host "✅ Safety-Check bestanden"

# Starte Guardian im Hintergrund
Write-Host "`n🛡️  Starte Guardian..."
Start-Process python.exe -ArgumentList "`"$($Config.BasePath)\autoresearch_guardian.py`" --train-command `"uv run train.py`"" -WindowStyle Hidden

# Führe Experiment aus
Write-Host "`n🔬 Starte Experiment..."
cd "$AutoresearchPath"
uv run train.py

Write-Host "`n✅ Experiment abgeschlossen"
"@
    
    $wrapper | Set-Content "$($Config.BasePath)\run_isolated.ps1" -Encoding UTF8
    Write-Status "   ✓ Wrapper erstellt" "Success"
    
    Write-Status "`n✅ Fort Knox Setup abgeschlossen!" "Success"
    Write-Status "   Base Path: $($Config.BasePath)" "Info"
    Write-Status "   User: $($Config.UserName)" "Info"
    Write-Status "   Starten mit: .\FortKnox-Autoresearch.ps1 -Action run" "Info"
}

# ============================================================================
# RUN FUNKTION
# ============================================================================

function Start-FortKnoxExperiment {
    Write-Status "🚀 Starte isoliertes Experiment..." "Info"
    
    # 1. Erstelle Backup
    Write-Status "`n💾 Erstelle Backup..." "Debug"
    $backupName = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $AutoresearchPath "$($Config.BackupPath)\$backupName" -Recurse -Force
    Write-Status "   ✓ Backup: $backupName" "Success"
    
    # 2. Safety-Check
    Write-Status "`n🔍 Pre-Flight Safety-Check..." "Debug"
    $safetyResult = & python.exe $Config.SafetyCheckerPath --file "$AutoresearchPath\train.py" --format json 2>$null | ConvertFrom-Json
    
    if ($safetyResult.overall_score -lt 80) {
        Write-Status "❌ Safety-Check fehlgeschlagen!" "Error"
        Write-Status "   Score: $($safetyResult.overall_score)/100" "Error"
        Write-Status "   Violations: $($safetyResult.violations.Count)" "Error"
        
        # Zeige Violations
        $safetyResult.violations | Where-Object { $_.severity -in @("CRITICAL", "HIGH") } | ForEach-Object {
            Write-Status "   🔴 [$($_.severity)] $($_.message) (Line $($_.line))" "Error"
        }
        
        exit 1
    }
    Write-Status "   ✅ Safety-Score: $($safetyResult.overall_score)/100" "Success"
    
    # 3. Starte als isolierter User
    Write-Status "`n🔬 Starte Experiment als isolierter User..." "Debug"
    
    $credential = Get-Credential -UserName $Config.UserName -Message "Bitte Passwort für $($Config.UserName) eingeben"
    
    $job = Start-Job -ScriptBlock {
        param($Path, $UserName)
        
        # Hier würde der tatsächliche Prozess-Start kommen
        # Für Test: Einfach eine Datei erstellen
        "Experiment gestartet am $(Get-Date)" | Set-Content "C:\Autoresearch\experiment.log"
        
    } -ArgumentList $AutoresearchPath, $Config.UserName -Credential $credential
    
    Write-Status "   ✅ Experiment gestartet (Job ID: $($job.Id))" "Success"
    
    # 4. Zeige Status
    Write-Status "`n📊 Status:" "Info"
    Write-Status "   Log-Datei: C:\Autoresearch\experiment.log" "Info"
    Write-Status "   Guardian: C:\Autoresearch\guardian_status.log" "Info"
    Write-Status "   Überwache mit: Get-Job -Id $($job.Id)" "Info"
    
    Write-Status "`n💡 Tipps:" "Info"
    Write-Status "   - Überwache Logs: Get-Content C:\Autoresearch\experiment.log -Wait" "Debug"
    Write-Status "   - Status prüfen: .\FortKnox-Autoresearch.ps1 -Action status" "Debug"
    Write-Status "   - Stoppen: .\FortKnox-Autoresearch.ps1 -Action stop" "Debug"
}

# ============================================================================
# STATUS FUNKTION
# ============================================================================

function Get-FortKnoxStatus {
    Write-Status "📊 Fort Knox Status" "Info"
    Write-Status "==================" "Info"
    
    # Prüfe ob Prozess läuft
    $process = Get-Process -Name "python" -ErrorAction SilentlyContinue | 
               Where-Object { $_.CommandLine -like "*train.py*" }
    
    if ($process) {
        Write-Status "   🟢 Experiment läuft" "Success"
        Write-Status "   PID: $($process.Id)" "Info"
        Write-Status "   Laufzeit: $([math]::Round(($process.TotalProcessorTime).TotalMinutes, 1)) Min" "Info"
        Write-Status "   Speicher: $([math]::Round($process.WorkingSet64 / 1GB, 2)) GB" "Info"
    } else {
        Write-Status "   🔴 Kein Experiment aktiv" "Warning"
    }
    
    # Zeige letzte Logs
    if (Test-Path "$($Config.BasePath)\guardian_status.log") {
        Write-Status "`n🛡️  Guardian Status (letzte 5 Zeilen):" "Info"
        Get-Content "$($Config.BasePath)\guardian_status.log" -Tail 5 | ForEach-Object {
            Write-Status "   $_" "Debug"
        }
    }
    
    # Zeige Incidents
    if (Test-Path "$($Config.BasePath)\guardian_incidents.log") {
        $incidents = Get-Content "$($Config.BasePath)\guardian_incidents.log" | ConvertFrom-Json
        if ($incidents) {
            Write-Status "`n🚨 Incidents: $($incidents.Count)" "Warning"
        }
    }
}

# ============================================================================
# STOP FUNKTION
# ============================================================================

function Stop-FortKnoxExperiment {
    Write-Status "🛑 Stoppe Experiment..." "Warning"
    
    # Finde Prozesse
    $processes = Get-Process -Name "python" -ErrorAction SilentlyContinue | 
                 Where-Object { $_.CommandLine -like "*train.py*" -or $_.CommandLine -like "*guardian*" }
    
    foreach ($proc in $processes) {
        Write-Status "   Beende PID $($proc.Id)..." "Debug"
        Stop-Process -Id $proc.Id -Force
    }
    
    Write-Status "✅ Experiment gestoppt" "Success"
}

# ============================================================================
# HAUPTPROGRAMM
# ============================================================================

switch ($Action) {
    "setup" { Initialize-FortKnox }
    "run" { Start-FortKnoxExperiment }
    "status" { Get-FortKnoxStatus }
    "stop" { Stop-FortKnoxExperiment }
    default { 
        Write-Status "Unbekannte Aktion: $Action" "Error"
        Write-Status "Verwendung: .\FortKnox-Autoresearch.ps1 -Action [setup|run|status|stop]" "Info"
    }
}
