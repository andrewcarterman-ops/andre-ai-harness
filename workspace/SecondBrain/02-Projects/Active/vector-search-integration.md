---
date: 11-04-2026
type: task
status: todo
priority: medium
tags: [task, vector-search, obsidian, ai, second-brain]
related-projects: [openclaw-renovation, night-agent]
---

# TODO: Vector Search Integration für SecondBrain

## Ziel
Semantische Suche im Obsidian Vault implementieren, um Inhalte nach Bedeutung (nicht nur Keywords) zu finden.

## Nutzen
- Natürlichsprachige Suche: "Wie mache ich Safety?" findet Permissions, Fort Knox, Risk Analysis
- Automatische Verwandte-Notizen-Vorschläge
- Bessere Auffindbarkeit der 6 claw-code SPECs
- Vernetzung von Konzepten ohne manuelle WikiLinks

## Optionen zu evaluieren

### Option 1: Smart Connections (Empfohlen)
- **Beschreibung**: Obsidian Plugin mit KI-Embeddings
- **Vorteile**: Einfache Installation, hohe Qualität, automatische Verwandte-Notizen
- **Nachteile**: Benötigt API-Key (OpenAI) oder lokale GPU
- **Kosten**: Ggf. API-Kosten für Embeddings
- **Privacy**: Daten gehen an API (wenn nicht lokal)

### Option 2: Obsidian Semantic Search
- **Beschreibung**: Einfacheres semantisches Suche-Plugin
- **Vorteile**: Keine externe API nötig, datenschutzfreundlicher
- **Nachteile**: Weniger leistungsstark als Smart Connections
- **Kosten**: Kostenlos
- **Privacy**: 100% lokal

### Option 3: Self-hosted (Ollama)
- **Beschreibung**: Lokales LLM (z.B. Llama 3) macht Embeddings
- **Vorteile**: 100% privat, keine Kosten, volle Kontrolle
- **Nachteile**: Hoher Setup-Aufwand, braucht RAM/CPU, langsamer
- **Kosten**: Strom/Hardware
- **Privacy**: 100% lokal

## Anforderungen
- [ ] Plugin-Recherche durchführen
- [ ] Test mit aktuellem Vault (10-20 Dateien)
- [ ] Vergleich: Keyword-Suche vs. Vector-Suche
- [ ] Entscheidung: Welche Option passt zu unserem Setup?
- [ ] Installation und Konfiguration
- [ ] Integration mit bestehendem Tag-System

## Offene Fragen
- Akzeptieren wir API-Nutzung (Smart Connections) oder strikt lokal (Ollama)?
- Wie performant ist es mit 1000+ Dateien?
- Können wir eigene Embeddings-Modelle nutzen (z.B. für Deutsch)?

## Next Steps
1. Smart Connections Plugin testen (wenn API-Key OK)
2. Alternativ: Obsidian Semantic Search testen
3. Dokumentation der Ergebnisse
4. Entscheidung mit Parzival besprechen

## Links
- [[openclaw-renovation|OpenClaw Renovierung]] (könnte davon profitieren)
- [[_MOC-Knowledge|Knowledge MOC]] (bessere Verknüpfungen)
- Quelle: Diskussion über claw-code SPECs Auffindbarkeit

---
**Erstellt**: 11-04-2026  
**Letzte Aktualisierung**: 11-04-2026  
**Status**: Warte auf GO für Recherche
