#!/usr/bin/env python3
"""
Voice Bridge - Direct LLM Integration

Workflow:
    1. ENTER -> Sprechen -> ENTER
    2. Transkription mit Whisper
    3. Text wird an OpenClaw Session gesendet (LLM Verarbeitung)
    4. LLM Antwort empfangen
    5. TTS generieren und abspielen

Usage:
    python voice_bridge_llm.py [--session-key SESSION_KEY]
    
Beispiel:
    python voice_bridge_llm.py --session-key agent:main:tui-xxxxx
"""

import sys
import time
import tempfile
import wave
import subprocess
import json
import argparse
from pathlib import Path
from datetime import datetime

import numpy as np
import sounddevice as sd

# Pfade
TRANSCRIBE_SCRIPT = Path.home() / ".openclaw" / "workspace" / "skills" / "whisper-local-stt" / "scripts" / "transcribe.py"
PIPER_EXE = Path.home() / ".openclaw" / "piper" / "piper" / "piper.exe"
PIPER_MODEL = Path.home() / ".openclaw" / "piper" / "models" / "de_DE-thorsten-high.onnx"

def record_audio():
    """Nimmt Audio auf bis ENTER gedrueckt wird"""
    print("\n[DRUCKE ENTER UND SPRICH...]")
    input()
    
    print("\n[🔴 NIMMT AUF... sprich jetzt!]")
    print("[DRUCKE ENTER WENN DU FERTIG BIST...]")
    
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
    
    input()
    
    stream.stop()
    stream.close()
    
    if not recording:
        print("[❌ Keine Aufnahme!]")
        return None
    
    audio = np.concatenate(recording, axis=0)
    duration = len(audio) / 16000
    
    wav_path = Path(tempfile.gettempdir()) / f"voice_{int(time.time())}.wav"
    with wave.open(str(wav_path), 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(audio.tobytes())
    
    print(f"[✅ Aufnahme: {duration:.1f}s]")
    return wav_path

def transcribe(wav_path):
    """Nutzt transcribe.py fuer Transkription"""
    print("[🔄 Transkribiere...]")
    
    result = subprocess.run(
        [sys.executable, str(TRANSCRIBE_SCRIPT), str(wav_path)],
        capture_output=True,
        text=True,
        timeout=120
    )
    
    text = result.stdout.strip()
    # Filtere Debug-Output raus
    lines = [l for l in text.split('\n') if l.strip() and not l.startswith('🔧') and not l.startswith('⚙️')]
    if lines:
        return lines[-1].strip()
    return "[Kein Text erkannt]"

def send_to_llm(text, session_key):
    """
    Sendet Text an OpenClaw Session und wartet auf Antwort.
    Nutzt openclaw CLI sessions send.
    """
    print(f"\n[📤 Sende an Andrew...]")
    print(f"   Du: {text[:60]}..." if len(text) > 60 else f"   Du: {text}")
    
    try:
        # Nutze openclaw CLI
        cmd = [
            "openclaw", "sessions", "send",
            "--message", text,
            "--timeout", "45"
        ]
        
        if session_key:
            cmd.extend(["--session-key", session_key])
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=50
        )
        
        if result.returncode == 0:
            response = result.stdout.strip()
            return response
        else:
            error = result.stderr.strip() if result.stderr else "Unbekannter Fehler"
            print(f"[⚠️ OpenClaw Fehler: {error}]")
            return None
            
    except subprocess.TimeoutExpired:
        print("[⚠️ Timeout - Andrew hat zu lange gebraucht]")
        return None
    except FileNotFoundError:
        print("[❌ OpenClaw CLI nicht gefunden]")
        print("   Ist 'openclaw' im PATH?")
        return None
    except Exception as e:
        print(f"[⚠️ Fehler: {e}]")
        return None

def generate_tts(text, output_path):
    """Generiert TTS mit Piper"""
    print("[🎵 Generiere Sprache...]")
    
    result = subprocess.run(
        [str(PIPER_EXE), "--model", str(PIPER_MODEL), "--output_file", str(output_path)],
        input=text.encode('utf-8'),
        capture_output=True,
        timeout=60
    )
    
    return result.returncode == 0 and output_path.exists()

def play_audio(wav_path):
    """Spielt Audio direkt auf dem PC ab"""
    print("[🔊 Spiele Antwort ab...]")
    
    try:
        with wave.open(str(wav_path), 'rb') as wf:
            frames = wf.readframes(wf.getnframes())
            rate = wf.getframerate()
            audio = np.frombuffer(frames, dtype=np.int16)
            sd.play(audio, rate)
            sd.wait()
        
        print("[✅ Fertig!]")
        return True
        
    except Exception as e:
        print(f"[⚠️ Fehler beim Abspielen: {e}]")
        return False

def main():
    parser = argparse.ArgumentParser(description="Voice Bridge - Direct LLM Integration")
    parser.add_argument("--session-key", help="OpenClaw Session Key (optional)")
    args = parser.parse_args()
    
    print("\n" + "="*60)
    print("🎙️  VOICE BRIDGE - Direct LLM Integration")
    print("="*60)
    print("\nWorkflow:")
    print("  1. ENTER → Sprechen → ENTER")
    print("  2. Transkription (Whisper)")
    print("  3. Text → Andrew (LLM)")
    print("  4. Antwort → TTS")
    print("  5. Audio wird abgespielt!")
    print("\n[Druecke Ctrl+C zum Beenden]")
    print("="*60)
    
    # Pruefe Voraussetzungen
    if not PIPER_EXE.exists():
        print(f"\n[❌ Piper nicht gefunden: {PIPER_EXE}]")
        print("   Bitte installiere Piper TTS zuerst")
        return
    
    if not TRANSCRIBE_SCRIPT.exists():
        print(f"\n[❌ Transcribe Script nicht gefunden: {TRANSCRIBE_SCRIPT}]")
        return
    
    print("\n[✅ Alle Komponenten gefunden!]")
    if args.session_key:
        print(f"[🔗 Session: {args.session_key}]")
    else:
        print("[🔗 Session: Auto (letzte aktive)]")
    
    while True:
        try:
            # 1. Aufnahme
            wav_path = record_audio()
            if not wav_path:
                continue
            
            # 2. Transkription
            user_text = transcribe(wav_path)
            
            # Cleanup
            try:
                wav_path.unlink()
            except:
                pass
            
            if user_text == "[Kein Text erkannt]":
                print("[❌ Nichts verstanden, versuch es nochmal]")
                continue
            
            print(f"\n[📝 Transkribiert]: {user_text}")
            
            # 3. An LLM senden und Antwort empfangen
            print("\n" + "-"*60)
            llm_response = send_to_llm(user_text, args.session_key)
            
            if not llm_response:
                print("[❌ Keine Antwort erhalten]")
                continue
            
            print(f"\n[💬 Andrew]: {llm_response}")
            print("-"*60)
            
            # 4. TTS generieren
            tts_path = Path(tempfile.gettempdir()) / f"tts_{int(time.time())}.wav"
            
            if generate_tts(llm_response, tts_path):
                # 5. Abspielen
                play_audio(tts_path)
                
                # Cleanup
                try:
                    tts_path.unlink()
                except:
                    pass
            else:
                print("[❌ TTS Fehler]")
            
        except KeyboardInterrupt:
            print("\n\n[👋 Beendet. Bis bald!]")
            break
        except Exception as e:
            print(f"\n[❌ Fehler: {e}]")
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    main()
