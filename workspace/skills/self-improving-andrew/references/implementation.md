# Self-Improving Andrew - Implementation Guide

## Übersicht

Dies ist eine vereinfachte Version des Self-Improving-Agenten, speziell für Andrew (den AI-Assistenten) und Parzival (den Benutzer) entwickelt.

## Funktionen

### 1. Korrektur-Tracking

Wenn Parzival mich korrigiert, speichere ich das:

```python
from scripts.self_improving import SelfImprovingAndrew

si = SelfImprovingAndrew()
result = si.log_correction(
    "Bevorzugt Python statt JavaScript",
    context="Bei Code-Beispielen"
)
```

Nach 3x gleicher Korrektur → wird automatisch zu einer HOT Regel.

### 2. Präferenz-Speicherung

Explizite Präferenzen werden gespeichert:

```python
si.log_preference(
    "Mag kurze, direkte Antworten ohne Floskeln",
    category="communication"
)
```

### 3. Muster-Erkennung

Wiederkehrende Muster werden erkannt:

```python
si.log_pattern(
    "Fragt oft nach Zusammenfassungen",
    evidence="Letzte 5 Anfragen enthielten 3x 'fasse zusammen'"
)
```

## Datei-Struktur

```
memory/self-improving/
├── hot.md              # Aktive Regeln (immer im Kontext)
├── corrections.md      # Letzte 50 Korrekturen
├── preferences.md      # Kategorisierte Präferenzen
└── patterns.md         # Erkannte Muster (tentativ)
```

## Integration in Andrew

### Automatisches Lernen

In jeder Session prüfe ich:
1. Wurde ich korrigiert? → `log_correction()`
2. Hat der User eine Präferenz ausgedrückt? → `log_preference()`
3. Gibt es ein wiederkehrendes Muster? → `log_pattern()`

### Verwendung im Kontext

Bevor ich antworte, lade ich:
```python
hot_rules = si.get_hot_rules()
# Diese Regeln fließen in meine Antwort-Generierung ein
```

## CLI-Usage

```bash
# Korrektur speichern
python scripts/self_improving.py correction -t "Bevorzugt Python"

# Präferenz speichern
python scripts/self_improving.py preference -t "Mag kurze Antworten" -c communication

# Muster erkennen
python scripts/self_improving.py pattern -t "Fragt oft nach Code" --context="5/10 Anfragen"

# HOT Regeln anzeigen
python scripts/self_improving.py hot

# Letzte Korrekturen
python scripts/self_improving.py recent

# Alle Präferenzen
python scripts/self_improving.py prefs
```

## Erweiterungsmöglichkeiten

### 1. Embeddings für besseres Matching
Statt einfachem String-Matching könnten wir Embeddings nutzen, um ähnliche Korrekturen zu finden.

### 2. Self-Reflection Trigger
Automatische Reflexion nach großen Aufgaben:
- Hat es funktioniert?
- Was war gut/schlecht?
- Erkenntnis speichern

### 3. Proaktive Vorschläge
Wenn ein Muster stark wird (z.B. 5x "kürzer"), könnte ich fragen:
"Ich habe bemerkt, dass du oft kürzere Antworten möchtest. Soll ich das als Standard einstellen?"

### 4. Integration mit MEMORY.md
Regelmäßiges Review: Was in self-improving gelernt wurde, könnte in MEMORY.md überführt werden.

## Sicherheit

- Keine Credentials speichern
- Keine persönlichen Daten von Dritten
- Keine Gesundheits-/Finanzdaten
- Nur explizites Feedback verwenden (nicht aus Stille lernen)

## Unterschiede zum Original

| Feature | Original (ClawHub) | Diese Version |
|---------|-------------------|---------------|
| Komplexität | Hoch (3 Ebenen: HOT/WARM/COLD) | Einfach (1 Ebene + Korrekturen) |
| Setup | Erfordert setup.md | Auto-initialisierung |
| Proactivity | Integriert | Optional |
| Heartbeat | Eingebaut | Optional |
| Kompressions-Logik | Komplex | Einfach (nur HOT) |

Diese Version ist **Minimal Viable Product** — funktioniert, aber kann ausgebaut werden.
