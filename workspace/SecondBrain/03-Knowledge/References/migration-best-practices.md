---
date: 11-04-2026
type: reference
status: active
tags: [reference, migration, best-practices, safety, quality]
---

# Migration Best Practices: Foolproof & High Quality

> Zusätzliche Safety-Maßnahmen für zukünftige Migrationen jeglicher Art.
> Basierend auf Lessons Learned aus dem Vault-Migration-Fehler.

---

## 1. Vorbereitungsphase (VOR dem ersten Copy)

### 1.1 Vollständiges Backup erstellen
```powershell
# NIE ohne Backup arbeiten!
$backupPath = "00-Meta/Backups/MIGRATION_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $backupPath -ItemType Directory
# Komplettes Quell-Verzeichnis kopieren
Copy-Item -Path "Quelle/*" -Destination $backupPath -Recurse
```

**Wichtig:** Backup muss VOR jeder Änderung existieren!

### 1.2 Ziel-Verzeichnis analysieren
- Was existiert bereits?
- Welche Dateien könnten überschrieben werden?
- Erstelle Liste: "Kollisionsgefahr"

### 1.3 Dry-Run auf 3 Dateien
- Wähle 3 repräsentative Dateien aus
- Führe komplette Migration durch
- VALIDIERE: Inhalt vollständig? Links funktionieren? Formatierung OK?
- ERST dann GO für weitere Dateien

---

## 2. Während der Migration

### 2.1 Inkrementelles Vorgehen (Batches)
| Batch-Größe | Wann anwenden |
|-------------|---------------|
| **1 Datei** | Kritische/unsichere Dateien |
| **3-5 Dateien** | Normale Dateien |
| **Max 10** | Nur bei sehr sicheren, homogenen Dateien |

**Nach jedem Batch:**
1. Pause
2. Validierung durchführen
3. GO für nächsten Batch einholen

### 2.2 Automatisierte Validierung
```powershell
# Nach jeder Migration prüfen:
function Test-Migration {
    param($Source, $Destination)
    
    # 1. Datei existiert?
    if (-not (Test-Path $Destination)) {
        throw "Datei fehlt: $Destination"
    }
    
    # 2. Größe prüfen (nicht leer)
    $destSize = (Get-Item $Destination).Length
    if ($destSize -lt 100) {
        throw "Datei zu klein/leer: $Destination ($destSize Bytes)"
    }
    
    # 3. Inhalt prüfen (keine Platzhalter)
    $content = Get-Content $Destination -Raw
    if ($content -match "Inhalt wurde nicht|Platzhalter|TODO") {
        throw "Unvollständiger Inhalt in: $Destination"
    }
    
    # 4. YAML-Frontmatter valide?
    if ($content -match "^---") {
        # Prüfe ob Frontmatter geschlossen ist
        $matches = [regex]::Matches($content, "---")
        if ($matches.Count -lt 2) {
            throw "Ungültige YAML-Frontmatter in: $Destination"
        }
    }
    
    return $true
}
```

### 2.3 Content-Hash Vergleich
```powershell
# SHA256-Hash vor und nach Migration vergleichen
$sourceHash = Get-FileHash -Path $sourceFile -Algorithm SHA256
$destHash = Get-FileHash -Path $destFile -Algorithm SHA256

if ($sourceHash.Hash -ne $destHash.Hash) {
    Write-Warning "Datei wurde verändert: $filename"
    # Absichtlich? (z.B. Format-Konvertierung) → OK
    # Unabsichtlich? → FEHLER
}
```

---

## 3. Qualitätsprüfungen

### 3.1 Stichproben-Verfahren
| Datei-Typ | Stichproben-Rate |
|-----------|------------------|
| **Kritisch** (ADRs, Projekte) | 100% (alle prüfen) |
| **Wichtig** (Daily Notes) | 50% (jede 2. Datei) |
| **Normal** (Sessions) | 25% (jede 4. Datei) |
| **Gering** (Archiv) | 10% (jede 10. Datei) |

### 3.2 Manuelle Checkliste pro Datei
- [ ] YAML-Frontmatter vorhanden und valide?
- [ ] Titel vorhanden?
- [ ] Inhalt nicht leer (mindestens 500 Zeichen)?
- [ ] Keine Platzhalter-Templates?
- [ ] Links funktionieren (keine Broken Links)?
- [ ] Formatierung korrekt (keine kaputten Tabellen)?
- [ ] Bilder/Attachments referenziert und vorhanden?

### 3.3 Automatisierte Checks
```powershell
# Skript: vault-health-check.ps1
function Test-VaultHealth {
    $issues = @()
    
    # 1. Leere Dateien finden
    $emptyFiles = Get-ChildItem -Recurse -File | Where-Object { $_.Length -lt 200 }
    
    # 2. Fehlende YAML-Frontmatter
    $noFrontmatter = Get-ChildItem -Recurse -File | Where-Object {
        $content = Get-Content $_.FullName -Raw -TotalCount 5
        -not ($content -match "^---")
    }
    
    # 3. Platzhalter finden
    $placeholders = Get-ChildItem -Recurse -File | Where-Object {
        $content = Get-Content $_.FullName -Raw
        $content -match "(Inhalt wurde nicht|TODO|FIXME|XXX|Hier einfügen)"
    }
    
    # 4. Broken WikiLinks finden (einfache Prüfung)
    $allLinks = Get-ChildItem -Recurse -File | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        [regex]::Matches($content, "\[\[([^\]]+)\]\]") | ForEach-Object {
            $link = $_.Groups[1].Value
            # Prüfe ob Ziel existiert...
        }
    }
    
    return @{
        EmptyFiles = $emptyFiles
        NoFrontmatter = $noFrontmatter
        Placeholders = $placeholders
        # BrokenLinks = $brokenLinks
    }
}
```

---

## 4. Menschliche Kontrolle

### 4.1 Vier-Augen-Prinzip
- Eine Person migriert
- Andere Person prüft (oder: DU prüfst meine Arbeit)

### 4.2 Review-Prozess
1. **Pre-Migration Review:** "Das ist mein Plan, stimmt das?"
2. **Post-Migration Review:** "Das habe ich gemacht, bitte prüfen"
3. **Final Review:** Nach 24h nochmal drüberschauen (frische Augen)

### 4.3 Entscheidungsmatrix
| Situation | Wer entscheidet |
|-----------|-----------------|
| Klare 1:1 Migration | Automatisiert |
| Format-Änderung | Agent + User-GO |
| Content-Merge | User muss entscheiden |
| Löschen/Archivieren | User muss entscheiden |
| Unklar | User muss entscheiden |

---

## 5. Rollback-Strategie

### 5.1 Immer rollback-fähig bleiben
```powershell
# Nach jeder Migration:
# 1. Backup behalten (mindestens 7 Tage)
# 2. Änderungen dokumentieren
# 3. Wenn Fehler gefunden → Sofort rollback

function Invoke-Rollback {
    param($BackupPath, $TargetPath)
    
    Write-Host "ROLLBACK wird durchgeführt..."
    Remove-Item -Path $TargetPath -Recurse -Force
    Copy-Item -Path $BackupPath -Destination $TargetPath -Recurse
    Write-Host "ROLLBACK abgeschlossen."
}
```

### 5.2 Rollback-Trigger
- Validierung schlägt fehl
- User sagt "Das ist falsch"
- Fehlende Dateien entdeckt
- Datenverlust-Verdacht

---

## 6. Dokumentation

### 6.1 Migrations-Logbuch
| Timestamp | Aktion | Datei(en) | Ergebnis | Validierung |
|-----------|--------|-----------|----------|-------------|
| 2026-04-11 10:00 | Backup erstellt | komplettes Vault | OK | - |
| 2026-04-11 10:05 | Migration Batch 1 | 5 Daily Notes | OK | Stichprobe OK |
| 2026-04-11 10:15 | Fehler gefunden | 02-04-2026.md | LEER | Rollback |

### 6.2 Fehler-Datenbank
- Was ist schiefgelaufen?
- Warum?
- Wie wurde es behoben?
- Wie verhindern wir das in Zukunft?

---

## 7. Technische Tools

### 7.1 Empfohlene Tools
| Tool | Zweck |
|------|-------|
| **VS Code** | Diff-Vergleich zwischen Quelle/Ziel |
| **Obsidian** | Vault-Übersicht, Link-Prüfung |
| **WinMerge** | Ordner-Vergleich |
| **PowerShell** | Automatisierte Checks |
| **Git** | Versionierung (wenn möglich) |

### 7.2 Git für Migrationen
```bash
# Wenn das Vault in Git ist:
git add .
git commit -m "Pre-Migration Backup"
# ... Migration ...
git diff  # Änderungen anzehen
git status  # Neue/gelöschte Dateien
# Bei Fehler:
git reset --hard HEAD  # Rollback
```

---

## Zusammenfassung: Die goldene Regel

> **"NIE eine Datei löschen oder überschreiben, bevor nicht 100% sicher ist, dass die Migration vollständig und korrekt ist."**

**Prioritäten:**
1. **Datensicherheit** > Geschwindigkeit
2. **Qualität** > Quantität
3. **Validierung** > Annahme
4. **Backup** > Optimierung

---

**Erstellt:** 11-04-2026  
**Status:** Aktiv  
**Anwendung:** Alle zukünftigen Migrationen
