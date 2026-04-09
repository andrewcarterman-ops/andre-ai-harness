---
session_id: "ECC-SKILL-202401-001"
date: "2024-01-15"
tokens_used: 0
agent_mode: "skill"
key_decisions: []
tags: ["skill", "markdown", "documentation", "writing"]
status: "active"
proficiency: 4
last_used: "2024-01-15"
---

# SKILL: Markdown

## Überblick

| Feld | Wert |
|------|------|
| **Kategorie** | tech |
| **Proficiency** | 4/5 |
| **Status** | active |
| **Last Used** | 2024-01-15 |

## Beschreibung

Markdown ist eine leichte Auszeichnungssprache zur Formatierung von Text. Sie wird für Dokumentation, Notizen, READMEs und viele andere Zwecke verwendet.

## Warum wichtig?

- Universell lesbar (Plain Text)
- Einfach zu schreiben
- Wird überall unterstützt
- Basis für Obsidian, GitHub, etc.

## Grundlagen

### Text-Formatierung

```markdown
# H1 Überschrift
## H2 Überschrift
### H3 Überschrift

**Fett** oder __Fett__
*Kursiv* oder _Kursiv_
~~Durchgestrichen~~

> Zitat

`Inline Code`
```

### Listen

```markdown
- Ungeordnete Liste
- Item 2
  - Nested Item

1. Geordnete Liste
2. Item 2
```

### Links & Bilder

```markdown
[Link Text](URL)
![Alt Text](Bild-URL)
```

### Tabellen

```markdown
| Spalte 1 | Spalte 2 |
|----------|----------|
| Wert 1   | Wert 2   |
```

## Fortgeschritten

### Code-Blöcke

````markdown
```python
def hello():
    print("Hello World")
```
````

### Task Lists

```markdown
- [x] Erledigt
- [ ] Offen
```

### YAML Frontmatter

```markdown
---
title: "Titel"
date: "2024-01-15"
tags: ["tag1", "tag2"]
---
```

## Ressourcen

### Lernmaterialien
- [Markdown Guide](https://www.markdownguide.org/)
- [GitHub Markdown](https://docs.github.com/en/get-started/writing-on-github)

### Tools
- Obsidian
- Typora
- VS Code

## Projekte mit diesem Skill

```dataview
LIST
FROM "01-Projects"
WHERE contains(tags, "markdown")
```

## Übungen & Challenges

- [x] ECC Framework Dokumentation
- [ ] Eigene Cheatsheet erstellen
- [ ] Markdown-Parser bauen

## Notizen

### 2024-01-15
- ECC Framework vollständig in Markdown dokumentiert

## Verknüpfungen

### Related Skills
- [[SKILL-Obsidian]]
- [[SKILL-Git]]

### Related Patterns
- [[PATTERN-Documentation-as-Code]]
- [[PATTERN-YAML-Frontmatter]]

### Related Snippets
- [[SNIPPET-Markdown-Table]]
- [[SNIPPET-YAML-Template]]

---
*Skill Created: 2024-01-15*
