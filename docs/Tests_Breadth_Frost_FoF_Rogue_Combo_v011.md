# Tests — Breadth #24–25: Frost Fingers of Frost and Rogue Combat combo-point truth

**24 November 2026. Source-native evidence only — NOT in-game Approved.** Published Hekili Forever stable **v0.11.0**, exact source zmsl/hekili SHA **86b739cbc4e6afbcbc693c3790ee81197fc6234b**, using actual tests/Forever/helpers/mage_world.lua and rogue_world.lua. Public [PR #106](https://github.com/tkbiccay/APLForever-Open/pull/106), [final focused 12/12 native PASS](https://github.com/tkbiccay/APLForever-Open/actions/runs/45355162182). All original full APLs, default, working and catalogue selection/rollback remain untouched. Test source: experiments/native/aplforever_frost_fof_rogue_combo_v011_spec.lua.

## Pins, complete comparators and methodology

**30 whole advancing source World loops**, matched seeds 30417 and 30437, native Cooldowns/Minor/Defensives/Interrupts/Movement OFF. Shipped WoWSims priorities remain a **comparator only**, never constrain custom design. No synthetic proc, Energy, Mana, hidden aura or health, and no substituted Retail/Classic rules.

- **Frost:** 2 seeds × TRUE starting 100/25/**5% Mana** × full shipped Frost and entire protected Frost Current v1.0 = **12** complete 100-second Worlds at 25yd. Exact Current SHA256 **f05a17a34b9d13238d6594e27f4fa7994cf2ce9eae5c4e5916ecc7dc0decbd22**, roles/Mage/Current/APL_Mage_Frost_v1.0_Draft.txt. Source truth: positive/expired two-charge Fingers of Frost auras, actual charge present before accepted Ice Lance, unique target spell-damage amount 300/crit600 at 25yd (published W.hit emits no spell ID), and genuine Winter's Chill auras on target. The actual source supports FoF 15% chance after landed chill, each mage spell spending one stack, and Winter's Chill proc on landed Frostbolt.
- **Combat Rogue:** 2 seeds × TRUE starting 100/25% Energy × full shipped, protected original Current v1.0 and unselected complete Candidate v1.1 at 4yd, 95s = **12 Worlds**. Added 2 seeds × 20s short outdoor solo × all three full APLs = **6 Worlds**. Source truth: native W.res combo-point power type 4 before/after accepted builders and Eviscerate, genuine resource gain/spend events and actual Slice and Dice aura on player, rather than pressed icon alone. Original Current v1.0 SHA256 **ff69f6d4baa3e74d054f8e96595993b5bd931e283e0b7a81cf1dd95a03b13218**, roles/Rogue/Current/APL_Rogue_Combat_v1.0_Draft.txt; full previously saved unselected v1.1 SHA256 **97f4b0a3514fa9c31b0710b97e85e283d78b31d76a69392f5aa0bc0f246748ca**, roles/Rogue/Candidates/APL_Rogue_Combat_v1.1_Draft.txt.
- Frost v1.0 and Rogue v1.1 remain **Draft, preferred_apl=null, last_working_apl=null, not Approved**. No new full APL revision in this research batch.

## #24 Frost: true FoF charge effect and 5% Mana terminal fallback

Previous breadth #07 proved original Frost full release importer and source accepted spells at 100/25/5% Mana. This unit newly audits **actual effects**: landed Frostbolt creates a true FoF two-charge aura; a true FoF charge is present when the APL selects Ice Lance; native Ice Lance hit with source-modelled 300/600 magic-damage outcome and Winter's Chill target aura are observed. The source W.hit spell truth does **not** expose an ability ID, so unique damage value under this 25yd single-target fixture is used for confirming native Ice Lance outcomes, not any real damage claim.

| Seed | TRUE initial Mana | Shipped accepted / true FoF aura grants / Ice Lance | Protected Current accepted / true FoF grants / Winter's Chill target events | Current real FoF-guided Ice Lance / source-modelled landed hits | Refused Current |
|---|---|---|---|---|---|
|30417|100%|41 / 8 / 0|**35 / 11 / 34**|**3 / 3**|**0**|
|30437|100%|41 / 14 / 0|**35 / 10 / 34**|**4 / 4**|**0**|
|30417|25%|25 / 4 / 0|**16 / 6 / 16**|**4 / 4**|**0**|
|30437|25%|26 / 10 / 0|**16 / 6 / 16**|**4 / 4**|**0**|
|30417|**5%**|reference FoF 6|**12 accepted Frostbolts / 0 true FoF / 12 Winter's Chill**|**0 / 0**|**0**|
|30437|**5%**|reference FoF 8|**11 accepted spells incl. 9 Frostbolts / 2 true FoF / 10 Winter's Chill**|**2 / 2**|**0**|

**New positive:** all Current Ice Lances observed at these intervals were selected while **true FoF** charges were present and produced the specific source-native damage effect; shipped source **did not cast any Ice Lance** at full/25% Mana in these matched worlds. Current had fewer total accepted spells than shipped in some cases; raw count is **not DPS** and cannot justify promotion. **Critical severe-Mana test:** the 5% seed with NO FoF correctly repeats *legal, castable Frostbolt* 12 times. A prior diagnostic [45354949081](https://github.com/tkbiccay/APLForever-Open/actions/runs/45354949081) incorrectly required three **different** post-Frostbolt actions, causing RED despite 0 source refused. That error was fixed by checking three actual legal Frostbolt fillers at extreme Mana, while retaining strict zero-refused. Initial stateful [10/10 PASS](https://github.com/tkbiccay/APLForever-Open/actions/runs/45354562609) and final 12/12 PASS are separately preserved. Live Fingers proc, range, latency, movement, target swaps, Frostfire alternate build, actual DPS and ranks 1–59 remain unproven.

## #25 Combat Rogue: true combo spending/retention, low-Energy refused tail and short solo

Earlier Rogue Combat source tests proved an in-combat low-Energy false-Garrote loop and tested one-line guarded complete v1.1. This **independent** unit verifies actual combo points and avoided finisher semantics instead of stopping at raw accepted cast count.

| Seed | TRUE Energy | Protected Current accepted / raw Garrote refused | Unselected v1.1 accepted / raw Garrote refused | Candidate Eviscerates / true landed spends / legitimate avoided retains | Candidate real generated builder points |
|---|---|---|---|---|---|
|30417|100% 95s|62 / **0**|62 / **0**|12 / 10 / 2|28|
|30437|100% 95s|60 / **0**|60 / **0**|14 / 10 / 4|28|
|30417|25% 95s|**2 / 476**|**60 / 0**|10 / 9 / 1|28|
|30437|25% 95s|**2 / 476**|**58 / 1**|9 / 9 / 0|29|
|30417|100% 20s|17 / 0|17 / 0|3 / 2 / 1|7|
|30437|100% 20s|17 / 0|17 / 0|4 / 2 / 2|7|

**Source correctness correction:** released native World explicitly **preserves combo points on an avoided finisher**, spending all only on a landed Eviscerate. A true 3→3 point state with an avoided result is legitimate, not a broken Eviscerate. The first [diagnostic RED 45354090409](https://github.com/tkbiccay/APLForever-Open/actions/runs/45354090409) treated every non-zero post-finisher point as a failure. Refined [10/10 PASS](https://github.com/tkbiccay/APLForever-Open/actions/runs/45354562609) and final [12/12 PASS](https://github.com/tkbiccay/APLForever-Open/actions/runs/45355162182) require EVERY accepted Eviscerate to be **either actually spent on a hit or retained on an observed avoided outcome**; no unexpected combos above 5, no missing later follow-ons.

**Baseline regression remains real and contextual:** at 25% Energy, original Current repeated **476 refused Garrotes per seed**, whereas v1.1 produced 58–60 accepted spells and no mid-combat refusal. At 100% Energy, original Current and candidate have exact parity and zero refused; do not manufacture a full-Energy original fault.

**Residual terminal action refusal NOT WAIVED:** 25%-Energy seed 30437 generated **one true source refused Garrote exactly t=98.000**, the **95-second World shutdown instant plus 3-second pull**, reason **requires:not stealthed**. That one rejection is recorded and separately classified as a **source-terminal transition** rather than the original in-combat 476-refusal loop. Cause/live equivalence not proven; keep complete v1.1 **unselected / Needs Retest**, not universally "zero refused" or Approved. Observe actual postfight Stealth/Vanish transition in client; never weaken the global final fallback guard to excuse repeated uncastable actions.

**New potentially important solo throughput gap:** shipped source applied **6 genuine Slice and Dice auras in each 95s source world** and **2 in each 20s solo world**, while protected Current and full v1.1 applied **zero** in ordinary one-target non-boss combat: custom APL deliberately requires boss or 2+ enemies for Slice and Dice. This is a falsifiable opportunity to improve self-sufficient solo attacks in longer outdoor fights, but the source world does not prove real attack-speed damage, weapon-poison uptime or net DPS; spending combo/Energy/GCD on a short pull may be worse. Do NOT auto-select an untested Slice and Dice variant or conflate buff-count with DPS.

## Final fallback, constraints, live checks, rollback and status

**Final Fallback / Repeated Recommendation:** Frost 5% repeats 9–12 legal Frostbolts, 0 refused, even when no FoF procs; that is stable castability, not proof of maximum damage. Rogue protected Current 25% repeats a genuinely uncastable Garrote 476 times and FAILS, while saved v1.1 fixes during-combat chains with 9–14 genuine finishers, 0 during-combat refused; its one end-world Garrote rejection remains an honest Needs Retest checkpoint. No external tool can certify player-client stealth or gameplay from source. Real talents/unlocks1–60, Mobs/swap/aoe/poison/imbue reads, raid boss target state, health, UI flicker, DPS are unverified.

**Saturday safe gameplay request:** Frost use actual Fingers of Frost proc / cast Ice Lance, Winter's Chill and natural low-Mana fallback; Rogue Combat test naturally low Energy after opener, real combo/Eviscerate hit vs miss, terminal false Garrote and *real solo* Slice and Dice tradeoff in 10–20s mobs vs long stationary elites only when safe. Capture /hek snap on conflicting recommendations. P0 Guardian and Hunter BM gameplay priorities remain intact.

**Approval state:** #24/#25 are independent source-effect research units, **not playable Approved**; no APL revision changed, Current/last-working protected, source estimated Mana remains uncertain. Campaign stays **23/50 until PR #106 all exact-head CI green, protected squash merge and postmerge integrity/cleanup PASS**, then can record 25/50 with 53 full protected revisions and 0 Approved. [25-unit portfolio evidence audit](knowledge/BREADTH_25_REVIEW.md) records all coverage gaps and next work.
