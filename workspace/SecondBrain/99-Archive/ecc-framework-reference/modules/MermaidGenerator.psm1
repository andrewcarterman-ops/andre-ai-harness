#Requires -Version 5.1
<#
.SYNOPSIS
    Mermaid Diagram Generator - Vereinfachte Version

.DESCRIPTION
    Erstellt Mermaid-Diagramme für Obsidian.
    Unterstützt: Architekturdiagramme, Flowcharts, Mindmaps, Klassendiagramme.

.EXAMPLE
    New-ArchitectureDiagram -Title "System Architecture" -Components @(...)
    New-Flowchart -Title "Workflow" -Steps @(...)

.NOTES
    Author: Andrew (andrew-main)
    Version: 1.0.0-simplified
    Location: SecondBrain/00-Meta/Scripts/ecc-framework/
#>

# Module Variables
$script:ModuleVersion = "1.0.0"

#region Public Functions

<#
.SYNOPSIS
    Erstellt ein Architekturdiagramm (C4-Style)

.PARAMETER Title
    Titel des Diagramms

.PARAMETER Components
    Array von Komponenten (@{Id="X"; Name="Name"; Type="System"/"Container"/"Component"})

.PARAMETER Relationships
    Array von Beziehungen (@{From="X"; To="Y"; Label="beschreibung"})

.EXAMPLE
    New-ArchitectureDiagram -Title "Mein System" -Components @(
        @{Id="A"; Name="Web App"; Type="Container"},
        @{Id="B"; Name="API"; Type="System"}
    ) -Relationships @(
        @{From="A"; To="B"; Label="HTTP Request"}
    )
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
    
    # Komponenten hinzufügen
    foreach ($component in $Components) {
        $id = $component.Id
        $name = $component.Name
        $type = $component.Type
        
        $style = switch ($type) {
            "Person" { "([$name])" }
            "System" { "[$name]" }
            "Container" { "[[$name]]" }
            "Component" { "[($name)]" }
            default { "[$name]" }
        }
        
        $diagram += "        $id$style" + "`n"
    }
    
    # Beziehungen hinzufügen
    foreach ($rel in $Relationships) {
        $from = $rel.From
        $to = $rel.To
        $label = $rel.Label
        
        if ($label) {
            $diagram += "        $from -->|\"$label\"| $to" + "`n"
        }
        else {
            $diagram += "        $from --> $to" + "`n"
        }
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
    Array von Schritten (@{Id="1"; Text="Schritt"; Type="process"/"decision"/"start"/"end"})

.PARAMETER Direction
    Richtung: TB (Top-Bottom), LR (Left-Right)

.EXAMPLE
    New-Flowchart -Title "Workflow" -Steps @(
        @{Id="A"; Text="Start"; Type="start"},
        @{Id="B"; Text="Verarbeiten"; Type="process"},
        @{Id="C"; Text="Ende"; Type="end"}
    ) -Direction "TB"
#>
function New-Flowchart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Steps,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("TB", "LR")]
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
            default { "[$text]" }
        }
        
        $diagram += "`n    $id$shape"
    }
    
    # Verbindungen (falls Next definiert)
    if ($Steps[0].PSObject.Properties.Name -contains "Next") {
        foreach ($step in $Steps) {
            if ($step.Next) {
                foreach ($next in $step.Next) {
                    $target = $next.Target
                    $label = $next.Label
                    
                    if ($label) {
                        $diagram += "`n    $($step.Id) -->|\"$label\"| $target"
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
    Wurzelknoten (zentraler Begriff)

.PARAMETER Branches
    Array von Zweigen (@{Name="Zweig"; Children=@("Kind1", "Kind2")})

.EXAMPLE
    New-Mindmap -Title "Projektideen" -RootNode "App" -Branches @(
        @{Name="Features"; Children=@("Login", "Dashboard", "Profil")},
        @{Name="Tech"; Children=@("React", "Node.js", "MongoDB")}
    )
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
    Array von Klassen (@{Name="Klasse"; Attributes=@("+name: string"); Methods=@("+methode()")})

.PARAMETER Relationships
    Array von Beziehungen (@{From="A"; To="B"; Type="inheritance"/"composition"/"association"})

.EXAMPLE
    New-ClassDiagram -Title "Datenmodell" -Classes @(
        @{Name="User"; Attributes=@("-id: int", "-name: string"); Methods=@("+login()", "+logout()")},
        @{Name="Admin"; Attributes=@(); Methods=@()}
    ) -Relationships @(
        @{From="Admin"; To="User"; Type="inheritance"}
    )
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

#endregion

# Export Module Members
Export-ModuleMember -Function @(
    'New-ArchitectureDiagram',
    'New-Flowchart',
    'New-Mindmap',
    'New-ClassDiagram'
)
