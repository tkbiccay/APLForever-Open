# Tests — Rogue Combat v1.1 full standalone Garrote opener

**Date:** 23 Nov 2026. **Evidence:** [initial strict red 45093222644](https://github.com/tkbiccay/APLForever-Open/actions/runs/45093222644); [refusal trace red 45093384553](https://github.com/tkbiccay/APLForever-Open/actions/runs/45093384553); [in-memory A/B 4/4 PASS 45093516898](https://github.com/tkbiccay/APLForever-Open/actions/runs/45093516898); **[full stored Candidate 4/4 PASS 45093860815](https://github.com/tkbiccay/APLForever-Open/actions/runs/45093860815)**. Each uses published Forever v0.11.0 pinned source `86b739cbc4e6afbcbc693c3790ee81197fc6234b`.

| Seed | Starting Energy | Shipped accepted/refused | Protected Current v1.0 accepted/refused | Full new v1.1 Candidate accepted/refused |
| --- | ---: | --- | --- | --- |
| 30417 | 100 | 47 / 0 | 52 / 0 | **52 / 0** |
| 30437 | 100 | 48 / 0 | 51 / 0 | **51 / 0** |
| 30417 | 25 | 55 / 0 | 2 / **501** | **64 / 0** |
| 30437 | 25 | 58 / 0 | 2 / **501** | **63 / 0** |

**Scope:** two matched seeds × full and 25 Energy; **12 full source-native combat-profile executions**, 75s normal/100s low; cooldowns, minor cooldowns and defensives OFF. Each new stored v1.1 import verifies all action lists active, no warnings/load errors, exact APL bytes equal protected v1.0 with **only one Garrote guard** changed; next-three follow-on accepted action assertion and no source refusals. Major OFF verified (Blade Flurry/Adrenaline Rush zero). At low Energy new v1.1 achieved 62/61 actual accepted combat actions respectively, including 61/60 subsequent combats. `sinister_strike` accepted 39/38; `eviscerate` 11/11. All primary first-press completion was observed **in this source world only**.

**Final Fallback / Repeated Recommendation:** original Current blocked on 501 real refused Garrotes at 0.2s cadence; new v1.1 removes repeated refusal and proceeds through the entire reachable fallback chain; safe repeats of legal `sinister_strike` filler are not regressions. The last-cast and 1–60 edge cases outside these two level-60 source fixtures are UNTESTED.

**Known deficits/uncertainty:** source-world rogue Stealth loss timing may differ in client, no real combat footage, true Vanish/Ghostly Strike exception, target switching, 2+/boss Slice and Dice damage choice, poison application, rank/unlock and PvP checks, observed output/DPS/TPS, and abilities at movement/facing limits. No new settings. No production promotion, no in-game proof; retain Current v1.0 and original rollback. Player Saturday test: in a naturally safe fight with intentionally low Energy while stealthed, check first icon → actual ability → three later accepted actions; if Garrote repeatedly cannot cast, capture `/hek snap`. No forced risky pulls.
