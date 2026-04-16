"""
Mini-Evolve-Loop for targeted code improvement.
Sequentially evolves one target script and stages proposals in 05-Research/pending/.
"""

import io
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import yaml

os.environ["PYTHONUNBUFFERED"] = "1"
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
sys.stdout.reconfigure(line_buffering=True)

from llm_router import LLMRouter, LLMClient


@dataclass
class Node:
    id: int
    name: str
    motivation: str
    code: str
    results: Dict[str, Any]
    analysis: str
    score: float


class PromptManager:
    def __init__(self, prompt_dir: Path):
        self.prompt_dir = Path(prompt_dir)

    def render(self, template_name: str, **context) -> str:
        file_path = self.prompt_dir / f"{template_name}.jinja2"
        if not file_path.exists():
            raise ValueError(f"Prompt template not found: {file_path}")
        text = file_path.read_text(encoding="utf-8")
        # Very simple Jinja-like substitution
        for key, value in context.items():
            placeholder = f"{{{{ {key} }}}}"
            if placeholder in text:
                text = text.replace(placeholder, str(value))
        # Handle {%% for ... %} loops naively by leaving them if unresolved
        return text


def extract_diffs(diff_text: str) -> List[Tuple[str, str]]:
    pattern = r"<<<<<<< SEARCH\n(.*?)=======\n(.*?)>>>>>>> REPLACE"
    blocks = re.findall(pattern, diff_text, re.DOTALL)
    return [(s.rstrip(), r.rstrip()) for s, r in blocks]


def extract_markdown_code_blocks(text: str) -> List[str]:
    """Extract all fenced code blocks from markdown text."""
    # Match ```python\n...``` or ```\n...```
    pattern = r"```(?:\w+)?\n(.*?)```"
    return re.findall(pattern, text, re.DOTALL)


def extract_proposal(response_text: str) -> Dict[str, str]:
    """Robust extraction of name, motivation, and code/diff from LLM response."""
    result: Dict[str, str] = {}

    # 1. Extract name and motivation from XML tags (even inside markdown fences)
    for tag in ["name", "motivation"]:
        pattern = rf"<\s*{tag}\s*>(.*?)<\s*/\s*{tag}\s*>"
        match = re.search(pattern, response_text, re.DOTALL | re.IGNORECASE)
        if match:
            result[tag] = match.group(1).strip()

    # 2. Try to find <code>...</code> first
    code_match = re.search(r"<\s*code\s*>(.*?)<\s*/\s*code\s*>", response_text, re.DOTALL | re.IGNORECASE)
    if code_match:
        result["code"] = code_match.group(1).strip()
        return result

    # 3. Fallback: look for SEARCH/REPLACE diffs in markdown code blocks
    code_blocks = extract_markdown_code_blocks(response_text)
    for block in code_blocks:
        if "<<<<<<< SEARCH" in block:
            result["code"] = block.strip()
            return result

    # 4. Last resort: search entire text for diffs
    if "<<<<<<< SEARCH" in response_text:
        result["code"] = response_text.strip()
        return result

    return result


def apply_diff(original_code: str, diff_text: str) -> str:
    blocks = extract_diffs(diff_text)
    if not blocks:
        raise ValueError("No diff blocks found in response")
    result = original_code
    for i, (search_text, replace_text) in enumerate(blocks):
        if search_text not in result:
            raise ValueError(f"Diff block {i+1}: search text not found")
        result = result.replace(search_text, replace_text, 1)
    return result


def run_engineer(script_path: str, test_command: str, timeout: int) -> Dict[str, Any]:
    """Run the target script and capture metrics."""
    start = time.time()
    try:
        proc = subprocess.run(
            test_command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout,
            encoding="utf-8",
            errors="replace",
        )
        runtime = time.time() - start
        stdout = proc.stdout or ""
        stderr = proc.stderr or ""

        # Heuristic parsing of semantic-memory-poc.py output
        indexed_docs = 0
        m = re.search(r"FAISS index built with (\d+) vectors", stdout)
        if m:
            indexed_docs = int(m.group(1))

        # Simple quality: did it complete successfully?
        success = proc.returncode == 0 and indexed_docs > 0

        # Score: 0-100 based on success + indexed doc count (cap at 500 for max score)
        score = 0.0
        if success:
            score = min(100.0, 50.0 + (indexed_docs / 500.0) * 50.0)

        return {
            "success": success,
            "eval_score": score,
            "runtime": runtime,
            "indexed_docs": indexed_docs,
            "returncode": proc.returncode,
            "stdout_snippet": stdout[-2000:] if len(stdout) > 2000 else stdout,
            "stderr_snippet": stderr[-1000:] if len(stderr) > 1000 else stderr,
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "eval_score": 0.0,
            "runtime": timeout,
            "error": "Timeout",
        }
    except Exception as e:
        return {
            "success": False,
            "eval_score": 0.0,
            "runtime": 0.0,
            "error": str(e),
        }


def save_proposal(
    pending_dir: Path,
    step: int,
    node: Node,
    original_code: str,
    diff_code: str,
    task_description: str,
) -> Path:
    pending_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    filename = pending_dir / f"{timestamp}-semantic-memory-iteration-{step}.md"

    lines = [
        "---",
        f"status: pending",
        f"source: mini-evolve-loop",
        f"target: SecondBrain/00-Meta/Scripts/semantic-memory-poc.py",
        f"iteration: {step}",
        f"score: {node.score:.2f}",
        f"created: {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        "---",
        "",
        f"# Vorschlag: {node.name}",
        "",
        "## Kontext",
        f"{task_description}",
        "",
        "## Begründung",
        f"{node.motivation}",
        "",
        "## Konkrete Änderung",
        "```python",
        "# Diff applied to semantic-memory-poc.py",
        "```",
        "```diff",
        diff_code,
        "```",
        "",
        "## Results",
        f"```json\n{json.dumps(node.results, indent=2, ensure_ascii=False)}\n```",
        "",
        "## Analysis",
        f"{node.analysis}",
        "",
        "## Validation",
        "- [ ] Getestet",
        "- [ ] Implementiert",
        "- [ ] Abgelehnt",
        "",
    ]

    filename.write_text("\n".join(lines), encoding="utf-8")
    return filename


def main():
    script_dir = Path(__file__).parent.resolve()
    config_path = script_dir / "config.yaml"
    if not config_path.exists():
        print("config.yaml not found", file=sys.stderr)
        sys.exit(1)

    with open(config_path, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    script_dir = Path(__file__).parent.resolve()
    router = LLMRouter(config)
    researcher_llm = router.get_client("coding")
    analyzer_llm = router.get_client("reasoning")
    prompts = PromptManager(script_dir / "prompts")

    target_script = (script_dir / config["target"]["script_path"]).resolve()
    test_command = config["target"]["test_command"]
    eval_timeout = config["target"]["eval_timeout"]
    max_steps = config["pipeline"]["max_steps"]
    pending_dir = (script_dir / config["output"]["pending_dir"]).resolve()

    task_description = (
        "Improve the semantic-memory-poc.py script. "
        "Goals: faster indexing, better search quality, more robust error handling, "
        "or cleaner code structure. Maintain the same CLI behavior."
    )

    nodes: List[Node] = []

    for step in range(1, max_steps + 1):
        print(f"\n{'='*60}")
        print(f"Step {step}/{max_steps}")
        print("=" * 60)

        # 1. Load current base code
        base_code = target_script.read_text(encoding="utf-8")

        # 2. Researcher generates diff
        print("[Researcher] Generating diff...")
        context_nodes = nodes[-3:] if nodes else []
        # Simple context serialization
        context_str = ""
        for n in context_nodes:
            context_str += f"\n### {n.name}\nScore: {n.score}\nAnalysis: {n.analysis}\n"

        prompt = prompts.render(
            "researcher_diff",
            task_description=task_description,
            base_code=base_code,
            context_nodes=context_str,
        )
        # Clean up unresolved Jinja conditionals when context is empty
        if not context_str.strip():
            jinja_block = "{% if context_nodes %}\n## Context from Previous Experiments\n{% for node in context_nodes %}\n### {{ node.name }}\n**Score**: {{ node.score }}\n**Motivation**: {{ node.motivation }}\n{% if node.code %}\n**Code Diff**:\n```python\n{{ node.code }}\n```\n{% endif %}\n{% if node.results %}\n**Results**: {{ node.results | tojson(indent=2) }}\n{% endif %}\n{% if node.analysis %}\n**Analysis**: {{ node.analysis }}\n{% endif %}\n{% endfor %}\n{% endif %}"
            prompt = prompt.replace(jinja_block, "")

        try:
            response = researcher_llm.generate(prompt)
            result = extract_proposal(response.content)
            name = result.get("name", f"iteration-{step}")
            motivation = result.get("motivation", "")
            diff_text = result.get("code", "")
            print(f"[Researcher] Extracted: name='{name}', diff_length={len(diff_text)}")
        except Exception as e:
            print(f"[Researcher] Failed: {e}")
            continue

        if not diff_text:
            print("[Researcher] No diff generated, skipping")
            continue

        # 3. Apply diff
        print("[Engineer] Applying diff...")
        try:
            new_code = apply_diff(base_code, diff_text)
        except Exception as e:
            print(f"[Engineer] Diff failed: {e}")
            continue

        # Write mutated code to temp file
        temp_script = target_script.parent / f"semantic-memory-poc-iter{step}.py"
        temp_script.write_text(new_code, encoding="utf-8")

        # Adjust test command for temp file
        adjusted_test = test_command.replace(
            'semantic-memory-poc.py"',
            f'semantic-memory-poc-iter{step}.py"'
        )

        # 4. Engineer runs evaluation
        print("[Engineer] Running evaluation...")
        results = run_engineer(str(temp_script), adjusted_test, eval_timeout)

        print(f"[Engineer] Score: {results['eval_score']:.2f}, Success: {results['success']}, Runtime: {results.get('runtime', 0):.2f}s")

        # 5. Analyzer evaluates result
        print("[Analyzer] Analyzing...")
        best_node = nodes[-1] if nodes else None
        analyzer_prompt = prompts.render(
            "analyzer",
            task_description=task_description,
            code=diff_text,
            results=json.dumps(results, indent=2, ensure_ascii=False),
            best_sampled_node=best_node,
        )

        try:
            analysis_result = analyzer_llm.extract_tags(analyzer_prompt)
            analysis = analysis_result.get("analysis", "")
        except Exception as e:
            print(f"[Analyzer] Failed: {e}")
            analysis = ""

        # 6. Create node
        node = Node(
            id=step,
            name=name,
            motivation=motivation,
            code=new_code,
            results=results,
            analysis=analysis,
            score=results["eval_score"],
        )
        nodes.append(node)

        # 7. Save proposal to 05-Research/pending/
        proposal_path = save_proposal(
            pending_dir, step, node, base_code, diff_text, task_description
        )
        print(f"[Loop] Proposal saved: {proposal_path}")

        # Cleanup temp file
        try:
            temp_script.unlink()
        except Exception:
            pass

    print(f"\n{'='*60}")
    print("Evolve loop completed")
    print(f"Total proposals: {len(nodes)}")
    if nodes:
        best = max(nodes, key=lambda n: n.score)
        print(f"Best score: {best.score:.2f} (Step {best.id})")
    print("=" * 60)


if __name__ == "__main__":
    main()
