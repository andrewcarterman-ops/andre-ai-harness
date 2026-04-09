#Requires -Version 7.0
<#
.SYNOPSIS
    Dataview Query Generator Module für OpenClaw-Obsidian Integration

.DESCRIPTION
    Dieses Modul bietet Funktionen zur Generierung von Dataview-Queries
    für Obsidian. Es erstellt dynamische Abfragen für TODOs, Entscheidungen,
    Sessions und Projekte.

.FUNCTIONS
    Get-OpenTodos - Generiert Queries für offene TODOs
    Get-RecentDecisions - Generiert Queries für kürzliche Entscheidungen
    Get-SessionStats - Generiert Statistik-Queries für Sessions
    Get-ProjectOverview - Generiert Projekt-Übersichts-Queries
    Get-CodeBlockIndex - Generiert Code-Block-Index-Queries
    Get-TagCloud - Generiert Tag-Cloud-Queries
    Get-TimeTracking - Generiert Zeiterfassungs-Queries
#>

# ============================================================================
# OFFENE TODOS
# ============================================================================

function Get-OpenTodos {
    <#
    .SYNOPSIS
        Generiert Dataview-Queries für offene TODOs

    .PARAMETER GroupBy
        Gruppierung (project, priority, date, none)

    .PARAMETER IncludeCompleted
        Auch abgeschlossene TODOs anzeigen

    .PARAMETER Limit
        Maximale Anzahl der Ergebnisse

    .EXAMPLE
        Get-OpenTodos -GroupBy project -Limit 50
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("project", "priority", "date", "none")]
        [string]$GroupBy = "project",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeCompleted,
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 100,
        
        [Parameter(Mandatory = $false)]
        [string]$FilterTag = ""
    )
    
    $completedFilter = if ($IncludeCompleted) { "" } else { "AND !completed" }
    $tagFilter = if ($FilterTag) { "AND contains(tags, `"$FilterTag`")" } else { "" }
    
    $queries = @{}
    
    # Basis-Query
    $queries.Base = @"
## Offene TODOs

\`\`\`dataview
TASK
FROM "01-Sessions" OR "02-Areas" OR "03-Resources"
WHERE !completed $completedFilter $tagFilter
SORT created DESC
LIMIT $Limit
\`\`\`
"@
    
    # Nach Projekt gruppiert
    if ($GroupBy -eq "project") {
        $queries.ByProject = @"
## TODOs nach Projekt

\`\`\`dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed $completedFilter $tagFilter
GROUP BY project AS Projekt
SORT project ASC
\`\`\`
"@
    }
    
    # Nach Priorität (aus Text extrahiert)
    $queries.ByPriority = @"
## TODOs nach Priorität

### Hohe Priorität (!)
\`\`\`dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed AND text.contains("!") $tagFilter
SORT created DESC
\`\`\`

### Normale Priorität
\`\`\`dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed AND !text.contains("!") AND !text.contains("?") $tagFilter
SORT created DESC
\`\`\`

### Niedrige Priorität (?)
\`\`\`dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed AND text.contains("?") $tagFilter
SORT created DESC
\`\`\`
"@
    
    # Überfällige TODOs
    $queries.Overdue = @"
## Überfällige TODOs

\`\`\`dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed AND created < date(today - 7 days) $tagFilter
SORT created ASC
\`\`\`
"@
    
    # TODO-Statistik
    $queries.Statistics = @"
## TODO-Statistik

\`\`\`dataview
TABLE WITHOUT ID
  length(filter(file.tasks, (t) => !t.completed)) AS "Offen",
  length(filter(file.tasks, (t) => t.completed)) AS "Erledigt",
  length(file.tasks) AS "Gesamt",
  round(length(filter(file.tasks, (t) => t.completed)) / length(file.tasks) * 100, 1) + "%" AS "Fortschritt"
FROM "01-Sessions"
WHERE file.tasks
\`\`\`
"@
    
    return $queries
}

# ============================================================================
# ENTSCHEIDUNGEN
# ============================================================================

function Get-RecentDecisions {
    <#
    .SYNOPSIS
        Generiert Dataview-Queries für Entscheidungen

    .PARAMETER Status
        Filter nach Status (proposed, approved, implemented, rejected, all)

    .PARAMETER DaysBack
        Nur Entscheidungen der letzten X Tage

    .EXAMPLE
        Get-RecentDecisions -Status proposed -DaysBack 30
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("proposed", "approved", "implemented", "rejected", "all")]
        [string]$Status = "all",
        
        [Parameter(Mandatory = $false)]
        [int]$DaysBack = 90,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeUnlinked
    )
    
    $statusFilter = if ($Status -ne "all") { "AND status = `"$Status`"" } else { "" }
    $dateFilter = if ($DaysBack -gt 0) { "AND created >= date(today - $DaysBack days)" } else { "" }
    
    $queries = @{}
    
    # Alle Entscheidungen
    $queries.AllDecisions = @"
## Alle Entscheidungen

\`\`\`dataview
TABLE
  decision AS "Entscheidung",
  status AS "Status",
  project AS "Projekt",
  session_id AS "Session",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE file.name != "README" $statusFilter $dateFilter
SORT created DESC
\`\`\`
"@
    
    # Nach Status gruppiert
    $queries.ByStatus = @"
## Entscheidungen nach Status

### Vorgeschlagen
\`\`\`dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE status = "proposed" $dateFilter
SORT created DESC
\`\`\`

### Genehmigt
\`\`\`dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE status = "approved" $dateFilter
SORT created DESC
\`\`\`

### Implementiert
\`\`\`dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE status = "implemented" $dateFilter
SORT created DESC
\`\`\`

### Verworfen
\`\`\`dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  created AS "Erstellt"
FROM "02-Areas/Decisions"
WHERE status = "rejected" $dateFilter
SORT created DESC
\`\`\`
"@
    
    # Unentschiedene Entscheidungen
    $queries.Undecided = @"
## Unentschiedene Entscheidungen

\`\`\`dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  session_id AS "Session",
  created AS "Erstellt",
  date(today) - created AS "Tage offen"
FROM "02-Areas/Decisions"
WHERE status = "proposed" $dateFilter
SORT created ASC
\`\`\`
"@
    
    # Entscheidungen ohne Backlinks
    if ($IncludeUnlinked) {
        $queries.Unlinked = @"
## Entscheidungen ohne Backlinks

\`\`\`dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt"
FROM "02-Areas/Decisions"
WHERE !outgoing AND !incoming $dateFilter
SORT created DESC
\`\`\`
"@
    }
    
    # Entscheidungs-Timeline
    $queries.Timeline = @"
## Entscheidungs-Timeline

\`\`\`dataview
CALENDAR created
FROM "02-Areas/Decisions"
WHERE status != "rejected" $dateFilter
\`\`\`
"@
    
    return $queries
}

# ============================================================================
# SESSION-STATISTIKEN
# ============================================================================

function Get-SessionStats {
    <#
    .SYNOPSIS
        Generiert Dataview-Queries für Session-Statistiken

    .PARAMETER Metric
        Metrik für Statistiken (tokens, cost, count, duration)

    .PARAMETER GroupBy
        Gruppierung (project, model, date, tag)

    .EXAMPLE
        Get-SessionStats -Metric tokens -GroupBy project
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("tokens", "cost", "count", "duration", "all")]
        [string]$Metric = "all",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("project", "model", "date", "tag", "none")]
        [string]$GroupBy = "project",
        
        [Parameter(Mandatory = $false)]
        [int]$TopN = 10
    )
    
    $queries = @{}
    
    # Übersicht
    $queries.Overview = @"
## Session-Übersicht

\`\`\`dataview
TABLE WITHOUT ID
  length(rows.session_id) AS "Anzahl Sessions",
  sum(rows.token_usage) AS "Gesamt Tokens",
  round(sum(rows.cost), 2) AS "Gesamt Kosten",
  round(avg(rows.token_usage), 0) AS "Ø Tokens/Session"
FROM "01-Sessions"
GROUP BY true
\`\`\`
"@
    
    # Nach Projekt
    if ($GroupBy -eq "project" -or $Metric -eq "all") {
        $queries.ByProject = @"
## Sessions nach Projekt

\`\`\`dataview
TABLE WITHOUT ID
  project AS "Projekt",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
GROUP BY project
SORT sum(rows.token_usage) DESC
LIMIT $TopN
\`\`\`
"@
    }
    
    # Nach Modell
    if ($GroupBy -eq "model" -or $Metric -eq "all") {
        $queries.ByModel = @"
## Token-Usage nach Modell

\`\`\`dataview
TABLE WITHOUT ID
  model AS "Modell",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Gesamt Tokens",
  round(avg(rows.token_usage), 0) AS "Ø Tokens"
FROM "01-Sessions"
GROUP BY model
SORT sum(rows.token_usage) DESC
\`\`\`
"@
    }
    
    # Nach Datum (Timeline)
    if ($GroupBy -eq "date" -or $Metric -eq "all") {
        $queries.ByDate = @"
## Sessions pro Tag

\`\`\`dataview
CALENDAR created
FROM "01-Sessions"
\`\`\`

### Tägliche Statistik
\`\`\`dataview
TABLE WITHOUT ID
  dateformat(created, "yyyy-MM-dd") AS "Datum",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Tokens"
FROM "01-Sessions"
GROUP BY dateformat(created, "yyyy-MM-dd")
SORT dateformat(created, "yyyy-MM-dd") DESC
LIMIT 30
\`\`\`
"@
    }
    
    # Top Sessions nach Token-Usage
    $queries.TopByTokens = @"
## Top Sessions (nach Token-Usage)

\`\`\`dataview
TABLE
  title AS "Titel",
  project AS "Projekt",
  token_usage AS "Tokens",
  cost AS "Kosten",
  model AS "Modell"
FROM "01-Sessions"
SORT token_usage DESC
LIMIT $TopN
\`\`\`
"@
    
    # Kostenanalyse
    $queries.CostAnalysis = @"
## Kostenanalyse

\`\`\`dataview
TABLE WITHOUT ID
  dateformat(created, "yyyy-MM") AS "Monat",
  round(sum(rows.cost), 2) AS "Kosten",
  sum(rows.token_usage) AS "Tokens",
  length(rows.session_id) AS "Sessions"
FROM "01-Sessions"
GROUP BY dateformat(created, "yyyy-MM")
SORT dateformat(created, "yyyy-MM") DESC
\`\`\`
"@
    
    # Aktivitäts-Heatmap
    $queries.ActivityHeatmap = @"
## Aktivitäts-Heatmap

\`\`\`dataview
CALENDAR created
FROM "01-Sessions"
\`\`\`
"@
    
    return $queries
}

# ============================================================================
# PROJEKT-ÜBERSICHT
# ============================================================================

function Get-ProjectOverview {
    <#
    .SYNOPSIS
        Generiert Dataview-Queries für Projekt-Übersichten

    .PARAMETER Status
        Filter nach Projektstatus

    .EXAMPLE
        Get-ProjectOverview -Status active
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("active", "completed", "on-hold", "cancelled", "all")]
        [string]$Status = "all",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetrics
    )
    
    $statusFilter = if ($Status -ne "all") { "AND status = `"$Status`"" } else { "" }
    
    $queries = @{}
    
    # Projekt-Liste
    $queries.ProjectList = @"
## Projekt-Übersicht

\`\`\`dataview
TABLE
  project AS "Projekt",
  status AS "Status",
  priority AS "Priorität",
  start_date AS "Start",
  due_date AS "Fällig",
  progress AS "Fortschritt"
FROM "02-Areas/Projects"
WHERE file.name != "README" $statusFilter
SORT priority DESC, due_date ASC
\`\`\`
"@
    
    # Projekte mit Metriken
    if ($IncludeMetrics) {
        $queries.WithMetrics = @"
## Projekte mit Metriken

\`\`\`dataview
TABLE WITHOUT ID
  project AS "Projekt",
  length(filter(file.tasks, (t) => !t.completed)) AS "Offene TODOs",
  length(filter(file.tasks, (t) => t.completed)) AS "Erledigt",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
WHERE project != null
GROUP BY project
SORT sum(rows.token_usage) DESC
\`\`\`
"@
    }
    
    # Projekte nach Status
    $queries.ByStatus = @"
## Projekte nach Status

### Aktiv
\`\`\`dataview
TABLE
  project AS "Projekt",
  priority AS "Priorität",
  due_date AS "Fällig"
FROM "02-Areas/Projects"
WHERE status = "active"
SORT priority DESC, due_date ASC
\`\`\`

### Abgeschlossen
\`\`\`dataview
TABLE
  project AS "Projekt",
  completion_date AS "Abgeschlossen"
FROM "02-Areas/Projects"
WHERE status = "completed"
SORT completion_date DESC
\`\`\`

### Pausiert
\`\`\`dataview
TABLE
  project AS "Projekt",
  hold_reason AS "Grund"
FROM "02-Areas/Projects"
WHERE status = "on-hold"
SORT due_date ASC
\`\`\`
"@
    
    # Projekt-Timeline
    $queries.Timeline = @"
## Projekt-Timeline

\`\`\`dataview
gantt
    title Projekt-Timeline
    dateFormat yyyy-MM-dd
\`\`\`

### Start-Daten
\`\`\`dataview
CALENDAR start_date
FROM "02-Areas/Projects"
WHERE status = "active"
\`\`\`

### Fälligkeits-Daten
\`\`\`dataview
CALENDAR due_date
FROM "02-Areas/Projects"
WHERE status = "active"
\`\`\`
"@
    
    return $queries
}

# ============================================================================
# CODE-BLOCK INDEX
# ============================================================================

function Get-CodeBlockIndex {
    <#
    .SYNOPSIS
        Generiert Dataview-Queries für Code-Block-Indizes

    .PARAMETER Language
        Filter nach Programmiersprache

    .EXAMPLE
        Get-CodeBlockIndex -Language "powershell"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Language = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent
    )
    
    $langFilter = if ($Language) { "AND file.name.contains(\".$Language\")" } else { "" }
    
    $queries = @{}
    
    # Alle Code-Blocks
    $queries.AllBlocks = @"
## Code-Block Index

\`\`\`dataview
TABLE
  file.name AS "Datei",
  file.ctime AS "Erstellt",
  file.mtime AS "Geändert"
FROM "03-Resources/CodeBlocks"
WHERE file.name != "README" $langFilter
SORT file.ctime DESC
\`\`\`
"@
    
    # Nach Sprache gruppiert
    $queries.ByLanguage = @"
## Code-Blocks nach Sprache

\`\`\`dataview
TABLE WITHOUT ID
  substring(file.name, reverse(string(file.name)).indexOf(".") * -1) AS "Sprache",
  length(rows.file.name) AS "Anzahl",
  rows.file.name AS "Dateien"
FROM "03-Resources/CodeBlocks"
GROUP BY substring(file.name, reverse(string(file.name)).indexOf(".") * -1)
SORT length(rows.file.name) DESC
\`\`\`
"@
    
    # Code-Blocks mit Session-Verknüpfung
    $queries.WithSessionLinks = @"
## Code-Blocks mit Session-Links

\`\`\`dataview
TABLE
  file.name AS "Code-Block",
  file.inlinks AS "Verlinkt von",
  file.ctime AS "Erstellt"
FROM "03-Resources/CodeBlocks"
WHERE file.inlinks $langFilter
SORT file.ctime DESC
\`\`\`
"@
    
    # Unbenutzte Code-Blocks
    $queries.Unused = @"
## Unbenutzte Code-Blocks

\`\`\`dataview
TABLE
  file.name AS "Code-Block",
  file.ctime AS "Erstellt",
  date(today) - file.ctime AS "Tage unbenutzt"
FROM "03-Resources/CodeBlocks"
WHERE !file.inlinks $langFilter
SORT file.ctime ASC
\`\`\`
"@
    
    return $queries
}

# ============================================================================
# TAG CLOUD
# ============================================================================

function Get-TagCloud {
    <#
    .SYNOPSIS
        Generiert Dataview-Queries für Tag-Analysen

    .EXAMPLE
        Get-TagCloud
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$MinCount = 2
    )
    
    $queries = @{}
    
    # Alle Tags
    $queries.AllTags = @"
## Tag-Cloud

\`\`\`dataview
TABLE WITHOUT ID
  tag AS "Tag",
  length(rows.file.name) AS "Häufigkeit",
  rows.file.name AS "Dateien"
FROM "01-Sessions" OR "02-Areas" OR "03-Resources"
FLATTEN tags AS tag
WHERE tag != null
GROUP BY tag
SORT length(rows.file.name) DESC
\`\`\`
"@
    
    # Häufigste Tags
    $queries.TopTags = @"
## Top Tags (min. $MinCount Vorkommen)

\`\`\`dataview
TABLE WITHOUT ID
  tag AS "Tag",
  length(rows.file.name) AS "Häufigkeit"
FROM "01-Sessions" OR "02-Areas" OR "03-Resources"
FLATTEN tags AS tag
WHERE tag != null
GROUP BY tag
SORT length(rows.file.name) DESC
WHERE length(rows.file.name) >= $MinCount
\`\`\`
"@
    
    # Tags nach Kategorie
    $queries.ByCategory = @"
## Tags nach Kategorie

### Projekt-Tags
\`\`\`dataview
LIST
FROM "01-Sessions"
WHERE contains(tags, "project-")
FLATTEN filter(tags, (t) => contains(t, "project-")) AS project_tag
GROUP BY project_tag
\`\`\`

### Technologie-Tags
\`\`\`dataview
LIST
FROM "01-Sessions" OR "03-Resources"
WHERE contains(tags, "tech-") OR contains(tags, "lang-")
FLATTEN filter(tags, (t) => contains(t, "tech-") OR contains(t, "lang-")) AS tech_tag
GROUP BY tech_tag
\`\`\`
"@
    
    return $queries
}

# ============================================================================
# ZEITERFASSUNG
# ============================================================================

function Get-TimeTracking {
    <#
    .SYNOPSIS
        Generiert Dataview-Queries für Zeiterfassung

    .EXAMPLE
        Get-TimeTracking
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("day", "week", "month", "year")]
        [string]$Period = "week"
    )
    
    $queries = @{}
    
    # Tägliche Aktivität
    $queries.Daily = @"
## Tägliche Aktivität

\`\`\`dataview
TABLE WITHOUT ID
  dateformat(created, "yyyy-MM-dd") AS "Datum",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
GROUP BY dateformat(created, "yyyy-MM-dd")
SORT dateformat(created, "yyyy-MM-dd") DESC
LIMIT 30
\`\`\`
"@
    
    # Wöchentliche Zusammenfassung
    $queries.Weekly = @"
## Wöchentliche Zusammenfassung

\`\`\`dataview
TABLE WITHOUT ID
  dateformat(created, "yyyy-'W'WW") AS "Woche",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
GROUP BY dateformat(created, "yyyy-'W'WW")
SORT dateformat(created, "yyyy-'W'WW") DESC
LIMIT 12
\`\`\`
"@
    
    # Monatliche Zusammenfassung
    $queries.Monthly = @"
## Monatliche Zusammenfassung

\`\`\`dataview
TABLE WITHOUT ID
  dateformat(created, "yyyy-MM") AS "Monat",
  length(rows.session_id) AS "Sessions",
  sum(rows.token_usage) AS "Tokens",
  round(sum(rows.cost), 2) AS "Kosten"
FROM "01-Sessions"
GROUP BY dateformat(created, "yyyy-MM")
SORT dateformat(created, "yyyy-MM") DESC
LIMIT 12
\`\`\`
"@
    
    # Aktivitäts-Kalender
    $queries.Calendar = @"
## Aktivitäts-Kalender

\`\`\`dataview
CALENDAR created
FROM "01-Sessions"
\`\`\`
"@
    
    return $queries
}

# ============================================================================
# DASHBOARD QUERY
# ============================================================================

function Get-DashboardQuery {
    <#
    .SYNOPSIS
        Generiert eine komplette Dashboard-Query

    .EXAMPLE
        Get-DashboardQuery
    #>
    [CmdletBinding()]
    param()
    
    $dashboard = @"
# OpenClaw Dashboard

## Schnellübersicht

\`\`\`dataviewjs
const totalSessions = dv.pages('"01-Sessions"').length;
const totalTokens = dv.pages('"01-Sessions"').token_usage.array().reduce((a, b) => a + b, 0);
const totalCost = dv.pages('"01-Sessions"').cost.array().reduce((a, b) => a + b, 0);
const openTodos = dv.pages().file.tasks.where(t => !t.completed).length;
const openDecisions = dv.pages('"02-Areas/Decisions"').where(p => p.status == "proposed").length;

dv.table(
  ["Metrik", "Wert"],
  [
    ["Sessions", totalSessions],
    ["Gesamt Tokens", totalTokens.toLocaleString()],
    ["Gesamt Kosten", "`$" + totalCost.toFixed(2)],
    ["Offene TODOs", openTodos],
    ["Unentschiedene Entscheidungen", openDecisions]
  ]
);
\`\`\`

## Heutige Sessions

\`\`\`dataview
TABLE
  title AS "Titel",
  token_usage AS "Tokens",
  project AS "Projekt"
FROM "01-Sessions"
WHERE created >= date(today)
SORT created DESC
\`\`\`

## Offene TODOs (Top 10)

\`\`\`dataview
TASK
FROM "01-Sessions" OR "02-Areas"
WHERE !completed
SORT created DESC
LIMIT 10
\`\`\`

## Unentschiedene Entscheidungen

\`\`\`dataview
TABLE
  decision AS "Entscheidung",
  project AS "Projekt",
  date(today) - created AS "Tage offen"
FROM "02-Areas/Decisions"
WHERE status = "proposed"
SORT created ASC
LIMIT 5
\`\`\`

## Aktivitäts-Kalender

\`\`\`dataview
CALENDAR created
FROM "01-Sessions"
\`\`\`
"@
    
    return $dashboard
}

# ============================================================================
# EXPORT
# ============================================================================

Export-ModuleMember -Function @(
    'Get-OpenTodos',
    'Get-RecentDecisions',
    'Get-SessionStats',
    'Get-ProjectOverview',
    'Get-CodeBlockIndex',
    'Get-TagCloud',
    'Get-TimeTracking',
    'Get-DashboardQuery'
)
