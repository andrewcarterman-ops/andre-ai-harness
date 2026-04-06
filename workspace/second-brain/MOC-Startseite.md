# MOC: Modular Agent Framework + Second Brain

## 🗺️ Übersicht

Dies ist das **Second Brain** für das Modular Agent Framework - ein PARA-basiertes Wissensmanagement-System.

## 🧭 Navigation

### 📊 Dashboards
- [[00-Dashboard/Dashboard|Haupt-Dashboard]] - Übersicht aller Aktivitäten

### 📝 Sessions
- [[01-Sessions/|Alle Sessions]] - Chronologische Session-Historie
- Letzte: `=this.file.inlinks`

### 🎯 Entscheidungen
- [[02-Areas/Decisions/|Architektur-Entscheidungen]] - ADRs
- Offen: `=filter(this.file.inlinks, (f) => contains(f.path, "Decisions") and f.status = "Proposed")`

### 📁 Projekte
- [[02-Areas/Projects/|Aktive Projekte]] - Projekt-Übersicht

### 📚 Ressourcen
- [[03-Resources/CodeBlocks/|Code-Blöcke]] - Wiederverwendbarer Code
- [[03-Resources/Dataview/|Queries]] - Dataview-Abfragen

## 🔗 Framework-Integration

| Second Brain | Framework | Pfad |
|--------------|-----------|------|
| Sessions | Memory Logs | `../memory/` |
| Decisions | Registry ADRs | `../registry/` |
| Projects | Plans | `../plans/` |
| CodeBlocks | Extrahiert aus Sessions | `03-Resources/CodeBlocks/` |

## 🔄 Sync-Status

```dataviewjs
const lastSync = dv.pages("second-brain/01-Sessions").sort(p => p.file.mtime, 'desc')[0];
if (lastSync) {
    dv.paragraph("Letzter Sync: " + lastSync.file.mtime);
}
```

## 📈 Statistiken

| Metrik | Wert |
|--------|------|
| Sessions | `=length(this.file.inlinks)` |
| Entscheidungen | `=length(filter(this.file.inlinks, (f) => contains(f.path, "Decisions")))` |
| Projekte | `=length(filter(this.file.inlinks, (f) => contains(f.path, "Projects")))` |
| Code-Blöcke | `=length(filter(this.file.inlinks, (f) => contains(f.path, "CodeBlocks")))` |

## 🚀 Quick Actions

- [Neue Session starten](../memory/)
- [Sync durchführen](second-brain/scripts/sync-openclaw-to-secondbrain.ps1)
- [Dashboard öffnen](00-Dashboard/Dashboard.md)

---

*Dies ist Teil des [Modular Agent Frameworks](../README.md)*
