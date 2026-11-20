"""Lean all-role APL independence audit. Existing hashes remain immutable."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import audit_apl_controls as controls  # noqa: E402


class APLAutonomyTests(unittest.TestCase):
    def test_current_repository_all_apl_controls_hash_integrity_and_no_new_settings(self):
        rows, failures = controls.analyse(ROOT)
        self.assertEqual([], failures)
        self.assertGreaterEqual(len(rows), 34)
        settings = [r for r in rows if r["settings"]]
        # The only existing setting-dependent files are hash-pinned
        # historical references, not evidence that they are autonomy-ready.
        self.assertTrue(all(r["historical_setting_debt"] for r in settings))
        self.assertEqual(
            {"Druid_Guardian", "Warlock_Demonology"},
            {r["role"] for r in settings},
        )
        self.assertGreater(sum(bool(r["toggles"]) for r in rows), 15)
        self.assertIn("review, not failure", controls.summary(rows))

    def test_new_candidate_setting_is_a_failing_dependency(self):
        source = "actions=demoralizing_roar,if=settings.maintain_demoralizing_roar\n"
        settings, toggles = controls.references(source)
        self.assertEqual([], toggles)
        self.assertEqual(["settings.maintain_demoralizing_roar"],
                         [x["name"] for x in settings])
        findings = controls.new_dependencies(
            "roles/Druid/Candidates/APL_Druid_Guardian_v9.9_Draft.txt",
            "f" * 64, settings)
        self.assertEqual(1, len(findings))
        self.assertIn("new required setting dependency", findings[0])

    def test_old_exception_is_exact_content_sha_and_key_not_a_blanket_exemption(self):
        path, sha = next((p, h) for p, h in controls.HISTORICAL_SETTINGS
                         if "Guardian_Tank_v1.0" in p)
        old = [{"line": 1, "name": "settings.maintain_demoralizing_roar"}]
        changed = [{"line": 2, "name": "settings.new_undocumented_setting"}]
        self.assertEqual([], controls.new_dependencies(path, sha, old))
        self.assertEqual(1, len(controls.new_dependencies(path, "0" * 64, old)))
        self.assertEqual(1, len(controls.new_dependencies(path, sha, changed)))

    def test_toggle_is_recorded_not_mistaken_for_required_checkbox_or_cast_proof(self):
        source = ("# settings.ignore_me toggle.ignore_me\n"
                  "actions=swipe_bear,if=active_enemies>=3\n"
                  "actions+=/call_action_list,name=major,if=toggle.cooldowns\n"
                  "actions.major=berserk,if=toggle.cooldowns\n")
        settings, toggles = controls.references(source)
        self.assertEqual([], settings)
        self.assertEqual(2, len(toggles))
        self.assertEqual([], controls.new_dependencies(
            "roles/Druid/Candidates/experimental.txt", "f" * 64, settings))


if __name__ == "__main__":
    unittest.main()
