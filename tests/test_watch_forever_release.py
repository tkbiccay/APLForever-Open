"""Network-free published-release watcher tests; no external GitHub calls."""
from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import watch_forever_release as watch  # noqa: E402


class ForeverReleaseWatchTests(unittest.TestCase):
    def setUp(self):
        self.pin = watch.read_pin(ROOT / watch.LEDGER)
        self.old = self.pin["release_tag"]
        self.commit = "a" * 40

    def release(self, version, **kwargs):
        row = {"tag_name": version, "draft": False, "prerelease": False,
               "published_at": "2026-11-20T09:30:00Z"}
        row.update(kwargs)
        return row

    def test_pinned_actual_release_is_verifiable(self):
        self.assertEqual("zmsl/hekili", self.pin["upstream_repository"])
        self.assertEqual((0, 10, 0), watch.semver("v0.10.0"))
        self.assertEqual("v0.10.0", self.old)
        self.assertEqual("3c2cf3e32472cc807b1ba29d992fc13a273da8ee",
                         self.pin["release_commit"])

    def test_no_issues_when_release_is_unchanged_or_older(self):
        for version in ("v0.10.0", "v0.9.0"):
            status, title, body = watch.assess(self.release(version),
                                                self.pin, set(), self.commit)
            self.assertEqual(("pinned-current-or-newer", None, None),
                             (status, title, body))

    def test_new_published_version_generates_safe_tracked_issue(self):
        state, title, body = watch.assess(self.release("v0.10.1"),
                                          self.pin, set(), self.commit)
        self.assertEqual("new-release", state)
        self.assertEqual("Upstream Hekili Forever v0.10.1 — compatibility triage", title)
        self.assertIn(self.commit, body)
        self.assertIn("not", body.lower())
        self.assertIn("standalone", body)
        self.assertIn("No", body)
        self.assertNotIn("approved automatically", body.lower())

    def test_existing_closed_or_open_title_is_idempotent(self):
        title = "Upstream Hekili Forever v0.11.0 — compatibility triage"
        state, matched, body = watch.assess(self.release("v0.11.0"),
                                            self.pin, {title}, self.commit)
        self.assertEqual(("already-tracked", title, None),
                         (state, matched, body))

    def test_prelease_draft_bad_tag_and_bad_commit_fail_closed(self):
        for release in (self.release("v0.11.0", prerelease=True),
                        self.release("v0.11.0", draft=True),
                        self.release("../danger"), self.release("v0.11")):
            with self.assertRaises(ValueError):
                watch.assess(release, self.pin, set(), self.commit)
        with self.assertRaises(ValueError):
            watch.ticket("v0.11.0", "not-a-commit", "2026-11-20T09:30:00Z")

    def test_annotated_tag_resolves_only_to_commit(self):
        api = watch.GitHub("test-token")
        api.request = Mock(side_effect=[
            {"object": {"type": "tag", "sha": "b" * 40}},
            {"object": {"type": "commit", "sha": self.commit}},
        ])
        self.assertEqual(self.commit, api.resolved_commit("v0.11.0"))
        self.assertEqual(2, api.request.call_count)
        api.request.assert_any_call("/repos/zmsl/hekili/git/tags/" + "b" * 40)

    def test_issue_pagination_ignores_pull_requests_and_reads_second_page(self):
        api = watch.GitHub("test-token")
        page1 = [{"title": "old", "pull_request": {}}] + [
            {"title": f"old-{i}"} for i in range(99)
        ]
        api.request = Mock(side_effect=[page1, [
            {"title": "Upstream Hekili Forever v0.11.0 — compatibility triage"}
        ]])
        titles = api.issue_titles()
        self.assertNotIn("old", titles)
        self.assertIn("Upstream Hekili Forever v0.11.0 — compatibility triage", titles)

    def test_apply_rejects_any_non_main_or_other_repo_context(self):
        with patch.object(sys, "argv", ["prog", "--apply"]):
            with patch.dict("os.environ",
                            {"GITHUB_REF": "refs/heads/feature/test",
                             "GITHUB_REPOSITORY": watch.OWNER}):
                with self.assertRaises(SystemExit):
                    watch.main()
            with patch.dict("os.environ",
                            {"GITHUB_REF": "refs/heads/main",
                             "GITHUB_REPOSITORY": "someone/fork"}):
                with self.assertRaises(SystemExit):
                    watch.main()


if __name__ == "__main__":
    unittest.main()
