"""Offline tests for the lightweight public fun-facts counter (no GitHub calls)."""
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.parse import parse_qs, urlsplit

from scripts import project_fun_facts as facts


class ProjectFunFactsTests(unittest.TestCase):
    def test_numstat_separates_text_from_source_and_skips_binary(self):
        example = (
            "4\t2\troles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.1_Draft.txt\n"
            "12\t3\tscripts/example.py\n"
            "10\t0\tdocs/Research_Druid.md\n"
            "6\t1\t.github/workflows/validate.yml\n"
            "-\t-\timage.png\n"
            "no stats\n"
        )
        data = facts.count_numstat(example)
        self.assertEqual((data["added"], data["deleted"]), (32, 6))
        self.assertEqual((data["source_added"], data["source_deleted"]), (22, 6))

    def test_source_paths_are_explicit(self):
        self.assertTrue(facts.is_source_path("roles/Druid/Current/APL_Druid_X.txt"))
        self.assertTrue(facts.is_source_path("tests/native/example_spec.lua"))
        self.assertTrue(facts.is_source_path(".github/workflows/validate.yml"))
        self.assertFalse(facts.is_source_path("docs/Tests_Druid.md"))
        self.assertFalse(facts.is_source_path("LICENSE"))
        self.assertFalse(facts.is_source_path("roles/Druid/readme.md"))

    @patch.object(facts, "public_json")
    def test_prs_and_issues_do_not_get_mixed(self, api):
        def response(endpoint, token=""):
            if endpoint == "repos/" + facts.REPOSITORY:
                return {
                    "full_name": facts.REPOSITORY,
                    "private": False,
                    "created_at": "2026-11-18T20:42:06Z",
                    "stargazers_count": 2, "forks_count": 1,
                }
            query = parse_qs(urlsplit(endpoint).query).get("q", [""])[0]
            if "is:pr is:merged" in query:
                return {"total_count": 3}
            if "is:issue is:closed" in query:
                return {"total_count": 0}
            raise AssertionError("Unexpected filtered search: " + query)

        api.side_effect = response
        x = facts.github_stats("test-token")
        self.assertEqual(x["merged_prs"], 3)
        self.assertEqual(x["closed_issues"], 0)
        self.assertEqual(x["public_created"], "2026-11-18")
        self.assertEqual(api.call_count, 3)

    @patch.object(facts, "public_json")
    def test_private_repository_is_rejected(self, api):
        api.return_value = {"private": True, "full_name": facts.REPOSITORY}
        with self.assertRaises(ValueError):
            facts.github_stats()

    def test_catalogue_reads_real_public_roles(self):
        counts = facts.catalogue_stats(Path(__file__).resolve().parents[1])
        self.assertEqual(counts["roles"], 28)
        self.assertGreaterEqual(counts["supported"], 0)
        self.assertGreaterEqual(counts["blocked"], 0)
        self.assertGreaterEqual(counts["apl_revisions"], counts["roles"])
        self.assertEqual(counts["supported"] + counts["blocked"], counts["roles"])

    def test_render_discloses_migration_and_non_approval(self):
        x = {
            "as_of": "2026-11-19", "started": "2026-11-07",
            "public_created": "2026-11-18", "commits": 16, "text_changed": 15144,
            "source_changed": 11196, "merged_prs": 3, "closed_issues": 0,
            "stars": 0, "forks": 0, "roles": 28, "supported": 23,
            "blocked": 5, "apl_revisions": 32, "approved_roles": 0,
        }
        output = facts.render(x)
        self.assertIn("15,144", output)
        self.assertIn("11,196", output)
        self.assertIn("not unique lines of code", output)
        self.assertIn("migration of pre-existing APLs", output)
        self.assertIn("An imported Draft is not Approved", output)
        self.assertIn("7 November 2026", output)


if __name__ == "__main__":
    unittest.main()
