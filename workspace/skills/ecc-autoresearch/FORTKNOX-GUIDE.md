# 🏰 Autoresearch Fort Knox - Die Komplettlösung

> **"Ein Schloss aus Stahl für deine KI-Forschung"**

Diese Anleitung zeigt dir, wie du **autoresearch über Nacht laufen lassen kannst** - mit maximaler Sicherheit und minimalem Risiko.

---

## 🎯 Was du bekommst

| Feature | Beschreibung | Risiko-Reduktion |
|---------|-------------|------------------|
| **Isolierter User** | Dedizierter Windows-Account | 🔴→🟡 |
| **Network Firewall** | Nur HuggingFace erlaubt | 🔴→🟢 |
| **Filesystem Sandbox** | Kein Zugriff auf deine Daten | 🔴→🟢 |
| **Safety-Checker** | Code wird vorher geprüft | 🔴→🟢 |
| **Runtime Guardian** | Überwacht während der Laufzeit | 🟡→🟢 |
| **Discord Alerts** | Sofort-Benachrichtigung bei Problemen | 🟡→🟢 |
| **Auto-Backup** | Vorher + während des Experiments | 🟢→🟢 |

**Gesamt-Risiko:** 🔴 **KRITISCH** → 🟢 **NIEDRIG**

---

## 🚀 Schnellstart (3 Schritte)

### Schritt 1: Einmalig Setup (10 Minuten)

```powershell
# Als Administrator ausführen!
Set-Location "~\.openclaw\workspace\skills\ecc-autoresearch"
.\FortKnox-Autoresearch.ps1 -Action setup
```

**Das passiert:**
- ✅ Erstellt isolierten User "autoresearch"
- ✅ Konfiguriert Windows Firewall
- ✅ Setzt Berechtigungen
- ✅ Installiert Tools

**Wichtig:** Notiere das generierte Passwort!

---

### Schritt 2: Experiment vorbereiten (5 Minuten)

```powershell
# Kopiere autoresearch in isolierten Bereich
copy "~\Documents\Andrew Openclaw\autoresearch" "C:\Autoresearch\autoresearch" -Recurse

# Optional: Passe program.md an
notepad "C:\Autoresearch\autoresearch\program.md"
```

**Sicherheits-Tipps:**
- ✏️ Ändere `max_iterations` auf 50 (nicht unendlich)
- ✏️ Füge Discord-Webhook für Notifications hinzu
- ✏️ Setze `max_runtime_hours` auf 6 (nicht 8)

---

### Schritt 3: Starten und Schlafen gehen! 😴

```powershell
# Als Administrator ausführen
.\FortKnox-Autoresearch.ps1 -Action run -ExperimentName "mar31-overnight" -MaxRuntimeHours 6
```

**Das passiert jetzt:**
1. 🔍 Safety-Check prüft train.py
2. 💾 Backup wird erstellt
3. 🧱 Firewall aktiviert
4. 🚀 Experiment startet als isolierter User
5. 🛡️ Guardian überwacht alle 10 Sekunden
6. 📝 Logs werden geschrieben
7. 🔔 Discord-Benachrichtigung bei Start

**Geh schlafen!** 💤

---

## 📱 Morgens: Was erwartet dich

### Best-Case: Alles läuft perfekt

```
📱 Discord Notification:
"✅ Experiment 'mar31-overnight' abgeschlossen!
   42 Experimente durchgeführt
   Bestes val_bpb: 0.9895 (-0.0084 vs. baseline)
   Keine Sicherheitsverstöße"
```

### Worst-Case: Etwas ist schiefgelaufen

```
📱 Discord Notification:
"🚨 Guardian Alert: MAX_RUNTIME_EXCEEDED
   Experiment nach 6 Stunden gestoppt
   Letzter val_bpb: 0.9912
   Keine Daten verloren"
```

### Was du siehst im Vault:

```
📁 C:\Autoresearch\
├── 📄 experiment.log          ← Train-Output
├── 📄 guardian_status.log     ← Überwachungs-Daten
├── 📄 guardian_incidents.log  ← Falls etwas passierte
├── 📁 autoresearch\           ← Git-Repo mit History
├── 📁 backups\               ← Backup vor dem Start
└── 📁 results\               ← TSV-Dateien
```

---

## 🛡️ Die 7 Schutzschichten im Detail

### Layer 1: Isolierter User
```
🔒 User: autoresearch
🔒 Keine Admin-Rechte
🔒 Kein Zugriff auf deine Dateien
🔒 Nur C:\Autoresearch\ ist beschreibbar
```

**Was verhindert das?**
- ❌ Löschen deiner persönlichen Dateien
- ❌ Zugriff auf Windows-Systemdateien
- ❌ Installation von Malware systemweit

---

### Layer 2: Network Firewall
```
🧱 Outbound: BLOCK ALL (Default Deny)
🧱 Erlaubt: huggingface.co
🧱 Erlaubt: download.pytorch.org
🧱 Alles andere: VERBOTEN
```

**Was verhindert das?**
- ❌ Daten-Exfiltration zu fremden Servern
- ❌ Download von Malware
- ❌ Command & Control Kommunikation

---

### Layer 3: Filesystem Sandbox
```
📁 Schreibbar: C:\Autoresearch\
📁 Schreibbar: C:\Users\autoresearch\.cache\
📁 Lesbar: C:\Windows\System32 (nur für Python)
📁 Verboten: C:\Users\[DeinName]\
📁 Verboten: C:\Windows\System32\config\
```

**Was verhindert das?**
- ❌ Verschlüsselung deiner Dateien (Ransomware)
- ❌ Modifikation von System-Dateien
- ❌ Zugriff auf SSH-Keys, Passwörter, etc.

---

### Layer 4: Code Safety-Check
```python
# Vor dem Start wird train.py geprüft:
✅ Kein eval()
✅ Kein exec()
✅ Kein subprocess
✅ Kein __import__
✅ Keine verbotenen Imports
✅ Keine verdächtigen Muster
```

**Was verhindert das?**
- ❌ Code Injection
- ❌ Backdoors im train.py
- ❌ "Kreative" Lösungen des Agents

---

### Layer 5: Runtime Guardian
```python
# Alle 10 Sekunden:
⏱️  Runtime > 6h? → KILL
⏱️  VRAM > 48GB? → KILL
⏱️  Disk > 8GB? → KILL
⏱️  CPU > 80% (lange)? → KILL (Mining-Verdacht)
⏱️  Netzwerk zu unbekanntem Host? → KILL
⏱️  Prozess nicht mehr da? → STOP
```

**Was verhindert das?**
- ❌ Ressourcen-Exhaustion
- ❌ Crypto-Mining
- ❌ Daten-Lecks
- ❌ Hängende Prozesse

---

### Layer 6: Monitoring & Alerts
```
📊 Alle 30 Minuten:
   → Status-Update an Discord

🚨 Sofort bei:
   → Crash
   → Safety-Verstoß
   → Resource-Limit erreicht
   → Guardian-Intervention
```

**Was bringt das?**
- ✅ Du weißt sofort, wenn etwas passiert
- ✅ Kannst reagieren (remote stoppen)
- ✅ Hast vollständige Transparenz

---

### Layer 7: Backup & Recovery
```
💾 Vor dem Start:
   → Vollständiges Git-Backup
   
💾 Währenddessen:
   → Jeder Commit wird gespiegelt
   
💾 Nach dem Ende:
   → One-Click Restore möglich
```

**Was bringt das?**
- ✅ Immer Rollback möglich
- ✅ Kein Verlust von Fortschritt
- ✅ Experimente sind reproduzierbar

---

## 📋 Checkliste vor dem Start

```markdown
## Pre-Flight Checkliste

### Sicherheit
- [ ] Fort Knox Setup ausgeführt
- [ ] User "autoresearch" existiert
- [ ] Firewall-Regeln aktiv
- [ ] Discord-Webhook konfiguriert (optional)

### Code
- [ ] train.py manuell geprüft (kurzer Blick)
- [ ] prepare.py unverändert
- [ ] program.md angepasst (Iterations-Limit)

### Ressourcen
- [ ] GPU frei (kein anderes Training)
- [ ] Genug Disk-Speicher (>20GB frei)
- [ ] Stromversorgung stabil (Laptop am Netzteil)

### Monitoring
- [ ] Discord auf Handy installiert
- [ ] Laptop nicht im Ruhezustand (Einstellungen)
- [ ] VPN aus (nicht nötig, könnte stören)
```

---

## 🚨 Notfall-Prozeduren

### Fall 1: Du willst sofort stoppen

```powershell
# Von überall (auch Remote via SSH/RDP):
.\FortKnox-Autoresearch.ps1 -Action stop
```

**Oder hart:**
```powershell
# Alle Python-Prozesse killen:
Get-Process python | Stop-Process -Force
```

---

### Fall 2: Guardian hat gestoppt

```powershell
# Status prüfen:
.\FortKnox-Autoresearch.ps1 -Action status

# Logs ansehen:
Get-Content C:\Autoresearch\guardian_incidents.log

# Falls OK: Fortsetzen
.\FortKnox-Autoresearch.ps1 -Action run
```

---

### Fall 3: Discord zeigt "CRITICAL VIOLATION"

**Sofort:**
1. Laptop vom Netzwerk trennen (WLAN aus)
2. `.\FortKnox-Autoresearch.ps1 -Action stop`
3. `C:\Autoresearch\guardian_incidents.log` prüfen
4. **Niemals** den verdächtigen Code ausführen!
5. Aus Backup wiederherstellen: `C:\Autoresearch\backups\`

**Wahrscheinlichkeit:** Extrem gering (Safety-Checks verhindern das)

---

## 🔧 Erweiterte Konfiguration

### Discord-Webhook einrichten

1. Discord Server → Server-Einstellungen → Integrationen
2. Webhooks → Neuer Webhook
3. Kopiere URL
4. In `C:\Autoresearch\guardian_config.json` einfügen:

```json
{
  "notification_webhook": "https://discord.com/api/webhooks/..."
}
```

---

### Limits anpassen

In `FortKnox-Autoresearch.ps1`:

```powershell
# Konservativer (sicherer)
$Config.MaxRuntimeHours = 4      # Statt 6
$Config.MaxMemoryGB = 40         # Statt 48

# Aggressiver (mehr Experimente)
$Config.MaxRuntimeHours = 8      # Statt 6
$Config.MaxMemoryGB = 60         # Statt 48
```

---

## 📊 Vergleich: Ohne vs. Mit Fort Knox

| Szenario | Ohne Fort Knox | Mit Fort Knox |
|----------|---------------|---------------|
| **Agent macht Fehler** | Könnte System beschädigen | Guardian stoppt sofort |
| **Crypto-Mining** | Möglich | CPU-Limit erkennt & stoppt |
| **Daten-Leak** | Möglich | Firewall blockiert |
| **Ransomware** | Möglich | Sandbox verhindert |
| **Dauerhafte Schäden** | Möglich | Keine (isoliert) |
| **Dein Schlaf** | 😰 Unruhig | 😴 Tief und fest |

---

## 🎓 Best Practices

### 1. Starte konservativ
```
Erste Nacht:
- Max 20 Iterationen
- Max 4 Stunden
- Du bleibst wach für die ersten 30 Min

Zweite Nacht:
- Max 50 Iterationen
- Max 6 Stunden
- Geh schlafen

Dritte Nacht:
- Vertraue dem System
```

### 2. Überwache die ersten Male
```powershell
# Live-Log beobachten:
Get-Content C:\Autoresearch\experiment.log -Wait

# Alle 10 Min prüfen:
while ($true) { 
    .\FortKnox-Autoresearch.ps1 -Action status
    Start-Sleep 600
}
```

### 3. Vertrauen aufbauen
```
Woche 1: 50% Autonomie (du schaust oft rein)
Woche 2: 80% Autonomie (nur noch Alerts)
Woche 3: 100% Autonomie (schlafen bis morgen)
```

---

## 🆘 Support

### Problem: Setup schlägt fehl
```powershell
# Als Admin ausführen?
[Security.Principal.WindowsPrincipal]::Current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Wenn False: Rechtsklick → "Mit PowerShell als Administrator ausführen"
```

### Problem: Guardian startet nicht
```powershell
# Python installiert?
python --version

# psutil installiert?
pip install psutil
```

### Problem: Keine Discord-Notifications
```powershell
# Webhook testen:
Invoke-RestMethod -Uri "DEIN_WEBHOOK_URL" -Method Post -Body '{"content":"Test"}' -ContentType "application/json"
```

---

## 🎉 Fazit

**Autoresearch Fort Knox =**
- 🏰 Ein Schloss aus Stahl
- 😴 Gute Nachtruhe garantiert
- 🧠 Maximierte Forschung
- 🛡️ Minimiertes Risiko

**Du kannst jetzt:**
1. ✅ Sicher über Nacht experimentieren
2. ✅ Deinen Laptop unbeaufsichtigt lassen
3. ✅ Tief schlafen ohne Sorgen
4. ✅ Morgens tolle Ergebnisse finden

---

**Letzter Check:**
- [ ] Setup ausgeführt
- [ ] Test-Run gemacht (Tagsüber, 30 Min)
- [ ] Discord-Webhook funktioniert
- [ ] Du bist bereit für die erste Nacht!

**Viel Erfolg mit deiner KI-Forschung! 🚀**

---

*Dokumentation: Fort Knox für Autoresearch*  
*Version: 1.0*  
*Erstellt: 2026-03-31*
