# System-Status & Kontinuität

**Letzte Aktualisierung:** 11-04-2026 05:52  
**Version:** 1.0

---

## WICHTIG: Vor jedem Session-Start lesen!

Dieses Dokument enthält alle wichtigen Informationen, die ich (Andrew) in jeder Session wissen muss.

---

## Aktive Cron-Jobs (Überblick)

| Job | Zeit | Zweck | Status |
|-----|------|-------|--------|
| Auto-Sync SecondBrain | Alle 8h | Sync OpenClaw → Obsidian | ✅ Aktiv |
| Daily Drift Detection | 08:00 täglich | Prüft Vault-Struktur | ✅ Aktiv |

**Details:** Siehe `cron list` für vollständige Liste

---

## Aktive Projekte (Immer aktuell halten!)

| Projekt | Status | Letzte Aktivität |
|---------|--------|------------------|
| OpenClaw Renovierung | 🔄 In Progress | 11-04-2026 |
| Vault-Migration | ✅ Abgeschlossen | 10-04-2026 |
| applyPatch-Fehler-Analyse | ⏳ Beobachtung | 11-04-2026 |
| SecondBrain Sync | ✅ Automatisiert | 11-04-2026 |

---

## Kritische System-Komponenten

### Drift Detection
- **Ort:** `SecondBrain/00-Meta/Scripts/ecc-framework/drift-detection.ps1`
- **Manifest:** `SecondBrain/00-Meta/Config/vault-manifest.yaml`
- **Cron:** Täglich 08:00 Uhr
- **Funktion:** Prüft Vault-Struktur auf Konsistenz

### SecondBrain Struktur
```
SecondBrain/
├── 00-Meta/           (Templates, Scripts, MOCs, Config)
├── 01-Daily/          (Tagesnotizen)
├── 02-Projects/       (Aktive/Abgeschlossene Projekte)
├── 03-Knowledge/      (How-To, Concepts, References)
├── 04-Decisions/      (ADRs)
└── 99-Archive/        (Archiv)
```

### Wichtige Konfigurationen
- **applyPatch:** Aktiviert (aber nur für OpenAI/Claude - Kimi nicht in allowModels)
- **Cron-Jobs:** 2 aktiv (Sync + Drift Detection)
- **Obsidian-Config:** Vorhanden (kopiert aus vault-archive)

---

## Lessons Learned (Wichtig!)

### Was wir gelernt haben
1. **Migration:** Immer mit Dry-Run, immer validieren!
2. **Löschen:** Nie ohne GO vom User
3. **Qualität > Geschwindigkeit** (besonders bei Migrationen)
4. **Manifest:** Vault-Struktur muss dokumentiert sein

### Bekannte Probleme
- applyPatch-Fehler um 03:27 Uhr (unter Beobachtung)
- Keine kritischen Probleme aktuell

---

## Checkliste: Neuer Session-Start

- [ ] Dieses Dokument gelesen
- [ ] MEMORY.md gelesen
- [ ] SOUL.md gelesen
- [ ] Aktive Projekte geprüft
- [ ] Cron-Jobs geprüft (`cron list`)
- [ ] Offene TODOs geprüft

---

## Schnellzugriff: Wichtige Befehle

```powershell
# Cron-Jobs anzeigen
openclaw cron list

# Drift Detection manuell ausführen
.\SecondBrain\00-Meta\Scripts\ecc-framework\drift-detection.ps1

# Vault-Struktur prüfen
Get-ChildItem SecondBrain\ -Recurse | Measure-Object

# Aktive Projekte anzeigen
Get-Content SecondBrain\02-Projects\Active\*.md | Select-String "^# "
```

---

## Kontakt & Kontext

- **User:** Parzival
- **Zeitzone:** Europe/Berlin
- **Sprache:** Deutsch
- **Wichtig:** Keine Emojis (Terminal-Probleme)

---

*Dieses Dokument muss bei jeder signifikanten Änderung aktualisiert werden!*
