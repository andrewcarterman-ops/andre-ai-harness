---
tags:
  - resources
  - index
  - para
---

# 03 - Resources 📚

> **Reusable Knowledge** - Wiederverwendbare Ressourcen

---

## Definition

Ressourcen sind:
- **Wiederverwendbares** Wissen
- **Referenzmaterial** für Projekte
- **Keine** unmittelbare Aktion erforderlich

---

## Struktur

### 🛠️ Skills
Fähigkeiten und Kompetenzen
- [[Skills/SKILL-Template|Skill-Template]]
- [[Skills/SKILL-Markdown|Markdown]]

### 📐 Patterns
Code-Patterns und Best Practices
- [[Patterns/PATTERN-Template|Pattern-Template]]
- [[Patterns/PATTERN-YAML-Frontmatter|YAML Frontmatter]]

### 💻 Snippets
Code-Snippets und Templates
- [[Snippets/SNIPPET-Template|Snippet-Template]]
- [[Snippets/SNIPPET-YAML-Template|YAML Template]]

---

## Index

```dataview
TABLE file.tags as Tags, file.mtime as "Modified"
FROM "03-Resources"
WHERE file.name != "README"
SORT file.name ASC
```

---

## Code Block Index

```dataview
LIST
FROM "03-Resources"
WHERE file.content contains "```"
```

---

*PARA Method - ECC Second Brain Framework*
