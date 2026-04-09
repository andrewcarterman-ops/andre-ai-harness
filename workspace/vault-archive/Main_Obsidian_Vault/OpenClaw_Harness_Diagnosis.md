# OpenClaw Harness: Diagnose und Behebung des "Missing required parameter: newText"-Fehlers

## 1. Executive Summary: Das Problem im Überblick

### 1.1 Fehlerbeschreibung

#### 1.1.1 Terminal-Meldung

Die zentrale Fehlermeldung, die den Anwender konfrontiert, lautet präzise:

```
[tools] edit failed: Missing required parameter: newText (newText or new_string). Supply correct parameters before retrying.
```

Diese Meldung erscheint systematisch bei jeder Verwendung des `edit`-Tools in OpenClaw Harness mit Kimi K2.5 als zugrundeliegendem Sprachmodell. Die Fehlermeldung selbst ist bemerkenswert informativ gestaltet: Sie nennt explizit die beiden akzeptierten Parameter-Namen – `newText` im camelCase-Format und `new_string` im snake_case-Format. Dies impliziert, dass OpenClaw intern ein Alias-System für Parameter-Namen implementiert hat, das verschiedene Modell-Konventionen unterstützen soll.

Die Tatsache, dass beide Varianten in der Fehlermeldung genannt werden, während der Aufruf dennoch fehlschlägt, deutet auf eine tieferliegende Diskrepanz hin: Entweder sendet das Modell diese Parameter unter einem nicht erkannten Namen, oder das Modell lässt sie vollständig weg. Die Analyse der Logs zeigt, dass Kimi K2.5 die Text-Parameter tatsächlich vollständig auslässt und nur `file_path` und `path` übergibt – ein Verhalten, das auf ein defektes Tool-Schema zurückzuführen ist, nicht auf ein Modell-Defizit. Die Fehlermeldung tritt nicht sporadisch auf, sondern mit 100%iger Reproduzierbarkeit, was einen deterministischen Softwarefehler anstelle eines transienten Netzwerk- oder API-Problems signalisiert.

#### 1.1.2 Auswirkung: Automatischer Fallback auf gefährliches "write"-Tool mit Datenverlustrisiko

Die kritischste Konsequenz des edit-Tool-Fehlers manifestiert sich im automatischen Fallback-Verhalten des Agenten. Nach mehreren fehlgeschlagenen Versuchen – in dokumentierten Fällen bis zu zehn Wiederholungen – wechselt Kimi K2.5 selbstständig zum write-Tool, um die beabsichtigte Dateioperation dennoch durchzuführen. Dieses Verhalten ist aus Sicht der Aufgabenerfüllung nachvollziehbar, birgt jedoch erhebliche Risiken für die Datenintegrität:

| Aspekt | edit-Tool | write-Tool (Fallback) |
|--------|-----------|----------------------|
| Operationsmodus | Präzise Textersetzung | Vollständige Dateiüberschreibung |
| Parameter | path, oldText/old_string, newText/new_string | file_path, content |
| Kontexterhaltung | Ja – nur spezifizierter Text wird geändert | Nein – gesamte Datei wird ersetzt |
| Risiko | Gering – fehlgeschlagene Matches werden erkannt | Hoch – Datenverlust bei unvollständigem Kontext |
| Idempotenz | Ja – wiederholbar bei gleichem oldText | Nein – jeder Aufruf überschreibt erneut |

Die Gefahr wird durch die Beobachtung aus GitHub-Issue #44203 verdeutlicht: Der Agent denkt explizit "The edit tool is failing again. Let me use write instead to update the file" und schreibt dabei 1391 Bytes in die Zieldatei – ohne Garantie, dass dieser Inhalt die vollständige, korrekte Datei repräsentiert. Kommentare, Formatierungen, Metadaten oder nicht im Agent-Kontext geladene Dateiabschnitte gehen dabei verloren. Die Formulierung im Issue – "eine ziemlich gefährliche Operation, die leicht zum Verlust großer Datenmengen führen kann" – unterstreicht die Dringlichkeit einer kausalen Lösung anstelle symptomatischer Workarounds.

#### 1.1.3 Häufigkeit: Systematischer Fehler bei jeder Edit-Tool-Verwendung

Die Fehlerhäufigkeit ist als absolut und nicht zufällig zu charakterisieren. Mehrere unabhängige Beobachtungen aus der OpenClaw-Community bestätigen, dass der Fehler bei jedem einzelnen edit-Tool-Aufruf auftritt, sobald Kimi K2.5 als Modell eingesetzt wird. GitHub-Issue #15809 dokumentiert explizit: "After updating from OpenClaw 2026.2.9 to 2026.2.12, the embedded agent using Kimi K2.5 via Moonshot Direct consistently generates malformed tool calls" – wobei "consistently" die fehlende Varianz im Fehlverhalten betont. Diese Systematik ist diagnostisch wertvoll: Sie schließt Modell-Halluzinationen, API-Rate-Limiting und Netzwerkinstabilität weitgehend aus und verweist eindeutig auf eine deterministische Code-Regression.

Die quantitative Dimension der Häufigkeit wird durch die dokumentierte Wiederholungsrate von über zehn fehlgeschlagenen Versuchen pro Operation illustriert. Der Agent versucht wiederholt, das edit-Tool zu verwenden, scheitert jedes Mal an derselben Parameter-Validierung, und wiederholt den Versuch – ohne aus den Fehlschlägen zu lernen oder alternative Parameter-Namen zu explorieren. Dieses Verhalten verdeutlicht die Striktheit der Schema-Validierung in OpenClaw einerseits und die Unfähigkeit des Agenten zur selbstständigen Fehlerkorrektur andererseits. Die systematische Natur ermöglicht zwar zuverlässige Reproduktion für Debugging-Zwecke, bedeutet aber auch, dass keine temporären Workarounds wie "erneuter Versuch" oder "Warten auf API-Stabilisierung" erfolgreich sein können.

### 1.2 Betroffene Komponenten

#### 1.2.1 OpenClaw Harness Setup

Das betroffene System ist OpenClaw Harness in einer spezifischen Konfiguration, die Kimi K2.5 als primäres Sprachmodell nutzt. OpenClaw Harness ist die zentrale Laufzeitumgebung für OpenClaw-Agenten, die die Orchestrierung zwischen Benutzer, Large Language Model und Werkzeugen (Tools) übernimmt. Die "Setup"-Bezeichnung im ursprünglichen Problemhinweis deutet auf eine individuelle Installation hin, typischerweise via npm global (`npm install -g @openclaw/harness`), möglicherweise mit angepassten Konfigurationsdateien oder spezifischen Tool-Profilen.

Die modulare Architektur von OpenClaw umfasst mehrere Schichten, die für die Fehleranalyse relevant sind:

| Schicht | Verantwortlichkeit | Relevante Dateien |
|---------|-------------------|-------------------|
| Agent-Logik | Sitzungsmanagement, Kontextführung | src/agents/pi-agent.ts |
| Tool-Subsystem | Schema-Generierung, Parameter-Normalisierung, Ausführung | src/agents/pi-tools.ts, pi-tools.read.ts, pi-tools.params.ts, pi-tools.schema.ts |
| Provider-Adapter | Modell-spezifische API-Übersetzung | src/providers/openai-completions.ts |
| Konfiguration | Benutzer-spezifische Einstellungen | ~/.openclaw/openclaw.json |

Die Tatsache, dass der Fehler spezifisch für das edit-Tool auftritt, während andere Tools wie read oder write (im Fallback) funktionieren, erlaubt die Schlussfolgerung, dass die Ursache in der spezifischen Schema-Definition oder Parameter-Validierung des edit-Tools zu suchen ist – nicht in der allgemeinen Tool-Infrastruktur. Diese Eingrenzung ist für die gezielte Fehlerbehebung von entscheidender Bedeutung.

#### 1.2.2 LLM-Modell: Kimi K2.5 (via Moonshot OpenAI-kompatible API)

Das verwendete Sprachmodell ist Kimi K2.5, entwickelt von Moonshot AI, über deren OpenAI-kompatible API (api.moonshot.ai) angebunden. Diese Konfiguration ist für das Verständnis des Fehlers zentral, da sie die Schnittstelle zwischen Modell und Framework definiert. Kimi K2.5 hat sich in der OpenClaw-Community als leistungsfähiges, kosteneffizientes Modell etabliert, das besonders bei langen Kontextfenstern (bis zu 200.000 Token) und komplexen Reasoning-Aufgaben überzeugt.

Die OpenAI-kompatible API von Moonshot implementiert den Standard-Chat-Completions-Endpunkt mit Tool-Calling-Erweiterungen. Diese Kompatibilitätsschicht ist einerseits vorteilhaft für die Integration in bestehende Infrastrukturen, birgt jedoch die Gefahr von Subtilitäten bei der Parameter-Übertragung, wenn das Zielmodell nicht exakt das gleiche Verhalten wie OpenAI-Modelle zeigt. Die Tatsache, dass dieselbe Konfiguration mit OpenClaw 2026.2.9 funktionierte, mit 2026.2.12 jedoch nicht mehr, legt nahe, dass Änderungen in OpenClaws Schema-Handling die Kompatibilität mit Kimi K2.5s spezifischer Interpretation der OpenAI-Tool-Spezifikation beeinträchtigt haben. Dies ist ein klassisches Beispiel für "Hyrum's Law" in API-Design: Kimi K2.5 hat sich möglicherweise auf implizite Verhaltensweisen verlassen, die durch OpenClaws explizitere Schema-Manipulation gebrochen wurden.

#### 1.2.3 Tool: edit (Dateibearbeitung)

Das betroffene Tool ist eines der fundamentalen Dateisystem-Werkzeuge in OpenClaws Tool-Set. Es ist konzipiert für präzise, kontextbasierte Textmodifikationen in Dateien und unterscheidet sich damit fundamental vom write-Tool, das komplette Dateien überschreibt. Die Spezifikation des edit-Tools in OpenClaw sieht vor, dass der Agent drei essentielle Parameter bereitstellt:

| Parameter | Alias-Varianten | Semantik |
|-----------|-----------------|----------|
| path | file_path | Lokalisierung der Zieldatei |
| oldText | old_string, old_text (nicht registriert) | Zu ersetzender Textabschnitt |
| newText | new_string, new_text (nicht registriert) | Ersatztext |

Die technische Implementierung involviert mehrere Validierungsschichten: Schema-Validierung (prüft Parameter-Existenz), Inhaltsvalidierung (prüft oldText-Übereinstimmung) und Berechtigungsprüfung. Der beobachtete Fehler tritt in der ersten Schicht auf – die Schema-Validierung schlägt fehl, bevor die inhaltliche Prüfung beginnen kann. Diese frühe Fehlerposition ist diagnostisch wertvoll, da sie den Fehlerursprung auf die Schema-Definition und -Transformation eingrenzt.

#### 1.2.4 Kritische Parameter: newText / new_string (fehlend), oldText / old_string (fehlend)

Die vier kritischen Parameter bilden das Kern-Interface des edit-Tools. Die Existenz von jeweils zwei Namensvarianten (camelCase und snake_case) ist eine bewusste Design-Entscheidung in OpenClaw, um Kompatibilität mit verschiedenen Modell-Typen zu gewährleisten:

- **Claude-Modelle** neigen historisch zu camelCase (oldText, newText)
- **OpenAI-Style-Modelle** bevorzugen snake_case (old_string, new_string)

Die Fehlermeldung nennt explizit `newText (newText or new_string)`, was darauf hindeutet, dass die Validierungslogik beide Varianten akzeptieren würde – wenn sie denn empfangen würden. Die Analyse der tatsächlichen Modell-Ausgaben in Issue #44203 zeigt jedoch, dass Kimi K2.5 die Text-Parameter vollständig weglässt, nicht unter einem alternativen Namen sendet. Ein exemplarischer fehlgeschlagener Aufruf:

```json
{
  "name": "edit",
  "arguments": {
    "file_path": "C:/Users/Admin/.openclaw/workspace/memory/2026-03-12.md",
    "path": "C:/Users/Admin/.openclaw/workspace/memory/2026-03-12.md"
  }
}
```

Diese Beobachtung – Duplizierung des Pfad-Parameters bei vollständiger Absenz der Text-Parameter – deutet auf ein grundlegendes Schema-Kommunikationsproblem hin, das über bloße Namenskonventions-Unterschiede hinausgeht.

---

## 2. Root-Cause-Analyse: Drei analytische Perspektiven

### 2.1 Perspektive: AI Engineer (Modellverhalten)

#### 2.1.1 Beobachtung: Kimi K2.5 sendet nur file_path und path, nicht die erforderlichen Text-Parameter

Aus der Perspektive eines AI Engineers präsentiert sich der Fehler als klares Modell-Verhaltensmuster. Die JSONL-Logs dokumentieren konsistent, dass Kimi K2.5 bei edit-Tool-Aufrufen ausschließlich Pfad-Parameter übergibt, während die für die Operation essentiellen Text-Parameter fehlen. Die Duplizierung von `file_path` und `path` mit identischem Wert ist dabei aufschlussreich: Sie deutet darauf hin, dass das Modell die Alias-Struktur teilweise erkannt hat – beide Namen werden gesendet, um sicherzustellen, dass mindestens einer akzeptiert wird –, aber diese Vorsicht nicht auf die Text-Parameter ausgedehnt wurde.

Dieses selektive Verhalten lässt mehrere Interpretationen zu:

1. Kimi K2.5 könnte das edit-Tool grundlegend anders interpretieren – möglicherweise als reines "Öffnen" einer Datei ohne Modifikationsabsicht.
2. Ein verwirrendes oder überladenes Tool-Schema könnte das Modell dazu bringen, irrelevante Parameter zu priorisieren.
3. Ein Kontextfenster- oder Prompt-Engineering-Problem könnte dazu führen, dass die Parameter-Anforderungen nicht ausreichend betont werden.

Die plausibelste Erklärung, gestützt durch die Versions-Analyse, ist jedoch ein defektes Schema, das keine klaren Required-Constraints kommuniziert.

Die Denkprozesse des Modells (im thinking-Feld der API-Antworten) zeigen, dass Kimi K2.5 durchaus die Absicht hat, Inhalte zu modifizieren – es erkennt explizit, dass der edit-Aufruf fehlschlägt, und plant den Fallback auf write. Dies deutet darauf hin, dass das Modell nicht "versteht", dass seine Parameter-Übergabe unvollständig ist, oder dass es keine Möglichkeit sieht, die korrekten Parameter zu bestimmen. Die Fehlermeldung von OpenClaw wird vom Modell empfangen, aber offenbar nicht als hinreichend informativ interpretiert, um das Verhalten zu korrigieren.

#### 2.1.2 Vergleich: Andere Modelle (Claude, GPT-4) liefern korrekte Parameter

Der kritische Vergleich mit anderen Modellen offenbart die Spezifität des Problems und eliminiert ganze Klassen von Hypothesen:

| Modell | Provider | Tool-Calling-Verhalten | Betroffen von Issue |
|--------|----------|----------------------|---------------------|
| Claude 3.5 Sonnet | Anthropic | Sendet Parameter auch wenn optional, bevorzugt camelCase | Nein |
| GPT-4 | OpenAI | Folgt strikt required-Array, bevorzugt snake_case | Potenziell |
| Kimi K2.5 | Moonshot | Folgt strikt required-Array, sendet leere Objekte wenn required leer | Ja |
| Qwen 3.5 | Alibaba | Sendet old_text/new_text (snake_case mit Unterstrich) | Ja (Issue #42488) |
| GLM-5 | Zhipu | Ähnlich Kimi K2.5, unvollständige Parameter | Ja |

Diese Tabelle verdeutlicht, dass das Problem nicht universell ist, sondern eine spezifische Klasse von Modellen betrifft: solche, die strikt der OpenAI-Tool-Spezifikation folgen und das required-Array als autoritative Quelle für Parameter-Verpflichtung betrachten. Claude-Modelle, die historisch die primären Zielmodelle für OpenClaw waren, zeigen robustere Heuristiken – sie senden Parameter basierend auf semantischer Analyse der Tool-Beschreibung, unabhängig von deren Presence im required-Array. Diese Beobachtung wird durch die Funktionsweise von `patchToolSchemaForClaudeCompatibility()` bestätigt: Die Funktion ist explizit für Claude-Optimierung entworfen, was impliziert, dass andere Modelle diese Optimierungen nicht benötigen oder sogar negativ beeinflusst werden.

#### 2.1.3 Hypothese: Modell-spezifische Parameter-Namenskonventionen (snake_case vs. camelCase)

Die zentrale Hypothese aus AI-Engineering-Perspektive postuliert, dass Kimi K2.5 spezifische Konventionen für Parameter-Namen erwartet oder generiert, die nicht vollständig vom Alias-System von OpenClaw abgedeckt sind. Die etablierten Alias-Paare in OpenClaw sind:

- `old_string` → `oldText`
- `new_string` → `newText`

Die Analyse von Issue #42488 offenbart jedoch eine dritte Variante: Modelle wie Qwen 3.5 senden Parameter-Namen im Format `old_text` und `new_text` – also snake_case mit Unterstrich, aber ohne das `_string`-Suffix. Diese Variante ist weder identisch mit `old_string` noch mit `oldText` und wird daher vom aktuellen Alias-System nicht erkannt.

Für Kimi K2.5 ist die Situation komplexer. Die Logs zeigen vollständiges Fehlen der Text-Parameter, nicht alternative Namen. Dies deutet auf das primäre Problem des leeren required-Arrays hin, nicht auf fehlende Alias-Registrierung. Es ist jedoch plausibel, dass in Szenarien mit korrektem required-Array Kimi K2.5 ebenfalls `new_text`/`old_text` generieren würde, da dies der konsistenten snake_case-Konvention entspricht, die das Modell bei `file_path` bereits demonstriert.

Die beiden Probleme – leeres required-Array und fehlende new_text/old_text-Alias – sind als separate, aber potenziell kumulative Ursachen zu betrachten. Ein vollständiger Fix muss beide Aspekte adressieren.

### 2.2 Perspektive: Software-Architekt (Tool-Schema-Design)

#### 2.2.1 OpenClaw-Version als Auslöser: Regression nach Update auf 2026.2.12

Aus software-architektonischer Perspektive ist die Versionsgeschichte des Problems der entscheidende Ausgangspunkt. Issue #15809 dokumentiert präzise:

> "After updating from OpenClaw 2026.2.9 to 2026.2.12, the embedded agent using Kimi K2.5 via Moonshot Direct consistently generates malformed tool calls. This worked correctly on 2026.2.9."

Diese binäre Zustandsänderung – von "working correctly" zu "consistently generates malformed" – innerhalb eines Patch-Version-Updates deutet eindeutig auf eine eingeführte Regression hin. Die zeitliche Einordnung im Februar 2026 platziert die Änderung in einen Kontext aktiver Entwicklung der Claude-Integration, was die Hypothese einer Claude-zentrierten Optimierung mit unbeabsichtigten Seiteneffekten stützt.

Die Release-Geschwindigkeit von OpenClaw – mit mehreren Versionen pro Monat – erzeugt Druck, der möglicherweise zu Kürzungen in der Testabdeckung führt. Die Tatsache, dass ein Patch-Release, typischerweise für Bugfixes vorgesehen, einen neuen, schwerwiegenden Fehler einführte, deutet auf eine unzureichende Testmatrix für nicht-Claude-Modelle hin. Für Nutzer, die eine sofortige Lösung benötigen, ist die Kenntnis dieser Versionsgeschichte kritisch: Ein Downgrade auf 2026.2.9 ist die zuverlässigste kurzfristige Maßnahme.

#### 2.2.2 Verdächtige Funktion: patchToolSchemaForClaudeCompatibility()

Die Funktion `patchToolSchemaForClaudeCompatibility()` tritt als primärer Verdächtiger in den Fokus der architektonischen Analyse. Der Funktionsname selbst ist aufschlussreich: Eine Funktion, die explizit für "Claude Compatibility" entwickelt wurde, wird universell angewendet, unabhängig davon, welches Modell tatsächlich verwendet wird. Diese "one-size-fits-all"-Annäherung an Modell-Kompatibilität ist anfällig für die beobachteten Probleme, wenn Modelle mit unterschiedlichen Erwartungen an die Schema-Struktur auf das gleiche gepatchte Schema stoßen.

Die Funktion ist lokalisiert in `src/agents/pi-tools.read.ts` und wird bei der Tool-Schema-Generierung aufgerufen. Ihre dokumentierte Funktionalität umfasst das Hinzufügen von Parameter-Aliasen:

| Original-Name | Alias (Claude-Stil) | Intention |
|---------------|---------------------|-----------|
| path | file_path | Explizitere Semantik |
| oldText | old_string | snake_case-Präferenz |
| newText | new_string | snake_case-Präferenz |

Die architektonische Kritik an dieser Funktion ist zweifach:

1. Die Spezialisierung auf ein einzelne Modellfamilie (Claude) ohne ausreichende Abstraktion für andere Modelle ist ein Verstoß gegen das Open/Closed Principle.
2. Die Alias-Einführung ohne vollständige Schema-Validierung – insbesondere die Aktualisierung des required-Arrays – führt zu inkonsistenten Schemata.

#### 2.2.3 Schema-Änderungen: Hinzufügen von Aliasen (old_string→oldText, new_string→newText)

Die spezifischen Schema-Änderungen in Version 2026.2.12 betrafen die Parameter-Namenskonvention für das edit-Tool. Die ursprüngliche Spezifikation nutzte camelCase (oldText, newText), die gepatchte Version fügte snake_case-Aliase (old_string, new_string) hinzu. Diese Änderung war motiviert durch Claude-Modelle, die in ihren Trainingsdaten snake_case-Parameter bevorzugen.

Die technische Implementierung dieser Aliase erfordert zwei koordinierte Operationen:

1. Hinzufügen der neuen Namen zur Schema-Definition (im properties-Objekt)
2. Aktualisierung des required-Arrays, um die neuen Namen als gültige Alternativen zu markieren

Die Analyse in Issue #15809 und #37645 suggeriert, dass Schritt (2) fehlerhaft implementiert wurde: Die Funktion entfernt Original-Parameter-Namen aus required, fügt jedoch die Alias-Namen nicht als Ersatz hinzu. Das Resultat ist ein required-Array, das entweder leer ist oder nur teilweise gefüllt – mit dramatischen Konsequenzen für die Modell-Interpretation.

#### 2.2.4 Kritischer Bug: Entfernung originaler Parameter aus required-Array ohne Ersatz durch Aliase

Die detaillierteste technische Analyse des Bugs stammt aus Issue #37645, das den exakten Implementierungsfehler identifiziert. Die fehlerhafte Code-Stelle lautet:

```javascript
const idx = required.indexOf(original);
if (idx !== -1) {
  required.splice(idx, 1);  // Entfernt "path", fügt NICHTS hinzu
  changed = true;
}
```

Diese Implementierung verwendet `splice(idx, 1)` – die zwei-Argumente-Version, die ein Element am Index entfernt ohne Ersatz. Die korrekte Implementierung müsste lauten:

```javascript
required.splice(idx, 1, alias);  // Ersetzt durch Alias
```

Die drei-Argumente-Version entfernt ebenfalls ein Element, fügt aber sofort das alias-Element an derselben Position ein, wodurch die Array-Länge konstant bleibt.

Die Konsequenzen dieses Fehlers sind quantifizierbar:

| Tool | Ursprüngliche required-Länge | Nach fehlerhaftem Patch | Reduktion |
|------|------------------------------|------------------------|-----------|
| read | 1 (path) | 0 | 100% |
| edit | 3 (path, oldText, newText) | 0 oder 1 | 67-100% |
| write | 2 (path, content) | 0 oder 1 | 50-100% |

Ein leeres required-Array (`[]`) ist in JSON-Schema-technisch valide und signalisiert: "Keine Parameter sind verpflichtend". Modelle, die strikt dieser Spezifikation folgen – wie Kimi K2.5 – interpretieren dies korrekt und senden minimale oder leere Argument-Objekte.

### 2.3 Perspektive: Integrationsspezialist (API-Kompatibilität)

#### 2.3.1 Moonshot-API-Spezifikation vs. OpenClaw-Tool-Schema

Aus Integrationsperspektive stellt sich das Problem als Konflikt zwischen der Moonshot-API-Spezifikation und dem von OpenClaw generierten Tool-Schema dar. Moonshot's OpenAI-kompatible API implementiert den OpenAI-Chat-Completions-Standard, der Tool-Calls über ein spezifisches JSON-Schema-Format definiert. Ein zentrales Element ist das required-Array, das explizit auflistet, welche Properties eines Objekts zwingend vorhanden sein müssen.

Die OpenClaw-Generierung von Tool-Schemata involviert mehrere Transformationsschichten:

```
Internes Schema → patchToolSchemaForClaudeCompatibility() → Moonshot-API → Kimi K2.5
                      ↑
                 FEHLER: required-Array wird geleert
```

Wenn das durch `patchToolSchemaForClaudeCompatibility()` transformierte Schema an Moonshot gesendet wird, interpretiert Kimi K2.5 dieses Schema gemäß der OpenAI-Spezifikation. Das fehlerhafte required-Array führt dazu, dass Kimi K2.5 annimmt, die Text-Parameter seien optional, und lässt sie daher weg. Die resultierende Diskrepanz zwischen dem, was das Modell sendet, und dem, was OpenClaw erwartet, manifestiert sich als Validierungsfehler.

#### 2.3.2 OpenAI-kompatible API-Schicht: Parameter-Mapping-Probleme

Die Parameter-Mapping-Schicht in OpenClaw ist für die Übersetzung zwischen externen API-Konventionen und internen Tool-Parametern zuständig. Die zentrale Funktion `normalizeToolParams()` in `pi-tools.params.ts` transformiert eingehende Parameter-Namen in interne Namen. Die aktuelle Implementierung deckt ab:

| Eingehender Name | Interner Name | Status |
|------------------|---------------|--------|
| old_string | oldText | Implementiert |
| new_string | newText | Implementiert |
| old_text | oldText | Fehlt |
| new_text | newText | Fehlt |

Diese Lücke ist für Qwen-Modelle kritisch, die explizit `old_text`/`new_text` senden. Für Kimi K2.5 ist das primäre Problem das leere required-Array, aber die fehlende Alias-Registrierung würde bei korrektem Schema zu sekundären Fehlern führen.

Ein zusätzliches Problem, dokumentiert in Issue #41852, betrifft den kimi-coding-Provider, der `anthropicToolSchemaMode: "openai-functions"` erzwingt – was Kimi K2.5's native Tool-Use-Fähigkeiten unterdrückt. Die Workaround-Lösung – Umbenennung des Providers – deutet auf übermäßige Spezialisierung im OpenClaw-Provider-Handling hin.

#### 2.3.3 Fehlende Testabdeckung: Keine Validierung mit Kimi K2.5 vor Release 2026.2.12

Die systematische Natur des Fehlers und seine Persistenz über mehrere Versionen deuten auf einen strukturellen Mangel im Qualitätssicherungsprozess von OpenClaw hin. Die Einführung von `patchToolSchemaForClaudeCompatibility()` wurde offensichtlich ohne ausreichende Tests mit nicht-Claude-Modellen durchgeführt. Eine angemessene Testmatrix hätte mindestens umfassen müssen:

| Test-Typ | Beschreibung | Fehlende Abdeckung |
|----------|--------------|-------------------|
| Unit-Test | Isolierte Test der patchToolSchemaForClaudeCompatibility-Funktion | Keine Validierung des required-Array nach Patch |
| Integrationstest | End-to-End-Test mit verschiedenen LLM-Providern | Keine Testfälle für Kimi K2.5, GLM-5, Qwen |
| Schema-Validierung | Automatische Prüfung auf wohlgeformte JSON-Schemas | Keine Erkennung leerer required-Arrays |
| Regressionstest | Vergleich des Tool-Verhaltens vor/nach Änderung | Keine Baseline für nicht-Claude-Modelle |

Die Community-Response auf das Problem – mehrere detaillierte Bug-Reports mit Logs und Analysen – zeigt, dass die Fehlerbehebung primär auf Community-Beiträgen basiert, nicht auf proaktiver Fehlererkennung durch das Entwicklerteam. Die Empfehlung in Issue #15809 – "Testing tool schema changes against OpenAI-compatible models before release" – ist eine konkrete Verbesserungsmaßnahme, die jedoch bisher nicht implementiert zu sein scheint.

---

## 3. Detaillierte technische Ursachen

### 3.1 Die patchToolSchemaForClaudeCompatibility()-Funktion

#### 3.1.1 Zweck: Claude-spezifische Parameter-Aliase für bessere Kompatibilität

Die Funktion `patchToolSchemaForClaudeCompatibility()` wurde als Reaktion auf beobachtete Inkompatibilitäten zwischen Claude-Modellen und OpenClaws ursprünglichen Tool-Schemas implementiert. Claude-Modelle zeigten in frühen OpenClaw-Versionen Tendenzen, Parameter-Namen im camelCase-Format zu generieren, während die ursprünglichen Tool-Schemas snake_case-Konventionen verwendeten. Diese Diskrepanz führte zu Validierungsfehlern, bei denen Claude korrekte semantische Tool-Aufrufe generierte, die jedoch aufgrund nicht exakt übereinstimmender Parameter-Namen abgelehnt wurden.

Der Design-Ansatz – dynamisches Schema-Patching zur Laufzeit – ermöglicht schnelle Anpassungen ohne Datenbank-Migrationen oder Konfigurationsänderungen. Diese Flexibilität erkauft man sich jedoch mit erhöhter Komplexität und schwerer vorhersagbarem Verhalten. Die Funktion operiert auf dem Tool-Schema-Objekt, das aus `@mariozechner/pi-coding-agent` stammt, und modifiziert es vor der Übergabe an den jeweiligen LLM-Provider. Die Alias-Definition ist in einer Konstanten `CLAUDE_PARAM_GROUPS` kodiert, die Mappings wie `"oldText"`, `"newText"`, `"file_path"` enthält.

Die architektonische Entscheidung, diese Funktion universell anzuwenden – unabhängig vom tatsächlich verwendeten Modell – ist der Wurzel des Übels. Eine robustere Architektur hätte provider-spezifische Schema-Transformationen ermöglicht, die nur dann angewendet werden, wenn das Zielmodell diese Transformation tatsächlich benötigt.

#### 3.1.2 Implementierungsfehler: `required.splice(idx, 1)` statt `required.splice(idx, 1, alias)`

Der konkrete Implementierungsfehler liegt in einer einzigen Code-Zeile, die die Manipulation des required-Arrays durchführt. Die JavaScript-splice-Methode hat die Signatur `splice(start, deleteCount, ...items)`. Der fehlerhafte Aufruf `splice(idx, 1)` nutzt nur die ersten beiden Parameter, was zur reinen Löschung führt. Der korrekte Aufruf nutzt den dritten Parameter, um das gelöschte Element durch seinen Alias zu ersetzen: `splice(idx, 1, alias)`.

Die semantische Differenz zwischen diesen Operationen lässt sich am Beispiel verdeutlichen:

```javascript
// Ausgangszustand:
required = ["path", "oldText", "newText"];

// Fehlerhafte Operation für "path" → "file_path":
required.splice(0, 1);
// Ergebnis: ["oldText", "newText"]  "path" entfernt, "file_path" nicht hinzugefügt

// Korrekte Operation:
required.splice(0, 1, "file_path");
// Ergebnis: ["file_path", "oldText", "newText"]  Ersetzt, nicht entfernt
```

Wenn diese fehlerhafte Operation für alle drei Parameter des edit-Tools wiederholt wird, resultiert ein leeres Array: `[]`.

#### 3.1.3 Konsequenz: Leeres oder unvollständiges required-Array im Tool-Schema

Die Konsequenz des Implementierungsfehlers ist ein korruptes Tool-Schema, das von strikten JSON-Schema-Validatoren fehlinterpretiert wird. Die genaue Manifestation hängt von der Reihenfolge der Parameter-Verarbeitung ab:

| Szenario | required nach fehlerhaftem Patch | Validierungsverhalten |
|----------|----------------------------------|----------------------|
| Alle Parameter gepatcht | `[]` (leer) | Keine Pflichtfeld-Validierung |
| Teilweise gepatcht | Unvollständige Liste | Partielle Validierung, inkonsistent |
| Keine Patches angewendet | Original-Liste | Korrekte Validierung (selten) |

Für das edit-Tool resultiert typischerweise das erste Szenario: Ein leeres required-Array. Die JSON-Schema-Spezifikation definiert, dass ein fehlendes oder leeres required-Array bedeutet: "Alle Properties sind optional". Kimi K2.5, das strikt dieser Spezifikation folgt, interpretiert dies korrekt und sendet nur die Parameter, die es für unbedingt notwendig hält – in der dokumentierten Beobachtung nur `file_path` und `path`.

Die Interaktion zwischen diesem fehlerhaften Schema und verschiedenen Modell-Verhalten erklärt die beobachtete Diskrepanz:

| Modell-Typ | Interpretation von required: [] | Resultierendes Verhalten |
|------------|--------------------------------|-------------------------|
| Claude | Ignoriert, sendet Parameter basierend auf Semantik | Funktioniert trotz fehlerhaftem Schema |
| Kimi K2.5 | Strikte Folge: alle Parameter optional | Sendet minimale Parameter, Fehler |
| GPT-4 | Strikte Folge, aber andere Heuristiken | Potenziell betroffen |

### 3.2 Parameter-Namenskonflikte

#### 3.2.1 Akzeptierte Namen in OpenClaw: newText, new_string

Die aktuelle Implementierung von OpenClaw definiert explizit zwei akzeptierte Namensvarianten für die Parameter des edit-Tools. Diese Dualität spiegelt die historische Entwicklung wider: `old_string`/`new_string` waren die ursprünglichen Namen in frühen OpenAI-Implementierungen, während `oldText`/`newText` die von Claude bevorzugten Varianten sind. Die Definition erfolgt in der Regel in einer zentralen Konfigurationsdatei oder Konstante, typischerweise `CLAUDE_PARAM_GROUPS` in `src/agents/pi-tools.params.ts`.

Die Alias-Struktur ist nicht symmetrisch zwischen allen Tools. Während edit beide Konventionen unterstützen soll, haben andere Tools möglicherweise unterschiedliche Alias-Sets. Diese Inkonsistenz erschwert die Modell-Training und Prompt-Engineering, da keine universelle Namenskonvention etabliert ist. Die Fehlermeldung selbst – "`newText (newText or new_string)`" – dokumentiert diese Akzeptanz explizit, vermittelt aber gleichzeitig die falsche Sicherheit, dass diese beiden Varianten ausreichend seien.

#### 3.2.2 Von Kimi K2.5 gesendete Namen: potenziell new_text (snake_case)

Die Hypothese, dass Kimi K2.5 alternative Namenskonventionen wie `new_text` (snake_case mit Unterstrich, aber ohne "string"-Suffix) oder `newtext` (lowercase) generiert, ist durch die verfügbaren Logs nicht direkt verifizierbar. Die beobachtete Tatsache – vollständiges Fehlen von Text-Parametern – deutet jedoch auf ein grundlegendes Problem hin, das über bloße Namenskonvention hinausgeht.

Die vorgeschlagene Erweiterung in Issue #42488 – "also check replacement, text, content for edit" – basiert auf der Beobachtung, dass verschiedene LLM-Modelle semantisch äquivalente, aber syntaktisch unterschiedliche Parameter-Namen generieren. Eine robuste Alias-Implementierung würde diese Varianten explizit unterstützen. Für Kimi K2.5 spezifisch ist die Konsistenz in der Namenskonvention bemerkenswert: Das Modell generiert `file_path` (snake_case), was die Hypothese stützt, dass es generell snake_case bevorzugt. Die Erweiterung um `new_text`/`old_text` ist daher vorsorglich sinnvoll, auch wenn sie das aktuelle Problem nicht direkt löst.

#### 3.2.3 Fehlende Alias-Registrierung: new_text und old_text nicht in CLAUDE_PARAM_GROUPS

Die Konstante `CLAUDE_PARAM_GROUPS` ist der zentrale Ort für die Definition von Parameter-Aliasen in OpenClaw. Die aktuelle Implementierung umfasst offensichtlich nicht alle von Kimi K2.5 potenziell genutzten Varianten. Die erforderliche Erweiterung, wie in Issue #42488 vorgeschlagen, würde die Definition von:

```javascript
// Aktuell (fehlerhaft/unvollständig):
{ keys: ["newText", "new_string"], label: "newText (newText or new_string)" }

// Korrigiert/erweitert:
{ keys: ["newText", "new_string", "new_text"], label: "newText (newText or new_string or new_text)" }
```

Diese Erweiterung allein löst jedoch nicht das fundamentale Problem der fehlerhaften required-Array-Manipulation, sondern fügt lediglich weitere Alias-Optionen hinzu. Ein vollständiger Fix muss beide Aspekte adressieren: die korrekte Schema-Transformation und die erweiterte Alias-Registrierung.

### 3.3 Versions-spezifische Regression

#### 3.3.1 Funktionierende Version: OpenClaw 2026.2.9

Version 2026.2.9 ist als letzte stabile Version für Kimi K2.5 dokumentiert. In dieser Version war die `patchToolSchemaForClaudeCompatibility()`-Funktion entweder nicht vorhanden oder nicht aktiv für Kimi-Modelle. Das Tool-Schema wurde unverändert an alle Modelle übermittelt, mit camelCase-Parameter-Namen (oldText, newText). Kimi K2.5 war in dieser Konfiguration offensichtlich in der Lage, diese Namen korrekt zu interpretieren und zu generieren.

Die Identifikation von 2026.2.9 als letzte funktionierende Version basiert auf Community-Berichten und der zeitlichen Korrelation mit der Einführung der Schema-Patching-Funktion. Für Nutzer, die sofortige Stabilität benötigen, ist der Downgrade auf diese Version die zuverlässigste Option. Die Einschränkungen liegen im Verzicht auf Sicherheitsupdates und neue Features, die in späteren Versionen eingeführt wurden.

#### 3.3.2 Fehlerhafte Version: OpenClaw 2026.2.12 und später

Version 2026.2.12 markiert die Einführung oder Aktivierung der `patchToolSchemaForClaudeCompatibility()`-Funktion. Ab dieser Version tritt der dokumentierte Fehler systematisch auf. Die Versionshinweise von 2026.2.12 erwähnen typischerweise "improved Claude compatibility" oder ähnliche Formulierungen, ohne die potenziellen Seiteneffekte für andere Modelle zu benennen.

Die Eskalation des Fehlerbilds über Versionen ist bemerkenswert:

| Version | Fehler-Charakteristik | Schweregrad |
|---------|----------------------|-------------|
| 2026.2.12 | Edit-Tool missing parameters | Hoch |
| 2026.3.08 | Systematischer Edit-Fehler, Write-Fallback | Kritisch |
| 2026.3.11 | Vollständiger Tool-Ausfall, "hallucinated raw function strings" | Kritisch |
| 2026.3.23 | Parameter-Silencing: `{}` statt Parameter | Kritisch |

Die zunehmende Schwere deutet auf kumulative Schema-Komplexität hin, die Kimi K2.5 progressiv überfordert. Die Persistenz des Fehlers über mehr als sechs Wochen und mehrere Release-Zyklen deutet auf eine unterschätzte Priorität oder komplexe Fix-Anforderungen hin.

#### 3.3.3 Auslösender Commit: Änderungen an Tool-Schema-Patching für Claude-Modelle

Der spezifische Commit, der die Regression einführte, ist in den verfügbaren Quellen nicht öffentlich identifiziert, aber die Analyse der Git-History von `pi-tools.read.ts` und `pi-tools.params.ts` würde ihn lokalisieren. Typische Commit-Muster für solche Änderungen umfassen:

- "refactor: centralize schema patching"
- "feat: add Claude-specific parameter aliases"
- "fix: improve tool schema compatibility"

Für Entwickler, die einen Source-Code-Fix anstreben, wäre die Identifikation des auslösenden Commits durch `git bisect` zwischen 2026.2.9 und 2026.2.12 der effizienteste Ansatz. Der Fix selbst – Korrektur der splice-Operation – ist vermutlich ein Einzeiler, dessen Impact jedoch fundamental ist.

---

## 4. Fehleranalyse des bisherigen Lösungsansatzes

### 4.1 Identifizierte Fehlannahmen

#### 4.1.1 Fokus auf Modell-Rekonfiguration statt Schema-Fix

Die im vom Anwender referenzierten Chatverlauf dokumentierten Lösungsversuche zeigen eine Präferenz für Modell-seitige Anpassungen. Ansätze wie Änderung der System-Prompts, Variation der Temperatur-Parameter, oder Experimente mit verschiedenen Provider-Konfigurationen adressieren jedoch nicht die root cause – den fehlerhaften Schema-Patch in OpenClaw selbst.

Die Modell-Rekonfiguration ist attraktiv, weil sie keine Code-Änderung erfordert und schnell iterierbar ist. Die empirische Evidenz zeigt jedoch ihre Ineffektivität: Solange das Tool-Schema, das Kimi K2.5 präsentiert wird, ein leeres oder unvollständiges required-Array enthält, wird das Modell weiterhin unvollständige Parameter senden, unabhängig von Prompt-Formulierungen. Die Investition in Prompt-Optimierung wäre besser in die Behebung der Schema-Generierung geflossen.

#### 4.1.2 Fehlende Berücksichtigung der OpenClaw-Versionsgeschichte

Ohne Kenntnis der Versionsgeschichte – insbesondere der Tatsache, dass 2026.2.9 funktionierte und 2026.2.12 die Regression einführte – konzentrieren sich Nutzer auf die Debug ihrer aktuellen Installation, anstatt einen Downgrade in Betracht zu ziehen. Diese Blindheit für temporale Kontexte ist ein häufiges Muster in der Software-Fehlerdiagnose.

Die Versionsgeschichte ist nicht nur diagnostisch relevant, sondern auch für die Lösungsstrategie: Ein Downgrade auf eine bekannte funktionierende Version ist oft schneller und zuverlässiger als die Suche nach einer Konfigurationslösung für eine fehlerhafte neue Version. Die Etablierung einer Versions-Tracking-Dokumentation für kritische Infrastrukturkomponenten wie OpenClaw ist eine empfohlene präventive Maßnahme.

#### 4.1.3 Unzureichende Analyse der patchToolSchemaForClaudeCompatibility()-Funktion

Die Funktion `patchToolSchemaForClaudeCompatibility()` als primäre Fehlerquelle zu identifizieren, erfordert eine tiefe Kenntnis der OpenClaw-Interna, die im initialen Ansatz offenbar nicht vorhanden war. Diese Wissenslücke ist verständlich, da die Funktion nicht Teil der öffentlichen API-Dokumentation ist und ihre Existenz erst durch Code-Analyse oder GitHub-Issue-Recherche offenbar wird.

Die Konsequenz ist eine Suche nach Lösungen auf der falschen Abstraktionsebene: Statt die Schema-Transformation zu korrigieren, werden Versuche unternommen, die Symptome durch Workarounds zu mildern. Die Erkenntnis, dass ein spezifischer, identifizierbarer Code-Bereich verantwortlich ist, ermöglicht gezielte und effiziente Behebungsstrategien.

### 4.2 Nicht erfolgreiche Ansätze

#### 4.2.1 Manuelle Parameter-Korrektur im Prompt (nicht nachhaltig)

Der Versuch, durch manuelle Parameter-Korrektur im System-Prompt das Modellverhalten zu steuern, ist grundsätzlich nachvollziehbar, aber technisch nicht nachhaltig. Prompt-basierte Korrekturen sind inhärent fragil: Sie hängen von der Interpretation des Modells ab, können durch Modell-Updates invalidiert werden, und erfordern kontinuierliche Pflege.

Die Limitation dieses Ansatzes wird in Issue #42488 explizit genannt: "Instructing agents to use old_string/new_string: Requires per-workspace AGENTS.md updates and models may still output old_text/new_text. Does not fix root cause". Für Kimi K2.5 spezifisch ist der Ansatz zusätzlich ineffektiv, da das Modell in vielen Fällen überhaupt keine Text-Parameter sendet – ein Verhalten, das durch Prompt-Anweisungen nicht korrigiert werden kann, wenn das Schema selbst unklar ist.

#### 4.2.2 Modell-Wechsel ohne Schema-Anpassung (symptomatisch, nicht kausal)

Der Wechsel zu einem anderen Modell (z.B. Claude oder GPT-4) mag die Symptome beseitigen, ist aber keine kausale Lösung des Problems. Dieser Ansatz bestätigt lediglich, dass das Problem modell-spezifisch ist, ohne die Ursache zu adressieren. Für Nutzer, die aus Kosten-, Latenz- oder Verfügbarkeitsgründen auf Kimi K2.5 angewiesen sind, ist dieser Workaround nicht praktikabel.

Darüber hinaus verschleiert der Modell-Wechsel die systematische Natur des Fehlers: Wenn `patchToolSchemaForClaudeCompatibility` tatsächlich fehlerhaft ist, könnte sie auch Claude-Modelle in bestimmten Edge-Cases beeinträchtigen, selbst wenn diese grundsätzlich funktionieren. Eine kausale Behebung des Schema-Problems würde die Robustheit für alle Modelle verbessern.

#### 4.2.3 Konfigurationsänderungen in openclaw.json ohne Versions-Rollback

Die Modifikation von `openclaw.json` ohne Versions-Rollback ist ein häufiger Versuch, der aufgrund der Natur des Fehlers zum Scheitern verurteilt ist. Die Konfigurationsdatei steuert hochrangige Verhaltensaspekte (Modell-Auswahl, Tool-Allowlists, Provider-Einstellungen), aber nicht die low-level Schema-Transformationslogik, die in `patchToolSchemaForClaudeCompatibility` implementiert ist.

Selbst fortgeschrittene Konfigurationsoptionen wie Feature-Flags oder Schema-Overrides wären in diesem Fall unwirksam, da der Fehler in der fundamentalen Transformationslogik liegt, nicht in einer optionalen Komponente. Ein Versions-Rollback oder Code-Fix ist die einzige effektive Maßnahme.

---

## 5. Lösungsstrategien: Vier Handlungsoptionen

### 5.1 Option A: Sofortmaßnahme (Minimal-Invasiv)

#### 5.1.1 Downgrade auf OpenClaw 2026.2.9

Der Downgrade auf Version 2026.2.9 ist die schnellste und zuverlässigste Sofortmaßnahme. Diese Version ist explizit als funktionierend mit Kimi K2.5 dokumentiert und eliminiert alle in späteren Versionen eingeführten Schema-Transformationsfehler. Die Implementierung erfordert:

```bash
npm uninstall -g @openclaw/harness
npm install -g @openclaw/harness@2026.2.9
```

Die Versionsspezifikation `@2026.2.9` stellt sicher, dass nicht versehentlich eine neuere, fehlerhafte Version installiert wird. Nach der Installation sollte die Version explizit verifiziert werden: `openclaw --version`.

#### 5.1.2 Validierung: Bestätigung der Funktionalität mit Kimi K2.5

Die Validierung des Downgrades erfordert einen systematischen Test des edit-Tools in einer repräsentativen Arbeitsumgebung:

| Test-Typ | Beschreibung | Erfolgskriterium |
|----------|--------------|------------------|
| Einfacher Edit-Test | Erstellen einer Testdatei, Ausführung eines edit-Befehls mit explizitem oldText/newText | Datei wird korrekt modifiziert, keine Fehlermeldung |
| Komplexer Edit-Test | Mehrzeilige Ersetzung, Spezialzeichen, Unicode-Inhalt | Korrekte Handhabung von Edge-Cases |
| Automatisierter Workflow-Test | Wiederholung eines typischen Arbeitsablaufs, der zuvor fehlschlug | Keine write-Fallbacks, konsistente edit-Nutzung |

Die erfolgreiche Ausführung aller Tests bestätigt die Effektivität des Downgrades. Persistierende Fehler würden auf zusätzliche Probleme (Konfiguration, API-Key, Netzwerk) hindeuten.

#### 5.1.3 Risiko: Fehlende Sicherheitsupdates und neue Features

Der Downgrade ist nicht ohne Kompromisse. Die wesentlichen Risiken umfassen:

| Risiko-Kategorie | Beschreibung | Mitigation |
|------------------|--------------|------------|
| Sicherheitslücken | Version 2026.2.9 enthält möglicherweise nicht alle Sicherheitspatches von 2026.2.12+ | Überwachung von CVEs, geplanter schneller Upgrade nach Fix-Verfügbarkeit |
| Feature-Verlust | Neue Funktionen seit 2026.2.9 sind nicht verfügbar | Bewertung der Feature-Relevanz für den konkreten Use-Case |
| Kompatibilität | Zukünftige Tool- oder Provider-Integrationen könnten 2026.2.9 nicht unterstützen | Testing in isolierter Umgebung vor Produktivsetzung |

Die Abwägung zwischen sofortiger Funktionalität und langfristiger Aktualität muss individuell getroffen werden. Für kritische Produktivumgebungen ist der Downgrade jedoch typischerweise vorzuziehen gegenüber einem instabilen aktuellen System.

### 5.2 Option B: Code-Fix (Empfohlen für Entwickler)

#### 5.2.1 Lokalisierung: src/agents/pi-tools.read.ts

Der Code-Fix erfordert die Modifikation von zwei Dateien in der OpenClaw-Codebasis:

| Datei | Zweck | Spezifische Änderung |
|-------|-------|---------------------|
| `src/agents/pi-tools.read.ts` | Enthält `patchToolSchemaForClaudeCompatibility()` | Korrektur der splice-Operation |
| `src/agents/pi-tools.params.ts` | Enthält `CLAUDE_PARAM_GROUPS` | Erweiterung um new_text/old_text |

Die erste Datei ist der primäre Fix-Standort, die zweite Datei adressiert die sekundäre Alias-Lücke.

#### 5.2.2 Einzeiliger Fix: `required.splice(idx, 1, alias)` statt `required.splice(idx, 1)`

Der kritische Code-Change ist minimal in seiner Syntax, maximal in seiner Wirkung:

```javascript
// VORHER (fehlerhaft):
required.splice(idx, 1);

// NACHHER (korrigiert):
required.splice(idx, 1, alias);
```

Diese Änderung stellt sicher, dass das required-Array nach der Transformation vollständig bleibt, mit den Alias-Namen anstelle der ursprünglichen Namen. Die Lokalisation der zu ändernden Zeile erfordert die Suche nach der Funktionsdefinition `patchToolSchemaForClaudeCompatibility` und der darin enthaltenen splice-Operation.

#### 5.2.3 Erweiterung: Hinzufügen von new_text/old_text zu CLAUDE_PARAM_GROUPS

Die sekundäre Erweiterung adressiert die Alias-Lücke für Qwen-ähnliche Modelle und ist vorsorglich für Kimi K2.5 sinnvoll:

```javascript
// In src/agents/pi-tools.params.ts:
// VORHER:
{ keys: ["newText", "new_string"], label: "newText (newText or new_string)" }

// NACHHER:
{ keys: ["newText", "new_string", "new_text"], label: "newText (newText or new_string or new_text)" }
```

Analog für oldText. Diese Erweiterung erfordert zudem die Aktualisierung von `normalizeToolParams`, um die neuen Aliase in interne Namen zu übersetzen.

#### 5.2.4 Neukompilierung und lokale Installation

Nach den Code-Änderungen erfolgt die Neukompilierung und Installation:

```bash
# Im OpenClaw-Repository-Verzeichnis:
npm install  # Abhängigkeiten sicherstellen
npm run build  # Kompilierung TypeScript → JavaScript
npm link  # Oder: npm install -g .
```

Die Verifikation erfolgt durch erneute Ausführung der Testmatrix aus Option A.

### 5.3 Option C: Konfigurationsbasierte Umgehung

#### 5.3.1 Deaktivierung von patchToolSchemaForClaudeCompatibility via Feature-Flag

Eine konfigurationsbasierte Deaktivierung der fehlerhaften Funktion wäre die eleganteste Lösung, falls OpenClaw ein entsprechendes Feature-Flag unterstützte. Die Untersuchung der aktuellen Codebasis zeigt jedoch, dass keine solche Konfigurationsoption dokumentiert oder implementiert ist. Die Funktion wird unbedingt und universell aufgerufen, ohne Modell-spezifische Bedingung.

#### 5.3.2 Manuelle Schema-Überschreibung in openclaw.json

Die `openclaw.json` erlaubt Tool-spezifische Konfigurationen, aber keine direkte Schema-Manipulation. Ein Versuch, das edit-Tool-Schema manuell zu überschreiben, würde an der frühen Anwendung von `patchToolSchemaForClaudeCompatibility` scheitern, die das Schema vor der Konfigurationsanwendung modifiziert.

#### 5.3.3 Einschränkung: Nicht alle OpenClaw-Versionen unterstützen dies

Option C ist praktisch nicht umsetzbar in den betroffenen Versionen. Die Architektur von OpenClaw 2026.2.12+ bietet keinen Hookpunkt für die Deaktivation oder Überschreibung der Schema-Patching-Logik. Diese Einschränkung unterstreicht die Notwendigkeit eines Code-Fixes (Option B) oder eines Downgrades (Option A).

### 5.4 Option D: Modell-Seitige Anpassung

#### 5.4.1 System-Prompt-Engineering: Explizite Parameter-Namensvorgaben

Der Versuch, durch System-Prompt-Engineering korrekte Parameter-Namen zu erzwingen, ist theoretisch möglich, praktisch fragil:

```
SYSTEM PROMPT (konzeptionell):
"When using the edit tool, ALWAYS include all three parameters: 
'path' (or 'file_path'), 'oldText' (or 'old_string'), and 'newText' (or 'new_string'). 
Never omit any parameter."
```

Die Limitationen sind erheblich: Das Modell muss die Instruktion korrekt interpretieren, sie muss im Kontextfenster gehalten werden, und sie konkurriert mit dem Tool-Schema, das möglicherweise widersprüchliche Signale sendet.

#### 5.4.2 Few-Shot-Beispiele für korrekte Edit-Tool-Nutzung

Few-Shot-Beispiele in der System-Prompt oder Conversation-History könnten die Wahrscheinlichkeit korrekter Aufrufe erhöhen:

```
EXAMPLE 1:
User: "Change 'hello' to 'world' in file.txt"
Assistant tool call: edit({"path": "file.txt", "oldText": "hello", "newText": "world"})
```

Die Effektivität ist jedoch nicht garantiert, da das Modell das Tool-Schema weiterhin als primäre Informationsquelle betrachtet.

#### 5.4.3 Einschränkung: Modell-verhalten nicht deterministisch garantierbar

Die fundamentale Einschränkung aller modell-seitigen Ansätze ist die Nicht-Deterministik des LLM-Verhaltens. Selbst mit optimalen Prompts und Beispielen kann das Modell aufgrund von Temperatur, Kontextfenster-Limitierungen oder internen Zuständen von der erwarteten Ausgabe abweichen. Für kritische Produktivumgebungen ist diese Unsicherheit inakzeptabel.

---

## 6. Implementierungsleitfaden: Schritt-für-Schritt-Anleitung

### 6.1 Vorbereitung

#### 6.1.1 Backup der aktuellen OpenClaw-Konfiguration

Vor jeder Änderung ist ein vollständiges Backup erforderlich:

```bash
# Backup des Konfigurationsverzeichnisses:
cp -r ~/.openclaw ~/.openclaw.backup.$(date +%Y%m%d)

# Dokumentation der aktuellen Einstellungen:
openclaw config list > openclaw-config-backup.txt
```

#### 6.1.2 Dokumentation der aktuellen Version

Die exakte Versionsdokumentation ist kritisch für die Fehleranalyse und Rückverfolgung:

```bash
openclaw --version > openclaw-version.txt
# Erwartete Ausgabe: z.B. "2026.3.08" oder "2026.2.12"
```

#### 6.1.3 Identifikation der Installationsmethode (npm, yarn, source)

Die Installationsmethode bestimmt die Update-Strategie:

| Methode | Identifikation | Update-Pfad |
|---------|---------------|-------------|
| npm global | `which openclaw` → `/usr/local/bin/openclaw` | `npm install -g` |
| yarn global | `yarn global list` | `yarn global add` |
| Source/Development | `git remote -v` im Repository | `git pull`, `npm run build` |

### 6.2 Option A: Downgrade-Implementierung

#### 6.2.1 Deinstallation

```bash
npm uninstall -g @openclaw/harness
# Verifikation:
which openclaw  # Sollte nichts zurückgeben
```

#### 6.2.2 Installation spezifischer Version

```bash
npm install -g @openclaw/harness@2026.2.9
# Verifikation der Installation:
openclaw --version  # Sollte "2026.2.9" anzeigen
```

#### 6.2.3 Verifikation: Test-Edit-Operation mit Kimi K2.5

Die funktionale Verifikation erfolgt durch einen repräsentativen Arbeitsablauf:

1. OpenClaw starten mit Kimi K2.5 als konfiguriertem Modell
2. Einfache Edit-Anfrage stellen: "Change 'TODO' to 'DONE' in README.md"
3. Beobachtung: Keine Fehlermeldung, korrekte Dateimodifikation, kein write-Fallback

### 6.3 Option B: Source-Code-Fix

#### 6.3.1 Repository-Klon

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

#### 6.3.2 Checkout der Zielversion

```bash
git fetch --tags
git checkout v2026.2.12  # Oder: git checkout 2026.3.08 für neueste Version
```

#### 6.3.3 Datei-Editierung: src/agents/pi-tools.read.ts

Lokalisierung der Funktion `patchToolSchemaForClaudeCompatibility`:

```bash
grep -n "patchToolSchemaForClaudeCompatibility" src/agents/pi-tools.read.ts
# Notiere Zeilennummer für Navigation
```

#### 6.3.4 Patch-Anwendung

Suche nach `patchToolSchemaForClaudeCompatibility` Innerhalb der Funktion, suche nach der splice-Operation:

```javascript
// Typisches Muster (variiert leicht nach Version):
const idx = required.indexOf(original);
if (idx !== -1) {
  required.splice(idx, 1);  // <-- ZU ÄNDERN
  changed = true;
}
```

#### 6.3.5 Zeilenänderung

```javascript
// KORRIGIERT:
const idx = required.indexOf(original);
if (idx !== -1) {
  required.splice(idx, 1, alias);  // Alias als drittes Argument
  changed = true;
}
```

#### 6.3.6 Erweiterung in pi-tools.params.ts

```bash
// Lokalisierung von CLAUDE_PARAM_GROUPS.edit:
grep -n "CLAUDE_PARAM_GROUPS" src/agents/pi-tools.params.ts

// Modifikation der relevanten Einträge:
// VON:
{ keys: ["newText", "new_string"], label: "newText (newText or new_string)" }

// ZU:
{ keys: ["newText", "new_string", "new_text"], label: "newText (newText or new_string or new_text)" }
```

Analog für `oldText`/`old_string`/`old_text`.

#### 6.3.7 Build

```bash
npm install  # Abhängigkeiten sicherstellen
npm run build  # TypeScript-Kompilierung
# Erfolgsindikator: Keine TypeScript-Fehler, dist/-Verzeichnis aktualisiert
```

#### 6.3.8 Lokale Installation

```bash
# Option 1: Globale Installation aus dem geklonten Repository:
npm install -g .

# Option 2: Entwicklungslink (für iterative Änderungen):
npm link
# In anderem Testprojekt:
npm link @openclaw/harness
```

### 6.4 Validierung und Testing

#### 6.4.1 Unit-Test

```bash
# Falls verfügbar:
npm test -- --grep "pi-tools.schema"
# Oder spezifischer:
npm test -- pi-tools.schema.test.ts
```

#### 6.4.2 Integrationstest: Edit-Operation in bestehendem Projekt

Die realitätsnahe Validierung erfolgt durch:

1. Navigieren zu einem bestehenden Projekt mit OpenClaw-Integration
2. Typische Edit-Operation anfordern, die zuvor fehlschlug
3. Beobachtung von: Erfolgreiche Ausführung, korrekte Parameter-Übermittlung, keine write-Fallbacks

#### 6.4.3 Logging-Aktivierung für detaillierte Tool-Aufrufe

```bash
OPENCLAW_DEBUG=1 openclaw
# Oder in der Konfiguration:
# debug: true
```

Die Debug-Ausgabe zeigt:
- Das tatsächlich an das Modell gesendete Tool-Schema
- Die vom Modell zurückgegebenen Tool-Aufrufe
- Die Parameter-Normalisierung und -Validierung

---

## 7. Präventive Maßnahmen und Monitoring

### 7.1 Für OpenClaw-Entwickler

#### 7.1.1 Erweiterte Testmatrix: Kimi K2.5, GLM-5, Qwen vor jedem Release

Die Pflichtenheft-Erweiterung für den Release-Prozess:

| Modell | Provider | Testumfang | Akzeptanzkriterium |
|--------|----------|-----------|-------------------|
| Kimi K2.5 | Moonshot | Alle Core-Tools (read, edit, write, apply_patch) | 100% erfolgreiche Tool-Aufrufe |
| GLM-5 | Zhipu | Edit-Tool mit verschiedenen Parameter-Kombinationen | Keine missing parameter-Fehler |
| Qwen 3.5 | Alibaba | Parameter-Alias-Validierung (old_text/new_text) | Korrekte Normalisierung |
| Claude 3.5 | Anthropic | Regressionstest bestehender Funktionalität | Keine Performance-Einbußen |

#### 7.1.2 Schema-Validierung: Automatische Prüfung auf leere required-Arrays

Implementierungsvorschlag für CI/CD-Pipeline:

```javascript
// Pseudocode für Schema-Validierung:
function validateToolSchema(schema) {
  for (const tool of schema.tools) {
    const required = tool.parameters.required;
    if (!required || required.length === 0) {
      throw new Error(`Tool ${tool.name}: empty required array detected`);
    }
    // Zusätzlich: Verifikation, dass alle required Parameter in properties existieren
  }
}
```

#### 7.1.3 Feature-Flags für experimentelle Schema-Patches

Architektur-Empfehlung: `patchToolSchemaForClaudeCompatibility` sollte bedingt ausführbar sein:

```javascript
// Konfigurationsbasierte Aktivierung:
if (config.features.claudeSchemaPatch !== false) {
  // Standard: aktiviert für Rückwärtskompatibilität
  patchToolSchemaForClaudeCompatibility(schema);
}

// Oder modell-spezifisch:
if (model.family === 'claude') {
  patchToolSchemaForClaudeCompatibility(schema);
}
```

### 7.2 Für Nutzer

#### 7.2.1 Versions-Pinning in package.json

Die präventive Stabilisierung durch explizite Versionsangabe:

```json
{
  "dependencies": {
    "@openclaw/harness": "2026.2.9"
  }
}
```

Oder für globale Installationen: Dokumentation der funktionierenden Version mit Upgrade-Verweigerung bis Fix-Verfügbarkeit.

#### 7.2.2 Automatisierte Regressionstests im CI/CD

Empfohlene Test-Suite für OpenClaw-abhängige Projekte:

```yaml
# .github/workflows/openclaw-regression.yml (Konzept)
name: OpenClaw Regression Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup OpenClaw
        run: npm install -g @openclaw/harness@${{ matrix.openclaw-version }}
      - name: Test Edit Tool
        run: ./scripts/test-edit-tool.sh  # Custom test script
    strategy:
      matrix:
        openclaw-version: ["2026.2.9", "latest"]
```

#### 7.2.3 Community-Feedback: GitHub-Issues bei Modell-spezifischen Problemen

Die aktive Partizipation in der OpenClaw-Community durch:
- Detaillierte Bug-Reports mit Versionsangabe, Logs, Reproduktionsschritten
- Cross-Referenzierung verwandter Issues (z.B. #15809, #42488, #44203)
- Validierung von Fix-Vorschlägen in der eigenen Umgebung

---

## 8. Zusammenfassung und Handlungsempfehlung

### 8.1 Primäre Empfehlung

#### 8.1.1 Kurzfristig: Downgrade auf OpenClaw 2026.2.9 (Option A)

Für alle Nutzer, die sofortige Produktivität benötigen, ist der Downgrade auf OpenClaw 2026.2.9 die empfohlene Maßnahme. Diese Version ist valide getestet, minimal invasiv und sofort umsetzbar. Die Einschränkungen (fehlende Sicherheitsupdates, neue Features) sind gegenüber einem nicht funktionierenden System vernachlässigbar.

#### 8.1.2 Mittelfristig: Code-Fix mit Parameter-Alias-Erweiterung (Option B)

Für Entwickler und technisch versierte Nutzer ist der Code-Fix die nachhaltige Lösung. Der einzeilige Change in `patchToolSchemaForClaudeCompatibility()` plus die Alias-Erweiterung in `CLAUDE_PARAM_GROUPS` adressieren beide identifizierte Ursachen (leeres required-Array, fehlende new_text/old_text-Alias). Die Neukompilierung ermöglicht die Nutzung aktueller OpenClaw-Versionen mit vollem Feature-Set.

#### 8.1.3 Langfristig: Überwachung des offiziellen OpenClaw-Fixes für Issue #42488

Die strategische Positionierung für die Zukunft umfasst:
- Abonnement der relevanten GitHub-Issues (#42488, #15809, #44203)
- Evaluierung offizieller Releases auf Fix-Integration
- Geplanter Upgrade-Pfad nach Verfügbarkeit eines validierten Fixes

### 8.2 Kritische Erfolgsfaktoren

#### 8.2.1 Verständnis: Kein Modell-Bug, sondern Schema-Regressionsfehler

Die mentale Modell-Korrektur ist fundamental: Das Problem ist nicht, dass Kimi K2.5 "falsch" arbeitet – es arbeitet korrekt gemäß der ihm präsentierten Spezifikation. Die Spezifikation selbst ist durch einen Software-Fehler in OpenClaw korrumpiert. Diese Perspektive verschiebt den Fokus von Modell-Tuning zu Code-Korrektur und ermöglicht effiziente Lösungsstrategien.

#### 8.2.2 Präzision: Zielgerichtete Änderung in patchToolSchemaForClaudeCompatibility

Die chirurgische Präzision des erforderlichen Fixes – eine Zeile in einer Funktion – unterstreicht die Wichtigkeit korrekter Diagnose. Falsche Diagnosen führen zu umfangreichen, ineffektiven Änderungen (Prompt-Engineering, Modell-Wechsel, Konfigurations-Experimente). Die korrekte Diagnose ermöglicht minimale, maximale Wirkung erzielende Intervention.

#### 8.2.3 Validierung: Bestätigung der Fix-Wirkung vor Produktivsetzung

Unabhängig von der gewählten Option ist systematische Validierung unerlässlich:

| Validierungsstufe | Methode | Akzeptanzkriterium |
|-------------------|---------|-------------------|
| Unit | Schema-Inspektion, Debug-Logging | required-Array enthält erwartete Aliase |
| Integration | Isolierter Tool-Test | Einzelner edit-Aufruf erfolgreich |
| System | Vollständiger Arbeitsablauf | Keine write-Fallbacks über 10+ Operationen |
| Regression | Wiederholung zuvor fehlgeschlagener Szenarien | Konsistente Erfolgsrate |

Die Disziplin der Validierung verhindert Scheinlösungen und Rückfälle, und schafft Vertrauen in die Systemstabilität.

---

*Generated by Kimi.ai*
