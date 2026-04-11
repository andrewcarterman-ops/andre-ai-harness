# OpenClaw Skill: Obsidian Second Brain Implementation

```yaml
---
id: "obsidian-second-brain-impl"
name: "obsidian-second-brain-impl"
triggers: ["implement second brain", "setup obsidian", "organize vault"]
status: "active"
---
```

## 🎯 Ziel

Systematischer Aufbau eines professionellen Obsidian Second Brain mit PARA-Methode, intelligentem Tag-System und OpenClaw-Integration. **Jeder Schritt wird validiert bevor der nächste beginnt.**

---

## 📋 Voraussetzungen (Pre-Flight Check)

Vor Start prüfen:
- [ ] Obsidian ist installiert
- [ ] Vault-Pfad ist bekannt (z.B. `C:\Users\andre\Obsidian Vault`)
- [ ] OpenClaw Gateway läuft
- [ ] Schreibrechte im Vault-Verzeichnis

**Abbruch wenn:** Vault-Pfad nicht existiert oder keine Schreibrechte.

---

## Phase 1: Ordnerstruktur erstellen (PARA)

### Schritt 1.1: Hauptordner anlegen

**Aktion:** Erstelle die 5 PARA-Ordner + MOCs

```powershell
# Ordner erstellen
$vaultPath = "C:\Users\andre\Obsidian Vault"  # ANPASSEN!

New-Item -ItemType Directory -Force -Path "$vaultPath\00 Inbox"
New-Item -ItemType Directory -Force -Path "$vaultPath\01 Projects"
New-Item -ItemType Directory -Force -Path "$vaultPath\02 Areas"
New-Item -ItemType Directory -Force -Path "$vaultPath\03 Resources"
New-Item -ItemType Directory -Force -Path "$vaultPath\04 Archives"
New-Item -ItemType Directory -Force -Path "$vaultPath\MOCs"
```

**Check 1.1:** Ordner existieren?
```powershell
Get-ChildItem $vaultPath | Where-Object {$_.PSIsContainer} | Select-Object Name
```

**Erwartetes Ergebnis:** Liste zeigt alle 6 Ordner

**Bei Fehler:** STOPP - Prüfe Schreibrechte und Pfad

---

### Schritt 1.2: README in jedem Ordner

**Aktion:** Erstelle README.md in jedem Ordner zur Erklärung

**Inhalt für `00 Inbox/README.md`:**
```markdown
# 00 Inbox

**Zweck:** Eingangskorb für alle neuen Notizen

**Regeln:**
- Jede neue Notiz landet hier zuerst
- Täglich reviewen und verschieben
- Max. 20 Notizen - sonst überfordert!

**Workflow:**
1. Neue Idee/Notiz → Inbox
2. Innerhalb 24h taggen und verschieben
3. Nie länger als 1 Woche hier lassen

**Tags:** #status/inbox
```

**Inhalt für `01 Projects/README.md`:**
```markdown
# 01 Projects

**Zweck:** Aktive Projekte mit Deadline/Ziel

**Regeln:**
- Jedes Projekt = eigener Unterordner
- Projekt hat Start- und Enddatum
- Max. 3-5 aktive Projekte gleichzeitig

**Projekt-Template:**
```
Projekt-Name/
├── README.md          # Projektübersicht
├── TODO.md           # Offene Aufgaben
├── Notes/            # Projekt-Notizen
└── Archive/          # Abgeschlossenes
```

**Tags:** #type/project #status/active
```

**Inhalt für `02 Areas/README.md`:**
```markdown
# 02 Areas

**Zweck:** Verantwortungsbereiche ohne festes Ende

**Beispiele:**
- Gesundheit
- Finanzen
- Karriere/Weiterbildung
- Beziehungen

**Regeln:**
- Kontinuierlich gepflegt
- Keine Deadlines, aber regelmäßige Reviews
- Breites Wissen sammeln

**Tags:** #type/area
```

**Inhalt für `03 Resources/README.md`:**
```markdown
# 03 Resources

**Zweck:** Referenzmaterial und Wissen

**Unterordner:**
- Technik/
- Bücher/
- Konzepte/
- Tools/
- Code-Snippets/

**Regeln:**
- Gut getaggt für schnelles Finden
- Verlinkt mit anderen Notizen
- Wiederverwendbares Wissen

**Tags:** #type/resource #status/evergreen
```

**Inhalt für `04 Archives/README.md`:**
```markdown
# 04 Archives

**Zweck:** Abgeschlossene Projekte und altes Material

**Struktur:**
- JJJJ-Projekte/ (z.B. 2024-Projekte)
- Alte-Themen/
- Backup/

**Regeln:**
- Nicht löschen, nur archivieren
- Selten gebraucht, aber verfügbar
- Kann komprimiert werden

**Tags:** #status/archived
```

**Inhalt für `MOCs/README.md`:**
```markdown
# MOCs (Maps of Content)

**Zweck:** Navigation und Übersicht

**Was ist ein MOC?**
Eine "Inhaltsseite" die verwandte Notizen verlinkt.

**Haupt-MOCs:**
- 🏠 Home.md - Dashboard
- 📊 MOC - Projekte.md
- 🧠 MOC - Wissen.md
- 💻 MOC - Technik.md
- 📚 MOC - Ressourcen.md

**Regeln:**
- Jeder MOC hat Links zu allen relevanten Notizen
- Notizen verlinken zurück zum MOC
- Regelmäßig aktualisieren

**Tags:** #type/moc
```

**Check 1.2:** READMEs existieren?
```powershell
Get-ChildItem "$vaultPath\*" -Include "README.md" -Recurse | Select-Object FullName
```

**Erwartetes Ergebnis:** 6 README.md Dateien gefunden

---

## Phase 2: Tag-System implementieren

### Schritt 2.1: Tag-Konfiguration erstellen

**Aktion:** Erstelle zentrale Tag-Definition

**Datei:** `MOCs/Tag-System.md`

```markdown
---
tags: ["#type/moc", "#meta/tags"]
---

# Tag-System

## Übersicht aller Tags

### Status-Tags (Lebenszyklus)
- `#status/seed` 🌱 Neu, unverarbeitet
- `#status/sprout` 🌿 Wächst, wird erweitert
- `#status/evergreen` 🌳 Reif, vollständig
- `#status/dormant` 💤 Schlafend (archiviert)
- `#status/dead` 🍂 Veraltet (löschbar)
- `#status/inbox` 📥 In Inbox

### Typ-Tags (Art der Notiz)
- `#type/note` 📝 Standard
- `#type/moc` 🗺️ Map of Content
- `#type/project` 📊 Projekt
- `#type/area` 🗂️ Bereich
- `#type/resource` 📚 Ressource
- `#type/person` 👤 Person
- `#type/book` 📖 Buch
- `#type/concept` 💡 Konzept
- `#type/code` 💻 Code
- `#type/template` 📋 Template

### Themen-Tags (Inhalt)
- `#tech/ai` 🤖 KI
- `#tech/programming` 💻 Programmierung
- `#tech/openclaw` 🦞 OpenClaw
- `#tech/web` 🌐 Webentwicklung
- `#biz/strategy` 📈 Strategie
- `#biz/productivity` ⚡ Produktivität
- `#life/health` ❤️ Gesundheit
- `#life/learning` 📖 Lernen
- `#life/ideas` 💡 Ideen

### Prioritäts-Tags
- `#prio/p0` 🔴 Kritisch (sofort)
- `#prio/p1` 🟠 Hoch (diese Woche)
- `#prio/p2` 🟡 Mittel (diesen Monat)
- `#prio/p3` 🟢 Niedrig (irgendwann)

### OpenClaw-Tags (Integration)
- `#claw/session` 🤖 Von Session erstellt
- `#claw/insight` 💡 Wichtige Erkenntnis
- `#claw/todo` ✅ Offene Aufgabe
- `#claw/memory` 🧠 Für MEMORY.md
- `#claw/sync` 🔄 Synchronisiert

## Tag-Regeln

1. **Mindestens 3 Tags pro Notiz:**
   - 1 Status-Tag
   - 1 Typ-Tag
   - 1 Themen- oder Prioritäts-Tag

2. **Maximal 7 Tags:** Sonst unübersichtlich

3. **Konsistente Schreibweise:**
   - Kleinbuchstaben
   - Bindestriche statt Leerzeichen
   - Englisch bevorzugt (außer Eigennamen)

4. **Keine doppelten Tags:**
   - Nicht `#AI` und `#ai`
   - Nicht `#OpenClaw` und `#openclaw`

## Tag-Workflow

```
Neue Notiz → #status/seed + #type/note
     ↓
Bearbeitet → #status/sprout
     ↓
Fertig + verlinkt → #status/evergreen
     ↓
Veraltet → #status/archived
```
```

**Check 2.1:** Tag-System existiert?
```powershell
Test-Path "$vaultPath\MOCs\Tag-System.md"
```

**Erwartetes Ergebnis:** `True`

---

### Schritt 2.2: Template für neue Notizen

**Aktion:** Erstelle Standard-Template

**Datei:** `MOCs/Templates/Standard-Note.md`

```markdown
---
tags:
  - "#status/seed"
  - "#type/note"
date: {{date:YYYY-MM-DD}}
source: ""
---

# {{title}}

## Zusammenfassung

[Kurze Beschreibung in 1-2 Sätzen]

## Hauptinhalt

[Hier der eigentliche Inhalt]

## Verwandte Notizen

- [[MOC - Thema]]
- [[Andere Notiz]]

## Offene Fragen/Aufgaben

- [ ] Noch zu klären... #claw/todo

---

#status/seed #type/note
```

**Check 2.2:** Template existiert?
```powershell
Test-Path "$vaultPath\MOCs\Templates\Standard-Note.md"
```

---

## Phase 3: MOCs (Maps of Content) erstellen

### Schritt 3.1: Home Dashboard

**Aktion:** Erstelle zentrale Startseite

**Datei:** `Home.md`

```markdown
---
tags: ["#type/moc", "#status/evergreen"]
---

# 🏠 Home

Willkommen in deinem Second Brain!

## 📊 Dashboard

### Aktive Projekte
```dataview
TABLE status, prio
FROM "01 Projects"
WHERE status = "active"
SORT prio ASC
```

### Offene Aufgaben
```dataview
TASK
WHERE contains(tags, "#claw/todo") AND !completed
SORT prio ASC
```

### Neue Notizen (letzte 7 Tage)
```dataview
TABLE date, tags
FROM "00 Inbox" OR "01 Projects" OR "02 Areas" OR "03 Resources"
WHERE date >= date(today) - dur(7 days)
SORT date DESC
LIMIT 10
```

## 🗺️ Navigation

### Haupt-MOCs
- [[MOC - Projekte]] - Alle Projekte
- [[MOC - Areas]] - Verantwortungsbereiche
- [[MOC - Ressourcen]] - Wissen und Referenzen
- [[MOC - Technik]] - Tech-Stack, Tools, Code
- [[MOC - OpenClaw]] - OpenClaw Integration

### Meta
- [[Tag-System]] - Alle Tags im Überblick
- [[MOCs/README]] - Was sind MOCs?

## 🚀 Schnellaktionen

- [Neue Notiz erstellen](obsidian://new?file=00%20Inbox/)
- [Inbox leeren](obsidian://search?query=path:%2200%20Inbox%22)
- [Offene TODOs](obsidian://search?query=tag:#claw/todo)

## 📈 Statistiken

- **Gesamt-Notizen:** `=length(this.file.inlinks)`
- **In Inbox:** `=length(file.inlinks) WHERE file.folder = "00 Inbox"`
- **Projekte aktiv:** `=length(file.inlinks) WHERE file.folder = "01 Projects"`

---

Letzte Aktualisierung: `=dateformat(this.file.mtime, "yyyy-MM-dd HH:mm")`
```

**Check 3.1:** Home.md existiert und Dataview-Queries sind korrekt?
```powershell
Test-Path "$vaultPath\Home.md"
```

---

### Schritt 3.2: Themen-MOCs erstellen

**Aktion:** Erstelle MOC für Projekte

**Datei:** `MOCs/MOC - Projekte.md`

```markdown
---
tags: ["#type/moc", "#status/evergreen"]
---

# MOC - Projekte

Übersicht aller Projekte.

## Aktive Projekte

```dataview
TABLE startdate, duedate, status, completion
FROM "01 Projects"
WHERE status = "active"
SORT duedate ASC
```

## Abgeschlossene Projekte

```dataview
TABLE completion, status
FROM "01 Projects"
WHERE status = "completed"
SORT completion DESC
LIMIT 10
```

## Projekt-Templates

- [[Template - Projekt-Start]]
- [[Template - Projekt-Abschluss]]

## Verwandte Bereiche

- [[MOC - Areas]] - Kontinuierliche Verantwortungen
- [[MOC - Ressourcen]] - Benötigtes Wissen

---

#type/moc #status/evergreen
```

**Aktion:** Erstelle MOC für Technik

**Datei:** `MOCs/MOC - Technik.md`

```markdown
---
tags: ["#type/moc", "#status/evergreen", "#tech/programming"]
---

# MOC - Technik

Tech-Stack, Tools, Code-Snippets.

## Programmierung

### Sprachen
- [[Python]]
- [[TypeScript]]
- [[PowerShell]]

### Frameworks
- [[React]]
- [[Next.js]]
- [[Node.js]]

## Tools

### Entwicklung
- [[VS Code]]
- [[Git]]
- [[Docker]]

### OpenClaw
- [[OpenClaw Config]]
- [[OpenClaw Skills]]
- [[OpenClaw Troubleshooting]]

## Code-Snippets

```dataview
LIST
FROM "03 Resources" OR "00 Inbox"
WHERE contains(tags, "#type/code")
SORT file.name ASC
```

## Verwandte MOCs

- [[MOC - Ressourcen]]
- [[MOC - OpenClaw]]

---

#type/moc #status/evergreen #tech/programming
```

**Aktion:** Erstelle MOC für OpenClaw

**Datei:** `MOCs/MOC - OpenClaw.md`

```markdown
---
tags: ["#type/moc", "#status/evergreen", "#tech/openclaw"]
---

# MOC - OpenClaw

Alles rund um OpenClaw.

## Konfiguration

- [[OpenClaw Config]] - Hauptkonfiguration
- [[OpenClaw Environment]] - Umgebungsvariablen
- [[OpenClaw Troubleshooting]] - Problemlösungen

## Skills

### Meine Skills
```dataview
LIST
FROM "03 Resources/OpenClaw"
WHERE contains(tags, "#type/skill")
SORT file.name ASC
```

### Skill-Templates
- [[Template - Skill]]
- [[Template - Hook]]

## Integration

- [[OpenClaw + Obsidian]] - Sync-Strategie
- [[MEMORY.md]] - Langzeitgedächtnis
- [[SOUL.md]] - Persönlichkeit

## Sessions

```dataview
TABLE date, tags
FROM "00 Inbox" OR "03 Resources"
WHERE contains(tags, "#claw/session")
SORT date DESC
LIMIT 20
```

## TODOs

```dataview
TASK
WHERE contains(tags, "#claw/todo")
WHERE !completed
SORT prio ASC
```

---

#type/moc #status/evergreen #tech/openclaw
```

**Check 3.2:** Alle MOCs existieren?
```powershell
$requiredMocs = @("Home.md", "MOCs/MOC - Projekte.md", "MOCs/MOC - Technik.md", "MOCs/MOC - OpenClaw.md")
foreach ($moc in $requiredMocs) {
    if (Test-Path "$vaultPath\$moc") {
        Write-Host "✅ $moc" -ForegroundColor Green
    } else {
        Write-Host "❌ $moc fehlt!" -ForegroundColor Red
    }
}
```

---

## Phase 4: OpenClaw-Integration

### Schritt 4.1: MEMORY.md Setup

**Aktion:** Erstelle oder aktualisiere MEMORY.md

**Datei:** `MEMORY.md` (im Vault-Root)

```markdown
---
tags: ["#claw/memory", "#status/evergreen", "#type/reference"]
date: 2026-04-05
---

# MEMORY.md

Langzeitgedächtnis für OpenClaw.

## Fakten über den User

- Name: Parzival
- OS: Windows 10
- Shell: PowerShell
- Editor: VS Code
- Vault-Pfad: `C:\Users\andre\Obsidian Vault`

## Präferenzen

- Live-Updates alle 30 Sekunden
- Keine stille Verarbeitung
- Klare "Fertig!"-Signale
- Schrittweise Implementation mit Checks

## Wichtige Pfade

```
C:\Users\andre\
├── .openclaw\workspace\          # OpenClaw Arbeitsverzeichnis
├── .openclaw\registry\           # Skills, Agents, Hooks
├── Documents\Andrew Openclaw\    # Hauptarbeitsverzeichnis
└── Obsidian Vault\               # Second Brain (dieses Vault)
```

## Tools & Patterns

### File Operations
- Immer `read` → modify → `write` (nicht `edit`)
- Pfade mit doppelten Backslashes escapen
- Vor dem Schreiben validieren

### Tagging-System
- Status: #status/seed, #status/sprout, #status/evergreen
- Typ: #type/note, #type/moc, #type/project
- Themen: #tech/ai, #tech/openclaw, #biz/productivity
- Priorität: #prio/p0, #prio/p1, #prio/p2, #prio/p3
- OpenClaw: #claw/session, #claw/insight, #claw/todo

## Aktive Projekte

- Obsidian Second Brain Setup #status/active #prio/p1
- OpenClaw Config Optimierung #status/active #prio/p2

## Offene TODOs

- [ ] Vault-Organisation vervollständigen #claw/todo #prio/p1
- [ ] Tags auf bestehende Notizen anwenden #claw/todo #prio/p2
- [ ] MOCs verlinken und pflegen #claw/todo #prio/p3

---

#claw/memory #status/evergreen #type/reference
```

**Check 4.1:** MEMORY.md existiert?
```powershell
Test-Path "$vaultPath\MEMORY.md"
```

---

### Schritt 4.2: Sync-Skill erstellen

**Aktion:** Erstelle Skill für OpenClaw-Obsidian-Sync

**Datei:** `.openclaw/skills/obsidian-sync.md`

```yaml
---
id: "obsidian-sync"
name: "obsidian-sync"
triggers: ["sync to obsidian", "update second brain", "session to vault"]
status: "active"
---

## OpenClaw → Obsidian Sync

Synchronisiert OpenClaw-Sessions mit dem Obsidian Vault.

### Workflow

1. **Session analysieren**
   - Extrahiere Key Insights
   - Identifiziere neue Konzepte
   - Finde offene TODOs

2. **Notiz erstellen**
   - Speicherort: `03 Resources/Sessions/YYYY-MM-DD-Session.md`
   - Tags: #claw/session #status/sprout
   - Verlinke verwandte MOCs

3. **Tags zuweisen**
   - Themen-Tag basierend auf Inhalt (#tech/ai, #biz/strategy)
   - Priorität wenn TODOs gefunden (#prio/p1, #prio/p2)
   - Status: #status/sprout (wird später zu #status/evergreen)

4. **MOCs aktualisieren**
   - Füge Link in passendem MOC hinzu
   - Erstelle Rücklink in Session-Notiz

5. **MEMORY.md updaten**
   - Neue Fakten extrahieren
   - TODOs übernehmen
   - Projekte aktualisieren

6. **Home.md refresh**
   - Neue Notiz erscheint automatisch in Dataview

### Output-Format

```
✅ Session "Kimi Optimization" synchronisiert:
   📁 Gespeichert: 03 Resources/Sessions/2026-04-05-Kimi-Optimization.md
   🏷️ Tags: #claw/session #tech/ai #status/sprout #prio/p2
   🔗 Verlinkt in: MOC - Technik, MOC - OpenClaw
   📝 MEMORY.md aktualisiert: +2 Fakten, +1 TODO
```

### Automatisierung

```bash
# Nach jeder Session automatisch ausführen
openclaw run obsidian-sync --latest-session

# Alle Sessions der letzten Woche syncen
openclaw run obsidian-sync --since "7 days"

# Trockenlauf (nur anzeigen, nicht speichern)
openclaw run obsidian-sync --dry-run
```
```

**Check 4.2:** Skill existiert und ist registriert?
```powershell
Test-Path "$env:USERPROFILE\.openclaw\skills\obsidian-sync.md"
openclaw skills list | findstr "obsidian-sync"
```

---

## Phase 5: Validierung & Test

### Schritt 5.1: Gesamt-Check

**Aktion:** Führe alle Checks aus

```powershell
Write-Host "=== PARA Struktur ===" -ForegroundColor Cyan
Get-ChildItem $vaultPath -Directory | Select-Object Name

Write-Host "`n=== READMEs ===" -ForegroundColor Cyan
Get-ChildItem "$vaultPath\*" -Include "README.md" -Recurse | Measure-Object | Select-Object Count

Write-Host "`n=== Tag-System ===" -ForegroundColor Cyan
Test-Path "$vaultPath\MOCs\Tag-System.md"

Write-Host "`n=== MOCs ===" -ForegroundColor Cyan
Get-ChildItem "$vaultPath\MOCs\*.md" | Select-Object Name

Write-Host "`n=== Home Dashboard ===" -ForegroundColor Cyan
Test-Path "$vaultPath\Home.md"

Write-Host "`n=== MEMORY.md ===" -ForegroundColor Cyan
Test-Path "$vaultPath\MEMORY.md"

Write-Host "`n=== OpenClaw Skill ===" -ForegroundColor Cyan
Test-Path "$env:USERPROFILE\.openclaw\skills\obsidian-sync.md"
```

**Erwartetes Ergebnis:**
- 6 Ordner (00-04, MOCs)
- 6 READMEs
- Tag-System.md existiert
- Mind. 4 MOCs
- Home.md existiert
- MEMORY.md existiert
- obsidian-sync.md existiert

---

### Schritt 5.2: Test-Notiz erstellen

**Aktion:** Erstelle Test-Notiz mit korrektem Tagging

**Datei:** `00 Inbox/Test-Notiz.md`

```markdown
---
tags:
  - "#status/seed"
  - "#type/note"
  - "#tech/openclaw"
  - "#prio/p2"
date: 2026-04-05
---

# Test-Notiz

Dies ist eine Test-Notiz zur Validierung des Tag-Systems.

## Inhalt

- OpenClaw Second Brain funktioniert
- Tags werden korrekt erkannt
- MOCs sind verlinkt

## Verwandte Notizen

- [[MOC - OpenClaw]]
- [[Tag-System]]

## TODOs

- [ ] Diese Test-Notiz nach erfolgreichem Test löschen #claw/todo

---

#status/seed #type/note #tech/openclaw #prio/p2
```

**Check 5.2:** Test-Notiz wird in Dataview angezeigt?
- Öffne Home.md in Obsidian
- Prüfe ob "Neue Notizen" die Test-Notiz zeigt
- Prüfe ob Tags korrekt gerendert werden

---

## 🎉 Fertig!

### Zusammenfassung

✅ **Phase 1:** PARA-Ordnerstruktur mit READMEs
✅ **Phase 2:** Professionelles Tag-System
✅ **Phase 3:** MOCs mit Dataview-Queries
✅ **Phase 4:** OpenClaw-Integration mit MEMORY.md
✅ **Phase 5:** Validierung und Test

### Nächste Schritte

1. **Bestehende Notizen migrieren:**
   ```bash
   openclaw run obsidian-organizer --tag-existing
   ```

2. **Täglicher Workflow:**
   - Neue Notizen in Inbox
   - Täglich reviewen und taggen
   - Wöchentlich MOCs aktualisieren

3. **OpenClaw-Sessions syncen:**
   ```bash
   openclaw run obsidian-sync --latest-session
   ```

### Troubleshooting

| Problem | Lösung |
|---------|--------|
| Dataview zeigt nichts | Plugin "Dataview" installieren und aktivieren |
| Tags nicht farbig | Plugin "Tag Wrangler" oder "Supercharged Links" |
| MOCs nicht verlinkt | Links mit `[[` und `]]` prüfen |
| OpenClaw findet Skill | `openclaw skills refresh` ausführen |

---

**Implementation abgeschlossen!** 🚀
