# SYSTEMSPEZIFIKATIONEN - Parzival

**Datum:** 2026-04-09

**WICHTIG:** Diese Info ist relevant für alle AI/Performance-Empfehlungen!

---

## Technologie-Stack (OpenClaw AI Harness)

| Komponente | Technologie | Notiz |
|------------|-------------|-------|
| **OpenClaw Gateway** | Rust | Core-System |
| **MCP Server** | Rust/Node.js | Model Context Protocol |
| **TUI** | Rust | Terminal Interface |
| **Session Management** | Rust | Agent-Isolation |
| **Cron/Scheduler** | Rust | Automatisierung |

**Implikation:** Rust-basiertes System = Hohe Performance, Speichersicherheit, keine GC-Pausen.

---

## Hardware

## Hardware

| Komponente | Spezifikation |
|------------|---------------|
| **CPU** | Intel Core i7-6820HK @ 2.70GHz (4 Kerne/8 Threads) |
| **RAM** | 32 GB DDR4 |
| **Speicher** | 1TB Samsung SSD 860 EVO (932 GB nutzbar) |
| **GPU** | NVIDIA GeForce GTX 980M (8 GB VRAM) |
| **iGPU** | Intel HD Graphics 530 |
| **System** | Windows 10/11 64-bit |

## Kritische Einschränkungen

- **KEIN H100/A100!** Nur GTX 980M (4GB effektiv nutzbar wegen Shared Memory)
- **RAM:** 32GB gut für LLM-Hosting (gguf-Modelle bis ~13B Parameter möglich)
- **SSD:** 1TB ausreichend, aber keine riesigen Modelle (70B+ zu groß)

## Implikationen für AI-Workloads

### ✅ Funktioniert:
- Local LLMs bis ~13B Parameter (GGUF/Q4)
- Stable Diffusion (CPU oder 980M)
- Code-Generierung via API (Claude, OpenAI)
- Unser SecondBrain System
- ECC Autoresearch (kleine Modelle)

### ❌ Nicht möglich:
- Große LLMs (70B+) lokal
- H100-optimierte Workflows
- Große Batch-Training-Jobs
- CUDA-intensive Anwendungen (alte Architektur)

## Empfohlene lokale Modelle

1. **Llama 3.1 8B Q4** - Für lokale Inferenz
2. **Qwen 2.5 7B** - Alternative
3. **Mistral 7B** - Gut für Coding

## Speicherplatz

- **Gesamt:** 1TB SSD
- **Genutzt:** Vault-Archive hat viele Dateien
- **Verfügbar:** Ausreichend für SecondBrain

**Merke:** Bei AI-Empfehlungen immer auf GTX 980M (4GB effektiv) und 32GB RAM achten!
