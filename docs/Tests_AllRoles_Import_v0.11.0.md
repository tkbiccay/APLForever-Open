# All 23 Supported roles — Forever v0.11.0 full Current/Archive import and compiler triage

**Date:** 22 November 2026. **Source:** published Hekili Forever `v0.11.0` at `zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b`. **GitHub:** [PR #79](https://github.com/tkbiccay/APLForever-Open/pull/79); first strict red diagnostic [45081218957](https://github.com/tkbiccay/APLForever-Open/actions/runs/45081218957), corrected strict source-native [45081377956](https://github.com/tkbiccay/APLForever-Open/actions/runs/45081377956) **1/1 PASS**. Both runs used all 46 unchanged catalogue SHA256 checks; native source manifest contained 23 Supported roles, 31 historical selected revisions including extra pilot revisions. The test selected precisely one complete catalogue Current/Archive role APL for each Supported role; no 23-role game-combat claim.

## Measured outcome

| Category | Number | Source-native result |
| --- | ---: | --- |
| Supported role APL full imports attempted | **23/23** | Published `ImportSimcAPL`, `LoadScripts`, `ReviewPacks`, full default/precombat and all list activation |
| Clean Current/Archive imports | **21** | Zero H.errors / unsupported-unknown importer rejects / inactive lists |
| Known Feral Current v1.0 compiler diagnostics | **1 role, 3 H.errors** | Full protected Feral v1.0 still includes three combat `health.pct` guards that the source cannot compile; separately confirmed by earlier PRs #61, #72, #76; exact bytes unchanged |
| Known Warrior Arms Current v1.0 compiler diagnostics | **1 role, 1 H.error** | Precombat Bloodrage guard `health.pct>=95` still emits one opaque compiler diagnostic; in-memory **single-expression substitution** `health.pct>=95` → `0` reduced H.errors **1 → 0**, with zero importer rejects/inactive lists |
| **Unexpected** role importer/compile findings | **0** | Strict gate fails if the two known fault categories change or any other unexpected role error emerges |

All other 21 roles imported/compiled cleanly on the released native source: Druid Balance/Guardian; Hunter BM/Marksmanship/Survival; Mage Arcane/Fire/Frost; Paladin Protection/Retribution; Priest Shadow; Rogue Assassination/Combat/Subtlety; Shaman Elemental/Enhancement; Warlock Affliction/Demonology/Destruction; Warrior Fury/Protection. The two non-clean roles are **not** declared source-compatible; neither is silently waived or treated as a clean pass.

## Important limits and what was NOT proved

- **The green run means the diagnostic harness ran correctly**, accounting for two known pre-existing APL compiler faults; it does not mean 23 APLs passed every import/compilation gate. Exactly 21 passed those checks.
- This is **not a source-world combat loop**: it did not execute recommendations, verify real ability ranks 1–60, model threat and temporary guardians, evaluate final repeated fallbacks, measure DPS/TPS/HPS or prove the game's actual UI works.
- `H.errors` is an opaque source-format template; attribution for Feral derives from prior independent three-guard substitution evidence. Arms precombat-health attribution in THIS run has an independent exact one-expression negative control. The test does not prove whether Arms's precombat health is visible in a real live client; do not remove the guard in a production APL merely to improve static metrics.
- Full protected APLs, rollback, catalogue selection, 28 intended roles (five blocked healer roles), and **zero Approved** statuses remain unchanged. No source-code edits to upstream.

## Decision and next distinct development action

Accept [full-source **21 clean + 2 known debt** compiler/import visibility](../experiments/native/aplforever_allroles_import_v011_spec.lua) as a reusable early compatibility gate; classify release compatibility **Partial**, not Approved/fully tested. Run separate **full accepted-action, matched source-world fallback suites** as necessary, prioritising Guardian/Hunter BM equal P0, then Feral DPS. For actual fixes, preserve old bytes and produce a separately stored full Draft Candidate only with verified APL guards, repeated-fallback and native off-switch evidence. For Arms, first research whether a source-supported, precombat-safe replacement for health is available; never invent an API read or assume the in-memory literal-zero control is production-ready.

**Rollback:** exact protected role references remain in `catalogue/roles.json`; no files under `roles/` changed.
