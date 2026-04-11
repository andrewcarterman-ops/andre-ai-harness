---
date: 10-04-2026
type: knowledge
category: reference
tags: [reference, openclaw, bug, diagnosis, edit-tool, technical]
source: "vault-archive/OpenClaw_Harness_Diagnosis.md"
---

# OpenClaw Harness Diagnose: Der "Missing required parameter"-Fehler

## Executive Summary

Das `edit`-Tool in OpenClaw Harness mit Kimi K2.5 als Sprachmodell schlägt systematisch fehl mit der Fehlermeldung:

```
[tools] edit failed: Missing required parameter: newText (newText or new_string). 
Supply correct parameters before retrying.
```

Dies ist ein **deterministischer Softwarefehler** (kein transientes Netzwerkproblem), der bei **jeder** Verwendung des edit-Tools mit Kimi K2.5 auftritt.

---

## 1. Das Problem im Detail

### 1.1 Fehlerbeschreibung

Die Fehlermeldung erscheint mit 100%iger Reproduzierbarkeit. Sie nennt explizit die beiden akzeptierten Parameter-Namen:
- `newText` (camelCase)
- `new_string` (snake_case)

Die Tatsache, dass beide Varianten genannt werden, während der Aufruf fehlschlägt, deutet auf eine tieferliegende Diskrepanz hin.

**Root Cause:** Kimi K2.5 lässt die Text-Parameter vollständig weg und übergibt nur:
```json
{
  "name": "edit",
  "arguments": {
    "file_path": "...",
    "path": "..."
  }
}
```

### 1.2 Kritische Auswirkung: Automatischer Fallback auf "write"

Nach mehreren fehlgeschlagenen Versuchen (bis zu 10x) wechselt der Agent selbstständig zum `write`-Tool:

| Aspekt | edit-Tool | write-Tool (Fallback) |
|--------|-----------|----------------------|
| Operationsmodus | Präzise Textersetzung | Vollständige Dateiüberschreibung |
| Parameter | path, oldText/old_string, newText/new_string | file_path, content |
| Kontexterhaltung | Ja | Nein |
| Risiko | Gering | **Hoch - Datenverlust!** |
| Idempotenz | Ja | Nein |

> ⚠️ **Warnung:** Der Fallback ist "eine ziemlich gefährliche Operation, die leicht zum Verlust großer Datenmengen führen kann."

### 1.3 Betroffene Komponenten

| Komponente | Details |
|------------|---------|
| **System** | OpenClaw Harness |
| **Modell** | Kimi K2.5 (via Moonshot API) |
| **Tool** | edit (Dateibearbeitung) |
| **Kritische Parameter** | newText/new_string (fehlend), oldText/old_string (fehlend) |

---

## 2. Root-Cause-Analyse

### 2.1 Perspektive: AI Engineer (Modellverhalten)

**Beobachtung:** Kimi K2.5 sendet nur `file_path` und `path`, nicht die erforderlichen Text-Parameter.

**Vergleich mit anderen Modellen:**

| Modell | Tool-Calling | Betroffen? |
|--------|--------------|------------|
| Claude 3.5 Sonnet | Sendet alle Parameter | Nein |
| GPT-4 | Folgt required-Array | Potenziell |
| **Kimi K2.5** | **Folgt required-Array strikt** | **Ja** |
| Qwen 3.5 | Sendet old_text/new_text | Ja |

**Hypothese:** Modell-spezifische Parameter-Namenskonventionen (snake_case vs. camelCase) und striktes required-Array-Handling.

### 2.2 Perspektive: Software-Architekt

**Auslöser:** Regression nach Update auf OpenClaw 2026.2.12
- Vorher (2026.2.9): Funktionierte korrekt
- Nachher (2026.2.12): Systematischer Fehler

**Verdächtige Funktion:** `patchToolSchemaForClaudeCompatibility()`
- Entwickelt für Claude-Optimierung
- Wird universell angewendet (auch für nicht-Claude-Modelle)
- Fügt snake_case-Aliase hinzu (old_string, new_string)

**Kritischer Bug:**
```javascript
// FEHLERHAFT (aktuelle Implementierung):
required.splice(idx, 1);  // Entfernt Parameter, fügt nichts hinzu

// KORREKT (sollte sein):
required.splice(idx, 1, alias);  // Ersetzt durch Alias
```

Die Funktion entfernt Original-Parameter aus dem required-Array, fügt aber die Aliase nicht als Ersatz hinzu. Das Resultat ist ein **leeres oder unvollständiges required-Array**.

### 2.3 Perspektive: DevOps/Infrastruktur

**Kimi K2.5-spezifische Auslöser:**
- Interpretiert leeres required-Array als "keine Parameter nötig"
- Claude/GPT senden Parameter trotzdem (robustere Heuristik)

**Gateway-Version als Faktor:**
- Gateway 2026.2.12: Fehler aufgetreten
- Gateway 2026.2.9: Funktionierte

---

## 3. Technische Details

### 3.1 Das Tool-Schema

**Erforderliche Parameter für edit:**

| Parameter | Alias-Varianten | Semantik |
|-----------|-----------------|----------|
| path | file_path | Lokalisierung der Zieldatei |
| oldText | old_string | Zu ersetzender Text |
| newText | new_string | Ersatztext |

### 3.2 Validierungsschichten

1. **Schema-Validierung** ← Hier schlägt der Fehler fehl
2. Inhaltsvalidierung (oldText-Übereinstimmung)
3. Berechtigungsprüfung

### 3.3 Beobachteter Fehler-Modus

```json
// LLM versucht zu senden:
{ "file_path": "test.txt", "old_string": "alt", "new_string": "neu" }

// Tatsächlich gesendet:
{ "file_path": "test.txt", "old_string": "alt" }
// → new_string FEHLt!
```

---

## 4. Verwandte Issues

- **GitHub Issue #15809:** "After updating from OpenClaw 2026.2.9 to 2026.2.12... consistently generates malformed tool calls"
- **GitHub Issue #37645:** Detaillierte technische Analyse des splice()-Bugs
- **GitHub Issue #42488:** Qwen 3.5 mit ähnlichem Problem (old_text/new_text)
- **GitHub Issue #44203:** Beispiel für gefährlichen write-Fallback

---

## 5. Nächste Schritte

Siehe [[openclaw-edit-tool-developer-fix|Teil 2: Lösungen & Workarounds]] für:
- Konkrete Fix-Strategien
- Workarounds für Nutzer
- Implementierungsdetails

---

*Quelle: OpenClaw_Harness_Diagnosis.md (vault-archive)*
*Ursprüngliche Größe: 58 KB - aufgeteilt für bessere Lesbarkeit*
*Teil 1 von 2: Problem & Diagnose*
