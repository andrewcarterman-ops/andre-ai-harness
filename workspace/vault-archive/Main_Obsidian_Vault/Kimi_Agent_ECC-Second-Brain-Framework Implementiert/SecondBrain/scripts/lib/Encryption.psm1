#Requires -Version 5.1
<#
.SYNOPSIS
    ECC Encryption Module - AES-256-GCM Verschlüsselung für API-Keys

.DESCRIPTION
    Sicheres Verschlüsselungsmodul für das ECC Second Brain Framework.
    Verwendet AES-256-GCM für API-Keys und sensible Daten.

.EXAMPLE
    Protect-ApiKey -KeyName "OpenAI" -ApiKey "sk-..."
    Unprotect-ApiKey -KeyName "OpenAI"

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    ECC Framework: Security
#>

# Module Variables
$script:ModuleVersion = "1.0.0"
$script:KeyStoragePath = Join-Path $PSScriptRoot "..\..\.obsidian\plugins\ecc-vault\secure-keys.json"
$script:MasterKeyPath = Join-Path $PSScriptRoot "..\..\.obsidian\plugins\ecc-vault\.masterkey"

#region Public Functions

<#
.SYNOPSIS
    Verschlüsselt einen API-Key

.PARAMETER KeyName
    Name des Keys (z.B. "OpenAI", "Anthropic")

.PARAMETER ApiKey
    Der zu verschlüsselnde API-Key

.PARAMETER StoragePath
    Pfad zur Speicherdatei

.OUTPUTS
    PSCustomObject - Verschlüsselte Key-Informationen
#>
function Protect-ApiKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyName,
        
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [string]$StoragePath = $script:KeyStoragePath
    )
    
    try {
        # Get or create master key
        $masterKey = Get-MasterKey
        
        # Generate IV
        $iv = New-Object byte[] 12
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($iv)
        
        # Encrypt API key
        $encryptedData = Encrypt-Data -Data $ApiKey -Key $masterKey -IV $iv
        
        # Create key entry
        $keyEntry = @{
            name = $KeyName
            encryptedData = [Convert]::ToBase64String($encryptedData)
            iv = [Convert]::ToBase64String($iv)
            createdAt = (Get-Date -Format "o")
            updatedAt = (Get-Date -Format "o")
            algorithm = "AES-256-GCM"
        }
        
        # Load existing storage
        $storage = Get-KeyStorage -StoragePath $StoragePath
        
        # Add or update key
        $storage.keys[$KeyName] = $keyEntry
        $storage.lastUpdated = (Get-Date -Format "o")
        
        # Save storage
        Save-KeyStorage -Storage $storage -StoragePath $StoragePath
        
        Write-ECCLog "API key '$KeyName' encrypted and stored successfully" -Level "INFO"
        
        return $keyEntry
    }
    catch {
        Write-ECCLog "Failed to encrypt API key '$KeyName': $_" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Entschlüsselt einen API-Key

.PARAMETER KeyName
    Name des Keys

.PARAMETER StoragePath
    Pfad zur Speicherdatei

.OUTPUTS
    String - Der entschlüsselte API-Key
#>
function Unprotect-ApiKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyName,
        
        [Parameter(Mandatory = $false)]
        [string]$StoragePath = $script:KeyStoragePath
    )
    
    try {
        # Load storage
        $storage = Get-KeyStorage -StoragePath $StoragePath
        
        # Check if key exists
        if (!$storage.keys.ContainsKey($KeyName)) {
            throw "API key '$KeyName' not found in storage"
        }
        
        $keyEntry = $storage.keys[$KeyName]
        
        # Get master key
        $masterKey = Get-MasterKey
        
        # Decrypt API key
        $encryptedData = [Convert]::FromBase64String($keyEntry.encryptedData)
        $iv = [Convert]::FromBase64String($keyEntry.iv)
        
        $decryptedData = Decrypt-Data -EncryptedData $encryptedData -Key $masterKey -IV $iv
        
        Write-ECCLog "API key '$KeyName' decrypted successfully" -Level "DEBUG"
        
        return $decryptedData
    }
    catch {
        Write-ECCLog "Failed to decrypt API key '$KeyName': $_" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Listet alle gespeicherten API-Keys auf

.PARAMETER StoragePath
    Pfad zur Speicherdatei

.OUTPUTS
    PSCustomObject[] - Liste der Keys (ohne verschlüsselte Daten)
#>
function Get-ApiKeys {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$StoragePath = $script:KeyStoragePath
    )
    
    $storage = Get-KeyStorage -StoragePath $StoragePath
    
    $keys = @()
    foreach ($keyName in $storage.keys.Keys) {
        $keyEntry = $storage.keys[$keyName]
        $keys += [PSCustomObject]@{
            Name = $keyName
            CreatedAt = $keyEntry.createdAt
            UpdatedAt = $keyEntry.updatedAt
            Algorithm = $keyEntry.algorithm
        }
    }
    
    return $keys
}

<#
.SYNOPSIS
    Löscht einen API-Key

.PARAMETER KeyName
    Name des zu löschenden Keys

.PARAMETER StoragePath
    Pfad zur Speicherdatei

.PARAMETER Force
    Keine Bestätigung
#>
function Remove-ApiKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyName,
        
        [Parameter(Mandatory = $false)]
        [string]$StoragePath = $script:KeyStoragePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    $storage = Get-KeyStorage -StoragePath $StoragePath
    
    if (!$storage.keys.ContainsKey($KeyName)) {
        Write-Warning "API key '$KeyName' not found"
        return
    }
    
    if (!$Force) {
        $confirm = Read-Host "Are you sure you want to delete API key '$KeyName'? (y/N)"
        if ($confirm -ne "y") {
            Write-Host "Deletion cancelled" -ForegroundColor Yellow
            return
        }
    }
    
    $storage.keys.Remove($KeyName)
    $storage.lastUpdated = (Get-Date -Format "o")
    
    Save-KeyStorage -Storage $storage -StoragePath $StoragePath
    
    Write-ECCLog "API key '$KeyName' deleted successfully" -Level "INFO"
}

<#
.SYNOPSIS
    Testet die Verschlüsselung

.OUTPUTS
    Boolean
#>
function Test-Encryption {
    [CmdletBinding()]
    param()
    
    try {
        $testData = "Test data for encryption validation"
        $masterKey = Get-MasterKey
        $iv = New-Object byte[] 12
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($iv)
        
        $encrypted = Encrypt-Data -Data $testData -Key $masterKey -IV $iv
        $decrypted = Decrypt-Data -EncryptedData $encrypted -Key $masterKey -IV $iv
        
        return $decrypted -eq $testData
    }
    catch {
        Write-ECCLog "Encryption test failed: $_" -Level "ERROR"
        return $false
    }
}

#endregion

#region Private Functions

function Get-MasterKey {
    if (Test-Path $script:MasterKeyPath) {
        $encryptedKey = Get-Content $script:MasterKeyPath -Raw
        return [Convert]::FromBase64String($encryptedKey)
    }
    else {
        # Generate new master key
        $key = New-Object byte[] 32
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($key)
        
        # Ensure directory exists
        $keyDir = Split-Path $script:MasterKeyPath -Parent
        if (!(Test-Path $keyDir)) {
            New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
        }
        
        # Save master key
        [Convert]::ToBase64String($key) | Set-Content $script:MasterKeyPath -NoNewline
        
        # Set restrictive permissions
        $acl = Get-Acl $script:MasterKeyPath
        $acl.SetAccessRuleProtection($true, $false)
        
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $currentUser, "Read", "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl $script:MasterKeyPath $acl
        
        return $key
    }
}

function Encrypt-Data {
    param(
        [string]$Data,
        [byte[]]$Key,
        [byte[]]$IV
    )
    
    $aes = [System.Security.Cryptography.AesGcm]::new($Key)
    
    $plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
    $ciphertext = New-Object byte[] $plaintextBytes.Length
    $tag = New-Object byte[] 16
    
    $aes.Encrypt($IV, $plaintextBytes, $ciphertext, $tag, $null)
    
    # Combine ciphertext and tag
    $result = New-Object byte[] ($ciphertext.Length + $tag.Length)
    [Array]::Copy($ciphertext, 0, $result, 0, $ciphertext.Length)
    [Array]::Copy($tag, 0, $result, $ciphertext.Length, $tag.Length)
    
    return $result
}

function Decrypt-Data {
    param(
        [byte[]]$EncryptedData,
        [byte[]]$Key,
        [byte[]]$IV
    )
    
    $aes = [System.Security.Cryptography.AesGcm]::new($Key)
    
    # Split ciphertext and tag
    $ciphertextLength = $EncryptedData.Length - 16
    $ciphertext = New-Object byte[] $ciphertextLength
    $tag = New-Object byte[] 16
    
    [Array]::Copy($EncryptedData, 0, $ciphertext, 0, $ciphertextLength)
    [Array]::Copy($EncryptedData, $ciphertextLength, $tag, 0, 16)
    
    $plaintext = New-Object byte[] $ciphertextLength
    $aes.Decrypt($IV, $ciphertext, $tag, $plaintext, $null)
    
    return [System.Text.Encoding]::UTF8.GetString($plaintext)
}

function Get-KeyStorage {
    param([string]$StoragePath)
    
    if (Test-Path $StoragePath) {
        $content = Get-Content $StoragePath -Raw
        return $content | ConvertFrom-Json -AsHashtable
    }
    else {
        return @{
            version = "1.0"
            lastUpdated = (Get-Date -Format "o")
            keys = @{}
            metadata = @{
                encryption = "AES-256-GCM"
                keyDerivation = "PBKDF2"
            }
        }
    }
}

function Save-KeyStorage {
    param(
        [hashtable]$Storage,
        [string]$StoragePath
    )
    
    $storageDir = Split-Path $StoragePath -Parent
    if (!(Test-Path $storageDir)) {
        New-Item -ItemType Directory -Path $storageDir -Force | Out-Null
    }
    
    $Storage | ConvertTo-Json -Depth 10 | Set-Content $StoragePath -Encoding UTF8
}

function Write-ECCLog {
    param(
        [string]$Message,
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "DEBUG" { Write-Verbose $logEntry }
        "INFO"  { Write-Host $logEntry -ForegroundColor Cyan }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
    }
}

#endregion

# Export Module Members
Export-ModuleMember -Function @(
    'Protect-ApiKey',
    'Unprotect-ApiKey',
    'Get-ApiKeys',
    'Remove-ApiKey',
    'Test-Encryption'
)
