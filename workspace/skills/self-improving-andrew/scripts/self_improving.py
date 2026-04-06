#!/usr/bin/env python3
"""
Self-Improving Andrew - Learning System
Speichert und verwaltet gelernte Patterns und Präferenzen
"""
import json
import os
import re
from datetime import datetime
from pathlib import Path

class SelfImprovingAndrew:
    def __init__(self, base_path=None):
        if base_path is None:
            base_path = Path.home() / ".openclaw" / "workspace" / "memory" / "self-improving"
        self.base_path = Path(base_path)
        self._ensure_structure()
    
    def _ensure_structure(self):
        """Stelle sicher, dass alle Dateien existieren"""
        self.base_path.mkdir(parents=True, exist_ok=True)
        
        files = {
            "hot.md": "# HOT Memory - Aktive Regeln\n\nDiese Regeln werden immer berücksichtigt.\n\n",
            "corrections.md": "# Corrections - Letzte Korrekturen\n\n## Format\n- Datum | Korrektur | Häufigkeit | Status\n\n",
            "preferences.md": "# Preferences - Deine Präferenzen\n\n",
            "patterns.md": "# Patterns - Erkannte Muster\n\n"
        }
        
        for filename, content in files.items():
            filepath = self.base_path / filename
            if not filepath.exists():
                filepath.write_text(content, encoding="utf-8")
    
    def log_correction(self, correction, context=None):
        """Speichere eine Korrektur"""
        corrections_file = self.base_path / "corrections.md"
        
        # Prüfe, ob diese Korrektur bereits existiert
        existing = self._find_existing_correction(correction)
        
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
        entry = f"- {timestamp} | {correction}"
        if context:
            entry += f" | Context: {context}"
        entry += "\n"
        
        if existing:
            # Update Häufigkeit
            self._increment_correction_count(correction)
            count = self._get_correction_count(correction)
            
            # Nach 3x → promote zu HOT
            if count >= 3:
                self._promote_to_hot(correction, context)
                return {
                    "status": "promoted",
                    "message": f"Korrektur '{correction[:50]}...' wurde zu einer festen Regel!",
                    "count": count
                }
            else:
                return {
                    "status": "updated",
                    "message": f"Korrektur erfasst ({count}/3 bis zur Regel)",
                    "count": count
                }
        else:
            # Neue Korrektur
            with open(corrections_file, "a", encoding="utf-8") as f:
                f.write(entry)
            
            return {
                "status": "logged",
                "message": "Korrektur gespeichert",
                "count": 1
            }
    
    def log_preference(self, preference, category="general"):
        """Speichere eine Präferenz"""
        prefs_file = self.base_path / "preferences.md"
        
        timestamp = datetime.now().strftime("%Y-%m-%d")
        entry = f"\n## {category} ({timestamp})\n{preference}\n"
        
        with open(prefs_file, "a", encoding="utf-8") as f:
            f.write(entry)
        
        return {
            "status": "saved",
            "message": f"Präferenz in Kategorie '{category}' gespeichert"
        }
    
    def log_pattern(self, pattern, evidence=None):
        """Speichere ein erkanntes Muster"""
        patterns_file = self.base_path / "patterns.md"
        
        timestamp = datetime.now().strftime("%Y-%m-%d")
        entry = f"\n## Pattern ({timestamp})\n**Pattern:** {pattern}\n"
        if evidence:
            entry += f"**Evidence:** {evidence}\n"
        entry += "**Status:** Tentative (needs confirmation)\n"
        
        with open(patterns_file, "a", encoding="utf-8") as f:
            f.write(entry)
        
        return {
            "status": "pattern_logged",
            "message": "Muster erkannt und gespeichert"
        }
    
    def get_hot_rules(self):
        """Lade alle HOT Regeln"""
        hot_file = self.base_path / "hot.md"
        content = hot_file.read_text(encoding="utf-8")
        
        # Extrahiere Regeln (einfache Markdown-Liste)
        rules = []
        for line in content.split("\n"):
            if line.strip().startswith("-") or line.strip().startswith("*"):
                rules.append(line.strip()[1:].strip())
        
        return rules
    
    def get_recent_corrections(self, limit=10):
        """Lade letzte Korrekturen"""
        corrections_file = self.base_path / "corrections.md"
        content = corrections_file.read_text(encoding="utf-8")
        
        lines = [l for l in content.split("\n") if l.strip().startswith("-")]
        return lines[-limit:]
    
    def get_preferences(self):
        """Lade alle Präferenzen"""
        prefs_file = self.base_path / "preferences.md"
        return prefs_file.read_text(encoding="utf-8")
    
    def _find_existing_correction(self, correction):
        """Prüfe, ob eine ähnliche Korrektur existiert"""
        corrections_file = self.base_path / "corrections.md"
        content = corrections_file.read_text(encoding="utf-8")
        
        # Einfache String-Matching (könnte besser mit Embeddings sein)
        correction_key = correction.lower()[:50]
        return correction_key in content.lower()
    
    def _increment_correction_count(self, correction):
        """Erhöhe den Zähler für eine Korrektur"""
        # Simplifizierte Implementierung
        pass
    
    def _get_correction_count(self, correction):
        """Hole den Zähler für eine Korrektur"""
        corrections_file = self.base_path / "corrections.md"
        content = corrections_file.read_text(encoding="utf-8")
        
        correction_key = correction.lower()[:50]
        return content.lower().count(correction_key)
    
    def _promote_to_hot(self, correction, context=None):
        """Promote eine Korrektur zu HOT Regel"""
        hot_file = self.base_path / "hot.md"
        
        timestamp = datetime.now().strftime("%Y-%m-%d")
        entry = f"\n- **{correction}** (confirmed {timestamp})\n"
        if context:
            entry += f"  - Context: {context}\n"
        
        with open(hot_file, "a", encoding="utf-8") as f:
            f.write(entry)

def main():
    """CLI Interface"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Self-Improving Andrew")
    parser.add_argument("action", choices=["correction", "preference", "pattern", "hot", "recent", "prefs"])
    parser.add_argument("--text", "-t", help="Text to log")
    parser.add_argument("--category", "-c", default="general", help="Kategorie für Präferenz")
    parser.add_argument("--context", help="Zusätzlicher Kontext")
    
    args = parser.parse_args()
    
    si = SelfImprovingAndrew()
    
    if args.action == "correction":
        if not args.text:
            print("Fehler: --text erforderlich für correction")
            return
        result = si.log_correction(args.text, args.context)
        print(json.dumps(result, indent=2, ensure_ascii=False))
    
    elif args.action == "preference":
        if not args.text:
            print("Fehler: --text erforderlich für preference")
            return
        result = si.log_preference(args.text, args.category)
        print(json.dumps(result, indent=2, ensure_ascii=False))
    
    elif args.action == "pattern":
        if not args.text:
            print("Fehler: --text erforderlich für pattern")
            return
        result = si.log_pattern(args.text, args.context)
        print(json.dumps(result, indent=2, ensure_ascii=False))
    
    elif args.action == "hot":
        rules = si.get_hot_rules()
        print("HOT Regeln:")
        for rule in rules:
            print(f"  - {rule}")
    
    elif args.action == "recent":
        corrections = si.get_recent_corrections()
        print("Letzte Korrekturen:")
        for c in corrections:
            print(f"  {c}")
    
    elif args.action == "prefs":
        print(si.get_preferences())

if __name__ == "__main__":
    main()
