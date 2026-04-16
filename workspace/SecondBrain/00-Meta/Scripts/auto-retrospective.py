"""
Auto-Retrospective Generator

Reads a session markdown file and generates a structured retrospective
suitable for MEMORY.md or Daily Notes.

Usage:
    python auto-retrospective.py <path-to-session-md>
"""

import io
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import List, Optional

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


@dataclass
class Retrospective:
    date: str
    summary: str
    decisions: List[str] = field(default_factory=list)
    open_todos: List[str] = field(default_factory=list)
    lessons_learned: List[str] = field(default_factory=list)
    mistakes: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)


def extract_date_from_path_or_content(file_path: Path, content: str) -> str:
    """Try to find a date in filename or frontmatter."""
    # From filename: YYYY-MM-DD or DD-MM-YYYY
    stem = file_path.stem
    m = re.search(r"(\d{4}-\d{2}-\d{2})", stem)
    if m:
        return m.group(1)
    m = re.search(r"(\d{2}-\d{2}-\d{4})", stem)
    if m:
        parts = m.group(1).split("-")
        return f"{parts[2]}-{parts[1]}-{parts[0]}"
    # From frontmatter
    fm = re.search(r"^---\s*\n.*?date:\s*(\S+).*?^---", content, re.MULTILINE | re.DOTALL)
    if fm:
        return fm.group(1).strip()
    return datetime.now().strftime("%Y-%m-%d")


def extract_frontmatter(content: str) -> dict:
    """Parse simple YAML-like frontmatter."""
    fm = {}
    match = re.search(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return fm
    for line in match.group(1).strip().splitlines():
        if ":" in line:
            key, val = line.split(":", 1)
            fm[key.strip()] = val.strip()
    return fm


def _clean_bullet(line: str) -> Optional[str]:
    """Strip markdown bullet markers and whitespace."""
    line = line.strip()
    if not line:
        return None
    for marker in ("- ", "* ", "+ ", "• "):
        if line.startswith(marker):
            line = line[len(marker):]
            break
    # Strip checkboxes
    line = re.sub(r"^\[.\]\s*", "", line)
    line = line.strip()
    if not line or line.lower().startswith("*(noch") or line.lower().startswith("_(noch"):
        return None
    return line


def parse_session(content: str, file_path: Path = Path("session.md")) -> Retrospective:
    """Parse raw markdown into a structured retrospective."""
    fm = extract_frontmatter(content)
    retro = Retrospective(
        date=extract_date_from_path_or_content(file_path, content),
        summary="",
    )

    # Heuristic extraction based on common headers
    lines = content.splitlines()
    current_section = None

    section_map = {
        "zusammenfassung": "summary",
        "summary": "summary",
        "session summary": "summary",
        "key activities": "summary",
        "discoveries": "lessons_learned",
        "decisions": "decisions",
        "decisions made": "decisions",
        "entscheidungen": "decisions",
        "getroffene entscheidungen": "decisions",
        "todos": "open_todos",
        "open todos": "open_todos",
        "offene todos": "open_todos",
        "offene punkte": "open_todos",
        "next steps": "open_todos",
        "nächste schritte": "open_todos",
        "action items": "open_todos",
        "lessons learned": "lessons_learned",
        "lessons": "lessons_learned",
        "erkenntnisse": "lessons_learned",
        "key learnings": "lessons_learned",
        "insights": "lessons_learned",
        "mistakes": "mistakes",
        "fehler": "mistakes",
        "probleme": "mistakes",
        "issues found": "mistakes",
        "issues": "mistakes",
        "tags": "tags",
    }

    for line in lines:
        lower = line.lower().strip()
        # Detect section headers (# ## ###)
        if lower.startswith(("# ", "## ", "### ")):
            header = re.sub(r"^#+\s*", "", lower).strip()
            current_section = section_map.get(header)
            continue

        if current_section == "summary" and not retro.summary:
            cleaned = _clean_bullet(line)
            if cleaned and len(cleaned) > 10 and not cleaned.lower().startswith("date:"):
                retro.summary = cleaned
        elif current_section in ("decisions", "open_todos", "lessons_learned", "mistakes"):
            cleaned = _clean_bullet(line)
            if cleaned and len(cleaned) > 3:
                getattr(retro, current_section).append(cleaned)
        elif current_section == "tags":
            cleaned = _clean_bullet(line)
            if cleaned:
                retro.tags.append(cleaned.strip("#`"))

    # Fallback summary if none found
    if not retro.summary:
        # Take first substantial paragraph
        for line in lines:
            stripped = line.strip()
            if stripped and not stripped.startswith(("#", "-", "*", "---")) and len(stripped) > 20:
                retro.summary = stripped
                break

    # Extract tags from frontmatter if available
    if "tags" in fm:
        tags_raw = fm["tags"].strip("[]")
        retro.tags = [t.strip().strip("#`") for t in tags_raw.split(",") if t.strip()]

    return retro


def format_retrospective(retro: Retrospective, source_file: str) -> str:
    """Format a Retrospective as a markdown document."""
    lines = [
        f"---",
        f"date: {retro.date}",
        f"type: retrospective",
        f"source: {source_file}",
        f"generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        f"---",
        f"",
        f"# Retrospective: {retro.date}",
        f"",
        f"## Summary",
        f"{retro.summary}",
        f"",
    ]

    def section(title: str, items: List[str]):
        if not items:
            return
        lines.append(f"## {title}")
        for item in items:
            lines.append(f"- {item}")
        lines.append("")

    section("Decisions", retro.decisions)
    section("Lessons Learned", retro.lessons_learned)
    section("Mistakes / Problems", retro.mistakes)
    section("Open TODOs", retro.open_todos)

    if retro.tags:
        lines.append("## Tags")
        lines.append(", ".join(f"#{t}" for t in retro.tags))
        lines.append("")

    lines.append("---")
    lines.append("")
    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        # Default: analyze the most recent daily note
        daily_dir = Path(__file__).parent.parent.parent / "01-Daily"
        md_files = sorted(daily_dir.glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True)
        if not md_files:
            print("No markdown file provided and no daily notes found.", file=sys.stderr)
            sys.exit(1)
        target_file = md_files[0]
        print(f"No file argument given. Using most recent daily note: {target_file.name}")
    else:
        target_file = Path(sys.argv[1])

    if not target_file.exists():
        print(f"File not found: {target_file}", file=sys.stderr)
        sys.exit(1)

    content = target_file.read_text(encoding="utf-8-sig", errors="replace")
    retro = parse_session(content, target_file)
    output = format_retrospective(retro, str(target_file.name))

    # Write to stdout and optionally to a file
    print(output)

    out_dir = Path(__file__).parent.parent.parent / "01-Daily" / "Retrospectives"
    out_dir.mkdir(exist_ok=True)
    out_file = out_dir / f"retrospective-{retro.date}.md"
    out_file.write_text(output, encoding="utf-8")
    print(f"\n[Saved retrospective to {out_file}]")


if __name__ == "__main__":
    main()
