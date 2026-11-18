"""No-network regression checks for release-pinned wiki diff detection."""

import tempfile
import unittest
from pathlib import Path
from subprocess import run

from scripts.wiki_release_diff import compare, markdown


class WikiDiffTest(unittest.TestCase):
    def test_versioned_added_modified_removed_and_unrelated(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp)

            def git(*args):
                run(["git", "-C", str(p), *args], capture_output=True, check=True)

            git("init", "-q")
            git("config", "user.email", "local@example.invalid")
            git("config", "user.name", "Test")
            (p / "docs/wiki").mkdir(parents=True)
            (p / "docs/wiki/APL-Syntax-Reference.md").write_text("alpha\n")
            (p / "docs/wiki/Old.md").write_text("old\n")
            (p / "docs/wiki/internal.png").write_bytes(b"x")
            git("add", ".")
            git("commit", "-qm", "first")
            git("tag", "v0.8.2")
            (p / "docs/wiki/APL-Syntax-Reference.md").write_text("beta\n")
            (p / "docs/wiki/Old.md").unlink()
            (p / "docs/wiki/Pack-Testing-And-Gates.md").write_text("added\n")
            git("add", "-A")
            git("commit", "-qm", "second")
            git("tag", "v0.8.3")
            r = compare(p, "v0.8.2", "v0.8.3")
            self.assertEqual((2, 2, 3), (r["old_pages"], r["new_pages"], r["changed_pages"]))
            self.assertEqual(
                [
                    ("APL-Syntax-Reference.md", "modified", "apl-engine"),
                    ("Old.md", "removed", "operations-or-ui"),
                    ("Pack-Testing-And-Gates.md", "added", "class-mechanics-tests"),
                ],
                [
                    (Path(x["path"]).name, x["change"], x["impact"])
                    for x in r["changes"]
                ],
            )
            self.assertIn("changed: 3", markdown(r))
            self.assertEqual(0, compare(p, "v0.8.3", "v0.8.3")["changed_pages"])

    def test_invalid_refs_fail_instead_of_claiming_no_changes(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):
                compare(Path(tmp), "missing-a", "missing-b")


if __name__ == "__main__":
    unittest.main()
