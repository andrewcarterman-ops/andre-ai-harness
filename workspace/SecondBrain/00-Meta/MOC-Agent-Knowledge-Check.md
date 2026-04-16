# SecondBrain Auto-Check Workflow

## Bei JEDER Benutzer-Anfrage:

### Schritt 1: Kontext prüfen (immer!)
```
BEFORE answering:
1. memory_search(query=user_question, maxResults=5)
2. Check SecondBrain/_MOC-*.md for relevant topics
3. Read SecondBrain/02-Projects/Active/ if projects mentioned
4. Check SecondBrain/03-Knowledge/ for existing knowledge
```

### Schritt 2: Anfrage kategorisieren

| Fragetyp | Wo prüfen |
|----------|-----------|
| "Was ist X?" | `03-Knowledge/Concepts/`, `03-Knowledge/References/` |
| "Wie mache ich Y?" | `03-Knowledge/How-To/` |
| "Was ist mit Projekt Z?" | `02-Projects/Active/`, `02-Projects/Completed/` |
| "Erinnerst du dich an...?" | `memory/YYYY-MM-DD.md`, `MEMORY.md` |
| "Haben wir...?" | `PROJECT-INDEX.md`, `registry/` |

### Schritt 3: Antwort-Strategie

**Fall A: Info existiert bereits**
- ✅ Zitieren: "Wir haben das am DD-MM-YYYY dokumentiert: [Zitat]"
- ✅ Verlinken: "Siehe `SecondBrain/.../datei.md`"
- ✅ Ergänzen nur wenn nötig

**Fall B: Info existiert nicht**
- ✅ "Dazu habe ich nichts in unserem SecondBrain gefunden"
- ✅ Dann neue Info erstellen & dokumentieren

**Fall C: Info ist veraltet/widersprüchlich**
- ✅ "Wir haben widersprüchliche Infos: [Quelle 1] vs [Quelle 2]"
- ✅ Klären: "Welche Version ist aktuell?"

---

## Wichtige MOCs (Maps of Content)

Vor jeder Antwort prüfen:
- `_MOC-Startseite.md` - Hauptnavigation
- `_MOC-Projects.md` - Aktuelle Projekte
- `_MOC-Knowledge.md` - Wissens-Übersicht

## Registry-Check

Wenn es um System/Konfiguration geht:
- `registry/agents.yaml` - Wer bin ich?
- `registry/skills.yaml` - Welche Skills haben wir?
- `registry/hooks.yaml` - Welche Automationen laufen?

---

## Anti-Patterns (DAS NICHT TUN!)

❌ "Ich denke..." ohne zu prüfen
❌ Neues Projekt anlegen ohne nach Existierendem zu suchen
❌ "Lass mich das bauen..." ohne zu fragen "Haben wir das schon?"
❌ Memory-Dateien ignorieren
❌ SecondBrain nur bei expliziter Anfrage nutzen

---

## Automatische Trigger

**Wenn User fragt nach:**
- "Was haben wir..." → memory_search + PROJECT-INDEX
- "Wie war..." → memory/YYYY-MM-DD.md lesen
- "Status von..." → 02-Projects/Active/ prüfen
- "Kannst du..." → Skills prüfen bevor "Ja" sagen

---

## Beispiel: Richtiger Workflow

**User:** "Was ist mit dem Voice Projekt?"

**FALSCH:**
> "Ich erstelle ein neues Projekt..."

**RICHTIG:**
> Lese: `memory/2026-04-14.md` + `SecondBrain/02-Projects/Active/`
> Antwort: "Wir haben das Voice Projekt am 14.04. dokumentiert. Status: [Zitat]. 
> Aktuell versuchen wir die OpenClaw Integration. Soll ich die Details zeigen?"

---

**Letzte Aktualisierung:** 16-04-2026
**Erstellt wegen:** Feedback von Parzival über inkonsistentes Wissen
