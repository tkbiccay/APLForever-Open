# Mage Fire — published v0.11.0 low-Mana fallback and accepted-action accounting

**Dated:** 23 November 2026. **Role:** Mage Fire DPS, Supported, Current `roles/Mage/Current/APL_Mage_Fire_v1.0_Draft.txt`. No separate last-working or selected/approved APL registered; exact Current retained as development rollback. **Source:** published Forever v0.11.0 `zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b`, complete shipped WoWSims-derived Fire default and complete protected Current APL. [PR #91](https://github.com/tkbiccay/APLForever-Open/pull/91), [native final 4/4 success 45212151120](https://github.com/tkbiccay/APLForever-Open/actions/runs/45212151120), two matched seeds × 25% and 5% initial Mana, full import and real released-source press loop for 100 seconds. Major and Minor Cooldowns OFF. Eight complete source-world profile runs.

| Seed | Start Mana | Shipped accepted / refused (offensive) | Current accepted / refused (offensive) | Current later accepted offensive |
| --- | ---: | --- | --- | ---: |
| 30417 | 1542 (25%) | 31 / 0 (30) | **20 / 0 (20)** | **19** |
| 30437 | 1542 (25%) | 32 / 0 (31) | **20 / 0 (20)** | **19** |
| 30417 | 308.4 (5%) | 33 / 0 (32) | **20 / 0 (20)** | **19** |
| 30437 | 308.4 (5%) | 33 / 0 (32) | **16 / 0 (16)** | **15** |

**Full fallback/repeated recommendation:** all four Current runs had zero refused world actions and 3+ later accepted offensive actions, mostly legal Scorch, with some Fire Blast. No repeatedly *unaffordable* spell in these source-world scenarios. No numerical DPS measured; the shipped extra accepted actions may differ by resource choice, channel timing and other mechanics. This test did not test high/full starting Mana, level ranks, execute, 2+/AoE, maintained DoT, combat movement, proc or actual game recommendation/UI.

**Important harness correction, preserved failures:** an earlier gate looped `rr.pressed` as if indexed by number of accepted presses (wrong); subsequent strict comparison also failed because `rr.pressed` is tick-indexed and does not always preserve all accepted actions. The final test uses `rr.pressedBy` for the authoritative per-spell **accepted total** and asserts offensive total ≤ total accepted; it still prints `tickOffense` and `missingTickHistory` 0–2 per seed. This supports an accepted-action *count* but not exact timing/order of every accepted cast. If future safety needs chronological action order, instrument the world press handler and compare returned accepted events directly. Do not hide a real refusal or treat mismatched histories as the APL failing.

**Classification:** current-release source-world baseline and harness observability lesson, no new custom APL. All existing 48 protected revisions and rollbacks untouched, no "Approved" promotion. [Cross-spec lesson](knowledge/CROSS_SPEC_LESSONS.md), [role queue](knowledge/ROLE_COVERAGE.md), [breadth campaign](knowledge/BREADTH_50_CAMPAIGN.md). Next distinct breadth role: Hunter Survival **melee-known vs ranged/dead-zone source-world fixture**, with safe three accepted follow-ons where possible.
