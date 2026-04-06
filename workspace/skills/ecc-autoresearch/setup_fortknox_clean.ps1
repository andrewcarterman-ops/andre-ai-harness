# Fort Knox Setup - Ultra Simple (ASCII only)
param()

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Administrator required!"
    exit 1
}

Write-Host "Starting Fort Knox Setup..."

# Config
$UserName = "autoresearch"
$BasePath = "C:\Autoresearch"
$LogPath = "$BasePath\logs"

# Create directories
Write-Host "Creating directories..."
@($BasePath, $LogPath, "$BasePath\backups") | ForEach-Object {
    if (!(Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Host "  Created: $_"
    }
}

# Create user
Write-Host "Creating user..."
$user = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
if (-not $user) {
    $password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    New-LocalUser -Name $UserName -Password $securePassword -Description "Autoresearch account" | Out-Null
    Write-Host "  User created: $UserName"
    Write-Host "  PASSWORD: $password"
    Write-Host "  (Save this password!)"
} else {
    Write-Host "  User already exists"
}

# Set permissions
Write-Host "Setting permissions..."
$acl = Get-Acl $BasePath
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $UserName, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.SetAccessRule($rule)
Set-Acl $BasePath $acl
Write-Host "  Permissions set"

# Configure firewall
Write-Host "Configuring firewall..."
Get-NetFirewallRule -DisplayName "Autoresearch-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

New-NetFirewallRule -DisplayName "Autoresearch-Block-All" -Direction Outbound -Action Block -LocalUser $UserName -Enabled True | Out-Null

$allowedHosts = @("huggingface.co", "download.pytorch.org")
foreach ($host in $allowedHosts) {
    try {
        $ips = [System.Net.Dns]::GetHostAddresses($host) | Where-Object { $_.AddressFamily -eq "InterNetwork" }
        foreach ($ip in $ips) {
            New-NetFirewallRule -DisplayName "Autoresearch-Allow-$host" -Direction Outbound -RemoteAddress $ip.IPAddressToString -Action Allow -LocalUser $UserName | Out-Null
        }
        Write-Host "  Allowed: $host"
    } catch {
        Write-Host "  Warning: $host not configured"
    }
}

# Copy files
Write-Host "Copying tools..."
$ScriptSource = Split-Path -Parent $MyInvocation.MyCommand.Path
Copy-Item "$ScriptSource\autoresearch_guardian.py" "$BasePath\" -Force
Copy-Item "$ScriptSource\ecc_safety_checker.py" "$BasePath\" -Force

# Create config
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
Write-Host "  Tools copied"

Write-Host ""
Write-Host "SETUP COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Copy autoresearch to: $BasePath\autoresearch\"
Write-Host "  2. Test with: cd $BasePath; python autoresearch_guardian.py"
Write-Host ""
Write-Host "Important paths:"
Write-Host "  Base: $BasePath"
Write-Host "  Logs: $LogPath"
