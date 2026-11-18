"""Warrior Protection Sunder-path *static* regression checks.

No simulation of hidden target debuffs, rage, boss detection or in-game action
eligibility is attempted. This guards the protected 1.0 baseline until we have
player /hek snap evidence for the reported repeated Sunder icons.
"""

from pathlib import Path
import hashlib
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
APL = ROOT / "roles" / "Warrior" / "Current" / "APL_Warrior_Protection_Tank_v1.0_PendingInGame.txt"
PINNED_SHA256 = "e97acd14bdebf1fdc6d8c5b482814471cad7065bef30b4f14f48b07c4f6468e0"


class WarriorProtectionSunderV1Regression(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        raw = APL.read_bytes()
        assert hashlib.sha256(raw).hexdigest() == PINNED_SHA256
        cls.lines = [s for s in raw.decode("utf-8").splitlines()
                     if s.startswith("actions")]

    def line(self, prefix):
        hits = [s for s in self.lines if s.startswith(prefix)]
        self.assertEqual(len(hits), 1, f"{prefix} has {len(hits)} matches")
        return hits[0]

    def test_two_distinct_reachable_sunder_chains(self):
        early = self.line("actions+=/call_action_list,name=early")
        self.assertIn("!action.revenge.known", early)
        pack = self.line("actions+=/call_action_list,name=pack")
        pair = self.line("actions+=/call_action_list,name=pair")
        single = self.line("actions+=/call_action_list,name=single")
        for later in (pack, pair, single):
            self.assertIn("action.revenge.known", later)
        # The late Sunder chain is reached through those separate lists.
        # Four call-sites: pack, pair, then separate mutually exclusive boss
        # and normal paths inside single. The third LIST is not one call-site.
        callers = [s for s in self.lines if "name=armor" in s]
        self.assertEqual(len(callers), 4)
        self.assertEqual(sum(s.startswith("actions.pack") for s in callers), 1)
        self.assertEqual(sum(s.startswith("actions.pair") for s in callers), 1)
        singles = [s for s in callers if s.startswith("actions.single")]
        self.assertEqual(len(singles), 2)
        self.assertTrue(any("if=target.is_boss" in s for s in singles))
        self.assertTrue(any("if=!target.is_boss" in s for s in singles))
        self.assertEqual(len([s for s in self.lines
                              if re.match(r"actions\.early\+?=/?sunder_armor,", s)]), 3)
        self.assertEqual(len([s for s in self.lines
                              if re.match(r"actions\.armor\+?=/?sunder_armor,", s)]), 3)

    def test_early_normal_solo_does_not_intentionally_build_five_stacks(self):
        line = self.line("actions.early+=/sunder_armor,if=!target.is_boss&active_enemies=1")
        self.assertIn("!debuff.sunder_armor.up", line)
        self.assertIn("rage.lo>=action.sunder_armor.cost+15", line)
        self.assertNotIn("debuff.sunder_armor.stack<5", line)

    def test_normal_packs_require_spare_rage_and_cap_at_three(self):
        for prefix in ("actions.early+=/sunder_armor,if=!target.is_boss&active_enemies>=2",
                       "actions.armor+=/sunder_armor,if=!target.is_boss&active_enemies>=2"):
            line = self.line(prefix)
            self.assertIn("debuff.sunder_armor.stack<3", line)
            self.assertIn("rage.lo>=action.sunder_armor.cost+", line)

    def test_boss_paths_can_intentionally_build_five_stacks(self):
        for prefix in ("actions.early+=/sunder_armor,if=target.is_boss",
                       "actions.armor=sunder_armor,if=target.is_boss"):
            line = self.line(prefix)
            self.assertIn("debuff.sunder_armor.stack<5", line)
            self.assertIn("!debuff.sunder_armor.up", line)
        # Source-level *risk*, not a known cause of the user's symptom:
        self.assertNotIn("rage.lo>=", self.line(
            "actions.early+=/sunder_armor,if=target.is_boss"))
        # Native engine castability may still suppress it.

    def test_sunder_never_overrides_existing_next_swing_queue(self):
        sunder = [s for s in self.lines if re.match(
            r"actions\.(?:early|armor)\+?=/?sunder_armor,", s)]
        self.assertEqual(len(sunder), 6)
        for line in sunder:
            self.assertIn("!buff.heroic_strike.up", line)
            self.assertIn("!buff.cleave.up", line)

    def test_final_early_chain_can_end_at_white_swings(self):
        tail = [s for s in self.lines if s.startswith("actions.early")]
        self.assertTrue(tail[-1].startswith("actions.early+=/heroic_strike,"))
        self.assertIn("rage.lo>=40", tail[-1])
        # The absence of a GCD filler does not prove a recommendation bug;
        # no new action can be claimed without engine/player evidence.
        self.assertFalse(any("life_tap" in x for x in self.lines))


if __name__ == "__main__":
    unittest.main()
