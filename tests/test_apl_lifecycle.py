"""Owner lifecycle invariants and stale operational path regression gate."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def version(value):
    return tuple(int(part) for part in value[1:].split("."))


class AplLifecycleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = json.loads((ROOT / "catalogue/roles.json").read_text(encoding="utf-8"))
        cls.roles = cls.data["roles"]

    def test_protected_current_is_explicit_and_unique(self):
        self.assertEqual(self.data.get("lifecycle_policy"), "protected-current-v1")
        supported = [r for r in self.roles if r["support_status"] == "Supported"]
        self.assertEqual(len(supported), 23)
        expected = set()
        for role in supported:
            with self.subTest(role=role["apl_name"]):
                protected = role["protected_rollback_apl"]
                revisions = role["revisions"]
                current = [row for row in revisions if "/Current/" in row["apl_file"]]
                self.assertEqual(len(current), 1)
                self.assertEqual(current[0]["apl_file"], protected)
                expected.add(protected)
                for row in revisions:
                    path = row["apl_file"]
                    if version(row["revision"]) < version(current[0]["revision"]):
                        self.assertIn("/Archive/", path)
                    if "/Candidates/" in path:
                        self.assertGreater(version(row["revision"]), version(current[0]["revision"]))
                    self.assertNotIn("/Checkpoints/", path)
        actual = {p.relative_to(ROOT).as_posix() for p in (ROOT / "roles").glob("*/Current/*.txt")}
        self.assertEqual(actual, expected)

    def test_no_stale_relocated_apl_paths_in_operational_files(self):
        stale = set()
        for role in self.roles:
            for row in role["revisions"]:
                prior = row.get("relocated_from")
                if prior and len(Path(prior).parts) == 4 and prior != row["apl_file"] and not (ROOT / prior).exists():
                    stale.add(prior)
        files = []
        for directory in ("scripts", "tests", "experiments", ".github/workflows"):
            files.extend(p for p in (ROOT / directory).rglob("*")
                         if p.is_file() and p.suffix in {".py", ".lua", ".yml", ".yaml", ".json", ".sh"})
        files.append(ROOT / "docs/knowledge/engine/observability-baseline.json")
        failures = []
        for path in files:
            source = path.read_text(encoding="utf-8")
            for prior in sorted(stale):
                parts = Path(prior).parts
                split_path = (r'["\x27]' + re.escape(parts[2]) + r'["\x27]\s*/\s*["\x27]'
                              + re.escape(parts[3]) + r'["\x27]')
                if prior in source or "/".join(parts[1:]) in source or re.search(split_path, source):
                    failures.append(f"{path.relative_to(ROOT)}: {prior}")
        self.assertFalse(failures, "\n".join(failures))


if __name__ == "__main__":
    unittest.main()
