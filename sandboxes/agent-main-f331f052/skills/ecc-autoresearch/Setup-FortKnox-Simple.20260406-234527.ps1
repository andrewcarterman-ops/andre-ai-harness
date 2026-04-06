# Fort Knox Setup - Korrigierte Version
# Führt alle Sicherheitsmaßnahmen zusammen

# Prüfe Admin-Rechte
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ Dieses Skript benötigt Administrator-Rechte!" -ForegroundColor Red
    exit 1
}

Write-Host "🏰 Starte Fort Knox Setup..." -ForegroundColor Cyan

# Konfiguration
$UserName = "autoresearch"
$BasePath = "C:\Autoresearch"
$LogPath = "$BasePath\logs"
$ScriptSource = $PSScriptRoot

Write-Host "`n📁 Erstelle Verzeichnisse..." -ForegroundColor Gray

# Verzeichnisse erstellen
@($BasePath, $LogPath, "$BasePath\backups") | ForEach-Object {
    if (!(Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Host "   ✓ $_" -ForegroundColor Green
    }
}

Write-Host "`n👤 Erstelle isolierten User..." -ForegroundColor Gray

# User erstellen
$user = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
if (-not $user) {
    $password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    New-LocalUser -Name $UserName -Password $securePassword -Description "Isolated autoresearch account" | Out-Null
    Write-Host "   ✓ User '$UserName' erstellt" -ForegroundColor Green
    Write-Host "   ⚠️  Passwort: $password" -ForegroundColor Yellow
    Write-Host "   (Bitte in Passwort-Manager speichern!)" -ForegroundColor Yellow
} else {
    Write-Host "   ℹ️  User existiert bereits" -ForegroundColor Gray
}

Write-Host "`n🔒 Setze Berechtigungen..." -ForegroundColor Gray

# Berechtigungen
$acl = Get-Acl $BasePath
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $UserName, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.SetAccessRule($rule)
Set-Acl $BasePath $acl
Write-Host "   ✓ Berechtigungen gesetzt" -ForegroundColor Green

Write-Host "`n🧱 Konfiguriere Firewall..." -ForegroundColor Gray

# Firewall-Regeln
Get-NetFirewallRule -DisplayName "Autoresearch-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

New-NetFirewallRule -DisplayName "Autoresearch-Block-All" `
    -Direction Outbound `
    -Action Block `
    -LocalUser $UserName `
    -Enabled True | Out-Null

$allowedHosts = @("huggingface.co", "download.pytorch.org")
foreach ($host in $allowedHosts) {
    try {
        $ips = [System.Net.Dns]::GetHostAddresses($host) | Where-Object { $_.AddressFamily -eq "InterNetwork" }
        foreach ($ip in $ips) {
            New-NetFirewallRule -DisplayName "Autoresearch-Allow-$host" `
                -Direction Outbound `
                -RemoteAddress $ip.IPAddressToString `
                -Action Allow `
                -LocalUser $UserName | Out-Null
        }
        Write-Host "   ✓ $host erlaubt" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  $host nicht konfiguriert" -ForegroundColor Yellow
    }
}

Write-Host "`n🛠️ Kopiere Tools..." -ForegroundColor Gray

# Dateien kopieren
Copy-Item "$ScriptSource\autoresearch_guardian.py" "$BasePath\" -Force
Copy-Item "$ScriptSource\ecc_safety_checker.py" "$BasePath\" -Force
Copy-Item "$ScriptSource\FortKnox-Autoresearch.ps1" "$BasePath\" -Force

# Guardian-Config erstellen
$guardianConfig = @{
    max_runtime_minutes = 360
    max_memory_gb = 48
    max_disk_gb = 8
    max_cpu_percent = 80
    allowed_network_hosts = @("huggingface.co", "download.pytorch.org")
    check_interval_seconds = 10
} | ConvertTo-Json

$guardianConfig | Set-Content "$BasePath\guardian_config.json" -Encoding UTF8

Write-Host "   ✓ Tools kopiert" -ForegroundColor Green

Write-Host "`n✅ Fort Knox Setup abgeschlossen!" -ForegroundColor Green
Write-Host "`nNächste Schritte:" -ForegroundColor Cyan
Write-Host "   1. Kopiere autoresearch nach: $BasePath\autoresearch\" -ForegroundColor White
Write-Host "   2. Teste mit: .\FortKnox-Autoresearch.ps1 -Action run -MaxRuntimeHours 0.1" -ForegroundColor White
Write-Host "`nWichtige Pfade:" -ForegroundColor Gray
Write-Host "   Base: $BasePath" -ForegroundColor Gray
Write-Host "   Logs: $LogPath" -ForegroundColor Gray
