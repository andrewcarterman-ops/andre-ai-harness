# Knowledge Curator Workflow

## Wie die Agents dein Second Brain analysieren

### 1. Automatische Analyse (per Command)
```powershell
# Einfache Analyse
.\second-brain\scripts\analyze-vault.ps1

# Detaillierte Analyse
.\second-brain\scripts\analyze-vault.ps1 -Detailed

# Mit automatischen Entscheidungen
.\second-brain\scripts\analyze-vault.ps1 -AutoDecide
```

### 2. Was analysiert wird

#### Verbindungen (Connections)
- **Backlinks:** Wer verlinkt auf diese Notiz?
- **Ausgehende Links:** Wohin zeigt diese Notiz?
- **Hub Notes:** Zentrale Knotenpunkte mit vielen Verbindungen
- **Cluster:** Verbundene Inseln von Wissen

#### Orphans (Verwaiste Notizen)
- Notizen mit 0 Backlinks
- Nicht in MOCs verlinkt
- Keine Tags
- Leer oder fast leer

#### Qualitätsbewertung
Jede Notiz bekommt einen Score:
- **+3:** Hohe Konnektivität (5+ Backlinks)
- **+2:** Decision/ADR
- **+1:** Session Log
- **+1:** Umfangreicher Inhalt (>2000 Zeichen)

#### Broken Links
- Links die ins Leere zeigen
- Fehlende Ziel-Notizen
- Tote Verbindungen

### 3. Empfehlungen

| Empfehlung | Bedeutung | Aktion |
|------------|-----------|--------|
| **KEEP** | Wichtiges Wissen | Behalten, ggf. verbessern |
| **ARCHIVE** | Weniger relevant | In 04-Archive verschieben |
| **DELETE** | Überflüssig/Alt | Löschen (wird gelistet) |
| **REVIEW** | Unklar | Manuell prüfen |

### 4. Nutzung mit Agenten

#### Der Knowledge Curator kann:
1. **Vault analysieren** - Komplette Übersicht erstellen
2. **Verbindungen erkennen** - Hidden Links finden
3. **Orphans identifizieren** - Verwaiste Notizen finden
4. **Bewertungen geben** - Keep/Archive/Delete empfehlen
5. **Struktur optimieren** - Verbesserungsvorschläge machen

#### Beispiel-Workflow:
```
User: "Analysiere mein Second Brain"
→ Knowledge Curator aktiviert
→ Script läuft: analyze-vault.ps1
→ Report wird generiert
→ Empfehlungen werden präsentiert

User: "Zeige mir die orphans"
→ Curator zeigt verwaiste Notizen
→ Bewertet jeden: Löschen/Archivieren/Verbinden

User: "Verbinde lose Notizen"
→ Curator schlägt Links vor
→ Erstellt Verbindungen zu MOCs
```

### 5. Regelmäßige Analyse

#### Per Heartbeat (automatisch)
```yaml
# In HEARTBEAT.md ergänzen:
tasks:
  - name: "Weekly Knowledge Audit"
    schedule: "weekly"
    day: "sunday"
    time: "11:00"
    action: "analyze-vault"
    condition: "vault_size_increased"
    notify_only_on_orphans: true
```

#### Per Hook (nach großen Sessions)
```yaml
# In hooks.yaml:
session:end:
  post_actions:
    - name: "analyze-if-large"
      command: "analyze-vault"
      condition: "session.added_notes > 5"
```

### 6. Output-Format

Die Analyse erzeugt einen JSON-Report:
```json
{
  "timestamp": "2026-03-26T01:15:00Z",
  "total_notes": 42,
  "connected_notes": 35,
  "orphaned_notes": 7,
  "broken_links": 2,
  "hubs": [...],
  "orphans": [...],
  "recommendations": {
    "delete": [...],
    "archive": [...],
    "review": [...]
  }
}
```

### 7. Integration mit Obsidian

Das JSON-Report kann in Obsidian angezeigt werden:
- Dataview-Query für Hubs
- Dataview-Query für Orphans
- Dashboard-Integration

---

**Der Knowledge Curator sorgt dafür, dass dein Second Brain nicht zur Datengrab wird!**
