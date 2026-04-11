---
date: 10-04-2026
type: knowledge
category: how-to
tags: [how-to, powershell, encoding, lessons-learned, best-practices]
---

# Lessons Learned: PowerShell Skript Erstellung

> Was wir heute gelernt haben - damit Fehler nicht wiederholt werden

---

## Der Anlass

Bei der Erstellung von `setup-symlinks.ps1` traten mehrere kritische Fehler auf:

1. **Parser-Fehler** in Zeile 220 (fehlende Klammer)
2. **Massives Encoding-Problem** (UTF-8 vs Windows-1252)
3. **Fehlende String-Abschlusszeichen**
4. **Inkonsistente Logik** in der Zusammenfassung

---

## Die Fehler im Detail

### 1. Encoding-Problem (Der groesste Fehler)

**Was passierte:**
- UTF-8 Zeichen wurden als Windows-1252 interpretiert
- "🎉" wurde zu "ðŸŽ‰"
- "ä" wurde zu "Ã¤"
- "→" wurde zu "â†’"

**Ursache:**
PowerShell ISE und manche Editoren speichern nicht konsistent als UTF-8 with BOM

**Lösung:**
- NUR ASCII-Zeichen verwenden (keine Emojis)
- Umlaute vermeiden: "ae" statt "ä", "ue" statt "ü", "ss" statt "ß"
- Sonderzeichen vermeiden: "->" statt "→", "-" statt "•"

**Regel fuer Zukunft:**
```powershell
# VERBOTEN in PowerShell-Skripten:
Write-Host "✅ Erfolg!"           # Emojis
Write-Host "Fähigkeiten"          # Umlaute  
Write-Host "→ Weiter"             # Sonderzeichen

# ERLAUBT:
Write-Host "OK: Erfolg!"          # Reiner Text
Write-Host "Faehigkeiten"         # ASCII-Ersatz
Write-Host "-> Weiter"            # ASCII-Ersatz
```

---

### 2. Klammer-Fehler

**Was passierte:**
- Fehlende schliessende Klammer `}` am Ende eines Blocks
- PowerShell meldete: "Unerwartetes Token"

**Ursache:**
- Komplexe verschachtelte Strukturen
- Unaufmerksamkeit beim Schreiben

**Lösung:**
- Nach jedem öffnenden `{` sofort das schliessende `}` schreiben
- Dann den Inhalt einfügen
- IDE mit Syntax-Highlighting verwenden (VS Code)

**Best Practice:**
```powershell
# GUT - Block zuerst schliessen
try {
    # Hier Code einfügen
} catch {
    # Hier Code einfügen
}

# SCHLECHT - Block nicht geschlossen
try {
    # Hier Code einfügen
catch {
    # Hier Code einfügen
# Fehlt: }
```

---

### 3. String-Interpolation mit Klammern

**Was passierte:**
```powershell
Write-Host "(damit Änderungen erkannt werden)"  # Klammern im String
```
PowerShell interpretierte die `()` im String als Code-Ausdruck

**Lösung:**
- Text in einfache Anführungszeichen: `'Text mit (Klammern)'`
- Oder: Keine Klammern im Fliesstext verwenden
- Oder: Escapen mit Backtick: `` `( ``

---

### 4. Inkonsistente Array-Logik

**Was passierte:**
Die Zusammenfassung zeigte "einige konnten nicht erstellt werden" obwohl alles erfolgreich war.

**Ursache:**
- `$results` war ein reguläres Array `@()`
- `Where-Object` Filterung war unklar
- Vergleich `$successful.Count -eq $results.Count` war problematisch

**Lösung:**
- `ArrayList` verwenden für bessere Handhabung
- Explizite Zählung mit `($results | Where-Object { $_.Success -eq $true }).Count`
- Robuste Prüfung: `$successfulCount -eq $totalCount -and $totalCount -gt 0`

**Korrigierter Code:**
```powershell
# ArrayList statt @()
[System.Collections.ArrayList]$results = @()

# Explizite Zählung
$successfulCount = ($results | Where-Object { $_.Success -eq $true }).Count
$failedCount = ($results | Where-Object { $_.Success -eq $false }).Count
$totalCount = $results.Count

# Robuste Prüfung
if ($successfulCount -eq $totalCount -and $totalCount -gt 0) {
    Write-Host "Alles OK!"
}
```

---

### 5. Rückgabewerte müssen konsistent sein

**Was passierte:**
Die Funktion hat manchmal `$true`, manchmal ein Objekt zurückgegeben.

**Ursache:**
```powershell
# Schlecht: Inkonsistente Rückgabetypen
return $true                    # Einmal Boolean
return @{ Success = $true }     # Einmal Objekt
```

**Lösung:**
```powershell
# Gut: Immer das gleiche Format
return @{ Success = $true; Status = "AlreadyExists"; Action = "None" }
return @{ Success = $true; Status = "Created"; Action = "Created" }
return @{ Success = $false; Status = "SourceMissing" }
```

---

### 6. PowerShell-Array-Filterung ist tricky

**Was passierte:**
```powershell
$successful = $results | Where-Object { $_.Success }  # Kann unerwartet sein
```

**Ursache:**
`Where-Object { $_.Success }` filtert nach "truthy" Werten. Bei komplexen Objekten kann das unvorhersehbar sein.

**Lösung:**
```powershell
# Explizite Boolean-Vergleiche verwenden
$successful = @($results | Where-Object { $_.Success -eq $true })
$failed = @($results | Where-Object { $_.Success -eq $false })
```

**Wichtig:**
- `-eq $true` statt nur `{ $_.Success }`
- `-eq $false` statt `{ -not $_.Success }`

---

### 7. "Erfolg" hat verschiedene Bedeutungen

**Was passierte:**
Das Skript hat "bereits vorhanden" nicht als Erfolg gewertet, obwohl es OK ist.

**Ursache:**
Nur "neu erstellt" wurde als Erfolg gewertet, nicht "war schon da".

**Lösung:**
```powershell
# Unterscheide zwischen verschiedenen Erfolgstypen
if ($created.Count -eq $results.Count) {
    "Alle Symlinks erfolgreich erstellt!"
} elseif ($existing.Count -eq $results.Count) {
    "Alle Symlinks bereits vorhanden und gesund!"
} else {
    "Alle Symlinks OK (Teilweise neu, teilweise vorhanden)!"
}
```

---

### 8. Fehlermeldungen müssen kontextspezifisch sein

**Was passierte:**
```
"Einige Symlinks konnten nicht erstellt werden"
```
War auch bei "bereits vorhanden" zu sehen - verwirrend!

**Lösung:**
```powershell
# Spezifische Meldungen je nach Zustand
if ($existing.Count -eq $results.Count) {
    "Alle Symlinks bereits vorhanden und gesund!"
} elseif ($failed.Count -gt 0) {
    "FEHLER: Einige Symlinks konnten nicht erstellt werden"
}
```

---

### 9. Teste alle Code-Pfade

**Was passierte:**
Nur der "happy path" (neue Erstellung) wurde getestet, nicht "bereits vorhanden".

**Lösung:**
```powershell
# Teste explizit:
# 1. Neuen Symlink erstellen
# 2. Bereits vorhandenen Symlink erkennen
# 3. Broken Symlink reparieren
# 4. Fehlerfall (keine Berechtigung)
```

---

> **Wenn PowerShell-Skripte komplex werden:**
> 1. ASCII-only (keine Emojis, keine Umlaute)
> 2. Klammern sofort schliessen
> 3. In VS Code mit PowerShell-Extension schreiben
> 4. Vor dem Speichern: Syntax-Check durchführen
> 5. Encoding explizit auf UTF-8 with BOM setzen

---

## Checkliste fuer zukünftige PowerShell-Skripte

- [ ] Keine Emojis verwendet?
- [ ] Keine Umlaute (ae, oe, ue, ss)?
- [ ] Keine Sonderzeichen (-> statt →)?
- [ ] Alle Klammern geschlossen?
- [ ] Alle Anführungszeichen geschlossen?
- [ ] In VS Code mit Syntax-Highlighting geschrieben?
- [ ] Encoding: UTF-8 with BOM?
- [ ] Getestet mit `powershell -File script.ps1`?

---

## Werkzeuge

**Empfohlener Editor:** VS Code mit PowerShell Extension
- Syntax-Highlighting
- Intellisense
- Fehlererkennung
- Encoding-Anzeige (unten rechts: "UTF-8")

**Testing:**
```powershell
# Vor dem Ausführen: Syntax prüfen
powershell -Command "Get-Command .	est.ps1"

# Oder: ScriptAnalyzer verwenden
Install-Module PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path script.ps1
```

---

Letzte Aktualisierung: 10-04-2026  
Autor: Andrew  
Kontext: setup-symlinks.ps1 Bugfix
