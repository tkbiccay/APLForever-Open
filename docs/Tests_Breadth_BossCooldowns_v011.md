# Mage Arcane & Shaman Elemental — published v0.11 boss Cooldowns ON/OFF

**23 November 2026, Source-Native only; not In-Game / Approved.** Published Hekili Forever v0.11.0 source **zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b**. [Draft PR #100](https://github.com/tkbiccay/APLForever-Open/pull/100). Initial independent native [8/8 PASS 45271622429](https://github.com/tkbiccay/APLForever-Open/actions/runs/45271622429). Two separately substantiated proposed campaign units **#12 Mage Arcane** and **#13 Shaman Elemental**, count only after final-head CI and protected merge.

## Matched comparator, published source and limitations

Full shipped **Arcane (wowsims.com)** versus full protected original Mage Arcane v1.0; full shipped **Elemental (wowsims.com)** versus full protected Shaman Elemental v1.0. Both current APLs are SHA-protected and unchanged; no new Candidate or preferred change. At level60 with published talents, mana costs, modeled source-boss **targetLevel=-1**, source 25-yard distance (not live range proof), 100% or 25% starting fixture Max Mana (Mage 6,678; Shaman 6,295), matched seeds **30417/30437**, 90/100-second worlds. Four full profiles per seed/Mana (shipped OFF, Current OFF, shipped ON, Current ON). **32 fully advancing source combat loops**; Minor/Defensive/Interrupts OFF, native Major Cooldowns toggled OFF/ON. Whole default and all named action lists imported. Source W.press accepted/refused trace, authoritative rr.pressedBy counts and observed real post-first offensive actions.

## Unit #12 — Mage Arcane Power and Presence of Mind

| Seed | Mana | Shipped OFF/ON accepted | Current OFF/ON accepted | Current Arcane Power OFF/ON | Current Presence of Mind OFF/ON | Current ON observed later offences |
| --- | --- | --- | --- | --- | --- | --- |
| 30417 | 100% | 39 / 41 | **33 / 44** | **0 / 1** | **0 / 1** | 39 |
| 30417 | 25% | 32 / 31 | **22 / 33** | **0 / 1** | **0 / 1** | 28 |
| 30437 | 100% | 39 / 42 | **35 / 41** | **0 / 1** | **0 / 1** | 36 |
| 30437 | 25% | 26 / 33 | **19 / 39** | **0 / 1** | **0 / 1** | 34 |

**Positive source proof:** Native complete Current genuinely accepted one trained **Arcane Power** and one **Presence of Mind** in **every** boss/CD ON scenario, **none with CD OFF**, with at least 28 observed later offensive casts when ON and **no substantive refused**. One raw World source cast-end scheduling overlap (seed30437, 25% Mana, Current ON) at t=18.199999999999999 has true positive cast remainder **3.5527136788005009e-15s** on Arcane Power; stored in logs, not conflated with a cost/unknown failure. Shipped also exhibited such near-zero overlaps on Arcane Wrath/Missiles.

## Unit #13 — Shaman Elemental Mastery

| Seed | Mana | Shipped OFF/ON accepted | Current OFF/ON accepted | Current Elemental Mastery OFF/ON | Current ON observed later offences |
| --- | --- | --- | --- | --- | --- |
| 30417 | 100% | 47 / 50 | **51 / 53** | **0 / 1** | 46 |
| 30417 | 25% | 27 / 28 | **26 / 28** | **0 / 1** | 22 |
| 30437 | 100% | 44 / 45 | **51 / 49** | **0 / 1** | 43 |
| 30437 | 25% | 25 / 26 | **29 / 27** | **0 / 1** | 21 |

**Positive source proof:** One trained, source-accepted **Elemental Mastery** in **every** CD ON scenario and zero when OFF, 21–46 later offensive presses, zero substantive refusal. One Current ON full-Mana Lightning Bolt cast-end positive overlap at t=65.799999999999997 has **1.4210854715202004e-14s** cast remainder, with similar OFF/source-shipped overlap. **No zero-cost/cooldown/stance/GCD refused action was silently waived**; test rejects any substantive refusal or more than two tiny boundary events.

## Final fallback and what remains UNVERIFIED

Original full current APLs make many subsequent source-accepted legal spells with Major ON/OFF across matched full/25% Mana windows; **no repeated unaffordable recommendation** or source-substantive refusal. Exact source World's casting guard checks t less than castUntil with no epsilon; classify only tiny *positive* remaining casting time under 1e-7, never real refused cost. This is a new source-state dimension: earlier Arcane/Elemental v0.11 tests tested Major OFF only.

**Not proved:** any gain in DPS, optimal cooldown timing, true WoW boss range/facing, level1–59 ranks/talents, multi-target damage/DoT/totem effects, actual Mage spell power/crit or Elemental Mastery buff, real client health/resources, item/trinket eligibility, movement, PVP or live gameplay. Shipped counts are comparative accepted actions **not comparable damage**. No APL was edited, selected or Approved.

**Next:** owner Saturday live /hek snap on real boss with Cooldowns ON/OFF, verify real CD casts and three later spells with real resource truth, plus headless long-fight hold/ready and 1–60 specific unlock tests. If the published-source cooldown ON conclusions do not reproduce in client, retain full rollback and classify engine/fixture mismatch before any Candidate.
