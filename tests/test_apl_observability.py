"""Fast exact-byte observability regression and reachability tests."""
from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import audit_apl_observability as audit


class ObservabilityTests(unittest.TestCase):
    def test_exact_catalogue_34_revisions_and_historical_debt(self):
        all_rows, flagged = audit.analyse(ROOT)
        self.assertEqual(34, len(all_rows))
        self.assertEqual(4, len(flagged))
        self.assertEqual(18, sum(len(x["findings"]) for x in flagged))
        self.assertEqual(
            {"Druid_Feral", "Warrior_Arms", "Warlock_Demonology"},
            {x["role"] for x in flagged}
        )
        baseline = json.loads((ROOT / audit.BASELINE).read_text())
        self.assertEqual([], audit.compare_baseline(flagged, baseline))
        p0 = [x for x in all_rows if x["role"] in
              {"Druid_Guardian", "Hunter_BeastMastery"}]
        self.assertEqual(6, len(p0))
        self.assertTrue(all(not x["findings"] for x in p0))

    def test_combat_hidden_health_through_nested_action_calls(self):
        source = (
            "actions.precombat=bloodrage,if=health.pct>=95\n"
            "actions=call_action_list,name=cat\n"
            "actions.cat+=/call_action_list,name=defensives\n"
            "actions.defensives=barkskin,if=health.pct<50\n"
        )
        found = audit.scan_apl(source)
        self.assertEqual(2, len(found))
        self.assertEqual(
            [("player_health", "precombat"), ("player_health", "combat")],
            [(x["rule"], x["phase"]) for x in found]
        )

    def test_precombat_list_reused_by_combat_is_not_safe(self):
        source = (
            "actions.precombat=call_action_list,name=shared\n"
            "actions=call_action_list,name=shared\n"
            "actions.shared=bloodrage,if=health.pct>=95\n"
        )
        found = audit.scan_apl(source)
        self.assertEqual("combat", found[0]["phase"])

    def test_apl_health_tokens_ignore_pet_max_and_identifiers(self):
        source = (
            "actions=wrath,if=pet.health.pct<20&health.max>0&healthstone.known&"
            "target.health.max>1&rage.lo>12\n"
        )
        self.assertEqual([], audit.scan_apl(source))
        source = (
            "actions=wrath,if=health<50&target.health.pct<=20&"
            "incoming_magic_damage_5s>200&at_risk>0&fight_remains<8&"
            "target.time_to_pct_20<10\n"
        )
        found = audit.scan_apl(source)
        self.assertEqual(
            {"player_health", "target_health", "hidden_incoming",
             "group_health", "fixed_fight_time"}, {x["rule"] for x in found}
        )
        self.assertEqual(6, len(found))

    def test_unreachable_lists_not_mistaken_for_castability_proof(self):
        rows = audit.action_lines(
            "actions=wrath\n"
            "actions.never=wrath,if=health.pct<50\n"
        )
        self.assertEqual("unreachable/unproven", audit.phases(rows)["never"])

    def test_new_hidden_state_and_baseline_mutation_fail_closed(self):
        _, flagged = audit.analyse(ROOT)
        baseline = json.loads((ROOT / audit.BASELINE).read_text())
        fake = copy.deepcopy(flagged)
        fake.append({
            "role": "Hunter_BeastMastery", "revision": "v9.9",
            "path": "roles/Hunter/Candidates/new.txt", "sha256": "a" * 64,
            "signatures": {"player_health:combat": 1},
            "findings": [{"token": "health.pct"}]
        })
        self.assertTrue(any("NEW source-state exposure" in msg for msg in
                            audit.compare_baseline(fake, baseline)))
        broken = copy.deepcopy(flagged)
        broken[0]["signatures"] = {"player_health:combat": 2}
        self.assertTrue(any("baseline mismatch" in msg for msg in
                            audit.compare_baseline(broken, baseline)))

    def test_matrix_never_turns_unrun_source_into_approval(self):
        rows, flagged = audit.analyse(ROOT)
        evidence = json.loads((ROOT / audit.EVIDENCE).read_text())
        result = audit.report(rows, flagged, evidence, [])
        self.assertIn("Druid_Guardian", result)
        self.assertIn("Hunter_BeastMastery", result)
        self.assertIn("Warlock_Demonology", result)
        self.assertIn("Not individually established on v0.10.0", result)
        self.assertIn("Partial / Blocked", result)
        self.assertIn("not proven", result.lower())


if __name__ == "__main__":
    unittest.main()
