"""Shaman DPS v1.0 static regression checks; not an engine or gameplay harness."""

import hashlib
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CHECKSUMS = {
    "Elemental": ("fd19fe1d83d996be6b3d65a47ef374957e21deb154722a61e31f4cadacebe915", 34),
    "Enhancement": ("76c3ed75a4b01ebe18980104261bcd5589b48924fcaef87a3ed356f00de6ab35", 39),
}
# Action registrations verified in zmsl/hekili@246abf322ed53e3b7ab796ea7089c72329f3eb9d
SHAMAN_ACTIONS = {
    "water_shield", "lightning_shield", "strength_of_earth_totem",
    "windfury_totem", "mana_spring_totem", "searing_totem",
    "magma_totem", "mana_tide_totem", "windfury_weapon",
    "flametongue_weapon", "rockbiter_weapon", "lightning_bolt",
    "chain_lightning", "flame_shock", "earth_shock", "fire_nova",
    "stormstrike", "elemental_mastery", "rage_of_the_farseer",
}
SHARED = {"call_action_list", "use_items", "eureka", "elunes_light",
          "blood_fury", "berserking"}
LINE = re.compile(r"^actions(?:\.([a-z_]+))?\+?=/?([a-z_]+)")


class ShamanV1StaticGuards(unittest.TestCase):
    def read(self, spec):
        raw = (ROOT / "roles" / "Shaman" / "Current" / f"APL_Shaman_{spec}_v1.0_Draft.txt").read_bytes()
        expected, _ = CHECKSUMS[spec]
        self.assertEqual(hashlib.sha256(raw).hexdigest(), expected)
        return raw.decode("utf-8")

    def test_action_keys_and_full_list_chain(self):
        for spec, (_, count) in CHECKSUMS.items():
            with self.subTest(spec=spec):
                lines = [s for s in self.read(spec).splitlines() if s.strip()]
                self.assertEqual(len(lines), count)
                actions = [LINE.match(s) for s in lines]
                self.assertTrue(all(actions))
                names = {a.group(2) for a in actions}
                self.assertFalse(names - SHAMAN_ACTIONS - SHARED)
                self.assertFalse(names & {"lava_burst", "lightning_mastery"})
                defined = {a.group(1) for a in actions if a.group(1)}
                references = set(re.findall(r"call_action_list,name=([a-z_]+)", "\n".join(lines)))
                self.assertTrue(references <= defined)
                self.assertIn("final_fallback", references)

    def test_resource_recovery_and_player_offswitch(self):
        for spec in CHECKSUMS:
            with self.subTest(spec=spec):
                text = self.read(spec)
                lines = text.splitlines()
                self.assertTrue(all("toggle.cooldowns" in x for x in lines
                                    if x.startswith("actions.major_cooldowns")))
                self.assertTrue(all("toggle.cooldowns" in x for x in lines
                                    if x.startswith("actions.mana_recovery")))
                self.assertIn("action.mana_tide_totem.known&mana.pct_lo<35", text)
                for forbidden in ("health.", "target.casting", "settings.",
                                  "major_mana_potion", "demonic_rune", "cycle_targets="):
                    self.assertNotIn(forbidden, text)

    def test_totem_preference_and_fire_nova_safety(self):
        for spec in CHECKSUMS:
            with self.subTest(spec=spec):
                lines = self.read(spec).splitlines()
                self.assertTrue(all("!totem." in x and ".up" in x for x in lines
                                    if x.startswith("actions.support_totems")))
                self.assertTrue(all("!totem.fire.up" in x for x in lines
                                    if x.startswith("actions.fire_totems")))
                self.assertTrue(all("totem.fire.up" in x for x in lines
                                    if "=/fire_nova," in x or "=fire_nova," in x))
                self.assertTrue(self.read(spec).rstrip().splitlines()[-1]
                                .startswith("actions.final_fallback+="))

    def test_enhancement_imbue_and_maelstrom_gates(self):
        text = self.read("Enhancement")
        for name in ("windfury_weapon", "flametongue_weapon", "rockbiter_weapon"):
            lines = [s for s in text.splitlines() if s.startswith("actions.weapon_upkeep")
                     and ("="+name+"," in s or "=/"+name+"," in s)]
            self.assertEqual(len(lines), 1)
            self.assertIn("!buff.main_hand_enchant.up", lines[0])
        self.assertIn("buff.maelstrom_weapon.stack>=5", text)
        self.assertIn("talent.maelstrom_weapon.rank>0", text)
        self.assertNotIn("chain_lightning", text)
        self.assertIn("action.stormstrike.known", text)

    def test_elemental_damage_tail_and_true_cooldown_key(self):
        text = self.read("Elemental")
        self.assertIn("actions.major_cooldowns=elemental_mastery", text)
        self.assertTrue(text.rstrip().endswith(
            "actions.final_fallback=lightning_bolt,if=action.lightning_bolt.known\n"
            "actions.final_fallback+=/earth_shock,if=action.earth_shock.known"
            "&mana.pct_lo>=55"
        ))


if __name__ == "__main__":
    unittest.main()
