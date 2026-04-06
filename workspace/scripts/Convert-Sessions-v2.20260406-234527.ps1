# JSONL zu Markdown Konverter (angepasst fuer OpenClaw Format)
$sourceDir = "C:\Users\andre\.openclaw\agents\main\sessions"
$targetDir = "C:\Users\andre\.openclaw\workspace\second-brain\01-Sessions"

Write-Host "Konvertiere Sessions (angepasstes Format)..." -ForegroundColor Green

$jsonlFiles = Get-ChildItem -Path $sourceDir -Filter "*.jsonl" | 
    Where-Object { $_.Name -notmatch "\.deleted\." -and $_.Name -notmatch "\.reset\." }

$count = 0

foreach ($file in $jsonlFiles) {
    $sessionId = $file.BaseName
    $outputFile = Join-Path $targetDir "$sessionId.md"
    
    if (Test-Path $outputFile) {
        Write-Host "  Ueberspringe (existiert): $sessionId" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "  Konvertiere: $sessionId" -ForegroundColor Cyan
    
    $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
    if (-not $lines) { continue }
    
    # Session-Metadaten aus erster Zeile extrahieren
    $sessionMeta = $lines | Select-Object -First 1 | ConvertFrom-Json
    $date = [datetime]$sessionMeta.timestamp
    $dateStr = $date.ToString("yyyy-MM-dd")
    $timeStr = $date.ToString("HH:mm")
    
    # Markdown erstellen
    $md = @"
---
date: $dateStr
time: $timeStr
session_id: $sessionId
agent: main
status: converted
tags: [session, converted]
---

# Session: $sessionId

## Konversation

"@
    
    # Nur Nachrichten verarbeiten (type: "message")
    foreach ($line in $lines) {
        try {
            $entry = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            # Nur Eintraege vom Typ "message" verarbeiten
            if ($entry.type -eq "message" -and $entry.message) {
                $role = $entry.message.role
                $content = $entry.message.content
                
                # Content kann ein Array oder String sein
                $text = ""
                if ($content -is [array]) {
                    # Array von Content-Objekten
                    foreach ($item in $content) {
                        if ($item.type -eq "text" -and $item.text) {
                            $text += $item.text + "`n`n"
                        }
                    }
                } elseif ($content -is [string]) {
                    $text = $content
                }
                
                if ($role -and $text) {
                    $roleName = switch ($role) {
                        "user" { "User" }
                        "assistant" { "Assistant" }
                        "system" { "System" }
                        default { $role }
                    }
                    $md += "`n### $roleName`n`n$text`n---`n"
                }
            }
        } catch {
            # Fehler ueberspringen
        }
    }
    
    # Speichern
    $md | Out-File -FilePath $outputFile -Encoding UTF8
    $count++
}

Write-Host "`nFertig! $count Sessions konvertiert." -ForegroundColor Green
