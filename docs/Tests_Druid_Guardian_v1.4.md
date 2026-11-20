# Guardian v1.4 — Tests & evidence ledger

**20 November 2026; status: Draft / source-native checks submitted, not yet gameplay validated.** Latest official source: [Hekili Forever v0.10.0](https://github.com/zmsl/hekili/releases/tag/v0.10.0), pinned commit `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`. Candidate SHA `03cc2ef5df2ed18228e8437adf9218ea59f9e2e816243978bee9c68aa501c464`. Source and tests run on public GitHub-hosted runner.

| Check | Test design / evidence status |
| --- | --- |
| Whole source & unchanged working rollback | Catalogue hash and strict `validate_repository.py`; v1.0 remains preferred and exact |
| v1.0 / shipped / v1.2 / v1.3 / v1.4 | Matched L60 official source combat/conditions; source-accepted Roar/Barkskin, no refusals |
| No manual maintenance dependency | v1.4 boss case with native maintain setting OFF **and** ON: equivalent accepted Roar; Defensives OFF and Barkskin absent |
| Short normal-target solo | World source target level = player level, 9 s, actual natural Rage and hostile swings; no Roar with maintain setting either ON or OFF |
| Barkskin manual OFF/ON | v1.0–v1.4 existing source coverage; source-registered Barkskin level-43/44 boundary; no claimed hidden-health trigger |
| Fallback/unlocks/resources | Existing historical v0.9.0 natural low Rage, level 1–9 caster, 24/25, 30/31, 34 unlock, 3 state-advanced recommendations; source-only |
| Group+tanking positive, all modes | **Not demonstrated by real source-world group/threat fixture**; live `/hek snap` required |
| Long solo ordinary / recognised bosses | Natural source truth and target flags to verify; exact 4/5/12 sec and Rage reserve not optimised |
| Target within5 unknown-range, multi-target count | **Engine limitation**, no false castability promise |
| Actual survival/threat/DPS gains | **Not measured**, no phantom percentages |
| Positive high-Rage Maul queue | **Blocked** and separately tracked issue #3 |
| Full v0.10.0 cross-role gate | **Partial**; unrelated Feral combat-health/Arms warnings, PR #13 |

A failed native test fails the candidate and must be diagnosed, not muted. Clean test import does not certify live mechanics. Current preferred remains v1.0 until user observed/approved in-game.
