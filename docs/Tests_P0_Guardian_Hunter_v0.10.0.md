# P0 Guardian and Hunter BM: v0.10.0 decision evidence and short live check

**Date:** 19 November 2026. **Actual upstream source:** Hekili Forever v0.10.0, commit 3c2cf3e32472cc807b1ba29d992fc13a273da8ee. [Actual native source run](https://github.com/tkbiccay/APLForever-Open/actions/runs/44558486270) (job 135680945304).

**Scope warning:** Guardian and Hunter focused native steps PASSED; the overall workflow FAILED later on existing Feral hidden-health and Arms precombat warnings. Complete 23-role compatibility remains Partial / Needs Retest, [Draft PR #13](https://github.com/tkbiccay/APLForever-Open/pull/13). The results below were extracted from the original v0.10.0 job log, not rerun or reproduced in-game.

## 1. Guardian / Feral Tank, shipped versus v1.0 versus v1.2

- [v1.0 Reported Working / Needs Retest](../roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt): protected preferred SHA256 f386e158a5e262e309dac7d0fd2929fb8e16e02b1378d71b5956c1bf6b99a786.
- [v1.2 Draft Candidate](../roles/Druid/Candidates/APL_Druid_Guardian_v1.2_Draft.txt): unselected SHA256 da358b7c04b47732966c47a91b7f6f5d32410f9077aabe2aac39252139a47b76.
- [v0.10.0 shipped release](https://github.com/zmsl/hekili/releases/tag/v0.10.0): Guardian default removed Swipe and health-based Barkskin/Frenzied Regeneration; this is the comparator, not a mandated design.

| Actual native scenario | v1.0 | v1.2 | Interpretation |
| --- | --- | --- | --- |
| L60 two-attacker, Defensives OFF, natural Rage | 4 Demoralising Roars; 11 Lacerates, 7 Primal Bites | 0 Roars; 15 Lacerates, 8 Primal Bites | Toggle-driven *priority divergence*, not a TPS or DPS gain |
| L60 three-attacker, Defensives OFF | 2 Demoralising Roars | 0 Roars | Off-switch works in this world; first-turn threat/survival still unmeasured |
| L60 38-second Barkskin fixture, Defensives OFF | 0 Barkskin | 0 Barkskin | Correct negative eligibility |
| L60 38-second Barkskin fixture, Defensives ON | 0 Barkskin, 2 Roars | 1 Barkskin, 1 modelled aura, 2 Roars | **Proactive cast actually accepted in augmented source fixture**, not proven mitigation |

The published Guardian source world does not include Barkskin in its map/trained kit, so the Barkskin check **explicitly adds source-registered spell, training level and aura effect** to its test-only world. This is not evidence of actual damage reduction or of an unmodified source-world spellbook.

Natural level-60 low-Rage v1.2 high-kit Maul queue remains **Blocked**. Recorded maximum Belief lower Rage bound: **26** (two attackers), **24.869** (three attackers); no queue/strike. No direct high-Rage injection or synthetic positive claim.

**New source-derived risk to check:** the v1.2 Barkskin guard uses target.within5. The [v0.10.0 debugging guide](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Debugging.md) says that if Hekili cannot bracket distance, both target.withinN and target.outsideN can read true. Thus target.within5 does **not necessarily prove actual melee range**. A bad early Barkskin is a possible hypothesis, not a proven regression. Prior v1.0 remains the rollback.

## 2. Hunter BM, shipped versus v1.1 versus v1.2

- [v1.1 Current Draft reference](../roles/Hunter/Current/APL_Hunter_BeastMastery_v1.1_Draft.txt): SHA256 a9d752c5e6cdc11fc369fcb6627b73686cc52b5139ed2df4c6628db6c7826d96; not preferred/Approved.
- [v1.2 Draft Candidate](../roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.2_Draft.txt): SHA256 6abe7e0ff17ff3bfadf9dd8fe234399457127c3535272447b355120f2f5325cd; unselected.

| Real v0.10.0 source six-yard scenario | First three recorded icons | Source-accepted Hawk casts | Refusals |
| --- | --- | ---: | ---: |
| Shipped BM Turret | Serpent Sting / Serpent Sting / Serpent Sting | 0 | **109 range** |
| v1.1 reference | NO_ACTION / NO_ACTION / NO_ACTION | 0 | 0 |
| v1.2 Candidate | Summon Hawk / Summon Hawk / Summon Hawk | **3** | **0** |

The three v1.2 Hawk presses were accepted at **3.4, 9.4 and 21.4 seconds** with modelled live Hawk counts **0, 1 and 1** immediately before each; the model reached a maximum of two active slots. These are different event-advanced world states, not three simultaneous Hawks or evidence of spamming an unusable button. Temporary Hawk Belief does not establish main-pet status or real pet damage. The six-yard fixture has a known **unfaithful Auto Shot** component, so do not infer real ranged-auto behaviour.

At 12 yards, v1.1 and v1.2 were identical on that native world: **13 accepted actions Major OFF** and **19 Major ON**; this is expected because the Candidate's difference affects Hawk at 6–8 yards. Natural low-Mana tails also matched. No justified DPS-gain claim.

The existing pet-first-icon source test imports **v1.1** and shipped/archived, not the v1.2 pack itself: absent main pet -> Call Pet; dead -> Revive; living -> neither. v1.2 has byte-identical main-pet recovery lines, but **accepted Call/Revive, real main-pet arrival and next three live recommendations remain unproven**. Do not confuse main pet with temporary Hawks.

## 3. Minimal practical gameplay calibration

**No target dummies exist in WoW Forever.** [Official v0.10.0 debugging guide](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Debugging.md) requires using level-appropriate **open-world enemies**. Avoid unsafe pulls and ungrounded numerical DPS A/B trials.

1. Record actual installed Hekili Forever release, role, level, talent/gear, APL revision+hash, cooldown/defensive/interrupt/potion/AoE toggles, and any Cooldown Manager settings. If the character cannot learn the tested ability yet, mark it **Not Applicable**, not a FAIL.
2. Preserve the currently working in-game pack and settings **before** temporarily importing a separate test Candidate. [Official editor/import tutorial](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Tutorial-Your-First-Custom-Priority.md) documents creating a separate pack in /hekili > Priorities, pasting the full standalone APL into the **Source** tab, importing and making the test pack **Active**. A GitHub catalogue selection does not change which in-game pack is active.
3. On one safe ordinary pull, record the **first icon and three successive actual combat events** (recommendation -> pressed ability/accepted or refused -> new icon). Record repeated no-progress icons separately from deliberately waiting for resources.
4. **Guardian:** compare v1.0 with v1.2 on similar safe enemies. Test Demoralising Roar with Defensives OFF/ON. Only if Barkskin is legitimately known (level 44+), test whether v1.2 suggests it too early or when melee range is uncertain. Do **not** infer hidden player health or mitigation from a display icon.
5. **BM:** start with main pet absent and observe Call Pet -> actual arrival -> next three distinct recommendations. If safely possible, separately observe genuinely dead pet -> Revive Pet -> actual arrival. At **6–8 yards** check whether Hawk is sensible and real ranged actions remain castable; avoid inventing a manual pet-death scenario.
6. When a wrong/unusable/repeated icon **is visible**, type **/hek snap**; open **/hekili > Snapshots (Troubleshooting)**, select it, Ctrl+A / Ctrl+C, and save complete text. Attach it to a GitHub report with expected versus observed action. [Official snapshot instructions](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/Reporting-A-Problem.md). Keep full warnings and the diagnostic read lines.
7. If a meaningful regression occurs, **restore the earlier pack immediately**. Record result as **Good / Wrong icon / Inconclusive / Blocked by level or unobservable state**. Only explicit maintainer review after gameplay evidence can change catalogue preference or Approved status.

Submit a short report using the [P0 in-game validation issue template](https://github.com/tkbiccay/APLForever-Open/issues/new/choose), or add to the existing [Guardian issue #3](https://github.com/tkbiccay/APLForever-Open/issues/3) / [Hunter BM issue #5](https://github.com/tkbiccay/APLForever-Open/issues/5). No change to any shipped, last-working, Candidate APL bytes or status follows from this evidence report alone.
