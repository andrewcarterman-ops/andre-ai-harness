# FORT KNOX IMPLEMENTATION - JETZT!

> Keine Theorie mehr. Wir bauen es JETZT.

---

## 🚨 WICHTIG: Vorab-Checks

### 1. Bist du bereit?

- [ ] Laptop/Desktop mit NVIDIA GPU
- [ ] Windows 10/11
- [ ] Python 3.10+ installiert
- [ ] ~20GB freier Speicher
- [ ] Telegram auf dem Handy installiert
- [ ] 30 Minuten Zeit für Setup

### 2. Was brauchen wir?

```
📁 Quelle:  C:\Users\andre\.openclaw\workspace\skills\ecc-autoresearch\
📁 Ziel:    C:\Autoresearch\
```

---

## 🚀 SCHRITT 1: Telegram Bot (5 Min)

### A. Bot erstellen

1. **Telegram öffnen** (Handy oder Desktop)
2. Suche nach: **`@BotFather`**
3. Tippe: **`/start`**
4. Tippe: **`/newbot`**
5. Name eingeben: `Autoresearch Guardian`
6. Username eingeben: `andre_autoresearch_bot`
   - Muss einzigartig sein!
   - Wenn vergeben: `andre_autoresearch2_bot`

**BotFather antwortet:**
```
Use this token to access the HTTP API:
123456789:ABCdefGHIjklMNOpqrSTUvwxyz
```

👉 **Diesen Token kopieren und speichern!**

---

### B. Chat-ID herausfinden

1. Suche deinen Bot: **`@andre_autoresearch_bot`**
2. Starte Chat mit **`/start`**
3. Schreibe: **`Test`**
4. Öffne im Browser:
   ```
   https://api.telegram.org/bot123456789:ABCdefGHIjklMNOpqrSTUvwxyz/getUpdates
   ```
   (Ersetze mit DEINEM Token!)

5. Suche nach `"chat":{"id":`:
   ```json
   "chat":{"id":987654321,...}
   ```

👉 **Diese ID speichern!** (z.B. `987654321`)

---

### C. Token & ID speichern

```powershell
# ALS ADMINISTRATOR ausführen!

# Token setzen
[Environment]::SetEnvironmentVariable("TELEGRAM_BOT_TOKEN", "123456789:DEIN_TOKEN_HIER", "User")

# Chat-ID setzen  
[Environment]::SetEnvironmentVariable("TELEGRAM_CHAT_ID", "987654321", "User")

# Verifizieren
Write-Host "Token: $env:TELEGRAM_BOT_TOKEN"
Write-Host "Chat ID: $env:TELEGRAM_CHAT_ID"
```

**PowerShell komplett schließen und neu öffnen!**

---

## 🚀 SCHRITT 2: Fort Knox Setup (10 Min)

### A. Als Administrator PowerShell öffnen

```powershell
# Rechtsklick auf PowerShell → "Als Administrator ausführen"

# Zum Verzeichnis wechseln
cd "C:\Users\andre\.openclaw\workspace\skills\ecc-autoresearch"
```

---

### B. Setup ausführen

```powershell
.\FortKnox-Autoresearch.ps1 -Action setup
```

**Was passiert:**
1. ✅ Erstellt User "autoresearch"
2. ✅ Erstellt Verzeichnis `C:\Autoresearch\`
3. ✅ Konfiguriert Firewall
4. ✅ Kopiert Tools
5. ✅ Generiert Passwort (notieren!)

**Warte bis fertig!** (ca. 2-3 Minuten)

---

### C. Verzeichnisstruktur prüfen

```powershell
# Sollte jetzt existieren:
C:\Autoresearch\
├── autoresearch_guardian.py
├── ecc_safety_checker.py
├── FortKnox-Autoresearch.ps1
├── guardian_config.json
└── logs\
```

---

## 🚀 SCHRITT 3: Autoresearch kopieren (2 Min)

### A. Quelle vorbereiten

Hast du schon karpathy/autoresearch geklont?

**FALLS JA:**
```powershell
copy "C:\Users\andre\Documents\Andrew Openclaw\autoresearch" "C:\Autoresearch\autoresearch" -Recurse
```

**FALLS NEIN:**
```powershell
# Als normaler User (nicht Admin!)
cd C:\Autoresearch

# Git clone (falls Git installiert)
git clone https://github.com/karpathy/autoresearch.git

# ODER: Manuell downloaden und entpacken
```

---

### B. Test: Safety-Checker laufen lassen

```powershell
cd "C:\Autoresearch"
python ecc_safety_checker.py --file autoresearch\train.py --format json
```

**Erwartetes Ergebnis:**
```json
{
  "overall_score": 95,
  "passed": true,
  "violations": []
}
```

**Wenn PASSED:** Weiter!
**Wenn FAILED:** Melden - sollte nicht passieren bei Original-Code

---

## 🚀 SCHRITT 4: Test-Run (10 Min)

### A. Tagsüber-Test (WICHTIG!)

**Niemals direkt über Nacht starten!**

```powershell
# Als Administrator
.\FortKnox-Autoresearch.ps1 -Action run -ExperimentName "test-daytime" -MaxRuntimeHours 0.1
```

**Das macht:**
- Startet Experiment
- Läuft nur 6 Minuten (0.1h = 6min)
- Guardian überwacht
- Du siehst ob alles funktioniert

---

### B. Auf Telegram achten

**Solltest du sehen:**
```
🚀 Experiment gestartet
Guardian aktiviert
Überwache PID xxxxx
Max Runtime: 6 Minuten
```

**Nach 6 Minuten:**
```
🏁 Experiment erfolgreich beendet
Laufzeit: 6 Minuten
Keine Verstöße ✅
```

**Wenn das kommt:** 🎉 Alles funktioniert!

---

## 🚀 SCHRITT 5: Über Nacht (Die echte Sache)

### A. Vor dem Schlafengehen

```powershell
# Als Administrator
.\FortKnox-Autoresearch.ps1 -Action run -ExperimentName "mar31-overnight" -MaxRuntimeHours 6
```

### B. Checkliste vor dem Schlafen

- [ ] Telegram-Benachrichtigung kam
- [ ] Laptop am Netzteil
- [ ] Energiesparplan: Niemals in den Schlafmodus
- [ ] WLAN stabil
- [ ] Du hast den Alert-Bot auf dem Handy

---

### C. Morgens

**Was du erwartest:**
```
📱 Telegram:
🏁 Experiment erfolgreich beendet
Laufzeit: 360 Minuten
Keine Verstöße ✅
Gute Ergebnisse! 🎉
```

**Oder falls was schiefgelaufen:**
```
📱 Telegram:
🚨 GUARDIAN ALARM
Grund: MAX_RUNTIME_EXCEEDED
...
```

---

## 🛠️ Troubleshooting

### Problem: "python nicht gefunden"
```powershell
# Lösung: Python Pfad
$env:PATH += ";C:\Program Files\Python310"
# ODER Python neu installieren mit "Add to PATH"
```

### Problem: "psutil nicht installiert"
```powershell
pip install psutil
```

### Problem: "Telegram nicht konfiguriert"
```powershell
# Prüfen:
$env:TELEGRAM_BOT_TOKEN
$env:TELEGRAM_CHAT_ID

# Falls leer: Schritt 1 wiederholen
```

### Problem: "Zugriff verweigert"
```powershell
# Lösung: Als Administrator ausführen!
# Rechtsklick → "Als Administrator ausführen"
```

---

## ✅ FINAle CHECKLISTE

### Vor dem ersten ECHTEN Lauf:

- [ ] Telegram Bot erstellt
- [ ] Token & Chat-ID gespeichert
- [ ] Environment Variablen gesetzt
- [ ] Fort Knox Setup ausgeführt
- [ ] Tagsüber-Test (6 Min) erfolgreich
- [ ] Telegram-Benachrichtigung kam an
- [ ] Laptop-Einstellungen optimiert

### Jetzt bist du bereit für:
- 🌙 Übernacht-Experimente
- 😴 Tiefen Schlaf
- 🚀 Autonome KI-Forschung

---

**FRAGEN?**
Sag einfach Bescheid welcher Schritt nicht klappt!

**SONST:**
Viel Erfolg mit deiner ersten Fort Knox Nacht! 🏰🤖
