#!/usr/bin/env python3
"""Safely prune merged same-repository PR branches (never unmerged work or main).

Read-only by default. --apply is authorised only on GitHub Actions' main ref.
No PAT, external dependencies, or code from pull-request branches.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict

API = "https://api.github.com"
SHA = re.compile(r"[0-9a-f]{40}\Z")
SAFE_BRANCH = re.compile(r"[A-Za-z0-9._/-]+\Z")


def _head(pr: dict, repository: str) -> tuple[str, str] | None:
    head = pr.get("head") or {}
    source = head.get("repo") or {}
    name, sha = head.get("ref"), head.get("sha")
    if (source.get("full_name", "").casefold() != repository.casefold()
            or not isinstance(name, str) or not isinstance(sha, str)
            or not SHA.fullmatch(sha)):
        return None
    return name, sha


def select_candidates(branches: list[dict], pulls: list[dict],
                      repository: str, default_branch: str) -> list[dict]:
    """Pure fail-closed selection, easy to test without GitHub access."""
    open_names: set[str] = set()
    merged: dict[tuple[str, str], list[int]] = defaultdict(list)
    for pr in pulls:
        head = _head(pr, repository)
        if head is None:
            continue
        if pr.get("state") == "open":
            open_names.add(head[0])
        elif pr.get("merged_at") and type(pr.get("number")) is int:
            merged[head].append(pr["number"])

    results = []
    for branch in branches:
        name = branch.get("name")
        sha = (branch.get("commit") or {}).get("sha")
        if (not isinstance(name, str) or not SAFE_BRANCH.fullmatch(name)
                or name.startswith("/") or name.endswith("/")
                or ".." in name or name in {".", "HEAD", default_branch}
                or branch.get("protected") is not False
                or name in open_names or not isinstance(sha, str)
                or not SHA.fullmatch(sha)):
            continue
        linked = merged.get((name, sha))
        if linked:
            results.append({"branch": name, "sha": sha, "merged_prs": sorted(linked)})
    return sorted(results, key=lambda row: row["branch"])


class GitHub:
    def __init__(self, token: str, repository: str):
        if not token or not re.fullmatch(r"[\w.-]+/[\w.-]+", repository):
            raise ValueError("GH_TOKEN and a valid GITHUB_REPOSITORY are required")
        self.repo = repository
        self.token = token

    def request(self, path: str, method: str = "GET") -> object:
        req = urllib.request.Request(
            API + "/repos/" + self.repo + path,
            method=method,
            headers={
                "Authorization": "Bearer " + self.token,
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
                "User-Agent": "APLForever-merged-branch-cleanup",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=25) as response:
                if response.status == 204:
                    return None
                return json.load(response)
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                return None
            raise RuntimeError(f"GitHub {method} {path}: HTTP {exc.code}") from exc

    def all_pages(self, path: str) -> list[dict]:
        results = []
        for page in range(1, 31):
            separator = "&" if "?" in path else "?"
            batch = self.request(f"{path}{separator}per_page=100&page={page}")
            if not isinstance(batch, list):
                raise RuntimeError("GitHub list endpoint did not return a list")
            results.extend(batch)
            if len(batch) < 100:
                return results
        raise RuntimeError("GitHub result exceeds 3,000 rows: fail closed, not partial cleanup")


def check_live_branch(client: GitHub, item: dict, default_branch: str,
                      active_open_names: set[str]) -> tuple[bool, str]:
    name = item["branch"]
    if name == default_branch or name in active_open_names:
        return False, "protected default / open PR"
    encoded = urllib.parse.quote(name, safe="")
    branch = client.request("/branches/" + encoded)
    if not isinstance(branch, dict):
        return False, "branch already absent"
    if branch.get("protected") is not False:
        return False, "protected branch"
    if (branch.get("commit") or {}).get("sha") != item["sha"]:
        return False, "branch head moved since merged PR"
    ref = client.request("/git/ref/heads/" + urllib.parse.quote(name, safe="/"))
    if not isinstance(ref, dict) or ref.get("ref") != "refs/heads/" + name:
        return False, "Git ref absent or unexpected"
    if (ref.get("object") or {}).get("sha") != item["sha"]:
        return False, "Git ref changed since merge"
    return True, "exact merged head, unprotected, no open PR"


def report(deleted: list[str], skipped: list[str], eligible: int, apply: bool) -> None:
    mode = "APPLIED" if apply else "DRY RUN"
    lines = [
        f"## Safe merged-branch cleanup — {mode}",
        "",
        f"- Eligible exact-head merged branches: **{eligible}**",
        f"- Deleted: **{len(deleted) if apply else 0}**",
        f"- Dry-run eligible: **{len(deleted) if not apply else 0}**",
        f"- Skipped after recheck: **{len(skipped)}**",
        "- Protected main, forks, changed heads and branches with open PRs never qualify.",
    ]
    if deleted:
        lines += ["", "### Deleted or dry-run eligible", *("- " + name for name in deleted)]
    if skipped:
        lines += ["", "### Skipped", *("- " + row for row in skipped)]
    summary = "\n".join(lines) + "\n"
    print(summary, flush=True)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as handle:
            handle.write(summary)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="delete eligible refs; default is dry run")
    args = parser.parse_args()
    if args.apply and os.getenv("GITHUB_REF") != "refs/heads/main":
        parser.error("--apply is permitted only on the protected main branch")
    client = GitHub(os.environ.get("GH_TOKEN", ""), os.environ.get("GITHUB_REPOSITORY", ""))
    info = client.request("")
    if not isinstance(info, dict):
        raise RuntimeError("failed to read repository metadata")
    default = info.get("default_branch")
    if default != "main" or info.get("full_name", "").casefold() != client.repo.casefold():
        raise RuntimeError("expected APLForever repository with default branch main")
    branches = client.all_pages("/branches")
    pulls = client.all_pages("/pulls?state=all")
    plan = select_candidates(branches, pulls, client.repo, default)
    now_open = client.all_pages("/pulls?state=open")
    active = {head[0] for pr in now_open if (head := _head(pr, client.repo)) is not None}
    deleted, skipped = [], []
    for item in plan:
        ok, reason = check_live_branch(client, item, default, active)
        if not ok:
            skipped.append(f"{item['branch']}: {reason}")
            continue
        name = item["branch"]
        if args.apply:
            latest = client.all_pages("/pulls?state=open")
            latest_open = {h[0] for pr in latest if (h := _head(pr, client.repo)) is not None}
            if name in latest_open:
                skipped.append(f"{name}: new open PR")
                continue
            client.request("/git/refs/heads/" + urllib.parse.quote(name, safe="/"), "DELETE")
            remaining = client.request("/git/ref/heads/" + urllib.parse.quote(name, safe="/"))
            if remaining is not None:
                raise RuntimeError(f"branch still exists after DELETE: {name}")
        deleted.append(name)
    report(deleted, skipped, len(plan), args.apply)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, ValueError, OSError, urllib.error.URLError) as exc:
        print(f"merged-branch cleanup: FAIL CLOSED: {exc}", file=sys.stderr)
        sys.exit(1)
