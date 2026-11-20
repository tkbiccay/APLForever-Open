"""Tests for repository integrity checks (not APL behavior)."""

from __future__ import annotations

import copy
import hashlib
import json
import sys
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import validate_repository as validator  # noqa: E402


class RepositoryValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "catalogue").mkdir()
        self.data = json.loads((ROOT / "catalogue" / "roles.json").read_text(encoding="utf-8-sig"))
        # Tests use isolated synthetic revisions, not copied production APLs.
        # Keep the canonical 28-role identities, but start each fixture with no
        # real revisions or protected references so imports do not break tests.
        for role in self.data["roles"]:
            role["revisions"] = []
            role["latest_revision"] = None
            role["validation_status"] = "Unknown"
            for reference in validator.ROLE_REFERENCES:
                role[reference] = None
        self.write_catalogue()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_catalogue(self) -> None:
        (self.root / "catalogue" / "roles.json").write_text(json.dumps(self.data, indent=2), encoding="utf-8")
        (self.root / "Catalogue_All_Roles.md").write_text(validator.render_catalogue(self.data), encoding="utf-8")

    def errors(self) -> list[str]:
        self.write_catalogue()
        errors, _ = validator.validate_repository(self.root, check_git=False, enforce_layout=False)
        return errors

    def test_actual_repository_with_migrated_apls_is_integral(self) -> None:
        # Independently validate current production metadata and archived files.
        failures, _ = validator.validate_repository(ROOT, check_git=False)
        self.assertEqual(failures, [])

    def test_canonical_apl_names_match_class_and_spec_only(self) -> None:
        self.assertEqual(len({role["apl_name"] for role in self.data["roles"]}), 28)
        self.assertTrue(all(
            role["apl_name"] == f'{role["class"]}_{role["spec"]}'
            for role in self.data["roles"]
        ))
        self.assertEqual(self.errors(), [])

    def test_unselected_newer_hunter_candidate_keeps_current_lifecycle(self) -> None:
        # Regression: latest_revision must be a history/version pointer,
        # NEVER a hidden approval or implicit Current selector.
        import copy
        data = json.loads((ROOT / "catalogue" / "roles.json").read_text(encoding="utf-8-sig"))
        hunter = copy.deepcopy(next(r for r in data["roles"] if r["apl_name"] == "Hunter_BeastMastery"))
        current = next(item for item in hunter["revisions"] if "/Current/" in item["apl_file"])
        candidates = [item for item in hunter["revisions"] if "/Candidates/" in item["apl_file"]]
        latest = max(
            hunter["revisions"],
            key=lambda item: tuple(int(n) for n in item["revision"][1:].split(".")),
        )
        self.assertIsNone(hunter["preferred_apl"])
        self.assertEqual(latest["revision"], hunter["latest_revision"])
        self.assertIn(latest, candidates)
        self.assertGreaterEqual(len(candidates), 1)
        self.assertEqual("Current", validator._lifecycle_folder(hunter, current))
        for candidate in candidates:
            self.assertEqual("Candidates", validator._lifecycle_folder(hunter, candidate))
        self.assertEqual("Archive", validator._lifecycle_folder(hunter, hunter["revisions"][0]))

    def test_real_repository_enforces_class_lifecycle_layout(self) -> None:
        failures, _ = validator.validate_repository(ROOT, check_git=False)
        self.assertEqual(failures, [])
        for role in json.loads((ROOT / "catalogue" / "roles.json").read_text())["roles"]:
            for revision in role["revisions"]:
                path = Path(revision["apl_file"])
                self.assertEqual(path.parent.name, validator._lifecycle_folder(role, revision))
                self.assertEqual(path.parent.parent.name, role["class"])

    def test_wrong_apl_name_is_rejected(self) -> None:
        self.data["roles"][0]["apl_name"] = "Druid_Balance_DPS"
        self.assertTrue(any("apl_name must equal" in err for err in self.errors()))

    def test_legacy_role_suffix_requires_explicit_archive_flag(self) -> None:
        role = self.data["roles"][0]
        data = b"historical APL text\\n"
        name = "APL_Druid_Balance_DPS_v1.0_Draft.txt"
        (self.root / "roles").mkdir()
        (self.root / "roles" / name).write_bytes(data)
        rev = {"revision": "v1.0", "apl_file": f"roles/{name}",
               "status": "Draft", "sha256": hashlib.sha256(data).hexdigest()}
        role["latest_revision"] = "v1.0"
        role["revisions"] = [rev]
        self.assertTrue(any("non-canonical APL filename" in err for err in self.errors()))
        rev["legacy_filename"] = True
        self.assertEqual(self.errors(), [])

    def test_new_two_token_filename_is_accepted(self) -> None:
        role = self.data["roles"][0]
        data = b"actions=wrath\\n"
        name = "APL_Druid_Balance_v1.0_Draft.txt"
        (self.root / "roles").mkdir()
        (self.root / "roles" / name).write_bytes(data)
        role["latest_revision"] = "v1.0"
        role["revisions"] = [{"revision": "v1.0", "apl_file": f"roles/{name}",
                              "status": "Draft", "sha256": hashlib.sha256(data).hexdigest()}]
        self.assertEqual(self.errors(), [])

    def test_catalogue_contains_exact_intended_roles(self) -> None:
        self.assertEqual(len(self.data["roles"]), 28)
        guardian = next(role for role in self.data["roles"] if role["class"] == "Druid" and role["spec"] == "Guardian")
        self.assertEqual(guardian["addon_taxonomy"], {"addon": "Forever", "identifier": "Guardian/Feral"})
        self.assertEqual(self.errors(), [])

    def test_multiword_spec_uses_one_pascalcase_token(self) -> None:
        hunter = next(role for role in self.data["roles"] if role["class"] == "Hunter" and role["spec"] == "BeastMastery")
        self.assertEqual(hunter["role"], "DPS")
        self.assertIn(("Hunter", "BeastMastery", "DPS"), validator.EXPECTED_ROLES)
        self.assertIsNotNone(validator.APL_NAME_RE.fullmatch("APL_Hunter_BeastMastery_v1.0_Draft.txt"))
        self.assertIsNone(validator.APL_NAME_RE.fullmatch("APL_Hunter_Beast_Mastery_DPS_v1.0_Draft.txt"))

    def test_single_word_spec_uses_canonical_filename(self) -> None:
        self.assertIsNotNone(validator.APL_NAME_RE.fullmatch("APL_Druid_Balance_v1.0_Draft.txt"))

    def test_spaces_and_separators_are_rejected_in_name_tokens(self) -> None:
        for filename in (
            "APL_Hunter_Beast Mastery_DPS_v1.0_Draft.txt",
            "APL_Hunter_Beast-Mastery_DPS_v1.0_Draft.txt",
            "APL_Hunter_Beast_Mastery_DPS_v1.0_Draft.txt",
        ):
            with self.subTest(filename=filename):
                self.assertIsNone(validator.APL_NAME_RE.fullmatch(filename))

    def test_invalid_class_spec_role_combination_is_rejected(self) -> None:
        hunter = next(role for role in self.data["roles"] if role["spec"] == "BeastMastery")
        hunter["role"] = "Tank"
        failures = self.errors()
        self.assertTrue(any("missing intended role" in error for error in failures))
        self.assertTrue(any("unexpected role" in error for error in failures))

    def test_noncanonical_underscored_spec_is_rejected(self) -> None:
        hunter = next(role for role in self.data["roles"] if role["spec"] == "BeastMastery")
        hunter["spec"] = "Beast_Mastery"
        failures = self.errors()
        self.assertTrue(any("missing intended role" in error for error in failures))
        self.assertTrue(any("unexpected role" in error for error in failures))

    def test_supporting_files_enforce_canonical_spec_stem(self) -> None:
        (self.root / "roles").mkdir()
        hunter = next(role for role in self.data["roles"] if role["spec"] == "BeastMastery")
        apl_content = b"APL fixture\n"
        apl_name = "APL_Hunter_BeastMastery_v1.0_Draft.txt"
        (self.root / "roles" / apl_name).write_bytes(apl_content)
        hunter["latest_revision"] = "v1.0"
        hunter["revisions"] = [{
            "revision": "v1.0", "apl_file": f"roles/{apl_name}", "status": "Draft",
            "sha256": hashlib.sha256(apl_content).hexdigest(), "evidence": [], "test_results": [],
        }]
        (self.root / "roles" / "Research_Hunter_BeastMastery_v1.0.md").write_text("Research fixture\n", encoding="utf-8")
        self.assertEqual(self.errors(), [])
        (self.root / "roles" / "Research_Hunter_Beast_Mastery_v1.0.md").write_text("Invalid alias fixture\n", encoding="utf-8")
        self.assertTrue(any("non-canonical supporting filename" in error for error in self.errors()))

    def test_supporting_file_revision_must_match_apl_revision(self) -> None:
        hunter = next(role for role in self.data["roles"] if role["spec"] == "BeastMastery")
        content = b"APL fixture\n"
        filename = "APL_Hunter_BeastMastery_v1.0_Draft.txt"
        (self.root / "roles").mkdir()
        (self.root / "roles" / filename).write_bytes(content)
        hunter["latest_revision"] = "v1.0"
        hunter["revisions"] = [{"revision": "v1.0", "apl_file": f"roles/{filename}",
                                "status": "Draft", "sha256": hashlib.sha256(content).hexdigest()}]
        (self.root / "roles" / "Tests_Hunter_BeastMastery_v2.0.md").write_text("Tests\n", encoding="utf-8")
        self.assertTrue(any("no matching APL revision" in error for error in self.errors()))

    def test_invalid_revision_and_filename_status_are_rejected(self) -> None:
        role = self.data["roles"][0]
        role["revisions"] = [{
            "revision": "v1", "apl_file": "roles/APL_Druid_Balance_v1_Unknown.txt",
            "status": "Unknown", "sha256": "0" * 64,
        }]
        role["latest_revision"] = "v1"
        failures = self.errors()
        self.assertTrue(any("invalid revision syntax" in error for error in failures))
        self.assertTrue(any("invalid status" in error for error in failures))

    def test_catalogue_role_and_apl_filename_must_match(self) -> None:
        role = self.data["roles"][0]
        content = b"APL fixture\n"
        filename = "APL_Druid_Feral_v1.0_Draft.txt"
        (self.root / "roles").mkdir()
        (self.root / "roles" / filename).write_bytes(content)
        role["latest_revision"] = "v1.0"
        role["revisions"] = [{"revision": "v1.0", "apl_file": f"roles/{filename}",
                              "status": "Draft", "sha256": hashlib.sha256(content).hexdigest()}]
        self.assertTrue(any("non-canonical APL filename" in error for error in self.errors()))

    def test_missing_role_is_detected(self) -> None:
        self.data["roles"].pop()
        self.assertTrue(any("missing intended role" in error for error in self.errors()))

    def test_malformed_role_row_is_reported(self) -> None:
        self.data["roles"][0] = None
        (self.root / "catalogue" / "roles.json").write_text(json.dumps(self.data), encoding="utf-8")
        (self.root / "Catalogue_All_Roles.md").write_text("", encoding="utf-8")
        failures, _ = validator.validate_repository(self.root, check_git=False)
        self.assertTrue(any("must be an object" in error for error in failures))

    def test_invalid_lifecycle_is_detected(self) -> None:
        self.data["roles"][0]["validation_status"] = "LooksGood"
        self.assertTrue(any("validation_status" in error for error in self.errors()))

    def test_missing_protected_reference_is_detected(self) -> None:
        role = self.data["roles"][0]
        role["preferred_apl"] = "roles/APL_Druid_Balance_v1.0_Approved.txt"
        self.assertTrue(any("does not resolve" in error for error in self.errors()))

    def test_hash_mismatch_is_detected(self) -> None:
        role = self.data["roles"][0]
        content = b"# verified fixture\n"
        name = "APL_Druid_Balance_v1.0_Draft.txt"
        (self.root / "roles").mkdir()
        (self.root / "roles" / name).write_bytes(content)
        role["revisions"] = [{
            "revision": "v1.0", "apl_file": f"roles/{name}", "status": "Draft",
            "sha256": "0" * 64, "evidence": [], "test_results": [],
        }]
        role["latest_revision"] = "v1.0"
        self.assertTrue(any("sha256 mismatch" in error for error in self.errors()))

    def test_approval_without_evidence_is_detected(self) -> None:
        role = self.data["roles"][0]
        content = b"# non-empty fixture only\n"
        digest = hashlib.sha256(content).hexdigest()
        name = "APL_Druid_Balance_v1.0_Approved.txt"
        (self.root / "roles").mkdir()
        (self.root / "roles" / name).write_bytes(content)
        role.update({
            "support_status": "Unknown", "validation_status": "Approved",
            "preferred_apl": f"roles/{name}", "latest_revision": "v1.0",
            "revisions": [{"revision": "v1.0", "apl_file": f"roles/{name}",
                           "status": "Approved", "sha256": digest, "evidence": []}],
        })
        failures = self.errors()
        self.assertTrue(any("in-game evidence reference" in error for error in failures))

    def test_catalogue_rendering_is_deterministic(self) -> None:
        first = validator.render_catalogue(self.data)
        second = validator.render_catalogue(copy.deepcopy(self.data))
        self.assertEqual(first, second)

    def test_stale_generated_catalogue_is_detected(self) -> None:
        self.write_catalogue()
        (self.root / "Catalogue_All_Roles.md").write_text("stale\n", encoding="utf-8")
        failures, _ = validator.validate_repository(self.root, check_git=False)
        self.assertTrue(any("missing or stale" in error for error in failures))

    def test_protected_revision_can_be_relocated_without_changing_its_blob(self) -> None:
        role = self.data["roles"][0]
        source = "roles/APL_Druid_Balance_v1.0_Draft.txt"
        target = "roles/Druid/Current/APL_Druid_Balance_v1.0_Draft.txt"
        original = b"actions=wrath\\n"
        (self.root / "roles").mkdir()
        (self.root / source).write_bytes(original)
        role["latest_revision"] = "v1.0"
        role["revisions"] = [{
            "revision": "v1.0", "apl_file": source, "status": "Draft",
            "sha256": hashlib.sha256(original).hexdigest(),
        }]
        self.write_catalogue()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.email", "test@example.invalid"], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.name", "Repository Test"], check=True)
        subprocess.run(["git", "-C", str(self.root), "add", "."], check=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-qm", "protected baseline"], check=True)

        (self.root / target).parent.mkdir(parents=True)
        (self.root / target).write_bytes(original)
        (self.root / source).unlink()
        role["revisions"][0]["apl_file"] = target
        role["revisions"][0]["relocated_from"] = source
        self.write_catalogue()
        failures, note = validator.validate_repository(self.root)
        self.assertIsNone(note)
        self.assertEqual(failures, [])

        (self.root / target).write_bytes(b"actions=shadow_bolt\\n")
        failures, _ = validator.validate_repository(self.root)
        self.assertTrue(any("protected APL changed in place" in e for e in failures))

        (self.root / target).write_bytes(original)
        role["revisions"][0]["relocated_from"] = "roles/Druid/Archive/APL_Druid_Balance_v1.0_Draft.txt"
        self.write_catalogue()
        failures, _ = validator.validate_repository(self.root)
        self.assertTrue(any("unverified relocation" in e for e in failures))

    def test_protected_git_baseline_cannot_be_rewritten_in_place(self) -> None:
        role = self.data["roles"][0]
        content = b"APL baseline fixture\n"
        digest = hashlib.sha256(content).hexdigest()
        name = "APL_Druid_Balance_v1.0_ReportedWorking.txt"
        (self.root / "roles").mkdir()
        (self.root / "roles" / name).write_bytes(content)
        role["last_working_apl"] = f"roles/{name}"
        role["latest_revision"] = "v1.0"
        role["revisions"] = [{"revision": "v1.0", "apl_file": f"roles/{name}",
                              "status": "ReportedWorking", "sha256": digest,
                              "evidence": [], "test_results": []}]
        self.write_catalogue()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.email", "test@example.invalid"], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.name", "Repository Test"], check=True)
        subprocess.run(["git", "-C", str(self.root), "add", "."], check=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-qm", "baseline"], check=True)
        (self.root / "roles" / name).write_bytes(b"changed in place\n")
        failures, note = validator.validate_repository(self.root, enforce_layout=False)
        self.assertIsNone(note)
        self.assertTrue(any("protected APL changed in place" in error for error in failures))

    def test_pull_request_compares_protected_files_with_main(self) -> None:
        role = self.data["roles"][0]
        baseline = b"APL baseline fixture\n"
        baseline_hash = hashlib.sha256(baseline).hexdigest()
        name = "APL_Druid_Balance_v1.0_ReportedWorking.txt"
        apl_path = self.root / "roles" / name
        apl_path.parent.mkdir()
        apl_path.write_bytes(baseline)
        role["last_working_apl"] = f"roles/{name}"
        role["latest_revision"] = "v1.0"
        role["revisions"] = [{"revision": "v1.0", "apl_file": f"roles/{name}",
                              "status": "ReportedWorking", "sha256": baseline_hash,
                              "evidence": [], "test_results": []}]
        self.write_catalogue()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.email", "test@example.invalid"], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.name", "Repository Test"], check=True)
        subprocess.run(["git", "-C", str(self.root), "add", "."], check=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-qm", "main baseline"], check=True)
        base_sha = subprocess.run(["git", "-C", str(self.root), "rev-parse", "HEAD"], check=True,
                                  capture_output=True, text=True).stdout.strip()
        subprocess.run(["git", "-C", str(self.root), "update-ref", "refs/remotes/origin/main", base_sha], check=True)

        candidate = b"APL candidate changed in place\n"
        apl_path.write_bytes(candidate)
        role["revisions"][0]["sha256"] = hashlib.sha256(candidate).hexdigest()
        self.write_catalogue()
        subprocess.run(["git", "-C", str(self.root), "add", "."], check=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-qm", "candidate rewrite"], check=True)

        # CI exports GITHUB_BASE_REF for the *outer* PR; this isolated
        # fixture creates its own origin/main baseline and must select it.
        with patch.dict("os.environ", {"GITHUB_BASE_REF": "main"}):
            failures, note = validator.validate_repository(self.root, enforce_layout=False)
        self.assertIsNone(note)
        self.assertTrue(any("protected APL changed in place since" in error for error in failures))


if __name__ == "__main__":
    unittest.main()
