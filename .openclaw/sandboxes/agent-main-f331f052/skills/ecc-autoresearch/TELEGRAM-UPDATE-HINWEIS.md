# ⚡ WICHTIGE UPDATE-HINWEIS für Telegram

## Alle Discord-Referenzen durch Telegram ersetzen!

Die Fort Knox Anleitung erwähnt Discord, aber wir nutzen jetzt **Telegram**!

### Schnelle Änderungen:

| Wo | Discord (alt) | Telegram (neu) |
|----|---------------|----------------|
| **Benachrichtigungen** | Discord Webhook | Telegram Bot |
| **Setup** | Server erstellen | @BotFather |
| **Mobile App** | Discord | Telegram |

### Was du brauchst:
1. Telegram auf dem Handy installiert
2. Bot erstellt via @BotFather
3. Bot-Token und Chat-ID
4. In Guardian-Skript eintragen

### Detaillierte Anleitung:
📖 **Siehe:** `TELEGRAM-SETUP.md`

### Schnellstart:
```powershell
# Umgebungsvariablen setzen:
[Environment]::SetEnvironmentVariable("TELEGRAM_BOT_TOKEN", "123456789:ABC...", "User")
[Environment]::SetEnvironmentVariable("TELEGRAM_CHAT_ID", "987654321", "User")

# Dann neu starten und Experiment laufen lassen!
```

---

**Warum Telegram statt Discord?**
- ✅ Einfacher Setup (kein Server nötig)
- ✅ Schnellerer Push aufs Handy
- ✅ Keine US-Cloud (Schweiz)
- ✅ Einfachere API

---

*Aktualisiert: 2026-03-31*
