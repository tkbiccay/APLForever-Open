"""Shadow Priest v1.0 source-level regression guardrails (not in-game tests)."""

import hashlib
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
APL = ROOT / "roles" / "Priest" / "Current" / "APL_Priest_Shadow_v1.0_Draft.txt"
SHA256 = "66ee308453ae07c1e2c77b5f82e414e61abbd5f2099d21a252448174be7eec79"
PRIEST_ACTIONS = {
    "power_word_fortitude", "divine_spirit", "inner_fire", "shadowguard",
    "shadowform", "mind_blast", "shadow_word_pain", "devouring_plague",
    "vampiric_embrace", "mind_flay", "inner_focus", "smite", "shoot",
}
SHARED_ACTIONS = {"call_action_list", "use_items", "eureka", "elunes_light",
                  "berserking", "blood_fury"}
LINE = re.compile(r"^actions(?:\.([a-z_]+))?\+?=/?([a-z_]+)")


class ShadowV1StaticGuards(unittest.TestCase):
    def source(self):
        raw = APL.read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(), SHA256)
        return raw.decode("utf-8")

    def test_source_keys_and_list_reachability(self):
        lines = [s for s in self.source().splitlines() if s.strip()]
        matches = [LINE.match(s) for s in lines]
        self.assertEqual(len(lines), 24)
        self.assertTrue(all(matches), "Malformed APL action record")
        keys = {match.group(2) for match in matches}
        self.assertFalse(keys - PRIEST_ACTIONS - SHARED_ACTIONS)
        defined = {match.group(1) for match in matches if match.group(1)}
        called = set(re.findall(r"call_action_list,name=([a-z_]+)", "\n".join(lines)))
        self.assertTrue(called <= defined)
        self.assertIn("final_fallback", called)

    def test_safe_channel_non_clipping(self):
        lines = self.source().splitlines()
        for action in ("actions=shadowform", "actions+=/call_action_list,name=upkeep",
                       "actions+=/call_action_list,name=major_cooldowns",
                       "actions+=/mind_blast", "actions+=/call_action_list,name=minor_cooldowns",
                       "actions.final_fallback+=/shoot"):
            matched = [s for s in lines if s.startswith(action)]
            self.assertEqual(len(matched), 1)
            self.assertIn("!action.mind_flay.channeling", matched[0])
        self.assertIn("actions+=/mind_flay,if=action.mind_flay.known&!action.mind_flay.channeling",
                      lines)

    def test_resource_and_health_safety(self):
        text = self.source()
        for blocked in ("shadow_word_death", "dark_sacrifice", "demonic_rune",
                        "major_mana_potion", "health.", "settings."):
            self.assertNotIn(blocked, text)
        self.assertIn("actions.final_fallback=smite,if=action.smite.known"
                      "&!action.mind_flay.known&!buff.shadowform.up", text)
        self.assertIn("mana.pct_lo<12&!action.shoot.channeling", text)

    def test_cooldown_and_buff_intent(self):
        lines = self.source().splitlines()
        major = [x for x in lines if x.startswith("actions.major_cooldowns")]
        minor = [x for x in lines if x.startswith("actions.minor_cooldowns")]
        self.assertTrue(major and minor)
        self.assertTrue(all("toggle.cooldowns" in x for x in major))
        self.assertTrue(all("toggle.cooldowns" in x and
                            "toggle.minor_cooldowns" in x for x in minor))
        for action in ("power_word_fortitude", "divine_spirit", "inner_fire"):
            line = next(x for x in lines if
                        re.match(r"^actions\.precombat\+?="+"/?"+action+r",", x))
            self.assertIn("!buff.shadowform.up", line)


if __name__ == "__main__":
    unittest.main()
