# Vault Setup & Konfiguration

> Dokumentation fuer SecondBrain Vault-Struktur und externe Verknuepfungen

---

## Vault-Struktur

```
SecondBrain/                    <- Haupt-Vault
├── 00-Meta/                    <- Meta-Daten, Configs, Scripts
│   ├── Scripts/                <- Automatisierungs-Scripts
│   │   ├── setup-symlinks.ps1  <- Symlink-Setup
│   │   ├── check-vault-health.ps1
│   │   └── ...
│   ├── Templates/              <- Note-Templates
│   ├── Config/                 <- Konfigurationsdateien
│   └── vault-config.md         <- Diese Datei
│
├── 01-Daily/                   <- Tagesnotizen
├── 02-Projects/                <- Projekte
├── 03-Knowledge/               <- Wissens-Base
├── 04-Decisions/               <- Architektur-Entscheidungen
│
├── skills/                     <- Symlink -> ~/.openclaw/workspace/skills
├── docs/                       <- Symlink -> ~/.openclaw/workspace/docs (optional)
│
└── _MOC-*.md                   <- Maps of Content (Navigation)
```

---

## Externe Verknuepfungen (Symlinks)

### Warum Symlinks?

**Vorteile:**
- Skills sind im Vault sichtbar -> WikiLinks funktionieren
- Werden von Obsidian indexiert -> Graph View, Backlinks
- Zukunft: Semantische Suche indexiert Skills mit
- Keine Datei-Duplikate
- Aenderungen an Skills sofort im Vault sichtbar

**Nachteile:**
- Bricht beim Verschieben des Vaults
- Muss auf neuen PCs neu eingerichtet werden
- Nicht versioniert (nur der Link, nicht das Ziel)

---

## Konfigurierte Symlinks

| Name | Ziel (Source) | Vault-Pfad | Status |
|------|---------------|------------|--------|
| **skills** | ~/.openclaw/workspace/skills | SecondBrain/skills | Aktiv |
| **docs** | ~/.openclaw/workspace/docs | SecondBrain/docs | Optional |

---

## Setup durchfuehren

### Erstmalige Einrichtung

```powershell
# 1. PowerShell als Administrator oeffnen

# 2. Zum Vault-Verzeichnis navigieren
cd "C:\Users\andre\.openclaw\workspace\SecondBrain"

# 3. Setup-Skript ausfuehren
.\00-Meta\Scripts\setup-symlinks.ps1

# 4. Obsidian neu starten (damit Aenderungen erkannt werden)
```

### Nach Vault-Verschiebung

Wenn du den Vault verschiebst, brechen die Symlinks. So behebst du es:

```powershell
# 1. Alte/broken Symlinks entfernen
cd "[Neuer Vault Pfad]"
Remove-Item -Path "skills" -Force  # Entfernt broken symlink

# 2. Setup neu ausfuehren
.\00-Meta\Scripts\setup-symlinks.ps1
```

---

## Health-Check

```powershell
# Ueberprueft alle Symlinks auf Integritaet
.\00-Meta\Scripts\check-vault-health.ps1
```

Ausgabe:
```
OK Symlink 'skills' ist gesund
   -> Ziel: C:\Users\andre\.openclaw\workspace\skills
   
X Symlink 'docs' ist BROKEN
   -> Erwartet: C:\Users\andre\.openclaw\workspace\docs
   -> Fuehre aus: .\00-Meta\Scripts\setup-symlinks.ps1
```

---

## Semantische Suche (Zukunft)

### Warum sind Symlinks wichtig fuer semantische Suche?

**Das Problem:**
Semantische Such-Tools indexieren nur Dateien, die physikalisch im Vault sind.

**Die Loesung:**
Symlinks machen externe Ordner Teil des Vaults -> werden mitindexiert.

### Geplante Integration

| Tool | Verwendung | Status |
|------|------------|--------|
| **Smart Connections** | Obsidian-Plugin fuer AI-Suche | Geplant |
| **Ollama + Embeddings** | Lokale semantische Suche | Geplant |
| **Night Agent** | Eigene Loesung mit ChromaDB | In Entwicklung |

**Beispiel-Szenario:**

Du suchst: "Wie mache ich ein Security Review?"

Ohne Symlinks:
-> Findet nur: Daily Notes, wo du ueber Security Review gesprochen hast

Mit Symlinks:
-> Findet: Daily Notes + SKILL.md selbst + Code-Beispiele
-> Zeigt: Aehnliche Skills (API Design, Testing Patterns)
-> Ergebnis: Vollstaendige, kontextreiche Antwort

---

## Wartung

### Regelmaessige Checks (monatlich)

```powershell
# Health-Check durchfuehren
.\00-Meta\Scripts\check-vault-health.ps1

# Bei Problemen: Setup wiederholen
.\00-Meta\Scripts\setup-symlinks.ps1
```

### Nach OpenClaw-Updates

Wenn neue Skills installiert werden:
- Symlinks bleiben erhalten
- Neue Skills sind sofort im Vault sichtbar
- Keine Aktion noetig

---

## Troubleshooting

### Problem: Symlink existiert, zeigt aber ins Leere

**Ursache:** Ziel-Ordner wurde verschoben oder geloescht

**Loesung:**
```powershell
Remove-Item -Path "skills" -Force
.\00-Meta\Scripts\setup-symlinks.ps1
```

### Problem: Obsidian zeigt Symlink nicht an

**Ursache:** Obsidian hat den Ordner noch nicht neu gescannt

**Loesung:**
1. Obsidian komplett schliessen
2. Neu oeffnen
3. Falls immer noch nicht sichtbar: Strg+P -> "Reload app without saving"

### Problem: Keine Berechtigung fuer Symlink-Erstellung

**Ursache:** PowerShell nicht als Admin gestartet

**Loesung:**
1. PowerShell schliessen
2. Rechtsklick -> "Als Administrator ausfuehren"
3. Skript erneut ausfuehren

### Problem: Encoding-Fehler im Skript

**Ursache:** Datei wurde mit falschem Encoding gespeichert

**Loesung:**
Das Skript ist jetzt in UTF-8 mit BOM kodiert. Falls Probleme auftreten:
```powershell
# Im PowerShell ISE oder VS Code oeffnen und speichern als UTF-8 with BOM
```

---

## Metriken

- Anzahl Symlinks: 1 (skills)
- Indexierbare Dateien: +80 durch Symlinks
- Setup-Dauer: < 10 Sekunden
- Wartungsaufwand: Minimal

---

Letzte Aktualisierung: 10-04-2026  
Version: 1.0  
Autor: Andrew
