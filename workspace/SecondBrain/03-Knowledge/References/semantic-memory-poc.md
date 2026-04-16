# Semantic Memory PoC

**Zuletzt aktualisiert:** 14-04-2026
**Status:** Funktionsfähig
**Ort:** `SecondBrain/00-Meta/Scripts/semantic-memory-poc.py`

---

## Was macht es?

Indiziert alle Markdown-Dateien im SecondBrain Vault mit **FAISS + Sentence-Transformers** (`all-MiniLM-L6-v2`) und ermöglicht **semantische Suche** über den Vault.

## Technische Details

- **Embedding-Modell:** `sentence-transformers/all-MiniLM-L6-v2` (384 Dimensionen)
- **Index:** `faiss.IndexFlatIP` mit L2-Normalisierung (= Cosine Similarity)
- **Persistenz:** `SecondBrain/00-Meta/semantic-memory/`
- **Indexierte Dokumente:** 329 Markdown-Dateien

## Ausführung

```powershell
cd C:\Users\andre\.openclaw\workspace\SecondBrain
python 00-Meta/Scripts/semantic-memory-poc.py
```

## Test-Ergebnisse (14-04-2026)

| Query | Top-Ergebnis | Score |
|-------|-------------|-------|
| "edit tool workaround" | `edit-tool-workaround.md` | 0.346 |
| "rules for migrations" | `migration-best-practices.md` | 0.289 |
| "OpenClaw architecture" | `claw-code-masterplan.md` | 0.603 |

## Integration

Wird vom **Mini-Evolve-Loop** als erstes Target für automatische Verbesserungen genutzt.
