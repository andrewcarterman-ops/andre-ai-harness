# Sicherheitsanalyse: karpathy/autoresearch

**Datum:** 2026-03-31  
**Analyst:** Andrew (AI Assistant)  
**Repository:** https://github.com/karpathy/autoresearch  
**Gesamtrisiko:** 🟢 NIEDRIG-MEDIUM

---

## Zusammenfassung

| Kategorie | Risiko | Bemerkung |
|-----------|--------|-----------|
| Code-Execution | 🟢 Niedrig | Keine eval/exec/subprocess gefunden |
| File-System | 🟢 Niedrig | Fest auf ~/.cache/autoresearch beschränkt |
| Network | 🟡 Medium | HTTPS-Downloads von HuggingFace |
| Deserialization | 🟡 Medium | Pickle wird verwendet |
| Resource Exhaustion | 🟢 Niedrig | Time-Budget-Loop stoppt garantiert |

---

## Datei: train.py

### RISIKO_LEVEL: MEDIUM

### Befunde

| Zeile | Kategorie | Befund | Risiko |
|-------|-----------|--------|--------|
| 19 | Code Execution | `from kernels import get_kernel` | 🟡 MEDIUM |
| 21-22 | Network | Dynamischer HF Hub Repo-Download | 🟡 MEDIUM |
| ~260 | Resource | `TIME_BUDGET = 300` (5 Min) | 🟢 LOW |

### Details

**Externe Kernel-Ladung (Zeile 19-22):**
```python
from kernels import get_kernel
repo = "varunneal/flash-attention-3" if cap == (9, 0) else "kernels-community/flash-attn3"
fa3 = get_kernel(repo).flash_attn_interface
```
- Lädt kompilierte CUDA-Kernels aus HuggingFace Hub
- Keine Version-Pinning oder Checksummen-Validierung sichtbar

**Time-Budget Schutz:**
```python
TIME_BUDGET = 300  # 5 Minuten
while True:
    if total_training_time >= TIME_BUDGET:
        break
```
- Garantierter Stop nach 5 Minuten
- Keine unendlichen Loops möglich

### Empfehlungen

```python
# Kernel-Version pinnen
repo = "kernels-community/flash-attn3@v0.1.0"

# HF Hub Offline-Mode für Produktion
os.environ["HF_HUB_OFFLINE"] = "1"
```

---

## Datei: prepare.py

### RISIKO_LEVEL: MEDIUM

### Befunde

| Zeile | Kategorie | Befund | Risiko |
|-------|-----------|--------|--------|
| 25-28 | File System | Feste CACHE_DIR Pfade | 🟢 LOW |
| 47 | Network | `requests.get(url, stream=True, timeout=30)` | 🟢 LOW |
| ~70 | Multiprocessing | `Pool(processes=workers)` | 🟢 LOW |
| ~102 | Deserialization | `pickle.dump(enc, f)` | 🟡 MEDIUM |
| ~162 | Deserialization | `pickle.load(f)` | 🟡 MEDIUM |

### Details

**Sichere File-Operations:**
```python
CACHE_DIR = os.path.join(os.path.expanduser("~"), ".cache", "autoresearch")
DATA_DIR = os.path.join(CACHE_DIR, "data")

# Atomare Operation
os.rename(temp_path, filepath)
```

**Pickle-Risiko:**
```python
# Tokenizer wird mit pickle serialisiert
with open(tokenizer_pkl, "wb") as f:
    pickle.dump(enc, f)
```
- Risiko: Code-Execution bei manipulierten Dateien
- Mitigation: Tokenizer wird lokal neu trainiert, nicht heruntergeladen

**Network-Resilienz:**
```python
response = requests.get(url, stream=True, timeout=30)
# Retry-Logik mit Exponential Backoff
time.sleep(2 ** attempt)
```

### Empfehlungen

```python
# Pickle ersetzen durch JSON (für Config)
import json
json.dump(tokenizer_config, f)

# Oder torch.save mit weights_only
torch.save(obj, f, _use_new_zipfile_serialization=True)
torch.load(f, weights_only=True)
```

---

## Datei: pyproject.toml

### Dependencies

| Package | Version | Risiko | Begründung |
|---------|---------|--------|------------|
| torch==2.9.1 | Gepinnt | 🟢 Niedrig | Offizielle PyTorch |
| requests>=2.32.0 | Min-Version | 🟡 Medium | Flexibel |
| pyarrow>=21.0.0 | Min-Version | 🟢 Niedrig | Apache-Projekt |
| rustbpe>=0.1.0 | Min-Version | 🟡 Medium | Kleines Projekt |
| kernels>=0.11.7 | Min-Version | 🟡 Medium | Kompilierte Kernels |
| tiktoken>=0.11.0 | Min-Version | 🟢 Niedrig | OpenAI |

**Externer Index:**
```toml
[[tool.uv.index]]
name = "pytorch-cu128"
url = "https://download.pytorch.org/whl/cu128"
```
- Verwendet offiziellen PyTorch-Index (legitim)

---

## Übernehmbare Patterns

### ✅ SICHER übernehmen

| Pattern | Nutzen |
|---------|--------|
| Time-Budget-Loop | Verhindert Endlos-Runs |
| ~/.cache/ Pfade | Isoliert Daten |
| Atomare File-Ops | `os.rename(temp, final)` |
| Retry mit Backoff | Resilientes Downloaden |
| Hardcoded URLs | Kein User-Input in Network-Calls |

### ⚠️ MIT VORSICHT übernehmen

| Pattern | Risiko | Mitigation |
|---------|--------|------------|
| pickle | Code-Execution | Nur lokale Dateien, Hash-Check |
| Multiprocessing.Pool | Resource-Exhaustion | Max-Workers begrenzen |
| torch.compile() | Runtime-Kompilierung | Akzeptabel für lokales ML |

---

## Fazit

### Soll man es ausführen?

✅ **JA**, wenn:
- Dem Code vertraut wird (Karpathy = bekannter Forscher)
- Pickle-Dateien selbst erzeugt werden
- In isolierter Umgebung (keine sensiblen Daten im ~/.cache)

⚠️ **VORSICHT**, wenn:
- Fremde Checkpoints/Tokenizers verwendet werden
- Auf Produktivsystem ohne GPU

🔴 **NICHT**, wenn:
- Fremde `tokenizer.pkl` aus unbekannten Quellen
- Agent-Modifikationen mit eval/exec zugelassen werden

---

## Empfohlene Sicherheitsmaßnahmen

```bash
# 1. Isolierte Umgebung
python -m venv autoresearch-env
source autoresearch-env/bin/activate

# 2. Dependencies prüfen
pip install --no-deps -r requirements.txt

# 3. Cache-Verzeichnis überwachen
ls -la ~/.cache/autoresearch/

# 4. Vor dem Run prüfen
grep -E "(os.system|subprocess|eval|exec|__import__)" *.py

# 5. Pickle ersetzen
torch.save(obj, f, _use_new_zipfile_serialization=True)
torch.load(f, weights_only=True)
```

---

*Analyse erstellt am 2026-03-31 durch Andrew (AI Assistant)*
