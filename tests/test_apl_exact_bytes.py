"""Protect catalogue SHA-256 values from Git line-ending conversion."""

from __future__ import annotations

import hashlib
import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class AplExactBytesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalogue = json.loads(
            (ROOT / "catalogue" / "roles.json").read_text(encoding="utf-8-sig")
        )
        cls.apls = [
            revision
            for role in cls.catalogue["roles"]
            for revision in role["revisions"]
        ]

    def test_every_catalogued_apl_matches_its_exact_byte_hash(self) -> None:
        for revision in self.apls:
            with self.subTest(path=revision["apl_file"]):
                content = (ROOT / revision["apl_file"]).read_bytes()
                self.assertEqual(hashlib.sha256(content).hexdigest(), revision["sha256"])

    def test_git_text_conversion_is_disabled_for_every_apl(self) -> None:
        paths = [revision["apl_file"] for revision in self.apls]
        result = subprocess.run(
            ["git", "check-attr", "text", "--stdin"],
            input="\n".join(paths) + "\n",
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        attributes = result.stdout.splitlines()
        self.assertEqual(len(attributes), len(paths))
        self.assertTrue(all(line.endswith(": text: unset") for line in attributes))


if __name__ == "__main__":
    unittest.main()
