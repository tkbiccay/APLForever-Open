"""Guardian v1.1 candidate static guardrails — not a native importer or live test."""

import hashlib
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKING = ROOT / "roles" / "Druid" / "Current" / "APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt"
CANDIDATE = ROOT / "roles" / "Druid" / "Archive" / "APL_Druid_Guardian_v1.1_Draft.txt"
WORKING_HASH = "f386e158a5e262e309dac7d0fd2929fb8e16e02b1378d71b5956c1bf6b99a786"
CANDIDATE_HASH = "9be531a5ce56893b1afc508b9181d966637a2713134c340eb391d127d7fff94f"
BARKSKIN_CANDIDATE = ROOT / "roles" / "Druid" / "Candidates" / "APL_Druid_Guardian_v1.2_Draft.txt"
BARKSKIN_HASH = "da358b7c04b47732966c47a91b7f6f5d32410f9077aabe2aac39252139a47b76"
DRUID_ACTIONS = {
    "mark_of_the_wild", "thorns", "bear_form", "faerie_fire", "wrath", "moonfire",
    "demoralizing_roar", "lacerate", "primal_bite", "swipe_bear", "maul",
}
SHARED = {"call_action_list", "elunes_light"}
LINE = re.compile(r"^actions(?:\.([a-z_]+))?\+?=/?([a-z_]+)")


class GuardianV11StaticGuards(unittest.TestCase):
    def source(self):
        data = CANDIDATE.read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(), CANDIDATE_HASH)
        return data.decode("utf-8")

    def test_exact_working_rollback_untouched(self):
        self.assertEqual(hashlib.sha256(WORKING.read_bytes()).hexdigest(), WORKING_HASH)

    def test_action_keys_lists_and_full_reachable_chain(self):
        lines = [s for s in self.source().splitlines() if s.strip()]
        self.assertEqual(len(lines), 25)
        matches = [LINE.match(s) for s in lines]
        self.assertTrue(all(matches), "unrecognised APL action line")
        self.assertFalse({m.group(2) for m in matches} - DRUID_ACTIONS - SHARED)
        defined = {m.group(1) for m in matches if m.group(1)}
        referenced = set(re.findall(r"call_action_list,name=([a-z_]+)", "\n".join(lines)))
        self.assertTrue(referenced <= defined)
        for name in ("prebear", "cooldowns", "mitigation", "keep_up", "damage", "rage_dump"):
            self.assertIn(name, referenced)
        self.assertTrue(lines[-1].startswith("actions.rage_dump+=/maul,"))

    def test_roar_follows_defensives_and_no_per_spec_setting(self):
        text = self.source()
        self.assertNotIn("settings.", text)
        entries = text.splitlines()
        call = next(x for x in entries if "name=mitigation" in x)
        roar = next(x for x in entries if x.startswith("actions.mitigation=demoralizing_roar"))
        for expected in ("toggle.defensives", "buff.bear_form.up"):
            self.assertIn(expected, call)
        for expected in ("toggle.defensives", "action.demoralizing_roar.known",
                         "target.within5", "!debuff.demoralizing_roar.up",
                         "rage.lo>=action.demoralizing_roar.cost"):
            self.assertIn(expected, roar)

    def test_cooldown_offswitch_on_list_and_racial_action(self):
        lines = self.source().splitlines()
        cd_call = next(x for x in lines if "name=cooldowns" in x)
        cd = next(x for x in lines if x.startswith("actions.cooldowns="))
        self.assertIn("toggle.cooldowns", cd_call)
        self.assertIn("toggle.cooldowns", cd)
        self.assertIn("action.elunes_light.known", cd)

    def test_next_swing_maul_guard_both_paths(self):
        text = self.source()
        mauls = [x for x in text.splitlines()
                 if x.startswith("actions.rage_dump") and
                 re.search(r"=/?maul,", x)]
        self.assertEqual(len(mauls), 2)
        for line in mauls:
            self.assertIn("action.maul.known", line)
            self.assertIn("!buff.maul.up", line)
            self.assertIn("rage.lo>=", line)
        self.assertIn("name=rage_dump,if=buff.bear_form.up", text)

    def test_level_one_fallback_and_no_health_triggers(self):
        t = self.source()
        self.assertIn("actions.prebear=moonfire,if=action.moonfire.known", t)
        self.assertIn("actions.prebear+=/wrath,if=action.wrath.known", t)
        self.assertNotIn("health.", t)
        for forbidden in ("/life_tap", "fight_remains", "cycle_targets="):
            self.assertNotIn(forbidden, t)


class GuardianV12BarkskinStaticGuards(unittest.TestCase):
    def test_v12_exact_v11_plus_standalone_source_registered_barkskin(self):
        original = CANDIDATE.read_bytes()
        candidate = BARKSKIN_CANDIDATE.read_bytes()
        self.assertEqual(hashlib.sha256(original).hexdigest(), CANDIDATE_HASH)
        self.assertEqual(hashlib.sha256(candidate).hexdigest(), BARKSKIN_HASH)
        call = ("actions+=/call_action_list,name=defensive_cooldowns,"
                "if=toggle.defensives&buff.bear_form.up\n").encode()
        bark = ("actions.defensive_cooldowns=barkskin,"
                "if=toggle.defensives&action.barkskin.known&action.barkskin.ready"
                "&buff.bear_form.up&!buff.barkskin.up&target.within5\n").encode()
        self.assertEqual(candidate.count(call), 1)
        self.assertTrue(candidate.endswith(bark))
        self.assertEqual(candidate.replace(call, b"").replace(bark, b""), original)
        text = candidate.decode("utf-8")
        defined = {m.group(1) for line in text.splitlines()
                   if (m := LINE.match(line)) and m.group(1)}
        referenced = set(re.findall(r"call_action_list,name=([a-z_]+)", text))
        self.assertLessEqual(referenced, defined)
        self.assertNotIn("health.", text)
        self.assertNotIn("settings.", text)


if __name__ == "__main__":
    unittest.main()
