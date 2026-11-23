# Druid Balance — v0.11 full Moonkin/Form, Mana and final-fallback evidence

**23 November 2026. Source-native executed, not in-game.** Published upstream Hekili Forever v0.11.0 source SHA 86b739cbc4e6afbcbc693c3790ee81197fc6234b. [Draft PR #98](https://github.com/tkbiccay/APLForever-Open/pull/98); [first startup-only Lua syntax RED 45264336355](https://github.com/tkbiccay/APLForever-Open/actions/runs/45264336355) corrected without changing APL; [actual native 10/10 PASS 45264542438](https://github.com/tkbiccay/APLForever-Open/actions/runs/45264542438).

**Role/support:** Druid Balance DPS, Supported. **Protected immutable full Current Draft v1.0:** roles/Druid/Current/APL_Druid_Balance_DPS_v1.0_Draft.txt, SHA256 1cf83328f343e20a8efc93ed06645e862979e8d2f8bfce79acdcfcbedc55c1c2. Catalogue preferred APL and last-working APL are both null, so no player-proved rollback and no promotion. Complete shipped Balance (wowsims.com) priority used as comparator, not an architectural constraint. No new Candidate or edits to protected APLs.

## Fair matched test and actual results

Published Forever.helpers.druid_loop_world.Balance: level 60 full class kit, exact published talent header including Eclipse/Reflection, Moonkin index 5, 4,000 Max Mana and native source Mana/FSR regen, spell prices/procs and DoTs. Two matched seeds **30417 and 30437**. Source-world distance parameter 20yd, **but Balance fixture does not pin an independently verified range table** (unlike Feral), so no real 20yd cast/range/facing claim. Same source and initial state per shipped/current pair. Five scenarios × two matched seeds × two profiles: **20 full source combat loops**. Durations 70–95s. Imported full eight lists (precombat/default/mana_recovery/major_cooldowns/aoe/upkeep/eclipse_spenders/final_fallback) with zero compile/runtime errors; actual accepted spells counted by rr.pressedBy with direct W.press attempted/refused trace.

| Moonkin/form + Mana start | Cooldowns | Seed | Shipped accepted | Current accepted | Current offence | Current Wrath / Starfire | Current Moonkin / Innervate | Current refused |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Moonkin, 4,000 (100%) | OFF | 30417 | 27 | **25** | 25 | 8 / 7 | 0 / 0 | **0** |
| Moonkin, 4,000 | OFF | 30437 | 25 | **25** | 25 | 10 / 7 | 0 / 0 | **0** |
| Moonkin, 1,000 (25%) | OFF | 30417 | 17 | **17** | 17 | 13 / 1 | 0 / 0 | **0** |
| Moonkin, 1,000 | OFF | 30437 | 17 | **17** | 17 | 13 / 1 | 0 / 0 | **0** |
| Moonkin, 200 (5%) | OFF | 30417 | 13 | **13** | 13 | 11 / 0 | 0 / 0 | **0** |
| Moonkin, 200 | OFF | 30437 | 12 | **12** | 12 | 11 / 0 | 0 / 0 | **0** |
| Unshifted, 4,000 | OFF | 30417 | 24 | **24** | 21 | 8 / 6 | **1 / 0** | **0** |
| Unshifted, 4,000 | OFF | 30437 | 26 | **25** | 22 | 11 / 4 | **1 / 0** | **0** |
| Unshifted, 1,000 | ON | 30417 | 26 | **28** | 24 | 12 / 5 | **1 / 1** | **0** |
| Unshifted, 1,000 | ON | 30437 | 25 | **24** | 20 | 12 / 3 | **1 / 1** | **0** |

**Moonkin:** Unshifted scenarios source-accepted one Moonkin Form per seed and ended in form index 5; already-Moonkin scenarios did not recast form. This is a L60 known-kit finding, not universal trainer/unlock eligibility. **Innervate:** Source accepted one at 25% Mana with Cooldowns ON, zero at Cooldowns OFF. Actual source Mana regeneration is modelled, not confirmed true live-client observable health/Mana. With ON the accepted Current sequence can place Innervate and Insect Swarm before Moonkin Form: no proven optimal cast order from this fixture.

**Entire APL and fallback:** At 5% Mana and Cooldowns OFF, Current still genuinely accepted **11 Wraths per seed** and **12/13 offensive actions overall**, with zero refused actions and zero Starfires in the extreme-starvation worlds. Its Moonfire and Insect Swarm accepted counts varied by seed; source regen/Omen drive timing. Directly observed subsequent offensive actions after first DoT: Current **13/15** at full-Mana, **12/12** at 25%-Mana, **0/5** at 5%-Mana (first starved run's DoTs were late, not source proof of stalling). W.press event chronology omits up to two source-accepted actions versus authoritative rr.pressedBy; never claim complete order. Full final_fallback list imported; individual every-branch reachability in all levels was **not** separately proved.

**Compared with shipped:** Both profiles accepted without refusals. Current 25/25 vs shipped 27/25 at full Mana, 17/17 parity at 25%, 13/12 parity at 5%, and mixed with unshifted/cooldowns ON. Cast counts and DoT opener ordering (Current Insect Swarm before Moonfire, shipped reversed) do **not** establish comparative DPS, damage, uptime, time-to-kill or safety. No source-based Candidate promotion.

## Evidence grades and remaining work

**Confirmed (source-native bounded):** L60 shift/no repeat, true-World accepted Mana/cost and fallback filler, optional cooldown OFF, innate Innervate ON, zero source refused in ten tests. **Unverified in game:** levels 1–59 (Moonkin talent unlock/form restrictions), actual spell range/movement/facing, level-appropriate gearing, real Mana/buffs/potions, boss conditions and threat, multiple targets/AoE Hurricane, authentic Eclipse/Clearcasting and DoT auras, items/cooldown safety, DPS/HP. No in-game proof, and source harness damage/proc is not a reliable DPS oracle.

**Final Fallback / Repeated Recommendation:** The fully imported Current under source 5%-Mana with CD OFF accepted Wrath repeatedly (11/seed) without refused casts, not a repeated inappropriate fallback. Completely empty Mana, uncertain resources, movement and earlier ranks remain untested. Next real Saturday test: live /hek snap after DoTs when Mana is 5–25%, check multiple successive suggestions and real Moonkin/form/cooldown state. Catalogue role remains Draft, preferred null, 0 Approved.

**Next independent tests:** Low-level Moonkin talent/kit boundary, 0-Mana no-action tail, actual range in the client, Eclipse DoT ordering, target count/AoE, and in-game health/Mana. Evaluate custom independent alternative priorities only once a material positive hypothesis and bounded evidence justify a protected Draft Candidate.
