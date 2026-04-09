#Requires -Version 7.0
<#
.SYNOPSIS
    Mermaid Diagram Generator Module für OpenClaw-Obsidian Integration

.DESCRIPTION
    Dieses Modul bietet Funktionen zur Generierung verschiedener Mermaid-Diagramme
    für die Dokumentation von Systemarchitekturen, Workflows und Mindmaps.

.FUNCTIONS
    New-ArchitectureDiagram - Erstellt Architekturdiagramme
    New-Flowchart - Erstellt Flussdiagramme
    New-Mindmap - Erstellt Mindmaps
    New-ClassDiagram - Erstellt Klassendiagramme
    New-SequenceDiagram - Erstellt Sequenzdiagramme
    New-StateDiagram - Erstellt Zustandsdiagramme
    New-ERDiagram - Erstellt Entity-Relationship-Diagramme
    New-GanttChart - Erstellt Gantt-Diagramme
#>

# ============================================================================
# ARCHITEKTUR-DIAGRAMM
# ============================================================================

function New-ArchitectureDiagram {
    <#
    .SYNOPSIS
        Erstellt ein Mermaid-Architekturdiagramm (C4-Style)

    .PARAMETER Title
        Titel des Diagramms

    .PARAMETER Components
        Hashtable mit Komponenten (Name = @{Type="service|database|external"; Label="..."; Description="..."})

    .PARAMETER Relationships
        Array von Beziehungen (@{From="..."; To="..."; Label="..."; Direction="-->|-.->|==>"})

    .PARAMETER Direction
        Diagramm-Richtung (TB, BT, LR, RL)

    .PARAMETER Style
        Architektur-Stil (simple, c4, kubernetes)

    .EXAMPLE
        $components = @{
            "API" = @{Type="service"; Label="REST API"; Description="Haupt-API"}
            "DB" = @{Type="database"; Label="PostgreSQL"; Description="Hauptdatenbank"}
        }
        $rels = @(@{From="API"; To="DB"; Label="speichert"; Direction="-->"})
        New-ArchitectureDiagram -Title "Systemarchitektur" -Components $components -Relationships $rels
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Components,
        
        [Parameter(Mandatory = $false)]
        [array]$Relationships = @(),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("TB", "BT", "LR", "RL")]
        [string]$Direction = "TB",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("simple", "c4", "kubernetes")]
        [string]$Style = "simple"
    )
    
    $diagram = @"
## $Title

```mermaid
flowchart $Direction
"@
    
    # Knoten-Definitionen mit Styling
    foreach ($name in $Components.Keys) {
        $comp = $Components[$name]
        $safeName = $name -replace '[^\w]', '_'
        
        switch ($Style) {
            "c4" {
                $shape = switch ($comp.Type) {
                    "person" { "([$($comp.Label)])" }
                    "system" { "[[$($comp.Label)]]" }
                    "container" { "[($($comp.Label))]" }
                    "component" { "[[$($comp.Label)]]" }
                    "database" { "[($($comp.Label))]" }
                    "external" { "(([$($comp.Label)]))" }
                    default { "[$($comp.Label)]" }
                }
            }
            "kubernetes" {
                $shape = switch ($comp.Type) {
                    "pod" { "([$($comp.Label)])" }
                    "service" { "[[$($comp.Label)]]" }
                    "deployment" { "[($($comp.Label))]" }
                    "database" { "[($($comp.Label))]" }
                    default { "[$($comp.Label)]" }
                }
            }
            default {
                $shape = switch ($comp.Type) {
                    "database" { "[($($comp.Label))]" }
                    "external" { "(([$($comp.Label)]))" }
                    "service" { "[[$($comp.Label)]]" }
                    default { "[$($comp.Label)]" }
                }
            }
        }
        
        $diagram += "    $safeName$shape`n"
        
        if ($comp.Description) {
            $diagram += "    click $safeName `"$($comp.Description)`"`n"
        }
    }
    
    $diagram += "`n"
    
    # Beziehungen
    foreach ($rel in $Relationships) {
        $from = $rel.From -replace '[^\w]', '_'
        $to = $rel.To -replace '[^\w]', '_'
        $direction = if ($rel.Direction) { $rel.Direction } else { "-->" }
        $label = if ($rel.Label) { "|$($rel.Label)|" } else { "" }
        
        $diagram += "    $from $direction$label $to`n"
    }
    
    # Styling-Klassen
    $diagram += @"
    
    %% Styling
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:2px
    classDef database fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef external fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef service fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
"@
    
    $diagram += "```"
    
    return $diagram
}

# ============================================================================
# FLUSS-DIAGRAMM
# ============================================================================

function New-Flowchart {
    <#
    .SYNOPSIS
        Erstellt ein Mermaid-Flussdiagramm

    .PARAMETER Title
        Titel des Diagramms

    .PARAMETER Steps
        Array von Schritten (@{Id="..."; Label="..."; Type="start|process|decision|end"})

    .PARAMETER Connections
        Array von Verbindungen (@{From="..."; To="..."; Label="..."})

    .PARAMETER Direction
        Diagramm-Richtung (TB, BT, LR, RL)

    .PARAMETER Subgraphs
        Hashtable von Subgraphen

    .EXAMPLE
        $steps = @(
            @{Id="A"; Label="Start"; Type="start"}
            @{Id="B"; Label="Verarbeitung"; Type="process"}
            @{Id="C"; Label="Ende"; Type="end"}
        )
        $conn = @(@{From="A"; To="B"; Label=""}, @{From="B"; To="C"; Label=""})
        New-Flowchart -Title "Workflow" -Steps $steps -Connections $conn
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Steps,
        
        [Parameter(Mandatory = $false)]
        [array]$Connections = @(),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("TB", "BT", "LR", "RL")]
        [string]$Direction = "TB",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Subgraphs = @{}
    )
    
    $diagram = @"
## $Title

```mermaid
flowchart $Direction
"@
    
    # Subgraphen verarbeiten
    $subgraphSteps = @{}
    foreach ($subName in $Subgraphs.Keys) {
        $subSteps = $Subgraphs[$subName]
        $subgraphSteps[$subName] = $subSteps
        
        $diagram += "    subgraph $subName`n"
        foreach ($stepId in $subSteps) {
            $step = $Steps | Where-Object { $_.Id -eq $stepId }
            if ($step) {
                $shape = switch ($step.Type) {
                    "start" { "([$($step.Label)])" }
                    "end" { "([$($step.Label)])" }
                    "decision" { "{$($step.Label)}" }
                    "process" { "[$($step.Label)]" }
                    "input" { "/$($step.Label)/" }
                    default { "[$($step.Label)]" }
                }
                $diagram += "        $($step.Id)$shape`n"
            }
        }
        $diagram += "    end`n"
    }
    
    # Schritte außerhalb von Subgraphen
    foreach ($step in $Steps) {
        $inSubgraph = $false
        foreach ($subSteps in $subgraphSteps.Values) {
            if ($subSteps -contains $step.Id) {
                $inSubgraph = $true
                break
            }
        }
        
        if (-not $inSubgraph) {
            $shape = switch ($step.Type) {
                "start" { "([$($step.Label)])" }
                "end" { "([$($step.Label)])" }
                "decision" { "{$($step.Label)}" }
                "process" { "[$($step.Label)]" }
                "input" { "/$($step.Label)/" }
                default { "[$($step.Label)]" }
            }
            $diagram += "    $($step.Id)$shape`n"
        }
    }
    
    $diagram += "`n"
    
    # Verbindungen
    foreach ($conn in $Connections) {
        $label = if ($conn.Label) { "|$($conn.Label)|" } else { "" }
        $diagram += "    $($conn.From) -->$label $($conn.To)`n"
    }
    
    # Styling
    $diagram += @"
    
    %% Styling
    classDef startEnd fill:#4caf50,stroke:#2e7d32,stroke-width:2px,color:#fff
    classDef process fill:#2196f3,stroke:#1565c0,stroke-width:2px,color:#fff
    classDef decision fill:#ff9800,stroke:#ef6c00,stroke-width:2px,color:#fff
"@
    
    # Klassen zuweisen
    $startEndIds = ($Steps | Where-Object { $_.Type -in @("start", "end") }).Id -join ","
    $processIds = ($Steps | Where-Object { $_.Type -eq "process" }).Id -join ","
    $decisionIds = ($Steps | Where-Object { $_.Type -eq "decision" }).Id -join ","
    
    if ($startEndIds) { $diagram += "    class $startEndIds startEnd`n" }
    if ($processIds) { $diagram += "    class $processIds process`n" }
    if ($decisionIds) { $diagram += "    class $decisionIds decision`n" }
    
    $diagram += "```"
    
    return $diagram
}

# ============================================================================
# MINDMAP
# ============================================================================

function New-Mindmap {
    <#
    .SYNOPSIS
        Erstellt eine Mermaid-Mindmap

    .PARAMETER Title
        Titel der Mindmap

    .PARAMETER Root
        Wurzelknoten-Text

    .PARAMETER Branches
        Hashtable von Zweigen (Key = Zweigname, Value = Array von Unterpunkten)

    .PARAMETER Direction
        Richtung der Mindmap

    .EXAMPLE
        $branches = @{
            "Technologie" = @("Frontend", "Backend", "Datenbank")
            "Prozess" = @("Planung", "Entwicklung", "Deployment")
        }
        New-Mindmap -Title "Projektübersicht" -Root "Projekt" -Branches $branches
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Root,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Branches,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("default", "radial")]
        [string]$Layout = "default"
    )
    
    $diagram = @"
## $Title

```mermaid
mindmap
"@
    
    if ($Layout -eq "radial") {
        $diagram += "  root(($Root))`n"
    }
    else {
        $diagram += "  root($Root)`n"
    }
    
    foreach ($branchName in $Branches.Keys) {
        $items = $Branches[$branchName]
        
        $diagram += "    $branchName`n"
        
        foreach ($item in $items) {
            if ($item -is [hashtable]) {
                $diagram += "      $($item.Name)`n"
                if ($item.Children) {
                    foreach ($child in $item.Children) {
                        $diagram += "        $child`n"
                    }
                }
            }
            else {
                $diagram += "      $item`n"
            }
        }
    }
    
    $diagram += "```"
    
    return $diagram
}

# ============================================================================
# KLASSEN-DIAGRAMM
# ============================================================================

function New-ClassDiagram {
    <#
    .SYNOPSIS
        Erstellt ein Mermaid-Klassendiagramm

    .PARAMETER Title
        Titel des Diagramms

    .PARAMETER Classes
        Hashtable von Klassen

    .PARAMETER Relationships
        Array von Klassenbeziehungen

    .EXAMPLE
        $classes = @{
            "User" = @{
                Attributes = @("-id: string", "-name: string")
                Methods = @("+login()", "+logout()")
            }
        }
        New-ClassDiagram -Title "Domain Model" -Classes $classes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Classes,
        
        [Parameter(Mandatory = $false)]
        [array]$Relationships = @()
    )
    
    $diagram = @"
## $Title

```mermaid
classDiagram
"@
    
    foreach ($className in $Classes.Keys) {
        $class = $Classes[$className]
        
        $diagram += "    class $className {`n"
        
        if ($class.Attributes) {
            foreach ($attr in $class.Attributes) {
                $diagram += "        $attr`n"
            }
        }
        
        if ($class.Attributes -and $class.Methods) {
            $diagram += "        --`n"
        }
        
        if ($class.Methods) {
            foreach ($method in $class.Methods) {
                $diagram += "        $method`n"
            }
        }
        
        $diagram += "    }`n"
    }
    
    foreach ($rel in $Relationships) {
        $type = switch ($rel.Type) {
            "inheritance" { "<|--" }
            "composition" { "*--" }
            "aggregation" { "o--" }
            "association" { "-->" }
            "dependency" { "..>" }
            "realization" { "..|>" }
            default { "-->" }
        }
        $label = if ($rel.Label) { " : $($rel.Label)" } else { "" }
        $diagram += "    $($rel.From) $type $($rel.To)$label`n"
    }
    
    $diagram += "```"
    
    return $diagram
}

# ============================================================================
# SEQUENZ-DIAGRAMM
# ============================================================================

function New-SequenceDiagram {
    <#
    .SYNOPSIS
        Erstellt ein Mermaid-Sequenzdiagramm

    .PARAMETER Title
        Titel des Diagramms

    .PARAMETER Participants
        Array von Teilnehmern

    .PARAMETER Messages
        Array von Nachrichten

    .EXAMPLE
        $participants = @("Client", "API", "Database")
        $messages = @(
            @{From="Client"; To="API"; Message="GET /users"; Type="->>"}
            @{From="API"; To="Database"; Message="SELECT *"; Type="->>"}
        )
        New-SequenceDiagram -Title "API Call" -Participants $participants -Messages $messages
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Participants,
        
        [Parameter(Mandatory = $true)]
        [array]$Messages,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoNumber
    )
    
    $diagram = @"
## $Title

```mermaid
sequenceDiagram
"@
    
    if ($AutoNumber) {
        $diagram += "    autonumber`n"
    }
    
    foreach ($participant in $Participants) {
        if ($participant -is [hashtable]) {
            $type = $participant.Type -replace '[^\w]', ''
            $diagram += "    $type $($participant.Name)`n"
        }
        else {
            $diagram += "    participant $participant`n"
        }
    }
    
    foreach ($msg in $Messages) {
        $type = if ($msg.Type) { $msg.Type } else { "->>" }
        $diagram += "    $($msg.From)$type$($msg.To): $($msg.Message)`n"
    }
    
    $diagram += "```"
    
    return $diagram
}

# ============================================================================
# ZUSTANDS-DIAGRAMM
# ============================================================================

function New-StateDiagram {
    <#
    .SYNOPSIS
        Erstellt ein Mermaid-Zustandsdiagramm

    .PARAMETER Title
        Titel des Diagramms

    .PARAMETER States
        Array von Zuständen

    .PARAMETER Transitions
        Array von Übergängen

    .EXAMPLE
        $states = @("Idle", "Processing", "Completed", "Error")
        $transitions = @(
            @{From="Idle"; To="Processing"; Event="start"}
            @{From="Processing"; To="Completed"; Event="success"}
        )
        New-StateDiagram -Title "Workflow States" -States $states -Transitions $transitions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$States,
        
        [Parameter(Mandatory = $true)]
        [array]$Transitions,
        
        [Parameter(Mandatory = $false)]
        [string]$StartState = "[*]",
        
        [Parameter(Mandatory = $false)]
        [string]$EndState = "[*]"
    )
    
    $diagram = @"
## $Title

```mermaid
stateDiagram-v2
"@
    
    # Start-Übergänge
    $startTransitions = $Transitions | Where-Object { $_.From -eq $StartState }
    foreach ($trans in $startTransitions) {
        $label = if ($trans.Event) { " : $($trans.Event)" } else { "" }
        $diagram += "    [*] --> $($trans.To)$label`n"
    }
    
    # Zustände definieren
    foreach ($state in $States) {
        if ($state -is [hashtable]) {
            $diagram += "    state `"$($state.Name)`" {`n"
            if ($state.Substates) {
                foreach ($sub in $state.Substates) {
                    $diagram += "        $sub`n"
                }
            }
            $diagram += "    }`n"
        }
        else {
            $diagram += "    $state`n"
        }
    }
    
    # Übergänge
    foreach ($trans in $Transitions) {
        if ($trans.From -ne $StartState -and $trans.To -ne $EndState) {
            $label = if ($trans.Event) { " : $($trans.Event)" } else { "" }
            $diagram += "    $($trans.From) --> $($trans.To)$label`n"
        }
    }
    
    # End-Übergänge
    $endTransitions = $Transitions | Where-Object { $_.To -eq $EndState }
    foreach ($trans in $endTransitions) {
        $label = if ($trans.Event) { " : $($trans.Event)" } else { "" }
        $diagram += "    $($trans.From) --> [*]$label`n"
    }
    
    $diagram += "```"
    
    return $diagram
}

# ============================================================================
# ER-DIAGRAMM
# ============================================================================

function New-ERDiagram {
    <#
    .SYNOPSIS
        Erstellt ein Mermaid Entity-Relationship-Diagramm

    .PARAMETER Title
        Titel des Diagramms

    .PARAMETER Entities
        Hashtable von Entitäten

    .PARAMETER Relationships
        Array von Beziehungen

    .EXAMPLE
        $entities = @{
            "USER" = @{Attributes = @("int id PK", "string name")}
            "ORDER" = @{Attributes = @("int id PK", "int user_id FK")}
        }
        New-ERDiagram -Title "Database Schema" -Entities $entities
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Entities,
        
        [Parameter(Mandatory = $false)]
        [array]$Relationships = @()
    )
    
    $diagram = @"
## $Title

```mermaid
erDiagram
"@
    
    foreach ($entityName in $Entities.Keys) {
        $entity = $Entities[$entityName]
        
        $diagram += "    $entityName {`n"
        
        if ($entity.Attributes) {
            foreach ($attr in $entity.Attributes) {
                $diagram += "        $attr`n"
            }
        }
        
        $diagram += "    }`n"
    }
    
    foreach ($rel in $Relationships) {
        $cardinality = switch ($rel.Cardinality) {
            "1:1" { "||--||" }
            "1:N" { "||--o{" }
            "N:1" { "}o--||" }
            "N:M" { "}o--o{" }
            default { "||--o{" }
        }
        $label = if ($rel.Label) { " : $($rel.Label)" } else { "" }
        $diagram += "    $($rel.From) $cardinality $($rel.To)$label`n"
    }
    
    $diagram += "```"
    
    return $diagram
}

# ============================================================================
# GANTT-DIAGRAMM
# ============================================================================

function New-GanttChart {
    <#
    .SYNOPSIS
        Erstellt ein Mermaid-Gantt-Diagramm

    .PARAMETER Title
        Titel des Diagramms

    .PARAMETER Tasks
        Array von Aufgaben

    .PARAMETER Sections
        Hashtable von Sektionen

    .EXAMPLE
        $tasks = @(
            @{Name="Planung"; Duration="5d"; Status="done"}
            @{Name="Entwicklung"; Duration="14d"; Status="active"}
        )
        New-GanttChart -Title "Projektplan" -Tasks $tasks
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Tasks,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Sections = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$DateFormat = "YYYY-MM-DD",
        
        [Parameter(Mandatory = $false)]
        [string]$StartDate = ""
    )
    
    $diagram = @"
## $Title

```mermaid
gantt
    title $Title
    dateFormat $DateFormat
"@
    
    if ($StartDate) {
        $diagram += "    $StartDate`n"
    }
    
    if ($Sections.Count -eq 0) {
        $diagram += "    section Tasks`n"
        foreach ($task in $Tasks) {
            $status = switch ($task.Status) {
                "done" { "done," }
                "active" { "active," }
                "crit" { "crit," }
                default { "" }
            }
            $after = if ($task.After) { "after $($task.After)," } else { "" }
            $diagram += "    $($task.Name) :$status$after $($task.Duration)`n"
        }
    }
    else {
        foreach ($sectionName in $Sections.Keys) {
            $diagram += "    section $sectionName`n"
            $sectionTasks = $Sections[$sectionName]
            
            foreach ($taskName in $sectionTasks) {
                $task = $Tasks | Where-Object { $_.Name -eq $taskName }
                if ($task) {
                    $status = switch ($task.Status) {
                        "done" { "done," }
                        "active" { "active," }
                        "crit" { "crit," }
                        default { "" }
                    }
                    $after = if ($task.After) { "after $($task.After)," } else { "" }
                    $diagram += "    $($task.Name) :$status$after $($task.Duration)`n"
                }
            }
        }
    }
    
    $diagram += "```"
    
    return $diagram
}

# ============================================================================
# EXPORT
# ============================================================================

Export-ModuleMember -Function @(
    'New-ArchitectureDiagram',
    'New-Flowchart',
    'New-Mindmap',
    'New-ClassDiagram',
    'New-SequenceDiagram',
    'New-StateDiagram',
    'New-ERDiagram',
    'New-GanttChart'
)
