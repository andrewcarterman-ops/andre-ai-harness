---
date: 06-04-2026
type: how-to
status: active
tags: [openclaw, powershell, step-by-step, renovation, guide]
source: vault-archive/Main_Obsidian_Vault/Master Rework 06.04.2026/3.0 openclaw-schritt-fuer-schritt-anleitung.md
overlap_checked: true
overlap_with: []
overlap_percentage: 0%
migration_strategy: ADD
reason: Detaillierte PowerShell-Anleitung für Renovierung
---

# OpenClaw Renovierung: Schritt-für-Schritt Anleitung

> **Für Windows PowerShell** - Extrem detailliert  
> **Wichtig:** Wir machen das Schritt für Schritt. Wenn ein Schritt nicht funktioniert, STOPP und frage nach!

---

## SCHRITT 0: Backup erstellen (UNBEDINGT MACHEN!)

### 0.1 PowerShell als Administrator öffnen

1. Drücke `Windows-Taste`
2. Tippe "PowerShell"
3. Klicke rechts auf "Windows PowerShell"
4. Wähle "Als Administrator ausführen"
5. Klicke "Ja" bei der Sicherheitswarnung

### 0.2 Zum OpenClaw-Verzeichnis wechseln

```powershell
# In das OpenClaw-Verzeichnis gehen
cd C:\Users\andre\.openclaw

# Prüfen, ob wir im richtigen Ordner sind
Get-Location
```

**Erwartete Ausgabe:** `C:\Users\andre\.openclaw`

### 0.3 Backup-Ordner erstellen

```powershell
# Backup-Ordner mit Datum erstellen
$datum = Get-Date -Format "yyyyMMdd"
$backupOrdner = "C:\Users\andre\OpenClaw-Backup-$datum"
New-Item -ItemType Directory -Path $backupOrdner -Force

# Den gesamten .openclaw-Ordner kopieren
Copy-Item -Path "C:\Users\andre\.openclaw\*" -Destination $backupOrdner -Recurse -Force

# Prüfen, ob Backup funktioniert hat
Get-ChildItem $backupOrdner
```

**Was passiert hier:**
- Ein Backup-Ordner wird erstellt: `C:\Users\andre\OpenClaw-Backup-20260406`
- Dein gesamtes `.openclaw` wird dorthin kopiert
- Falls etwas schiefgeht, können wir alles wiederherstellen

### 0.4 Git initialisieren (für Versionskontrolle)

```powershell
# Zurück zum .openclaw Ordner
cd C:\Users\andre\.openclaw

# Git initialisieren
git init

# Alle Dateien zum Git hinzufügen
git add .

# Ersten Commit erstellen
git commit -m "Initial commit: OpenClaw Renovierung Start"

# Prüfen
git log
```

---

## SCHRITT 1: Atomic Writes implementieren

### 1.1 Zielverzeichnis erstellen

```powershell
# Neues Verzeichnis für atomare Operationen
New-Item -ItemType Directory -Path "C:\Users\andre\.openclaw\workspace\atomic-ops" -Force

# Test-Datei erstellen
Set-Content -Path "C:\Users\andre\.openclaw\workspace\atomic-ops\test.txt" -Value "Test"
```

### 1.2 PowerShell-Modul für Atomic Writes

```powershell
# Modul-Datei erstellen
$modulePath = "C:\Users\andre\.openclaw\workspace\atomic-ops\AtomicFileOps.psm1"

$moduleContent = @'
function Write-AtomicFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$Content
    )
    
    $tempFile = "$Path.tmp"
    $backupFile = "$Path.bak"
    
    try {
        # Schritt 1: In temporäre Datei schreiben
        Set-Content -Path $tempFile -Value $Content -NoNewline
        
        # Schritt 2: Backup der originalen Datei (falls vorhanden)
        if (Test-Path $Path) {
            Copy-Item -Path $Path -Destination $backupFile -Force
        }
        
        # Schritt 3: Atomares Umbenennen (Windows macht das atomar)
        Move-Item -Path $tempFile -Destination $Path -Force
        
        # Schritt 4: Backup löschen (optional)
        if (Test-Path $backupFile) {
            Remove-Item -Path $backupFile
        }
        
        Write-Host "✅ Datei atomar geschrieben: $Path" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "❌ Fehler beim atomaren Schreiben: $_"
        
        # Rollback: Backup wiederherstellen
        if (Test-Path $backupFile) {
            Move-Item -Path $backupFile -Destination $Path -Force
            Write-Host "🔄 Backup wiederhergestellt" -ForegroundColor Yellow
        }
        
        return $false
    }
    finally {
        # Cleanup
        if (Test-Path $tempFile) {
            Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
        }
    }
}

Export-ModuleMember -Function Write-AtomicFile
'@

Set-Content -Path $modulePath -Value $moduleContent
```

### 1.3 Modul importieren und testen

```powershell
# Modul importieren
Import-Module "C:\Users\andre\.openclaw\workspace\atomic-ops\AtomicFileOps.psm1"

# Testen
Write-AtomicFile -Path "C:\Users\andre\.openclaw\workspace\test-atomic.txt" -Content "Hallo Welt!"

# Prüfen
Get-Content "C:\Users\andre\.openclaw\workspace\test-atomic.txt"
```

---

## Nächste Schritte

Siehe [[openclaw-action-checklist|Action Checklist]] für weitere Tasks.

---

**Original**: openclaw-schritt-fuer-schritt-anleitung.md (16 KB)  
**Status**: Detaillierte Implementierungs-Anleitung