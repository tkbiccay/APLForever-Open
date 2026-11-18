#!/usr/bin/env python3
"""Fast, offline public-repo provenance/safety gate.

This is NOT a security audit or Hekili runtime validation. It intentionally
fails on missing public governance files and checks imported APL hashes when
catalogue metadata and roles are present.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = (
    "README.md", "LICENSE", "AGENTS.md", "GOVERNANCE.md", "CONTRIBUTING.md",
    "SECURITY.md", "THIRD_PARTY_NOTICES.md", "PUBLIC_MIGRATION.md",
    ".github/CODEOWNERS", ".gitattributes",
)
TOKEN = re.compile(r"(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{40,})")
MARKER = "tkbiccay/APLForever-Open"


def check() -> list[str]:
    errors = []
    for name in REQUIRED:
        if not (ROOT / name).is_file():
            errors.append("Missing required public file: " + name)
    license_path = ROOT / "LICENSE"
    if license_path.is_file():
        body = license_path.read_text(encoding="utf-8", errors="replace")
        if "GNU GENERAL PUBLIC LICENSE" not in body or "Version 3, 29 June 2007" not in body:
            errors.append("LICENSE is not the expected GPLv3 text")
    readme = ROOT / "README.md"
    if readme.is_file() and MARKER not in readme.read_text(encoding="utf-8"):
        errors.append("README does not point to canonical public repository")
    attrib = ROOT / ".gitattributes"
    if attrib.is_file() and "roles/**/*.txt -text" not in attrib.read_text(encoding="utf-8"):
        errors.append("APL exact-byte .gitattributes protection missing")
    for name in ("README.md", "AGENTS.md", "GOVERNANCE.md", "PUBLIC_MIGRATION.md"):
        path = ROOT / name
        if path.is_file() and TOKEN.search(path.read_text(encoding="utf-8")):
            errors.append("Possible literal GitHub credential in " + name)
    catalogue = ROOT / "catalogue/roles.json"
    if catalogue.exists():
        try:
            roles = json.loads(catalogue.read_text(encoding="utf-8-sig"))["roles"]
            if len(roles) != 28:
                errors.append("Expected 28 intended roles after migration")
            n = 0
            for role in roles:
                for revision in role.get("revisions", []):
                    relative = revision["apl_file"]
                    path = (ROOT / relative).resolve()
                    if not path.is_relative_to(ROOT.resolve()):
                        errors.append("APL path escapes repository: " + relative)
                        continue
                    if not path.is_file():
                        errors.append("Missing catalogued APL: " + relative)
                    elif hashlib.sha256(path.read_bytes()).hexdigest() != revision["sha256"]:
                        errors.append("APL SHA256 mismatch: " + relative)
                    n += 1
            if n == 0:
                errors.append("Catalogue imported but contains no historical APL revisions")
        except (ValueError, KeyError, TypeError, OSError) as exc:
            errors.append("Invalid catalogue: " + type(exc).__name__)
    return errors


def main() -> int:
    errors = check()
    for line in errors:
        print("ERROR:", line)
    if errors:
        print("FAIL: Public source gate")
        return 1
    if (ROOT / "catalogue/roles.json").is_file():
        print("OK: public governance + exact-byte catalogue APL gate")
    else:
        print("OK: public governance bootstrap; historical APLs NOT YET IMPORTED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
