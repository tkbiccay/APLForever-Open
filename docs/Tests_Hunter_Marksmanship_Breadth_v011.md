# Hunter Marksmanship — complete Forever v0.11.0 Mana and 5/7/9yd range breadth

**23 Nov 2026**, Hunter Marksmanship DPS (Supported; source-native BREADTH, **not Approved**). Public pin published `zmsl/hekili v0.11.0@86b739cbc4e6afbcbc693c3790ee81197fc6234b`. [PR #86](https://github.com/tkbiccay/APLForever-Open/pull/86); [6/6 native result 45136477431](https://github.com/tkbiccay/APLForever-Open/actions/runs/45136477431). Source `tests/Forever/helpers/hunter_world.lua` `MarksmanshipTurret` with natural source stats at level 60. Full imported shipped WoWSims-derived pack, exact protected Current v1.0 and existing **unselected** pet-upkeep Candidate v1.1; two seeds 30417/30437; native Major/Minor/Defensive/Movement OFF. No APL changed.

## Measured full native test results

| Distance / starting Mana | Shipped actions / refused | Protected Current actions / refused | Candidate v1.1 actions / refused | Current/Candidate offensive acts |
| --- | --- | --- | --- | --- |
| 12yd / full Mana 3750, each seed | 26 / 1 (casting) | **26 / 0** | **26 / 0** | 24 each, 23 later |
| 12yd / 25% Mana 937.5, each seed | 18 / 0 | **17 / 0** | **17 / 0** | 15 each, 14 later |
| 9yd / full Mana, each seed | Not measured | **13 / 0** | **13 / 0** | 11 each, ten later |
| 7yd / full Mana, each seed | 2 / **149 range** | **2 / 0** | **2 / 0** | **zero** |
| 5yd / full Mana, each seed | Not measured | **2 / 0** | **2 / 0** | **zero** |

Durations: 12yd full 70s, 25%-Mana 95s, 5/7/9yd 30s. The test's six assertions each cover a paired seed × scenario, and it performs **26 full source-world profile executions** (3 profiles × two seeds × normal/low/7yd = 18, plus 2 profiles × two seeds × 5/9yd = 8). All tests passed and source raises/errors were zero. At 12yd Current and Candidate had the same accepted counts, next-three genuinely accepted offensive recommendations, and no refusals; no synthetic damage claims.

## Source range truth, unsupported kit and test limitations

The released Hunter source fixture enforces range: at **7yd** shipped repeatedly attempted attacks which the world refused for `range` 149 times per seed, while Current/Candidate suppressed those recommendations (zero false attempts, but also zero offensive actions). Unlike prior Priest Shadow, Affliction and Elemental fixture 60yd tests, this world has enforceable Hunter distance. At **9yd** Current/Candidate resume legal offence. Source **MarksmanshipTurret** kit is intentionally ranged; published `turret()` knows `auto_shot`, `aspect_of_the_hawk`, `hunters_mark`, `rapid_fire`, `arcane_shot`, `serpent_sting`, `aimed_shot` and `sniper_shot` but **does not know** `raptor_strike`, `mongoose_bite` or `strider_kick`. Consequently the 5yd zero offensive-source actions are **fixture character kit incompleteness**, not proven live-world inability to melee or an APL defect. Auto-shot white damage/swing clipping is not included in the accepted recommendation count.

At 12yd shipped had one `casting` refusal per full-Mana seed. The exact spell/time was **not traced**, so do not assume it is the Shaman float-boundary issue. Low-Mana shipped 18 accepted vs Current/Candidate 17, **not a DPS comparison**. The existing candidate's separate pet icon tests [44814291357](https://github.com/tkbiccay/APLForever-Open/actions/runs/44814291357) do not establish actual pet Call/Revive, arrival, pet health or damage, or Hunter range in the real client.

## Full fallback checkpoint and decision

Source normal range and 25%-Mana **three accepted subsequent offensive casts** passed, without repeated refused actions, and native Major OFF was honoured. 7yd held-no-offence vs 149 shipped range refusals is a safety/coverage trade-off, not an APL improvement automatically selected. 5yd needs an actual melee-known Marksmanship source-world character and honest client testing. Level 1–60 kits/talents, swaps, movement, 2+ AoE, interleaved auto-shot clipping, defensive modes, throughput and gameplay remain **Unverified**. No new Candidate or promotion; original Current v1.0 and unselected v1.1 remain byte-identical, rollback intact. A legal silence in a dead zone is not a verified optimal rotation; moving manually into range is outside tested APL logic.

**Next:** Saturday natural 5–8yd check and `/hek snap` if stuck; add safely modelled melee-known source character with true available rank, plus 9yd and 12yd regression; then decide whether any independent complete Candidate is warranted. Cross-spec transfer is documented in [lessons](knowledge/CROSS_SPEC_LESSONS.md) and [role coverage](knowledge/ROLE_COVERAGE.md).
