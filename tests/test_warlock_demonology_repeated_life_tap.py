"""Warlock Demonology repeated Life Tap source guards; not a native engine/live test."""

from pathlib import Path
import hashlib
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKING = ROOT / "roles/Warlock/Current/APL_Warlock_Demonology_DPS_v1.0_ReportedWorking.txt"
DEFAULT = ROOT / "roles/Warlock/Archive/APL_Warlock_Demonology_DPS_v0.8_Default.txt"
WORKING_SHA256 = "067ae757344a71f4a0d02f0a18e2f36745ceb8c0015761970948381aba8e7bf7"
DEFAULT_SHA256 = "da6e5b71c3fc8710745e4ef7037faf5c810958186508b870b3596334d19d3241"


class WarlockDemonologyRepeatedLifeTapGuards(unittest.TestCase):
    def test_preserved_working_hash_and_no_automatic_life_tap(self) -> None:
        data = WORKING.read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(), WORKING_SHA256)
        self.assertNotRegex(data.decode("utf-8"), r"(?m)^actions(?:\.[a-z_]+)?\+?=/life_tap\b")

    def test_working_damage_tail_is_not_a_health_spender(self) -> None:
        text = WORKING.read_text(encoding="utf-8")
        primary = text.split("\n\nactions.banes=", 1)[0]
        self.assertTrue(primary.rstrip().endswith("actions+=/shadow_bolt\nactions+=/searing_pain"))
        self.assertNotIn("/hellfire", text)
        self.assertNotIn("fight_remains", text)

    def test_shipped_comparator_remains_pinned_and_separate(self) -> None:
        self.assertEqual(hashlib.sha256(DEFAULT.read_bytes()).hexdigest(), DEFAULT_SHA256)
        self.assertNotEqual(DEFAULT.read_bytes(), WORKING.read_bytes())

    def test_default_life_tap_risk_remains_documented_not_suppressed(self) -> None:
        text = DEFAULT.read_text(encoding="utf-8")
        lines = text.splitlines()
        tap_lines = [line for line in lines if line.startswith("actions+=/life_tap,if=")]
        self.assertGreaterEqual(len(tap_lines), 2)
        tail = next(line for line in tap_lines if "mana.lo<action.shadow_bolt.cost" in line)
        self.assertNotIn("health.", tail)
        self.assertTrue(all("health." not in line for line in tap_lines))
        self.assertIn("actions+=/shadow_bolt", lines)
        self.assertIn("actions+=/searing_pain", lines)
        # This is a STATIC risk detector, NOT reproduction of the live symptom.


if __name__ == "__main__":
    unittest.main()
