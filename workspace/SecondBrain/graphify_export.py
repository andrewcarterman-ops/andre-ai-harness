import json
from pathlib import Path
from graphify.build import build_from_json
from graphify.export import to_obsidian, to_html, to_canvas
from graphify.cluster import score_all

# Load data
extraction = json.loads(Path('.graphify_extract.json').read_text())
analysis = json.loads(Path('.graphify_analysis.json').read_text())
labels_raw = json.loads(Path('.graphify_labels.json').read_text()) if Path('.graphify_labels.json').exists() else {}

G = build_from_json(extraction)
communities = {int(k): v for k, v in analysis['communities'].items()}
cohesion = {int(k): v for k, v in analysis['cohesion'].items()}
labels = {int(k): v for k, v in labels_raw.items()}

# Create output directories
obsidian_dir = 'C:/Users/andre/.openclaw/workspace/SecondBrain/00-Meta/Graphify-Output'
import os
os.makedirs(obsidian_dir, exist_ok=True)
os.makedirs(f'{obsidian_dir}/nodes', exist_ok=True)

print("Creating Obsidian vault export...")

# Export to Obsidian
n = to_obsidian(G, communities, obsidian_dir, community_labels=labels or None, cohesion=cohesion)
print(f'Obsidian vault: {n} notes in {obsidian_dir}/')

# Create canvas
try:
    to_canvas(G, communities, f'{obsidian_dir}/graph.canvas', community_labels=labels or None)
    print(f'Canvas: {obsidian_dir}/graph.canvas')
except Exception as e:
    print(f'Canvas creation skipped: {e}')

# Create HTML
print("Creating HTML visualization...")
try:
    to_html(G, communities, f'{obsidian_dir}/graph.html', community_labels=labels or None)
    print(f'HTML: {obsidian_dir}/graph.html')
except Exception as e:
    print(f'HTML creation skipped: {e}')

print("\n=== EXPORT COMPLETE ===")
print(f"Output directory: {obsidian_dir}")
print(f"Files created:")
print(f"  - {n} Obsidian notes")
print(f"  - graph.canvas (Obsidian canvas view)")
print(f"  - graph.html (Interactive HTML)")
print(f"  - GRAPH_REPORT.md (Audit report)")
print(f"  - graph.json (Raw graph data)")
