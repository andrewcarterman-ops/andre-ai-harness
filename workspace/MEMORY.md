# MEMORY.md - Kuratiertes Langzeit-Gedächtnis

> Wichtige Erkenntnisse, Patterns und Best Practices
> Automatisch kuratiert aus täglichen Sessions

---

## 🔴 HEILIGE DATEIEN - NIE ÜBERSCHREIBEN OHNE "JA, ÜBERSCHREIBEN"

**Diese Dateien sind HEILIG:**

| Datei | Status | Grund |
|-------|--------|-------|
| **MEMORY.md** | 🔴 HEILIG | Langzeit-Gedächtnis des Agents |
| **SOUL.md** | 🔴 HEILIG | Persönlichkeit und Identität |
| **USER.md** | 🔴 HEILIG | Informationen über Parzival |

**Protokoll für HEILIGE DATEIEN:**
1. Lesen mit `read()` - immer erlaubt
2. Änderungen vorschlagen - im Chat zeigen
3. **Explizites "JA, ÜBERSCHREIBEN" einholen**
4. Dann erst `write()` ausführen

**Fehler = Vertrauensbruch!**

---

## PowerShell Here-Strings: VERBOTEN (2026-04-05)

### Problem
Here-Strings in PowerShell sind extrem fehleranfällig wegen strikter Formatierungsregeln:

```powershell
# FALSCH - fuehrt zu Syntaxfehlern:
$text = @"
    content
    "@      # <- FEHLER: @ ist eingerueckt!

# FALSCH - fuehrt zu Syntaxfehlern:
$text = @"content
mehr content
"@         # <- FEHLER: "@ nicht am Zeilenanfang!
```

**PowerShell-Regel für Here-Strings:**
- `@