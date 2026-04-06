# Projekt-spezifische Patterns: Modular Agent Framework

**Projekt:** proj-modular-agent  
**Erstellt:** 2026-03-25  
**Quelle:** self-improving-andrew Skill (projektspezifisch)

---

## Erkannte Patterns

### Pattern 1: Strikte Phasenabfolge
**Kontext:** Architektur-Entscheidungen  
**Pattern:** User bevorzugt strikte, nicht überspringbare Phasen mit voller Transparenz  
**Beispiel:** Phase 1 → Phase 2 → Phase 3 (kein Skippen)  
**Konsequenz:** Jede Phase braucht Freigabe, Bestandsanalyse, Gap-Analyse

### Pattern 2: YAML für Menschen, JSON für Maschinen
**Kontext:** Datenformate in Registry  
**Pattern:** Menschenlesbare Dateien (YAML), maschinenoptimierte (JSON)  
**Anwendung:** Registry = YAML, Search-Index = JSON  
**Konsequenz:** Klare Trennung, beide Formate vorhanden

### Pattern 3: Keine blinden Übernahmen
**Kontext:** Fremde Frameworks (ECC)  
**Pattern:** Nichts ungeprüft übernehmen, immer 4-Faktoren-Prüfung  
**Faktoren:** Nutzen, Übertragbarkeit, Abhängigkeiten, Anpassungsbedarf  
**Konsequenz:** Jedes Element bewusst entschieden

### Pattern 4: Minimal-First
**Kontext:** Implementierungsansatz  
**Pattern:** Minimalversion zuerst, dann erweitern  
**Beispiel:** Session Store = einfache JSON-Dateien, nicht SQLite  
**Konsequenz:** Einfacher Start, erweiterbar

---

## Korrekturen → Patterns

| Datum | Korrektur | Wurde zu Pattern |
|-------|-----------|------------------|
| 2026-03-25 | "Keine Claude-Code-Muster ungeprüft" | Strikte Validierungsregeln |
| 2026-03-25 | "YAML vs JSON Entscheidung" | Hybrid-Format Strategie |
| 2026-03-25 | "Phasen nicht überspringen" | Strikte Phasenabfolge |

---

## Häufige Fehler (projektspezifisch)

1. **Fehler:** Zu schnell implementieren ohne Analyse  
   **Lösung:** Immer Bestandsanalyse zuerst

2. **Fehler:** Registry-Dateien unvollständig  
   **Lösung:** Validierungs-Checkliste verwenden

3. **Fehler:** Komplexität zu früh einführen  
   **Lösung:** Minimalprinzip beachten

---

*Auto-generiert aus self-improving-andrew Skill*  
*Projekt: proj-modular-agent*
