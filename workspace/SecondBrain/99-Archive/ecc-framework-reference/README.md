---
date: 10-04-2026
type: reference
tags: [archive, ecc-framework, reference, legacy]
---

# ECC Framework Reference Archive

> **Archivierte Komponenten des ECC Second Brain Frameworks**
> 
> Diese Dateien sind Referenzmaterial und werden nicht aktiv verwendet.
> Sie können bei Bedarf reaktiviert werden.

---

## 📁 Struktur

```
99-Archive/ecc-framework-reference/
├── scripts/           # Archivierte PowerShell Scripts
├── modules/           # Archivierte PowerShell Module (optional)
├── config/            # YAML Konfigurationen (Referenz)
└── README.md          # Diese Datei
```

---

## 📜 Archivierte Scripts

### 1. sync-openclaw-to-obsidian.ps1
**Typ:** Automatisierungsscript
**Status:** Archiviert (nicht mehr aktiv)
**Grund:** Zwei-Wege-Sync zu komplex, manuelle Migration bevorzugt
**Reaktivierung:** Wenn automatischer Sync benötigt wird
**Pfad:** `scripts/sync-openclaw-to-obsidian.ps1`

### 2. auto-backup.ps1
**Typ:** Backup-Automatisierung
**Status:** Archiviert (redundant)
**Grund:** cmd-backup.ps1 bietet manuelle Kontrolle, die ausreicht
**Reaktivierung:** Wenn regelmäßige automatische Backups ohne cron nötig
**Pfad:** `scripts/auto-backup.ps1`

### 3. drift-detection.ps1
**Typ:** Struktur-Validierung
**Status:** Archiviert (nicht kritisch)
**Grund:** Vault-Struktur ist stabil, Test-VaultStructure() in Utilities reicht
**Reaktivierung:** Wenn sich Struktur häufig ändert und Validierung nötig
**Pfad:** `scripts/drift-detection.ps1`

### 4. ecc-stability.ps1
**Typ:** System-Stabilitäts-Checks
**Status:** Archiviert (redundant)
**Grund:** Funktionalität in eval-runner und drift-detection enthalten
**Reaktivierung:** Wenn dedizierte Stabilitäts-Checks nötig
**Pfad:** `scripts/ecc-stability.ps1`

---

## 📦 Archivierte Module

### DataviewQuery.psm1 (ZUKÜNFTIG)
**Typ:** PowerShell Modul
**Status:** Für später geplant (siehe MEMORY.md)
**Grund:** Dynamische Dataview-Queries momentan nicht nötig
**Reaktivierung:** Wenn komplexe, parametriserte Reports automatisch generiert werden sollen
**Pfad:** `modules/DataviewQuery.psm1` (noch nicht archiviert, in vault-archive)

### MermaidGenerator.psm1
**Typ:** PowerShell Modul - Diagramm-Generator
**Status:** Archiviert
**Grund:** Mermaid-Diagramme können auch manuell erstellt werden (mermaid.live, Templates)
**Reaktivierung:** Wenn häufig Diagramme aus PowerShell-Daten generiert werden müssen
**Pfad:** `modules/MermaidGenerator.psm1`

**Funktionen:**
- `New-ArchitectureDiagram` - System-Architektur-Diagramme
- `New-Flowchart` - Workflow/Flowcharts
- `New-Mindmap` - Brainstorming-Mindmaps
- `New-ClassDiagram` - Klassendiagramme für Code-Doku

**Beispiel-Nutzung:** Siehe `modules/example-usage.ps1`

**Alternative:** Mermaid-Syntax manuell schreiben oder online Tools nutzen

---

## ⚙️ Archivierte Konfigurationen

### drift-config.yaml
**Inhalt:** Struktur-Validierungs-Einstellungen
**Status:** Referenz
**Grund:** JSON-Config bevorzugt, YAML-Overhead nicht nötig
**Wert:** Zeigt komplette ECC-Ordnerstruktur als Referenz
**Pfad:** `config/drift-config.yaml`

### eval-template.yaml
**Inhalt:** CI/CD Test-Definitionen
**Status:** Referenz
**Grund:** Kein CI/CD-Pipeline-Bedarf
**Wert:** Beispiel für Qualitäts-Gates und Test-Struktur
**Pfad:** `config/eval-template.yaml`

### stability-config.yaml
**Inhalt:** Token-Thresholds, Backup-Einstellungen, Retry-Config
**Status:** Referenz
**Grund:** Feste Defaults in Scripts ausreichend
**Wert:** Zeigt detaillierte Konfigurationsmöglichkeiten
**Pfad:** `config/stability-config.yaml`

---

## 🔄 Reaktivierung

Um ein archiviertes Script zu reaktivieren:

```powershell
# Beispiel: sync-openclaw-to-obsidian.ps1 reaktivieren
Copy-Item `
  "99-Archive/ecc-framework-reference/scripts/sync-openclaw-to-obsidian.ps1" `
  "00-Meta/Scripts/ecc-framework/"
```

---

## 📊 Entscheidungsmatrix

| Komponente | Core-System | Archiviert | Reaktivieren wenn... |
|------------|-------------|------------|---------------------|
| ECC-Utilities.psm1 | ✅ Ja | ❌ Nein | Immer aktiv |
| Encryption.psm1 | ✅ Ja | ❌ Nein | Immer aktiv |
| context-switch.ps1 | ✅ Ja | ❌ Nein | Immer aktiv |
| cmd-backup.ps1 | ✅ Ja | ❌ Nein | Immer aktiv |
| eval-runner.ps1 | ✅ Ja | ❌ Nein | Testing/Validierung nötig |
| MermaidGenerator.psm1 | ❌ Nein | ✅ Ja | Häufig Diagramme aus Daten generieren |
| sync-openclaw | ❌ Nein | ✅ Ja | Automatischer Sync nötig |
| auto-backup.ps1 | ❌ Nein | ✅ Ja | Ohne cron automatisch backuppen |
| drift-detection.ps1 | ❌ Nein | ✅ Ja | Häufige Struktur-Änderungen |
| ecc-stability.ps1 | ❌ Nein | ✅ Ja | Dedizierte Stabilitäts-Checks |
| DataviewQuery.psm1 | ❌ Nein | ⏸️ Später | Dynamische Reports nötig |

---

## 📝 Notizen

**Archivierungsdatum:** 10-04-2026
**Archiviert von:** Andrew (andrew-main)
**Grund:** System schlanker machen, nur Core-Komponenten behalten
**Letzte Aktualisierung:** 10-04-2026

---

**Verwandte Dokumente:**
- [[../../03-Knowledge/References/ecc-framework-referenz|ECC Framework Referenz]]
- [[../../../../MEMORY.md|MEMORY.md - System-Dokumentation]]
