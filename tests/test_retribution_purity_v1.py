"""Ret v1.1 spec/role purity guardrails. Static only; not Hekili runtime proof."""

import hashlib
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
RET_V11 = ROOT / "roles/Paladin/Archive/APL_Paladin_Retribution_v1.1_Draft.txt"
LEGACY_V10 = ROOT / "roles/Paladin/Archive/APL_Paladin_Retribution_DPS_v1.0_Draft.txt"
RET_SHA256 = "8ad51a292f53ece1e0248444fd4a4c5dc6fdf180532c637ee23155a4bd4fbb9a"
LEGACY_SHA256 = "dcbfa7e6c9ba4d34d40c3d464652917c47b240c4743ace3f2ba89595f693a3aa"


class RetOnlySourceGuardrails(unittest.TestCase):
    def source(self):
        data = RET_V11.read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(), RET_SHA256)
        return data.decode("utf-8")

    def test_legacy_draft_is_immutable(self):
        self.assertEqual(hashlib.sha256(LEGACY_V10.read_bytes()).hexdigest(), LEGACY_SHA256)

    def test_new_apl_is_retribution_dps_only(self):
        apl = self.source()
        for forbidden in (
            "talent.holy_shock", "/holy_shock", "/holy_shield",
            "/flash_of_light", "/righteous_fury", "talent.shieldsworn",
            "talent.iron_creed", "actions.healing=", "actions.tank=",
        ):
            self.assertNotIn(forbidden, apl)
        for required in (
            "talent.twist_of_light", "buff.echo_of_command",
            "buff.echo_of_righteousness", "actions.final_fallback=hammer_of_wrath",
            "/holy_strike", "/seal_of_command", "/seal_of_righteousness",
        ):
            self.assertIn(required, apl)

    def test_lists_and_cooldown_guards(self):
        apl = self.source()
        actions = [line for line in apl.splitlines() if line.strip()]
        self.assertTrue(all(re.match(r"^actions(?:\.[a-z_]+)?\+?=/?[a-z_]+", line) for line in actions))
        defined = set(re.findall(r"(?m)^actions\.([a-z_]+)(?:\+?=)", apl))
        called = set(re.findall(r"call_action_list,name=([a-z_]+)", apl))
        self.assertTrue(called <= defined)
        self.assertTrue(all("toggle.cooldowns" in line
                            for line in actions if line.startswith("actions.major_cooldowns")))
        self.assertNotIn("settings.", apl)


if __name__ == "__main__":
    unittest.main()
