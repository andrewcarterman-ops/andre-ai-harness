# Paket 4: PII Scrubbing

## Zusammenfassung

Automatische Erkennung und Maskierung sensibler Daten vor dem Sync.

## Komponenten

### scrubber.js

**Erkannte Muster:**
| Typ | Muster | Schweregrad |
|-----|--------|-------------|
| OpenAI Key | `sk-...` (48 chars) | 🔴 Critical |
| Anthropic Key | `sk-ant-...` | 🔴 Critical |
| Generic API Key | 32-64 chars + Kontext | 🟠 High |
| Bearer Token | `Bearer ...` | 🔴 Critical |
| JWT Token | `eyJ...` | 🟠 High |
| SSH Private Key | `-----BEGIN...` | 🔴 Critical |
| PEM Key | `-----BEGIN PRIVATE...` | 🔴 Critical |
| Password | `password = "..."` | 🟠 High |
| DB Connection | `postgres://...` | 🟠 High |

**Funktionen:**
- `analyze()` - Findet sensitive Daten
- `scrub()` - Maskiert mit `***REDACTED***`
- `report()` - Erstellt Security-Report

**Verwendung:**
```bash
# Analysieren
node scrubber.js analyze memory/2026-04-08.md

# Maskieren (Vorschau)
node scrubber.js scrub memory/2026-04-08.md

# Maskieren (Speichern)
node scrubber.js scrub memory/2026-04-08.md --save
```

## Integration in Session-Sync

```javascript
// Vor dem Speichern
const scrubResult = scrub(noteContent);
if (scrubResult.totalMasked > 0) {
  console.log(`⚠️  ${scrubResult.totalMasked} sensitive Daten maskiert`);
  noteContent = scrubResult.scrubbed;
}
```

## Test-Ergebnis

```
Input: test-sensitive.md
→ 11 sensitive Daten gefunden
→ Alle maskiert
→ Backup erstellt

Gemaskte Typen:
  openai_key: 1
  generic_api_key: 5
  bearer_token: 1
  jwt_token: 1
  ssh_private_key: 1
  password_assignment: 1
  db_connection: 1
```

## Sicherheits-Workflow

```
Session-Text
     ↓
scrubber.analyze() → Report
     ↓
scrubber.scrub() → Maskierung
     ↓
Gespeichert im Vault
```

## Alle Pakete

| Paket | Status | Beschreibung |
|-------|--------|--------------|
| 1 | ✅ | Semantic Search (QMD-Ersatz) |
| 2 | ✅ | Smart Tagging & Wikilinks |
| 3 | ✅ | Session Sync + Auto-Sync |
| 4 | ✅ | PII Scrubbing |

## Gemerkte TODOs

- [ ] Vault-Archiv bereinigen (726 Duplikate)
- [ ] Index optimieren (Duplikate ausschließen)

## Dateien

```
search-engine/
├── indexer.js              # Paket 1: Indexierung
├── search.js               # Paket 1: Suche
├── tagger.js               # Paket 2: Smart Tagger
├── session-sync.js         # Paket 3: Session Export
├── auto-sync.js            # Paket 3: Auto-Sync
├── scrubber.js             # Paket 4: PII Scrubbing
├── vault-analyzer.js       # Analyse-Tool
├── sync.bat                # Windows Batch
├── index/                  # Such-Index
├── .sync-state.json        # Auto-Sync State
└── DOKUMENTATION.md        # Diese Datei
```
