# Regression — Warlock_Demonology — Repeated Life Tap — 2026-11-08

- APL identity: `Warlock_Demonology` (DPS, per canonical catalogue)
- Incident date: **8 November 2026**
- Historical incident identifier: `DEMO-006` (legacy search alias only; not a filename or APL revision)
- Historical state: **Reported Working / Needs Retest**, never Approved.
- Current executability: **STATIC guardrails** and a **simulated low-Mana native comparison** are available. Live reproduction, health-cost validation and /hek snap remain Not Run.
- Canonical preferred/last-working rollback: `roles/Warlock/Current/APL_Warlock_Demonology_DPS_v1.0_ReportedWorking.txt`, SHA-256 `067ae757344a71f4a0d02f0a18e2f36745ceb8c0015761970948381aba8e7bf7`.
- Source-pinned comparator, **not** preferred: `roles/Warlock/Archive/APL_Warlock_Demonology_DPS_v0.8_Default.txt`; pinned Hekili Forever `zmsl/hekili@246abf322ed53e3b7ab796ea7089c72329f3eb9d` (source pack `Demonology (wowsims.com).simc`).

## Observed symptom, distinct from hypothesis

A previously reported-working custom Demonology APL was replaced by the shipped default after stronger upstream simulation/replay evidence. The user then reported repeated **Life Tap** recommendations after ordinary DoT upkeep, instead of a damage filler.

Historical source inspection reportedly identified an unconditional Life Tap tail and missing low-level damage filler below level 18. The exact in-game causal chain was not captured and remains **unconfirmed**.

The newer pinned v0.8.x shipped-default comparator includes Shadow Bolt and Searing Pain fillers but retains conditional automatic Life Tap lines without a verified player-health safeguard. That is a **source-level risk**, not proof the old symptom still occurs. The preserved reported-working Warlock Demonology rollback contains no auto Life Tap and has Shadow Bolt / Searing Pain fallbacks; this is **not** live proof of safety or throughput.

## Verified repository protection
- Both exact historical working APL and newer shipped-default comparator are now stored with verified SHA-256 fingerprints, separated in the role catalogue.
- `tests/test_warlock_demonology_repeated_life_tap.py` checks source-hash preservation and known fallback/health-conversion patterns. Static tests cannot confirm actual next-icon behaviour.
- Preserve the legacy working config unchanged; `settings.assigned_curse` remains an actual setting dependency in this rollback, pending a separately tested replacement.
- Related research and tests: `Research_Warlock_Demonology_DPS_v1.0.md` and `Tests_Warlock_Demonology_DPS_v1.0.md`.

## Mandatory live / replay test (still outstanding)
1. Record exact Forever client/addon build, level, talents, gear, options, APL file/hash, health and mana states. Verify normalised import.
2. After every DoT upkeep action, record the next suggested icon and the exact selected list entry; repeat on **three consecutive recommendation cycles**.
3. Check low-level unlocks (including below level 18), insufficient mana for Shadow Bolt, Searing Pain available/unavailable and when Life Tap is manually used.
4. Exercise target swap, single-target, 2 and 3+ targets, Cooldowns OFF, trinket/item gates and unknown mana/health.
5. Inspect `/hek snap` on repeated Life Tap, stalled damage, flicker or failed casts. Separate observed symptom, source hypothesis and engine-data issue.
6. Compare current shipped default, exact last-reported-working Warlock Demonology rollback and any separately versioned candidate at matched settings/gear/talents; preserve rollback.

A repeated inappropriate suggestion or critical castability regression **fails promotion**, whatever simulated DPS claims. Do not declare the incident resolved or an APL Approved without repeatable in-game evidence.

## Native low-Mana comparison — 15 November 2026

**Historical failing revision unavailable in inspected Git history.** The incident record describes a shipped-default substitution. The preserved v0.8 comparator is a newer pinned snapshot and cannot be identified as the incident bytes. v1.0 has zero Life Tap rules. v0.8 has three, including two in the main list and one in the cooldown list. Its exact SHA-256 is `da6e5b71c3fc8710745e4ef7037faf5c810958186508b870b3596334d19d3241`.

**Static source.** The pinned Warlock learn table teaches Shadow Bolt 686 at level 1, Life Tap 1454 at 6 and Searing Pain 5676 at 18. The v1.0 chain covers precombat, cooldowns, AoE, brand, banes, curses, proc fillers, Corruption, Immolate, then Shadow Bolt and Searing Pain. The rank- and talent-dependent spends remain engine checks. In the stock source world Corruption lasts 18 seconds and Immolate 15 seconds before applicable modifiers. The addon `tapped()` Mana model uses rank, capped level contribution, Spirit and Improved Life Tap. Neither that handler nor the harness `life_tap` effect debits health. The source world starts the player at one billion health. Health fields are available in engine state, but a reliable Life Tap safety guard requires evidence for the actual cost and observable health. See pinned `src/Hekili_Warlock/Warlock.lua`, `tests/Forever/helpers/warlock_world.lua` and `tests/Forever/wowsims/learn_warlock.lua`.

**Simulated.** Matched upstream level-60 Demonology kits, seed 30417, 25 seconds, one target, 20% starting world Mana (1265.6/6328), Cooldowns and Defensives OFF. The imported profiles drive the upstream loop. APL forecast floor, post-poll belief and post-poll truth are logged separately. The v0.8 comparison observed three successive accepted decisions with both DoTs active:

| World / engine time | First icon and accepted press | Forecast Mana floor | Post-poll Mana | Post-poll health |
|---|---|---:|---:|---:|
| 15.4 / 1050.4 | Life Tap, wait 0 | 1290.96 | 1973.826 | 999999924 |
| 17.0 / 1052.0 | Searing Pain, wait 0 | 1994.28 | 1998.146 | 999999924 |
| 18.6 / 1053.6 | Life Tap, wait 0 | 1850.60 | 2533.466 | 999999911 |

Both DoTs remained active through this sequence, with Immolate expiring at 25.5 and Corruption at 31.8. The two displayed Taps used the main-list low-Mana threshold. After the second Tap, Searing Pain was accepted at 20.2 and 21.8. Five Taps occurred overall. A health change between rows reflects other world events, because the Tap effect has no health debit. **The reported uninterrupted repetition was not reproduced in this window.** The alternating taps and fillers show that the current default can spend several GCDs recovering Mana even after upkeep.

v1.0 made five accepted combat attempts and ended at 139.11 Mana with no Life Tap and no world refusal. Its run did not establish a matched both-DoTs-active, three-decision window. That low-throughput observation warrants caution before declaring the working tail optimal. A longer starvation interval, moderate/full starting Mana, the sub-18 simulated tail and low-health safety were Not Run. No candidate edit was justified.

Reproduce through the existing native workflow against the pinned engine. The targeted Busted filter is `--filter="DEMO-006 pinned low-mana comparison"` on `tests/Forever/aplforever_progress_spec.lua`. [Native run 43692251578]([private historical reference; not publicly accessible]) passed 31 checks. [Repository run 43692251593]([private historical reference; not publicly accessible]) passed. The knowledge topic on the separate Guardian branch already points to this canonical record. For other resource conversions, verify that the world and engine model both sides of a conversion before making a safety claim.

## Source-native after-DoT repetition reproduced — 15 November 2026 (v0.8.3)

[Repeatable report](Tests_Warlock_Demonology_DEMO006_v083_PostDot_Mana.md) and [native CI]([private historical reference; not publicly accessible]) extend the earlier 20%-Mana study. Three matched seeds (30417–30419) reach **actual Corruption and Immolate upkeep**, then experience a **single artificial Mana drain to 10%** before three source-event-advanced observations.

Across all three seeds, both the archived v0.8 and current shipped v0.8.3 default **actually cast Life Tap three times consecutively after an initial Searing Pain**, with both DoTs active. Seven total default Life Tap casts occurred with both DoTs active in each run. The protected reported-working v1.0 cast **zero Life Taps** and used Searing Pain when affordable. All three versions had zero source-world refusals/errors in the fixture. **86 native and 86 upstream tests passed.**

This upgrades a *similar current-default repeated-Life-Tap behaviour* to **Source-Native Simulated / Reproduced**, but **does not validate the historical 8 November bytes or cause**, in-game behaviour, DPS, or actual health cost. The tagged headless Life Tap mapping adds Mana **without removing HP** and uses a 1-billion-health world, so **health safety remains Not Run / Engine Limitation**. Preserve exact v1.0 as **Reported Working / Needs Retest**, not Approved, and keep Issue #30 open.
