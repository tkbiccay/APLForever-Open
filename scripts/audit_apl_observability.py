#!/usr/bin/env python3
"""Audits secret/fixed Forever APL conditions; no simulation or approval claims.

Scans hash-verified historical and current APLs. Resolves named action-list
calls to distinguish combat reachability from precombat-only expressions.
Known historical findings are exact path+SHA+signature debt, not blanket
exemptions. New/changed findings cause a CI failure.
"""
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASELINE = "docs/knowledge/engine/observability-baseline.json"
EVIDENCE = "docs/knowledge/engine/headless-evidence.json"
ACTION = re.compile(r"^\s*actions(?:\.([a-z0-9_]+))?\+?=(.*)$")
LIST_NAME = re.compile(r"(?:^|,)name=([a-z0-9_]+)(?:,|$)")
RULES = {
    "player_health": re.compile(
        r"(?<![\w.])health(?:\.(?:pct|percent|current|actual|deficit)\b|\b(?![\w.]))"
    ),
    "target_health": re.compile(
        r"(?<![\w.])target\.health(?:\.(?:pct|percent|current|actual)\b|_(?:pct|percent|current)\b)"
    ),
    "hidden_incoming": re.compile(
        r"(?<![\w.])incoming_(?:(?:physical|magic)_)?(?:damage|heal)_\d+s\b"
    ),
    "group_health": re.compile(r"(?<![\w.])(?:group_health|at_risk)\b"),
    "fixed_fight_time": re.compile(
        r"(?<![\w.])(?:fight_remains|time_to_die|target\.time_to_die|target\.time_to_pct_\d+)\b"
    ),
}


def action_lines(source: str) -> list[tuple[int, str, str]]:
    rows = []
    for index, line in enumerate(source.splitlines(), 1):
        if line.lstrip().startswith("#"):
            continue
        match = ACTION.match(line)
        if match:
            rows.append((index, match.group(1) or "default", match.group(2)))
    return rows


def phases(rows: list[tuple[int, str, str]]) -> dict[str, str]:
    links: dict[str, set[str]] = collections.defaultdict(set)
    lists = {list_name for _, list_name, _ in rows}
    for _, origin, rhs in rows:
        if rhs.split(",", 1)[0].strip() in {"call_action_list", "run_action_list"}:
            called = LIST_NAME.search(rhs)
            if called:
                links[origin].add(called.group(1))

    def reachable(start: str) -> set[str]:
        if start not in lists:
            return set()
        seen, pending = set(), [start]
        while pending:
            name = pending.pop()
            if name in seen:
                continue
            seen.add(name)
            pending.extend(links.get(name, set()) - seen)
        return seen

    combat, precombat = reachable("default"), reachable("precombat")
    return {
        name: ("combat" if name in combat
               else "precombat" if name in precombat
               else "unreachable/unproven")
        for name in lists
    }


def scan_apl(source: str) -> list[dict]:
    rows = action_lines(source)
    phase_map = phases(rows)
    findings = []
    for line_num, list_name, rhs in rows:
        for rule, regex in RULES.items():
            for match in regex.finditer(rhs):
                findings.append({
                    "line": line_num, "list": list_name,
                    "phase": phase_map[list_name], "rule": rule,
                    "token": match.group(),
                })
    return findings


def signatures(findings: list[dict]) -> dict[str, int]:
    return dict(sorted(collections.Counter(
        item["rule"] + ":" + item["phase"] for item in findings
    ).items()))


def analyse(root: Path) -> tuple[list[dict], list[dict]]:
    catalogue = json.loads((root / "catalogue/roles.json").read_text(encoding="utf-8-sig"))
    if catalogue.get("schema_version") != 1 or len(catalogue["roles"]) != 28:
        raise ValueError("expected original 28-role catalogue schema")
    rows, flagged, seen = [], [], set()
    for role in catalogue["roles"]:
        for revision in role["revisions"]:
            path = revision["apl_file"]
            if path in seen or not path.startswith("roles/") or ".." in Path(path).parts:
                raise ValueError("unsafe or repeated catalogue path: " + path)
            seen.add(path)
            raw = (root / path).read_bytes()
            sha = hashlib.sha256(raw).hexdigest()
            if sha != revision["sha256"]:
                raise ValueError("immutable APL hash mismatch: " + path)
            findings = scan_apl(raw.decode("utf-8-sig"))
            row = {
                "role": role["apl_name"], "revision": revision["revision"],
                "path": path, "sha256": sha, "status": revision["status"],
                "selected": path == role.get("preferred_apl"),
                "findings": findings, "signatures": signatures(findings),
            }
            rows.append(row)
            if findings:
                flagged.append(row)
    if len(rows) < 23:
        raise ValueError("too few imported APLs in catalogue")
    return rows, flagged


def compare_baseline(flagged: list[dict], baseline: dict) -> list[str]:
    if baseline.get("schema_version") != 1:
        return ["unknown observability baseline schema"]
    expected = baseline.get("known_findings")
    if not isinstance(expected, list):
        return ["missing known_findings list"]
    problems, seen = [], set()
    for entry in expected:
        if entry["path"] in seen:
            problems.append("duplicate baseline path: " + entry["path"])
        seen.add(entry["path"])
        if not re.fullmatch(r"[0-9a-f]{64}", entry.get("sha256", "")):
            problems.append("bad baseline SHA: " + entry["path"])
        if not entry.get("reference_url", "").startswith("https://"):
            problems.append("missing source/issue reference: " + entry["path"])
    current = {row["path"]: row for row in flagged}
    known = {row["path"]: row for row in expected}
    for path in sorted(set(current) | set(known)):
        actual, pinned = current.get(path), known.get(path)
        if pinned is None:
            problems.append("NEW source-state exposure " + path + ": " +
                            str(actual["signatures"]))
        elif actual is None:
            problems.append("historical issue disappeared; review and update: " + path)
        elif actual["sha256"] != pinned["sha256"] or actual["signatures"] != pinned["signatures"]:
            problems.append("baseline mismatch in " + path + ", detected " +
                            str(actual["signatures"]) + ", pinned " +
                            str(pinned["signatures"]))
    return problems


def report(rows: list[dict], flagged: list[dict], evidence: dict,
           problems: list[str]) -> str:
    per_role: dict[str, list[dict]] = collections.defaultdict(list)
    for row in rows:
        per_role[row["role"]].append(row)
    version, scopes = evidence["source_release"], evidence["role_scopes"]
    lines = [
        "# Generated headless evidence matrix",
        "",
        "Static scan + manually pinned source-native evidence. This is not "
        "a fresh gameplay run or full approval.",
        "",
        f"- Inspected: {len(rows)} SHA-verified APLs across {len(per_role)} roles",
        f"- Known historical findings: {len(flagged)} revisions, " +
        str(sum(len(item["findings"]) for item in flagged)) + " expression occurrences",
        f"- New/changed findings: {len(problems)} (nonzero fails CI)",
        f"- Latest published: {version}; full all-role release compatibility: " +
        "Partial / Blocked (" + evidence["full_release_run"] + ")",
        "",
        "| Role | Latest | Preferred | Static historical findings | Latest-release native |",
        "| --- | --- | --- | --- | --- |",
    ]
    for name, rr in sorted(per_role.items()):
        latest = max(rr, key=lambda x: tuple(int(n) for n in x["revision"][1:].split(".")))
        preferred = next((x["revision"] for x in rr if x["selected"]), "none")
        issues = sum(len(x["findings"]) for x in rr)
        scope = scopes.get(name)
        native = (scope["result"] + " (" + scope["revision"] +
                  "; " + scope["run_url"] + ")" if scope else
                  "Not individually established on " + version)
        lines.append(f"| {name} | {latest['revision']} | {preferred} | "
                     f"{issues} known findings | {native} |")
    lines += [
        "", "## Exact historic debt (preserve original APL files)", "",
        "| APL | Revision | Rule and reachability | Occurrences |",
        "| --- | --- | --- | ---: |",
    ]
    for row in sorted(flagged, key=lambda x: x["path"]):
        for key, count in row["signatures"].items():
            lines.append(f"| {row['path']} | {row['revision']} | {key} | {count} |")
    lines += [
        "", "## Boundaries", "",
        "- Potentially combat-reachable action lists are not proven executable; "
        "dynamic conditions, levels and dead branches need the real source engine.",
        "- Player health is hidden in combat, but may be readable in genuinely "
        "precombat-only action lists. Target health is bounded by available "
        "execute thresholds, not actual HP. Fight remains is fixed/unknown.",
        "- Full v0.10.0 all-role suite is still blocked by historical old APL "
        "warnings; focused Guardian and BM native steps do not override that.",
        "- No positive high-Rage Maul proof, actual main-pet recovery or "
        "in-game Approved status can be inferred from this table.", "",
    ]
    if problems:
        lines.extend(["## New findings requiring review", ""])
        lines.extend("- " + text for text in problems)
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    rows, flagged = analyse(ROOT)
    baseline = json.loads((ROOT / BASELINE).read_text(encoding="utf-8"))
    evidence = json.loads((ROOT / EVIDENCE).read_text(encoding="utf-8"))
    issues = compare_baseline(flagged, baseline)
    content = report(rows, flagged, evidence, issues)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(content, encoding="utf-8")
    if os.getenv("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as fh:
            fh.write(content)
    print(f"Observability: {len(rows)} protected APLs scanned, " +
          f"{len(flagged)} historical flagged files, {len(issues)} new findings")
    for issue in issues:
        print("FAIL: " + issue, file=sys.stderr)
    return int(bool(args.check and issues))


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, KeyError, TypeError, ValueError, UnicodeError) as exc:
        print("observability check failed closed: " + str(exc), file=sys.stderr)
        sys.exit(1)
