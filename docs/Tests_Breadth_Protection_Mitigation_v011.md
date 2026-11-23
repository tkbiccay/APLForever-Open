# Protection breadth #16–17 — Holy Shield charge spend and zero-Rage fallback

**23 November 2026; source-native only; not In-Game Validated or Approved.** Published Hekili Forever v0.11.0 at exact zmsl/hekili source commit **86b739cbc4e6afbcbc693c3790ee81197fc6234b**. [Public PR #102](https://github.com/tkbiccay/APLForever-Open/pull/102), [first native 8/8 PASS 45279994767](https://github.com/tkbiccay/APLForever-Open/actions/runs/45279994767). Two separately falsifiable original mechanics; no APL or catalogue changes.

## Full released-source comparator and safeguards

For each role, independently import full shipped WoWSims-derived reference, complete original protected Current v1.0 and whole previously stored **unselected v1.1** into the matching level60 class-specific source World. 2 seeds and 2 test conditions per role; 4 cases × 3 full profiles × 2 classes = **24 complete source combat loops**. All imported original lists active; no errors, unknown syntax or class-kit substitutions. Major/Minor/Interrupt/Movement OFF throughout. Real accepted/refused source actions, not merely icon ticks, are measured. There is no DPS, numerical threat, real player gear, real client health or PvE survival oracle in these Worlds.

- Paladin Current: roles/Paladin/Current/APL_Paladin_Protection_Tank_v1.0_Draft.txt. Full preserved Candidate: roles/Paladin/Candidates/APL_Paladin_Protection_v1.1_Draft.txt. Both remain unpromoted and no confirmed working fallback is invented.
- Warrior Current: roles/Warrior/Current/APL_Warrior_Protection_Tank_v1.0_PendingInGame.txt. Full preserved Candidate: roles/Warrior/Candidates/APL_Warrior_Protection_v1.1_Draft.txt. Pending In-Game is not player approval.

## Unit #16: Paladin Protection — genuine incoming BLOCK and Holy Shield charge spending

**Novel independent question:** earlier source tests proved Holy Shield casts and buff activation; did the actual source incoming swings **consume real shield charges** rather than merely showing a buff? Published Protection World adds +30% modelled block chance while four-charge Holy Shield is active and spends one charge when a true BLOCK occurs. Grouped two-attacker world, 4yd, 68 seconds, player source threat 3 from controlled pre-Facade UnitThreatSituation, client role DAMAGER (cannot mistake role.tank for aggro). Two seeds 30417/30437; native Defensives OFF/ON; full shipped/Current/unselected Candidate. True World incoming swing BLOCK and emitted positive aura charge decrements counted independently.

| Seed | Defensives | Shipped HS casts | Current HS casts | Candidate HS casts | Candidate real BLOCK swings | Candidate positive charge decrements | Candidate later accepted actions |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 30417 | OFF | 3 | **0** | **4** | 11 | 10 | 24 |
| 30417 | ON | 3 | 4 | 4 | 11 | 10 | 24 |
| 30437 | OFF | 3 | **0** | **4** | 5 | 5 | 24 |
| 30437 | ON | 3 | 4 | 4 | 5 | 5 | 24 |

**Supported source result:** Candidate performed autonomous routine Holy Shield upkeep with optional Defensives OFF, while Current did not. The source actually blocked incoming attacks and spent 5–10 shield charges per scenario, with **zero candidate refused casts** and 24 accepted later actions. When native Defensives ON, full Current and Candidate produced identical accepted shield counts and charge/block event counts in the tested Worlds. Zero-stack aura events can result from expiry or depletion, so we do not claim every shield cast fully depleted its four charges. Source blocked-hit number is NOT a calibrated survival, threat or damage advantage; RNG and source fixture limits remain. This is not a new unselected APL revision; existing v1.1 stays protected.

## Unit #17: Warrior Protection — true initial Rage zero/five final chain

**Distinct from prior 25/100 starting Rage test:** 2 seeds 30461/30479 × starting **0 or 5 true Rage** × full shipped/Current/v1.1, 85-second naturally advancing two-attacker source World, 4yd, native Major/Minor/Defensives OFF. No artificial Rage, Revenge proc, power addition or action oracle injected. The full subsequent offensive chain is counted from actually accepted legal press events.

| Seed | Rage start | Shipped accepted / cost refused | Current accepted / offensive / refused | Candidate accepted / offensive / later offensive / refused |
| --- | ---: | --- | --- | --- |
| 30461 | 0 | 24 / **2** | 20 / 16 / **0** | **20 / 16 / 15 / 0** |
| 30461 | 5 | 25 / 0 | 19 / 15 / **0** | **19 / 15 / 14 / 0** |
| 30479 | 0 | 28 / 0 | 18 / 15 / **0** | **18 / 15 / 14 / 0** |
| 30479 | 5 | 27 / 0 | 18 / 15 / **0** | **18 / 15 / 14 / 0** |

**Supported source result:** Current and complete unselected Candidate recovered to 15–16 real accepted offensive actions with 14–15 later accepted offensive actions and **zero cost/other refused source presses**, even starting at zero Rage. The shipped default made **two real cost-refused attempts in one seed30461 0-Rage scenario**; retain this genuine negative, not cast-end epsilon. Shield Block stayed zero because Defensives OFF; these results **do not prove** tank defensive efficacy, Revenge eligibility after an actual block, client threat/aggro, or throughput based on cast-count differences.

## Feral DPS three health predicates — safety classification, NOT another counted unit

Audited the protected full Feral Current v1.0 and existing v1.4 as well as historical [three-independent-guard source compiler test](https://github.com/tkbiccay/APLForever-Open/actions/runs/44903782868) and [existing Feral Barkskin defensive source test](https://github.com/tkbiccay/APLForever-Open/actions/runs/45064263862). The original Current has exactly **three failing health.pct predicates** guarding Barkskin, Frenzied Regeneration and Nature's Grasp. The existing **unselected v1.4** already compiles without the three diagnostics by retaining **source-observable aggro/group-controlled Barkskin** and leaving two actual health-dependent healing/escape spells manual. The existing Feral guard and Barkskin source tests already demonstrate that; **do not count it as a duplicate breadth unit or pretend the three health-sensitive abilities are safely automated**. Removing all three actions à la Arms Bloodrage would cost useful defensive options; invented player-health expressions are forbidden. Actual Feral health/triage is an engine/client limitation and remains a Saturday in-game check. All Feral Current/Candidate bytes and selection are untouched.

## Entire final fallback, gaps, decision

The custom Paladin Candidate accepted 24 genuine later non-shield actions; both Warrior full custom profiles accepted 14–15 genuinely later offensive actions after zero/tiny Rage, with **zero source refusals** under these specific fixtures. That does **not** prove every low-level rank, Mana-zero ending, changed targets, 3+ live mob AoE, 6–8yd range, real threat, real mitigation, off-hand/shield gear checks, pet/health behaviour, items, numerical DPS, icon flicker or player GCD progression. Unverified tails are explicitly deferred, not labelled safe or Approved.

**Status:** two independently evidenced provisional source-native breadth units #16 and #17. Count **only after final-head CI all green, protected-main PR merge and postmerge integrity**. All existing last-working, Current, Candidate, hashes and rollback paths remain protected and unselected. **Next in-game safe play:** Paladin group combat with natural aggro, confirm Holy Shield buff CHARGES actually reduce after incoming hits and three safe subsequent casts; Warrior natural 0–5 Rage then three actual legal attacks, then separately native Defensives ON Shield Block/eligible Revenge without forcing dangerous combat. For Feral, collect a safe /hek snap on actual client if health triage is ever exposed; no artificially dangerous low-HP test requested.
