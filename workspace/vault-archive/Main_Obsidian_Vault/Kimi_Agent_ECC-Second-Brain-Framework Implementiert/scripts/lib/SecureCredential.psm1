#Requires -Version 7.0
<#
.SYNOPSIS
    Secure Credential Module für OpenClaw-Obsidian Integration

.DESCRIPTION
    Dieses Modul bietet Funktionen zur sicheren Speicherung von
    API-Keys und anderen sensiblen Daten mittels DPAPI.

.FUNCTIONS
    Protect-Secret - Verschlüsselt einen String
    Unprotect-Secret - Entschlüsselt einen String
    Save-EncryptedCredential - Speichert verschlüsselte Credentials
    Get-EncryptedCredential - Lädt verschlüsselte Credentials
    Test-Encryption - Testet die Verschlüsselung
#>

# ============================================================================
# VERSCHLÜSSELUNG
# ============================================================================

function Protect-Secret {
    <#
    .SYNOPSIS
        Verschlüsselt einen String mit DPAPI

    .PARAMETER Secret
        Der zu verschlüsselnde String

    .PARAMETER Scope
        Verschlüsselungsbereich (CurrentUser oder LocalMachine)

    .EXAMPLE
        Protect-Secret -Secret "my-api-key"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Secret,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "LocalMachine")]
        [string]$Scope = "CurrentUser"
    )
    
    process {
        try {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($Secret)
            $protected = [System.Security.Cryptography.ProtectedData]::Protect(
                $bytes,
                $null,
                [System.Security.Cryptography.DataProtectionScope]::$Scope
            )
            return [Convert]::ToBase64String($protected)
        }
        catch {
            Write-Error "Failed to protect secret: $($_.Exception.Message)"
            return $null
        }
    }
}

function Unprotect-Secret {
    <#
    .SYNOPSIS
        Entschlüsselt einen mit DPAPI verschlüsselten String

    .PARAMETER EncryptedSecret
        Der verschlüsselte String (Base64)

    .PARAMETER Scope
        Verschlüsselungsbereich (CurrentUser oder LocalMachine)

    .EXAMPLE
        Unprotect-Secret -EncryptedSecret "AQAAANCM..."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$EncryptedSecret,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "LocalMachine")]
        [string]$Scope = "CurrentUser"
    )
    
    process {
        try {
            $bytes = [Convert]::FromBase64String($EncryptedSecret)
            $unprotected = [System.Security.Cryptography.ProtectedData]::Unprotect(
                $bytes,
                $null,
                [System.Security.Cryptography.DataProtectionScope]::$Scope
            )
            return [System.Text.Encoding]::UTF8.GetString($unprotected)
        }
        catch {
            Write-Error "Failed to unprotect secret: $($_.Exception.Message)"
            return $null
        }
    }
}

# ============================================================================
# CREDENTIAL MANAGEMENT
# ============================================================================

function Save-EncryptedCredential {
    <#
    .SYNOPSIS
        Speichert verschlüsselte Credentials in einer JSON-Datei

    .PARAMETER Name
        Name der Credentials

    .PARAMETER Credential
        PSCredential-Objekt oder Hashtable mit User/Pass

    .PARAMETER FilePath
        Pfad zur Speicherdatei

    .EXAMPLE
        $cred = Get-Credential
        Save-EncryptedCredential -Name "API" -Credential $cred
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [object]$Credential,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath = "${env:LOCALAPPDATA}\OpenClaw\credentials.json",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "LocalMachine")]
        [string]$Scope = "CurrentUser"
    )
    
    try {
        # Verzeichnis erstellen
        $dir = Split-Path $FilePath -Parent
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        # Bestehende Credentials laden
        $credentials = @{}
        if (Test-Path $FilePath) {
            $content = Get-Content -Path $FilePath -Raw
            $credentials = $content | ConvertFrom-Json -AsHashtable
        }
        
        # Credentials extrahieren
        $username = ""
        $password = ""
        
        if ($Credential -is [System.Management.Automation.PSCredential]) {
            $username = $Credential.UserName
            $password = $Credential.GetNetworkCredential().Password
        }
        elseif ($Credential -is [hashtable]) {
            $username = $Credential.Username
            $password = $Credential.Password
        }
        else {
            throw "Unsupported credential type"
        }
        
        # Verschlüsseln
        $encryptedPassword = Protect-Secret -Secret $password -Scope $Scope
        
        # Speichern
        $credentials[$Name] = @{
            Username = $username
            Password = $encryptedPassword
            Scope = $Scope
            Created = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        }
        
        $credentials | ConvertTo-Json -Depth 5 | Set-Content -Path $FilePath
        
        Write-Host "Credentials saved: $Name" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to save credentials: $($_.Exception.Message)"
        return $false
    }
}

function Get-EncryptedCredential {
    <#
    .SYNOPSIS
        Lädt verschlüsselte Credentials aus einer JSON-Datei

    .PARAMETER Name
        Name der Credentials

    .PARAMETER FilePath
        Pfad zur Speicherdatei

    .EXAMPLE
        $cred = Get-EncryptedCredential -Name "API"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath = "${env:LOCALAPPDATA}\OpenClaw\credentials.json"
    )
    
    try {
        if (!(Test-Path $FilePath)) {
            Write-Warning "Credentials file not found: $FilePath"
            return $null
        }
        
        $content = Get-Content -Path $FilePath -Raw
        $credentials = $content | ConvertFrom-Json -AsHashtable
        
        if (!$credentials.ContainsKey($Name)) {
            Write-Warning "Credentials not found: $Name"
            return $null
        }
        
        $cred = $credentials[$Name]
        $decryptedPassword = Unprotect-Secret -EncryptedSecret $cred.Password -Scope $cred.Scope
        
        return [PSCustomObject]@{
            Username = $cred.Username
            Password = $decryptedPassword
            Created = $cred.Created
        }
    }
    catch {
        Write-Error "Failed to get credentials: $($_.Exception.Message)"
        return $null
    }
}

function Remove-EncryptedCredential {
    <#
    .SYNOPSIS
        Entfernt verschlüsselte Credentials

    .PARAMETER Name
        Name der Credentials

    .PARAMETER FilePath
        Pfad zur Speicherdatei

    .EXAMPLE
        Remove-EncryptedCredential -Name "API"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath = "${env:LOCALAPPDATA}\OpenClaw\credentials.json"
    )
    
    try {
        if (!(Test-Path $FilePath)) {
            Write-Warning "Credentials file not found: $FilePath"
            return $false
        }
        
        $content = Get-Content -Path $FilePath -Raw
        $credentials = $content | ConvertFrom-Json -AsHashtable
        
        if (!$credentials.ContainsKey($Name)) {
            Write-Warning "Credentials not found: $Name"
            return $false
        }
        
        $credentials.Remove($Name)
        $credentials | ConvertTo-Json -Depth 5 | Set-Content -Path $FilePath
        
        Write-Host "Credentials removed: $Name" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to remove credentials: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================================
# API KEY MANAGEMENT
# ============================================================================

function Save-ApiKey {
    <#
    .SYNOPSIS
        Speichert einen API-Key verschlüsselt

    .PARAMETER Service
        Name des Services (z.B. "OpenAI", "Anthropic")

    .PARAMETER ApiKey
        Der API-Key

    .PARAMETER FilePath
        Pfad zur Speicherdatei

    .EXAMPLE
        Save-ApiKey -Service "OpenAI" -ApiKey "sk-..."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Service,
        
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath = "${env:LOCALAPPDATA}\OpenClaw\api-keys.json",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "LocalMachine")]
        [string]$Scope = "CurrentUser"
    )
    
    try {
        $dir = Split-Path $FilePath -Parent
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        $apiKeys = @{}
        if (Test-Path $FilePath) {
            $content = Get-Content -Path $FilePath -Raw
            $apiKeys = $content | ConvertFrom-Json -AsHashtable
        }
        
        $encryptedKey = Protect-Secret -Secret $ApiKey -Scope $Scope
        
        $apiKeys[$Service] = @{
            Key = $encryptedKey
            Scope = $Scope
            Created = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
            LastUsed = $null
        }
        
        $apiKeys | ConvertTo-Json -Depth 5 | Set-Content -Path $FilePath
        
        # Maskierten Key anzeigen
        $masked = $ApiKey.Substring(0, [Math]::Min(8, $ApiKey.Length)) + "..."
        Write-Host "API key saved for service: $Service ($masked)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to save API key: $($_.Exception.Message)"
        return $false
    }
}

function Get-ApiKey {
    <#
    .SYNOPSIS
        Lädt einen verschlüsselten API-Key

    .PARAMETER Service
        Name des Services

    .PARAMETER FilePath
        Pfad zur Speicherdatei

    .PARAMETER UpdateLastUsed
        Aktualisiert das "LastUsed"-Datum

    .EXAMPLE
        $key = Get-ApiKey -Service "OpenAI"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Service,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath = "${env:LOCALAPPDATA}\OpenClaw\api-keys.json",
        
        [Parameter(Mandatory = $false)]
        [switch]$UpdateLastUsed
    )
    
    try {
        if (!(Test-Path $FilePath)) {
            Write-Warning "API keys file not found: $FilePath"
            return $null
        }
        
        $content = Get-Content -Path $FilePath -Raw
        $apiKeys = $content | ConvertFrom-Json -AsHashtable
        
        if (!$apiKeys.ContainsKey($Service)) {
            Write-Warning "API key not found for service: $Service"
            return $null
        }
        
        $keyData = $apiKeys[$Service]
        $decryptedKey = Unprotect-Secret -EncryptedSecret $keyData.Key -Scope $keyData.Scope
        
        if ($UpdateLastUsed) {
            $apiKeys[$Service].LastUsed = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
            $apiKeys | ConvertTo-Json -Depth 5 | Set-Content -Path $FilePath
        }
        
        return $decryptedKey
    }
    catch {
        Write-Error "Failed to get API key: $($_.Exception.Message)"
        return $null
    }
}

function Test-Encryption {
    <#
    .SYNOPSIS
        Testet die Verschlüsselung

    .EXAMPLE
        Test-Encryption
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Testing encryption..." -ForegroundColor Cyan
    
    $testString = "Test-String-12345!@#$%"
    
    try {
        # Verschlüsseln
        $encrypted = Protect-Secret -Secret $testString
        Write-Host "Encrypted: $encrypted"
        
        # Entschlüsseln
        $decrypted = Unprotect-Secret -EncryptedSecret $encrypted
        Write-Host "Decrypted: $decrypted"
        
        # Vergleichen
        if ($decrypted -eq $testString) {
            Write-Host "Encryption test PASSED" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Encryption test FAILED" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Error "Encryption test failed: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================================
# EXPORT
# ============================================================================

Export-ModuleMember -Function @(
    'Protect-Secret',
    'Unprotect-Secret',
    'Save-EncryptedCredential',
    'Get-EncryptedCredential',
    'Remove-EncryptedCredential',
    'Save-ApiKey',
    'Get-ApiKey',
    'Test-Encryption'
)
