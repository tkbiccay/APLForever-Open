# Breadth #20–21: Shadow full channel ticks; Affliction DoT and low-Mana truth

**23 November 2026 — source-native only, NOT In-Game Validated / Approved.** Hekili Forever stable v0.11.0, exact published source zmsl/hekili SHA **86b739cbc4e6afbcbc693c3790ee81197fc6234b**. [Draft PR #104](https://github.com/tkbiccay/APLForever-Open/pull/104). [Initial 12/12 source PASS 45286524867](https://github.com/tkbiccay/APLForever-Open/actions/runs/45286524867); [strengthened 12/12 source PASS 45286886122](https://github.com/tkbiccay/APLForever-Open/actions/runs/45286886122). [First syntax-only RED 45286353275](https://github.com/tkbiccay/APLForever-Open/actions/runs/45286353275): Lua variable declaration in new test, **before any source combat**; fixed test only. All original APLs unchanged.

## Full pinned comparators, mechanics, methodology

**24 distinct complete source-combat runs:** 2 seeds (30417/30437) × true initial 100%/25%/5% Mana × 2 whole profiles (shipped released WoWSims reference and byte-exact protected Current) × 2 supported roles. Runtime 90/105/115 seconds; Shadow 20yd and Affliction 25yd, one high-health target, natural source Mana regeneration, released level60 talents/gear. Native Major/Minor/Defensive/Interrupt/Movement toggles OFF. All original precombat/default/upkeep/final-fallback lists imported/active, no parser/runtime unknown-action errors. Shipped default is benchmark, **not an architectural constraint**. All actual press/refused reasons, source Mana and casts, player channel start/stop and three actual spell ticks, live target aura events, periodic shadow damage ticks, and Shadow Trance proc auras inspected from published World.truth. No source magic gains, health reads or created APL candidate.

- Priest Shadow Current v1.0: roles/Priest/Current/APL_Priest_Shadow_v1.0_Draft.txt, exact SHA256 **66ee308453ae07c1e2c77b5f82e414e61abbd5f2099d21a252448174be7eec79**.
- Warlock Affliction Current v1.0: roles/Warlock/Current/APL_Warlock_Affliction_DPS_v1.0_Draft.txt, exact SHA256 **65c664533b6918db6e0b1b4bd2c1e360edf56c2bcd647511c63dbd3cd4437c6d**.
- Both roles remain Draft, **preferred_apl=null and last_working_apl=null**. No new APL, hash, rollback, selection or Approved state claimed.

## #20 Priest Shadow — true Mind Flay 3-tick channel completion, not just accepted icons

Different from older [PR #80](https://github.com/tkbiccay/APLForever-Open/pull/80) accepted-channel count: source World includes a Mind Flay channel start, three seconds of spell hit/tick events (one/sec), and channelStop. The suite distinguishes a genuine **early in-combat interrupt** from a W.endCasts **stop at simulated run termination**; a last partly channelled Mind Flay at test end is NOT a player clip. Results below occurred identically for both seeds, and are **per seed**, not combined.

| Initial true Mana | Shipped accepted / full channels / raw refused | Current accepted / channel starts / completed three-tick channels | Current actual source Mind Flay tick spell events | Current real combat clips / simulation shutdown stops | Current true SWP+DP aura events / substantive refusals |
| --- | --- | --- | --- | --- | --- |
| 100% | 42 / 18 / 3 boundary-only | **41 / 21 / 20** | **60** | **0 / 1** | 8 / **0** |
| 25% | 35 / 27 / 1 boundary-only | **35 / 28 / 27** | **83** (81 from 27 complete + 2 end-truncated) | **0 / 1** | 2 / **0** |
| **5%** | 34 / 32 / 0 | **34 / 33 / 32** | **98** (96 complete + 2 end-truncated) | **0 / 1** | **0** / **0** |

All twenty, twenty-seven and thirty-two complete channels delivered **exactly three actual spell hit events**, not just suggestion/acceptance. At full and quarter Mana, whole Current applied real source-target Shadow Word: Pain and Devouring Plague auras and accepted **32** later non-DoT actions. At 5% Mana, Current and shipped each had 34 accepted, 32 complete channels and **no applied DoT auras**: a legal/channel-stable fallback but an unresolved damage/DoT-uptime limit, **not default or custom victory**. No real in-combat channel clipping was observed. The 3/1 raw shipped Mind Blast refused casts are **floating-point end-of-cast overlaps only**, from 3.55e-15 to 1.42e-14 seconds. Original Current has zero raw refused in all six Shadow worlds. Source fixture does not enforce actual 60yd priest range (previous documented limitation), player movement, UI queue latency, 1–59 ranks or actual DPS.

**Classification:** Confirmed source-native three-tick full-channel progression and non-clip under sampled worlds; zero-DOT extreme Mana state; no in-game proof, no player-health/DPS oracle.

## #21 Warlock Affliction — actual periodic damage, procs, resource tradeoff

Different from older [PR #81](https://github.com/tkbiccay/APLForever-Open/pull/81) accepted DoT/three-follow-on test: the published source Warlock World actually applies target **Corruption, Bane of Agony and Siphon Life aura** and emits periodic **kind=tick** shadow damage effects. Extra Wrack half-grid ticks can occur while it channels; **counts are not directly comparable damage per GCD or DPS**. Source Nightfall may grant Shadow Trance proc auras, counted independently. Below each value is per seed.

| Initial true Mana | Seed | Shipped accepted / Life Taps | Current accepted / Life Taps | Current true Corruption/Bane/Siphon aura applications | Current actual shadow periodic ticks | Current Searing Pain / Shadow Trance proc auras | Current substantive refused |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 100% | 30417 | 33 / 4 | **24 / 0** | 4/3/2 | **177** | 2 / 5 | **0** |
| 100% | 30437 | 30 / 3 | **24 / 0** | 4/3/3 | **184** | 2 / 3 | **0** |
| 25% | 30417 | 39 / 10 | **17 / 0** | 1/1/0 | **18** | **14 / 2** | **0** |
| 25% | 30437 | 37 / 9 | **17 / 0** | 1/1/0 | **18** | **14 / 0** | **0** |
| **5%** | 30417 | 45 / 13 | **16 / 0** | **0/1/0** | **12** | **15 / 0** | **0** |
| **5%** | 30437 | 42 / 12 | **16 / 0** | **0/1/0** | **12** | **15 / 0** | **0** |

At 100% Mana, Current maintained real target DoT auras, produced 177–184 actual periodic shadow ticks and procced source Shadow Trance. At 25% Mana, it applied Corruption/Bane only once (no Siphon) then continued with **14 legal Searing Pains**, 18 source periodic damage events, no true rejects. At 5% it applied **zero Corruptions**, one Bane, 12 source periodic ticks, **15 legal Searing Pains**, and zero Shadow Trance events in both seeds. Published highest Corruption cost is **340 Mana**; 5% of Affliction source 6311 Mana is **315.55**, consistent with insufficient initial true Mana for Corruption, but exact downstream Belief decision/path is **not fully established**.

**Raw refusals kept:** Current seed30417 at full Mana had one **casting** refusal overlapping the Shadow Bolt cast end by 1.421e-14 seconds; classified as **epsilon-only, not a substantive refusal**. Shipped also has single epsilon boundaries in selected full/25% worlds. All Current Affliction worlds have **zero substantive costs/eligibility refused** and **zero automatic Life Taps**, including the 5% worlds. We do not hide the raw one in the report.

**Safety-critical comparator limitation:** Shipped at 5% used **12–13 Life Taps**, so it made more accepted actions and DoT ticks. The published Warlock source has a Life Tap Mana gain **but DOES NOT MODEL ITS REAL PLAYER HEALTH DEBIT**. That means shipped's counts cannot prove safety, superior damage, or permission to add unguarded Life Tap to the standalone APL. This is a true resource conversion/DoT-uptime tradeoff, **not a simple optimisation win**. The current APL keeps its health-safe omission.

## Final fallback, errors, lessons, decisions

**Final Fallback / Repeated Recommendation:** Shadow's full fallback at 5% produced 32 complete legal Mind Flay channels with **0 actual source refusals** but lacked DoT coverage. Affliction at 5% still legally accepted **15 Searing Pains** with **no real refused actions** and true Bane ticks, but also missed Corruption/Siphon. Unlike DEMO-006's reported repeated health-costing Life Tap, there is NO automatic Life Tap or refused filler here; legal repeat is not a castability failure, and not necessarily optimal damage. Study low-Mana uptime and held-vs-ready before any candidate. None of these source-world results proves every later fight/no-Mana ending, live icon flicker, pet state, multiple targets, boss raid performance, rank1–59, client channel latency or actual health/DPS.

**Cross-spec transfer:** (a) Do not treat an end-of-test W.endCasts channelStop as real clipped rotation; require true timestamp vs simulated endpoint and actual three ticks. (b) A legal resource-starved filler can conceal major DoT/uptime gaps. (c) Never infer health safety from the released source's Life Tap gain alone. Grade Source Confirmed for observed effects, Experimental for output/survival hypotheses, Engine Limitation for real HP and unmodelled range.

**Next Saturday safe client checks:** Shadow full three Mind Flay ticks with normal movement/range, DoT uptime at naturally low Mana, three later legal spells; Warlock natural post-DoT low Mana Searing Pain follow-ons, real Corruption/Bane timers, manual Life Tap only if user independently judges HP safe (do not deliberately threaten health). Use /hek snap where recommendation conflicts with observed castability. Full future APL architecture and relative reserve hypotheses require source-supported guards and numerical DPS/survival evidence before selection.

**Campaign:** #20 and #21 are separate original source-evidenced breadth units **only after exact final-head CI green and protected-main merge** of PR #104 plus postmerge integrity. Baseline confirmed main stays **19/50** until then; 52 preserved APL revisions, 0 Approved. No AP promotion, new APL or rollback displacement in this PR.
