#Requires -Version 5.1
<#
.SYNOPSIS
    Encryption Module - Vereinfachte Version für API-Key Verschlüsselung

.DESCRIPTION
    Sicheres Verschlüsselungsmodul für API-Keys.
    Verwendet AES-256-GCM für maximale Sicherheit.

.EXAMPLE
    Protect-ApiKey -KeyName "OpenAI" -ApiKey "sk-..."
    Unprotect-ApiKey -KeyName "OpenAI"
    Get-ApiKeys

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0-simplified
    Location: SecondBrain/00-Meta/Scripts/ecc-framework/
#>

# Module Variables
$script:ModuleVersion = "1.0.0"
$script:KeyStoragePath = Join-Path $PSScriptRoot "..\..\..\00-Meta\Config\secure-keys.json"
$script:MasterKeyPath = Join-Path $PSScriptRoot "..\..\..\00-Meta\Config\.masterkey"

#region Private Functions

function Get-MasterKey {
    # Erstellt oder lädt den Master-Key
    if (Test-Path $script:MasterKeyPath) {
        $keyBytes = [Convert]::FromBase64String((Get-Content $script:MasterKeyPath -Raw))
        return $keyBytes
    }
    else {
        # Erstelle neuen Master-Key (32 Bytes für AES-256)
        $key = New-Object byte[] 32
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($key)
        
        # Speichere Master-Key
        $keyDir = Split-Path $script:MasterKeyPath -Parent
        if (!(Test-Path $keyDir)) {
            New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
        }
        
        [Convert]::ToBase64String($key) | Set-Content $script:MasterKeyPath -Encoding UTF8
        
        Write-Host "Master-Key erstellt. Bewahre ihn sicher auf!" -ForegroundColor Yellow
        return $key
    }
}

function Get-KeyStorage {
    if (Test-Path $script:KeyStoragePath) {
        $content = Get-Content $script:KeyStoragePath -Raw | ConvertFrom-Json
        return $content
    }
    else {
        return @{
            version = "1.0.0"
            lastUpdated = (Get-Date -Format "o")
            keys = @{}
        }
    }
}

function Save-KeyStorage {
    param([hashtable]$Storage)
    
    $storageDir = Split-Path $script:KeyStoragePath -Parent
    if (!(Test-Path $storageDir)) {
        New-Item -ItemType Directory -Path $storageDir -Force | Out-Null
    }
    
    $Storage | ConvertTo-Json -Depth 10 | Set-Content $script:KeyStoragePath -Encoding UTF8
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
    
    $aes.Encrypt($IV, $plaintextBytes, $ciphertext, $tag)
    
    # Kombiniere ciphertext + tag
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
    
    # Trenne ciphertext und tag
    $ciphertextLength = $EncryptedData.Length - 16
    $ciphertext = New-Object byte[] $ciphertextLength
    $tag = New-Object byte[] 16
    
    [Array]::Copy($EncryptedData, 0, $ciphertext, 0, $ciphertextLength)
    [Array]::Copy($EncryptedData, $ciphertextLength, $tag, 0, 16)
    
    $plaintext = New-Object byte[] $ciphertextLength
    $aes.Decrypt($IV, $ciphertext, $tag, $plaintext)
    
    return [System.Text.Encoding]::UTF8.GetString($plaintext)
}

#endregion

#region Public Functions

<#
.SYNOPSIS
    Verschlüsselt einen API-Key

.PARAMETER KeyName
    Name des Keys (z.B. "OpenAI", "Anthropic", "Voyage")

.PARAMETER ApiKey
    Der zu verschlüsselnde API-Key

.EXAMPLE
    Protect-ApiKey -KeyName "OpenAI" -ApiKey "sk-abc123"
#>
function Protect-ApiKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyName,
        
        [Parameter(Mandatory = $true)]
        [string]$ApiKey
    )
    
    try {
        # Master-Key holen
        $masterKey = Get-MasterKey
        
        # IV generieren (12 Bytes für GCM)
        $iv = New-Object byte[] 12
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($iv)
        
        # Verschlüsseln
        $encryptedData = Encrypt-Data -Data $ApiKey -Key $masterKey -IV $iv
        
        # Key-Eintrag erstellen
        $keyEntry = @{
            name = $KeyName
            encryptedData = [Convert]::ToBase64String($encryptedData)
            iv = [Convert]::ToBase64String($iv)
            createdAt = (Get-Date -Format "o")
            updatedAt = (Get-Date -Format "o")
            algorithm = "AES-256-GCM"
        }
        
        # Storage laden und aktualisieren
        $storage = Get-KeyStorage
        $storage.keys[$KeyName] = $keyEntry
        $storage.lastUpdated = (Get-Date -Format "o")
        
        # Speichern
        Save-KeyStorage -Storage $storage
        
        Write-Host "✅ API-Key '$KeyName' verschlüsselt und gespeichert" -ForegroundColor Green
        return $keyEntry
    }
    catch {
        Write-Host "❌ Fehler beim Verschlüsseln: $_" -ForegroundColor Red
        throw
    }
}

<#
.SYNOPSIS
    Entschlüsselt einen API-Key

.PARAMETER KeyName
    Name des Keys

.EXAMPLE
    Unprotect-ApiKey -KeyName "OpenAI"
#>
function Unprotect-ApiKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyName
    )
    
    try {
        # Storage laden
        $storage = Get-KeyStorage
        
        # Prüfen ob Key existiert
        if (!$storage.keys.PSObject.Properties.Name -contains $KeyName) {
            throw "API-Key '$KeyName' nicht gefunden"
        }
        
        $keyEntry = $storage.keys.$KeyName
        
        # Master-Key holen
        $masterKey = Get-MasterKey
        
        # Entschlüsseln
        $encryptedData = [Convert]::FromBase64String($keyEntry.encryptedData)
        $iv = [Convert]::FromBase64String($keyEntry.iv)
        
        $decryptedData = Decrypt-Data -EncryptedData $encryptedData -Key $masterKey -IV $iv
        
        Write-Host "✅ API-Key '$KeyName' entschlüsselt" -ForegroundColor Green
        return $decryptedData
    }
    catch {
        Write-Host "❌ Fehler beim Entschlüsseln: $_" -ForegroundColor Red
        throw
    }
}

<#
.SYNOPSIS
    Listet alle gespeicherten API-Keys auf

.EXAMPLE
    Get-ApiKeys
#>
function Get-ApiKeys {
    [CmdletBinding()]
    param()
    
    $storage = Get-KeyStorage
    
    if ($storage.keys.PSObject.Properties.Name.Count -eq 0) {
        Write-Host "Keine API-Keys gespeichert" -ForegroundColor Yellow
        return @()
    }
    
    $keys = $storage.keys.PSObject.Properties | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            CreatedAt = $_.Value.createdAt
            UpdatedAt = $_.Value.updatedAt
            Algorithm = $_.Value.algorithm
        }
    }
    
    return $keys
}

<#
.SYNOPSIS
    Löscht einen API-Key

.PARAMETER KeyName
    Name des zu löschenden Keys

.EXAMPLE
    Remove-ApiKey -KeyName "OpenAI"
#>
function Remove-ApiKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyName
    )
    
    $storage = Get-KeyStorage
    
    if ($storage.keys.PSObject.Properties.Name -contains $KeyName) {
        $storage.keys.PSObject.Properties.Remove($KeyName)
        $storage.lastUpdated = (Get-Date -Format "o")
        Save-KeyStorage -Storage $storage
        Write-Host "✅ API-Key '$KeyName' gelöscht" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ API-Key '$KeyName' nicht gefunden" -ForegroundColor Yellow
    }
}

#endregion

# Export Module Members
Export-ModuleMember -Function @(
    'Protect-ApiKey',
    'Unprotect-ApiKey',
    'Get-ApiKeys',
    'Remove-ApiKey'
)