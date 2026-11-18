"""Mage v1.0 static source and fallback guards, NOT in-game tests."""

import hashlib
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
PINNED = {
    "Arcane": "d89600259308d74e56dc96decd2af9a27c60d561d90fe2cca1a2ed15b359a036",
    "Fire": "500a40752f3f3c1ec125262ce243996c1fb69b3da8a91af5c59ca6c3d165982a",
    "Frost": "f05a17a34b9d13238d6594e27f4fa7994cf2ce9eae5c4e5916ecc7dc0decbd22",
}
# Registered in zmsl/hekili@246abf322ed53e3b7ab796ea7089c72329f3eb9d
MAGE_ACTIONS = {
    "arcane_blast", "arcane_wrath", "arcane_missiles", "arcane_power",
    "presence_of_mind", "evocation", "fire_blast", "pyroblast",
    "frostfire_bolt", "frostbolt", "ice_lance", "cone_of_cold",
    "ice_barrier", "blizzard", "fireball", "combustion", "scorch", "cold_snap",
}
SHARED = {"call_action_list", "use_items", "eureka", "blood_fury",
          "berserking", "read_ley_line"}
UNSUPPORTED = {"arcane_explosion", "flamestrike", "blast_wave", "mage_armor",
               "frost_armor", "mana_gem"}
ACTION_RE = re.compile(r"^actions(?:\.([a-z_]+))?\+?=/?([a-z_]+)")


class MageV1SourceGuards(unittest.TestCase):
    def source(self, spec):
        f = ROOT / "roles" / "Mage" / "Current" / f"APL_Mage_{spec}_v1.0_Draft.txt"
        b = f.read_bytes()
        self.assertEqual(hashlib.sha256(b).hexdigest(), PINNED[spec])
        return b.decode("utf-8")

    def test_exact_hashes_action_registration_and_lists(self):
        for spec in PINNED:
            with self.subTest(spec=spec):
                entries = [s for s in self.source(spec).splitlines() if s.strip()]
                matches = [ACTION_RE.match(s) for s in entries]
                self.assertTrue(all(matches))
                keys = {m.group(2) for m in matches}
                self.assertFalse(keys - MAGE_ACTIONS - SHARED)
                self.assertFalse(keys & UNSUPPORTED)
                defined = {m.group(1) for m in matches if m.group(1)}
                used = set(re.findall(r"call_action_list,name=([a-z_]+)", "\n".join(entries)))
                self.assertTrue(used <= defined)
                self.assertIn("final_fallback", used)

    def test_offswitches_and_absence_of_unverified_controls(self):
        for spec in PINNED:
            with self.subTest(spec=spec):
                txt = self.source(spec)
                ls = txt.splitlines()
                self.assertTrue(all("toggle.cooldowns" in s for s in ls
                                    if s.startswith("actions.major_cooldowns")))
                if spec == "Frost":
                    self.assertTrue(all("toggle.defensives" in s for s in ls
                                        if s.startswith("actions.defensives")))
                    self.assertIn("toggle.defensives", ls[0])
                for forbidden in ("health.", "target.casting", "settings.",
                                  "/major_mana_potion", "/demonic_rune",
                                  "/life_tap"):
                    self.assertNotIn(forbidden, txt)

    def test_final_damage_fallback_and_no_channel_spam(self):
        for spec in PINNED:
            with self.subTest(spec=spec):
                txt = self.source(spec)
                self.assertIn("actions.final_fallback=", txt)
                self.assertTrue(all("action." in s and ".known" in s for s
                                    in txt.splitlines()
                                    if s.startswith("actions.final_fallback")))
                self.assertTrue(all("!action.blizzard.channeling" in s for s
                                    in txt.splitlines() if "=blizzard," in s))
        self.assertIn("!buff.ice_barrier.up", self.source("Frost"))
        self.assertNotIn("buff.frigid_power.remains<=3", self.source("Frost"))

    def test_arcane_blast_upkeep_must_precede_always_usable_wrath(self):
        entries = [s for s in self.source("Arcane").splitlines()
                   if s.startswith("actions+=")]
        blast = next(i for i, s in enumerate(entries) if "actions+=/arcane_blast" in s)
        wrath = next(i for i, s in enumerate(entries) if "actions+=/arcane_wrath" in s)
        self.assertLess(blast, wrath)

    def test_fire_talent_and_frost_fingers_gating(self):
        self.assertIn("talent.improved_scorch.rank>0", self.source("Fire"))
        self.assertIn("buff.heating_up.stack>=3", self.source("Fire"))
        self.assertIn("buff.fingers_of_frost.stack>=1", self.source("Frost"))
        self.assertIn("debuff.winters_chill.stack>=5", self.source("Frost"))


if __name__ == "__main__":
    unittest.main()
