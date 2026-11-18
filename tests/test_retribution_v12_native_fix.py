"""Protect Ret v1.2 against the confirmed unsupported Blessing of Might import.

Source-only tests: native source compatibility is proved separately in the pinned
Hekili Forever Busted workflow; these assertions do not simulate casts.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
OLD10 = ROOT / "roles/Paladin/Archive/APL_Paladin_Retribution_DPS_v1.0_Draft.txt"
OLD11 = ROOT / "roles/Paladin/Archive/APL_Paladin_Retribution_v1.1_Draft.txt"
NEW12 = ROOT / "roles/Paladin/Current/APL_Paladin_Retribution_v1.2_Draft.txt"
HASHES = (
    "dcbfa7e6c9ba4d34d40c3d464652917c47b240c4743ace3f2ba89595f693a3aa",
    "8ad51a292f53ece1e0248444fd4a4c5dc6fdf180532c637ee23155a4bd4fbb9a",
    "d5a05302c341bbbcb7a69157a40d0a4ae2df8504ce40838e03407515e4e4731b",
)


class RetributionV12NativeFix(unittest.TestCase):
    def test_all_three_versions_preserved_exactly(self):
        for path, expected in zip((OLD10, OLD11, NEW12), HASHES):
            with self.subTest(path=str(path)):
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), expected)

    def test_only_unsupported_first_action_removed(self):
        before = OLD11.read_text(encoding="utf-8")
        after = NEW12.read_text(encoding="utf-8")
        old_first, remainder = before.split("\n", 1)
        self.assertTrue(old_first.startswith("actions.precombat=blessing_of_might,"))
        expected = remainder.replace(
            "actions.precombat+=/retribution_aura",
            "actions.precombat=retribution_aura",
            1,
        )
        self.assertEqual(after, expected)
        self.assertNotIn("actions.precombat=blessing_of_might", after)
        self.assertTrue(after.startswith("actions.precombat=retribution_aura"))
        self.assertEqual(
            len([x for x in after.splitlines() if x.startswith("actions")]),
            28,
        )

    def test_keeps_same_priority_chains_and_user_toggle(self):
        a = NEW12.read_text(encoding="utf-8")
        defined = set(re.findall(r"(?m)^actions\.([a-z_]+)(?:\+?=)", a))
        called = set(re.findall(r"call_action_list,name=([a-z_]+)", a))
        self.assertTrue(called <= defined)
        self.assertIn("actions.final_fallback=hammer_of_wrath", a)
        self.assertIn("actions.major_cooldowns=use_items", a)
        self.assertTrue(all(
            "toggle.cooldowns" in x
            for x in a.splitlines() if x.startswith("actions.major_cooldowns")
        ))
        self.assertNotIn("settings.", a)
        self.assertNotIn("/blessing_of_might", a)

    def test_candidate_is_not_promoted(self):
        catalogue = json.loads((ROOT / "catalogue/roles.json").read_text(encoding="utf-8"))
        role = next(x for x in catalogue["roles"] if x["apl_name"] == "Paladin_Retribution")
        self.assertEqual(role["validation_status"], "Draft")
        self.assertIsNone(role["preferred_apl"])
        self.assertIsNone(role["last_working_apl"])
        self.assertEqual(role["latest_revision"], "v1.2")
        self.assertEqual(len(role["revisions"]), 3)
        last = role["revisions"][-1]
        self.assertEqual(last["status"], "Draft")
        self.assertEqual(last["sha256"], HASHES[2])
        self.assertEqual(last["rollback_reference"], "roles/Paladin/Archive/APL_Paladin_Retribution_v1.1_Draft.txt")


if __name__ == "__main__":
    unittest.main()
