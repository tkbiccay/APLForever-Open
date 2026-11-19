"""Offline data and generated-reference invariants, no WoW client needed."""
import copy
import json
from pathlib import Path
import sys
import unittest
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import build_mechanics_reference as ref


class MechanicsReferenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.docs = ref.documents()
        cat = json.loads((ROOT / "catalogue" / "roles.json").read_text(encoding="utf-8-sig"))
        cls.supported = {r["apl_name"] for r in cat["roles"] if r["support_status"] == "Supported"}

    def test_all_source_pins_and_generated_pages(self):
        for d in self.docs:
            with self.subTest(d["class"]):
                ref.validate_structure(d, self.supported)
                page = ROOT / "docs" / "reference" / (d["pilot_role"] + ".md")
                self.assertEqual(ref.render(d), page.read_text(encoding="utf-8"))

    def test_pilot_coverage_and_talent_review_honesty(self):
        classes = {d["class"]: d for d in self.docs}
        self.assertEqual(50, len(classes["Hunter"]["talents"]))
        self.assertEqual(52, len(classes["Druid"]["talents"]))
        self.assertEqual(14, len(classes["Hunter"]["abilities"]))
        self.assertEqual(13, len(classes["Druid"]["abilities"]))
        self.assertTrue(any(not t["mechanics_reviewed"] for d in self.docs for t in d["talents"]))

    def test_native_toggle_separate_from_role_and_range(self):
        by = {d["class"]: {x["key"]: x for x in d["abilities"]} for d in self.docs}
        self.assertEqual("defensives", by["Druid"]["barkskin"]["native_toggle"])
        self.assertIsNone(by["Druid"]["demoralizing_roar"]["native_toggle"])
        self.assertEqual("off", by["Druid"]["maul"]["gcd"])
        self.assertIn("swipe_bear", by["Druid"])
        self.assertEqual(0, by["Hunter"]["summon_hawk"]["range"]["minimum_yards"])
        self.assertEqual(8, by["Hunter"]["serpent_sting"]["range"]["minimum_yards"])
        self.assertEqual("cooldowns", by["Hunter"]["bestial_wrath"]["native_toggle"])

    def test_unsupported_retail_fact_and_stale_pin_fail(self):
        hunter = next(d for d in self.docs if d["class"] == "Hunter")
        for mutation in ("tag", "toggle", "pin"):
            d = copy.deepcopy(hunter)
            if mutation == "tag":
                d["abilities"][0]["tags"].append("retail_unsupported")
            elif mutation == "toggle":
                d["abilities"][0]["native_toggle"] = "minor_cooldowns"
            else:
                d["pin"]["tag"] = "v0.9.1"
            with self.subTest(mutation), self.assertRaises(ValueError):
                ref.validate_structure(d, self.supported)


if __name__ == "__main__":
    unittest.main()
