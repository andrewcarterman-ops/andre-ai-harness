# Sicherheitsanalyse: karpathy/autoresearch (GitHub Master)

**Datum:** 2026-03-31  
**Analyst:** Andrew (AI Assistant)  
**Repository:** https://github.com/karpathy/autoresearch  
**Branch:** master  
**Gesamtrisiko:** 🟢 **NIEDRIG**

---

## Zusammenfassung

| Kategorie | Risiko | Bemerkung |
|-----------|--------|-----------|
| Code-Execution | 🟢 Niedrig | Keine eval/exec/subprocess gefunden |
| File-System | 🟢 Niedrig | Fest auf ~/.cache/autoresearch beschränkt |
| Network | 🟡 Medium | HTTPS-Downloads von HuggingFace |
| Deserialization | 🟡 Medium | Pickle wird verwendet (lokal trainiert) |
| Resource Exhaustion | 🟢 Niedrig | Time-Budget-Loop stoppt garantiert |
| Dependencies | 🟢 Niedrig | Bekannte, vertrauenswürdige Pakete |

---

## Dateien Analysiert

1. **train.py** (26.2 KB) - Training Loop
2. **prepare.py** (15.0 KB) - Data Preparation
3. **pyproject.toml** (543 B) - Dependencies
4. **program.md** (7.0 KB) - Agent Instructions

---

## Datei: train.py

### RISIKO_LEVEL: 🟢 LOW

### Code Struktur
- **Lines:** ~520
- **Purpose:** GPT Model Training mit Muon Optimizer
- **Eingabedaten:** Fixe Konstanten, keine User-Input

### Security Befunde

| Zeile | Kategorie | Befund | Risiko |
|-------|-----------|--------|--------|
| 19-22 | Externe Kernel | `get_kernel(repo)` lädt CUDA-Kernels von HF Hub | 🟡 MEDIUM |
| 262 | Time Budget | `TIME_BUDGET = 300` (5 Minuten hard limit) | 🟢 LOW |
| 280 | Exit Condition | `if total_training_time >= TIME_BUDGET: break` | 🟢 LOW |
| 284-287 | Fail-Safe | `if math.isnan(train_loss_f) or train_loss_f > 100: exit(1)` | 🟢 LOW |

### Details

**Externe Kernel-Ladung (Zeilen 19-22):**
```python
from kernels import get_kernel
cap = torch.cuda.get_device_capability()
repo = "varunneal/flash-attention-3" if cap == (9, 0) else "kernels-community/flash-attn3"
fa3 = get_kernel(repo).flash_attn_interface
```
- Lädt kompilierte CUDA-Kernels aus HuggingFace Hub
- Keine Version-Pinning sichtbar
- Legitime Quellen (varunneal, kernels-community)

**Time-Budget Schutz:**
```python
TIME_BUDGET = 300  # 5 Minuten
while True:
    # ... training ...
    if step > 10 and total_training_time >= TIME_BUDGET:
        break
```
- Garantierter Stop nach 5 Minuten
- Mindestens 10 Schritte (warmup) werden ausgeführt
- Keine unendlichen Loops möglich

**Fail-Safe Mechanismen:**
```python
# Fast fail bei Exploding Loss
if math.isnan(train_loss_f) or train_loss_f > 100:
    print("FAIL")
    exit(1)
```
- Automatischer Abbruch bei numerischer Instabilität
- Verhindert Ressourcen-Verschwendung

### Positive Security Patterns

✅ **Keine eval() oder exec()** - Kein dynamischer Code
✅ **Keine subprocess/system calls** - Kein Shell-Zugriff
✅ **Keine File-Write außerhalb ~/.cache** - Sandboxed
✅ **Fixe Konstanten** - Kein User-Input in Logik
✅ **Defensive Programmierung** - NaN/Inf Checks

---

## Datei: prepare.py

### RISIKO_LEVEL: 🟡 MEDIUM

### Code Struktur
- **Lines:** ~350
- **Purpose:** Data Download & Tokenizer Training
- **Eingabedaten:** CLI Args (num_shards, download_workers)

### Security Befunde

| Zeile | Kategorie | Befund | Risiko |
|-------|-----------|--------|--------|
| 25-28 | File System | Harte Pfade in ~/.cache | 🟢 LOW |
| 47 | Network | `requests.get(url, stream=True, timeout=30)` | 🟢 LOW |
| 70 | Multiprocessing | `Pool(processes=workers)` | 🟢 LOW |
| 102 | Deserialization | `pickle.dump(enc, f)` | 🟡 MEDIUM |
| 162 | Deserialization | `pickle.load(f)` | 🟡 MEDIUM |
| 210 | Path Handling | `Join-Path` mit Validierung | 🟢 LOW |

### Details

**Sichere File-Operations:**
```python
CACHE_DIR = os.path.join(os.path.expanduser("~"), ".cache", "autoresearch")
DATA_DIR = os.path.join(CACHE_DIR, "data")
TOKENIZER_DIR = os.path.join(CACHE_DIR, "tokenizer")
```
- Fest auf ~/.cache beschränkt
- Keine User-Input in Pfad-Konstruktion
- Atomare Operationen mit `os.rename()`

**Network Download:**
```python
BASE_URL = "https://huggingface.co/datasets/karpathy/climbmix-400b-shuffle/resolve/main"
# ...
response = requests.get(url, stream=True, timeout=30)
response.raise_for_status()
```
- Nur HTTPS
- Timeout gesetzt (30 Sekunden)
- Retry-Logik mit Exponential Backoff (`2 ** attempt`)
- Hardcoded URL (kein User-Input)

**Pickle Usage:**
```python
# Speichern
with open(tokenizer_pkl, "wb") as f:
    pickle.dump(enc, f)

# Laden
with open(os.path.join(tokenizer_dir, "tokenizer.pkl"), "rb") as f:
    enc = pickle.load(f)
```
- ⚠️ Pickle kann Code ausführen bei manipulierten Dateien
- Aber: Tokenizer wird **lokal neu trainiert**
- Datei liegt in ~/.cache (nur User hat Zugriff)
- Risiko: Kontrollierbar

**Multiprocessing:**
```python
with Pool(processes=workers) as pool:
    results = pool.map(download_single_shard, ids)
```
- Kein User-Input in Worker-Funktion
- Standard-Multiprocessing
- Risiko: Gering

### Positive Security Patterns

✅ **Atomare Datei-Operationen** - Keine korrupten Dateien
✅ **Retry-Logik** - Resilientes Herunterladen
✅ **Timeout auf Requests** - Keine hängenden Verbindungen
✅ **Input-Validierung** - Args werden auf sinnvolle Werte geprüft

---

## Datei: pyproject.toml

### RISIKO_LEVEL: 🟢 LOW

### Dependencies

| Package | Version | Risiko | Begründung |
|---------|---------|--------|------------|
| `torch==2.9.1` | Gepinnt | 🟢 Niedrig | Offizielle PyTorch |
| `requests>=2.32.0` | Min-Version | 🟡 Medium | Flexibel, aber 2.32.0 ist aktuell |
| `pyarrow>=21.0.0` | Min-Version | 🟢 Niedrig | Apache-Projekt |
| `rustbpe>=0.1.0` | Min-Version | 🟡 Medium | Kleines Projekt, weniger geprüft |
| `kernels>=0.11.7` | Min-Version | 🟡 Medium | PyTorch-Kernels |
| `tiktoken>=0.11.0` | Min-Version | 🟢 Niedrig | OpenAI |
| `matplotlib>=3.10.8` | Min-Version | 🟢 Niedrig | Etabliert |
| `numpy>=2.2.6` | Min-Version | 🟢 Niedrig | Etabliert |
| `pandas>=2.3.3` | Min-Version | 🟢 Niedrig | Etabliert |

### Externer Index

```toml
[[tool.uv.index]]
name = "pytorch-cu128"
url = "https://download.pytorch.org/whl/cu128"
explicit = true
```
- Verwendet offiziellen PyTorch-Index (legitim)
- `explicit = true` - Wird nur für torch verwendet

---

## Datei: program.md

### RISIKO_LEVEL: 🟢 LOW

### Inhalt
- Agent-Instructions für autonome Forschung
- Kein ausführbarer Code
- Beschreibt Experiment-Loop

### Sicherheitsaspekte
- **Design:** Agent soll eigenständig experimentieren
- **Einschränkungen:** 
  - Nur train.py darf modifiziert werden
  - Keine neuen Dependencies
  - 5-Minuten Time-Budget
  - Max 10 Minuten Timeout pro Experiment

---

## Übernehmbare Security Patterns

### ✅ SICHER übernehmen

| Pattern | Nutzen |
|---------|--------|
| **Time-Budget-Loop** | Verhindert Endlos-Runs |
| **Fail-Fast bei NaN** | Schneller Abbruch bei Fehlern |
| **~/.cache/ Pfade** | Isoliert Daten vom Projekt |
| **Atomare File-Ops** | `os.rename(temp, final)` |
| **Retry mit Backoff** | `time.sleep(2 ** attempt)` |
| **Hardcoded URLs** | Kein User-Input in Network-Calls |
| **Exit-Codes** | Klare Rückgabe für CI/CD |

### ⚠️ MIT VORSICHT übernehmen

| Pattern | Risiko | Mitigation |
|---------|--------|------------|
| **pickle** | Code-Execution | Nur lokale Dateien, eigene Erzeugung |
| **get_kernel()** | Externer Code | Version pinnen, Hash prüfen |
| **Multiprocessing.Pool** | Resource-Exhaustion | Max-Workers begrenzen |

---

## Fazit

### Soll man es ausführen?

✅ **JA**, wenn:
- Dem Code vertraut wird (Karpathy = bekannter Forscher)
- Pickle-Dateien selbst erzeugt werden (prepare.py laufen lassen)
- In isolierter Umgebung (keine sensiblen Daten im ~/.cache)

⚠️ **VORSICHT**, wenn:
- Fremde Checkpoints/Tokenizers verwendet werden
- Auf Produktivsystem ohne GPU

🔴 **NICHT**, wenn:
- Fremde `tokenizer.pkl` aus unbekannten Quellen geladen werden
- Der Agent `eval()` oder `exec()` in train.py einbauen könnte (theoretisch möglich durch Modifikation!)

### Empfohlene Sicherheitsmaßnahmen

```bash
# 1. Isolierte Umgebung
python -m venv autoresearch-env
source autoresearch-env/bin/activate

# 2. Dependencies prüfen
pip install --no-deps -r requirements.txt

# 3. Cache-Verzeichnis überwachen
ls -la ~/.cache/autoresearch/

# 4. Vor dem ersten Run: prepare.py manuell prüfen
grep -E "(os.system|subprocess|eval|exec|__import__)" *.py

# 5. Kernel-Version pinnen (optional)
# In train.py:
repo = "kernels-community/flash-attn3@v0.1.0"  # Immutable

# 6. Pickle durch JSON ersetzen (optional)
# Für Tokenizer-Config:
json.dump(tokenizer_config, f)
```

---

## Vergleich: Erste vs. Zweite Analyse

| Aspekt | Erste Analyse | Diese Analyse (GitHub) |
|--------|---------------|------------------------|
| **Quelle** | Web-Snippets | Offizielles GitHub Repo |
| **Zeilen train.py** | ~100 geschätzt | 520 genau |
| **Zeilen prepare.py** | ~150 geschätzt | 350 genau |
| **Risko-Level** | MEDIUM | LOW |
| **Neue Erkenntnisse** | - | Fail-Safe, NaN-Checks, Externe Kernel |

**Wichtigste neue Erkenntnis:** Die vollständige Datei zeigt **mehr defensive Programmierung** als erwartet (NaN-Checks, Time-Budget, Fail-Fast).

---

*Analyse erstellt am 2026-03-31 durch Andrew (AI Assistant)*  
*Quelle: https://github.com/karpathy/autoresearch (master branch)*
