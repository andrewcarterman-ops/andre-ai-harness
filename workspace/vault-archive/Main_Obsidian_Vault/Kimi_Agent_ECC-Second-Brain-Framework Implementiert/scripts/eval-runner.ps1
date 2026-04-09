# ============================================================================
# ECC-CORE Eval Runner
# Second-Brain Framework - CI/CD Evaluation Runner
# ============================================================================
#Requires -Version 5.1
#Requires -Modules @{ ModuleName="powershell-yaml"; ModuleVersion="0.4.2" }

<#
.SYNOPSIS
    Eval-Runner for Second-Brain CI/CD Pipeline

.DESCRIPTION
    Parses YAML evaluation templates, executes tests, and outputs results
    in JSON format for CI/CD integration.

.PARAMETER ConfigPath
    Path to the eval YAML configuration file.

.PARAMETER OutputPath
    Path for JSON output (default: stdout).

.PARAMETER VaultPath
    Path to the Obsidian vault to evaluate.

.PARAMETER Suite
    Specific test suite to run (default: all).

.PARAMETER FailFast
    Stop on first failure.

.EXAMPLE
    .\eval-runner.ps1 -ConfigPath "..\config\eval-template.yaml" -VaultPath "..\SecondBrain"

.EXAMPLE
    .\eval-runner.ps1 -Suite "structure" -OutputPath "..\.logs\eval-results.json"
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$ConfigPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain\config\eval-template.yaml",

    [Parameter()]
    [string]$VaultPath = "C:\Users\andre\Documents\Andrew Openclaw\SecondBrain",

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [string]$Suite,

    [Parameter()]
    [switch]$FailFast
)

# Import required modules
$libPath = Join-Path $PSScriptRoot "lib"
Import-Module (Join-Path $libPath "Logging.psm1") -Force
Import-Module (Join-Path $libPath "ErrorHandler.psm1") -Force

# Initialize logging
Initialize-ECCLogging -BasePath $VaultPath

# Exit codes for CI/CD
$script:ExitCodes = @{
    SUCCESS        = 0
    TEST_FAILURE   = 1
    CONFIG_ERROR   = 2
    RUNTIME_ERROR  = 3
    VAULT_NOT_FOUND = 4
}

<#
.SYNOPSIS
    Loads and parses the eval configuration YAML.
#>
function Get-EvalConfiguration {
    [CmdletBinding()]
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-FatalLog "Configuration file not found: $Path" -Source "EvalRunner"
        exit $script:ExitCodes.CONFIG_ERROR
    }

    try {
        $yamlContent = Get-Content -Path $Path -Raw
        $config = $yamlContent | ConvertFrom-Yaml
        Write-InfoLog "Loaded eval configuration from $Path" -Source "EvalRunner"
        return $config
    }
    catch {
        Write-FatalLog "Failed to parse YAML configuration: $_" -Source "EvalRunner" -ErrorRecord $_
        exit $script:ExitCodes.CONFIG_ERROR
    }
}

<#
.SYNOPSIS
    Runs structure validation tests.
#>
function Test-VaultStructure {
    [CmdletBinding()]
    param(
        [hashtable]$Config,
        [string]$VaultPath
    )

    $results = @{
        Name     = "structure"
        Passed   = 0
        Failed   = 0
        Tests    = @()
        Duration = 0
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Test required folders
    foreach ($folder in $Config.required_folders) {
        $folderPath = Join-Path $VaultPath $folder
        $testResult = @{
            Name    = "FolderExists: $folder"
            Type    = "structure"
            Passed  = Test-Path $folderPath -PathType Container
            Message = if (Test-Path $folderPath) { "Folder exists" } else { "Folder missing: $folder" }
        }
        $results.Tests += $testResult
        if ($testResult.Passed) { $results.Passed++ } else { $results.Failed++ }
    }

    # Test folder structure depth
    $maxDepth = $Config.max_folder_depth
    $folders = Get-ChildItem -Path $VaultPath -Directory -Recurse
    $excessiveDepth = $folders | Where-Object { 
        ($_.FullName.Replace($VaultPath, '').Split('\').Count - 1) -gt $maxDepth 
    }

    $testResult = @{
        Name    = "MaxFolderDepth: $maxDepth"
        Type    = "structure"
        Passed  = $excessiveDepth.Count -eq 0
        Message = if ($excessiveDepth.Count -eq 0) { "All folders within depth limit" } else { "Found $($excessiveDepth.Count) folders exceeding depth $maxDepth" }
    }
    $results.Tests += $testResult
    if ($testResult.Passed) { $results.Passed++ } else { $results.Failed++ }

    $stopwatch.Stop()
    $results.Duration = $stopwatch.ElapsedMilliseconds

    return $results
}

<#
.SYNOPSIS
    Runs metadata validation tests.
#>
function Test-NoteMetadata {
    [CmdletBinding()]
    param(
        [hashtable]$Config,
        [string]$VaultPath
    )

    $results = @{
        Name     = "metadata"
        Passed   = 0
        Failed   = 0
        Tests    = @()
        Duration = 0
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $requiredFields = $Config.required_fields
    $markdownFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse | 
                     Where-Object { $_.DirectoryName -notmatch '\.obsidian' }

    $sampleSize = [math]::Min($Config.sample_size, $markdownFiles.Count)
    $sampleFiles = $markdownFiles | Get-Random -Count $sampleSize

    foreach ($file in $sampleFiles) {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        # Check YAML frontmatter
        if ($content -match '^---\s*\r?\n(.*?)\r?\n---') {
            $frontmatter = $matches[1] | ConvertFrom-Yaml
            
            foreach ($field in $requiredFields) {
                $testResult = @{
                    Name    = "Metadata:$field [$($file.Name)]"
                    Type    = "metadata"
                    Passed  = $frontmatter.ContainsKey($field) -and -not [string]::IsNullOrWhiteSpace($frontmatter[$field])
                    Message = if ($frontmatter.ContainsKey($field)) { "Field '$field' present" } else { "Missing required field: $field" }
                }
                $results.Tests += $testResult
                if ($testResult.Passed) { $results.Passed++ } else { $results.Failed++ }
            }
        }
        else {
            $testResult = @{
                Name    = "FrontmatterExists [$($file.Name)]"
                Type    = "metadata"
                Passed  = $false
                Message = "No YAML frontmatter found"
            }
            $results.Tests += $testResult
            $results.Failed++
        }
    }

    $stopwatch.Stop()
    $results.Duration = $stopwatch.ElapsedMilliseconds

    return $results
}

<#
.SYNOPSIS
    Runs link validation tests.
#>
function Test-NoteLinks {
    [CmdletBinding()]
    param(
        [hashtable]$Config,
        [string]$VaultPath
    )

    $results = @{
        Name     = "links"
        Passed   = 0
        Failed   = 0
        Tests    = @()
        Duration = 0
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $markdownFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse | 
                     Where-Object { $_.DirectoryName -notmatch '\.obsidian' }

    $allLinks = @()
    $brokenLinks = @()

    foreach ($file in $markdownFiles) {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        # Find wiki-links [[...]]
        $wikiLinks = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]') | 
                     ForEach-Object { $_.Groups[1].Value }

        # Find markdown links [...](...)
        $mdLinks = [regex]::Matches($content, '\[([^\]]+)\]\(([^)]+)\)') | 
                   ForEach-Object { $_.Groups[2].Value }

        $allLinks += $wikiLinks
        $allLinks += $mdLinks

        # Check wiki-link targets
        foreach ($link in $wikiLinks) {
            $targetFile = Join-Path $VaultPath "$link.md"
            if (-not (Test-Path $targetFile)) {
                $brokenLinks += @{
                    Source = $file.Name
                    Target = $link
                    Type   = "wiki"
                }
            }
        }
    }

    # Test: No broken links
    $testResult = @{
        Name    = "NoBrokenLinks"
        Type    = "links"
        Passed  = $brokenLinks.Count -eq 0
        Message = if ($brokenLinks.Count -eq 0) { "All links valid" } else { "Found $($brokenLinks.Count) broken links" }
        Details = $brokenLinks
    }
    $results.Tests += $testResult
    if ($testResult.Passed) { $results.Passed++ } else { $results.Failed++ }

    # Test: Minimum links per note
    $minLinks = $Config.min_links_per_note
    $avgLinks = if ($markdownFiles.Count -gt 0) { $allLinks.Count / $markdownFiles.Count } else { 0 }
    
    $testResult = @{
        Name    = "MinLinksPerNote: $minLinks"
        Type    = "links"
        Passed  = $avgLinks -ge $minLinks
        Message = "Average links per note: $([math]::Round($avgLinks, 2))"
    }
    $results.Tests += $testResult
    if ($testResult.Passed) { $results.Passed++ } else { $results.Failed++ }

    $stopwatch.Stop()
    $results.Duration = $stopwatch.ElapsedMilliseconds

    return $results
}

<#
.SYNOPSIS
    Runs quality validation tests.
#>
function Test-NoteQuality {
    [CmdletBinding()]
    param(
        [hashtable]$Config,
        [string]$VaultPath
    )

    $results = @{
        Name     = "quality"
        Passed   = 0
        Failed   = 0
        Tests    = @()
        Duration = 0
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $markdownFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse | 
                     Where-Object { $_.DirectoryName -notmatch '\.obsidian' }

    $sampleSize = [math]::Min($Config.sample_size, $markdownFiles.Count)
    $sampleFiles = $markdownFiles | Get-Random -Count $sampleSize

    $minWords = $Config.min_words_per_note
    $emptyNotes = @()
    $shortNotes = @()

    foreach ($file in $sampleFiles) {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { 
            $emptyNotes += $file.Name
            continue 
        }

        # Remove YAML frontmatter for word count
        $bodyContent = $content -replace '^---\s*\r?\n.*?\r?\n---\s*\r?\n', ''
        $wordCount = ($bodyContent -split '\s+').Count

        if ($wordCount -eq 0) {
            $emptyNotes += $file.Name
        }
        elseif ($wordCount -lt $minWords) {
            $shortNotes += @{
                File  = $file.Name
                Words = $wordCount
            }
        }
    }

    # Test: No empty notes
    $testResult = @{
        Name    = "NoEmptyNotes"
        Type    = "quality"
        Passed  = $emptyNotes.Count -eq 0
        Message = if ($emptyNotes.Count -eq 0) { "No empty notes found" } else { "Found $($emptyNotes.Count) empty notes" }
        Details = $emptyNotes
    }
    $results.Tests += $testResult
    if ($testResult.Passed) { $results.Passed++ } else { $results.Failed++ }

    # Test: Minimum words per note
    $testResult = @{
        Name    = "MinWordsPerNote: $minWords"
        Type    = "quality"
        Passed  = $shortNotes.Count -eq 0
        Message = if ($shortNotes.Count -eq 0) { "All notes meet minimum word count" } else { "Found $($shortNotes.Count) notes below $minWords words" }
        Details = $shortNotes
    }
    $results.Tests += $testResult
    if ($testResult.Passed) { $results.Passed++ } else { $results.Failed++ }

    $stopwatch.Stop()
    $results.Duration = $stopwatch.ElapsedMilliseconds

    return $results
}

<#
.SYNOPSIS
    Main execution function.
#>
function Invoke-EvalRunner {
    [CmdletBinding()]
    param()

    Write-InfoLog "Starting ECC Eval Runner" -Source "EvalRunner"
    Write-InfoLog "Vault Path: $VaultPath" -Source "EvalRunner"
    Write-InfoLog "Config Path: $ConfigPath" -Source "EvalRunner"

    # Validate vault path
    if (-not (Test-Path $VaultPath)) {
        Write-FatalLog "Vault path not found: $VaultPath" -Source "EvalRunner"
        exit $script:ExitCodes.VAULT_NOT_FOUND
    }

    # Load configuration
    $config = Get-EvalConfiguration -Path $ConfigPath

    # Initialize results
    $evalResults = @{
        Timestamp    = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        Version      = $config.version
        VaultPath    = $VaultPath
        TotalPassed  = 0
        TotalFailed  = 0
        TotalTests   = 0
        Duration     = 0
        Suites       = @()
        Success      = $false
    }

    $overallStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Determine which suites to run
    $suitesToRun = if ($Suite) { @($Suite) } else { @('structure', 'metadata', 'links', 'quality') }

    # Run each test suite
    foreach ($suiteName in $suitesToRun) {
        Write-InfoLog "Running suite: $suiteName" -Source "EvalRunner"
        
        $suiteConfig = $config.eval.suites[$suiteName]
        if (-not $suiteConfig) {
            Write-WarnLog "Suite configuration not found: $suiteName" -Source "EvalRunner"
            continue
        }

        if (-not $suiteConfig.enabled) {
            Write-InfoLog "Suite disabled: $suiteName" -Source "EvalRunner"
            continue
        }

        $suiteResults = switch ($suiteName) {
            'structure' { Test-VaultStructure -Config $suiteConfig -VaultPath $VaultPath }
            'metadata'  { Test-NoteMetadata -Config $suiteConfig -VaultPath $VaultPath }
            'links'     { Test-NoteLinks -Config $suiteConfig -VaultPath $VaultPath }
            'quality'   { Test-NoteQuality -Config $suiteConfig -VaultPath $VaultPath }
            default     { $null }
        }

        if ($suiteResults) {
            $evalResults.Suites += $suiteResults
            $evalResults.TotalPassed += $suiteResults.Passed
            $evalResults.TotalFailed += $suiteResults.Failed
            $evalResults.TotalTests += $suiteResults.Tests.Count

            Write-InfoLog "Suite $suiteName completed: $($suiteResults.Passed) passed, $($suiteResults.Failed) failed" -Source "EvalRunner"

            if ($FailFast -and $suiteResults.Failed -gt 0) {
                Write-WarnLog "FailFast enabled, stopping evaluation" -Source "EvalRunner"
                break
            }
        }
    }

    $overallStopwatch.Stop()
    $evalResults.Duration = $overallStopwatch.ElapsedMilliseconds
    $evalResults.Success = $evalResults.TotalFailed -eq 0

    # Output results as JSON
    $jsonOutput = $evalResults | ConvertTo-Json -Depth 10

    if ($OutputPath) {
        $jsonOutput | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-InfoLog "Results written to: $OutputPath" -Source "EvalRunner"
    }
    else {
        Write-Output $jsonOutput
    }

    # Log summary
    Write-InfoLog "Evaluation complete: $($evalResults.TotalPassed) passed, $($evalResults.TotalFailed) failed" -Source "EvalRunner"

    # Return appropriate exit code
    if ($evalResults.TotalFailed -gt 0) {
        exit $script:ExitCodes.TEST_FAILURE
    }
    else {
        exit $script:ExitCodes.SUCCESS
    }
}

# Run main function
Invoke-EvalRunner
