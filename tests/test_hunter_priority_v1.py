"""Pinned v1.0 Hunter priority static regression checks.

These checks protect exact historical candidate bytes and obvious action-chain
hazards. They do NOT run WoW, the native Hekili importer, or the belief engine.
"""

import hashlib
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
ROOT_ACTIONS = ROOT / "roles" / "Hunter" / "Current"
PINNED = {
    "Marksmanship": "43c78f4517f260e54d59cb2bac06f7464bdc78306d1df6a2977b4366c335bc9a",
    "Survival": "e58fe21c311c90d49c7cac8424f369ff08199d5c6cb35adbab2a03374ae7b12c",
}
# Verified at zmsl/hekili@246abf322ed53e3b7ab796ea7089c72329f3eb9d
HUNTER_KIT = {
    "aspect_of_the_hawk", "aspect_of_the_beast", "hunters_mark",
    "rapid_fire", "multi_shot", "sniper_shot", "serpent_sting",
    "aimed_shot", "summon_hawk", "arcane_shot", "raptor_strike",
    "mongoose_bite", "strider_kick", "immolation_trap",
}
SHARED = {"use_items", "elunes_light", "blood_fury", "berserking"}
NOT_REGISTERED = {"counterattack", "explosive_trap", "volley", "trueshot_aura"}
ACTION = re.compile(r"^actions(?:\.([a-z_]+))?(\+?=)/?([a-z_]+)")


class HunterV1DraftGuardrails(unittest.TestCase):
    def read(self, spec):
        path = ROOT_ACTIONS / f"APL_Hunter_{spec}_DPS_v1.0_Draft.txt"
        data = path.read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(), PINNED[spec])
        return data.decode("utf-8")

    def test_exact_hashes_and_action_keys(self):
        for spec in PINNED:
            with self.subTest(spec=spec):
                lines = [s for s in self.read(spec).splitlines() if s.strip()]
                groups = [ACTION.match(line) for line in lines]
                self.assertTrue(all(groups), "malformed action-list entry")
                names = {m.group(3) for m in groups}
                self.assertFalse(names & NOT_REGISTERED)
                self.assertFalse(names - HUNTER_KIT - SHARED - {"call_action_list"})
                defined = {m.group(1) for m in groups if m.group(1)}
                called = set(re.findall(r"call_action_list,name=([a-z_]+)", "\n".join(lines)))
                self.assertTrue(called <= defined)

    def test_ranged_and_melee_fallbacks_are_castability_gated(self):
        for spec in PINNED:
            with self.subTest(spec=spec):
                text = self.read(spec)
                raptors = [s for s in text.splitlines() if re.match(r"actions\.melee\+?=/raptor_strike", s) or re.match(r"actions\.melee=raptor_strike", s)]
                self.assertEqual(len(raptors), 1)
                self.assertIn("!buff.raptor_strike.up", raptors[0])
                self.assertIn("target.within5", text)
                self.assertIn("target.outside8", text)
                self.assertRegex(text, r"actions\.ranged\+=/arcane_shot,if=action\.arcane_shot\.known&action\.arcane_shot\.in_range")
                self.assertNotIn("/life_tap", text)
                self.assertNotIn("/demonic_rune", text)
                self.assertNotIn("/major_mana_potion", text)
                self.assertNotIn("settings.", text)

    def test_major_cooldown_category_respects_user_toggle(self):
        for spec in PINNED:
            with self.subTest(spec=spec):
                lines = self.read(spec).splitlines()
                major = [x for x in lines if x.startswith("actions.major_cooldowns")]
                callers = [x for x in lines if "name=major_cooldowns" in x]
                self.assertTrue(major and callers)
                self.assertTrue(all("toggle.cooldowns" in x for x in major))
                self.assertTrue(all("toggle.cooldowns" in x for x in callers))


if __name__ == "__main__":
    unittest.main()
