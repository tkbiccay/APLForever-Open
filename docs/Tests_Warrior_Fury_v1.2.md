# Warrior Fury v1.2 — source-native movement and Rage regression evidence

**17 November 2026. Native / simulated, not player in-game.** Upstream **Hekili Forever v0.8.6** at exact source commit **2e9cb6a78d9088007e9acd9cce3eeb0e91463cc5**. Pull request [#84]([private historical reference; not publicly accessible]). **Code-head green CI:** [v0.8.6 run 44182255034]([private historical reference; not publicly accessible]), **843/843 tests passed, zero errors**. Companion repository validation [44182255295]([private historical reference; not publicly accessible]), v0.8.3 [44182255094]([private historical reference; not publicly accessible]), original v0.8.2 native [44182255066]([private historical reference; not publicly accessible]) green. Tagged v0.8.5 result must be checked separately; no claims until observed.

## Fixed experimental setup and full comparator

- **Current v1.0:** SHA256 bff9e4ecfac234f58d7057f47c1c1c4ef047f8d98f9018c506530d143e5d5b23, protected and selected, still Draft.
- **Archived v1.1 failure control:** SHA256 4c18938e392f8b4e785fda079b11a2f8e3dd41b850fe8e2e149ad1d8c264a2ff; retained byte-identical under Warrior/Archive.
- **New full standalone v1.2 Draft Candidate:** SHA256 **7280a021e796bfe97112e3b091e34e234348ead476305ef6a57856524ddf84d3**; identical to v1.1 except +5 Rage to Bloodthirst in both ST and AoE.
- **Released shipped comparator:** Fury (wowsims.com); no game-gear DPS fairness assumption.
- Source-native files: tests/native/aplforever_warrior_fury_movement_v086_spec.lua and tests/native/aplforever_warrior_fury_natural_v086_spec.lua. The imported full APL is checked against its immutable parent and exact edits; all lists compile and activate.

### 48 movement ON/OFF source worlds

Charge at **level 10 out of combat** and Intercept at **level 60 in combat**; actual source world distances **3 / 12 / 30 yards**; both toggle states; four profiles (Current, archived v1.1, v1.2 Candidate, shipped); matched seed **30417**, 9 seconds. Fixture installs independent public Forever **8–25yd** spellbook range for these two abilities in the fake client AND the true source cast checks, rather than treating all enemies as in melee. It undoes the released harness's **test-only forced Movement OFF reset** on its per-tick hook; this is not gameplay behaviour.

| Genuine accepted source casts at 12 yards | Movement OFF: Charge / Intercept | Movement ON: Charge / Intercept |
| --- | --- | --- |
| Protected Current v1.0 | **1 / 1 — OFF FAIL** | 1 / 1 |
| Archived v1.1 | **0 / 0** | **1 / 1** |
| New v1.2 Candidate | **0 / 0** | **1 / 1** |
| Shipped Fury | **1 / 1 — OFF FAIL** | 1 / 1 |

All profiles accepted **zero** mobility actions at illegal 3yd or 30yd. The positive ON checks are mandatory; this is not an OFF-only green. **48/48 passed**.

### 72 natural Rage, level unlock and final-tail worlds

Nine naturally trainer- and talent-cut levels **1/9/10/20/24/30/36/40/60**, one or two hostile attackers, **48 seconds**, source dual-wield Rage, same seed **30417**, four matching packs. Full repeated-first-icon checkpoint is counted only across **three genuine hostile swings**, not a manufactured resource oracle.

| Profile | Worlds | Source-accepted actions | Source cost refusals | Repeated-ready fallback failures |
| --- | ---: | ---: | ---: | ---: |
| Protected Current v1.0 | 18 | **253** | **0** | **0** |
| Archived v1.1 | 18 | **242** | **4**, all L60 two attackers | **0** by hostile-swing definition |
| New v1.2 | 18 | **244** | **0** | **0** |
| Shipped comparator | 18 | **338** | **0** | **0** |

The archived v1.1 **four cost failures** are an explicit expected-bad negative control, not a successful candidate: Bloodthirst 30 Rage attempted at **28.5345** Rage at 22.2/22.4/22.6 s and **29.5865** Rage at 37.8 s, with repeated refused suggestions inside those 0.2-second ticks. New v1.2 did **not** make those refused casts in any matched world and had no engine exceptions, unknown trained action accepts, forbidden Charge/Intercept with Movement OFF, or 3-hostile-swing repeated-ready failures. At L60 two attackers v1.2 accepted **14** source actions vs v1.0 **12**, archived **13**, but these are neither comparable DPS nor complete output metrics. Shipped's more numerous casts include unmodelled Bloodrage HP cost and different resource decisions. Source/world ceiling, estimated Rage, and high-level weapons in low-level worlds limit any performance inference. **72/72 passed** with the archived negative control interpreted as a preserved failure.

**Remaining upstream suite:** 24 Warrior Protection, 2 Arms guard, 16 Arms real nameplates, 28 Arms progression, 103 native imports, 93 Feral, and 457 upstream = **843 total** with 48 Movement and 72 Fury worlds. All passed at the test-code head. No new gameplay or replay DPS improvement claim.

## Approval / repeated recommendation checkpoint

**Source Safety Gate: PASS for this bounded matched source scenario**. **Live Safety & DPS: NOT TESTED**. Repeat recommendation with an immediate cost refusal was proven in archived v1.1; no such source refusal occurred in v1.2. The three-hostile-swing repeated-fallback gate also remains zero. Cannot declare universally safe when the engine's inferred Rage and actual real-client movement can diverge. Pending real in-game /hek snap at L60 with 1 and 2 targets, true Rage around 30, Movement ON/OFF at Charge/Intercept-valid ranges, normal dungeon conditions, an actual talent/gear/build pin and a fair shipped/current comparator. If a repeated refusal occurs, stop and keep Current unchanged; no silent candidate promotion.

**Rollback:** selected protected Current v1.0, exact checksum above; it is itself Draft, **not** proved ReportedWorking/Approved. Archived v1.1 is a failed regression reference, **not** a CheckPoint.
