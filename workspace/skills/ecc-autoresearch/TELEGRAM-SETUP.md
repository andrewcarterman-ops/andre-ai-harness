# Telegram Bot Setup für Autoresearch Fort Knox

> Discord ist gut, Telegram ist besser für mobile Benachrichtigungen

---

## 🚀 Telegram Bot erstellen (2 Minuten)

### Schritt 1: BotFather

1. Öffne Telegram auf Handy oder Desktop
2. Suche nach **@BotFather**
3. Starte den Chat mit `/start`
4. Schreibe `/newbot`
5. Gib einen Namen ein: `Autoresearch Guardian`
6. Gib einen Username ein: `deinname_autoresearch_bot`
   - Muss auf `_bot` enden
   - Muss einzigartig sein

**BotFather antwortet:**
```
Done! Congratulations on your new bot.
Use this token to access the HTTP API:
123456789:ABCdefGHIjklMNOpqrSTUvwxyz
```

**👉 Speichere den Token!** (z.B. in 1Password)

---

### Schritt 2: Deine Chat-ID herausfinden

1. Suche deinen neuen Bot (z.B. @deinname_autoresearch_bot)
2. Starte den Chat mit `/start`
3. Schreibe irgendetwas (z.B. "Test")
4. Rufe diese URL im Browser auf:
```
https://api.telegram.org/bot<DEIN_TOKEN>/getUpdates
```

**Beispiel-Antwort:**
```json
{
  "ok": true,
  "result": [
    {
      "update_id": 123456789,
      "message": {
        "message_id": 1,
        "from": {
          "id": 987654321,  <-- DAS IST DEINE CHAT-ID!
          "first_name": "DeinName"
        },
        "chat": {
          "id": 987654321,  <-- ODER HIER!
          "type": "private"
        },
        "text": "Test"
      }
    }
  ]
}
```

**👉 Speichere die Chat-ID!** (z.B. `987654321`)

---

## 🔧 Guardian-Skript für Telegram anpassen

In `autoresearch_guardian.py` ersetze die `_send_notification` Methode:

```python
def _send_notification(self, message):
    """Sendet Telegram Benachrichtigung"""
    import requests
    
    # Deine Daten hier eintragen:
    BOT_TOKEN = "123456789:ABCdefGHIjklMNOpqrSTUvwxyz"  # Von BotFather
    CHAT_ID = "987654321"  # Von getUpdates
    
    try:
        url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
        payload = {
            "chat_id": CHAT_ID,
            "text": message,
            "parse_mode": "Markdown",
            "disable_notification": False  # True für stille Nachrichten
        }
        
        response = requests.post(url, json=payload, timeout=10)
        
        if response.status_code == 200:
            print(f"   📱 Telegram gesendet")
        else:
            print(f"   ⚠️  Telegram-Fehler: {response.text}")
            
    except Exception as e:
        print(f"   ⚠️  Konnte Telegram nicht senden: {e}")
```

---

## 🎨 Schöne Nachrichten

### Verbesserte Version mit Formatierung:

```python
def _send_notification(self, title, message, level="info"):
    """Sendet formatierte Telegram Benachrichtigung"""
    import requests
    
    BOT_TOKEN = "DEIN_TOKEN"
    CHAT_ID = "DEINE_CHAT_ID"
    
    # Emoji basierend auf Level
    emojis = {
        "info": "ℹ️",
        "success": "✅",
        "warning": "⚠️",
        "error": "🚨",
        "critical": "🔴"
    }
    
    emoji = emojis.get(level, "ℹ️")
    
    # Formatieren
    text = f"{emoji} *{title}*\n\n{message}"
    
    try:
        url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
        payload = {
            "chat_id": CHAT_ID,
            "text": text,
            "parse_mode": "Markdown",
            "disable_notification": level in ["info", "success"]
        }
        
        requests.post(url, json=payload, timeout=10)
        
    except Exception as e:
        print(f"Telegram-Fehler: {e}")
```

---

## 📱 Beispiel-Nachrichten

### Start-Benachrichtigung:
```python
self._send_notification(
    "🚀 Experiment gestartet",
    f"*Experiment:* {experiment_name}\n"
    f"*Max Runtime:* 6 Stunden\n"
    f"*Start:* {datetime.now().strftime('%H:%M')}\n\n"
    f"_Ich überwache alle 10 Sekunden..._",
    level="info"
)
```

**Telegram sieht so aus:**
```
🚀 Experiment gestartet

Experiment: mar31-overnight
Max Runtime: 6 Stunden
Start: 23:45

Ich überwache alle 10 Sekunden...
```

---

### Status-Update (alle 30 Min):
```python
self._send_notification(
    "📊 Status Update",
    f"*Laufzeit:* {runtime_min} Minuten\n"
    f"*Experimente:* {exp_count}\n"
    f"*Bestes val_bpb:* {best_val_bpb}\n"
    f"*VRAM:* {vram_gb} GB / 48 GB\n\n"
    f"_Alles läuft normal_ ✅",
    level="success"
)
```

---

### Alarm bei Verstoß:
```python
self._send_notification(
    "🚨 GUARDIAN ALARM",
    f"*Grund:* {reason}\n"
    f"*Details:* {details}\n"
    f"*Aktion:* Prozess wurde gestoppt\n\n"
    f"⚠️ *Bitte prüfen!*",
    level="critical"
)
```

**Telegram sieht so aus:**
```
🚨 GUARDIAN ALARM

Grund: MAX_RUNTIME_EXCEEDED
Details: Laufzeit: 361min > 360min
Aktion: Prozess wurde gestoppt

⚠️ Bitte prüfen!
```

---

## 🔒 Sicherheit: Token schützen

### Option 1: Environment Variable (empfohlen)

```python
import os

BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID")

if not BOT_TOKEN or not CHAT_ID:
    print("⚠️  Telegram nicht konfiguriert (Environment Variables fehlen)")
    return
```

**Setzen in PowerShell:**
```powershell
[Environment]::SetEnvironmentVariable("TELEGRAM_BOT_TOKEN", "123456789:ABC...", "User")
[Environment]::SetEnvironmentVariable("TELEGRAM_CHAT_ID", "987654321", "User")
```

**Danach PowerShell neu starten!**

---

### Option 2: Config-Datei (außerhalb Git)

```python
import json
from pathlib import Path

def load_telegram_config():
    config_path = Path.home() / ".autoresearch" / "telegram_config.json"
    
    if config_path.exists():
        with open(config_path) as f:
            return json.load(f)
    
    return None

# config.json:
{
    "bot_token": "123456789:ABC...",
    "chat_id": "987654321"
}
```

---

## 🧪 Test vor dem ersten Einsatz

```python
# Test-Skript: test_telegram.py
import requests

BOT_TOKEN = "DEIN_TOKEN"
CHAT_ID = "DEINE_CHAT_ID"

def send_test_message():
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": CHAT_ID,
        "text": "🧪 *Test erfolgreich!*\n\nDein Autoresearch Guardian ist bereit.",
        "parse_mode": "Markdown"
    }
    
    response = requests.post(url, json=payload)
    
    if response.status_code == 200:
        print("✅ Telegram funktioniert!")
    else:
        print(f"❌ Fehler: {response.text}")

if __name__ == "__main__":
    send_test_message()
```

**Ausführen:**
```bash
python test_telegram.py
```

---

## 📋 Quick-Reference

| Was | Wert |
|-----|------|
| **API Base URL** | `https://api.telegram.org/bot<TOKEN>` |
| **Send Message** | `/sendMessage` |
| **Formatierung** | Markdown oder HTML |
| **Rate Limit** | ~30 Nachrichten pro Sekunde |
| **Max Länge** | 4096 Zeichen |
| **Dateien** | Bis 50 MB möglich |

---

## 🎯 Warum Telegram besser ist als Discord

| Feature | Discord | Telegram |
|---------|---------|----------|
| **Setup** | Server + Webhook | Nur Bot |
| **Mobile Push** | Manchmal verzögert | Sofort |
| **Offline** | Braucht Server | Funktioniert immer |
| **Einfachheit** | Komplexere API | Super einfach |
| **Dateien** | Max 8 MB | Max 50 MB |
| **Privacy** | US-Unternehmen | Schweiz |

---

## ✅ Checkliste

- [ ] @BotFather kontaktiert
- [ ] Bot erstellt
- [ ] Token gespeichert (sicher!)
- [ ] Chat-ID herausgefunden
- [ ] Token in Guardian-Skript eingetragen
- [ ] Test-Nachricht gesendet ✅
- [ ] Handy-Vibration aktiviert für Telegram

---

**Bereit für die erste Nacht mit Telegram-Benachrichtigungen!** 📱✨
