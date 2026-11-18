"""Rogue v1.0 static guardrails; no claim of native import or in-game proof."""

import hashlib
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CHECKSUMS = {
    "Assassination": ("f817fe4ab906e82c3244a886457216822824c2598cd53cbf619610b4709ee4e0", 22),
    "Combat": ("ff69f6d4baa3e74d054f8e96595993b5bd931e283e0b7a81cf1dd95a03b13218", 19),
    "Subtlety": ("3d5fa90ecfd4a9d1f57fa8c73f6cb6f72a7bf8dff48577285125af16433ff77e", 24),
}
# Verified against zmsl/hekili@246abf322ed53e3b7ab796ea7089c72329f3eb9d
ROGUE_ACTIONS = {
    "instant_poison", "deadly_poison", "stealth", "garrote", "riposte",
    "shank", "slice_and_dice", "rupture", "eviscerate", "mutilate",
    "sinister_strike", "cold_blood", "blade_flurry", "adrenaline_rush",
    "ghostly_strike", "hemorrhage", "death_mark", "premeditation",
}
SHARED = {
    "call_action_list", "use_items", "eureka", "elunes_light",
    "blood_fury", "berserking",
}
LINE = re.compile(r"^actions(?:\.([a-z_]+))?\+?=/?([a-z_]+)")


class RogueV1StaticGuards(unittest.TestCase):
    def read(self, spec):
        data = (ROOT / "roles" / "Rogue" / "Current" / f"APL_Rogue_{spec}_v1.0_Draft.txt").read_bytes()
        expected, _ = CHECKSUMS[spec]
        self.assertEqual(hashlib.sha256(data).hexdigest(), expected)
        return data.decode("utf-8")

    def test_registered_action_keys_and_complete_sublist_chain(self):
        for spec, (_, count) in CHECKSUMS.items():
            with self.subTest(spec=spec):
                lines = [s for s in self.read(spec).splitlines() if s.strip()]
                self.assertEqual(len(lines), count)
                parsed = [LINE.match(s) for s in lines]
                self.assertTrue(all(parsed), "Unrecognised action-list text")
                self.assertFalse({m.group(2) for m in parsed} - ROGUE_ACTIONS - SHARED)
                defined = {m.group(1) for m in parsed if m.group(1)}
                calls = set(re.findall(r"call_action_list,name=([a-z_]+)", "\n".join(lines)))
                self.assertTrue(calls <= defined)
                self.assertIn("final_fallback", calls)
                self.assertTrue(lines[-1].startswith("actions.final_fallback"))
                self.assertIn("actions+=/call_action_list,name=final_fallback", lines)

    def test_poison_and_stealth_only_in_precombat(self):
        for spec in CHECKSUMS:
            with self.subTest(spec=spec):
                lines = self.read(spec).splitlines()
                for poison, enchant in (("instant_poison", "main_hand_enchant"),
                                        ("deadly_poison", "off_hand_enchant")):
                    lines_for_poison = [s for s in lines if
                                        re.search(r"=/?"+poison+r",", s)]
                    self.assertEqual(len(lines_for_poison), 1)
                    self.assertTrue(lines_for_poison[0].startswith("actions.precombat"))
                    self.assertIn(f"!buff.{enchant}.up", lines_for_poison[0])
                self.assertTrue(any(s.startswith("actions.precombat") and
                                    "=stealth," in s or "=/stealth," in s
                                    for s in lines))
                self.assertFalse(any(s.startswith("actions=") and
                                     "=stealth," in s for s in lines))

    def test_major_cooldowns_and_no_forced_vanish_or_consumables(self):
        for spec in CHECKSUMS:
            with self.subTest(spec=spec):
                text = self.read(spec)
                lines = text.splitlines()
                major = [s for s in lines if s.startswith("actions.major_cooldowns")]
                self.assertTrue(major)
                self.assertTrue(all("toggle.cooldowns" in s for s in major))
                self.assertTrue(any("toggle.cooldowns" in s and
                                    "name=major_cooldowns" in s for s in lines))
                action_names = [LINE.match(s).group(2) for s in lines
                                if s.startswith("actions")]
                for excluded in ("vanish", "preparation", "thistle_tea",
                                 "major_mana_potion", "demonic_rune", "evasion"):
                    self.assertNotIn(excluded, action_names)
                for uncertain in ("settings.", "health.", "fight_remains",
                                  "cycle_targets=", "target.casting"):
                    self.assertNotIn(uncertain, text)

    def test_shank_energy_and_boot_knife_combo_guard(self):
        for spec in CHECKSUMS:
            with self.subTest(spec=spec):
                shank = next(s for s in self.read(spec).splitlines()
                             if s.startswith("actions+=/shank,"))
                self.assertIn("energy.lo<=75", shank)
                self.assertIn("combo_points.current<=3", shank)
                self.assertIn("talent.boot_knife.rank<5", shank)
                self.assertIn("combo_points.current<=4", shank)

    def test_openers_and_finisher_castability(self):
        for spec in CHECKSUMS:
            with self.subTest(spec=spec):
                text = self.read(spec)
                self.assertIn("actions.opener=garrote", text)
                self.assertIn("buff.ghostly_strike_next.up", text)
                self.assertIn("combo_points.current>=5", text)
                self.assertIn("action.eviscerate.known", text)
                self.assertIn("!buff.slice_and_dice.up", text)
                self.assertTrue(any("action.sinister_strike.known" in s and
                                    "combo_points.current<5" in s
                                    for s in text.splitlines() if s.startswith("actions.final_fallback")))

    def test_individual_spec_branches(self):
        assassination = self.read("Assassination")
        self.assertIn("actions.final_fallback=mutilate", assassination)
        self.assertIn("talent.blood_splatter.rank>0", assassination)
        combat = self.read("Combat")
        self.assertIn("actions.major_cooldowns=blade_flurry", combat)
        self.assertIn("window.riposte.up", combat)
        subtlety = self.read("Subtlety")
        self.assertIn("actions.precombat+=/premeditation", subtlety)
        self.assertIn("toggle.minor_cooldowns", subtlety)
        self.assertIn("actions+=/death_mark", subtlety)
        self.assertIn("buff.ghostly_strike_next.up", subtlety)
        self.assertIn("actions.final_fallback=ghostly_strike", subtlety)


if __name__ == "__main__":
    unittest.main()
