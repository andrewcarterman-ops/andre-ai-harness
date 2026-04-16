import json
from pathlib import Path
from graphify.detect import detect
from graphify.build import build_from_json
from graphify.cluster import cluster, score_all
from graphify.analyze import god_nodes, surprising_connections, suggest_questions
from graphify.report import generate
from graphify.export import to_json, to_obsidian, to_html
import networkx as nx

# Load detection result
detect_result = json.loads(Path('.graphify_detect.json').read_text())
ast_result = json.loads(Path('.graphify_ast.json').read_text())

# For semantic extraction on OpenClaw, we'll use a simplified approach
# Extract key concepts from document titles and structure

semantic_nodes = []
semantic_edges = []
semantic_hyperedges = []

# Process markdown documents - extract from paths and titles
doc_files = detect_result.get('files', {}).get('document', [])

print(f"Processing {len(doc_files)} documents for semantic extraction...")

for doc_path in doc_files[:50]:  # Process first 50 for now
    path = Path(doc_path)
    rel_path = str(path.relative_to(Path('C:/Users/andre/.openclaw/workspace/SecondBrain')))
    
    # Extract concepts from path structure
    parts = rel_path.replace('.md', '').split('\\')
    
    # Create node for the document
    doc_id = rel_path.replace('\\', '_').replace('.md', '').lower()
    doc_label = path.stem.replace('-', ' ').replace('_', ' ')
    
    doc_node = {
        "id": doc_id,
        "label": doc_label,
        "file_type": "document",
        "source_file": rel_path,
        "source_location": None,
        "source_url": None,
        "captured_at": None,
        "author": None,
        "contributor": None
    }
    semantic_nodes.append(doc_node)
    
    # Create edges based on folder structure
    for i, part in enumerate(parts[:-1]):
        folder_id = f"folder_{part.lower()}"
        folder_label = part.replace('-', ' ').replace('_', ' ')
        
        # Add folder node if not exists
        if not any(n['id'] == folder_id for n in semantic_nodes):
            semantic_nodes.append({
                "id": folder_id,
                "label": folder_label,
                "file_type": "folder",
                "source_file": rel_path,
                "source_location": None
            })
        
        # Create edge from folder to document or subfolder
        if i == len(parts) - 2:
            target = doc_id
        else:
            target = f"folder_{parts[i+1].lower()}"
        
        semantic_edges.append({
            "source": folder_id,
            "target": target,
            "relation": "contains",
            "confidence": "EXTRACTED",
            "confidence_score": 1.0,
            "source_file": rel_path,
            "weight": 1.0
        })

# Merge AST and semantic results
seen = {n['id'] for n in ast_result['nodes']}
merged_nodes = list(ast_result['nodes'])
for n in semantic_nodes:
    if n['id'] not in seen:
        merged_nodes.append(n)
        seen.add(n['id'])

merged_edges = ast_result['edges'] + semantic_edges

extraction = {
    'nodes': merged_nodes,
    'edges': merged_edges,
    'hyperedges': semantic_hyperedges,
    'input_tokens': 0,
    'output_tokens': 0
}

Path('.graphify_extract.json').write_text(json.dumps(extraction, indent=2))
print(f'Semantic extraction: {len(semantic_nodes)} nodes, {len(semantic_edges)} edges')
print(f'Total: {len(merged_nodes)} nodes, {len(merged_edges)} edges')
