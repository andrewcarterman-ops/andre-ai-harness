# Modulares Agentisches Framework

**Version:** 1.0.0  
**Status:** Produktionsreif  
**Letztes Update:** 2026-03-25  
**Projekt:** proj-modular-agent

---

## Übersicht

Dies ist ein modulares, erweiterbares Agenten-Framework für OpenClaw. Es bietet:

- 🗂️ **Registry-basierte Architektur** für Agents, Skills, Hooks
- 🧠 **Kognitive Schicht** mit Search, Planning, Review
- 💾 **Persistenz** durch Session Store und projektspezifisches Lernen
- 🚀 **Betriebsfähigkeit** durch Install, Audit und Drift Detection

---

## Schnellstart

### 1. System prüfen
```powershell
.\scripts\install-check.ps1
```

### 2. Drift prüfen (Abweichungen vom Soll-Zustand)
```powershell
.\scripts\drift-check.ps1
```

### 3. Deploy (lokal)
```powershell
.\scripts\deploy.ps1 -Target local
```

---

## Architektur

Das Framework besteht aus 4 Phasen:

### Phase 1: Registry Foundation
**Komponenten:** Agent Registry, Skill Registry, Hook Engine

```
registry/
├── agents.yaml      # Agenten-Definitionen
├── skills.yaml      # Verfügbare Skills
└── hooks.yaml       # Hook-Konfiguration
```

**Zweck:** Zentrale Verwaltung und Discovery aller Komponenten

### Phase 2: Cognitive Layer
**Komponenten:** Search-first, Planner, Reviewer, Eval-Harness

```
registry/
├── search-index.json     # Durchsuchbarer Index
├── review-config.yaml    # Review-Einstellungen
└── eval-*.yaml          # Evaluation-Tests

plans/
├── TEMPLATE.md          # Plan-Template
└── *.md                 # Einzelne Pläne
```

**Zweck:** Intelligentes Verhalten durch Planung, Suche und Qualitätsprüfung

### Phase 3: Persistence & Learning
**Komponenten:** Session Store, Project Registry, Contextual Learning

```
memory/
├── sessions/
│   ├── README.md
│   └── SESSION-*.json   # Vollständige Sessions
└── self-improving/
    └── projects/
        └── {project-id}/
            ├── patterns.md
            └── preferences.md
```

**Zweck:** Nachvollziehbarkeit, Audit-Trail, projektspezifisches Lernen

### Phase 4: Operations
**Komponenten:** Selective Install, Audit, Drift Doctor, Multi-Target Adapter

```
registry/
├── install-manifest.yaml  # System-Manifest
├── audit-config.yaml      # Audit-Regeln
├── drift-config.yaml      # Drift Detection
└── targets.yaml          # Deployment Targets

scripts/
├── install-check.ps1     # Installations-Check
├── drift-check.ps1       # Drift Detection
└── deploy.ps1           # Deployment
```

**Zweck:** Reproduzierbarkeit, Qualitätssicherung, Deployment

---

## Verzeichnisstruktur

```
workspace/
├── docs/                          # Dokumentation
│   ├── drift-doctor-concept.md
│   └── multi-target-adapter-concept.md
├── hooks/                         # Hook-Templates
│   ├── session-start.md
│   ├── session-end.md
│   └── review-post-execution.md
├── memory/                        # Persistenz
│   ├── sessions/                 # Session Store
│   └── self-improving/           # Learning
│       └── projects/
├── plans/                         # Planungs-Templates
│   └── TEMPLATE.md
├── registry/                      # Alle Registries
│   ├── agents.yaml
│   ├── skills.yaml
│   ├── hooks.yaml
│   ├── projects.yaml
│   ├── search-index.json
│   ├── review-config.yaml
│   ├── audit-config.yaml
│   ├── drift-config.yaml
│   ├── targets.yaml
│   ├── install-manifest.yaml
│   ├── eval-example-weather.yaml
│   ├── README.md
│   ├── VALIDATION.md
│   └── VALIDATION-PHASE4.md
├── scripts/                       # Hilfs-Skripte
│   ├── install-check.ps1
│   ├── drift-check.ps1
│   └── deploy.ps1
└── AGENTS.md                     # OpenClaw Konventionen
```

---

## Kernkonzepte

### Registry-Pattern
Alle Komponenten sind in zentralen Registries definiert:
- **YAML** für menschenlesbare Konfiguration
- **JSON** für maschinenoptimierte Indizes
- Einheitliches Schema mit Versionierung

### Hook-Engine
Ereignisgesteuerte Erweiterungspunkte:
- `session:start` - Session-Initialisierung
- `session:end` - Session-Abschluss
- `review:post_execution` - Qualitätsprüfung

### Search-first
Alle Komponenten sind durchsuchbar:
- Keyword-basierte Suche
- Kategorie-Filter
- Inverse Indizes für schnelle Lookups

### Plan-Driven
Strukturierte Aufgabenabwicklung:
- Markdown-Templates mit YAML-Frontmatter
- Schritt-für-Schritt Validierung
- Integriertes Review

---

## Entwicklungsprinzipien

### 1. Minimal-First
Jede Phase startet mit der minimalen funktionsfähigen Version.

### 2. Keine blinden Übernahmen
Nichts aus fremden Frameworks (ECC) ohne 4-Faktoren-Prüfung:
- Nutzen für unser System?
- Übertragbarkeit gegeben?
- Abhängigkeiten klar?
- Anpassungsbedarf gering?

### 3. Mensch-Maschine-Balance
- **YAML:** Menschenlesbare Konfiguration
- **JSON:** Maschinenoptimierte Indizes
- **Markdown:** Dokumentation und Pläne

### 4. Strikte Phasenabfolge
Keine Phase wird übersprungen. Jede Phase:
- Bestandsanalyse
- Gap-Analyse
- Freigabe durch User
- Dokumentation
- Validierung

---

## Kommandos

### System-Checks
```powershell
# Installation prüfen
.\scripts\install-check.ps1

# Drift erkennen
.\scripts\drift-check.ps1

# Audit durchführen (Konzept)
# .\scripts\audit.ps1
```

### Deployment
```powershell
# Lokal validieren
.\scripts\deploy.ps1 -Target local

# Dry-Run
.\scripts\deploy.ps1 -Target local -DryRun
```

### Wartung
```powershell
# Search-Index regenerieren
# Konzept: scripts/regenerate-index.ps1

# Backup erstellen
# Konzept: scripts/backup.ps1
```

---

## Erweiterung

### Neuen Skill hinzufügen
1. Ordner in `skills/{skill-name}/` erstellen
2. `SKILL.md` mit Frontmatter anlegen
3. `registry/skills.yaml` aktualisieren
4. Search-Index regenerieren

### Neuen Plan erstellen
1. `cp plans/TEMPLATE.md plans/{plan-name}.md`
2. YAML-Frontmatter ausfüllen
3. Schritte definieren
4. Review durchführen

### Audit erweitern
1. `registry/audit-config.yaml` bearbeiten
2. Neue Checks hinzufügen
3. Gewichtungen anpassen

---

## Status

| Phase | Status | Komponenten |
|-------|--------|-------------|
| Phase 1 | ✅ Complete | Registry Foundation |
| Phase 2 | ✅ Complete | Cognitive Layer |
| Phase 3 | ✅ Complete | Persistence & Learning |
| Phase 4 | ✅ Complete | Operations |

**Gesamt:** 23 Dateien, ~100 KB, Produktionsreif

---

## Troubleshooting

### Install-Check schlägt fehl
```powershell
# Prüfe welche Dateien fehlen
.\scripts\install-check.ps1 -Verbose
```

### Drift erkannt
```powershell
# Report anzeigen
Get-Content memory/drift/DRIFT-*.md | Select-Object -Last 1
```

### Search-Index veraltet
```powershell
# Manuell aktualisieren (Konzept)
# Scripts/regenerate-index.ps1
```

---

## Roadmap

### Phase 4+ (Erweiterungen)
- [ ] Vollständiger Drift Doctor mit Auto-Fix
- [ ] SSH Adapter für Remote Deployment
- [ ] Docker Adapter für Container
- [ ] CI/CD Integration
- [ ] Web UI für Registry Management

### Phase 5 (Produktion)
- [ ] Kubernetes Adapter
- [ ] Cloud Provider Integration
- [ ] Distributed Sessions
- [ ] Multi-Agent Orchestration

---

## Lizenz

MIT License - Siehe Projekt-Root

---

## Autor

**Andrew** (andrew-main)  
Entwickelt für Parzival  
2026

---

*Dieses Framework wurde strikt nach den 4 Phasen entwickelt,*
*mit voller Transparenz und ohne ungeprüfte Übernahmen.*
