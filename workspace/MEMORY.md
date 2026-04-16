# SYSTEMSPEZIFIKATIONEN - Parzival

**Datum:** 2026-04-09

**WICHTIG:** Diese Info ist relevant für alle AI/Performance-Empfehlungen!

---

## Technologie-Stack (OpenClaw AI Harness)

| Komponente | Technologie | Notiz |
|------------|-------------|-------|
| **OpenClaw Gateway** | Rust | Core-System |
| **MCP Server** | Rust/Node.js | Model Context Protocol |
| **TUI** | Rust | Terminal Interface |
| **Session Management** | Rust | Agent-Isolation |
| **Cron/Scheduler** | Rust | Automatisierung |

**Implikation:** Rust-basiertes System = Hohe Performance, Speichersicherheit, keine GC-Pausen.

---

## Meine Fähigkeiten & Tools

### PowerShell / Exec-Zugriff
**Status:** ✅ AKTIV (ask: off)

**Präferenz (kritisch):**
- **Immer PowerShell bevorzugen** gegenüber Bash/Git Bash
- Wenn Git Bash unbedingt nötig ist: **sehr genaue Instruktionen** geben
- Coding/Scripting: PowerShell oder Python (cross-platform)

Ich habe Zugriff auf PowerShell für:
- Datei-Operationen (read, write, edit)
- Skript-Ausführung (.

**Einschränkungen:**
- Nur in `safeBinTrustedDirs`:
  - `C:\Users\andre\.openclaw`
  - `C:\Users\andre\.openclaw\workspace`
  - `C:\Users\andre\.openclaw\workspace\skills`
- Keine Admin-Befehle ohne explizite Anfrage
- Keine sensiblen System-Commands

**Wichtige Skripte:**
- `SecondBrain/00-Meta/Scripts/setup-symlinks.ps1` - Symlink-Setup
- `SecondBrain/00-Meta/Scripts/check-vault-health.ps1` - Health-Check
- `SecondBrain/00-Meta/Scripts/semantic-memory-poc.py` - Semantische Vault-Suche
- `SecondBrain/00-Meta/Scripts/auto-retrospective.py` - Automatische Retrospektiven

### Active Projects & Capabilities
- **Mini-Evolve-Loop:** Lokaler Code-Evolution-Loop via Ollama (Qwen2.5 Coder 7B). Siehe `03-Knowledge/How-To/mini-evolve-loop.md`
- **Semantic Memory:** FAISS-basierte semantische Suche über SecondBrain Vault. Siehe `03-Knowledge/References/semantic-memory-poc.md`
- **05-Research Staging:** AI-generierte Vorschläge landen in `05-Research/pending/` und warten auf GO

### Coding-Skills
- **TypeScript/JavaScript** - Primäre Sprache
- **Python** - Für Scripts und AI
- **PowerShell** - Windows Automation
- **Rust** - Grundlagen (für OpenClaw Verständnis)

### Verfügbare Tools
- `read` / `write` / `edit` - Datei-Operationen
- `exec` - Shell/PowerShell
- `web_search` / `web_fetch` - Internet-Recherche
- `browser` - Browser-Steuerung
- `sessions_spawn` - Sub-Agenten starten
- `cron` - Automatisierung

---

## Hardware

| Komponente | Spezifikation |
|------------|---------------|
| **CPU** | Intel Core i7-6820HK @ 2.70GHz (4 Kerne/8 Threads) |
| **RAM** | 32 GB DDR4 |
| **Speicher** | 1TB Samsung SSD 860 EVO (932 GB nutzbar) |
| **GPU** | NVIDIA GeForce GTX 980M (8 GB VRAM) |
| **iGPU** | Intel HD Graphics 530 |
| **System** | Windows 10/11 64-bit |

## Kritische Einschränkungen

- **KEIN H100/A100!** Nur GTX 980M (4GB effektiv nutzbar wegen Shared Memory)
- **RAM:** 32GB gut für LLM-Hosting (gguf-Modelle bis ~13B Parameter möglich)
- **SSD:** 1TB ausreichend, aber keine riesigen Modelle (70B+ zu groß)

## Implikationen für AI-Workloads

### ✅ Funktioniert:
- Local LLMs bis ~13B Parameter (GGUF/Q4)
- Stable Diffusion (CPU oder 980M)
- Code-Generierung via API (Claude, OpenAI)
- Unser SecondBrain System
- ECC Autoresearch (kleine Modelle)

### ❌ Nicht möglich:
- Große LLMs (70B+) lokal
- H100-optimierte Workflows
- Große Batch-Training-Jobs
- CUDA-intensive Anwendungen (alte Architektur)

## Empfohlene lokale Modelle

1. **Llama 3.1 8B Q4** - Für lokale Inferenz
2. **Qwen 2.5 7B** - Alternative
3. **Mistral 7B** - Gut für Coding

## Speicherplatz

- **Gesamt:** 1TB SSD
- **Genutzt:** Vault-Archive hat viele Dateien
- **Verfügbar:** Ausreichend für SecondBrain

**Merke:** Bei AI-Empfehlungen immer auf GTX 980M (4GB effektiv) und 32GB RAM achten!

---

## SecondBrain Vault

**WICHTIG:** Parzival hat ein strukturiertes Knowledge Management System im Workspace.

### Location
```
C:\Users\andre\.openclaw\workspace\SecondBrain\
```

### Struktur
- **00-Meta/** - Templates, MOCs, Scripts, Config
- **01-Daily/** - Tagesnotizen (Format: DD-MM-YYYY.md)
- **02-Projects/** - Projekte (Active/, Paused/, Completed/)
- **03-Knowledge/** - Wissens-Base (Concepts/, How-To/, References/, People/)
- **04-Decisions/** - Architektur-Entscheidungen (ADRs)
- **99-Archive/** - Backup/Altlasten

### Wichtige MOCs (Maps of Content)
- `_MOC-Startseite.md` - Hauptnavigation
- `_MOC-Daily.md` - Übersicht Daily Notes
- `_MOC-Projects.md` - Übersicht Projekte
- `_MOC-Knowledge.md` - Übersicht Wissen

### Konventionen
- **Datum:** Deutsches Format (DD-MM-YYYY)
- **Dateinamen:** Snake_Case
- **Links:** WikiLinks mit Aliases
- **Templates:** In 00-Meta/Templates/

### Agent-Aufgaben
Wenn Parzival nach folgendem fragt:
- "Was sind meine Projekte?" → `SecondBrain/02-Projects/` lesen
- "Was haben wir besprochen?" → `SecondBrain/01-Daily/` lesen
- "Zeig meine Entscheidungen" → `SecondBrain/04-Decisions/` lesen
- "Wissen über X" → `SecondBrain/03-Knowledge/` durchsuchen

### Bereinigung abgeschlossen (10-04-2026)

**Was wurde gemacht:**
- ✅ `obsidian-vault/` migriert und gelöscht
- ✅ `test-obsidian-vault/` gelöscht
- ✅ `vault-recovery/` gelöscht
- ✅ 7 wichtige Sessions migriert
- ✅ 4 ECC-Framework Scripts kopiert
- ✅ Master Rework Dokumente aufgeteilt und migriert
- ✅ Vault-Archive bereinigt (~7.000 Dateien analysiert)
- ✅ Code-Projekte nach `~/Documents/Andrew Openclaw/Git-repos/` verschoben

### Outside Resources (Externe Referenzen & Code)
**Pfad:** `C:\Users\andre\Documents\Outside_resources\`

**Zweck:** Ablage für:
- Code-Projekte (eigene und fremde)
- Referenz-Daten und -Materialien
- Ideen/Dokumente von anderen LLMs (MD, PDF)
- Externe Ressourcen zum Nachschlagen

**Inhalt:**
- **harness-redesign/** (53 MB) - TypeScript Implementierung
- **everything-claude-code-main/** (30 MB) - Externes Referenz-Repo
- **output-buffering-harness/** (133 KB) - Python Projekt

### Verfügbare Scripts
**Ort:** `SecondBrain/00-Meta/Scripts/`
- `ecc-framework/sync-openclaw-to-obsidian.ps1` - Sync zwischen OpenClaw und Vault
- `ecc-framework/auto-backup.ps1` - Automatische Backups
- `ecc-framework/drift-detection.ps1` - Konfigurations-Drift Detection
- `ecc-framework/ecc-stability.ps1` - System-Stabilitäts-Checks

**NEU: ECC-Utilities PowerShell-Module** (10-04-2026)

**Ort:** `00-Meta/Scripts/ecc-framework/`

1. **ECC-Utilities.psm1** - Logging, Validierung, Fehlerbehandlung
   - `Write-ECCLog`, `Test-VaultStructure`, `Invoke-WithRetry`, `Invoke-SafeFileOperation`

2. **MermaidGenerator.psm1** - Diagramme für Obsidian (NEU)
   - `New-ArchitectureDiagram` - System-Architektur
   - `New-Flowchart` - Workflows
   - `New-Mindmap` - Brainstorming
   - `New-ClassDiagram` - Code-Struktur

3. **Encryption.psm1** - API-Key Verschlüsselung (NEU)
   - `Protect-ApiKey` - Verschlüsselt und speichert API-Keys
   - `Unprotect-ApiKey` - Entschlüsselt API-Keys
   - `Get-ApiKeys` - Listet alle Keys
   - `Remove-ApiKey` - Löscht einen Key
   - **Sicherheit:** AES-256-GCM, Master-Key in `00-Meta/Config/.masterkey`

**Import:** `Import-Module "...\ ECC-*.psm1"`

### Bekannte Probleme & Workarounds
- **Edit-Tool Bug:** `new_string` Parameter wird nicht akzeptiert
  - **Workaround:** `read` + `write` statt `edit` verwenden
  - **Doku:** `03-Knowledge/How-To/edit-tool-workaround.md`

### Agent Verhaltensregeln (aus Retrospektive 10-04-2026)

**WICHTIG:** Diese Regeln wurden aus Feedback der Session am 10-04-2026 abgeleitet.

| Regel | Konkrete Umsetzung |
|-------|-------------------|
| **1. "Fertig"-Meldung** | NIE "Das ist fertig" ohne explizite Prüfung. Stattdessen: "Das habe ich geprüft: [Liste]. Das fehlt noch: [Liste]" |
| **2. Löschen = GO erforderlich** | Vor JEDEM Löschen: "Soll ich [X] wirklich löschen?" - Keine automatischen Löschungen |
| **3. Oberflächlichkeit erkennen** | Wenn ich denke "Das reicht so" → Tiefer gehen. Checkliste nutzen: "Habe ich wirklich ALLES geprüft?" |
| **4. Geschwindigkeit < Qualität** | Lieber langsam und richtig als schnell und fehlerhaft. Besonders bei Migrationen/Projekten |
| **5. Retrospektive automatisch** | Am Ende jeder Session: "Soll ich die Retrospektive durchführen?" [Ja/Skip] - Bei Skip: doppelte Bestätigung |
| **6. MEMORY.md aktiv nutzen** | Vor jedem Vorschlag: "Was haben wir schon?" → MEMORY.md lesen. Keine Annahmen, nur Fakten. Siehe: [[workflow-aktives-memory-lesen\|Workflow: Aktives MEMORY.md Lesen]] |
| **7. Projekt-Klarstellung** | Bei neuen Aufgaben/Prozessen IMMER fragen: "Ist das ein Projekt für dich (mit Tracking, Zielen, Status), oder reine interne Doku?" Nie annehmen, immer klären! |
| **8. Migrations-Validierung** | Nach JEDER Migration: Stichprobenartig 3+ Dateien auf vollständigen Inhalt prüfen. Nie nur Metadaten checken! |
| **9. Backup vor Löschen** | NIE Originale löschen, bevor nicht Validierung OK ist. Backup-Ordner erstellen vor Migration. |
| **10. Content-Check bei migrated** | Bei `migrated` Tag immer prüfen: "Hat diese Datei wirklich Inhalt?" Platzhalter wie "*Inhalt nicht migriert*" = FEHLER. |
| **11. Dry-Run vor Migration** | Bei Migrationen erst simulieren (1-2 Dateien Testlauf), dann GO holen, dann restliche Dateien. |
| **12. Keine leeren Templates** | Nie Dateien mit leeren Platzhaltern erstellen. Entweder vollständiger Inhalt oder gar nicht. |
| **13. Große Downloads evaluieren** | Bei Downloads >100MB oder langen Laufzeiten: Manuelle Alternative prüfen (Browser, vorherige Downloads). Automatisierung ist nicht immer optimal. |

**Parzivals Präferenzen (Priorisiert):**
- Qualität > Geschwindigkeit
- Vollständigkeit > Schnelligkeit
- Schritt-für-Schritt mit Zwischen-Abfragen
- Batch-basiert: Ein Schritt fertig, dann GO holen

---

### Was ist ein Projekt für Parzival?

**KRITISCH:** Parzival sieht organisatorische, systemische und prozessuale Verbesserungen **ALS PROJEKTE** an — nicht als reine Meta-Doku.

| Typ | Beispiel | Wo speichern |
|-----|----------|--------------|
| **Projekt** | Neue Checkliste für Agent-Startup, Template-System, Automatisierung | `02-Projects/Active/` |
| **Meta/Doku** | Reine Beschreibung bestehender Struktur ohne Umsetzungsbedarf | `00-Meta/` |

**Daumenregel:** Wenn es Ziele, Status-Tracking, Phasen oder Deliverables hat → **Projekt**. Wenn es nur beschreibt was schon existiert → **Meta**.

**Wichtig:** Im Zweifel immer fragen! Nie annehmen.

---

### Lessons Learned: Migration-Fehler (11-04-2026)

**FEHLER:** Bei frueherer Migration wurden 6 Daily Notes zu leeren Huelen migriert.
- Nur Metadaten (Datum, Tags) wurden uebernommen
- Inhalt wurde nicht kopiert
- Originale wurden geloescht
- **Resultat: Datenverlust**

**Betroffene Dateien:**
- 02-04-2026.md
- 30-03-2026.md
- 04-04-2026.md
- 05-04-2026-v1.md
- 06-04-2026.md
- (10-04-2026-v2.md war korrekt)

**Ursache:** Keine Validierung nach Migration. Keine Stichproben.

**Massnahmen:** Regeln 8-12 wurden zu Agent Verhaltensregeln hinzugefuegt.

**Status:** Leere Dateien als VERLOREN markiert, nicht geloescht (Transparenz).

---

### Wichtige Projekte im Vault

**HINWEIS:** Bei Fragen nach TODOs, offenen Tasks oder aktiven Projekten → **immer `SecondBrain/02-Projects/Active/` prüfen!**

Dort liegen alle aktiven Projekte mit Status, Tasks und Deliverables.

- **OpenClaw Renovierung** - 12-Wochen-Plan für System-Transformation
  - Siehe: `02-Projects/Active/openclaw-renovation.md`
  - Architektur-ADR: `04-Decisions/ADR-004-openclaw-architecture.md`
  - Implementations-Plan: `03-Knowledge/How-To/openclaw-implementations-plan.md`
- **OpenClaw Google API Key Setup** - API Key für Web-Search
  - Siehe: `02-Projects/Active/OpenClaw-Google-API-Key.md`

### Night Agent
Geplant: Automatische Indexierung, Duplicate Detection, Broken Link Detection.
Status: In Entwicklung (siehe Projekt: vault-migration)

---

## Präferenzen (Wichtig!)

- **Sprache:** Deutsch für Antworten
- **Datum:** DD-MM-YYYY (deutsches Format)
- **Interface:** GUI/clickable bevorzugt über CLI
- **Design:** Linear-style dark aesthetic
- **Code:** TypeScript strict mode
- **Keine Emojis:** Nicht im Terminal darstellbar, daher vermeiden
