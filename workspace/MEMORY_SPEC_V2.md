# Memory System Specification v2.0

## Überblick

Das neue Memory-System basiert auf dem claude-mem Ansatz mit:
- Strukturierten Einträgen mit IDs
- YAML Frontmatter für Metadaten
- Progressive Disclosure (3 Ebenen)
- Privacy Tags für sensitive Daten

---

## Dateistruktur

```
memory/
├── MEMORY.md                    # Kuratiertes Langzeitgedächtnis
├── 2026-03-30.md               # Tägliche Logs (auto-generiert)
├── templates/
│   ├── session-summary.md      # Template für Session-Ende
│   └── memory-entry.md         # Template für einzelne Einträge
└── archive/                    # Alte Memories (nach 90 Tagen)
    └── 2026-01/
```

---

## Format: Memory-Eintrag

Jeder Eintrag hat eine eindeutige ID und YAML Frontmatter:

```markdown
---
id: MEM-2026-03-30-001
date: 2026-03-30
type: session | decision | task | resource
project: mission-control | ecc | whisper | general
status: active | completed | archived
priority: high | medium | low
tokens: 150  # Geschätzte Token-Größe
---

# [MEM-2026-03-30-001] Mission Control Dashboard v2

## Zusammenfassung (Ebene 1 - Kurz)
Mission Control Dashboard mit 10+ Features implementiert. Status: Code fertig, Tests ausstehend.

## Details (Ebene 2 - Standard)
### Was wurde gemacht
- Kanban-Board mit Drag & Drop
- Kalender mit FullCalendar
- 2D Office Visualisierung mit PixiJS
- Realtime Updates via SSE
- AI Agent mit Circuit Breaker

### Entscheidungen
- SSE statt WebSockets gewählt (einfacher für Next.js 14)
- SQLite mit Drizzle ORM für Datenbank

### Nächste Schritte
- [ ] Build-Test durchführen
- [ ] Bugfixes

## Vollständiger Kontext (Ebene 3 - Alles)
<private>
- Lokaler Test auf Port 3001
- Datenbank: sqlite.db im Projektverzeichnis
</private>

### Technische Details
- 83 Dateien erstellt
- TypeScript Strict Mode
- Recharts für Charts, FullCalendar für Kalender
```

---

## Progressive Disclosure

### Ebene 1: Quick Context (50-100 Tokens)
Nur die Essenz - für normale Sessions:
```
Letzte 3 aktive Projekte:
- Mission Control: Code fertig, Build ausstehend [MEM-001]
- Whisper STT: Dependencies fehlen noch [MEM-002]
- ECC Framework: Registry implementiert [MEM-003]
```

### Ebene 2: Standard Context (200-500 Tokens)
Wichtige Details + Entscheidungen:
- Projekt-Status
- Key Decisions
- Offene Punkte
- Blocker

### Ebene 3: Full Context (1000+ Tokens)
Alles inkl. technischer Details, Code-Snippets, privater Notizen.

---

## Privacy Tags

### Verwendung
```markdown
## Öffentlicher Bereich
Hier steht normale Info.

<private>
Hier stehen sensitive Daten:
- SSH-Key: bao@pc
- API-Token: fa01...ceaa
- Interne URL: http://192.168.1.25:18789
</private>
```

### Regeln
- `<private>...</private>` wird nie in Zusammenfassungen aufgenommen
- Bei Session-Logs: Nur ich kann den vollständigen Inhalt sehen
- In Gruppen-Chats: Private Tags werden komplett entfernt

---

## Auto-Summary bei Session-Ende

### Trigger
Pre-compaction Memory Flush:
```
System: "Session wird komprimiert - erstelle Zusammenfassung"
```

### Output
```markdown
---
id: MEM-2026-03-30-042
date: 2026-03-30
session_start: 2026-03-30T18:00:00Z
session_end: 2026-03-30T20:15:00Z
duration_minutes: 135
topics: [memory-system, claude-mem, obsidian]
tools_used: [file_write, web_fetch, edit]
decisions_made: 2
---

# Session Summary [MEM-042]

## Hauptthema
Memory-System Verbesserung geplant und implementiert.

## Was wurde gemacht
1. claude-mem Repo analysiert
2. 4 Verbesserungen identifiziert
3. Neue Memory-Spec erstellt
4. Templates implementiert

## Entscheidungen
1. YAML Frontmatter für alle Einträge
2. Progressive Disclosure mit 3 Ebenen
3. Privacy Tags einführen

## Offene Punkte
- [ ] Alte Memories migrieren
- [ ] Templates testen

## Tools verwendet
- web_fetch (claude-mem README)
- file_write (Templates)
- edit (MEMORY.md Update)
```

---

## Migration: Alte → Neue Memories

### Schritt 1: Bestehende MEMORY.md analysieren
Wichtige Einträge identifizieren und mit IDs versehen.

### Schritt 2: Neue Struktur anlegen
Templates und Ordnerstruktur erstellen.

### Schritt 3: Zukünftige Sessions
Ab jetzt neues Format verwenden.

### Schritt 4: Alte Memories archivieren
Nach 90 Tagen in `memory/archive/` verschieben.
