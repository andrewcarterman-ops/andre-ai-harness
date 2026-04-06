# JSONL zu Markdown Konverter
$sourceDir = "C:\Users\andre\.openclaw\agents\main\sessions"
$targetDir = "C:\Users\andre\.openclaw\workspace\second-brain\01-Sessions"

Write-Host "Konvertiere Sessions..." -ForegroundColor Green

# Alle JSONL-Dateien finden (ohne .deleted und .reset)
$jsonlFiles = Get-ChildItem -Path $sourceDir -Filter "*.jsonl" | 
    Where-Object { $_.Name -notmatch "\.deleted\." -and $_.Name -notmatch "\.reset\." }

$count = 0

foreach ($file in $jsonlFiles) {
    $sessionId = $file.BaseName
    $outputFile = Join-Path $targetDir "$sessionId.md"
    
    # Ueberspringen wenn bereits existiert
    if (Test-Path $outputFile) {
        Write-Host "  Ueberspringe (existiert): $sessionId" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "  Konvertiere: $sessionId" -ForegroundColor Cyan
    
    # JSONL einlesen
    $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
    if (-not $lines) { continue }
    
    # Erste Zeile fuer Datum
    $firstLine = $lines | Select-Object -First 1
    $date = $file.LastWriteTime.ToString("yyyy-MM-dd")
    $time = $file.LastWriteTime.ToString("HH:mm")
    
    # Markdown erstellen
    $md = @"
---
date: $date
time: $time
session_id: $sessionId
agent: main
status: converted
tags: [session, converted]
---

# Session: $sessionId

## Konversation

"@

    # Nachrichten hinzufuegen
    foreach ($line in $lines) {
        try {
            $msg = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($msg.role -and $msg.content) {
                $roleName = switch ($msg.role) {
                    "user" { "User" }
                    "assistant" { "Assistant" }
                    "system" { "System" }
                    default { $msg.role }
                }
                $md += "`n### $roleName`n`n$($msg.content)`n`n---`n"
            }
        } catch {
            # Ungueltige Zeile ueberspringen
        }
    }
    
    # Speichern
    $md | Out-File -FilePath $outputFile -Encoding UTF8
    $count++
}

Write-Host "`nFertig! $count Sessions konvertiert." -ForegroundColor Green
