# Breadth units #14–15 — Fire Scorch Mana truth and BM Rapid Fire

**23 November 2026 · Source-native, not In-Game / Approved.** Published Hekili Forever v0.11.0 exact source SHA **86b739cbc4e6afbcbc693c3790ee81197fc6234b**; [public PR #101](https://github.com/tkbiccay/APLForever-Open/pull/101). **[Final 8/8 native PASS 45275657804](https://github.com/tkbiccay/APLForever-Open/actions/runs/45275657804)**, 2/2 focused Fire negative-control test plus 8/8 full test. Prior honest [original Current Fire 7/8 RED 45273931332](https://github.com/tkbiccay/APLForever-Open/actions/runs/45273931332), [exact-cost-gated v1.1 still RED 45274664575](https://github.com/tkbiccay/APLForever-Open/actions/runs/45274664575), [true-Mana vs Belief 2/2 diagnostic RED 45275232751](https://github.com/tkbiccay/APLForever-Open/actions/runs/45275232751). These were real source cost refusals; preserve the original-file negative control rather than masking it.

## Fair pinned complete comparators

Two **independent source hypotheses**: supported Mage Fire (#14), and P0 Hunter BeastMastery (#15). Published source full world level60 class/talents/kit/gear, modelled boss targetLevel=-1; Fire 25yd and BM Turret 12yd. Two seeds **30417/30437** × 100%/25% Mana × native Major Cooldowns OFF/ON; Minor/Defensive/Interrupt/Movement OFF. 90s full-Mana or 105s quarter-Mana, very high target HP. **48 complete advancing source-world executions:** three full profiles × four seed/Mana cases × two cooldown settings **per role** (24 Fire + 24 BM). Compiled all original full action lists with no runtime/import errors. Actual accepted actions from rr.pressedBy; attempted and refused reason, source true resource, engine Mana Belief and cast-end time from W.press; direct observed genuine later offensive presses. All candidate worlds had 3+ subsequent accepted offensive actions. Source-count parity is **not DPS, DPS improvement, pet damage or client validation**.

**Fire profiles:** complete released shipped Fire (wowsims.com); full immutable Current Fire v1.0 SHA256 **500a40752f3f3c1ec125262ce243996c1fb69b3da8a91af5c59ca6c3d165982a**; new full **unselected Fire v1.1 Draft** under roles/Mage/Candidates/APL_Mage_Fire_v1.1_Draft.txt SHA256 **dde6ce369f549ae38f68364ddc8c7e794519cc3bffba0356f8af5604c9426250**. v1.1 is byte-exact v1.0 except both Scorch priority lines now require source-supported **mana.lo >= action.scorch.cost + 20**; no other change.

**Hunter BM profiles:** released shipped Beast Mastery Turret (wowsims.com); protected full Current BM v1.1 SHA256 **a9d752c5e6cdc11fc369fcb6627b73686cc52b5139ed2df4c6628db6c7826d96**; complete pre-existing unselected BM v1.4 SHA256 **718182dca05bbb926652a8b824127a212651bcbdf930d820c5afd726b613aae5**. No BM APL changes. Both catalogue preferred and last-working are null: do not invent player-working status.

## Unit #14 — Mage Fire: new genuine late-Mana refusal and safe bounded reserve

The released source top-rank Scorch costs **150 Mana**. At **seed 30417, starting 100% Mana, Major CD ON, t=89s**, full protected Current genuinely attempted **Scorch at true Mana 134.166**, while its engine **mana.lo=151.4465**. The reported lower bound was **17.2805 above true Mana**. Released W.press refused **cost**, not casting overlap. A first candidate with only mana.lo >= action.scorch.cost was also **refused at the exact same resource and timestamp**, so plain exact-cost guards do NOT solve this case. Both red runs stay recorded.

After observing this discrepancy, the **complete unselected v1.1** uses **+20 Mana reserve** (17.2805 observed + 2.7195 extra margin) at BOTH upkeep and final fallback Scorch conditions. This is a **single scenario-derived conservative bound**, not universal safety at other levels/ranks or resource states.

| Seed | Starting Mana | Shipped accepted OFF / ON | Protected Current accepted OFF / ON | New v1.1 accepted OFF / ON | Current real refusals | v1.1 real refusals |
| --- | --- | --- | --- | --- | --- | --- |
| 30417 | 100% | 46 / 47 | 32 / 41 | **31 / 41** | **1 Scorch cost at t89 ON** | **0** |
| 30417 | 25% | 32 / 35 | 20 / 33 | **21 / 33** | 0 | **0** |
| 30437 | 100% | 48 / 49 | 30 / 42 | **31 / 42** | 0 | **0** |
| 30437 | 25% | 33 / 34 | 21 / 35 | **21 / 33** | 0 | **0** |

In all four seed/Mana conditions, Current and v1.1 correctly accepted **0 Combustions with Cooldowns OFF / exactly 1 with ON**. In all v1.1 worlds, 7–18 Scorches genuinely accepted, 18–38 subsequent offensive actions, **zero substantive refusals**. Shipped has one positive **7.105e-15-second cast-end casting overlap** in one low-Mana source case, carefully classified as the released harness's floating-point boundary and NOT ignored as a real cost fault. The candidate made **two fewer accepted actions** than Current under seed30437, 25% Mana, CD ON, so a safety/uptime trade-off remains. Differences of ±1 in other scenarios also disallow any output/DPS claim.

**Source classification:** Confirmed discrepancy between the released *Belief lower band* and true source mana, not confirmed detailed root cause (regen phase, forecast timing, hidden-resource dynamics or implementation). Source-only APL guard improvement bounded to sampled conditions. **Unverified:** true client Mana, level1–59 Scorch ranks, 0–5% Mana, other talents/gear/latency, movement, AoE, real 25yd range, PvE survival, damage and optimal cushion. New v1.1 remains **unselected Draft**, no Approved.

## Unit #15 — BM Rapid Fire independent P0 follow-up

Distinct from older BW 6–12yd source-range work, this test independently validates source-native **Rapid Fire** at **100% and 25% Mana** and no extra refused ranged casts, keeping **Bestial Wrath** as a second native toggle/off-switch control. The released world starts with an **already alive, out, arrived** trained tamed pet, and modelled Hawk damage = zero; **no actual pet summon, revive, travel, damage, real game range or melee clipping proof**.

| Seed | Starting Mana | Shipped accepted OFF / ON | BM Current accepted OFF / ON | Full BM v1.4 accepted OFF / ON | Rapid Fire OFF/ON | Bestial Wrath OFF/ON |
| --- | --- | --- | --- | --- | --- | --- |
| 30417 | 100% | 27 / 31 | **27 / 31** | **27 / 31** | 0 / 1 | 0 / 1 |
| 30417 | 25% | 20 / 22 | **20 / 24** | **20 / 24** | 0 / 1 | 0 / 1 |
| 30437 | 100% | 27 / 31 | **28 / 32** | **28 / 32** | 0 / 1 | 0 / 1 |
| 30437 | 25% | 20 / 22 | **20 / 24** | **20 / 24** | 0 / 1 | 0 / 1 |

Both complete custom profiles source-accepted exactly one Rapid Fire and one BW with **CD ON**, none with **CD OFF**, zero refused actions, 17–28 true later offensive actions. Current and v1.4 full accepted action and Aimed Shot totals matched each other **in every world**; this is a safe *normal pet fixture* regression for unselected v1.4, **not** proof of its Lone Wolf/Revive guards. Shipped CD ON had one positive **1.776e-15-second BW casting-end overlap per scenario** but no substantive cost/range refused; retained in raw logs. No net BM DPS or hawk/pet survival benefit claimed.

## Full fallback, approvals, lessons and next test

**Final Fallback / Repeated Recommendation checkpoint:** All candidate loops genuinely progressed with 3+ legal later offensive casts and no substantive refused/repeated unavailable spell. **Original Current Fire had a real refused Scorch at t89**. The source test did not cover every reachable final fallback branch, levels1–59, true 0-Mana or arbitrarily long fights and cannot certify no icon flicker/no-action tails in-game. Fail any reproducible live repeated unsafe fallback regardless of source outcomes.

**Decision:** two *provisional* separately evidenced units #14 and #15 (count only after final-head green CI and protected merge), **zero new approved roles**. Fire v1.1 experimental Draft remains unselected, exact protected Current unchanged; BM Current and stored v1.4 unchanged. Saturday /hek snap: Fire near **150–180 Mana** during Scorch and both CD toggles, three successive actual casts; BM pet alive/dead/Lone Wolf, Rapid Fire ON/OFF at 6yd and 12yd, legal three follow-ons, real Hawk/spell range. Next research: test Fire smaller/relative reserves and low-level costs fairly; BM actual pet arrival requires live/source-faithful fixture. **Cross-spec transfer** is a *hypothesis only*: never apply Fire's +20 Mana reserve to Shaman/Warlock/Priest without independently reproducing a source truth/Band discrepancy.
