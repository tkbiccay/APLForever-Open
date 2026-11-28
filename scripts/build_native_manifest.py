#!/usr/bin/env python3
"""Build a verified Lua manifest for the pinned Hekili native preflight."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any
import re

ROOT = Path(__file__).resolve().parents[1]
PILOT_ROLES = ("Warrior_Protection", "Druid_Guardian", "Warlock_Demonology")
PROTECTED_SOURCE_RELEASE = "v0.8.2"


def _version(value: str) -> tuple[int, int, int]:
    match = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", value)
    if not match:
        raise ValueError(f"invalid released Hekili Forever source version: {value!r}")
    return tuple(int(part) for part in match.groups())


def _compatible(revision: dict[str, Any], source_release: str) -> bool:
    minimum = revision.get("min_source_release", PROTECTED_SOURCE_RELEASE)
    if not isinstance(minimum, str):
        raise ValueError(f"invalid min_source_release for {revision.get('apl_file')}")
    return _version(source_release) >= _version(minimum)


def select_revision(role: dict[str, Any], source_release: str) -> dict[str, Any]:
    """Select a compatible native TEST reference, not an APL promotion.

    An explicit catalogue preferred_apl wins when compatible. Otherwise use
    Current, then a historical Archive if the Current file requires a later
    source release (e.g. archived Hunter BM v1.0 on v0.8.2). Never let a newly
    added unselected Candidates revision displace a stable test reference
    simply because its version is higher. If nothing safe is available, fail
    closed rather than silently treating a Candidate as the selected APL.
    """
    eligible = [revision for revision in role["revisions"] if _compatible(revision, source_release)]
    if not eligible:
        raise ValueError(f"no source-compatible revision for {role['apl_name']} on {source_release}")
    preferred = role.get("preferred_apl")
    if preferred:
        found = next((revision for revision in eligible if revision["apl_file"] == preferred), None)
        if found is not None:
            return found

    # Explicit historical test reference preserves comparator bytes after relocation.
    explicit_test = role.get("native_test_apl")
    if explicit_test:
        found = next((revision for revision in eligible if revision["apl_file"] == explicit_test), None)
        if found is not None:
            return found

    def newest_in(folder: str) -> dict[str, Any] | None:
        candidates = [
            revision for revision in eligible
            if folder in Path(revision["apl_file"]).parts
        ]
        if not candidates:
            return None
        return max(
            candidates,
            key=lambda rev: tuple(int(part) for part in rev["revision"][1:].split("."))
        )

    selected = newest_in("Current") or newest_in("Archive")
    if selected is None:
        raise ValueError(
            f"no compatible Current/Archive test reference for {role['apl_name']} "
            f"on {source_release}; unselected Candidates cannot auto-promote"
        )
    return selected


def _lua_string(value: str) -> str:
    """Quote the ASCII catalogue values as Lua 5.1 string literals."""
    if not value.isascii():
        raise ValueError(f"native manifest field must be ASCII: {value!r}")
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def build_manifest(root: Path = ROOT, source_release: str = PROTECTED_SOURCE_RELEASE) -> tuple[list[dict[str, Any]], int]:
    _version(source_release)
    data = json.loads((root / "catalogue" / "roles.json").read_text(encoding="utf-8-sig"))
    roles = [role for role in data["roles"] if role.get("support_status") == "Supported"]
    by_name = {role["apl_name"]: role for role in roles}
    if len(roles) != 23 or len(by_name) != 23:
        raise ValueError(f"expected 23 unique supported roles, found {len(by_name)}")

    selected: list[tuple[dict[str, Any], dict[str, Any], bool]] = []
    for apl_name in PILOT_ROLES:
        role = by_name.get(apl_name)
        if role is None:
            raise ValueError(f"pilot role is not Supported: {apl_name}")
        for revision in role["revisions"]:
            if _compatible(revision, source_release):
                selected.append((role, revision, True))

    for role in roles:
        if role["apl_name"] in PILOT_ROLES:
            continue
        revision = select_revision(role, source_release)
        selected.append((role, revision, False))

    verified_revisions = 0
    for role in data["roles"]:
        for revision in role["revisions"]:
            path = root / revision["apl_file"]
            actual = hashlib.sha256(path.read_bytes()).hexdigest()
            if actual != revision["sha256"]:
                raise ValueError(f"SHA-256 mismatch: {revision['apl_file']}")
            verified_revisions += 1

    manifest = []
    seen_roles: set[str] = set()
    for role, revision, pilot in selected:
        manifest.append({
            "apl_name": role["apl_name"],
            "class": role["class"],
            "spec": role["spec"],
            "role": role["role"],
            "revision": revision["revision"],
            "status": revision["status"],
            "apl_file": revision["apl_file"],
            "sha256": revision["sha256"],
            "pilot": pilot,
        })
        seen_roles.add(role["apl_name"])

    if seen_roles != set(by_name):
        raise ValueError(f"native manifest role coverage mismatch: {sorted(set(by_name) - seen_roles)}")
    return manifest, verified_revisions


def write_lua_manifest(entries: list[dict[str, Any]], destination: Path) -> None:
    fields = ("apl_name", "class", "spec", "role", "revision", "status", "apl_file", "sha256")
    lines = ["return {"]
    for item in entries:
        values = [f"{field} = {_lua_string(item[field])}" for field in fields]
        values.append(f"pilot = {'true' if item['pilot'] else 'false'}")
        lines.append("    { " + ", ".join(values) + " },")
    lines.append("}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="generated Lua manifest path")
    parser.add_argument("--source-release", required=True, help="exact checked-out released version, e.g. v0.8.5")
    args = parser.parse_args()
    try:
        entries, verified = build_manifest(source_release=args.source_release)
        write_lua_manifest(entries, args.output)
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
        parser.exit(1, f"native manifest: FAIL: {exc}\n")
    print(f"native manifest source: {args.source_release}")
    print(f"native manifest: {len({row['apl_name'] for row in entries})} roles; "
          f"{len(entries)} exact APL revisions selected; {verified} catalogue SHA-256 values verified.")
    print(f"native manifest: wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
