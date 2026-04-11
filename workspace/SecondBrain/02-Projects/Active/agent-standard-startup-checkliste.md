---
date: 10-04-2026
type: project
status: active
priority: medium
tags: [project, openclaw, agent, onboarding, startup]
---

# Projekt: Agent Standard-Startup Checkliste

## Zusammenfassung

Implementierung einer automatisierten Standard-Checkliste für neue Sessions, die sicherstellt, dass der Agent bei jedem Start den vollen Kontext hat.

## Ziele

- [x] Definiere die 5 Standard-Dateien für Session-Startup
- [ ] Dokumentiere Startup-Prozess für zukünftige Sessions
- [ ] Automatisiere (wo möglich) das Laden dieser Dateien
- [ ] Erstelle Template für neue Checklisten/Prozesse

## Status

| Phase | Status | Beschreibung |
|-------|--------|--------------|
| 1. Definition | ✅ | 5 Punkte identifiziert |
| 2. Dokumentation | ✅ | Checkliste erstellt |
| 3. Speicherort | 🔄 | Nach 02-Projects/ verschoben |
| 4. Automatisierung | ⏳ | Prüfen, was automatisierbar ist |

## Die 5 Standard-Punkte

### 1. SOUL.md lesen
- **Pfad:** `~/.openclaw/workspace/SOUL.md`
- **Zweck:** Persönlichkeit, Vibe, Work Ethic
- **Status:** ✅ Manuelles Lesen

### 2. USER.md lesen
- **Pfad:** `~/.openclaw/workspace/USER.md`
- **Zweck:** Wer ist mein Human
- **Status:** ✅ Manuelles Lesen

### 3. Memory-Files (täglich) lesen
- **Pfad:** `memory/DD-MM-YYYY.md` (Heute + Gestern)
- **Zweck:** Recent context
- **Status:** ✅ Manuelles Lesen

### 4. MEMORY.md lesen (nur Main Sessions!)
- **Pfad:** `~/.openclaw/workspace/MEMORY.md`
- **Zweck:** Long-term Memory
- **⚠️ Wichtig:** Nur in 1:1 Chats, nie in Gruppen!
- **Status:** ✅ Manuelles Lesen

### 5. registry/agents.yaml lesen
- **Pfad:** `~/.openclaw/workspace/registry/agents.yaml`
- **Zweck:** Meine Rolle & Capabilities
- **Status:** ✅ Manuelles Lesen

## Verwandte Dokumente

- [[SOUL]]
- [[USER]]
- [[MEMORY]]
- [[_MOC-Projects]]

## Lessons Learned

- **Kommunikation wichtig:** Beim Erstellen klären, ob etwas "Projekt" oder "Meta" ist
- **Parzival sieht systemische/organisatorische Dinge als Projekte an**
- **Nächstes Mal:** Explizit nach Projekt-Status fragen

## Nächste Schritte

1. [ ] MEMORY.md aktualisieren mit dieser Erkenntnis
2. [ ] Template für "Neue Aufgabe erstellen" dokumentieren
3. [ ] Prüfen: Kann der Startup automatisiert werden?

---

**Erstellt:** 10-04-2026  
**Letzte Aktualisierung:** 10-04-2026
