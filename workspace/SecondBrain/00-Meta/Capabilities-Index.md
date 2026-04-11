---
date: 10-04-2026
type: index
category: meta
tags: [index, capabilities, tools, skills, commands, overview]
---

# Meine Faehigkeiten - Uebersicht

> Was kann ich alles fuer dich tun?  
> Diese Seite listet alle meine Skills, Tools und Commands mit einfachen Erklaerungen.

---

## Setup (Wichtig!)

Damit die Links zu den Skills funktionieren, muss das Symlink-Setup ausgefuehrt werden:

```powershell
# PowerShell als Admin
.\00-Meta\Scripts\setup-symlinks.ps1
```

Dokumentation: [[00-Meta/vault-config|Vault Konfiguration & Symlinks]]

---

## Schnellstart: Die beliebtesten Skills

| Skill | Wann benutzen? | Beispiel |
|-------|----------------|----------|
| **[[#Grill Me]]** | Du hast einen Plan und willst ihn testen | "Grill me on this plan" |
| **[[#Plan Feature]]** | Du willst ein Feature umsetzen | "Plan this feature for me" |
| **[[#Security Review]]** | Code auf Sicherheit pruefen | "Security review this code" |
| **[[#TDD Loop]]** | Test-driven Development | "TDD this feature" |

---

## Security & Safety

### Security Review
**Was ist das?**  
Automatisierte Sicherheitsanalyse fuer Code (Python, PowerShell, JavaScript, etc.)

**Wann benutzen?**
- Code auf Schwachstellen pruefen
- Vor dem Deployment
- Bei fremdem Code
- Regelmaessige Audits

**Wie aktiviert man es?**
```
"Security review this code"
"Check for vulnerabilities"
"Is this code safe?"
"Analyze security of [Pfad]"
```

**Was macht es genau?**
- Sucht nach bekannten Schwachstellen (SQL Injection, XSS, etc.)
- Prueft auf harte Passwoerter/Secrets im Code
- Analysiert Dependencies
- Gibt Risiko-Bewertung

[[skills/security-review/SKILL|Vollstaendige Doku]]

---

### Secure API Client
**Was ist das?**  
Sicherer HTTP-Client fuer API-Calls mit Authentication, Rate-Limiting, Timeouts

**Wann benutzen?**
- Daten von APIs holen
- API mit Auth-Token aufrufen
- Sichere HTTP-Requests machen

**Wie aktiviert man es?**
```
"Make API call to [URL]"
"Fetch data from API"
"Secure HTTP request"
```

**Was macht es genau?**
- Validiert Inputs
- Handled Timeouts
- Managed API-Keys sicher
- Rate-Limiting (nicht zu viele Requests)

[[skills/secure-api-client/SKILL|Vollstaendige Doku]]

---

## Planung & Design

### Grill Me
**Was ist das?**  
Ich interviewe dich gnadenlos ueber deinen Plan, bis wir alle Schwachstellen gefunden haben.

**Wann benutzen?**
- Vor der Implementation
- Bei komplexen Features
- Wenn du unsicher bist
- Um Edge Cases zu finden

**Wie aktiviert man es?**
```
"Grill me on this plan"
"Grill me"
"Test my design"
```

**Was macht es genau?**
- Stellt gezielte Fragen zu deinem Plan
- Geht jeden Zweig des Entscheidungsbaums durch
- Findet Widersprueche und Luecken
- Dokumentiert getroffene Entscheidungen

**Beispiel:**
```
Du: "Grill me on this plan: Ich will einen Chatbot bauen"
Ich: "Okay. Wer sind die Nutzer?"
Du: "Kunden..."
Ich: "Wie authentifizieren sie sich?"
...
```

[[skills/grill-me/SKILL|Vollstaendige Doku]]

---

### Plan Feature
**Was ist das?**  
Zerlegt ein Feature in logische Phasen/Schritte (Vertical Slices).

**Wann benutzen?**
- Neues Feature starten
- Grosse Aufgabe aufteilen
- Implementation planen

**Wie aktiviert man es?**
```
"Plan this feature"
"Break down this feature"
"Create implementation plan"
```

**Was macht es genau?**
- Analysiert die Codebase (falls vorhanden)
- Identifiziert Architektur-Entscheidungen
- Erstellt "Vertical Slices" (duenn, aber komplett)
- Speichert Plan in `./plans/`

[[skills/plan-feature/SKILL|Vollstaendige Doku]]

---

### Write a PRD
**Was ist das?**  
Erstellt ein Product Requirements Document durch Interview.

**Wann benutzen?**
- Neues Produkt/Feature von Grund auf planen
- Vor dem Coding
- Fuer Dokumentation

**Wie aktiviert man es?**
```
"Write a PRD"
"Create product requirements"
```

[[skills/write-a-prd/SKILL|Vollstaendige Doku]]

---

## Entwicklung & Coding

### TDD Loop
**Was ist das?**  
Test-Driven Development: Red -> Green -> Refactor

**Wann benutzen?**
- Neues Feature entwickeln
- Bug fixen
- Sauberen Code schreiben

**Wie aktiviert man es?**
```
"TDD this feature"
"Write test first"
"Red-green-refactor"
```

**Was macht es genau?**
1. **Red:** Test schreiben (fails)
2. **Green:** Minimaler Code (test passes)
3. **Refactor:** Code verbessern
4. Wiederholen

[[skills/tdd-loop/SKILL|Vollstaendige Doku]]

---

### Python Patterns
**Was ist das?**  
Python Best Practices und Patterns.

**Wann benutzen?**
- Python Code schreiben
- Python Code reviewen
- Projektstruktur planen

**Wie aktiviert man es?**
```
"Python best practices"
"Review Python code"
```

[[skills/python-patterns/SKILL|Vollstaendige Doku]]

---

### API Design
**Was ist das?**  
REST API Design Patterns und Best Practices.

**Wann benutzen?**
- API designen
- API reviewen
- Endpoints planen

**Wie aktiviert man es?**
```
"Design API"
"Review API"
```

[[skills/api-design/SKILL|Vollstaendige Doku]]

---

### Refactoring
**Was ist das?**  
Code-Refactoring Patterns und Techniken.

**Wann benutzen?**
- Bestehenden Code verbessern
- Technical Debt reduzieren
- Code modernisieren

**Wie aktiviert man es?**
```
"Refactor this code"
"Improve this code"
```

[[skills/refactoring/SKILL|Vollstaendige Doku]]

---

### Testing Patterns
**Was ist das?**  
Testing Best Practices und Patterns.

**Wann benutzen?**
- Tests schreiben
- Test-Strategie planen
- Test-Infrastruktur aufsetzen

**Wie aktiviert man es?**
```
"Write tests"
"Testing strategy"
```

[[skills/testing-patterns/SKILL|Vollstaendige Doku]]

---

## Forschung & Analyse

### ECC Autoresearch
**Was ist das?**  
Sichere autonome Forschung mit ECC-Sicherheitsgarantien.

**Wann benutzen?**
- Automatisierte Recherche
- Tiefen-Analyse eines Themas
- Mit Safety-Constraints

**Wie aktiviert man es?**
```
"Autoresearch [Thema]"
"Research with ECC"
```

**Was macht es genau?**
- Autonome Recherche
- Human-in-Loop (du gibst Approval)
- Fort Knox Safety Guards
- Dokumentiert alles

[[skills/ecc-autoresearch/SKILL|Vollstaendige Doku]]

---

### Weather
**Was ist das?**  
Wetter-Informationen via wttr.in oder Open-Meteo.

**Wann benutzen?**
- Wetter checken
- Wettervorhersage

**Wie aktiviert man es?**
```
"Wetter in [Stadt]"
"Weather in [City]"
```

[[skills/example-weather/SKILL|Vollstaendige Doku]]

---

### Documentation
**Was ist das?**  
Documentation Best Practices.

**Wann benutzen?**
- README schreiben
- API-Doku erstellen
- Dokumentation reviewen

**Wie aktiviert man es?**
```
"Write documentation"
"Review docs"
```

[[skills/documentation/SKILL|Vollstaendige Doku]]

---

## Voice & Audio

### Whisper Local STT
**Was ist das?**  
Lokale Speech-to-Text mit OpenAI Whisper.

**Wann benutzen?**
- Sprache zu Text umwandeln
- Transkriptionen
- Lokal (ohne Cloud)

**Wie aktiviert man es?**
```
"Transcribe audio"
"Speech to text"
```

[[skills/whisper-local-stt/SKILL|Vollstaendige Doku]]

---

## Meta & Selbstverbesserung

### Self-Improving Andrew
**Was ist das?**  
Ich verbessere mich selbst durch Feedback und Analyse.

**Wann benutzen?**
- Wenn du willst, dass ich mich verbessere
- Retrospektiven

**Wie aktiviert man es?**
```
"Improve yourself"
"Self-improvement"
```

[[skills/self-improving-andrew/SKILL|Vollstaendige Doku]]

---

### Mission Control
**Was ist das?**  
Dashboard fuer System-Status und Ueberwachung.

**Wann benutzen?**
- System-Status checken
- Ueberwachung

[[skills/mission-control/SKILL|Vollstaendige Doku]]

---

### Mission Control v2
**Was ist das?**  
Next.js Dashboard (neuere Version).

[[skills/mission-control-v2/SKILL|Vollstaendige Doku]]

---

## Tools & Commands (Built-in)

Das sind keine Skills, sondern eingebaute Werkzeuge:

| Tool | Was macht es? | Beispiel |
|------|---------------|----------|
| **read** | Datei lesen | `read("file.md")` |
| **write** | Datei schreiben | `write("file.md", "content")` |
| **edit** | Datei editieren (suchen & ersetzen) | `edit("file.md", old, new)` |
| **exec** | Shell-Command ausfuehren | `exec("ls -la")` |
| **web_search** | Web-Suche | `web_search("Python tutorial")` |
| **web_fetch** | Webseite laden | `web_fetch("https://...")` |
| **browser** | Browser steuern | `browser({action: "snapshot"})` |
| **sessions_spawn** | Sub-Agent starten | `sessions_spawn({task: "..."})` |
| **sessions_list** | Sessions auflisten | `sessions_list()` |
| **cron** | Cron-Jobs verwalten | `cron({action: "list"})` |
| **message** | Nachrichten senden | `message({action: "send", ...})` |
| **gateway** | OpenClaw Config | `gateway({action: "config.get"})` |

---

## Wie aktiviert man Skills?

### Variante 1: Natuerliche Sprache
Einfach sagen was du willst:
```
"Mach einen Security Review von diesem Code"
"Grill me on this plan"
"Plan this feature for me"
```

### Variante 2: Expliziter Aufruf
Wenn du einen bestimmten Skill willst:
```
"Use security-review skill"
"Activate grill-me"
```

### Variante 3: Mit Kontext
```
"Security review: [Code hier einfuegen]"
"TDD this: User can add items to cart"
```

---

## Skill-Statistiken

```dataview
TABLE WITHOUT ID
  "19" as "Gesamt Skills",
  "6" as "Security/Dev",
  "5" as "Planung/Design",
  "4" as "Coding",
  "4" as "Sonstige"
```

---

## Aktualisierung dieser Liste

**Wann aktualisieren?**
- Neuer Skill installiert
- Skill entfernt
- Neue Version mit neuen Faehigkeiten

**Wer aktualisiert?**
- Ich (automatisch bei Aenderungen)
- Du (manuell wenn gewuenscht)

---

## Troubleshooting

### Links funktionieren nicht in Obsidian

**Ursache:** Symlink wurde noch nicht erstellt

**Loesung:**
```powershell
.\00-Meta\Scripts\setup-symlinks.ps1
# Dann Obsidian neu starten
```

### Weitere Hilfe

[[00-Meta/vault-config|Vault Konfiguration & Troubleshooting]]

---

Letzte Aktualisierung: 10-04-2026  
Version: 1.1  
Total Skills: 19
