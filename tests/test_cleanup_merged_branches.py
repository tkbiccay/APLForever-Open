"""Network-free invariants for merged-branch cleanup."""
import sys
import unittest
from pathlib import Path
from unittest.mock import Mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import cleanup_merged_branches as cleanup  # noqa: E402

REPO = "tkbiccay/APLForever-Open"


def branch(name, sha="a"*40, protected=False):
    return {"name": name, "commit": {"sha": sha}, "protected": protected}


def pr(n, name, sha="a"*40, state="closed", merged=True, repo=REPO):
    return {"number": n, "state": state,
            "merged_at": "2026-11-19T09:00:00Z" if merged else None,
            "head": {"ref": name, "sha": sha, "repo": {"full_name": repo}}}


class SafeBranchCleanupTests(unittest.TestCase):
    def test_only_exact_unprotected_merged_heads_qualify(self):
        branches = [
            branch("main", protected=True), branch("docs/merged"),
            branch("docs/moved", "b"*40), branch("fix/unmerged"),
            branch("fix/open"), branch("fix/fork"),
            branch("fix/protected", protected=True),
            branch("fix/no-pr"), branch("fix/unsafe..name"),
        ]
        pulls = [
            pr(1, "docs/merged"), pr(2, "docs/moved"),
            pr(3, "fix/unmerged", merged=False),
            pr(4, "fix/open", state="open", merged=False),
            pr(5, "fix/fork", repo="other/fork"), pr(6, "fix/protected"),
            pr(7, "fix/unsafe..name"),
        ]
        rows = cleanup.select_candidates(branches, pulls, REPO, "main")
        self.assertEqual(["docs/merged"], [x["branch"] for x in rows])
        self.assertEqual([1], rows[0]["merged_prs"])

    def test_prior_merged_branch_reused_for_open_pr_is_safe(self):
        result = cleanup.select_candidates(
            [branch("feature/now-active")],
            [pr(1, "feature/now-active"),
             pr(2, "feature/now-active", state="open", merged=False)],
            REPO, "main")
        self.assertEqual([], result)

    def test_wrong_sha_and_fork_cannot_delete(self):
        self.assertEqual([], cleanup.select_candidates(
            [branch("test")], [pr(8, "test", "b"*40)], REPO, "main"))
        self.assertEqual([], cleanup.select_candidates(
            [branch("fork")], [pr(8, "fork", repo="other/fork")], REPO, "main"))

    def test_fresh_branch_ref_must_still_match(self):
        item = {"branch": "feature/good", "sha": "a"*40}
        git = Mock()
        git.request.side_effect = [
            branch("feature/good"),
            {"ref": "refs/heads/feature/good", "object": {"sha": "a"*40}},
        ]
        self.assertTrue(cleanup.check_live_branch(git, item, "main", set())[0])
        git.request.side_effect = [branch("feature/good", "b"*40)]
        self.assertFalse(cleanup.check_live_branch(git, item, "main", set())[0])
        git.request.side_effect = [branch("feature/good", protected=True)]
        self.assertFalse(cleanup.check_live_branch(git, item, "main", set())[0])
        git.request.side_effect = [branch("feature/good"), {
            "ref": "refs/heads/feature/good", "object": {"sha": "c"*40}}]
        self.assertFalse(cleanup.check_live_branch(git, item, "main", set())[0])
        self.assertFalse(cleanup.check_live_branch(git, item, "main", {"feature/good"})[0])


if __name__ == "__main__":
    unittest.main()
