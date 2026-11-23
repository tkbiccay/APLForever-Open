# Shaman Elemental — source-native v0.11.0 combat, low-Mana and final fallback

**23 November 2026.** Portfolio breadth role: **Shaman Elemental**. Published Forever v0.11.0 source pinned exactly to `zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b`. Full shipped profile vs **protected Current v1.0 Draft** `roles/Shaman/Current/APL_Shaman_Elemental_v1.0_Draft.txt`; Major OFF, two matched seeds, 25yd full/25% starting Mana and **diagnostic** 60yd, 65s/90s/28s. [PR #82](https://github.com/tkbiccay/APLForever-Open/pull/82), [final focused source run 45088305320](https://github.com/tkbiccay/APLForever-Open/actions/runs/45088305320), **6/6 successes and 12 full source-world profile executions**.

| Seed | Scenario | Shipped accepted | Current accepted | Refusal detail (strict) |
| --- | --- | ---: | ---: | --- |
| 30417 | 25yd normal Mana, 65s | 38 | 36 | Both zero |
| 30437 | 25yd normal Mana, 65s | 38 | 35 | Shipped 1 and Current 2 `casting` at the cast-end floating-point boundary, less than or equal to 1e-7 s; **zero substantial or other refusal** |
| 30417 | 25yd at 25% starting Mana, 90s | 24 | 25 | Both zero |
| 30437 | 25yd at 25% starting Mana, 90s | 22 | 21 | Both zero |
| 30417 | source fixture diagnostic 60yd, 28s | 19 | 17 | Both zero, but outside realistic cast range |
| 30437 | source fixture diagnostic 60yd, 28s | 19 | 16 | Both zero, but outside realistic cast range |

**Actual post-first-offensive fallback:** all Current 25yd profiles had **at least three later genuinely accepted `lightning_bolt` actions**, including low-Mana. Same-spell legal repeated filler is **not** a repeated-uncastable recommendation. The older detector incorrectly skipped the later Bolts; this PR corrected its counting. No numerical DPS, actual DoT damage, talent Clearcasting proc or live client proof.

**Float-boundary diagnosis and preserved red evidence:** [first underasserted green 45086730847](https://github.com/tkbiccay/APLForever-Open/actions/runs/45086730847) masked two Current source `casting` refusals. [Strict red 45088011895](https://github.com/tkbiccay/APLForever-Open/actions/runs/45088011895) then exposed them. [Exact attempted-key/timing trace 45088158613](https://github.com/tkbiccay/APLForever-Open/actions/runs/45088158613): both Current refusals were Lightning Bolt at 33.4/64.8s; shipped had the same 64.8s issue, each with `castUntil - W.t` strictly positive but below 1e-7s. Published `tests/Game/harness/world.lua` uses strict `t<castUntil` for this reason; GCD already tolerates 1e-9. Final test permits only at most two of those tiny boundary artefacts; rejects any other reason, substantial casting overlap, untraced refusal, or fewer than three subsequent accepted actions. Do **not** edit a production APL to accommodate this source-world clock rounding without real-client proof.

**Third caster range limitation (cross-spec):** at simulated 60yd the released Shaman source world still accepted 17 and 16 Current offensive casts across seeds (shipped 15 each). Its class source helper `C.usable` has no explicit range predicate. This mirrors Priest Shadow and Warlock Affliction: **test-fixture/model limitation**, not real cast range or grounds to remove gameplay safety guards.

**Known untested:** real Clearcasting procs or cost changes, target switching/AoE, totems/imbues completeness, levels 1–60, true rank unlocks, actual cast-time latency, defensive off-switch, native player range, damage/throughput and in-game feedback. Source-world pure acceptance counts do not establish DPS gains. No APL modification, catalogue promotion or full compatibility claim; the 46 protected historical revision hashes and rollbacks remain unchanged, zero Approved.

**Next role:** rotate to Rogue Combat or Mage Arcane to extend resource/fallback coverage into a *different* class. In a separate Elemental pass use real source-registered Clearcasting effects and both positive and negative cost scenarios; do not mark that tested here. **Final Fallback / Repeated Recommendation:** completed within this matched normal/low-Mana source gate only; out-of-game evidence remains required.
