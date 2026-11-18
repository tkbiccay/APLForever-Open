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

    # Fail closed when a newly tracked public file resembles a leaked credential,
    # private CI reference or personal path. Never exclude all of tests/.
    import subprocess
    try:
        tracked = subprocess.check_output(
            ["git", "-C", str(ROOT), "ls-files", "-z"], stderr=subprocess.PIPE
        ).split(b"\x00")
    except (OSError, subprocess.CalledProcessError):
        errors.append("Cannot enumerate tracked files for public safety scan")
        tracked = []

    patterns = {
        "github_credential": TOKEN,
        "aws_key": re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b"),
        "private_key": re.compile(r"-----BEGIN (?:[A-Z ]* )?PRIVATE KEY-----"),
        "credential_assignment": re.compile(
            r"(?i)\b(?:password|passwd|api[_-]?key|client_secret|access[_-]?token)"
            r"\s*[:=]\s*['\"]?[A-Za-z0-9+/_=-]{16,}"
        ),
        "embedded_basic_auth": re.compile(r"https?://[^\s/:@]+:[^\s@]+@[^\s]+"),
        "private_ci_link": re.compile(
            r"https://github\.com/tkbiccay/APLForever/(?:actions|pull|issues)/"
        ),
        "personal_windows_path": re.compile(r"[A-Za-z]:\\Users\\[^\\\s]+"),
    }
    personal_mail = re.compile(r"\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")
    for name in tracked:
        if not name:
            continue
        relative = name.decode("utf-8", "replace")
        path = ROOT / relative
        if not path.is_file() or path.is_symlink():
            errors.append("Missing or symlink tracked file: " + relative)
            continue
        if re.search(r"(?i)(?:^|/)(?:\.env(?:\..*)?|id_rsa|id_ed25519|[^/]+\.(?:pem|p12|pfx|key|sqlite3?|log))$", relative):
            errors.append("Sensitive filename requiring review: " + relative)
        data = path.read_bytes()
        if b"\x00" in data:
            errors.append("Binary tracked file requires review: " + relative)
            continue
        content = data.decode("utf-8", "replace")
        for kind, pattern in patterns.items():
            if pattern.search(content):
                errors.append("Potential " + kind + " in " + relative)
        for email_match in personal_mail.findall(content):
            domain = email_match.rpartition("@")[2].lower()
            if domain not in {"example.com", "example.org", "example.net",
                              "example.invalid", "users.noreply.github.com"}:
                errors.append("Potential personal email address in " + relative)
                break

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
