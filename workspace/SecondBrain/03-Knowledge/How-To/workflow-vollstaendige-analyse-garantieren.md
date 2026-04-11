---
date: 10-04-2026
type: knowledge
category: how-to
tags: [how-to, workflow, analysis, checklist, quality-assurance]
---

# Workflow: Vollstaendige Analyse garantieren

> Wie ich sicherstelle, dass wirklich ALLES analysiert wird, wenn Parzival sagt "analysiere alles"

---

## Das Problem (10-04-2026)

Bei der Analyse des ECC-SecondBrain-Frameworks:
- Anweisung: "analysiere, was wir noch nicht bewertet haben"
- Ergebnis: Inbox-Ordner nicht vollstaendig analysiert
- Folge: Critical-Bug-Doku (edit-tool) uebersehen
- Konsequenz: Wir haben einen bekannten Bug "neu" entdeckt

---

## Die Loesung: Systematischer Analyse-Prozess

### Phase 1: Inventarisierung (VOR der Analyse)

```powershell
# Schritt 1: Alle Dateien zaehlen
$totalFiles = (Get-ChildItem -Path $zielOrdner -Recurse -File).Count
Write-Host "Gesamt zu analysieren: $totalFiles Dateien"

# Schritt 2: Alle Ordner auflisten
$directories = Get-ChildItem -Path $zielOrdner -Directory | Select-Object Name
Write-Host "Ordner: $($directories.Name -join ', ')"
```

**Wichtig:** Diese Zahlen NIEDERSCHREIBEN!

---

### Phase 2: Kategorisierung

Jeden Ordner einzeln durchgehen:

| Ordner | Status | Anzahl Dateien | Prioritaet |
|--------|--------|----------------|------------|
| 00-Dashboard | ⬜ | ... | Hoch |
| 00-Inbox | ⬜ | ... | Hoch |
| 01-Projects | ⬜ | ... | Mittel |
| ... | ... | ... | ... |

**Regel:** Keinen Ordner ueberspringen, auch wenn er "unwichtig" aussieht!

---

### Phase 3: Datei-fuer-Datei Analyse

Fuer JEDE Datei:
1. [ ] Name notieren
2. [ ] Kurzbeschreibung erstellen
3. [ ] Bewertung: Relevant? Ja/Nein/Teilweise
4. [ ] Entscheidung: Migrieren/Uebernehmen/Ignorieren

**Mindestens 3 Saetze pro Datei!**

---

### Phase 4: Verifizierung (NACH der Analyse)

```powershell
# Schritt 1: Analysierte Dateien zaehlen
$analysedFiles = @(
    "Datei1.md",
    "Datei2.md",
    ...
)

# Schritt 2: Abgleich
$totalFiles = 50  # Aus Phase 1
$analysedCount = $analysedFiles.Count

if ($analysedCount -lt $totalFiles) {
    Write-ERROR "NUR $analysedCount von $totalFiles Dateien analysiert!"
    exit 1
}
```

---

### Phase 5: Explizite Bestaetigung

VOR dem Abschluss anzeigen:

```
=== ANALYSE-PROTOKOLL ===
Gesamt Dateien: 50
Analysiert:     50
Uebernommen:    15
Ignoriert:      35

Offene Punkte:
- [ ] Inbox/Datei1.md
- [ ] Projects/Datei2.md

Soll ich die offenen Punkte analysieren?
[Ja] [Nein, bewusst ueberspringen]
```

---

## Qualitaets-Checkliste

Vor dem "Fertig":

- [ ] Alle Ordner durchgegangen?
- [ ] Alle Dateien erfasst?
- [ ] Zahlen stimmen (Gesamt = Analysiert + Ignoriert)?
- [ ] Mindestens eine Datei pro Ordner angesehen?
- [ ] README-Dateien gelesen?
- [ ] Templates geprueft?
- [ ] Versteckte/unscheinbare Dateien nicht vergessen?

---

## Fehler-Prevention

### Verboten:
- ❌ "Das sieht nach Altlast aus, ueberspringe"
- ❌ "Nur die ersten 10 Dateien anschauen"
- ❌ "Nur Ueberschriften lesen"
- ❌ Schaetzen statt Zaehlen

### Erforderlich:
- ✅ Jeden Ordner oeffnen
- ✅ Jede Datei mindestens kurz oeffnen
- ✅ Zahlen dokumentieren
- ✅ Protokoll erstellen
- ✅ Explizites GO einholen

---

## Beispiel: Korrekte Analyse

**Anweisung:** "Analysiere den Ordner X"

**Meine Antwort:**
```
Inventarisierung:
- Gesamt: 47 Dateien in 8 Ordnern

Kategorisierung:
- 00-Inbox: 3 Dateien (inkl. Critical-Bug-Doku)
- 01-Projects: 5 Dateien
- ...

Analyse-Ergebnis:
- Relevant: 12 Dateien
- Bereits migriert: 8 Dateien
- Neu entdeckt: 4 Dateien

Empfehlung:
1. Critical-Bug-Doku uebernehmen (hochprioritaet)
2. Project-Doku archivieren
3. Rest ignorieren

GO?
```

---

## Merksatz

> **"Analysiere alles" = 100% der Dateien, nicht 80%, nicht 99%.**

Lieber langsamer und vollstaendig, als schnell und unvollstaendig.

---

Letzte Aktualisierung: 10-04-2026  
Kontext: Critical-Bug-Doku in Inbox uebersehen
