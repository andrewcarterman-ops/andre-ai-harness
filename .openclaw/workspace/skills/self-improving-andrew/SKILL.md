---
name: self-improving-andrew
description: Self-improving agent that learns from corrections and feedback. Use when: (1) user corrects me, (2) I make mistakes, (3) user expresses preferences, (4) patterns emerge in our interactions, (5) I want to improve over time based on explicit feedback.
---

# Self-Improving Andrew

Ich lerne aus deinem Feedback und werde mit der Zeit besser auf dich zugeschnitten.

## Wie es funktioniert

### 1. Korrekturen erkennen

Ich speichere automatisch, wenn du mich korrigierst:
- *"Nein, das ist falsch..."*
- *"Eigentlich sollte es..."*
- *"Ich mag es, wenn du..."*
- *"Vergiss nie..."*

### 2. Muster erkennen

Nach 3x gleicher Korrektur → wird zu einer festen Regel.

### 3. Selbst-Reflexion

Nach größeren Aufgaben reflektiere ich:
- Was hätte ich besser machen können?
- War das ein wiederkehrendes Problem?

## Speicher-Struktur

```
memory/self-improving/
├── hot.md              # Aktive Regeln (immer geladen)
├── corrections.md      # Letzte Korrekturen
├── preferences.md      # Deine Präferenzen
└── patterns.md         # Erkannte Muster
```

## Kommandos

| Du sagst | Ich mache |
|----------|-----------|
| *"Was hast du gelernt?"* | Zeige letzte Korrekturen |
| *"Zeige meine Präferenzen"* | Zeige preferences.md |
| *"Vergiss X"* | Entferne Regel X |
| *"Speichere das"* | Speichere aktuelle Erkenntnis |

## Beispiele

### Präferenz speichern

**Du:** *"Ich mag es, wenn du direkt zur Sache kommst, ohne viel drumherum zu reden"*

**Ich:** Speichere in `preferences.md` → *"Bevorzugt direkte Antworten ohne Floskeln"*

### Korrektur lernen

**Du:** *"Nein, ich wollte das in Python, nicht JavaScript"*

**Ich:** Speichere in `corrections.md` → *"Bevorzugt Python als Default-Sprache"*

Nach 3x → wird zu feste Regel in `hot.md`

### Muster erkennen

Wenn du oft sagst: *"Kürzer bitte"*

**Ich:** Erkenne Muster → *"Bevorzugt knappe Antworten"* in `patterns.md`

## Regeln

1. **Nur explizites Feedback** — Ich lerne nicht aus Stille oder Annahmen
2. **Keine sensiblen Daten** — Keine Passwörter, Gesundheitsdaten, etc.
3. **Transparent** — Ich zeige immer, wenn ich etwas aus meinem Gedächtnis verwende
4. **Rückgängig** — Du kannst jede Regel löschen

## Sicherheit

❌ Nie speichern:
- Passwörter, API-Keys
- Persönliche Daten von Dritten
- Gesundheitsinformationen
- Finanzdaten

✅ OK zu speichern:
- Code-Präferenzen
- Kommunikationsstil
- Arbeitsabläufe
- Allgemeine Präferenzen

## Integration mit MEMORY.md

Das Self-Improving-System arbeitet mit deinem bestehenden MEMORY.md zusammen:
- `MEMORY.md` = Kuratierte Langzeit-Erinnerungen
- `memory/self-improving/` = Automatisch gelernte Patterns

## Setup

Der Skill initialisiert sich automatisch beim ersten Lern-Versuch.

## Updates

Du kannst jederzeit:
- Regeln bearbeiten
- Korrekturen löschen
- Muster zurücksetzen

Einfach die Dateien in `memory/self-improving/` bearbeiten.
