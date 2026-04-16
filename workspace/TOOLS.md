# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Shell & Scripting Preferences

- **Default shell: PowerShell**
- **Preferred scripting language: PowerShell (.ps1)**
- **Bash / Git Bash:** Only when explicitly necessary. If Git Bash is required, provide very detailed instructions.
- **Python scripts:** Acceptable for cross-platform utilities

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## 🗂️ Workspace Map — Alle Arbeitsverzeichnisse

**WICHTIG:** Nicht nur im OpenClaw-Workspace arbeiten! Parzival hat Projekte an mehreren Orten.

### Primäre Verzeichnisse

| Pfad | Inhalt | Wann nutzen |
|------|--------|-------------|
| `C:\Users\andre\.openclaw\workspace\` | OpenClaw Skills, Memory, Config | Skills erstellen/verwalten, Memory |
| `C:\Users\andre\Documents\Andrew Openclaw\` | Hauptarbeitsverzeichnis | Projekte, Obsidian, ECC |

### Projekte im Detail

| Projekt | Pfad | Status |
|---------|------|--------|
| **ECC + Second Brain Framework** | `~\Documents\Andrew Openclaw\Kimi_Agent_ECC-Second-Brain-Framework Implementiert\` | ✅ Implementiert |
| **ECC Repo (Original)** | `~\Documents\Andrew Openclaw\everything-claude-code-main\` | Referenz-Repo |
| **Obsidian Haupt-Vault** | `~\Documents\Andrew Openclaw\` (hat .obsidian) | Aktiver Vault |
| **SecondBrain Vault** | `~\...\Kimi_Agent_ECC-Second-Brain-Framework Implementiert\SecondBrain\` | Aktiver Vault |
| **Code Implement** | `~\Documents\Andrew Openclaw\Code implement\` | Code-Projekte |
| **Mission Control v2** | `~\.openclaw\workspace\skills\mission-control-v2\` | Next.js Dashboard |
| **Secure API Client** | `~\.openclaw\workspace\skills\secure-api-client\` | Fertiger Skill |
| **Whisper Local STT** | `~\.openclaw\workspace\skills\whisper-local-stt\` | Code fertig, Setup ausstehend |

### Netzwerk / Remote

| Host | IP | Zweck |
|------|-----|-------|
| **OpenClaw PC** | 192.168.1.25 / 192.168.178.192 | OpenClaw Gateway (Port 18789) |
| **Bao PC** | bao@pc (SSH Key: ed25519) | Zweiter PC |
| **Tailscale** | In Einrichtung | Mesh-VPN zwischen Geräten |

### Regel für zukünftige Sessions

Bevor du sagst "das existiert nicht" oder "haben wir nicht gemacht":
1. Prüfe `~\.openclaw\workspace\` (OpenClaw Skills)
2. Prüfe `~\Documents\Andrew Openclaw\` (Hauptprojekte)
3. Prüfe `~\Downloads\` (neue Downloads)
4. Erst DANN sagen, dass etwas fehlt.
