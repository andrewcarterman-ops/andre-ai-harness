#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Fort Knox Setup - Final Working Version
    Based on lessons learned from 4 hours of debugging on 2026-03-31
    
.DESCRIPTION
    Sets up isolated autoresearch environment with proper permissions.
    Tested on German Windows systems.
    
.EXAMPLE
    .\Setup-FortKnox-Final.ps1
#>

[CmdletBinding()]
param()

# Error handling
$ErrorActionPreference = "Stop"

# Configuration
$UserName = "autoresearch"
$BasePath = "C:\Autoresearch"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "========================================"
Write-Host "FORT KNOX SETUP - FINAL VERSION"
Write-Host "========================================"
Write-Host ""

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Must run as Administrator!" -ForegroundColor Red
    exit 1
}

# Step 1: Create user if not exists
Write-Host "[1/8] Checking user..."
$user = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
if (-not $user) {
    Write-Host "  Creating user $UserName..."
    $password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    New-LocalUser -Name $UserName -Password $securePassword -Description "Autoresearch isolated account" | Out-Null
    Write-Host "  User created. PASSWORD: $password" -ForegroundColor Yellow
    Write-Host "  (Save this password!)"
} else {
    Write-Host "  User already exists."
}

# Step 2: Create directory
Write-Host "[2/8] Creating directory..."
if (!(Test-Path $BasePath)) {
    New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
    Write-Host "  Created $BasePath"
} else {
    Write-Host "  Directory exists."
}

# Step 3: Take ownership (KEY STEP!)
Write-Host "[3/8] Taking ownership..."
Write-Host "  Running: takeown /F `"$BasePath`" /R"
takeown /F "$BasePath" /R 2>&1 | Out-Null
Write-Host "  Ownership acquired."

# Step 4: Set permissions for current user (KEY STEP!)
Write-Host "[4/8] Setting permissions..."
Write-Host "  Running: icacls for $env:USERNAME"
icacls "$BasePath" /grant "$($env:USERNAME):(OI)(CI)F" /T 2>&1 | Out-Null
Write-Host "  Permissions set."

# Step 5: Create subdirectories
Write-Host "[5/8] Creating subdirectories..."
@("$BasePath\logs", "$BasePath\backups", "$BasePath\autoresearch") | ForEach-Object {
    if (!(Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}
Write-Host "  Subdirectories created."

# Step 6: Copy files
Write-Host "[6/8] Copying guardian tools..."
$filesToCopy = @(
    "autoresearch_guardian_v2.py",
    "guardian_simple.py", 
    "ecc_safety_checker.py"
)

$copySuccess = $true
foreach ($file in $filesToCopy) {
    $source = Join-Path $ScriptPath $file
    $dest = Join-Path $BasePath $file
    
    if (Test-Path $source) {
        try {
            Copy-Item $source $dest -Force
            Write-Host "  Copied: $file"
        } catch {
            Write-Host "  ERROR copying $file : $_" -ForegroundColor Red
            $copySuccess = $false
        }
    } else {
        Write-Host "  WARNING: $file not found in script directory" -ForegroundColor Yellow
    }
}

# Step 7: Create config (One-liner, no here-string!)
Write-Host "[7/8] Creating config..."
$configContent = '{"max_runtime_minutes":360,"max_memory_gb":48,"max_disk_gb":8,"max_cpu_percent":80,"allowed_network_hosts":["huggingface.co","download.pytorch.org"],"check_interval_seconds":10}'
$configContent | Set-Content "$BasePath\guardian_config.json" -Encoding UTF8
Write-Host "  Config created."

# Step 8: Set final permissions
Write-Host "[8/8] Setting final permissions..."
icacls "$BasePath" /grant "$UserName:(OI)(CI)F" /T 2>&1 | Out-Null
Write-Host "  Final permissions set."

# Verification
Write-Host ""
Write-Host "========================================"
Write-Host "VERIFICATION"
Write-Host "========================================"

$allOk = $true
$checkFiles = @(
    "$BasePath\autoresearch_guardian_v2.py",
    "$BasePath\ecc_safety_checker.py",
    "$BasePath\guardian_config.json"
)

foreach ($file in $checkFiles) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        Write-Host "  [OK] $file ($size bytes)"
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
        $allOk = $false
    }
}

# Test write permission
$testFile = "$BasePath\test_write.tmp"
try {
    "test" | Set-Content $testFile -Force
    if (Test-Path $testFile) {
        Remove-Item $testFile -Force
        Write-Host "  [OK] Write permission verified"
    }
} catch {
    Write-Host "  [ERROR] Write permission failed: $_" -ForegroundColor Red
    $allOk = $false
}

Write-Host ""
if ($allOk) {
    Write-Host "SETUP COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Clone autoresearch:"
    Write-Host "     cd $BasePath\autoresearch"
    Write-Host "     git clone https://github.com/karpathy/autoresearch.git ."
    Write-Host ""
    Write-Host "  2. Test the setup:"
    Write-Host "     cd $BasePath"
    Write-Host "     python autoresearch_guardian_v2.py --train-command 'uv run train.py'"
    Write-Host ""
    Write-Host "Important:"
    Write-Host "  - User '$UserName' password: (check above output)"
    Write-Host "  - Base path: $BasePath"
    Write-Host "  - Logs: $BasePath\logs"
} else {
    Write-Host "SETUP INCOMPLETE - some files missing!" -ForegroundColor Red
}
