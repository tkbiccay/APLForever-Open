"""Scope test: old-release full native regression must not run on new Draft-only changes.

The underlying native gate remains exact and callable manually. This is only
workflow trigger behaviour; there is no relaxation of test assertions.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
HIST = ROOT / ".github/workflows/native-v090-compat.yml"
STATIC = ROOT / ".github/workflows/validate.yml"

class HistoricalNativeWorkflowScope(unittest.TestCase):
    def test_v090_is_explicit_manual_and_not_catalogue_only(self):
        text = HIST.read_text(encoding="utf-8")
        self.assertIn("  workflow_dispatch:\n", text)
        self.assertIn("  pull_request:\n", text)
        trigger = text.split("    paths:\n",1)[1].split("\npermissions:",1)[0]
        paths = re.findall(r'^      - "([^"]+)"$',trigger,re.M)
        self.assertNotIn("catalogue/**",paths)
        self.assertIn("roles/**",paths)
        self.assertIn("!roles/**/Candidates/**",paths)
        self.assertLess(paths.index("roles/**"),paths.index("!roles/**/Candidates/**"))
        for essential in [".github/workflows/native-v090-compat.yml",
                          "tests/native/**", "scripts/build_native_manifest.py",
                          "scripts/wiki_release_diff.py"]:
            self.assertIn(essential,paths)
        self.assertIn("ref: 8f95f2ea0a45428554c1e938ed7357b870030514",text)
    def test_canonical_validator_still_runs_all_prs(self):
        text = STATIC.read_text(encoding="utf-8")
        self.assertIn("  pull_request:\n",text)
        self.assertIn("    branches: [main]",text)
        self.assertIn("python scripts/validate_repository.py",text)
if __name__ == "__main__":
    unittest.main()
