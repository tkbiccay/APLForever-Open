# Mage Frost — published v0.11.0 Frostfire kit boundary and full final-fallback evidence

**Date:** 23 November 2026. **Role:** Mage Frost DPS, Supported / Draft. **Exact release:** Hekili Forever v0.11.0, source SHA 86b739cbc4e6afbcbc693c3790ee81197fc6234b. **Native:** [PR #95](https://github.com/tkbiccay/APLForever-Open/pull/95), [7/7 PASS run 45254820633](https://github.com/tkbiccay/APLForever-Open/actions/runs/45254820633), [repository validator 45254820295](https://github.com/tkbiccay/APLForever-Open/actions/runs/45254820295). Complete upstream shipped Frost vs **exact immutable** roles/Mage/Current/APL_Mage_Frost_v1.0_Draft.txt. No selected preferred/last-working or Approved APL. Two matched seeds 30417/30437 × 100%/25%/5% starting Mana, 25yd, 75/100/100-second fixtures, 12 complete runs, plus a source-pack knowledge test. Native Major/Minor/Defensives OFF.

| Seed | Starting Mana | Shipped accepted / refused | Current accepted / refused | Current directly observed later offence |
| --- | --- | --- | --- | --- |
| 30417 | 6348 (100%) | 31 / 0 | **32 / 0** | **29** |
| 30437 | 6348 (100%) | 31 / 0 | **32 / 0** | **29** |
| 30417 | 1587 (25%) | 25 / 0 | **16 / 0** | **13** |
| 30437 | 1587 (25%) | 26 / 0 | **16 / 0** | **13** |
| 30417 | 317.4 (5%) | 23 / 0 | **12 / 0** | **10** |
| 30437 | 317.4 (5%) | 22 / 0 | **11 / 0** | **9** |

**Frostfire is a separate published source pack, not proof of Frost talent availability.** The published v0.11 mage_world.lua **Frost** level-60 preset does NOT know frostfire_bolt; its **Frostfire** preset (Fire-based spec 100082 rather than Frost spec 100083) DOES. A separate positive/negative loop.new check verified both conditions. Across 12 full Frost profile runs neither shipped nor Current cast Frostfire Bolt. This establishes a source-fixture distinction, not real client talent availability or alternate Frost builds.

**Final fallback / repeated recommendation:** Actual W.press hooks captured genuine accepted actions rather than treating incomplete tick-indexed rr.pressed as exhaustive. Current full Mana: 29 later directly observed offensive actions per seed; 25%: 13; 5%: 10 and 9. **Zero source-refused Current casts**, no Major OFF violations and no unsupported Frostfire casts. rr.pressedBy remains authoritative for accepted spell totals; our W.press hook missed up to two offensive presses per profile relative to that counter, so this is not an exhaustive time trace. At least first plus three accepted attacks is directly evidenced, not proof of no UI flicker or level 1–60 quality.

**Comparator limits:** Shipped accepted 25/26 at 25% and 23/22 at 5%; Current 16/16 and 12/11. These differences **do not establish DPS, survival, efficiency or superiority**: actual damage, proc truth, Mana estimates and encounter fidelity are not measured. No automatic APL revision is justified. Investigate Frostbolt cadence, Fingers of Frost and Ice Lance proc timing, 2+/AoE, movement, cooldowns ON, real range/Mana and lower ranks with independent proof before designing a Candidate.

**Decision:** bounded level-60 Frost source-native 7/7 green, repo validator green. In-game client, damage, defensive effects, alternate specs, movement/latency and Saturday acceptance **not run**. All 48 protected historical APLs and exact hashes, Current, preferred and last-working rollbacks remain unchanged. Zero Approved. Cross-spec lesson: independently verify each pack's known kit before transferring conditions from a sibling talent build. Next underserved independent role: Warlock Destruction, or equal-P0 Guardian/BM as evidence permits.
