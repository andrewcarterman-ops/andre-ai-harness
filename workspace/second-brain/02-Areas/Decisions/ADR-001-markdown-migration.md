---
date: 2026-04-06
adr_id: ADR-001
title: "Sessions von JSONL zu Markdown migrieren"
status: Accepted
priority: High
---

# ADR-001: Sessions von JSONL zu Markdown migrieren

## Kontext

Die Sessions wurden als JSONL-Dateien gespeichert (claw-code Format).
Dies führte zu Problemen:
- Dateien wurden beim Überschreiben zerstört
- Keine echte Versionskontrolle
- Schwierig zu lesen und zu durchsuchen

## Entscheidung

Wir migrieren alle Sessions zu Markdown mit YAML Frontmatter.

## Konsequenzen

- ✅ Besser lesbar
- ✅ Git-freundlich (echte Versionskontrolle)
- ✅ Obsidian-kompatibel
- ✅ Einfacher zu durchsuchen
- ⚠️ Konvertierung einmalig nötig

## Umsetzung

- PowerShell-Script erstellt: `Convert-Sessions-v2.ps1`
- 9 Sessions erfolgreich konvertiert
- Alte JSONL-Dateien bleiben als Backup erhalten
