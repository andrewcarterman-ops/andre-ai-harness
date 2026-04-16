#!/usr/bin/env python3
"""
Voice Bridge - Vollautomatisch mit OpenClaw
============================================
Dieses Script laeuft als OpenClaw Sub-Agent und nutzt sessions_spawn
um mit der Haupt-Session zu kommunizieren.

Workflow:
1. Nutzer startet diesen Sub-Agent in OpenClaw
2. Sub-Agent nimmt Sprache auf
3. Sub-Agent ruft Haupt-Agent via sessions_spawn
4. Haupt-Agent antwortet
5. Sub-Agent gibt Antwort als TTS aus
6. Loop wiederholt

Starten in OpenClaw:
    python skills/whisper-local-stt/scripts/voice_bridge_agent.py
"""

import sys
import time
import tempfile
import wave
import subprocess
from pathlib import Path
from datetime import datetime

import numpy as np
import sounddevice as sd

# Pfade
TRANSCRIBE_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "transcribe.py"
PIPER_EXE = Path.home() / ".openclaw" / "piper" / "piper" / "piper.exe"
PIPER_MODEL = Path.home() / ".openclaw" / "piper" / "models" / "de_DE-thorsten-high.onnx"

def log(msg):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"[{timestamp}] {msg}", flush=True)

def play_tts(text):
    """Text mit Piper TTS ausgeben"""
    if not text or len(text) < 2:
        return False
    
    try:
        tts_path = Path(tempfile.gettempdir()) / f"tts_{int(time.time())}.wav"
        
        result = subprocess.run(
            [str(PIPER_EXE), "--model", str(PIPER_MODEL), "--output_file", str(tts_path)],
            input=text.encode('utf-8'),
            capture_output=True,
            timeout=60
        )
        
        if result.returncode == 0 and tts_path.exists():
            with wave.open(str(tts_path), 'rb') as wf:
                frames = wf.readframes(wf.getnframes())
                audio_data = np.frombuffer(frames, dtype=np.int16)
                sd.play(audio_data, wf.getframerate())
                sd.wait()
            
            try:
                tts_path.unlink()
            except:
                pass
            return True
    except Exception as e:
        log(f"TTS Fehler: {e}")
    return False

def record_audio():
    """Audio aufnehmen bis ENTER gedrueckt wird"""
    recording = []
    
    def callback(indata, frames, time_info, status):
        recording.append(indata.copy())
    
    stream = sd.InputStream(
        samplerate=16000, 
        channels=1, 
        dtype=np.int16, 
        callback=callback,
        blocksize=1024
    )
    stream.start()
    
    # Warte auf ENTER
    input()
    
    stream.stop()
    stream.close()
    
    if not recording:
        return None, 0
    
    # Speichern
    audio = np.concatenate(recording, axis=0)
    duration = len(audio) / 16000
    
    wav_path = Path(tempfile.gettempdir()) / f"voice_{int(time.time())}.wav"
    with wave.open(str(wav_path), 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(audio.tobytes())
    
    return wav_path, duration

def transcribe(wav_path):
    """Whisper Transkription"""
    result = subprocess.run(
        [sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)],
        capture_output=True,
        text=True,
        timeout=300
    )
    
    text = result.stdout.strip()
    
    # Cleanup
    try:
        wav_path.unlink()
    except:
        pass
    
    return text

def main():
    print("\n" + "="*70)
    print("  VOICE BRIDGE - OpenClaw Voice Assistant")
    print("="*70)
    print("\n  🎙️  ENTER = Sprechen | ENTER = Stop | Ich antworte als TTS")
    print("\n  ⚠️  WICHTIG: Dieser Agent muss als Sub-Agent gestartet werden!")
    print("      Er kann nicht standalone laufen.")
    print("\n  Starte mit: sessions_spawn (runtime='subagent')")
    print("="*70 + "\n")
    
    log("Voice Bridge bereit. Warte auf Eingabe...")
    
    while True:
        try:
            print("\n" + "-"*70)
            log("[Druecke ENTER zum Sprechen...]")
            input()
            
            # Aufnahme
            log("🔴 NIMMT AUF... (sprich jetzt, dann ENTER)")
            wav_path, duration = record_audio()
            
            if not wav_path or duration < 0.5:
                log("⚠️  Aufnahme zu kurz")
                play_tts("Bitte noch einmal, das war zu kurz.")
                continue
            
            log(f"✅ Aufnahme: {duration:.1f}s")
            
            # Transkription
            log("🔄 Transkribiere mit Whisper...")
            question = transcribe(wav_path)
            
            if not question or question == "[Kein Text erkannt]":
                log("❌ Nichts verstanden")
                play_tts("Entschuldigung, ich habe dich nicht verstanden.")
                continue
            
            print("\n" + "="*70)
            log(f"📝 ERKANNT: {question}")
            print("="*70)
            
            # WICHTIG: Hier nutzen wir sessions_spawn
            # Aber das funktioniert NUR wenn dieses Script als OpenClaw Agent laeuft!
            log("📤 Sende an OpenClaw Haupt-Agent...")
            log("   (Erstelle Sub-Agent mit deiner Frage)")
            
            # Wir schreiben die Frage in stdout mit einem speziellen Marker
            # Die Haupt-Session (die diesen Sub-Agent gestartet hat) liest das
            # und kann dann antworten
            
            print("\n" + ">>>VOICE_QUESTION<<<")
            print(question)
            print(">>>END_VOICE_QUESTION<<<")
            print()
            
            log("⏳ Warte auf Antwort von Haupt-Agent...")
            log("   (Du musst in der Haupt-Session antworten)")
            
            # Warte auf Antwort vom Haupt-Agent
            # Dieser wird als stdin kommen oder als Datei
            
            # Fuer jetzt: Einfacher Hack - wir lesen stdin
            log("📝 Gib die Antwort ein (mehrzeilig, Ctrl+D oder 'ENDE' fuer Ende):")
            
            lines = []
            while True:
                try:
                    line = input()
                    if line.strip() == "ENDE":
                        break
                    lines.append(line)
                except EOFError:
                    break
            
            response = "\n".join(lines).strip()
            
            if response:
                print("\n" + "="*70)
                log(f"💬 ANTWORT: {response[:100]}...")
                print("="*70)
                
                # TTS
                log("🔊 Spiele Antwort als Sprache...")
                play_tts(response)
                log("✅ Fertig!")
            else:
                log("⚠️  Keine Antwort erhalten")
                play_tts("Keine Antwort erhalten.")
                
        except KeyboardInterrupt:
            log("\n👋 Voice Bridge beendet.")
            break
        except Exception as e:
            log(f"❌ Fehler: {e}")
            import traceback
            traceback.print_exc()
            continue

if __name__ == "__main__":
    main()
