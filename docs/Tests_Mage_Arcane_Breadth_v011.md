# Mage Arcane — Forever v0.11.0 native Mana/final fallback breadth

**Date:** 23 November 2026, portfolio BREADTH. Published Hekili Forever v0.11.0 pinned `zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b`. [Draft PR #84](https://github.com/tkbiccay/APLForever-Open/pull/84); [exact source-native run 45099858565](https://github.com/tkbiccay/APLForever-Open/actions/runs/45099858565): **4 successes, 0 failures, 0 errors**. Full shipped WoWSims-derived vs protected Current `roles/Mage/Current/APL_Mage_Arcane_v1.0_Draft.txt`, imported and activated through real released-source API, no production APL edited.

| Seed | Starting Mana | Shipped accepted / refused | Current accepted / refused | Current accepted offensive / subsequent offensive |
| --- | --- | --- | --- | --- |
| 30417 | Full (source max 6678) | 32 / 1 `casting` | **31 / 0** | **30 / 29** |
| 30437 | Full (source max 6678) | 32 / 0 | **31 / 0** | **30 / 29** |
| 30417 | 25% (1669.5) | 32 / 0 | **22 / 0** | **21 / 20** |
| 30437 | 25% (1669.5) | 26 / 1 `casting` | **19 / 0** | **18 / 17** |

**Gate:** 75 seconds at full Mana and 100 seconds at 25%; two matched seeds, four scenarios, eight complete profile executions. All Current source executions had 3+ genuine later accepted offensive actions, zero source refusals/raise/errors; native Major and Minor Cooldowns OFF, Current 0 Arcane Power/Presence of Mind. All six named Current action lists imported and were active. Repeated supported filler in the source world is legal; no observed repeated unaffordable final action in this scope.

**Source caveats:** `tests/Forever/helpers/mage_world.lua` models Mana hidden to the client during combat, finite source costs, simulated regen and missile channels. It cannot prove actual rank unlocks, 1–60 talent/gear diversity, 2+/4+ AoE, real range/facing/movement, real cooldown/proc state or numerical DPS. Shipped's isolated `casting` refusals were **not time-traced**, so don't automatically classify them as Shaman's known float-boundary. Differences in accepted-cast totals are a **research lead**: low Mana shipped completed 26/32 actions while Current completed 19/22, but not a fair DPS/survival comparison.

**Default vs last working:** shipped is the independent baseline; catalogue lists no separately reported-working Mage Arcane APL, so protected Current v1.0 is the only local comparator/rollback. There is **no new APL Candidate** because no safe, verified improvement was established; default-first benchmark is not an architecture requirement. All 47 stored revisions retained, nothing selected/promoted, 0 Approved.

**Final Fallback / Repeated Recommendation:** passed only this matched 60-level source test. Next evaluate actual Arcane Blast stack-cost changes and Missile Barrage proc/fallback, full level-unlock boundaries, combat movement/off switches, target swaps and client `/hek snap`. For cross-spec transfer see [shared lessons](knowledge/CROSS_SPEC_LESSONS.md). Next new BREADTH spec should use a distinct class (Warrior Protection/Hunter Marksmanship), not repeat under-measured caster range tests.
