"""Paladin Retribution v1.0 source/fallback checks — not native importer tests."""

from pathlib import Path
import hashlib
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
APL = ROOT / "roles" / "Paladin" / "Archive" / "APL_Paladin_Retribution_DPS_v1.0_Draft.txt"
EXPECTED_SHA256 = "dcbfa7e6c9ba4d34d40c3d464652917c47b240c4743ace3f2ba89595f693a3aa"
PALADIN_ACTIONS = {
    "blessing_of_might", "retribution_aura", "seal_of_the_crusader",
    "seal_of_command", "seal_of_righteousness", "judgement",
    "consecration", "hammer_of_wrath", "holy_shock", "holy_strike", "exorcism",
}
SHARED_ACTIONS = {"call_action_list", "use_items", "blood_fury", "berserking", "elunes_light"}
ACTION_PATTERN = re.compile(r"^actions(?:\.([a-z_]+))?\+?=/?([a-z_]+)")


class RetributionV1StaticTests(unittest.TestCase):
    def source(self):
        data = APL.read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(), EXPECTED_SHA256)
        return data.decode("utf-8")

    def test_action_keys_and_lists(self):
        lines = [line for line in self.source().splitlines() if line.strip()]
        actions = [ACTION_PATTERN.match(line) for line in lines]
        self.assertTrue(all(actions))
        self.assertFalse({m.group(2) for m in actions} - PALADIN_ACTIONS - SHARED_ACTIONS)
        lists = {m.group(1) for m in actions if m.group(1)}
        referenced = set(re.findall("call_action_list,name=([a-z_]+)", "\n".join(lines)))
        self.assertTrue(referenced <= lists)
        self.assertIn("final_fallback", referenced)
        self.assertNotIn("unsealed_wrath", self.source())

    def test_echo_switch_has_talent_and_stack_guards(self):
        lines = self.source().splitlines()
        echo = [line for line in lines if line.startswith("actions.seals") and "buff.echo_of_" in line]
        self.assertEqual(len(echo), 2)
        self.assertTrue(all("talent.twist_of_light.enabled" in line for line in echo))
        self.assertTrue(any("buff.echo_of_command.stack>=3" in line for line in echo))
        self.assertTrue(any("buff.echo_of_righteousness.stack>=1" in line for line in echo))

    def test_judgement_miss_and_unlock_escape(self):
        text = self.source()
        line = next(x for x in text.splitlines()
                    if "call_action_list,name=seals" in x)
        for guard in ("!action.judgement.known", "!cooldown.judgement.ready"):
            self.assertIn(guard, line)

    def test_holy_shock_variant_and_manual_seals(self):
        text = self.source()
        self.assertIn("talent.holy_shock.enabled", text)
        for seal in ("seal_of_wisdom", "seal_of_light", "seal_of_justice", "seal_of_fury"):
            self.assertIn(f"!buff.{seal}.up", text)

    def test_cooldown_offswitch_and_castable_tail(self):
        text = self.source()
        lines = text.splitlines()
        self.assertTrue(all("toggle.cooldowns" in x
                            for x in lines if x.startswith("actions.major_cooldowns")))
        self.assertTrue(text.rstrip().endswith(
            "actions.final_fallback+=/consecration,if=action.consecration.known"
            "&target.within5&mana.pct_lo>=45"))
        for forbidden in ("settings.", "health.", "target.casting",
                          "/major_mana_potion", "/demonic_rune", "fight_remains"):
            self.assertNotIn(forbidden, text)


if __name__ == "__main__":
    unittest.main()
