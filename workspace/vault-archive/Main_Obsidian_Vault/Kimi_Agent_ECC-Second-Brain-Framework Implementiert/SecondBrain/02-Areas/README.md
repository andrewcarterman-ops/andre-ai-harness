---
tags:
  - areas
  - index
  - para
---

# 02 - Areas 🎯

> **Areas of Responsibility** - Langfristige Verantwortungsbereiche

---

## Definition

Ein Bereich (Area) ist:
- Ein **Verantwortungsbereich** ohne Deadline
- **Langfristig** relevant
- Erfordert **kontinuierliche Pflege**

---

## Meine Bereiche

```dataview
TABLE status, priority, lastReviewed
FROM "02-Areas"
WHERE file.name != "README"
SORT priority DESC
```

---

## Bereiche nach Kategorie

### 🧠 Entwicklung
```dataview
LIST
FROM "02-Areas"
WHERE category = "development"
```

### 🔬 Forschung
```dataview
LIST
FROM "02-Areas"
WHERE category = "research"
```

### 📝 Dokumentation
```dataview
LIST
FROM "02-Areas"
WHERE category = "documentation"
```

### ⚙️ Operations
```dataview
LIST
FROM "02-Areas"
WHERE category = "operations"
```

---

## Review Schedule

| Bereich | Letztes Review | Nächstes Review |
|---------|----------------|-----------------|
| | | |

---

## Templates

- [[template-area|Bereich-Template]]

---

*PARA Method - ECC Second Brain Framework*
