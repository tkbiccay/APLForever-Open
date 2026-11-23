# Warrior Arms — released v0.11 health compiler and full fallback evidence

**23 November 2026 · Source-native executed, not in-game.** Public [PR #99](https://github.com/tkbiccay/APLForever-Open/pull/99); published Hekili Forever [v0.11.0](https://github.com/zmsl/hekili/releases/tag/v0.11.0), exact SHA 86b739cbc4e6afbcbc693c3790ee81197fc6234b. Test-only [Lua syntax RED 45268094797](https://github.com/tkbiccay/APLForever-Open/actions/runs/45268094797), [literal comparison assertion RED 45268245797](https://github.com/tkbiccay/APLForever-Open/actions/runs/45268245797), then **[native 8/8 PASS 45268453949](https://github.com/tkbiccay/APLForever-Open/actions/runs/45268453949)**. Neither early RED reached a combat assertion: preserve as fixture failures, not APL failures.

## Exact whole-profile comparator and protection

- Shipped **Arms (wowsims.com)** complete released default, comparison only. The world prices Rage and stance, but **does not subtract player HP for Bloodrage**.
- Protected exact Current v1.0: roles/Warrior/Current/APL_Warrior_Arms_DPS_v1.0_StaticValidated.txt, SHA256 **3bb923e9b071a3d9432471731ce609a3e8852741364ce4334d136e4509335f2c**. Historical StaticValidated status, catalogue preferred and last working **null**, no Approved or live proof. It has **one known compile error** in precombat automatic Bloodrage at hidden `health.pct>=95`.
- Complete original **unselected v1.1 Draft**: roles/Warrior/Candidates/APL_Warrior_Arms_v1.1_Draft.txt, SHA256 **28a3b253e94869ac7c043474426d1dd402c85305a3600431481c0efdc66d066b**. Byte-exact v1.0 except the *entire* automatic health-costing Bloodrage precombat action is omitted. All other actions and lists stay identical; no invented HP API, setting or new priority. Current unchanged and rollback protected.
- Earlier published all-role source native diagnostic proved that replacing *only* this health predicate **in memory** clears the error. That replacement is **not a safe standalone fix**: removing the guard while retaining automatic Bloodrage could cause HP loss. Candidate omits the whole health-costing action, potentially sacrificing a Rage power spike; it is not claimed superior DPS.

## Actual matched source-native tests

Published L60 Warrior Arms 2H/talent World, 75-second fights, two seeds **30417, 30437**, initial **25 / 90 Rage**, Minor cooldowns **OFF / ON**, Major/Defensive/Interrupt/Movement **OFF**. Eight cases × three complete profiles = **24 source combat loops**. Ten Current/Candidate lists imported and active (precombat, default, defensive_cures, minor_cooldowns, stance_control, major_cooldowns, cleave_and_aoe, rend_upkeep, utility, rage_dump). Actual accepted spells counted with source `rr.pressedBy`, cost/refusals and real follow-on press chronology via W.press, not simulated tick counts.

| Seed | Rage | Minor | Shipped accepted / Bloodrages | Current accepted / compiler errors | v1.1 accepted / errors | v1.1 offensive / observed follow-ons | Both custom refused |
| --- | ---: | --- | --- | --- | --- | --- | --- |
| 30417 | 25 | OFF | 32 / 2 | 17 / 1 | **17 / 0** | 16 / 16 | 0 |
| 30417 | 25 | ON | 32 / 2 | 17 / 1 | **17 / 0** | 16 / 16 | 0 |
| 30417 | 90 | OFF | 26 / 2 | 25 / 1 | **25 / 0** | 24 / 23 | 0 |
| 30417 | 90 | ON | 26 / 2 | 25 / 1 | **25 / 0** | 24 / 23 | 0 |
| 30437 | 25 | OFF | 26 / 2 | 15 / 1 | **15 / 0** | 14 / 13 | 0 |
| 30437 | 25 | ON | 26 / 2 | 15 / 1 | **15 / 0** | 14 / 13 | 0 |
| 30437 | 90 | OFF | 31 / 2 | 21 / 1 | **21 / 0** | 20 / 18 | 0 |
| 30437 | 90 | ON | 31 / 2 | 21 / 1 | **21 / 0** | 20 / 18 | 0 |

**Confirmed compiler finding:** Existing Current still yields exactly **one** compiler error in every world; complete v1.1 yields **zero** and all imported lists active. Candidate produces the **same accepted action counts as protected Current** in all eight matched worlds, zero source refused/cost attempts, 14–24 accepted offensives and 13–23 true observed subsequent offensive presses. Minor OFF/ON makes no measured difference in this non-boss source world, so there is **no confirmed output advantage**.

**Bloodrage safety limit:** Shipped makes **two accepted Bloodrage casts in each scenario even with Minor OFF**. The published source World grants Rage but does **not** debit HP for Bloodrage, so these casts cannot establish safety or higher DPS. Both Current and candidate made zero Bloodrages; Current's invalid precombat health guard probably explains that in this fixture, but is not reliable client proof. Never treat replacing health condition with a constant as a health-safe fix.

**Final Fallback / Repeated Recommendation checkpoint:** v1.1 made no refused or cost-failing recommendation in all eight source worlds and progressed through real later attacks after upkeep. This **does not prove** every tail branch, under-15 Rage, boss precombat, 1–59 ranks, low-health automatic conversion, true outgoing AoE, movement/range, execute, real DPS/TTK or real world Mana/health. Source model is neither a validated health oracle nor a real PvE output comparator.

**Decision:** **Unselected Draft / Needs In-Game Validation**; zero Approved. Protect v1.0 exact bytes/hash, no selection/rollback change. Existing all-23-role v0.11 import gate must still expect **one known Current Arms error**; the new Candidate is clean without falsifying the baseline. Next live test: `/hek snap` before combat and with low Rage and Minor OFF/ON, ensure no automatic health-cost Bloodrage; independently check authentic HP/API observability before attempting a safer controlled version. Recheck 1–60 ranks, 0–15 Rage, boss and manual real two-target mode before any candidate promotion. A measured safety win must not silently mask a meaningful DPS/Rage loss.
