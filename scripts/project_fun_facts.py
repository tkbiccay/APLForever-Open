#!/usr/bin/env python3
"""Read-only public APLForever fun facts. Stdlib only; never edits GitHub.

Workflow supplies a full-depth checkout and a read-only GITHUB_TOKEN.
Counts use PUBLIC main history, not the private historical reference repo.
"""
from __future__ import annotations

import argparse
from collections import Counter
from datetime import date, datetime, timezone
import json
import os
from pathlib import Path
import subprocess
from urllib.parse import urlencode
from urllib.request import Request, urlopen


REPOSITORY = "tkbiccay/APLForever-Open"
FIRST_DOCUMENTED_WORK = date(2026, 11, 7)  # Project conversation, not a GitHub creation timestamp.
ROOT = Path(__file__).resolve().parents[1]
CODE_SUFFIXES = (".py", ".lua", ".yml", ".yaml")


def is_source_path(path: str) -> bool:
    """APL imports, source, test and workflow files. Documents are excluded."""
    return (path.startswith("roles/") and path.endswith(".txt")) or path.endswith(CODE_SUFFIXES)


def count_numstat(text: str) -> dict[str, int]:
    """Interpret git log --numstat. '-' denotes binary lines, not zero lines."""
    counts = {"added": 0, "deleted": 0, "source_added": 0, "source_deleted": 0}
    for line in text.splitlines():
        parts = line.split("\t", 2)
        if len(parts) != 3:
            continue
        added, deleted, path = parts
        if not (added.isdecimal() and deleted.isdecimal()):
            continue  # binary data or commit separators
        a, d = int(added), int(deleted)
        counts["added"] += a
        counts["deleted"] += d
        if is_source_path(path):
            counts["source_added"] += a
            counts["source_deleted"] += d
    return counts


def git_stats(root: Path) -> dict[str, int]:
    def git(*args: str) -> str:
        return subprocess.run(
            ["git", "-C", str(root), *args], text=True, capture_output=True,
            check=True, timeout=30,
        ).stdout.strip()

    counts = count_numstat(git("log", "--format=", "--numstat", "HEAD"))
    counts["commits"] = int(git("rev-list", "--count", "HEAD"))
    counts["text_changed"] = counts["added"] + counts["deleted"]
    counts["source_changed"] = counts["source_added"] + counts["source_deleted"]
    return counts


def catalogue_stats(root: Path) -> dict[str, int]:
    data = json.loads((root / "catalogue" / "roles.json").read_text(encoding="utf-8"))
    roles = data["roles"]
    status = Counter(row.get("support_status", "Unknown") for row in roles)
    return {
        "roles": len(roles),
        "supported": status["Supported"],
        "blocked": status["Blocked"],
        "apl_revisions": sum(len(row.get("revisions", [])) for row in roles),
        "approved_roles": sum(row.get("validation_status") == "Approved" for row in roles),
    }


def public_json(endpoint: str, token: str = "") -> dict:
    request = Request(
        "https://api.github.com/" + endpoint,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "APLForever-Open-public-fun-facts",
            "X-GitHub-Api-Version": "2022-11-28",
            **({"Authorization": "Bearer " + token} if token else {}),
        },
    )
    with urlopen(request, timeout=20) as result:
        return json.load(result)


def github_stats(token: str = "") -> dict:
    info = public_json("repos/" + REPOSITORY, token)
    if info.get("private") is not False or info.get("full_name") != REPOSITORY:
        raise ValueError("Stats source must be the exact PUBLIC canonical repository")
    def search_count(*qualifiers: str) -> int:
        query = "repo:" + REPOSITORY + " " + " ".join(qualifiers)
        encoded = urlencode({"q": query, "per_page": 1})
        return int(public_json("search/issues?" + encoded, token)["total_count"])

    return {
        "public_created": info["created_at"][:10],
        "merged_prs": search_count("is:pr", "is:merged"),
        "closed_issues": search_count("is:issue", "is:closed"),
        "stars": int(info["stargazers_count"]),
        "forks": int(info["forks_count"]),
    }


def make_snapshot(root: Path, token: str = "", today: date | None = None) -> dict:
    day = today or datetime.now(timezone.utc).date()
    result = {"as_of": day.isoformat(), "started": FIRST_DOCUMENTED_WORK.isoformat()}
    result.update(git_stats(root))
    result.update(catalogue_stats(root))
    result.update(github_stats(token))
    return result


def render(snapshot: dict) -> str:
    x = snapshot
    def fmt(key: str) -> str:
        return f"{x[key]:,}"

    return (
        "# APLForever-Open — project fun facts\n\n"
        f"**Snapshot (UTC): {x['as_of']}** · "
        "**Proudly AI-developed, human-maintained, open source.**\n\n"
        "**First documented project work:** 7 November 2026 · "
        f"**Public repository established:** {x['public_created']}.\n\n"
        "| Fun fact | Public project total |\n"
        "|---|---:|\n"
        f"| Commits on public main | **{fmt('commits')}** |\n"
        f"| Text lines changed (additions + deletions) | **{fmt('text_changed')}** |\n"
        f"| APL/source/test/workflow lines changed | **{fmt('source_changed')}** |\n"
        f"| Merged pull requests | **{fmt('merged_prs')}** |\n"
        f"| Closed issues (excluding pull requests) | **{fmt('closed_issues')}** |\n"
        f"| GitHub stars | {fmt('stars')} |\n"
        f"| GitHub forks | {fmt('forks')} |\n"
        f"| Intended class/spec/roles | **{fmt('roles')}** |\n"
        f"| Supported / blocked roles | {fmt('supported')} / {fmt('blocked')} |\n"
        f"| Catalogued APL revisions | **{fmt('apl_revisions')}** |\n"
        f"| Approved roles (catalogue status) | **{fmt('approved_roles')}** |\n\n"
        "**How the numbers work:** Git commits/line changes come from this public "
        "checkout's complete main history. Line changes sum Git additions and "
        "deletions, **not unique lines of code**, and **include the clean-history "
        "migration of pre-existing APLs**. The source subset covers APL text "
        "under roles/, Python, Lua and YAML. Merged PRs and closed non-PR "
        "issues come from GitHub's separate filtered search queries. "
        "Role counts come from catalogue/roles.json. No private Git "
        "history, historical private PRs or private Actions logs are counted.\n\n"
        "**These are fun facts, not quality scores.** CI correctness, "
        "immutable rollbacks, source-native tests and real gameplay evidence "
        "matter more than commit volume. An imported Draft is not Approved.\n\n"
        "[Repository](https://github.com/tkbiccay/APLForever-Open) · "
        "[Priorities](https://github.com/tkbiccay/APLForever-Open/blob/main/docs/PROJECT_PRIORITIES.md) · "
        "[Live workflow summaries](https://github.com/tkbiccay/APLForever-Open/actions/workflows/project-fun-facts.yml)\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if os.environ.get("GITHUB_REPOSITORY", REPOSITORY) != REPOSITORY:
        parser.error("Only run against canonical APLForever-Open")
    result = make_snapshot(ROOT, os.environ.get("GITHUB_TOKEN", ""))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(render(result), encoding="utf-8")
    print(
        f"Public project stats: {result['commits']} commits, "
        f"{result['merged_prs']} merged PRs, {result['closed_issues']} closed issues, "
        f"{result['text_changed']} text lines changed, "
        f"{result['approved_roles']} Approved roles."
    )


if __name__ == "__main__":
    main()
