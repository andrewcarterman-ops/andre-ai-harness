---
date: 11-04-2026
type: task
status: todo
priority: critical
tags: [task, vault-migration, analysis, safety]
---

# Task: Vollständige Analyse Main_Obsidian_Vault

## Ziel

Analyse von `C:\Users\andre\.openclaw\workspace\vault-archive\Main_Obsidian_Vault` mit Vergleich zum aktuellen SecondBrain-Status.

**Kritisch:** Migration-Fehler aus der Vergangenheit vermeiden!

---

## Phase 1: Inventar erstellen (NUR LESEN)

### Schritt 1.1: Alle Dateien im Vault scannen
- Rekursiv alle `.md` Dateien auflisten
- Mit relativen Pfaden (Vault-Root als Basis)
- Mit Dateigrößen und Zeitstempeln
- Ohne Inhalt zu lesen (nur Metadaten)

### Schritt 1.2: Kategorisierung nach Dateityp
| Typ | Merkmale | Beispiel |
|-----|----------|----------|
| **Daily Note** | Format: DD-MM-YYYY.md oder YYYY-MM-DD.md | 10-04-2026.md |
| **Session** | Prefix: "Session-" oder "session-" | Session-2026-04-10.md |
| **Projekt** | Projekt-Titel, Status, Tasks | openclaw-renovation.md |
| **ADR** | Prefix: "ADR-" oder Ordner "Decisions/" | ADR-004.md |
| **Template** | Ordner "Templates/" oder "00-Meta/" | Daily.md |
| **MOC** | Prefix: "MOC-" oder "_MOC-" | _MOC-Startseite.md |
| **Sonstiges** | Alle anderen | README.md |

---

## Phase 2: Abgleich mit aktuellem SecondBrain

### Schritt 2.1: Existenz-Check
Für jede Datei im Vault prüfen:
1. Existiert sie im SecondBrain?
2. Gleicher Pfad oder verschoben?
3. Gleiche Dateigröße?

### Schritt 2.2: Status-Kategorien
| Status | Bedeutung | Aktion |
|--------|-----------|--------|
| **Vollständig migriert** | Datei existiert, Größe identisch | Keine Aktion |
| **Teilweise migriert** | Datei existiert, aber kleiner/leer | Re-Migration nötig |
| **Nicht migriert** | Datei fehlt komplett | Migration nötig |
| **Verschoben** | Datei existiert an anderem Ort | Prüfen ob korrekt |
| **Unbekannt** | Kann nicht zugeordnet werden | Manuelle Prüfung |

---

## Phase 2.5: Content-Analyse & Entscheidung (NEU)

### Schritt 2.5.1: Inhalts-Vergleich bei ähnlichen Dateien
Wenn Datei in beiden Orten existiert:

| Vergleich | Entscheidung |
|-----------|--------------|
| **Vault-Inhalt = SecondBrain-Inhalt** | Keine Aktion nötig |
| **Vault-Inhalt älter** | SecondBrain behalten |
| **Vault-Inhalt neuer** | **Fragen:** "Vault-Version übernehmen?" |
| **Vault mehr Inhalt** | Prüfen: "Neue Info relevant?" |
| **SecondBrain mehr Inhalt** | Prüfen: "Vault-Info fehlt?" |

### Schritt 2.5.2: Relevanz-Prüfung
Für jede Datei entscheiden:

**Brauchen wir es überhaupt?**
- [ ] **Ja** - Aktuell und relevant
- [ ] **Teilweise** - Nur bestimmte Abschnitte wichtig
- [ ] **Nein** - Veraltet/irrelevant → Archiv/99-Archive/
- [ ] **Unklar** → Dir vorlegen zur Entscheidung

### Schritt 2.5.3: Migrations-Strategie pro Datei
| Strategie | Wann anwenden | Beispiel |
|-----------|---------------|----------|
| **Komplett übernehmen** | SecondBrain-Version fehlt/leer | 02-04-2026.md |
| **Teilweise übertragen** | Beide haben relevante Infos | Zusammenführen nötig |
| **Ignorieren** | Veraltet, nicht mehr relevant | Alte Test-Dateien |
| **Nachfragen** | Unklar ob wichtig | Deine Entscheidung nötig |

### Schritt 2.5.4: Duplicate Detection
- Gleiche Themen in verschiedenen Dateien?
- Zusammenführen oder separat halten?
- Beispiel: "OpenClaw Setup" in 3 verschiedenen Sessions

---

## Phase 3: Safety-Maßnahmen (VOR Migration)

### Schritt 3.1: Backup-Strategie
```powershell
# Vor jeder Migration:
1. Backup-Ordner erstellen: 00-Meta/Backups/20260411-[Zeit]/
2. Zu migrierende Original-Dateien kopieren (als Backup)
3. SecondBrain-Status vor Migration dokumentieren
4. ERST dann migrieren
```

### Schritt 3.2: Validierungs-Checkliste
- [ ] Stichprobe: 3 zufällige Dateien vorher lesen
- [ ] Nach Migration: Diese 3 Dateien auf Vollständigkeit prüfen
- [ ] Keine Datei löschen vor Validierung!
- [ ] Nur markieren als "ready_for_deletion" nach GO

### Schritt 3.3: Inkrementelles Vorgehen
1. **NIE** alles auf einmal
2. Maximal 5 Dateien pro Batch
3. Nach jedem Batch: Pause + Validierung
4. Nächster Batch erst nach GO

---

## Phase 4: Dokumentation

### Ergebnis-Tabelle
| Datei (Vault) | Status | SecondBrain-Pfad | Content-Vergleich | Strategie | Priorität |
|---------------|--------|------------------|-------------------|-----------|-----------|
| 02-04-2026.md | Teilweise | 01-Daily/02-04-2026.md | Vault: 5KB, SB: 0.5KB | Komplett übernehmen | Hoch |
| ... | ... | ... | ... | ... | ... |

### Entscheidungs-Log
Für jede "Teilweise" oder "Unklar" Datei:
- Warum wurde so entschieden?
- Welche Inhalte wurden übernommen?
- Welche verworfen?

---

## Safety-Regeln (aus MEMORY.md)

| Regel | Umsetzung in dieser Task |
|-------|--------------------------|
| **8. Migrations-Validierung** | Stichprobe 3+ Dateien vor/nach Migration |
| **9. Backup vor Löschen** | Backup-Ordner Pflicht, keine Löschung vor Validierung |
| **10. Content-Check bei migrated** | Platzhalter = FEHLER, Inhalt muss vorhanden sein |
| **11. Dry-Run vor Migration** | Erst 1 Datei testen, dann GO, dann Rest |
| **12. Keine leeren Templates** | Nie Dateien mit "*Inhalt nicht migriert*" erstellen |

---

## Nächste Schritte

1. **Genehmigung einholen:** "Soll ich mit Phase 1 beginnen (nur lesen/analysieren)?"
2. **Ergebnis zeigen:** Inventar-Liste + Content-Vergleich vorlegen
3. **Entscheidungen abholen:** Für jede "Teilweise" oder "Unklar" Datei
4. **GO holen:** Für jede zu migrierende Datei einzeln
5. **Session-Speicherung klären:** Wohin mit den Sessions? (01-Sessions/ oder verteilt?)

---

**Erstellt:** 11-04-2026  
**Status:** Warte auf GO für Phase 1  
**Priorität:** Kritisch (Datenverlust-Risiko)
