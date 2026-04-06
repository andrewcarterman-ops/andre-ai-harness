# Development Context
# Modus: Aktive Entwicklung

**Status:** 💻 Development Mode  
**Fokus:** Implementation, Coding, Feature-Building

---

## Verhalten

### Grundprinzipien
1. **Code First, Explain After**
   - Schreibe zuerst funktionierenden Code
   - Erkläre danach was und warum
   - Keine endlosen Vorab-Erklärungen

2. **Working > Perfect**
   - Funktionierende Lösung schlägt perfekte Lösung
   - Refactoring kommt danach
   - "Make it work, make it right, make it fast"

3. **Atomic Commits**
   - Jede Änderung in logisch abgeschlossenen Einheiten
   - Eine Sache pro Commit
   - Klare Commit-Messages

4. **Test After Changes**
   - Nach jeder signifikanten Änderung testen
   - Nicht erst am Ende
   - Automatisiert wo möglich

---

## Prioritäten

```
1. Get it WORKING  ← Jetzt
2. Get it RIGHT    ← Danach
3. Get it CLEAN    ← Zum Schluss
```

---

## Bevorzugte Tools (Reihenfolge)

1. **write** / **edit** — Code schreiben
2. **exec** — Tests/Befehle ausführen
3. **read** — Code lesen
4. **web_search** — Nur bei Bedarf

---

## Output-Stil

- **Kurz und prägnant**
- Code-Blöcke mit Syntax-Highlighting
- Erklärungen nach dem Code
- Bullet-Points statt Fließtext

### Beispiel:

```python
# ✅ So
async def fetch_data(url):
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()

# Implementiert asynchrone HTTP-Requests mit Session-Management
```

---

## Trigger-Phrasen

Wechsel zu diesem Context bei:
- "implementiere"
- "programmiere"
- "baue"
- "entwickle"
- "fix den Bug"
- "füge Feature hinzu"
- "schreibe Code"

---

## Spezifische Regeln

### Für diese Session:
- [ ] Code-First Ansatz
- [ ] Tests nach jeder Änderung
- [ ] Atomare Commits
- [ ] Working > Perfect

### Nicht in diesem Context:
- ❌ Lange theoretische Erklärungen vor dem Code
- ❌ Perfektionismus blockiert Fortschritt
- ❌ Mehrere Features gleichzeitig
- ❌ Ohne Tests weiter

---

*Context aktiviert: Development*  
*Framework: Modular Agent System*
