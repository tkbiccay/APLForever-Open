"""Tests for the source-native Hekili manifest builder."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import build_native_manifest as manifest  # noqa: E402


class NativeManifestTests(unittest.TestCase):
    @staticmethod
    def expected_protected_revision_count() -> int:
        """The number of individually checked catalogue revisions is dynamic.
        
        Integrity of each original revision is independently enforced by
        validate_repository.py against the baseline Git blobs.
        """
        data = json.loads((ROOT / "catalogue" / "roles.json").read_text(encoding="utf-8-sig"))
        return sum(len(role["revisions"]) for role in data["roles"]
                   if role.get("support_status") == "Supported")

    def test_manifest_covers_all_supported_roles_and_prioritizes_p0_revisions(self) -> None:
        entries, verified = manifest.build_manifest(ROOT)
        names = {entry["apl_name"] for entry in entries}
        self.assertEqual(len(names), 23)
        self.assertEqual(verified, self.expected_protected_revision_count())
        self.assertEqual(
            [entry["apl_name"] for entry in entries[:8]],
            [
                "Warrior_Protection", "Druid_Guardian", "Druid_Guardian",
                "Druid_Guardian", "Druid_Guardian", "Druid_Guardian", "Warlock_Demonology", "Warlock_Demonology",
            ],
        )
        self.assertTrue(all(entry["pilot"] for entry in entries[:8]))
        self.assertEqual(entries[0]["revision"], "v1.0")
        self.assertEqual(entries[1]["revision"], "v1.0")
        self.assertEqual(entries[2]["revision"], "v1.1")
        self.assertEqual(entries[3]["revision"], "v1.2")
        self.assertEqual(entries[4]["revision"], "v1.3")
        self.assertEqual(entries[5]["revision"], "v1.4")
        ret = [entry for entry in entries if entry["apl_name"] == "Paladin_Retribution"]
        self.assertEqual(len(ret), 1)
        self.assertEqual(ret[0]["revision"], "v1.2")
        self.assertEqual(ret[0]["sha256"], "d5a05302c341bbbcb7a69157a40d0a4ae2df8504ce40838e03407515e4e4731b")

    def test_new_hunter_pet_actions_only_enter_v085_manifest(self) -> None:
        for version, expected in (
            ("v0.8.2", "v1.0"),
            ("v0.8.3", "v1.0"),
            ("v0.8.5", "v1.1"),
            ("v0.8.6", "v1.1"),
        ):
            entries, verified = manifest.build_manifest(ROOT, source_release=version)
            selected = [entry for entry in entries if entry["apl_name"] == "Hunter_BeastMastery"]
            self.assertEqual(len(selected), 1)
            self.assertEqual(selected[0]["revision"], expected, version)
            self.assertEqual(verified, self.expected_protected_revision_count())
        with self.assertRaises(ValueError):
            manifest.build_manifest(ROOT, source_release="latest")

    def test_feral_dps_v11_candidate_never_silently_replaces_current(self) -> None:
        # v1.1 is physically in Candidates, but is not approved or the selected
        # import. All source-release manifests must honour Current v1.0 Draft.
        for version in ("v0.8.2", "v0.8.3", "v0.8.5"):
            entries, verified = manifest.build_manifest(ROOT, source_release=version)
            feral = [entry for entry in entries if entry["apl_name"] == "Druid_Feral"]
            self.assertEqual(len(feral), 1)
            self.assertEqual(feral[0]["revision"], "v1.0", version)
            self.assertEqual(
                feral[0]["apl_file"],
                "roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt",
            )
            self.assertEqual(verified, self.expected_protected_revision_count())

    def test_fury_guarded_candidate_does_not_displace_protected_current(self) -> None:
        # The newest Fury v1.1 is a standalone Draft under Candidates; all
        # supported release manifests still use the exact v1.0 Current.
        for version in ("v0.8.2", "v0.8.3", "v0.8.5", "v0.8.6"):
            entries, verified = manifest.build_manifest(ROOT, source_release=version)
            selected = [row for row in entries if row["apl_name"] == "Warrior_Fury"]
            self.assertEqual(len(selected), 1)
            self.assertEqual(selected[0]["revision"], "v1.0", version)
            self.assertEqual(selected[0]["apl_file"],
                             "roles/Warrior/Current/APL_Warrior_Fury_DPS_v1.0_Draft.txt")
            self.assertEqual(verified, self.expected_protected_revision_count())


    def test_unselected_newer_bm_candidate_does_not_replace_current(self) -> None:
        """A new v1.2 Draft must not change the meaning of preferred_apl=null."""
        import copy

        data = json.loads((ROOT / "catalogue" / "roles.json").read_text(encoding="utf-8-sig"))
        hunter = copy.deepcopy(next(role for role in data["roles"]
                                    if role["apl_name"] == "Hunter_BeastMastery"))
        self.assertIsNone(hunter["preferred_apl"])
        candidate = copy.deepcopy(hunter["revisions"][-1])
        candidate["revision"] = "v1.2"
        candidate["apl_file"] = "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.2_Draft.txt"
        candidate["status"] = "Draft"
        hunter["revisions"].append(candidate)

        chosen = manifest.select_revision(hunter, "v0.9.0")
        self.assertEqual("v1.1", chosen["revision"])
        self.assertEqual("roles/Hunter/Current/APL_Hunter_BeastMastery_v1.1_Draft.txt",
                         chosen["apl_file"])

        # A SPECIFIC manual preferred selection remains honoured; only
        # accidental latest-revision selection is disallowed.
        hunter["preferred_apl"] = candidate["apl_file"]
        self.assertEqual("v1.2", manifest.select_revision(hunter, "v0.9.0")["revision"])

    def test_historical_hunter_fallback_and_candidate_only_fail_closed(self) -> None:
        """Retain v0.8.2 archive compatibility; never silently select Candidates."""
        data = json.loads((ROOT / "catalogue" / "roles.json").read_text(encoding="utf-8-sig"))
        hunter = next(role for role in data["roles"]
                      if role["apl_name"] == "Hunter_BeastMastery")
        old = manifest.select_revision(hunter, "v0.8.2")
        self.assertEqual("v1.0", old["revision"])
        self.assertIn("/Archive/", old["apl_file"])

        candidate_only = {
            "apl_name": "Hunter_BeastMastery",
            "preferred_apl": None,
            "revisions": [{
                "revision": "v9.9",
                "apl_file": "roles/Hunter/Candidates/APL_Hunter_BeastMastery_v9.9_Draft.txt",
                "min_source_release": "v0.9.0",
            }],
        }
        with self.assertRaisesRegex(ValueError, "cannot auto-promote"):
            manifest.select_revision(candidate_only, "v0.9.0")

    def test_protected_v082_bundle_selects_original_hunter(self) -> None:
        import build_testing_bundle
        import json
        from zipfile import ZipFile

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "v082.zip"
            build_testing_bundle.build_bundle(output)
            with ZipFile(output) as archive:
                payload = json.loads(archive.read("manifest.json"))
                bm = next(row for row in payload["supported"]
                          if row["apl_name"] == "Hunter_BeastMastery")
                self.assertEqual(bm["selected"]["revision"], "v1.0")
                self.assertTrue(bm["bundle_path"].endswith("APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt"))
                self.assertFalse(any("BeastMastery_v1.1" in name for name in archive.namelist()))

    def test_manifest_is_valid_lua_and_contains_exact_hashes(self) -> None:
        entries, _ = manifest.build_manifest(ROOT)
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "manifest.lua"
            manifest.write_lua_manifest(entries, output)
            text = output.read_text(encoding="utf-8")
        self.assertTrue(text.startswith("return {\n"))
        self.assertIn(entries[0]["sha256"], text)
        self.assertIn('apl_name = "Warrior_Protection"', text)


if __name__ == "__main__":
    unittest.main()
