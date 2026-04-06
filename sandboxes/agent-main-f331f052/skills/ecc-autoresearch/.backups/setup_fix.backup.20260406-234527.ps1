# Fort Knox Setup - Fix Berechtigungen
# Führt fehlende Schritte nach

param()

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Administrator required!"
    exit 1
}

$BasePath = "C:\Autoresearch"
$UserName = "autoresearch"
$ScriptSource = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Fort Knox Setup Fix..." -ForegroundColor Cyan

# 1. Fix Berechtigungen (aktuellem Admin User Schreibrechte geben)
Write-Host "Fixing permissions..."
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$acl = Get-Acl $BasePath

# Admin bekommt temporär FullControl
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $currentUser, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.AddAccessRule($adminRule)
Set-Acl $BasePath $acl
Write-Host "  Added write permissions for $currentUser"

# 2. Dateien kopieren
Write-Host "Copying files..."
try {
    Copy-Item "$ScriptSource\autoresearch_guardian.py" "$BasePath\" -Force
    Copy-Item "$ScriptSource\ecc_safety_checker.py" "$BasePath\" -Force
    Write-Host "  Copied guardian tools"
} catch {
    Write-Host "  ERROR copying: $_" -ForegroundColor Red
    exit 1
}

# 3. Guardian Config erstellen
$guardianConfig = @"
{
    "max_runtime_minutes": 360,
    "max_memory_gb": 48,
    "max_disk_gb": 8,
    "max_cpu_percent": 80,
    "allowed_network_hosts": ["huggingface.co", "download.pytorch.org"],
    "check_interval_seconds": 10
}
"@

$guardianConfig | Set-Content "$BasePath\guardian_config.json" -Encoding UTF8
Write-Host "  Created guardian_config.json"

# 4. Berechtigungen final setzen (autoresearch-User hat Full, Admin nur Read)
Write-Host "Setting final permissions..."
$acl = Get-Acl $BasePath

# Entferne Admin-Write-Regel
$acl.RemoveAccessRule($adminRule)

# autoresearch-User hat FullControl
$autoresearchRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $UserName, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.SetAccessRule($autoresearchRule)

# Admins haben Read
$adminReadRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrators", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.AddAccessRule($adminReadRule)

Set-Acl $BasePath $acl
Write-Host "  Permissions set: autoresearch=Full, Administrators=Read"

# 5. Firewall Fix (ohne reserved word)
Write-Host "Fixing firewall..."
$allowedHosts = @("huggingface.co", "download.pytorch.org", "pypi.org", "files.pythonhosted.org")
foreach ($hostname in $allowedHosts) {
    try {
        $ips = [System.Net.Dns]::GetHostAddresses($hostname) | Where-Object { $_.AddressFamily -eq "InterNetwork" }
        foreach ($ip in $ips) {
            $ruleName = "Autoresearch-Allow-$hostname-$($ip.IPAddressToString)"
            # Prüfe ob Regel schon existiert
            $existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
            if (-not $existing) {
                New-NetFirewallRule -DisplayName $ruleName `
                    -Direction Outbound `
                    -RemoteAddress $ip.IPAddressToString `
                    -Action Allow | Out-Null
            }
        }
        Write-Host "  Allowed: $hostname"
    } catch {
        Write-Host "  Warning: Could not configure $hostname"
    }
}

# 6. Verifizierung
Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Cyan

$files = @(
    "$BasePath\autoresearch_guardian.py",
    "$BasePath\ecc_safety_checker.py",
    "$BasePath\guardian_config.json"
)

$allOk = $true
foreach ($file in $files) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        Write-Host "  OK: $file ($size bytes)"
    } else {
        Write-Host "  MISSING: $file" -ForegroundColor Red
        $allOk = $false
    }
}

if ($allOk) {
    Write-Host ""
    Write-Host "SETUP COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Password for user '$UserName':"
    Write-Host "  Check previous output or reset with:"
    Write-Host "  net user $UserName *"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Copy autoresearch repository to: $BasePath\autoresearch\"
    Write-Host "  2. Change to directory: cd $BasePath"
    Write-Host "  3. Test guardian: python autoresearch_guardian.py --train-command 'uv run train.py'"
    Write-Host ""
    Write-Host "To run isolated as autoresearch user:"
    Write-Host "  runas /user:$UserName powershell.exe"
} else {
    Write-Host ""
    Write-Host "ERRORS detected! Some files are missing." -ForegroundColor Red
}
