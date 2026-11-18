#!/usr/bin/env python3
"""Compare version-pinned Hekili Forever docs/wiki pages without mirroring them."""

import argparse
import json
import subprocess
from pathlib import Path


def run_git(repo: Path, *args: str) -> bytes:
    process = subprocess.run(
        ["git", "-C", str(repo), *args], capture_output=True, check=False
    )
    if process.returncode:
        raise ValueError(
            f"git {' '.join(args)} failed: {process.stderr.decode('utf-8', 'replace').strip()}"
        )
    return process.stdout


def tree(repo: Path, ref: str) -> dict[str, str]:
    """Return path -> git blob SHA for tracked Markdown wiki pages at ref."""
    raw = run_git(repo, "ls-tree", "-r", "-z", ref, "--", "docs/wiki")
    pages: dict[str, str] = {}
    for record in raw.split(b"\0"):
        if not record:
            continue
        meta, path = record.split(b"\t", 1)
        mode, kind, blob = meta.decode("ascii").split(" ")
        name = path.decode("utf-8")
        if kind == "blob" and name.endswith(".md"):
            pages[name] = blob
    return pages


def impact(path: str) -> str:
    filename = Path(path).name
    if filename.startswith("APL-") or filename in {
        "What-Hekili-Forever-Can-And-Cannot-Know.md",
        "How-Targets-Are-Counted.md",
        "Cooldown-Manager.md",
        "Toggles.md",
        "Abilities-And-Items.md",
        "Reading-A-Snapshot.md",
        "Accuracy.md",
    }:
        return "apl-engine"
    if filename.startswith("Pack-") or filename in {
        "Supported-Classes-And-Priorities.md", "Specializations-Reference.md"
    }:
        return "class-mechanics-tests"
    return "operations-or-ui"


def compare(repo: Path, old: str, new: str) -> dict:
    before, after = tree(repo, old), tree(repo, new)
    paths = sorted(set(before) | set(after))
    changes = []
    for path in paths:
        if path not in before:
            change = "added"
        elif path not in after:
            change = "removed"
        elif before[path] != after[path]:
            change = "modified"
        else:
            continue
        changes.append({
            "path": path, "change": change, "impact": impact(path),
            "old_blob": before.get(path), "new_blob": after.get(path),
        })
    return {
        "old_ref": old, "new_ref": new,
        "old_pages": len(before), "new_pages": len(after),
        "changed_pages": len(changes), "changes": changes,
    }


def markdown(result: dict) -> str:
    head = (
        f"# Hekili Forever wiki source diff: {result['old_ref']} → {result['new_ref']}\n\n"
        f"Markdown pages: {result['old_pages']} → {result['new_pages']}; "
        f"changed: {result['changed_pages']}. "
        "All findings require source review; this is not APL validation.\n"
    )
    if not result["changes"]:
        return head + "\nNo wiki Markdown changes.\n"
    lines = ["\n| Page | Change | Review queue |", "| --- | --- | --- |"]
    for row in result["changes"]:
        lines.append(f"| `{row['path']}` | {row['change']} | {row['impact']} |")
    return head + "\n".join(lines) + "\n"


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--repo", required=True, type=Path, help="local checkout of zmsl/hekili")
    p.add_argument("--old", required=True, help="old release tag/commit, e.g. v0.8.2")
    p.add_argument("--new", required=True, help="new release tag/commit, e.g. v0.8.3")
    p.add_argument("--format", choices=("markdown", "json"), default="markdown")
    args = p.parse_args()
    result = compare(args.repo, args.old, args.new)
    print(json.dumps(result, indent=2) if args.format == "json" else markdown(result))


if __name__ == "__main__":
    main()
