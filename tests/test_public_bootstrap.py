"""Tests for clean-history public project boundaries."""
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from scripts.check_public_repository import check


class PublicBootstrapTests(unittest.TestCase):
    def test_public_repo_policy_and_apl_hashes_when_available(self):
        self.assertEqual(check(), [])

    def test_private_git_history_is_not_a_runtime_dependency(self):
        text = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("read-only historical reference", text)
        self.assertIn("only active development", text)

    def test_no_direct_mirror_to_private(self):
        text = (ROOT / "PUBLIC_MIGRATION.md").read_text(encoding="utf-8")
        self.assertIn("do not develop there", text)
        self.assertIn("WITHOUT copying its", text)


if __name__ == "__main__":
    unittest.main()
