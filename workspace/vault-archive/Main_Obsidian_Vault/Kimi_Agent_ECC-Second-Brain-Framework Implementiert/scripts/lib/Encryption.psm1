#Requires -Version 7.0
<#
.SYNOPSIS
    AES-Verschlüsselungsmodul für ECC Second Brain
.DESCRIPTION
    Bietet sichere Verschlüsselung für API-Keys und sensible Daten
    mit AES-256-GCM und sicherer Schlüsselableitung
.AUTHOR
    ECC Stability Engine
.VERSION
    1.0.0
.EXPORTS
    Protect-ApiKey, Unprotect-ApiKey, New-EncryptionKey, Test-Encryption
#>

# ═══════════════════════════════════════════════════════════════
# MODUL-METADATEN
# ═══════════════════════════════════════════════════════════════

$script:ModuleVersion = "1.0.0"
$script:DefaultKeyLength = 32  # 256-bit
$script:DefaultNonceLength = 12  # 96-bit for GCM
$script:DefaultTagLength = 16   # 128-bit authentication tag
$script:IterationCount = 100000  # PBKDF2 iterations

# ═══════════════════════════════════════════════════════════════
# HILFSFUNKTIONEN
# ═══════════════════════════════════════════════════════════════

function Get-VaultKeyPath {
    param([string]$VaultPath)
    
    $defaultVault = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain"
    $basePath = if ($VaultPath) { $VaultPath } else { $defaultVault }
    
    $keyPath = Join-Path $basePath ".obsidian\plugins\ecc-vault"
    
    if (-not (Test-Path $keyPath)) {
        New-Item -ItemType Directory -Path $keyPath -Force | Out-Null
        # Verzeichnis verstecken
        $dirInfo = Get-Item $keyPath
        $dirInfo.Attributes = $dirInfo.Attributes -bor [System.IO.FileAttributes]::Hidden
    }
    
    return $keyPath
}

function Get-MasterKeyPath {
    param([string]$VaultPath)
    
    $keyDir = Get-VaultKeyPath -VaultPath $VaultPath
    return Join-Path $keyDir ".master.key"
}

function Get-SecureKeysPath {
    param([string]$VaultPath)
    
    $keyDir = Get-VaultKeyPath -VaultPath $VaultPath
    return Join-Path $keyDir "secure-keys.json"
}

function ConvertTo-SecureBytes {
    param([SecureString]$SecureString)
    
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes(
            [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
        )
        return $bytes
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
}

function Get-RandomBytes {
    param([int]$Length)
    
    $bytes = New-Object byte[] $Length
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    return $bytes
}

function Clear-Bytes {
    param([byte[]]$Bytes)
    
    if ($Bytes) {
        [System.Array]::Clear($Bytes, 0, $Bytes.Length)
    }
}

# ═══════════════════════════════════════════════════════════════
# SCHLÜSSEL-MANAGEMENT
# ═══════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    Erzeugt einen neuen Master-Schlüssel für die Vault-Verschlüsselung
.DESCRIPTION
    Generiert einen zufälligen 256-bit Schlüssel und speichert ihn
    mit zusätzlichem Passwort-Schutz
#>
function New-EncryptionKey {
    [CmdletBinding()]
    param(
        [string]$VaultPath,
        [SecureString]$Password,
        [switch]$Force
    )
    
    $masterKeyPath = Get-MasterKeyPath -VaultPath $VaultPath
    
    if ((Test-Path $masterKeyPath) -and -not $Force) {
        throw "Master-Key existiert bereits. Verwenden Sie -Force zum Überschreiben."
    }
    
    # Neuen Schlüssel generieren
    $masterKey = Get-RandomBytes -Length $script:DefaultKeyLength
    $salt = Get-RandomBytes -Length 32
    
    if ($Password) {
        # Mit Passwort schützen
        $passwordBytes = ConvertTo-SecureBytes -SecureString $Password
        
        $keyDerivation = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
            $passwordBytes, $salt, $script:IterationCount, [System.Security.Cryptography.HashAlgorithmName]::SHA256
        )
        $encryptionKey = $keyDerivation.GetBytes(32)
        
        # Master-Key verschlüsseln
        $encryptedKey = Encrypt-WithKey -Plaintext $masterKey -Key $encryptionKey -Salt $salt
        
        Clear-Bytes -Bytes $passwordBytes
        Clear-Bytes -Bytes $encryptionKey
    } else {
        # Nur Salt + unverschlüsselter Key (für automatischen Betrieb)
        $encryptedKey = @{
            Salt = [Convert]::ToBase64String($salt)
            Data = [Convert]::ToBase64String($masterKey)
            Protected = $false
        }
    }
    
    # Speichern
    $keyData = @{
        Version = $script:ModuleVersion
        Created = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Salt = [Convert]::ToBase64String($salt)
        EncryptedKey = $encryptedKey
        Algorithm = "AES-256-GCM"
    }
    
    $keyData | ConvertTo-Json -Depth 5 | Set-Content $masterKeyPath -Encoding UTF8
    
    # Berechtigungen setzen
    $acl = Get-Acl $masterKeyPath
    $acl.SetAccessRuleProtection($true, $false)
    
    # Nur aktueller Benutzer
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $currentUser, "Read", "Allow"
    )
    $acl.SetAccessRule($rule)
    Set-Acl $masterKeyPath $acl
    
    Clear-Bytes -Bytes $masterKey
    
    Write-Host "Master-Key erfolgreich erstellt: $masterKeyPath" -ForegroundColor Green
    
    return $keyData
}

<#
.SYNOPSIS
    Lädt den Master-Schlüssel aus dem geschützten Speicher
#>
function Get-MasterKey {
    [CmdletBinding()]
    param(
        [string]$VaultPath,
        [SecureString]$Password
    )
    
    $masterKeyPath = Get-MasterKeyPath -VaultPath $VaultPath
    
    if (-not (Test-Path $masterKeyPath)) {
        throw "Master-Key nicht gefunden. Führen Sie New-EncryptionKey aus."
    }
    
    $keyData = Get-Content $masterKeyPath | ConvertFrom-Json
    
    if ($keyData.EncryptedKey.Protected -eq $false) {
        # Unverschlüsselter Key
        return [Convert]::FromBase64String($keyData.EncryptedKey.Data)
    }
    
    if (-not $Password) {
        throw "Passwort erforderlich für geschützten Master-Key"
    }
    
    # Entschlüsseln
    $salt = [Convert]::FromBase64String($keyData.Salt)
    $passwordBytes = ConvertTo-SecureBytes -SecureString $Password
    
    $keyDerivation = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
        $passwordBytes, $salt, $script:IterationCount, [System.Security.Cryptography.HashAlgorithmName]::SHA256
    )
    $encryptionKey = $keyDerivation.GetBytes(32)
    
    $encryptedData = [Convert]::FromBase64String($keyData.EncryptedKey.Data)
    $nonce = [Convert]::FromBase64String($keyData.EncryptedKey.Nonce)
    $tag = [Convert]::FromBase64String($keyData.EncryptedKey.Tag)
    
    $masterKey = Decrypt-WithKey -Ciphertext $encryptedData -Nonce $nonce -Tag $tag -Key $encryptionKey
    
    Clear-Bytes -Bytes $passwordBytes
    Clear-Bytes -Bytes $encryptionKey
    
    return $masterKey
}

# ═══════════════════════════════════════════════════════════════
# AES-VERSCHLÜSSELUNG
# ═══════════════════════════════════════════════════════════════

function Encrypt-WithKey {
    param(
        [byte[]]$Plaintext,
        [byte[]]$Key,
        [byte[]]$Salt
    )
    
    $nonce = Get-RandomBytes -Length $script:DefaultNonceLength
    
    $aes = [System.Security.Cryptography.AesGcm]::new($Key)
    
    $ciphertext = New-Object byte[] $Plaintext.Length
    $tag = New-Object byte[] $script:DefaultTagLength
    
    $aes.Encrypt($nonce, $Plaintext, $ciphertext, $tag)
    
    return @{
        Data = [Convert]::ToBase64String($ciphertext)
        Nonce = [Convert]::ToBase64String($nonce)
        Tag = [Convert]::ToBase64String($tag)
        Salt = [Convert]::ToBase64String($Salt)
    }
}

function Decrypt-WithKey {
    param(
        [byte[]]$Ciphertext,
        [byte[]]$Nonce,
        [byte[]]$Tag,
        [byte[]]$Key
    )
    
    $aes = [System.Security.Cryptography.AesGcm]::new($Key)
    
    $plaintext = New-Object byte[] $Ciphertext.Length
    
    try {
        $aes.Decrypt($Nonce, $Ciphertext, $Tag, $plaintext)
    }
    catch {
        throw "Entschlüsselung fehlgeschlagen: Falsches Passwort oder beschädigte Daten"
    }
    
    return $plaintext
}

# ═══════════════════════════════════════════════════════════════
# ÖFFENTLICHE API-FUNKTIONEN
# ═══════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    Verschlüsselt einen API-Key und speichert ihn sicher
.DESCRIPTION
    Verwendet AES-256-GCM mit dem Vault-Master-Key
.PARAMETER ApiKey
    Der zu verschlüsselnde API-Key (als SecureString empfohlen)
.PARAMETER ServiceName
    Name des Dienstes (z.B. "openai", "anthropic")
.PARAMETER VaultPath
    Pfad zur Vault (optional)
.PARAMETER Metadata
    Zusätzliche Metadaten für den Key
.EXAMPLE
    $secureKey = Read-Host "API Key" -AsSecureString
    Protect-ApiKey -ApiKey $secureKey -ServiceName "openai"
#>
function Protect-ApiKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [SecureString]$ApiKey,
        
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [string]$VaultPath,
        
        [hashtable]$Metadata = @{}
    )
    
    Write-Verbose "Verschlüssele API-Key für Dienst: $ServiceName"
    
    # Master-Key laden
    $masterKey = Get-MasterKey -VaultPath $VaultPath
    
    try {
        # API-Key in Bytes konvertieren
        $keyBytes = ConvertTo-SecureBytes -SecureString $ApiKey
        
        # Verschlüsseln
        $salt = Get-RandomBytes -Length 32
        $encrypted = Encrypt-WithKey -Plaintext $keyBytes -Key $masterKey -Salt $salt
        
        # In secure-keys.json speichern
        $secureKeysPath = Get-SecureKeysPath -VaultPath $VaultPath
        
        $secureKeys = @{}
        if (Test-Path $secureKeysPath) {
            $secureKeys = Get-Content $secureKeysPath | ConvertFrom-Json -AsHashtable
        }
        
        $secureKeys[$ServiceName] = @{
            EncryptedData = $encrypted.Data
            Nonce = $encrypted.Nonce
            Tag = $encrypted.Tag
            Salt = $encrypted.Salt
            Algorithm = "AES-256-GCM"
            Created = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
            Metadata = $Metadata
        }
        
        $secureKeys | ConvertTo-Json -Depth 10 | Set-Content $secureKeysPath -Encoding UTF8
        
        # Berechtigungen setzen
        $acl = Get-Acl $secureKeysPath
        $acl.SetAccessRuleProtection($true, $false)
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $currentUser, "Read", "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl $secureKeysPath $acl
        
        Clear-Bytes -Bytes $keyBytes
        
        Write-Host "API-Key für '$ServiceName' erfolgreich verschlüsselt" -ForegroundColor Green
        
        return @{
            Success = $true
            Service = $ServiceName
            Path = $secureKeysPath
        }
    }
    finally {
        Clear-Bytes -Bytes $masterKey
    }
}

<#
.SYNOPSIS
    Entschlüsselt einen gespeicherten API-Key
.DESCRIPTION
    Lädt und entschlüsselt einen API-Key aus dem sicheren Speicher
.PARAMETER ServiceName
    Name des Dienstes
.PARAMETER VaultPath
    Pfad zur Vault (optional)
.PARAMETER AsPlainText
    Gibt den Key als Plaintext zurück (VORSICHT!)
.EXAMPLE
    $apiKey = Unprotect-ApiKey -ServiceName "openai"
    # Verwendung mit SecureString
#>
function Unprotect-ApiKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [string]$VaultPath,
        
        [switch]$AsPlainText
    )
    
    Write-Verbose "Entschlüssele API-Key für Dienst: $ServiceName"
    
    # Secure Keys laden
    $secureKeysPath = Get-SecureKeysPath -VaultPath $VaultPath
    
    if (-not (Test-Path $secureKeysPath)) {
        throw "Keine gespeicherten API-Keys gefunden"
    }
    
    $secureKeys = Get-Content $secureKeysPath | ConvertFrom-Json -AsHashtable
    
    if (-not $secureKeys.ContainsKey($ServiceName)) {
        throw "Kein API-Key für Dienst '$ServiceName' gefunden"
    }
    
    $keyData = $secureKeys[$ServiceName]
    
    # Master-Key laden
    $masterKey = Get-MasterKey -VaultPath $VaultPath
    
    try {
        # Entschlüsseln
        $ciphertext = [Convert]::FromBase64String($keyData.EncryptedData)
        $nonce = [Convert]::FromBase64String($keyData.Nonce)
        $tag = [Convert]::FromBase64String($keyData.Tag)
        
        $plaintext = Decrypt-WithKey -Ciphertext $ciphertext -Nonce $nonce -Tag $tag -Key $masterKey
        
        $keyString = [System.Text.Encoding]::UTF8.GetString($plaintext)
        
        if ($AsPlainText) {
            Clear-Bytes -Bytes $plaintext
            return $keyString
        }
        
        # Als SecureString zurückgeben
        $secureString = ConvertTo-SecureString -String $keyString -AsPlainText -Force
        Clear-Bytes -Bytes $plaintext
        
        return $secureString
    }
    finally {
        Clear-Bytes -Bytes $masterKey
    }
}

<#
.SYNOPSIS
    Listet alle gespeicherten API-Keys auf
#>
function Get-ProtectedApiKeys {
    [CmdletBinding()]
    param([string]$VaultPath)
    
    $secureKeysPath = Get-SecureKeysPath -VaultPath $VaultPath
    
    if (-not (Test-Path $secureKeysPath)) {
        return @()
    }
    
    $secureKeys = Get-Content $secureKeysPath | ConvertFrom-Json -AsHashtable
    
    $results = foreach ($service in $secureKeys.Keys) {
        [PSCustomObject]@{
            Service = $service
            Created = $secureKeys[$service].Created
            Algorithm = $secureKeys[$service].Algorithm
            HasMetadata = ($secureKeys[$service].Metadata -ne $null)
        }
    }
    
    return $results
}

<#
.SYNOPSIS
    Entfernt einen gespeicherten API-Key
#>
function Remove-ProtectedApiKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [string]$VaultPath
    )
    
    $secureKeysPath = Get-SecureKeysPath -VaultPath $VaultPath
    
    if (-not (Test-Path $secureKeysPath)) {
        throw "Keine gespeicherten API-Keys gefunden"
    }
    
    $secureKeys = Get-Content $secureKeysPath | ConvertFrom-Json -AsHashtable
    
    if ($secureKeys.Remove($ServiceName)) {
        $secureKeys | ConvertTo-Json -Depth 10 | Set-Content $secureKeysPath -Encoding UTF8
        Write-Host "API-Key für '$ServiceName' entfernt" -ForegroundColor Green
        return $true
    }
    
    return $false
}

<#
.SYNOPSIS
    Testet die Verschlüsselungsfunktionalität
#>
function Test-Encryption {
    [CmdletBinding()]
    param([string]$VaultPath)
    
    Write-Host "=== ECC Encryption Test ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Master-Key prüfen
    $masterKeyPath = Get-MasterKeyPath -VaultPath $VaultPath
    Write-Host "Master-Key: " -NoNewline
    if (Test-Path $masterKeyPath) {
        Write-Host "Vorhanden ✓" -ForegroundColor Green
    } else {
        Write-Host "Nicht vorhanden ✗" -ForegroundColor Red
    }
    
    # Secure Keys prüfen
    $secureKeysPath = Get-SecureKeysPath -VaultPath $VaultPath
    Write-Host "Secure Keys: " -NoNewline
    if (Test-Path $secureKeysPath) {
        Write-Host "Vorhanden ✓" -ForegroundColor Green
    } else {
        Write-Host "Nicht vorhanden ✗" -ForegroundColor Yellow
    }
    
    # Verschlüsselungstest
    Write-Host ""
    Write-Host "Teste Verschlüsselung..." -ForegroundColor Gray
    
    try {
        $testKey = ConvertTo-SecureString -String "test-api-key-12345" -AsPlainText -Force
        
        # Sichern existierender Keys
        $existingKeys = $null
        if (Test-Path $secureKeysPath) {
            $existingKeys = Get-Content $secureKeysPath
        }
        
        # Test verschlüsseln
        $result = Protect-ApiKey -ApiKey $testKey -ServiceName "__test__" -VaultPath $VaultPath -Verbose:$false
        
        # Test entschlüsseln
        $decrypted = Unprotect-ApiKey -ServiceName "__test__" -VaultPath $VaultPath -AsPlainText
        
        # Cleanup
        Remove-ProtectedApiKey -ServiceName "__test__" -VaultPath $VaultPath | Out-Null
        
        if ($existingKeys) {
            $existingKeys | Set-Content $secureKeysPath -Encoding UTF8
        }
        
        Write-Host "Verschlüsselung: " -NoNewline
        if ($decrypted -eq "test-api-key-12345") {
            Write-Host "Funktioniert ✓" -ForegroundColor Green
        } else {
            Write-Host "Fehlgeschlagen ✗" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Verschlüsselung: Fehlgeschlagen ✗" -ForegroundColor Red
        Write-Host "Fehler: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "=== Test abgeschlossen ===" -ForegroundColor Cyan
}

# ═══════════════════════════════════════════════════════════════
# MODUL-EXPORTE
# ═══════════════════════════════════════════════════════════════

Export-ModuleMember -Function @(
    'Protect-ApiKey',
    'Unprotect-ApiKey',
    'New-EncryptionKey',
    'Get-ProtectedApiKeys',
    'Remove-ProtectedApiKey',
    'Test-Encryption'
)
