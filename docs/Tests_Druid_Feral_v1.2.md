# Tests — Druid Feral DPS v1.2 Draft Candidate

**Date:** 19 November 2026. **Source pin:** official Hekili Forever v0.10.0 `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`, [published release](https://github.com/zmsl/hekili/releases/tag/v0.10.0). **Commit:** [Candidate test head 43402c5](https://github.com/tkbiccay/APLForever-Open/commit/43402c5190328ca04e10222d06833b9eaed5b390). **Actual Actions run:** [44574486358](https://github.com/tkbiccay/APLForever-Open/actions/runs/44574486358), **PASSED 3/3**.

## Before/after and exact bytes

Historical Feral Current v1.0 Draft is **not reported working**, SHA256 `f2f72d0621c8e709c7df8f2ccff248ce0af604a1c02e115a5ad725cf93d288f1`; prior unselected v1.1 Draft SHA256 `f611e4510a52ca125103eed9f3d1d4fc99a0b656b161cdc88134f0e72b6e52f7`. New independent standalone v1.2 Draft SHA256 `52568f2d069699c5b453aaa98515c3c2096594f4b790ba0e8591c417bcdb95c9`. Both earlier originals remain untouched and v1.0 remains `preferred_apl`, with `last_working_apl=null`.

The v1.2 full list differs from v1.1 **only** by replacing `health.pct<=65` Barkskin with `combat>0&tanking&target.within5` plus the existing Defensives/known/ready/aura gates, and removing unreachable `health.pct<=45` Frenzied Regeneration/Nature's Grasp lines. The original damage/form/DoT/CP/major/minor/precombat/fallback chains are otherwise identical.

## Reproducible executable evidence

Source-native isolated `tests/native/aplforever_feral_defensives_v010_spec.lua` (run by `.github/workflows/feral-v010-candidate.yml`) imports **the literal catalogued candidate**, compiles and reviews all internal lists with **zero hidden-health warnings**. It checks the entire Cat/Bear/caster topology and requires genuine world-accepted non-vacuous progression.

| Pin / scenario | Accepted source casts | Refused source casts | Source engine errors | Evidence |
| --- | ---: | ---: | ---: | --- |
| v0.10.0 static and native import check | n/a | n/a | 0 | 1/1 pass |
| 32s Feral single-target, Defensives OFF, stock spellbook | 24 | 0 | 0 | 1/1 pass |
| Same matched world, Defensives ON, stock spellbook | 24 | 0 | 0 | 1/1 pass |

**Failure corrected and preserved:** [first red run 44574136921](https://github.com/tkbiccay/APLForever-Open/actions/runs/44574136921) was a **test-harness error**: omitted required `loop.run` driver list (`drivers=nil`), not a source refusal. Fixed only the test driver with verified pattern, then [green run 44574486358](https://github.com/tkbiccay/APLForever-Open/actions/runs/44574486358) passed. No candidate APL bytes/hash changed between the two.

## Strictly unverified

The published Feral source world does **not** train Barkskin, so both 32s worlds are *negative eligibility and DPS fallback checks*, not evidence of a real Barkskin cast under `tanking`. No actual tanking threat-trigger was source-accepted, player health/mitigation in combat is unreadable, and Frenzied Regeneration health exchange is source-unmodelled. Other source levels, 2/3+ targets, Cat facing/positional Shred, live buffs and /hek snap remain unrun on v1.2. Existing v1.1 Feral Shred/CP resource tests are inherited by exact unchanged priorities but **not rerun under this new source pin**. This is not numerical DPS, live-gameplay or approval evidence. The shipped v0.10.0 default and no known last-working Feral comparator have not undergone a fair matched DPS comparison.

**Final fallback / repeated recommendation checkpoint:** 32s true source-accepted combat and zero refusal are confirmed for stock Feral kit; **3 consecutive state-advanced first icons and low-resource exhaustion in v1.2 are not separately probed**, so in-game/extended-loop approval remains blocked. Historical v0.9.0 all-role regression is independently tracked by PR #16.

**State:** Source-native tested Draft Candidate (not preferred, not Approved). Next: focused real source Barkskin eligibility if world supports measured threat, otherwise player /hek snap at L44+ with Defensives ON and OFF; preserve both earlier full APLs. No speculative polish.
