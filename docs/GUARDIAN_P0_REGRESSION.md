# Guardian P0 source regression tests

The scenario branch builds on [Draft PR #33]([private historical reference; not publicly accessible]). Its baseline verified 27 catalogue hashes and passed native import, active-list checks and the three combat press gate for all 25 selected revisions. [Baseline native CI]([private historical reference; not publicly accessible])

## Reproduce

Use the Ubuntu native preflight workflow. It checks out Hekili Forever at `246abf322ed53e3b7ab796ea7089c72329f3eb9d`, generates the checked manifest with `python scripts/build_native_manifest.py --output "$RUNNER_TEMP/aplforever-native-manifest.lua"`, and runs upstream `make bootstrap`. With `APLFOREVER_ROOT` and `APLFOREVER_NATIVE_MANIFEST` set and the two native specs copied to upstream `tests/Forever`, run `.lua/bin/busted --verbose tests/Forever/aplforever_import_spec.lua tests/Forever/aplforever_progress_spec.lua`.

The comparison uses the source level-60 Guardian fixture in bear form, Primal Fury 2/2, its 88–120 damage weapon with a 2.5-second swing, seed 30417 and a 25-second window. Each run boots its own instance. The upstream benchmark keeps the shipped pack. Imported inputs are v1.0 Reported Working (`f386e158a5e262e309dac7d0fd2929fb8e16e02b1378d71b5956c1bf6b99a786`) and v1.1 Draft (`9be531a5ce56893b1afc508b9181d966637a2713134c340eb391d127d7fff94f`).

`GUARDIAN_P0` logs first-icon output and the subsequent world state, including accepted actions and refusals. The three consecutive polls beginning at world time 8 are an opener observation. Time alone does not establish that every upkeep condition is exhausted. `GUARDIAN_MAUL` isolates the registered ability and the pinned world press/swing path from APL selection.

## Coverage boundaries

- APL selection of Maul through swing consumption and Clearcasting at enqueue and impact remain **Not Run** as regression gates. The seeded Roar exploratory runs below did not produce a custom Maul queue.
- The forced final fallback matrix, including higher-priority actions deliberately on cooldown and exactly enough Rage at the decision, remains **Not Run**. Exact Rage in the Maul component test is a press-level input.
- In-game evidence remains **Not Run**.

## Simulated results

[Native CI 43650189461]([private historical reference; not publicly accessible]) completed at `de1d5d0` with 37 successes, zero failures and zero errors. [Repository CI 43650189460]([private historical reference; not publicly accessible]) ran the unit and integrity checks. The native log includes the exact inputs listed above and the observed aura snapshots and accepted actions.

| Pack and setting | Roar evidence | First icon at 8.0, 8.2, 8.4 seconds | Wait in seconds | World Rage after each poll |
|---|---|---|---|---|
| v1.0 OFF | Historical behavior. One combat Roar, 24 published mitigation slots | Primal Bite ×3 | 0.66, 0.46, 0.26 | 12.5, 12.5, 12.5 |
| v1.0 ON | One combat Roar, 24 published mitigation slots | Primal Bite ×3 | 0.66, 0.46, 0.26 | 12.5, 12.5, 12.5 |
| v1.1 OFF | **PASS**. Zero mitigation Roar slots. Three Primal Bites and four Lacerates accepted | Lacerate ×3 | 3.16, 2.96, 2.76 | 2.5, 2.5, 2.5 |
| v1.1 ON | **PASS**. One combat Roar, 24 published mitigation slots | Primal Bite ×3 | 0.66, 0.46, 0.26 | 12.5, 12.5, 12.5 |
| Upstream OFF | Benchmark. One Roar across the entire run, including precombat. Its lists are distinct | Lacerate ×3 | 0, 1.3, 1.1 | 18.75, 20.75, 20.75 |

The driver accepted the upstream Lacerate at 8.0. It attempted none of the other actions shown at these three polls because their published waits were above the driver's readiness threshold. All five comparison runs recorded zero world refusals. The ON custom runs observed the active Roar debuff after a successful cast.

| Maul world case | Queue result | Swing result | Classification |
|---|---|---|---|
| 14 Rage | Refused with `cost`, no queue or resource change | No queued strike | PASS |
| 15 Rage | Accepted with all 15 Rage still available | Queue cleared, Maul landed, strike cost 15 | PASS |
| 35 Rage | Accepted with all 35 Rage still available | Queue cleared, Maul landed, strike cost 15 | PASS |

The Maul table verifies the source world mechanics. The three-poll samples demonstrate observed resource waiting and accepted actions under this encounter. The full final fallback gate remains Not Run. The next Guardian experiment should drive a custom APL into an actual Maul queue and record three decisions across the swing, including the registered Clearcasting aura.

## Seeded Roar and excess world Rage

[Native CI 43690216780]([private historical reference; not publicly accessible]) at `f3af0b1` passed 41 checks and verified 27 APL hashes. The matching [repository checks]([private historical reference; not publicly accessible]) cover the unit suite and integrity validator.

The independent custom comparison used the same character, seed and duration as above, with 100 starting world Rage, major cooldowns off and the source-registered Roar aura applied through the world API. Both revisions saw the aura for all 125 sampled combat polls. Under both Defensives settings, each cast eight Lacerates and two Primal Bites, with no Roar press and no world refusal. v1.1 OFF had zero mitigation Roar slots. v1.1 ON and both v1.0 settings had later-slot forecasts. The first occurred at world time 18.4 in slot 3, with exact engine time 1065.2 and current engine time 1053.4. That forecasts world time 30.2, the seeded aura's expiry. v1.1 therefore **passed** the first-icon and no-redundant-press gate in both settings. The v1.0 result describes its historical settings behavior only. The untouched upstream run above did not use this new aura seed.

Neither imported revision queued Maul in the seeded run. In v1.1 OFF at pull, world Rage was 85 and estimated Rage was 20. At 6.0, world Rage was 71.25 and estimated Rage was 31.25. Seeding world Rage alone did not establish the APL's `rage.lo` guard, and the full-level fixture still knew Primal Bite and Lacerate. This is **inconclusive** about Maul reachability. A targeted follow-up should log the actual belief bounds and use a source-defined unlock fixture with Maul known and both builders unavailable if available. Avoid inferring Clearcasting behavior for the custom APL from the isolated world component check.

The forced resource and cooldown fallback matrix and the performance comparison remain **Not Run**. Static inspection finds separate pre-bear, upkeep, damage and Rage dump lists, including a low-kit Maul branch and a reserve-based high-kit branch. The current simulation supports the tested Roar toggle and ordinary damage progression. It provides insufficient evidence to rank threat, mitigation uptime, proc responsiveness, level adaptation or fallback stability.

## Targeted v1.1 Maul reachability

**PASS, simulated.** [Native CI 43691300274]([private historical reference; not publicly accessible]) at `e09a874` passed 42 checks. [Repository CI 43691300283]([private historical reference; not publicly accessible]) passed. Run the native commands above. For a targeted run add `--filter="Guardian imported low-kit Maul"` to the progression spec command.

The test uses the pinned upstream level-10 Guardian fixture from `tests/Forever/wowsims_druid_spec.lua` and its `ws.content` builder, including the upstream talent cut and Lacerate hotfix rank overrides. DB2-derived learn data puts Bear Form 5487 and Maul 6807 at 10, and Primal Bite 407995 at 25. The level-10 Tauren fixture has one point in talent 16934, a 2.5-second weapon and known spell IDs 5487, 6807, 99, 1126, 5232, 467, 20549, 16934. Native knowledge checks confirmed Bear Form and Maul known and both builders unknown. The imported v1.1 SHA-256 is `9be531a5ce56893b1afc508b9181d966637a2713134c340eb391d127d7fff94f`. Seed 30417, 25 seconds, Defensives and Cooldowns OFF. World Rage came from the stock encounter.

| World time | Published first icon | Observed state and outcome |
|---|---|---|
| 3.0 | Maul, wait 5.00 s | Actual Rage 0. Current belief low/estimate/high 0/0/6.24. Published forecast floor 22.5. |
| 5.4 | Maul, wait 0, `rage_dump:1` | Published floor 19 exceeded the resolved cost of 14. The real driver accepted the queue with 22.5 actual Rage before and after. |
| 7.660 | Separate Maul strike | Landed (`WOUND`), charged 14, queue cleared. |
| 7.8 / 8.0 / 8.2 | Maul, waits 2.37 / 2.17 / 1.97 s | Actual Rage 8.5. Current post-poll belief 6.375/8.5/9.99. Published forecast floor 17.25. No premature press. |
| 10.2 / 10.4 | Maul, waits 0.17 / 0 s | Actual Rage 31. The driver accepted another queue at 10.4. |

The log distinguishes the recommendation's forecast floor from the current post-poll belief and the actual Rage sampled immediately around the native press. There were seven accepted Maul presses and zero refusals. Only the first matched strike was asserted. The three consecutive post-strike polls demonstrate a receding forecast through a low-resource interval; the following swing gain and accepted queue demonstrate progression at sufficient Rage. The three polls themselves did not each introduce a cast or world resource change. This covers the natural low-to-sufficient sequence. Exact-cost forced fallback, Clearcasting integration, the high-kit route and in-game validation remain **Not Run**. The low-kit result resolves reachability without changing the APL.

## Released v0.8.5 natural high-kit low-Rage tail — 16 November 2026

**PASS — bounded source-native / no APL promotion.** [PR #63]([private historical reference; not publicly accessible]), [v0.8.5 CI]([private historical reference; not publicly accessible]); pinned source `zmsl/hekili@a0a06583f458cca7a2ceaebb0b2ba0c4c783b946`. Test `tests/native/aplforever_guardian_highkit_tail_v085_spec.lua` uses source-defined level-60 Guardian kit, learn overrides/talents/gear, two attackers, 70 seconds, seed 30417, Defensives/Cooldowns/Movement OFF, and native swing/ability-based Rage. **No fabricated Rage drip, artificial drain, cast success or proc aura.** Exact complete standalone v1.0 ReportedWorking, separate v1.1 Draft and untouched shipped were imported separately. Every profile genuinely cast a builder before source-true Rage fell to <=25, then produced **three distinct incoming-swing checkpoints** with first icon, wait, forecast Rage floor, current belief, actual Rage and successful presses in between.

| Profile | Three observed low-Rage first icons and waits | Raw world refusals / errors | Actual source Maul accepts in 70 s |
| --- | --- | --- | --- |
| Shipped | Lacerate 1.79 s; Primal Bite 0 s (**accepted**); Lacerate 1.10 s | 0 / 0 | 3 |
| v1.0 **Current / ReportedWorking** | Lacerate 0 s (**accepted**); Lacerate 0.70 s; Lacerate 3.76 s | 0 / 0 | 0 |
| v1.1 **Candidates / Draft** | Lacerate 1.96 s; Lacerate 0.76 s; Lacerate 0.50 s; one actual Lacerate accepted between the second and third checkpoints | 0 / 0 | 0 |

These distinct world-state changes were **legitimate waits or accepted presses**, not repeated immediately ready unaffordable actions. The test fails a repeated ready first-icon across all three swings without an accepted corresponding action. The candidate cast **no Demoralising Roar with Defensives OFF**; in this source scenario, shipped and v1.0 each cast three. That matches the candidate's explicit player off-switch; it **does not** demonstrate better threat, mitigation or DPS. Maul remained unqueued in both custom high-kit runs, so **full high-kit Maul reachability, 100-Rage beliefs, exact-cost forced tail and all-level fallback remain unverified**. Do not force an unrealistically visible Rage input to make the recommendation look good.

[CI v0.8.5]([private historical reference; not publicly accessible]) passed **3 focused + 13 Hunter + 4 Warlock + 2 Paladin + 126 native + 116 Hunter/options + 101 Druid + 183 class** checks. Protected [v0.8.2]([private historical reference; not publicly accessible]), [v0.8.3]([private historical reference; not publicly accessible]) and [repository integrity]([private historical reference; not publicly accessible]) passed, all 28 APL SHA-256 values unchanged.

**Decision:** retain exact `roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt` as working-reported Current / NeedsRetest and `roles/Druid/Candidates/APL_Druid_Guardian_v1.1_Draft.txt` as unpromoted Candidate. Bounded level-60 low-Rage safety evidence gained, no measured damage/survival superiority. **Not Run:** actual level-1–60 unlock coverage, real Rage client belief at high resources, in-game queued Maul/roar/Defensives toggles, target swaps, CDM, serious tank incoming damage or approved live import. Reuse the existing game-wide [cross-APL fallback method](knowledge/lessons/CROSS_APL_TRANSFER.md), not a separate new algorithm; stop this same test on unchanged source.

## 17 November 2026 — high-kit Maul reachability and queue-to-strike diagnostic

**Result: source-native PASS, no production APL change.** [Merged PR #67]([private historical reference; not publicly accessible]) used released Hekili Forever v0.8.5 (source a0a06583f458cca7a2ceaebb0b2ba0c4c783b946), level-60 registered Guardian talents/gear, seed 30417, 70 seconds. The original two-attacker comparison was preserved and three-attacker versions added. One extra full standalone v1.1 import was modified only *in memory*, moving the existing Maul/rage_dump list call ahead of damage without changing its conditions. This was an experiment, not a new APL revision.

| Source profile | Mob attackers | Highest actual Rage | Highest belief floor | Full sampled Maul reserve matches | Maul queues / strikes / unqueues | Accepted Lacerate / Primal Bite |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| Shipped | 2 | 40.5 | 30.375 | n/a, different guard | 3 / 2 / 1 | 17 / 9 |
| v1.0 Reported Working Current | 2 | 35.25 | 26.375 | 0 | 0 / 0 / 0 | 12 / 7 |
| v1.1 Draft Candidate | 2 | 54.9 | 52.15 | **2** | 0 / 0 / 0 | **22 / 9** |
| Shipped | 3 | 31 | 20 | n/a | 0 / 0 / 0 | 11 / 6 |
| v1.0 Current | 3 | 31.25 | 25.81 | 0 | 0 / 0 / 0 | 7 / 5 |
| v1.1 Draft Candidate | 3 | 39.5 | 28.125 | 0 | 0 / 0 / 0 | 6 / 6 |
| **v1.1 test-only reordered** | 2 | 54.9 | 52.15 | **1** | **1 / 1 / 0**, cost **13 Rage paid** | **14 / 8** |

**Finding:** Original v1.1 reached two source-sampled complete Maul reserve-guard opportunities (t=21.8 and 22.0, Rage floor 52.15; source costs Maul 13, Primal Bite 18, Lacerate 15, Swipe 18, target count 1) but showed Lacerate rather than queuing Maul. The test-only list reordering produced a genuine accepted Maul queue, later natural strike and 13 Rage spent. Every world reported zero source-world refused casts and engine errors. A queued press alone is not a paid strike: shipped accepted three queues but executed only two strikes and unqueued one.

**Do not assume superiority:** Compared with unmodified v1.1, the reordered experiment also changed accepted Lacerates 22→14 and Primal Bites 9→8. Swing replacement, resource trajectory and source RNG can change the rest of the encounter. The source-world damage, tank mitigation and threat model is unmeasured; this is *not* evidence of improved tank DPS, survival or threat. Three attackers did not create a corresponding believed Rage reserve. The belief and post-press world truth are not identical-timing observables. No full level-1–60, high-Rage in-game CDM/defensive, target-swap or complete repeated-final-fallback proof is claimed.

**CI:** [v0.8.5 44039011637]([private historical reference; not publicly accessible]) passed seven focused Guardian cases plus existing suites; [v0.8.3 44039011682]([private historical reference; not publicly accessible]), [protected v0.8.2 44039011624]([private historical reference; not publicly accessible]) and [repository validation 44039011663]([private historical reference; not publicly accessible]) all passed. All **29 APL SHA-256 references and rollback selections unchanged**.

**Decision:** STOP treating a single extra Maul as a validated gain. Protect exact v1.0 Reported Working / Needs Retest Current and v1.1 Draft Candidate. **No v1.2**. Further priority work requires meaningful source-grounded threat/survival comparison or narrow real-game evidence, not source-world fake damage. Reuse the verified queue → natural swing → actual cost/unqueue test method on registered Warrior next-swing actions only if a new role-specific decision warrants it; not shared runtime code.


## 17 November 2026 — Guardian unlock and state-advanced repeated-fallback matrix

**PASS — 15 new source-native progression cases, no APL revision.** [Merged PR #68]([private historical reference; not publicly accessible]), released Hekili Forever **v0.8.5** pin `a0a06583f458cca7a2ceaebb0b2ba0c4c783b946`; source `tests/Forever/wowsims/learn_druid.lua`, hotfix-aware `tests/Forever/wowsims_druid_spec.lua`, and source Guardian `Druid.lua`. Three separately imported **untouched shipped**, **exact v1.0 ReportedWorking Current**, **exact v1.1 Draft Candidate** at levels **24, 25, 29, 30, 34**; seed **30417**, two naturally attacking enemies, **42 seconds** per world, original source talent cut/ranks/gear, Defensives/Cooldowns/Movement OFF. All seven previous high-kit Maul tests remain active.

| Guardian level | Source kit/real accepted action findings (shipped / v1.0 / v1.1) |
| --- | --- |
| **24** | Bear/Maul and Faerie Fire known, Primal Bite and Lacerate unknown; actual **Maul 9 / 9 / 12**; neither locked action cast |
| **25** | Primal Bite becomes known and genuinely accepts **7 / 7 / 7** casts; Lacerate still unknown |
| **29** | Primal Bite **7 / 7 / 7**; Lacerate still unknown in this source talent allocation |
| **30** | **Lacerate first-rank Feral talent (1328617)** acquired by the pinned build's 21st Feral point; **10 / 8 / 8** accepted Lacerates; trained rank 2 still unavailable |
| **34** | Trained Lacerate rank 2 (1328616) becomes known; **10 / 9 / 11** accepted Lacerates |

**Non-vacuous safety gates:** in every one of the 15 worlds, **41–42 distinct real incoming-swing timestamps**, **11–20 accepted player casts**, **zero source-world refused casts**, **zero source engine errors/raises**, **zero three-swing immediately-ready first-icon repetitions without an intervening accepted cast**. The test permits positive forecast waits and No Action when justified. It checks knowledge before recommending those tracked actions and that locked Primal Bite/Lacerate are not actually pressed. This is a source-native 5-bracket castability/repeated-fallback check, **not** a universal repeated-final-tick proof or claim of complete 1–60 coverage.

**Failed-first root cause (test expectation, not APL):** initial [CI 44046831030]([private historical reference; not publicly accessible]) saw 3 failures across shipped/v1.0/v1.1 **only** because the test incorrectly asserted *all* Lacerate unavailable at level 33. Released Druid source registers first rank as a **talent** (id 1328617), while level-34 rank 2 is id 1328616; the pinned WoWSims Guardian talents take the first-rank point at **level 30**. Corrected test uses the actual imported build's talent IDs plus trained spell IDs, and adds a strict **level 29/30** boundary rather than preserving the false level-33 assumption. **Do not generalise level 30 to every possible player talent order**; inspect each actual build.

**Final green:** [v0.8.5 CI 44047233998]([private historical reference; not publicly accessible]) **22 focused Guardian** (7 earlier + 15 new), and all existing 13 Hunter, 4 Warlock, 2 Paladin, 6 Feral, 126 native, 116 Hunter/options, 101 Druid and 183 other class checks passed; protected [v0.8.2 44047233967]([private historical reference; not publicly accessible]), [v0.8.3 44047233959]([private historical reference; not publicly accessible]) and [repository integrity 44047234018]([private historical reference; not publicly accessible]) all passed. **29 immutable APL SHA-256**, preferred/working and rollback selection unchanged.

**Decision:** exact Guardian v1.0 remains **Reported Working / Needs Retest**, v1.1 remains **Draft Candidate**; no new APL, no performance ranking and no approval. Follow up on **actual caster-form level 1–9** with a verified Mana and Wrath/Moonfire source fixture before asserting those levels, plus different talent allocations, Rage at exact cost with cooldowns unavailable, live Roar/defensive control, swaps/AoE and full repeated-final chain. Current Guardian source world starts in Bear with Rage: **never pass it off as a low-level caster world**. [Cross-role method UNLOCK-008](knowledge/lessons/CROSS_APL_TRANSFER.md) reuses talent-plus-trained-rank verification, not shared runtime code.

## 17 November 2026 — pre-Bear caster source-Mana 1–9

**PASS — bounded 15-world source-native castability, NOT realistic level-1–9 Mana endurance.** Merged [PR #69]([private historical reference; not publicly accessible]), released Hekili Forever **v0.8.5**, source **a0a06583f458cca7a2ceaebb0b2ba0c4c783b946**. Source Druid learn table verifies Wrath at 1, Moonfire at 4, Thorns at 6, Bear Form at 10. Test levels **1, 3, 4, 6, 9**, 30 seconds, seed 30417, one naturally attacking enemy, exact standalone shipped, v1.0 Reported Working Current and v1.1 Draft Candidate independently imported, Defensives/Cooldowns/Movement OFF.

**Fixture mechanism and caveat:** The previous Guardian source world begins in Bear and its resolver captures **Rage**. Editing its character power to Mana alone would silently make Wrath/Moonfire free (its resolver ignores foreign Mana costs). This experiment uses the **same released Druid class code**, but reuses the source Balance caster world's **Mana-primary resolver, real spell costs/cast/GCD/auras, and five-second-rule model**, while importing the original **Guardian PACK/spec APL** and limiting known spells to released source IDs relevant to pre-Bear casts. Caster form is 0 and Bear/Maul remain unavailable. **The borrowed source world has a 4,000-Mana level-60 pool and Spirit, not level-specific Mana, stats or regen.** It establishes native castability and positive Mana-price events, not low-level OOM timing, cast endurance or comparable DPS.

| Level | Shipped default — accepted combat casts | Current v1.0 — accepted casts | Candidate v1.1 — accepted casts |
| --- | --- | --- | --- |
| **1, 3** | **0** in each world | each: 20 Wraths + 1 Mark of the Wild | same as Current |
| **4** | **0** | 16 Wraths + 4 Moonfires + 1 Mark | same as Current |
| **6, 9** | **0** in each world | each: 13 Wraths + 4 Moonfires + 1 Thorns + 1 Mark | same as Current |

All **15 scenarios** progressed through **14–15 real incoming-swing timestamps**, **zero refused casts, zero engine errors/raises and zero repeated immediately-ready unpressed first icons over three state-advanced swings**. Custom profiles had positive source-event Mana costs (**18–20 paid-spell events each**), not a Rage-closure fake-free-spell artifact. Source regeneration frequently restored the large Mana pool to full; do not infer resource endurance from final Mana. The shipped default produced **no combat action at any sampled pre-Bear level** in this fixture because its priority is Bear-first and has no low-level caster fallback; record as a **bounded shipped coverage gap**, not proof of a real-game addon failure. The two complete custom APLs supplied independently importable pre-Bear fallback without new changes.

**Final CI:** [v0.8.5 44062406318]([private historical reference; not publicly accessible]) **37 focused Guardian** (22 prior + 15 new), all existing native/class/importer suites green. [v0.8.3 44062406355]([private historical reference; not publicly accessible]), [v0.8.2 44062406264]([private historical reference; not publicly accessible]) and [repository 44062406406]([private historical reference; not publicly accessible]) passed. All **29 APL SHA-256**, preference, reported-working rollback and statuses unchanged; no candidate promotion.

**Decision / next evidence:** This closes *caster-form action availability and positive-cost cast progression* for sampled 1–9 levels only. **Not Run:** calibrated level-specific Mana/regen and OOM tail, realistic low-level equipment, unmodelled other Druid abilities, exact-cost tail with competing cooldowns, alternate talents and full 1–60/repeat-chain coverage, real-player /hek snap and defensives/CDM. Reuse [FORM-009](knowledge/lessons/CROSS_APL_TRANSFER.md): compare entire resource closures, not just character.power when validating cross-form roles. Retain v1.0 Current **Reported Working / Needs Retest**; v1.1 **Draft Candidate**; neither approved.

## 17 November 2026 — controlled exact-Rage cost stress — red source-native

**FAIL / not merged / not proven in game.** [Closed PR #70]([private historical reference; not publicly accessible]) tested source-native Guardian on published Hekili Forever **v0.8.5**, exact pinned commit a0a06583f458cca7a2ceaebb0b2ba0c4c783b946. Two natural incoming attackers, seed **30417**, 27 seconds. All three independently imported profiles (untouched shipped default, v1.0 ReportedWorking Current and v1.1 Draft Candidate) were compared at level **10** and **30**. The test consistently gave the actual source world and initial character the same **controlled warm-start Rage** at the registered ability cost **minus 1, exactly, or plus 1**. Source costs and form/talent rank came from the registered class (level-10 Maul 14 Rage; level-30 Lacerate 15 Rage), no fake combat Rage, casts, cooldowns, extra resource observability or hidden API data. Defensives/Cooldowns/Movement and legacy maintenance Roar setting OFF.

**18/18 normal hidden-Rage safety cases FAILED** ([initial CI 44077079161]([private historical reference; not publicly accessible]); [diagnostic CI 44077743562]([private historical reference; not publicly accessible])). At level 10, starting just **below 14 Rage** produced no accepted attacks while true Rage later reached **98.75**, because the belief floor remained at 13. Starting at **14 or 15 Rage** queued and completed **five genuine Maul strikes** costing **70 Rage** each profile, yet the hidden-resource belief floor remained at its starting value even after true Rage became zero. The native driver then saw **68–74 insufficient-Rage refusals** and **7–8 three-swing repeated-ready first-icon failures** across profiles. At level 30 with 15/16 starting Rage, the two custom profiles each produced **92 cost refusals and eight repeated-ready checkpoints** after real Faerie Fire upkeep and some accepted Lacerates; shipped also had refusals. These are source-world safety FAILS, not evidence of superior damage or a live-client defect.

**Decisive test-only positive control:** Four otherwise matched cases switched the native observer to explicitly show real Rage on every world event (source option plainPower[RAGE] = always): shipped/v1.0/v1.1 level-10 exact and v1.1 level-30 exact. **4/4 PASS, zero source cost refusals and zero repeated-ready checkpoints**; source Maul still queued, swung and paid. This deliberately unrealistic oracle is **not a Forever player API or proposed addon setting**. It isolates the controlled failure to hidden Rage versus estimated resource visibility rather than to an APL-specific ordering fault. The released expression reference supports rage.lo and action.<key>.ready, but the latter still uses estimated-resource readiness; no verified standalone APL condition reading actual hidden Rage was established.

**Status: Source-Native Reproduced / Suspected Engine–Observer Belief Limitation / Live Unverified.** Original **37** natural-resource Guardian cases stayed green. Final v0.8.5 diagnostic CI **41 passes / 18 fails** (37 existing + four truth-visible controls vs 18 hidden tests); [protected v0.8.2]([private historical reference; not publicly accessible]), [v0.8.3]([private historical reference; not publicly accessible]), and [repository integrity]([private historical reference; not publicly accessible]) passed. **PR #70 was closed unmerged**: do not delete or weaken safety assertions to make CI green. The PR keeps the negative diagnostic and oracle control for a future supported engine fix.

**Rollback / next proof:** 29 APL revisions and all selected preferences/checkpoints untouched. Exact Guardian v1.0 **Reported Working / Needs Retest** remains the working-report rollback; v1.1 separate **Draft**; neither Approved. Keep [Issue #30]([private historical reference; not publicly accessible]) OPEN. To confirm any real-world problem, capture a genuine **/hek snap** after a paid Maul swing with actual Rage low and note the next three state-advanced recommendations, real player action and refusal; avoid speculative model work before that. Reuse cross-role [OBS-010](knowledge/lessons/CROSS_APL_TRANSFER.md) for diagnosis only. With Guardian's exact-cost **not cleared** and a new live observation needed, move headless optimisation to **priority #2 Feral DPS**.

## 18 November 2026 — source-registered Barkskin draft coverage (NO production approval)

[PR #89]([private historical reference; not publicly accessible]) adds a v1.2 **standalone Draft Candidate**, without replacing v1.0 Reported Working Current. The previous full v1.1 Draft moves byte-identically to Archive. At pinned released v0.8.6, a narrowly source-backed test-only Barkskin world (real ID 22812, level44, 60s CD, 15s aura, Defensives toggle) passes the original 10-world gate: one actual Barkskin accept/aura ON, no OFF or level43, Roar maintained. Player HP and mitigation damage remain unmodelled and ON reduced other accepted action counts 16→14 in the short case; **not a proven survivability/throughput win**. Latest exact-file v1.2 parity and CI must pass before using this as a validated source-native candidate. Full details in [Research v1.2](Research_Druid_Guardian_v1.2.md) and [Tests v1.2](Tests_Druid_Guardian_v1.2.md). Prior negative Rage/Maul and failed artificial warm-start evidence remains preserved.
