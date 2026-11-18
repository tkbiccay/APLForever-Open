"""Druid Balance v1.0 static source guardrails — NOT a live WoW/engine test."""

from pathlib import Path
import hashlib
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
APL = ROOT / "roles" / "Druid" / "Current" / "APL_Druid_Balance_DPS_v1.0_Draft.txt"
SHA256 = "1cf83328f343e20a8efc93ed06645e862979e8d2f8bfce79acdcfcbedc55c1c2"
DRUID_KIT = {
    "mark_of_the_wild", "thorns", "moonkin_form", "wrath", "starfire",
    "moonfire", "insect_swarm", "hurricane", "innervate",
}
SHARED = {"call_action_list", "use_items", "elunes_light", "blood_fury", "berserking"}
LINE = re.compile(r"^actions(?:\.([a-z_]+))?\+?=/?([a-z_]+)")


class BalanceV1SourceGuardrails(unittest.TestCase):
    def source(self):
        data = APL.read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(), SHA256)
        return data.decode("utf-8")

    def test_actions_resolve_to_verified_kit_or_shared_names(self):
        lines = [x for x in self.source().splitlines() if x.strip()]
        records = [LINE.match(x) for x in lines]
        self.assertTrue(all(records))
        action_keys = {m.group(2) for m in records}
        self.assertFalse(action_keys - DRUID_KIT - SHARED)
        lists = {m.group(1) for m in records if m.group(1)}
        calls = set(re.findall(r"call_action_list,name=([a-z_]+)", "\n".join(lines)))
        self.assertTrue(calls <= lists)
        self.assertIn("final_fallback", calls)

    def test_eclipse_and_fallback_are_explicit(self):
        text = self.source()
        self.assertIn("buff.eclipse.stack>0", text)
        self.assertIn("talent.eclipse.enabled", text)
        self.assertIn("buff.clearcasting.up", text)
        self.assertIn("!action.starfire.executing", text)
        self.assertIn("!action.hurricane.channeling", text)
        self.assertTrue(text.rstrip().endswith(
            "actions.final_fallback=wrath,if=action.wrath.known\n"
            "actions.final_fallback+=/starfire,if=action.starfire.known"
        ))

    def test_offswitches_and_no_untrusted_health_or_consumables(self):
        text = self.source()
        lines = text.splitlines()
        self.assertTrue(all("toggle.cooldowns" in x
                            for x in lines if x.startswith("actions.major_cooldowns")))
        self.assertTrue(all("toggle.cooldowns" in x
                            for x in lines if x.startswith("actions.mana_recovery")))
        for forbidden in ("health.", "target.casting", "fight_remains", "settings.",
                          "/major_mana_potion", "/demonic_rune", "/life_tap"):
            self.assertNotIn(forbidden, text)

    def test_precombat_respects_manual_animal_forms(self):
        text = self.source()
        form = next(x for x in text.splitlines()
                    if x.startswith("actions.precombat+=/moonkin_form"))
        for guard in ("!buff.bear_form.up", "!buff.cat_form.up", "!buff.travel_form.up"):
            self.assertIn(guard, form)


if __name__ == "__main__":
    unittest.main()
