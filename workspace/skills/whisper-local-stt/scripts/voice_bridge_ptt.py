#!/usr/bin/env python3
"""
Voice Bridge Phase 3 - PTT Hotkey Handler
Global F12 Listener für Push-to-Talk

Usage:
    python voice_bridge_ptt.py
    Drücke F12 → Zeigt "PTT aktiviert"
    Ctrl+C → Beenden
"""

import sys
from pynput import keyboard
from datetime import datetime

# PTT Status
ptt_active = False


def on_press(key):
    """Wird aufgerufen wenn eine Taste gedrückt wird"""
    global ptt_active
    
    try:
        # Prüfe ob F12 gedrückt wurde
        if key == keyboard.Key.f12:
            if not ptt_active:
                ptt_active = True
                timestamp = datetime.now().strftime("%H:%M:%S")
                print(f"[{timestamp}] [PTT] F12 GEDRÜCKT - Aufnahme startet...")
                
                # Hier später: Audio-Aufnahme starten
                # start_recording()
                
    except Exception as e:
        print(f"[FEHLER] {e}")


def on_release(key):
    """Wird aufgerufen wenn eine Taste losgelassen wird"""
    global ptt_active
    
    try:
        # Prüfe ob F12 losgelassen wurde
        if key == keyboard.Key.f12:
            if ptt_active:
                ptt_active = False
                timestamp = datetime.now().strftime("%H:%M:%S")
                print(f"[{timestamp}] [PTT] F12 LOSGELASSEN - Aufnahme stoppt...")
                
                # Hier später: Audio-Aufnahme stoppen + Transkription
                # stop_and_transcribe()
                
    except Exception as e:
        print(f"[FEHLER] {e}")


def main():
    """Hauptfunktion"""
    print("\n" + "="*60)
    print("PTT HOTKEY HANDLER - Phase 3")
    print("="*60)
    print("\nStatus: BEREIT")
    print("Drücke F12 für PTT")
    print("Drücke Ctrl+C zum Beenden")
    print("="*60 + "\n")
    
    # Keyboard Listener starten
    with keyboard.Listener(
        on_press=on_press,
        on_release=on_release
    ) as listener:
        try:
            listener.join()
        except KeyboardInterrupt:
            print("\n\nBeendet.")
            sys.exit(0)


if __name__ == "__main__":
    main()
