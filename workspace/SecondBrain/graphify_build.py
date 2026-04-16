import json
from pathlib import Path
from graphify.build import build_from_json
from graphify.cluster import cluster, score_all
from graphify.analyze import god_nodes, surprising_connections, suggest_questions
from graphify.report import generate
from graphify.export import to_json, to_obsidian, to_html, to_canvas
import os

# Load extraction
extraction = json.loads(Path('.graphify_extract.json').read_text())
detection = json.loads(Path('.graphify_detect.json').read_text())

print("Building graph...")
G = build_from_json(extraction)

print(f"Graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")

print("Clustering...")
communities = cluster(G)
cohesion = score_all(G, communities)

print(f"Found {len(communities)} communities")

# Analyze
print("Analyzing god nodes...")
gods = god_nodes(G)

print("Finding surprising connections...")
surprises = surprising_connections(G, communities)

# Generate labels based on community content
labels = {}
for cid, nodes in communities.items():
    # Get most common words from node labels in this community
    node_labels = [G.nodes[n].get('label', n) for n in nodes[:5]]
    labels[cid] = ' '.join(node_labels[:2]) if node_labels else f'Community {cid}'

print(f"Community labels: {labels}")

# Generate questions
questions = suggest_questions(G, communities, labels)

# Generate report
tokens = {'input': extraction.get('input_tokens', 0), 'output': extraction.get('output_tokens', 0)}
report = generate(G, communities, cohesion, labels, gods, surprises, detection, tokens, 'C:/Users/andre/.openclaw/workspace/SecondBrain', suggested_questions=questions)

# Create output directory
os.makedirs('graphify-out', exist_ok=True)
os.makedirs('C:/Users/andre/.openclaw/workspace/SecondBrain/00-Meta/Graphify-Output', exist_ok=True)

Path('graphify-out/GRAPH_REPORT.md').write_text(report, encoding='utf-8')
print("Report saved to graphify-out/GRAPH_REPORT.md")

# Save graph JSON
to_json(G, communities, 'graphify-out/graph.json')
print("Graph JSON saved")

# Save analysis
analysis = {
    'communities': {str(k): v for k, v in communities.items()},
    'cohesion': {str(k): v for k, v in cohesion.items()},
    'gods': gods,
    'surprises': surprises,
    'questions': questions,
}
Path('.graphify_analysis.json').write_text(json.dumps(analysis, indent=2))

# Save labels
Path('.graphify_labels.json').write_text(json.dumps({str(k): v for k, v in labels.items()}))

print("Analysis complete!")
print(f"\n=== SUMMARY ===")
print(f"Nodes: {G.number_of_nodes()}")
print(f"Edges: {G.number_of_edges()}")
print(f"Communities: {len(communities)}")
print(f"God Nodes: {len(gods)}")
