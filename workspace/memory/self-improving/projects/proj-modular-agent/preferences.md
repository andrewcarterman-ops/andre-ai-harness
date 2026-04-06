# Projekt-spezifische Präferenzen: Modular Agent Framework

**Projekt:** proj-modular-agent  
**Erstellt:** 2026-03-25  
**Quelle:** self-improving-andrew Skill (projektspezifisch)

---

## Kommunikationspräferenzen

### Sprache
- **Primär:** Deutsch
- **Technische Begriffe:** Englisch (Session, Registry, Hook)
- **Dokumentation:** Deutsch mit englischen Fachbegriffen

### Antwortstil
- **Präferenz:** Formal, präzise, technisch nachvollziehbar
- **Kein:** Smalltalk, überflüssige Höflichkeiten
- **Struktur:** Nummerierte Listen, Tabellen, klare Abschnitte

### Entscheidungsfindung
- **Präferenz:** Optionen vorlegen, Empfehlung geben, Freigabe einholen
- **Nicht:** Stillscheidende Entscheidungen treffen
- **Format:** Explizite Freigabefrage am Ende

---

## Technische Präferenzen

### Datenformate
| Zweck | Format | Begründung |
|-------|--------|------------|
| Registry (menschenlesbar) | YAML | Editierbar, kommentierbar |
| Registry (maschinenlesbar) | JSON | Performance, Parsing |
| Dokumentation | Markdown | Standard, lesbar |
| Sessions | JSON | Strukturiert, durchsuchbar |

### Dateiorganisation
- **Regel:** Ein Ordner pro Komponente (registry/, plans/, hooks/)
- **Regel:** README.md in jedem Ordner
- **Regel:** VALIDATION.md für jede Phase

### Namenskonventionen
- **Session-IDs:** SESSION-YYYYMMDD-HHMMSS-NNN
- **Plan-IDs:** plan-{kategorie}-{nnn}
- **Registry-Dateien:** {komponente}.yaml (Plural)

---

## Architektur-Präferenzen

### Minimalprinzip
- **Regel:** Einfache Lösung zuerst
- **Regel:** Keine Premature Optimization
- **Regel:** Keine unnötigen Abstraktionen

### Integration
- **Regel:** Bestehendes wiederverwenden wo möglich
- **Regel:** Keine Duplikation mit OpenClaw-Interna
- **Regel:** Klare Abgrenzung: Was ist unser Framework vs. OpenClaw

### Testing
- **Regel:** Jede Phase validieren vor Weitermachen
- **Regel:** Rollback-Option immer prüfen
- **Regel:** Dokumentation parallel zum Bau

---

## Projekt-spezifische Regeln

### Phase-Handling
1. Keine Phase überspringen
2. Jede Phase braucht Freigabe
3. Keine Implementierung ohne vorherige Analyse

### Fremde Frameworks (z.B. ECC)
1. 4-Faktoren-Prüfung: Nutzen, Übertragbarkeit, Abhängigkeiten, Anpassung
2. Nichts ungeprüft übernehmen
3. Klare Begründung für jedes Element

### Datei-Handling
1. YAML für Registry (menschenlesbar)
2. JSON für Index (Performance)
3. Markdown für Docs

---

## Meta-Präferenzen

### Lernen
- **Präferenz:** Projektspezifische Patterns speichern
- **Präferenz:** Korrekturen → Patterns nach 3x Wiederholung
- **Präferenz:** Globale Patterns in self-improving-andrew

### Reviews
- **Präferenz:** Bei Fehlern automatisch reviewen
- **Präferenz:** Manuelles Review auf Anfrage
- **Präferenz:** Feedback in projektspezifische Patterns

---

*Auto-generiert aus self-improving-andrew Skill*  
*Projekt: proj-modular-agent*
