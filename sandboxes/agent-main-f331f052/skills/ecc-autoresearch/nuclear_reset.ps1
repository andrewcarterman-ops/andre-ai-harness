# Fort Knox - Nuclear Reset
# Loescht ALLES und baut sauber neu auf

param(
    [switch]$Force
)

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Administrator required!" -ForegroundColor Red
    exit 1
}

$UserName = "autoresearch"
$BasePath = "C:\Autoresearch"

Write-Host "FORT KNOX NUCLEAR RESET" -ForegroundColor Red
Write-Host "=======================" -ForegroundColor Red
Write-Host ""

if (-not $Force) {
    Write-Host "WARNING: This will DELETE everything in $BasePath" -ForegroundColor Yellow
    Write-Host "and recreate with correct permissions." -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Type 'NUCLEAR' to confirm"
    if ($confirm -ne "NUCLEAR") {
        Write-Host "Aborted." -ForegroundColor Gray
        exit 0
    }
}

# 1. ALLES loeschen
Write-Host "Step 1: Cleaning up..." -ForegroundColor Cyan

# Firewall rules
Get-NetFirewallRule -DisplayName "Autoresearch-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
Write-Host "  Removed firewall rules"

# User (optional - behalten wir, sonst geht Passwort verloren)
# $user = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
# if ($user) { Remove-LocalUser -Name $UserName }

# Verzeichnis komplett loeschen
if (Test-Path $BasePath) {
    # Zuerst Berechtigungen zuruecksetzen (takeown)
    takeown /F "$BasePath" /R /D Y 2>$null | Out-Null
    icacls "$BasePath" /grant "$env:USERNAME:(OI)(CI)F" /T 2>$null | Out-Null
    
    # Dann loeschen
    Remove-Item -Path $BasePath -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $BasePath) {
        # Wenn immer noch da, robocopy Trick
        $empty = "C:\Windows\Temp\empty_$([Guid]::NewGuid())"
        New-Item -ItemType Directory -Path $empty | Out-Null
        robocopy $empty $BasePath /MIR /NFL /NDL /NJH /NJS 2>$null | Out-Null
        Remove-Item -Path $BasePath -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $empty -Recurse -Force
    }
}

Write-Host "  Deleted $BasePath"

# 2. NEU aufbauen mit korrekten Berechtigungen
Write-Host ""
Write-Host "Step 2: Building fresh..." -ForegroundColor Cyan

# Verzeichnis erstellen (als Admin)
New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
Write-Host "  Created $BasePath"

# Berechtigungen korrekt setzen (von Anfang an!)
$acl = Get-Acl $BasePath

# Remove inherited
$acl.SetAccessRuleProtection($true, $false)

# Admins: FullControl
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.AddAccessRule($adminRule)

# System: FullControl
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.AddAccessRule($systemRule)

# Autoresearch-User: FullControl
$userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $UserName, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.AddAccessRule($userRule)

# Creator (du): FullControl
currentRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.AddAccessRule($currentRule)

Set-Acl $BasePath $acl
Write-Host "  Set correct permissions"

# Sub-Verzeichnisse
New-Item -ItemType Directory -Path "$BasePath\logs" -Force | Out-Null
New-Item -ItemType Directory -Path "$BasePath\backups" -Force | Out-Null
New-Item -ItemType Directory -Path "$BasePath\autoresearch" -Force | Out-Null
Write-Host "  Created subdirectories"

# 3. Dateien kopieren
Write-Host ""
Write-Host "Step 3: Installing tools..." -ForegroundColor Cyan

$ScriptSource = Split-Path -Parent $MyInvocation.MyCommand.Path

Copy-Item "$ScriptSource\autoresearch_guardian.py" "$BasePath\" -Force
Copy-Item "$ScriptSource\ecc_safety_checker.py" "$BasePath\" -Force
Write-Host "  Copied guardian tools"

# Config erstellen
$config = @"
{
    "max_runtime_minutes": 360,
    "max_memory_gb": 48,
    "max_disk_gb": 8,
    "max_cpu_percent": 80,
    "allowed_network_hosts": ["huggingface.co", "download.pytorch.org"],
    "check_interval_seconds": 10
}
"@
$config | Set-Content "$BasePath\guardian_config.json" -Encoding UTF8
Write-Host "  Created config"

# 4. Firewall (vereinfacht - ohne PolicyAppId)
Write-Host ""
Write-Host "Step 4: Configuring firewall..." -ForegroundColor Cyan

# Outbound block fuer autoresearch-User
New-NetFirewallRule -DisplayName "Autoresearch-Block-Outbound" `
    -Direction Outbound `
    -Action Block `
    -LocalUser $UserName `
    -Enabled True | Out-Null

# Erlaubte Hosts (global, nicht User-spezifisch wegen komplexitaet)
$allowedHosts = @{
    "huggingface.co" = "99.84.191.33"
    "download.pytorch.org" = "52.85.49.34"
}

foreach ($host in $allowedHosts.GetEnumerator()) {
    try {
        New-NetFirewallRule -DisplayName "Autoresearch-Allow-$($host.Key)" `
            -Direction Outbound `
            -RemoteAddress $host.Value `
            -Action Allow | Out-Null
        Write-Host "  Allowed: $($host.Key)"
    } catch {
        Write-Host "  Warning: Could not add $($host.Key)"
    }
}

# 5. Verifikation
Write-Host ""
Write-Host "Step 5: Verification..." -ForegroundColor Cyan

$testFile = "$BasePath\test_write.tmp"
try {
    "test" | Set-Content $testFile -Force
    if (Test-Path $testFile) {
        Remove-Item $testFile -Force
        Write-Host "  Write test: PASSED"
    }
} catch {
    Write-Host "  Write test: FAILED - $_" -ForegroundColor Red
}

$files = @(
    "$BasePath\autoresearch_guardian.py",
    "$BasePath\ecc_safety_checker.py", 
    "$BasePath\guardian_config.json"
)

$allOk = $true
foreach ($file in $files) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        Write-Host "  File: $file ($size bytes)"
    } else {
        Write-Host "  MISSING: $file" -ForegroundColor Red
        $allOk = $false
    }
}

# 6. Finale Berechtigungen (Admin ReadOnly, autoresearch Full)
Write-Host ""
Write-Host "Step 6: Finalizing permissions..." -ForegroundColor Cyan

$acl = Get-Acl $BasePath

# Entferne Admin FullControl, setze ReadOnly
$acl.RemoveAccessRule($adminRule)
$adminReadRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrators", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.AddAccessRule($adminReadRule)

Set-Acl $BasePath $acl
Write-Host "  Final permissions set"

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "NUCLEAR RESET COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($allOk) {
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host ""
    Write-Host "Structure:"
    Get-ChildItem $BasePath -Recurse | ForEach-Object {
        $indent = "  " * ($_.FullName.Split("\").Count - 3)
        Write-Host "$indent$($_.Name)"
    }
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Download karpathy/autoresearch to:"
    Write-Host "     $BasePath\autoresearch\"
    Write-Host ""
    Write-Host "  2. Or clone: cd $BasePath\autoresearch; git clone https://github.com/karpathy/autoresearch.git ."
    Write-Host ""
    Write-Host "  3. Test the setup:"
    Write-Host "     cd $BasePath"
    Write-Host "     python autoresearch_guardian.py"
    Write-Host ""
    Write-Host "User '$UserName' password:"
    Write-Host "  (Check previous output or reset with: net user $UserName *)"
} else {
    Write-Host "Status: PARTIAL - Some files missing" -ForegroundColor Yellow
}
