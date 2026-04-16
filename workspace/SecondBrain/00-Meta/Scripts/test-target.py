"""Small test script for evolve loop validation."""
import json
from pathlib import Path

def load_docs(folder: Path):
    docs = []
    for f in folder.rglob("*.md"):
        text = f.read_text(encoding="utf-8")
        docs.append({"path": str(f), "text": text[:500]})
    return docs

def save_results(data, out_file):
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

if __name__ == "__main__":
    docs = load_docs(Path("."))
    save_results({"count": len(docs)}, "results.json")
    print(f"Loaded {len(docs)} docs")
