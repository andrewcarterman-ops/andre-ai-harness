---
date: 03-04-2026
type: knowledge
category: how-to
tags: [how-to, bug, workaround, openclaw, edit-tool]
---

# How-To: Edit-Tool Workaround

> **WICHTIG:** Das `edit` Tool hat einen bekannten Bug. Diese Anleitung zeigt den Workaround.

## Das Problem

Das `edit` Tool kann den `new_string` (oder `newText`) Parameter nicht korrekt an das Gateway übergeben.

**Fehlermeldung:**
```
[tools] edit failed: Missing required parameter: newText (newText or new_string). 
Supply correct parameters before retrying.
```

**Ursache:**
- Gateway validiert den Parameter, aber er kommt nie an
- Getestet mit `new_string` und `newText` - beide funktionieren nicht
- Problem liegt im Gateway-Level (`thread-bindings-*.js`)

---

## Die Lösung: Read + Write Pattern

Statt `edit` zu verwenden, nutze **`read` + `write`**:

### Schritt-für-Schritt

1. **Datei lesen** - Aktuellen Inhalt holen
2. **Inhalt ändern** - Modifikation durchführen  
3. **Datei schreiben** - Neuen Inhalt zurückschreiben

### Beispiel

**❌ FALSCH (edit funktioniert nicht):**
```markdown
edit file.txt
old_string: "alt"
new_string: "neu"
```

**✅ RICHTIG (read + write):**
```markdown
# Schritt 1: Lesen
read file.txt

# Schritt 2: Schreiben (mit komplettem Inhalt)
write file.txt "neuer inhalt"
```

---

## Praktisches Code-Beispiel

### Vorher (mit edit - funktioniert NICHT):
```powershell
# Dies wird FEHLER produzieren:
edit C:\Pfad\zur\Datei.md
old_string: "## Alte Überschrift"
new_string: "## Neue Überschrift"
```

### Nachher (mit read + write - funktioniert):
```powershell
# Schritt 1: Datei lesen
$content = read C:\Pfad\zur\Datei.md

# Schritt 2: Inhalt im Code modifizieren
$newContent = $content -replace "## Alte Überschrift", "## Neue Überschrift"

# Schritt 3: Zurückschreiben
write C:\Pfad\zur\Datei.md $newContent
```

---

## Einschränkungen

| Feature | edit (broken) | read + write (workaround) |
|---------|---------------|---------------------------|
| Präzision | ✅ Nur spezifischer Text | ❌ Ganze Datei |
| Sicherheit | ✅ Rollback möglich | ⚠️ Backup empfohlen |
| Komplexität | ✅ Einfach | ❌ Mehr Schritte |
| Zuverlässigkeit | ❌ Funktioniert nicht | ✅ Funktioniert |

---

## Best Practices

### 1. **Immer Backup erstellen**
```powershell
# Vor dem Schreiben: Backup
Copy-Item "datei.md" "datei.md.backup"
write "datei.md" "neuer inhalt"
```

### 2. **Nur kleine Dateien**
Das `write` Tool ersetzt die **ganze Datei**. Bei großen Dateien:
- Zeitaufwändig
- Token-intensiv

### 3. **Validation nach dem Schreiben**
```powershell
write "datei.md" "neuer inhalt"
$content = read "datei.md"
# Prüfen ob Änderung erfolgreich
```

---

## Wann wird das gefixt?

**Status:** 🔴 Bekanntes Problem, kein Fix-Datum

**Monitoring:**
- [ ] Gateway-Updates beobachten
- [ ] OpenClaw Changelog prüfen
- [ ] Community Issues verfolgen

---

## Verwandte Dokumente

- [[openclaw-code-referenz|Code-Referenz]]
- [[system_memory_vault_architektur|System-Architektur]]

---

*Quelle: Critical-Bug-edit-tool-2026-04-03.md (ECC Framework)*  
*Erstellt: 03-04-2026*  
*Letzte Aktualisierung: 10-04-2026*
