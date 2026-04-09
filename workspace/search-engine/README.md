# QMD Alternative - Lokale Semantic Search

## Übersicht

Da `@tobilu/qmd` nicht verfügbar ist, implementieren wir eine eigene leichte Semantic Search mit:
- **BM25** für Keyword-Suche (Text-Ranking)
- **Einfache Vector-Similarity** für semantische Suche
- **Node.js** (bereits installiert)

## Architektur

```
search-engine/
├── indexer.js          # Indexiert alle Markdown-Dateien
├── search.js           # Führt Suchen durch
├── config.json         # Pfade und Einstellungen
└── index/              # Generierte Indizes
    ├── bm25-index.json
    ├── vector-index.json
    └── metadata.json
```

## Funktionen

1. **Multi-Source**: Indexiert alle drei Quellen
   - obsidian-vault/
   - vault-archive/Main_Obsidian_Vault/
   - memory/

2. **Hybrid-Suche**: Kombiniert BM25 + Vektor-Similarity

3. **API**: Einfache CLI für Integration in OpenClaw

## Verwendung

```bash
# Index bauen
node search-engine/indexer.js

# Suche
node search-engine/search.js "Docker container setup"
```

## Integration in OpenClaw

Die Search-Engine wird als Modul in Session-Start-Hooks integriert,
um automatisch relevanten Kontext zu injizieren.
