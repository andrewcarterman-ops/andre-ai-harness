#Requires -Version 5.1
<#
.SYNOPSIS
    ECC Mermaid Diagram Generator - Erstellt Mermaid-Diagramme für Obsidian

.DESCRIPTION
    PowerShell-Modul zur Generierung von Mermaid-Diagrammen für das ECC Second Brain Framework.
    Unterstützt Flowcharts, Sequenzdiagramme, Klassendiagramme, Mindmaps und mehr.

.EXAMPLE
    New-ArchitectureDiagram -Title "System Architecture" -Components @(...)

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0
    ECC Framework: Visualization
#>

# Module Variables
$script:ModuleVersion = "1.0.0"
$script:DefaultTheme = "dark"

#region Public Functions

<#
.SYNOPSIS
    Erstellt ein Architekturdiagramm im C4-Style

.PARAMETER Title
    Titel des Diagramms

.PARAMETER Components
    Array von Komponenten

.PARAMETER Relationships
    Array von Beziehungen

.OUTPUTS
    String - Mermaid-Diagramm-Code
#>
function New-ArchitectureDiagram {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Components,
        
        [Parameter(Mandatory = $false)]
        [array]$Relationships = @()
    )
    
    $diagram = @"
```mermaid
graph TB
    subgraph "$Title"
"@
    
    # Add components
    foreach ($component in $Components) {
        $id = $component.Id
        $name = $component.Name
        $type = $component.Type
        $tech = $component.Technology
        
        $style = switch ($type) {
            "Person" { "([$name])" }
            "System" { "[$name]" }
            "Container" { "[[$name]]" }
            "Component" { "[($name)]" }
            default { "[$name]" }
        }
        
        if ($tech) {
            $diagram += "        $id$style`: $tech`"
        }
        else {
            $diagram += "        $id$style"
        }
        $diagram += "`n"
    }
    
    # Add relationships
    foreach ($rel in $Relationships) {
        $from = $rel.From
        $to = $rel.To
        $label = $rel.Label
        
        if ($label) {
            $diagram += "        $from -->|$label| $to"
        }
        else {
            $diagram += "        $from --> $to"
        }
        $diagram += "`n"
    }
    
    $diagram += @"
    end
    
    %% Styling
    classDef person fill:#6366f1,stroke:#4f46e5,color:white
    classDef system fill:#22c55e,stroke:#16a34a,color:white
    classDef container fill:#f59e0b,stroke:#d97706,color:black
    classDef component fill:#8b5cf6,stroke:#7c3aed,color:white
```
"@
    
    return $diagram
}

<#
.SYNOPSIS
    Erstellt ein Flussdiagramm

.PARAMETER Title
    Titel des Diagramms

.PARAMETER Steps
    Array von Schritten

.PARAMETER Direction
    Richtung (TB, BT, LR, RL)

.OUTPUTS
    String - Mermaid-Diagramm-Code
#>
function New-Flowchart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Steps,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("TB", "BT", "LR", "RL")]
        [string]$Direction = "TB"
    )
    
    $diagram = @"
```mermaid
flowchart $Direction
    title[$Title]
"@
    
    foreach ($step in $Steps) {
        $id = $step.Id
        $text = $step.Text
        $type = $step.Type
        
        $shape = switch ($type) {
            "start" { "([$text])" }
            "end" { "([$text])" }
            "process" { "[$text]" }
            "decision" { "{$text}" }
            "input" { "[/$text/]" }
            "output" { "[$text]" }
            default { "[$text]" }
        }
        
        $diagram += "`n    $id$shape"
    }
    
    # Add connections if provided
    if ($Steps[0].PSObject.Properties.Name -contains "Next") {
        foreach ($step in $Steps) {
            if ($step.Next) {
                foreach ($next in $step.Next) {
                    $label = $next.Label
                    $target = $next.Target
                    
                    if ($label) {
                        $diagram += "`n    $($step.Id) -->|$label| $target"
                    }
                    else {
                        $diagram += "`n    $($step.Id) --> $target"
                    }
                }
            }
        }
    }
    
    $diagram += "`n```"
    
    return $diagram
}

<#
.SYNOPSIS
    Erstellt eine Mindmap

.PARAMETER Title
    Titel der Mindmap

.PARAMETER RootNode
    Wurzelknoten

.PARAMETER Branches
    Array von Zweigen

.OUTPUTS
    String - Mermaid-Diagramm-Code
#>
function New-Mindmap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$RootNode,
        
        [Parameter(Mandatory = $true)]
        [array]$Branches
    )
    
    $diagram = @"
```mermaid
mindmap
  root(($RootNode))
"@
    
    foreach ($branch in $Branches) {
        $name = $branch.Name
        $children = $branch.Children
        
        $diagram += "`n    $name"
        
        if ($children) {
            foreach ($child in $children) {
                $diagram += "`n      $child"
            }
        }
    }
    
    $diagram += "`n```"
    
    return $diagram
}

<#
.SYNOPSIS
    Erstellt ein Klassendiagramm

.PARAMETER Title
    Titel des Diagramms

.PARAMETER Classes
    Array von Klassen

.PARAMETER Relationships
    Array von Beziehungen

.OUTPUTS
    String - Mermaid-Diagramm-Code
#>
function New-ClassDiagram {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Classes,
        
        [Parameter(Mandatory = $false)]
        [array]$Relationships = @()
    )
    
    $diagram = @"
```mermaid
classDiagram
    title $Title
"@
    
    foreach ($class in $Classes) {
        $name = $class.Name
        $attributes = $class.Attributes
        $methods = $class.Methods
        
        $diagram += "`n    class $name {"
        
        if ($attributes) {
            foreach ($attr in $attributes) {
                $diagram += "`n        $attr"
            }
        }
        
        if ($methods) {
            foreach ($method in $methods) {
                $diagram += "`n        $method()"
            }
        }
        
        $diagram += "`n    }"
    }
    
    foreach ($rel in $Relationships) {
        $from = $rel.From
        $to = $rel.To
        $type = $rel.Type
        $label = $rel.Label
        
        $arrow = switch ($type) {
            "inheritance" { "<|--" }
            "composition" { "*--" }
            "aggregation" { "o--" }
            "association" { "<--" }
            "dependency" { "<.." }
            default { "<--" }
        }
        
        if ($label) {
            $diagram += "`n    $from $arrow $to : $label"
        }
        else {
            $diagram += "`n    $from $arrow $to"
        }
    }
    
    $diagram += "`n```"
    
    return $diagram
}

<#
.SYNOPSIS
    Erstellt ein Sequenzdiagramm

.PARAMETER Title
    Titel des Diagramms

.PARAMETER Participants
    Array von Teilnehmern

.PARAMETER Messages
    Array von Nachrichten

.OUTPUTS
    String - Mermaid-Diagramm-Code
#>
function New-SequenceDiagram {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Participants,
        
        [Parameter(Mandatory = $true)]
        [array]$Messages
    )
    
    $diagram = @"
```mermaid
sequenceDiagram
    title: $Title
"@
    
    # Add participants
    foreach ($participant in $Participants) {
        $type = $participant.Type
        $name = $participant.Name
        $alias = $participant.Alias
        
        if ($alias) {
            $diagram += "`n    $type $name as $alias"
        }
        else {
            $diagram += "`n    $type $name"
        }
    }
    
    # Add messages
    foreach ($msg in $Messages) {
        $from = $msg.From
        $to = $msg.To
        $text = $msg.Text
        $type = $msg.Type
        
        $arrow = switch ($type) {
            "solid" { "->>" }
            "dashed" { "-->>" }
            "solid-open" { "->" }
            "dashed-open" { "-->" }
            default { "->>" }
        }
        
        $diagram += "`n    $from$arrow$to: $text"
    }
    
    $diagram += "`n```"
    
    return $diagram
}

<#
.SYNOPSIS
    Erstellt ein Zustandsdiagramm

.PARAMETER Title
    Titel des Diagramms

.PARAMETER States
    Array von Zuständen

.PARAMETER Transitions
    Array von Transitionen

.OUTPUTS
    String - Mermaid-Diagramm-Code
#>
function New-StateDiagram {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$States,
        
        [Parameter(Mandatory = $true)]
        [array]$Transitions
    )
    
    $diagram = @"
```mermaid
stateDiagram-v2
    [*] --> $($States[0].Name)
"@
    
    foreach ($state in $States) {
        $name = $state.Name
        $description = $state.Description
        
        if ($description) {
            $diagram += "`n    state `"$name`" as $name {"
            $diagram += "`n        $description"
            $diagram += "`n    }"
        }
    }
    
    foreach ($transition in $Transitions) {
        $from = $transition.From
        $to = $transition.To
        $event = $transition.Event
        
        if ($event) {
            $diagram += "`n    $from --> $to : $event"
        }
        else {
            $diagram += "`n    $from --> $to"
        }
    }
    
    $diagram += "`n```"
    
    return $diagram
}

<#
.SYNOPSIS
    Erstellt ein ER-Diagramm

.PARAMETER Title
    Titel des Diagramms

.PARAMETER Entities
    Array von Entitäten

.PARAMETER Relationships
    Array von Beziehungen

.OUTPUTS
    String - Mermaid-Diagramm-Code
#>
function New-ERDiagram {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Entities,
        
        [Parameter(Mandatory = $false)]
        [array]$Relationships = @()
    )
    
    $diagram = @"
```mermaid
erDiagram
    title $Title
"@
    
    foreach ($entity in $Entities) {
        $name = $entity.Name
        $attributes = $entity.Attributes
        
        $diagram += "`n    $name {"
        
        if ($attributes) {
            foreach ($attr in $attributes) {
                $diagram += "`n        $($attr.Type) $($attr.Name) $($attr.Constraints)"
            }
        }
        
        $diagram += "`n    }"
    }
    
    foreach ($rel in $Relationships) {
        $from = $rel.From
        $to = $rel.To
        $fromCardinality = $rel.FromCardinality
        $toCardinality = $rel.ToCardinality
        $label = $rel.Label
        
        $diagram += "`n    $from $fromCardinality--$toCardinality $to : `"$label`""
    }
    
    $diagram += "`n```"
    
    return $diagram
}

<#
.SYNOPSIS
    Erstellt ein Gantt-Diagramm

.PARAMETER Title
    Titel des Diagramms

.PARAMETER Sections
    Array von Sektionen mit Tasks

.PARAMETER DateFormat
    Datumsformat

.OUTPUTS
    String - Mermaid-Diagramm-Code
#>
function New-GanttChart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Sections,
        
        [Parameter(Mandatory = $false)]
        [string]$DateFormat = "YYYY-MM-DD"
    )
    
    $diagram = @"
```mermaid
gantt
    title $Title
    dateFormat $DateFormat
"@
    
    foreach ($section in $Sections) {
        $sectionName = $section.Name
        $diagram += "`n    section $sectionName"
        
        foreach ($task in $section.Tasks) {
            $name = $task.Name
            $status = $task.Status
            $start = $task.Start
            $duration = $task.Duration
            
            $statusMarker = switch ($status) {
                "done" { "done," }
                "active" { "active," }
                "crit" { "crit," }
                default { "" }
            }
            
            $diagram += "`n        $name :$statusMarker $start, $duration"
        }
    }
    
    $diagram += "`n```"
    
    return $diagram
}

#endregion

# Export Module Members
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
