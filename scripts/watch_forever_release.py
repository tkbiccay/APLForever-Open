#!/usr/bin/env python3
"""Monitor *published* zmsl/hekili releases, never edit upstream or APLs.

Daily / manual GitHub Action: compare a pinned local release record to GitHub's
published latest stable release. Create one deduplicated compatibility-triage
issue ONLY for a newer release. No automatic APL edits, CI claims or promotion.
By default, dry-run. --apply requires official protected-main Actions context.
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
from pathlib import Path

OWNER = "tkbiccay/APLForever-Open"
UPSTREAM = "zmsl/hekili"
API = "https://api.github.com"
LEDGER = "docs/knowledge/engine/current-release.json"
VERSION = re.compile(r"v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\Z")
SHA = re.compile(r"[0-9a-f]{40}\Z")
TITLE_PREFIX = "Upstream Hekili Forever "


def semver(value: str) -> tuple[int, int, int]:
    match = VERSION.fullmatch(value) if isinstance(value, str) else None
    if not match:
        raise ValueError(f"invalid published Forever release version: {value!r}")
    return tuple(int(x) for x in match.groups())


def read_pin(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1 or data.get("upstream_repository") != UPSTREAM:
        raise ValueError("pinned release file has unsupported schema or upstream")
    semver(data.get("release_tag"))
    if not SHA.fullmatch(data.get("release_commit", "")):
        raise ValueError("pinned release commit must be a verified 40-digit SHA")
    return data


def ticket(tag: str, commit: str, published_at: str) -> tuple[str, str]:
    semver(tag)
    if not SHA.fullmatch(commit):
        raise ValueError("cannot publish issue without exact upstream release commit")
    if not isinstance(published_at, str) or not published_at.endswith("Z"):
        raise ValueError("missing GitHub release publication timestamp")
    title = TITLE_PREFIX + tag + " — compatibility triage"
    body = f"""## Newly published Hekili Forever release (automated detection)

- **Project boundary:** APLForever develops **our own** standalone APLs. We do **not** develop, maintain or control the external Hekili Forever addon.
- **Verified upstream release:** https://github.com/zmsl/hekili/releases/tag/{tag}
- **Published at (UTC):** {published_at}
- **Resolved upstream commit:** `{commit}`
- **Official source repository:** https://github.com/zmsl/hekili
- **Local pinned baseline:** [current-release.json](https://github.com/tkbiccay/APLForever-Open/blob/main/docs/knowledge/engine/current-release.json)
- **Release process:** [RELEASE_LEDGER.md](https://github.com/tkbiccay/APLForever-Open/blob/main/docs/knowledge/engine/RELEASE_LEDGER.md)

### Manual compatibility checklist — no APLs automatically modified

- [ ] Confirm published tag and immutable commit; compare current validated baseline and new release notes/source, default packs, class kits, Belief/API/line options and official documentation.
- [ ] Keep shipped default **and** exact preferred/last-working APL hashes and rollbacks; identify impacted specs. Check our Guardian Tank + Hunter BM co-priority first, then Feral DPS and risk-based remaining roles.
- [ ] Run repository hashes and targeted **released-source native** import/compile/castability, toggles, progression, resource/level boundaries, and final/repeated recommendation checks. Broad all-role suite only when a change justifies it.
- [ ] Distinguish changed engine, inaccurate fixture, genuinely unsafe APL, and unobservable gameplay. Preserve genuine FAIL/BLOCKED results. Do not copy the shipped default or fake resources/health/pet status to obtain a PASS.
- [ ] Add only complete standalone **unselected Candidates** for verified, necessary changes; compare shipped, previous working and Candidate under matched conditions.
- [ ] Update release ledger and exact version pin **after review**, including partial or blocked findings. Any in-game or Approved status still needs the maintainer's explicit validation.

**Automated issue creation does not claim that the release is compatible or that a current APL is broken.** Do not change the protected public main or historical private archive automatically.
"""
    return title, body


def assess(latest: dict, pinned: dict, existing_issue_titles: set[str],
           commit: str) -> tuple[str, str | None, str | None]:
    if latest.get("draft") or latest.get("prerelease"):
        raise ValueError("latest GitHub release was not published as stable")
    version = latest.get("tag_name")
    wanted = semver(version)
    current = semver(pinned["release_tag"])
    if wanted <= current:
        return "pinned-current-or-newer", None, None
    title, body = ticket(version, commit, latest.get("published_at"))
    if title in existing_issue_titles:
        return "already-tracked", title, None
    return "new-release", title, body


class GitHub:
    def __init__(self, token: str):
        self.token = token

    def request(self, path: str, method: str = "GET", payload: dict | None = None):
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        request = urllib.request.Request(
            API + path, data=data, method=method,
            headers={
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
                "User-Agent": "APLForever-published-release-watch",
                **({"Authorization": "Bearer " + self.token} if self.token else {}),
                **({"Content-Type": "application/json"} if data is not None else {}),
            },
        )
        with urllib.request.urlopen(request, timeout=20) as response:
            return json.load(response)

    def resolved_commit(self, tag: str) -> str:
        semver(tag)
        value = self.request(f"/repos/{UPSTREAM}/git/ref/tags/{tag}")
        item = value.get("object") or {}
        if item.get("type") == "tag":
            value = self.request(f"/repos/{UPSTREAM}/git/tags/{item['sha']}")
            item = value.get("object") or {}
        if item.get("type") != "commit" or not SHA.fullmatch(item.get("sha", "")):
            raise ValueError("release tag does not resolve to an immutable git commit")
        return item["sha"]

    def issue_titles(self) -> set[str]:
        names = set()
        # Full pagination avoids a false duplicate miss when old releases grow.
        for page in range(1, 31):
            rows = self.request(
                f"/repos/{OWNER}/issues?state=all&per_page=100&page={page}"
            )
            if not isinstance(rows, list):
                raise ValueError("unexpected issue list; do not open duplicate ticket")
            for row in rows:
                if "pull_request" not in row and isinstance(row.get("title"), str):
                    names.add(row["title"])
            if len(rows) < 100:
                return names
        raise ValueError("issue list exceeded 3,000 rows; fail closed")


def output_summary(message: str) -> None:
    print(message)
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a", encoding="utf-8") as handle:
            handle.write("## Hekili Forever published-release watch\n\n" + message + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true",
                        help="create a single issue for a newer published release")
    args = parser.parse_args()
    if args.apply and (
        os.environ.get("GITHUB_REF") != "refs/heads/main"
        or os.environ.get("GITHUB_REPOSITORY") != OWNER
    ):
        parser.error("--apply is only allowed in the official repository's main workflow")
    pin = read_pin(Path(LEDGER))
    api = GitHub(os.environ.get("GH_TOKEN", ""))
    release = api.request(f"/repos/{UPSTREAM}/releases/latest")
    if not isinstance(release, dict):
        raise ValueError("GitHub latest-release endpoint did not return a release")
    tag = release.get("tag_name")
    semver(tag)
    # Resolve only *newer* release refs: unchanged-day checks should be cheap.
    if semver(tag) <= semver(pin["release_tag"]):
        output_summary(f"Published latest: **{tag}**; pinned: **{pin['release_tag']}**. "
                       "No new release, no source-native rerun, no APL changes.")
        return 0
    sha = api.resolved_commit(tag)
    state, title, body = assess(release, pin, api.issue_titles(), sha)
    if state == "new-release" and args.apply:
        if not api.token:
            raise ValueError("no GitHub token: cannot create release triage issue")
        created = api.request(f"/repos/{OWNER}/issues", "POST",
                              {"title": title, "body": body})
        if not isinstance(created, dict) or not created.get("html_url"):
            raise ValueError("GitHub did not confirm issue creation")
        output_summary(f"Published **{tag}** at commit \`{sha}\`; opened "
                       f"compatibility issue {created['html_url']}. "
                       "No APLs were changed or approved.")
    else:
        output_summary(f"Published **{tag}** at commit \`{sha}\`; {state}. "
                       + ("Dry-run only; issue would be created." if state == "new-release"
                          else "No duplicate issue created.")
                       + " No APLs were changed or approved.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, TypeError, urllib.error.URLError) as exc:
        print("published-release watch failed closed: " + str(exc), file=sys.stderr)
        sys.exit(1)
