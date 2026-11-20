#!/usr/bin/env python3
"""Source-only all-APL control audit: flag *new* settings dependencies.

No source-native casts, cooldown availability or game behaviour are proven by
this audit. Historical settings-bearing APLs are protected, not approved. All
toggle.* usages are inventory only: off switches and core gates need semantic
review against the actually released Hekili ability Require Toggle fields.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOKEN = re.compile(r"(?<![\w.])(settings|toggle)\.([a-z_][a-z0-9_]*)\b")

# Exceptions document exact pre-policy bytes, not permission to create a new
# settings-dependent APL or select one as Approved. New Sha -> fails closed.
HISTORICAL_SETTINGS = {
    ("roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt",
     "f386e158a5e262e309dac7d0fd2929fb8e16e02b1378d71b5956c1bf6b99a786"):
        {"settings.maintain_demoralizing_roar"},
    ("roles/Warlock/Current/APL_Warlock_Demonology_DPS_v1.0_ReportedWorking.txt",
     "067ae757344a71f4a0d02f0a18e2f36745ceb8c0015761970948381aba8e7bf7"):
        {"settings.assigned_curse"},
    ("roles/Warlock/Archive/APL_Warlock_Demonology_DPS_v0.8_Default.txt",
     "da6e5b71c3fc8710745e4ef7037faf5c810958186508b870b3596334d19d3241"):
        {"settings.assigned_curse"},
    # A previously produced v1.3 Draft on PR #22, historically BEFORE the
    # 20 Nov maintainer-wide rule. v1.4 is intended to supersede it.
    ("roles/Druid/Candidates/APL_Druid_Guardian_v1.3_Draft.txt",
     "200d7109ffcc345c41b05312a49b658b9a456a6f17fb56ea952f84d1d57079e0"):
        {"settings.maintain_demoralizing_roar"},
}


def references(source: str) -> tuple[list[dict], list[dict]]:
    """Report exact source refs without treating toggle OFF as an APL bug."""
    settings, toggles = [], []
    for line_number, line in enumerate(source.splitlines(), 1):
        if line.lstrip().startswith("#"):
            continue
        for match in TOKEN.finditer(line):
            obj = {"line": line_number, "name": f"{match[1]}.{match[2]}",
                   "action": line.strip()}
            (settings if match[1] == "settings" else toggles).append(obj)
    return settings, toggles


def new_dependencies(path: str, digest: str, settings: list[dict]) -> list[str]:
    """Constrain legacy exemptions by both content hash and exact source key."""
    allowed = HISTORICAL_SETTINGS.get((path, digest), set())
    return [f"{path}:{r['line']}: new required setting dependency {r['name']}"
            for r in settings if r["name"] not in allowed]


def analyse(root: Path = ROOT) -> tuple[list[dict], list[str]]:
    catalogue = json.loads((root / "catalogue/roles.json").read_text(encoding="utf-8-sig"))
    rows, errors = [], []
    for role in catalogue["roles"]:
        for revision in role["revisions"]:
            path = revision["apl_file"]
            source_path = root / path
            if not source_path.is_file():
                errors.append(f"{path}: no source file")
                continue
            raw = source_path.read_bytes()
            digest = hashlib.sha256(raw).hexdigest()
            if digest != revision["sha256"]:
                errors.append(f"{path}: protected SHA-256 mismatch")
                continue
            settings, toggles = references(raw.decode("utf-8-sig"))
            errors.extend(new_dependencies(path, digest, settings))
            rows.append({
                "role": role["apl_name"],
                "revision": revision["revision"],
                "status": revision["status"],
                "path": path,
                "sha256": digest,
                "selected": role.get("preferred_apl") == path,
                "settings": settings, "toggles": toggles,
                "historical_setting_debt": bool(settings)
                    and not new_dependencies(path, digest, settings),
            })
    return rows, errors


def summary(rows: list[dict]) -> str:
    lines = [
        "# APLForever all-revision autonomous-control inventory",
        "",
        "Static only. A toggle reference is not automatically defective and an "
        "old-settings exemption is NOT approval. All-role source/cast and "
        "gameplay gates remain separate.",
        "",
        f"Revisions inspected: **{len(rows)}**. "
        f"Settings-bearing: **{sum(bool(x['settings']) for x in rows)}**. "
        f"Toggle-bearing: **{sum(bool(x['toggles']) for x in rows)}**.",
        "",
        "| Role / revision | Selected? | Per-spec setting refs | Toggle refs (review, not failure) |",
        "| --- | --- | --- | --- |",
    ]
    for row in rows:
        s = ", ".join(sorted({x["name"] for x in row["settings"]})) or "—"
        t = ", ".join(sorted({x["name"] for x in row["toggles"]})) or "—"
        lines.append(f"| {row['role']} {row['revision']} | "
                     f"{'Yes' if row['selected'] else 'No'} | {s} | {t} |")
    lines += ["", "For classification and upgrade priorities, see "
              "`docs/APL_AUTONOMY_STANDARD.md`. A pure text scan "
              "does not establish that a native Require Toggle gate is absent, "
              "or that a listed action is optional versus core.",
              ""]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail on new settings references")
    parser.add_argument("--report", type=Path, help="write review-only Markdown inventory")
    args = parser.parse_args()
    rows, errors = analyse()
    report = summary(rows)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(report, encoding="utf-8")
    print(f"APL control audit: {len(rows)} revisions; "
          f"{sum(bool(r['settings']) for r in rows)} exact historical settings-bearing; "
          f"{sum(bool(r['toggles']) for r in rows)} toggle-bearing (review only)")
    for err in errors:
        print("FAIL: " + err)
    return 1 if args.check and errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
