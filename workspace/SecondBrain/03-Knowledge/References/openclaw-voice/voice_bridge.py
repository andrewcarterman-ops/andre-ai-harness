#!/usr/bin/env python3
"""
OpenClaw Voice Bridge - Lokales TTS/STT Setup
=============================================

Funktionen:
- Push-to-Talk (F12) oder Toggle-Modus
- STT mit Whisper.cpp
- LLM mit llama.cpp (lokal)
- TTS mit Piper
- Visuelles Status-Feedback

Hardware-Optimierung für: i7-6820HK + GTX 980M (8GB VRAM)
"""

import os
import sys
import time
import json
import wave
import tempfile
import subprocess
import threading
import requests
from pathlib import Path
from dataclasses import dataclass
from typing import Optional, Callable

# Audio
import pyaudio
import numpy as np

# Hotkeys
import keyboard

# Visual Feedback
import tkinter as tk
from tkinter import ttk


@dataclass
class VoiceConfig:
    """Konfiguration für Voice Bridge"""
    # Pfade
    whisper_exe: str = "whisper/main.exe"
    whisper_model: str = "models/ggml-medium.bin"
    llama_server: str = "llama/llama-server.exe"
    llama_model: str = "models/Llama-3.1-8B-Instruct-Q4_K_M.gguf"
    piper_exe: str = "piper/piper.exe"
    piper_model: str = "models/de_DE-thorsten-high.onnx"
    
    # Audio
    sample_rate: int = 16000
    channels: int = 1
    chunk_size: int = 1024
    
    # Hotkeys
    ptt_key: str = "f12"
    exit_key: str = "esc"
    
    # Verhalten
    toggle_mode: bool = True  # True = Toggle, False = Hold-to-talk
    save_recordings: bool = False
    
    # LLM
    llama_host: str = "localhost"
    llama_port: int = 8080
    max_tokens: int = 512
    temperature: float = 0.7
    
    # Sprache
    language: str = "de"  # "de" oder "en"
    
    # Visual
    show_overlay: bool = True


class AudioRecorder:
    """Audio-Aufnahme mit Pyaudio"""
    
    def __init__(self, config: VoiceConfig):
        self.config = config
        self.audio = pyaudio.PyAudio()
        self.stream = None
        self.frames = []
        self.is_recording = False
        
    def start_recording(self):
        """Starte Audio-Aufnahme"""
        self.frames = []
        self.is_recording = True
        
        self.stream = self.audio.open(
            format=pyaudio.paInt16,
            channels=self.config.channels,
            rate=self.config.sample_rate,
            input=True,
            frames_per_buffer=self.config.chunk_size,
            stream_callback=self._callback
        )
        
    def _callback(self, in_data, frame_count, time_info, status):
        """Callback für Audio-Stream"""
        if self.is_recording:
            self.frames.append(in_data)
        return (in_data, pyaudio.paContinue)
    
    def stop_recording(self) -> str:
        """Stoppe Aufnahme und speichere WAV-Datei"""
        self.is_recording = False
        
        if self.stream:
            self.stream.stop_stream()
            self.stream.close()
            
        # Speichere als WAV
        wav_path = os.path.join(tempfile.gettempdir(), "voice_input.wav")
        
        with wave.open(wav_path, 'wb') as wf:
            wf.setnchannels(self.config.channels)
            wf.setsampwidth(self.audio.get_sample_size(pyaudio.paInt16))
            wf.setframerate(self.config.sample_rate)
            wf.writeframes(b''.join(self.frames))
            
        return wav_path
    
    def cleanup(self):
        """Aufräumen"""
        if self.stream:
            self.stream.close()
        self.audio.terminate()


class WhisperSTT:
    """Speech-to-Text mit Whisper.cpp"""
    
    def __init__(self, config: VoiceConfig):
        self.config = config
        
    def transcribe(self, wav_path: str) -> Optional[str]:
        """Transkribiere Audio-Datei"""
        if not os.path.exists(self.config.whisper_exe):
            print(f"❌ Whisper nicht gefunden: {self.config.whisper_exe}")
            return None
            
        if not os.path.exists(self.config.whisper_model):
            print(f"❌ Whisper-Modell nicht gefunden: {self.config.whisper_model}")
            return None
        
        cmd = [
            self.config.whisper_exe,
            "-m", self.config.whisper_model,
            "-f", wav_path,
            "-l", self.config.language,
            "--output-txt",
            "-of", os.path.join(tempfile.gettempdir(), "transcription")
        ]
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                txt_path = os.path.join(tempfile.gettempdir(), "transcription.txt")
                if os.path.exists(txt_path):
                    with open(txt_path, 'r', encoding='utf-8') as f:
                        text = f.read().strip()
                    return text
            else:
                print(f"Whisper Fehler: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            print("❌ Whisper Timeout")
        except Exception as e:
            print(f"❌ Whisper Fehler: {e}")
            
        return None


class LlamaLLM:
    """Lokales LLM mit llama.cpp Server"""
    
    def __init__(self, config: VoiceConfig):
        self.config = config
        self.server_process = None
        self.server_url = f"http://{config.llama_host}:{config.llama_port}"
        
    def start_server(self) -> bool:
        """Starte llama-server"""
        if not os.path.exists(self.config.llama_server):
            print(f"❌ llama-server nicht gefunden: {self.config.llama_server}")
            return False
            
        if not os.path.exists(self.config.llama_model):
            print(f"❌ LLM-Modell nicht gefunden: {self.config.llama_model}")
            return False
        
        cmd = [
            self.config.llama_server,
            "-m", self.config.llama_model,
            "--host", self.config.llama_host,
            "--port", str(self.config.llama_port),
            "-c", "8192",  # Kontext-Länge
            "-ngl", "99",  # Alle Layer auf GPU
            "--timeout", "300"
        ]
        
        try:
            self.server_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # Warte auf Server-Start
            print("🚀 Starte LLM-Server...")
            time.sleep(3)
            
            # Prüfe ob Server läuft
            if self._is_server_ready():
                print("✅ LLM-Server bereit")
                return True
            else:
                print("❌ LLM-Server konnte nicht gestartet werden")
                return False
                
        except Exception as e:
            print(f"❌ Fehler beim Starten: {e}")
            return False
    
    def _is_server_ready(self) -> bool:
        """Prüfe ob Server bereit ist"""
        try:
            response = requests.get(f"{self.server_url}/health", timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def generate(self, prompt: str) -> Optional[str]:
        """Generiere Antwort"""
        if not self._is_server_ready():
            print("❌ LLM-Server nicht bereit")
            return None
        
        # Llama 3.1 Chat-Format
        messages = [
            {"role": "system", "content": "Du bist ein hilfreicher Assistent. Antworte kurz und prägnant auf Deutsch."},
            {"role": "user", "content": prompt}
        ]
        
        payload = {
            "messages": messages,
            "temperature": self.config.temperature,
            "max_tokens": self.config.max_tokens,
            "stream": False
        }
        
        try:
            response = requests.post(
                f"{self.server_url}/v1/chat/completions",
                json=payload,
                timeout=60
            )
            
            if response.status_code == 200:
                data = response.json()
                return data['choices'][0]['message']['content']
            else:
                print(f"❌ LLM Fehler: {response.status_code}")
                
        except requests.Timeout:
            print("❌ LLM Timeout")
        except Exception as e:
            print(f"❌ LLM Fehler: {e}")
            
        return None
    
    def stop_server(self):
        """Stoppe LLM-Server"""
        if self.server_process:
            self.server_process.terminate()
            self.server_process.wait()
            print("🛑 LLM-Server gestoppt")


class PiperTTS:
    """Text-to-Speech mit Piper"""
    
    def __init__(self, config: VoiceConfig):
        self.config = config
        
    def speak(self, text: str) -> bool:
        """Synthetisiere und spiele Audio ab"""
        if not os.path.exists(self.config.piper_exe):
            print(f"❌ Piper nicht gefunden: {self.config.piper_exe}")
            return False
            
        if not os.path.exists(self.config.piper_model):
            print(f"❌ Piper-Modell nicht gefunden: {self.config.piper_model}")
            return False
        
        wav_path = os.path.join(tempfile.gettempdir(), "tts_output.wav")
        
        cmd = [
            self.config.piper_exe,
            "--model", self.config.piper_model,
            "--output_file", wav_path
        ]
        
        try:
            # Starte Piper-Prozess
            proc = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Sende Text
            proc.stdin.write(text)
            proc.stdin.close()
            proc.wait(timeout=30)
            
            if os.path.exists(wav_path):
                # Spiele Audio ab
                self._play_audio(wav_path)
                return True
            else:
                print("❌ TTS-Audio nicht erstellt")
                
        except subprocess.TimeoutExpired:
            print("❌ Piper Timeout")
        except Exception as e:
            print(f"❌ Piper Fehler: {e}")
            
        return False
    
    def _play_audio(self, wav_path: str):
        """Spiele WAV-Datei ab"""
        # Versuche Windows Media Player
        try:
            os.system(f'start /min "" "{wav_path}"')
        except:
            # Fallback: ffplay oder aplay
            try:
                subprocess.run(["ffplay", "-nodisp", "-autoexit", wav_path], 
                             capture_output=True, timeout=60)
            except:
                print(f"⚠️ Konnte Audio nicht abspielen: {wav_path}")


class StatusOverlay:
    """Visuelles Status-Feedback"""
    
    def __init__(self):
        self.root = None
        self.label = None
        self.status_var = None
        self.running = False
        
    def start(self):
        """Starte Overlay in separatem Thread"""
        self.thread = threading.Thread(target=self._run, daemon=True)
        self.thread.start()
        
    def _run(self):
        """Tkinter Hauptloop"""
        self.root = tk.Tk()
        self.root.title("OpenClaw Voice")
        self.root.geometry("300x100")
        self.root.attributes('-topmost', True)
        self.root.resizable(False, False)
        
        # Styling
        self.root.configure(bg='#1e1e1e')
        
        self.status_var = tk.StringVar(value="🎙️ Bereit (F12)")
        
        self.label = tk.Label(
            self.root,
            textvariable=self.status_var,
            font=('Segoe UI', 14, 'bold'),
            bg='#1e1e1e',
            fg='#00ff00',
            pady=20
        )
        self.label.pack(expand=True)
        
        # Status-Indikator
        self.canvas = tk.Canvas(self.root, width=20, height=20, bg='#1e1e1e', highlightthickness=0)
        self.canvas.place(x=10, y=10)
        self.indicator = self.canvas.create_oval(2, 2, 18, 18, fill='gray')
        
        self.running = True
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)
        self.root.mainloop()
        
    def _on_close(self):
        self.running = False
        self.root.destroy()
        
    def set_status(self, status: str, color: str = "gray"):
        """Aktualisiere Status"""
        if self.root and self.running:
            self.root.after(0, lambda: self._update_ui(status, color))
            
    def _update_ui(self, status: str, color: str):
        """UI-Update im Main-Thread"""
        if self.status_var:
            self.status_var.set(status)
        if self.canvas:
            self.canvas.itemconfig(self.indicator, fill=color)
            
    def stop(self):
        """Stoppe Overlay"""
        if self.root:
            self.root.after(0, self.root.destroy)


class VoiceBridge:
    """Hauptklasse für Voice Bridge"""
    
    def __init__(self, config: VoiceConfig):
        self.config = config
        self.recorder = AudioRecorder(config)
        self.stt = WhisperSTT(config)
        self.llm = LlamaLLM(config)
        self.tts = PiperTTS(config)
        self.overlay = StatusOverlay() if config.show_overlay else None
        
        self.is_listening = False
        self.is_processing = False
        self.running = False
        
    def start(self):
        """Starte Voice Bridge"""
        print("=" * 60)
        print("🎙️  OpenClaw Voice Bridge")
        print("=" * 60)
        print(f"PTT-Taste: {self.config.ptt_key.upper()}")
        print(f"Modus: {'Toggle' if self.config.toggle_mode else 'Hold-to-Talk'}")
        print(f"Sprache: {self.config.language}")
        print(f"Beenden: {self.config.exit_key.upper()}")
        print("=" * 60)
        
        # Starte LLM-Server
        if not self.llm.start_server():
            print("❌ Konnte LLM-Server nicht starten")
            return
        
        # Starte Overlay
        if self.overlay:
            self.overlay.start()
            time.sleep(0.5)  # Warte auf Fenster
        
        # Registriere Hotkeys
        keyboard.on_press_key(self.config.ptt_key, self._on_ptt_press)
        if self.config.toggle_mode:
            keyboard.on_release_key(self.config.ptt_key, self._on_ptt_release)
        keyboard.on_press_key(self.config.exit_key, self._on_exit)
        
        self.running = True
        
        # Hauptloop
        try:
            while self.running:
                time.sleep(0.1)
        except KeyboardInterrupt:
            pass
        finally:
            self.stop()
    
    def _on_ptt_press(self, event):
        """PTT-Taste gedrückt"""
        if self.is_processing:
            return
            
        if self.config.toggle_mode:
            # Toggle-Modus
            if self.is_listening:
                self._stop_listening()
            else:
                self._start_listening()
        else:
            # Hold-to-Talk
            self._start_listening()
    
    def _on_ptt_release(self, event):
        """PTT-Taste losgelassen (nur Hold-to-Talk)"""
        if not self.config.toggle_mode and self.is_listening:
            self._stop_listening()
    
    def _start_listening(self):
        """Starte Aufnahme"""
        if self.is_listening:
            return
            
        print("🔴 Höre zu...")
        self.is_listening = True
        
        if self.overlay:
            self.overlay.set_status("🔴 Höre zu... (F12 zum Beenden)", "red")
            
        self.recorder.start_recording()
    
    def _stop_listening(self):
        """Stoppe Aufnahme und verarbeite"""
        if not self.is_listening:
            return
            
        print("⏹️  Verarbeite...")
        self.is_listening = False
        self.is_processing = True
        
        if self.overlay:
            self.overlay.set_status("⏳ Verarbeite...", "yellow")
        
        # Stoppe Aufnahme
        wav_path = self.recorder.stop_recording()
        
        # Verarbeite in separatem Thread
        thread = threading.Thread(target=self._process_audio, args=(wav_path,))
        thread.start()
    
    def _process_audio(self, wav_path: str):
        """Verarbeite Audio: STT -> LLM -> TTS"""
        try:
            # 1. STT
            print("📝 Transkribiere...")
            text = self.stt.transcribe(wav_path)
            
            if not text:
                print("❌ Keine Sprache erkannt")
                if self.overlay:
                    self.overlay.set_status("❌ Nicht verstanden", "orange")
                time.sleep(2)
                return
                
            print(f"🗣️  Du: {text}")
            
            # 2. LLM
            print("🤔 Denke nach...")
            if self.overlay:
                self.overlay.set_status("🤔 Denke nach...", "blue")
                
            response = self.llm.generate(text)
            
            if not response:
                print("❌ Keine Antwort vom LLM")
                if self.overlay:
                    self.overlay.set_status("❌ LLM-Fehler", "orange")
                time.sleep(2)
                return
                
            print(f"🤖 Assistent: {response}")
            
            # 3. TTS
            print("🔊 Spreche...")
            if self.overlay:
                self.overlay.set_status("🔊 Spreche...", "green")
                
            self.tts.speak(response)
            
        except Exception as e:
            print(f"❌ Fehler: {e}")
            if self.overlay:
                self.overlay.set_status(f"❌ Fehler", "red")
        finally:
            self.is_processing = False
            if self.overlay:
                self.overlay.set_status("🎙️ Bereit (F12)", "gray")
    
    def _on_exit(self, event):
        """Beenden"""
        print("\n👋 Beende...")
        self.running = False
    
    def stop(self):
        """Aufräumen"""
        self.running = False
        
        if self.is_listening:
            self.recorder.stop_recording()
        
        self.recorder.cleanup()
        self.llm.stop_server()
        
        if self.overlay:
            self.overlay.stop()
        
        keyboard.unhook_all()
        print("✅ Voice Bridge beendet")


def main():
    """Haupteinstiegspunkt"""
    config = VoiceConfig()
    
    # Lade Konfiguration aus Datei falls vorhanden
    config_path = Path("voice_config.json")
    if config_path.exists():
        with open(config_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            for key, value in data.items():
                if hasattr(config, key):
                    setattr(config, key, value)
        print(f"📄 Konfiguration geladen: {config_path}")
    
    # Starte Voice Bridge
    bridge = VoiceBridge(config)
    bridge.start()


if __name__ == "__main__":
    main()
