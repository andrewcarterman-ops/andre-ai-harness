---
date: 06-04-2026
type: knowledge
category: how-to
source: "vault-archive/OpenClaw_Harness_Diagnosis.md"
tags: [how-to, openclaw, bug, diagnosis, edit-tool, kimik25, technical-deep-dive]
---

# OpenClaw Harness: Diagnose und Behebung des "Missing required parameter"-Fehlers

> Vollständige technische Analyse des Edit-Tool-Problems mit Kimi K2.5

---

## 1. Executive Summary

### 1.1 Das Problem

```
[tools] edit failed: Missing required parameter: newText (newText or new_string).
```

Diese Fehlermeldung erscheint **systematisch** bei jeder Verwendung des `edit`-Tools mit Kimi K2.5.

**Kritisch:** Nach mehreren Fehlversuchen wechselt Kimi K2.5 automatisch zum `write`-Tool – das **gesamte Dateien überschreibt** und Datenverlust verursachen kann.

| Aspekt | edit-Tool | write-Tool (Fallback) |
|--------|-----------|----------------------|
| Modus | Präzise Textersetzung | Komplette Überschreibung |
| Risiko | Gering | **Hoch – Datenverlust** |
| Idempotenz | Ja | Nein |

---

## 2. Root Cause Analysis

### 2.1 Die drei analytischen Perspektiven

**AI Engineer (Modellverhalten):**
- Kimi K2.5 sendet nur `file_path` und `path`, **nicht** die erforderlichen Text-Parameter
- Andere Modelle (Claude, GPT-4) liefern korrekte Parameter
- **Hypothese:** Modell-spezifische Parameter-Namenskonventionen

**Software-Architekt (Tool-Schema):**
- **OpenClaw 2026.2.9:** Funktionierte
- **OpenClaw 2026.2.12:** Regression eingeführt
- Verdächtige Funktion: `patchToolSchemaForClaudeCompatibility()`

**Integrationsspezialist (API):**
- Moonshot API vs. OpenClaw Tool-Schema Konflikt
- Fehlende Testabdeckung für Kimi K2.5 vor Release

---

## 3. Der kritische Bug

### 3.1 Die fehlerhafte Funktion

`patchToolSchemaForClaudeCompatibility()` in `src/agents/pi-tools.read.ts`

**Zweck:** Fügt Claude-spezifische Parameter-Aliase hinzu
- `old_string` → `oldText`
- `new_string` → `newText`
- `path` → `file_path`

### 3.2 Der Implementierungsfehler

```javascript
// FEHLERHAFT:
required.splice(idx, 1);  // Entfernt nur, fügt nichts hinzu

// KORREKT:
required.splice(idx, 1, alias);  // Ersetzt durch Alias
```

### 3.3 Konsequenzen

| Tool | Ursprünglich required | Nach fehlerhaftem Patch | Reduktion |
|------|----------------------|------------------------|-----------|
| read | 1 (path) | 0 | **100%** |
| edit | 3 (path, oldText, newText) | 0-1 | **67-100%** |
| write | 2 (path, content) | 0-1 | **50-100%** |

Ein **leeres required-Array** (`[]`) signalisiert: "Keine Parameter sind verpflichtend."

**Kimi K2.5** (strikt JSON-Schema-konform) interpretiert dies korrekt und sendet minimale Parameter.

---

## 4. Versions-Geschichte

| Version | Status | Charakteristik |
|---------|--------|----------------|
| 2026.2.9 | ✅ Funktioniert | Letzte stabile Version |
| 2026.2.12 | ❌ Fehler | Einführung des Bugs |
| 2026.3.08 | ❌ Kritischer | Systematischer Edit-Fehler |
| 2026.3.11 | ❌ Kritischer | Vollständiger Tool-Ausfall |
| 2026.3.23 | ❌ Kritischer | Parameter-Silencing: `{}` |

---

## 5. Lösungsstrategien

### 5.1 Kurzfristig: Downgrade (5 Minuten)

```bash
# 1. Deinstallieren
npm uninstall -g @openclaw/harness

# 2. Alte Version installieren
npm install -g @openclaw/harness@2026.2.9

# 3. Verifizieren
openclaw --version  # Sollte 2026.2.9 anzeigen
```

### 5.2 Mittelfristig: read+write Workaround

Wenn edit nicht funktioniert:
```
1. read → Datei komplett laden
2. write → Geänderte Version schreiben
```

⚠️ **Risiko:** Datenverlust bei unvollständigem Kontext

### 5.3 Langfristig: Code-Fix (2-3 Stunden)

**Datei:** `src/agents/pi-tools.read.ts`

```javascript
// Zeile ~45 korrigieren:
required.splice(idx, 1, alias);  // Alias hinzufügen

// Erweiterte Alias-Registrierung in pi-tools.params.ts:
const CLAUDE_PARAM_GROUPS = [
  { keys: ["newText", "new_string", "new_text"], label: "newText" },
  { keys: ["oldText", "old_string", "old_text"], label: "oldText" },
];
```

---

## 6. Parameter-Namenskonflikte

### 6.1 Aktuell unterstützt
- `newText` / `new_string` ✓
- `oldText` / `old_string` ✓

### 6.2 Fehlende Aliase (Issue #42488)
- `new_text` ✗
- `old_text` ✗
- `replacement` ✗

### 6.3 Empfohlene Erweiterung

```javascript
// In CLAUDE_PARAM_GROUPS ergänzen:
{ keys: ["newText", "new_string", "new_text", "replacement"], label: "newText" },
{ keys: ["oldText", "old_string", "old_text"], label: "oldText" },
```

---

## 7. Modell-Vergleich

| Modell | Verhalten | Betroffen |
|--------|-----------|-----------|
| Claude 3.5 Sonnet | Sendet Parameter basierend auf Semantik | Nein |
| GPT-4 | Strikte Folge von required | Potenziell |
| **Kimi K2.5** | **Strikte Folge, sendet minimale Parameter** | **Ja** |
| Qwen 3.5 | Sendet `old_text`/`new_text` | Ja |
| GLM-5 | Ähnlich Kimi K2.5 | Ja |

---

## 8. Nicht erfolgreiche Ansätze

| Ansatz | Warum nicht erfolgreich |
|--------|------------------------|
| Manuelle Prompt-Korrektur | Nicht nachhaltig, modellabhängig |
| Provider-Rekonfiguration | Adressiert nicht die Root Cause |
| Temperatur-Parameter ändern | Kein Einfluss auf Schema-Validierung |

---

## 9. Test-Checkliste

### Nach Fix:
- [ ] edit-Tool mit Kimi K2.5 testen
- [ ] Alle Parameter werden korrekt gesendet
- [ ] Kein automatischer Fallback auf write
- [ ] Andere Modelle weiterhin funktionsfähig
- [ ] Edge Cases (leere Dateien, große Dateien)

---

## 10. Referenzen

**GitHub Issues:**
- #15809: Initialer Bug-Report
- #37645: Detaillierte Analyse des splice-Fehlers
- #42488: Fehlende Aliase
- #44203: Gefährlicher Write-Fallback

**Quellcode:**
- `src/agents/pi-tools.read.ts` – Schema-Patching
- `src/agents/pi-tools.params.ts` – Parameter-Normalisierung

---

## Zusammenfassung

**Der Bug ist ein Einzeiler:**
```javascript
// Von:
required.splice(idx, 1);

// Zu:
required.splice(idx, 1, alias);
```

Dieser Fehler entfernt Original-Parameter aus `required`, fügt aber keine Aliase hinzu → leeres Array → Kimi K2.5 sendet keine Text-Parameter.

**Empfohlene Lösung:**
1. **Sofort:** Downgrade auf 2026.2.9
2. **Mittelfristig:** OpenClaw-Update mit Fix abwarten
3. **Alternativ:** Code-Fix lokal anwenden
