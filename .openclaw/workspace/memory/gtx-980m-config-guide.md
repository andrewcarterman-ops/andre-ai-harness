

---

## 📝 Update (während der Session)

### Zusätzliche Änderung gefunden:

**Zeile 298 in train.py:**
```python
pin_memory=True  # War: True
# Ändern zu:
pin_memory=False  # Reduziert Host-Memory-Druck
```

**Warum:** `pin_memory=True` beschleunigt DataLoader, aber verbraucht zusätzlichen RAM. Bei begrenztem System-Memory (neben 4GB VRAM) sicherer auf False zu setzen.

---

**Letzte Aktualisierung:** 2026-04-01 01:27 UTC  
**Gesamte Änderungen:** 8 in train.py, 2 in prepare.py
