#Requires -Version 5.1
<#
.SYNOPSIS
    ECC Dataview Query Generator - Erstellt Dataview-Queries für Obsidian

.DESCRIPTION
    PowerShell-Modul zur Generierung von Dataview-Queries für das ECC Second Brain Framework.
    Erstellt dynamische Übersichten für TODOs, Entscheidungen, Sessions und mehr.

.EXAMPLE
    Get-OpenTodos -GroupByProject
    Get-RecentDecisions -Status "accepted"

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    ECC Framework: Dataview Integration
#>

# Module Variables
$script:ModuleVersion = "1.0.0"

#region Public Functions

<#
.SYNOPSIS
    Gibt eine Dataview-Query für offene TODOs zurück

.PARAMETER GroupByProject
    Gruppiert TODOs nach Projekt

.PARAMETER ShowOverdue
    Zeigt überfällige TODOs

.PARAMETER Priority
    Filter nach Priorität

.OUTPUTS
    String - Dataview-Query
#>
function Get-OpenTodos {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$GroupByProject,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowOverdue,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("high", "medium", "low")]
        [string]$Priority
    )
    
    $query = @"
```dataview
TASK
FROM #todo
WHERE !completed
"@
    
    if ($Priority) {
        $query += "`nAND priority = `"$Priority`""
    }
    
    if ($ShowOverdue) {
        $query += "`nAND dueDate < date(today)"
    }
    
    if ($GroupByProject) {
        $query += @"

GROUP BY file.folder AS Project
"@
    }
    
    $query += @"

SORT priority DESC, dueDate ASC
```
"@
    
    return $query
}

<#
.SYNOPSIS
    Gibt eine Dataview-Query für Entscheidungen zurück

.PARAMETER Status
    Filter nach Status (proposed, accepted, deprecated, superseded)

.PARAMETER Limit
    Maximale Anzahl der Ergebnisse

.OUTPUTS
    String - Dataview-Query
#>
function Get-RecentDecisions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("proposed", "accepted", "deprecated", "superseded", "all")]
        [string]$Status = "all",
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 20
    )
    
    $query = @"
```dataview
TABLE decision_id, status, date
FROM #decision
"@
    
    if ($Status -ne "all") {
        $query += "`nWHERE status = `"$Status`""
    }
    
    $query += @"

SORT date DESC
LIMIT $Limit
```
"@
    
    return $query
}

<#
.SYNOPSIS
    Gibt eine Dataview-Query für Session-Statistiken zurück

.PARAMETER Metric
    Metrik (tokens, duration, count)

.PARAMETER TimeRange
    Zeitraum (day, week, month, year)

.OUTPUTS
    String - Dataview-Query
#>
function Get-SessionStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("tokens", "duration", "count")]
        [string]$Metric = "tokens",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("day", "week", "month", "year")]
        [string]$TimeRange = "week"
    )
    
    $query = @"
```dataview
TABLE session_id, date, tokens_used, agent_mode, key_decisions
FROM "05-Daily"
"@
    
    switch ($TimeRange) {
        "day" { $query += "`nWHERE date >= date(today) - dur(1 day)" }
        "week" { $query += "`nWHERE date >= date(today) - dur(7 days)" }
        "month" { $query += "`nWHERE date >= date(today) - dur(30 days)" }
        "year" { $query += "`nWHERE date >= date(today) - dur(365 days)" }
    }
    
    switch ($Metric) {
        "tokens" { $query += "`nSORT tokens_used DESC" }
        "duration" { $query += "`nSORT duration DESC" }
        "count" { $query += "`nSORT date DESC" }
    }
    
    $query += "`n```"
    
    return $query
}

<#
.SYNOPSIS
    Gibt eine Dataview-Query für Projektübersichten zurück

.PARAMETER Status
    Filter nach Status

.PARAMETER IncludeArchived
    Archivierte Projekte einbeziehen

.OUTPUTS
    String - Dataview-Query
#>
function Get-ProjectOverview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("active", "completed", "archived", "all")]
        [string]$Status = "active",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeArchived
    )
    
    $query = @"
```dataview
TABLE status, startDate, dueDate, completion
FROM "01-Projects"
"@
    
    if ($Status -ne "all") {
        $query += "`nWHERE status = `"$Status`""
    }
    elseif (!$IncludeArchived) {
        $query += "`nWHERE status != `"archived`""
    }
    
    $query += @"

SORT status ASC, startDate DESC
```
"@
    
    return $query
}

<#
.SYNOPSIS
    Gibt eine Dataview-Query für Code-Block-Index zurück

.PARAMETER Language
    Programmiersprache filtern

.PARAMETER Folder
    Ordner filtern

.OUTPUTS
    String - Dataview-Query
#>
function Get-CodeBlockIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Language,
        
        [Parameter(Mandatory = $false)]
        [string]$Folder = "03-Resources/Snippets"
    )
    
    $query = @"
```dataview
LIST
FROM "$Folder"
"@
    
    if ($Language) {
        $query += "`nWHERE file.content contains `"```$Language`""
    }
    else {
        $query += "`nWHERE file.content contains `"````""
    }
    
    $query += @"

SORT file.name ASC
```
"@
    
    return $query
}

<#
.SYNOPSIS
    Gibt eine Dataview-Query für Tag-Cloud zurück

.PARAMETER MinCount
    Minimale Anzahl für Anzeige

.PARAMETER ExcludeSystem
    System-Tags ausschließen

.OUTPUTS
    String - Dataview-Query
#>
function Get-TagCloud {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$MinCount = 2,
        
        [Parameter(Mandatory = $false)]
        [switch]$ExcludeSystem
    )
    
    $query = @"
```dataview
TABLE length(rows) as Count
FLATTEN file.tags as Tag
FROM ""
"@
    
    if ($ExcludeSystem) {
        $query += "`nWHERE !contains([""#decision"", ""#todo"", ""#insight"", ""#session"", ""#context"", ""#project"", ""#area""], Tag)"
    }
    
    $query += @"

GROUP BY Tag
WHERE length(rows) >= $MinCount
SORT length(rows) DESC
```
"@
    
    return $query
}

<#
.SYNOPSIS
    Gibt eine Dataview-Query für Zeiterfassung zurück

.PARAMETER StartDate
    Startdatum

.PARAMETER EndDate
    Enddatum

.OUTPUTS
    String - Dataview-Query
#>
function Get-TimeTracking {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate = (Get-Date).AddDays(-7),
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = (Get-Date)
    )
    
    $startStr = $StartDate.ToString("yyyy-MM-dd")
    $endStr = $EndDate.ToString("yyyy-MM-dd")
    
    $query = @"
```dataview
TABLE sum(duration) as "Total Time"
FROM "05-Daily"
WHERE date >= date("$startStr") AND date <= date("$endStr")
GROUP BY agent_mode
SORT sum(duration) DESC
```
"@
    
    return $query
}

<#
.SYNOPSIS
    Gibt eine vollständige Dashboard-Query zurück

.OUTPUTS
    Hashtable - Sammlung von Queries
#>
function Get-DashboardQuery {
    [CmdletBinding()]
    param()
    
    return @{
        OpenTodos = Get-OpenTodos
        RecentDecisions = Get-RecentDecisions -Limit 10
        SessionStats = Get-SessionStats -Metric "tokens" -TimeRange "week"
        ActiveProjects = Get-ProjectOverview -Status "active"
        CodeBlocks = Get-CodeBlockIndex
        TagCloud = Get-TagCloud -MinCount 3
        TimeTracking = Get-TimeTracking
    }
}

<#
.SYNOPSIS
    Exportiert alle Queries als Markdown-Datei

.PARAMETER OutputPath
    Pfad zur Ausgabedatei

.PARAMETER IncludeDescriptions
    Beschreibungen einfügen
#>
function Export-DataviewQueries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDescriptions
    )
    
    $queries = Get-DashboardQuery
    $content = @"
# Dataview Queries

> Auto-generated Dataview queries for ECC Second Brain

---

"@
    
    foreach ($queryName in $queries.Keys) {
        if ($IncludeDescriptions) {
            $description = switch ($queryName) {
                "OpenTodos" { "All open TODOs grouped by priority" }
                "RecentDecisions" { "Recent architecture decisions" }
                "SessionStats" { "Session statistics and token usage" }
                "ActiveProjects" { "Currently active projects" }
                "CodeBlocks" { "Index of all code blocks" }
                "TagCloud" { "Tag frequency analysis" }
                "TimeTracking" { "Time tracking by agent mode" }
                default { "" }
            }
            
            if ($description) {
                $content += "## $queryName`n`n> $description`n`n"
            }
            else {
                $content += "## $queryName`n`n"
            }
        }
        else {
            $content += "## $queryName`n`n"
        }
        
        $content += $queries[$queryName]
        $content += "`n`n---`n`n"
    }
    
    $content | Set-Content -Path $OutputPath -Encoding UTF8
    
    Write-Host "Exported Dataview queries to: $OutputPath" -ForegroundColor Green
}

#endregion

# Export Module Members
Export-ModuleMember -Function @(
    'Get-OpenTodos',
    'Get-RecentDecisions',
    'Get-SessionStats',
    'Get-ProjectOverview',
    'Get-CodeBlockIndex',
    'Get-TagCloud',
    'Get-TimeTracking',
    'Get-DashboardQuery',
    'Export-DataviewQueries'
)
