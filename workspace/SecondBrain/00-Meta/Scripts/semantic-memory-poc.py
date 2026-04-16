"""
Semantic Memory PoC for SecondBrain Vault.
Builds a FAISS index over markdown files and allows semantic search.
"""

import io
import json
import sys
from pathlib import Path

import faiss

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
import numpy as np
from sentence_transformers import SentenceTransformer

VAULT_DIR = Path(__file__).parent.parent.parent
INDEX_DIR = VAULT_DIR / "00-Meta" / "semantic-memory"
MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
MAX_FILES = 500
MAX_CHARS_PER_DOC = 4000


def load_documents(vault_dir: Path, max_files: int = MAX_FILES):
    """Load markdown files from the vault."""
    md_files = list(vault_dir.rglob("*.md"))
    print(f"Found {len(md_files)} markdown files in vault.")

    documents = []
    for md_file in md_files[:max_files]:
        try:
            try:
                content = md_file.read_text(encoding="utf-8-sig")
            except Exception:
                content = md_file.read_text(encoding="utf-8", errors="replace")
            # Skip very short files
            if len(content.strip()) < 50:
                continue
            # Truncate very long files for the PoC
            if len(content) > MAX_CHARS_PER_DOC:
                content = content[:MAX_CHARS_PER_DOC] + "\n... [truncated]"
            documents.append({
                "path": str(md_file.relative_to(vault_dir)),
                "content": content,
            })
        except Exception as e:
            print(f"Warning: could not read {md_file}: {e}")

    print(f"Loaded {len(documents)} documents for indexing.")
    return documents


def build_index(documents):
    """Build a FAISS index from documents."""
    print(f"Loading embedding model: {MODEL_NAME}")
    model = SentenceTransformer(MODEL_NAME, device="cpu")

    texts = [doc["content"] for doc in documents]
    print("Encoding documents...")
    embeddings = model.encode(texts, normalize_embeddings=True, show_progress_bar=True)
    embeddings = np.array(embeddings, dtype=np.float32)

    dim = embeddings.shape[1]
    print(f"Embedding dimension: {dim}")

    index = faiss.IndexFlatIP(dim)
    index.add(embeddings)

    print(f"FAISS index built with {index.ntotal} vectors.")
    return model, index, embeddings


def save_index(documents, index, index_dir: Path):
    """Persist index and metadata to disk."""
    index_dir.mkdir(parents=True, exist_ok=True)

    faiss.write_index(index, str(index_dir / "index.faiss"))
    with open(index_dir / "documents.json", "w", encoding="utf-8") as f:
        json.dump(documents, f, ensure_ascii=False, indent=2)

    print(f"Index saved to {index_dir}")


def search(model, index, documents, query: str, top_k: int = 5):
    """Search the index for documents semantically similar to the query."""
    query_embedding = model.encode([query], normalize_embeddings=True)
    query_embedding = np.array(query_embedding, dtype=np.float32)

    scores, indices = index.search(query_embedding, top_k)

    results = []
    for score, idx in zip(scores[0], indices[0]):
        if idx < 0:
            continue
        doc = documents[idx]
        results.append({
            "path": doc["path"],
            "score": float(score),
            "snippet": doc["content"][:300].replace("\n", " "),
        })

    return results


def main():
    INDEX_DIR.mkdir(parents=True, exist_ok=True)

    # Load or build index
    if (INDEX_DIR / "index.faiss").exists() and (INDEX_DIR / "documents.json").exists():
        print("Loading existing index...")
        with open(INDEX_DIR / "documents.json", "r", encoding="utf-8") as f:
            documents = json.load(f)
        index = faiss.read_index(str(INDEX_DIR / "index.faiss"))
        model = SentenceTransformer(MODEL_NAME, device="cpu")
        print(f"Loaded index with {index.ntotal} documents.")
    else:
        documents = load_documents(VAULT_DIR, MAX_FILES)
        if not documents:
            print("No documents found. Exiting.")
            sys.exit(1)
        model, index, _ = build_index(documents)
        save_index(documents, index, INDEX_DIR)

    # Run a few test queries
    test_queries = [
        "How does the edit tool workaround function?",
        "What are the rules for migrations?",
        "Tell me about the OpenClaw architecture.",
        "How should I handle API keys securely?",
        "What happened on the 10th of April 2026?",
    ]

    for query in test_queries:
        print(f"\n{'='*60}")
        print(f"Query: {query}")
        print("=" * 60)
        results = search(model, index, documents, query, top_k=3)
        for i, res in enumerate(results, 1):
            print(f"\n{i}. [{res['score']:.3f}] {res['path']}")
            print(f"   {res['snippet']}...")


if __name__ == "__main__":
    main()
