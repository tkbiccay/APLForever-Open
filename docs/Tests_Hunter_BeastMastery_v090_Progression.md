# Tests — Hunter Beast Mastery v0.9.0 accepted-cast and Major-toggle comparison

**19 November 2026 | Source-Native (controlled), not In-Game Validated or Approved.**

## Immutable baseline

- Released Hekili Forever **v0.9.0**, source `8f95f2ea0a45428554c1e938ed7357b870030514`.
- Untouched shipped **Beast Mastery Turret (wowsims.com)** comparator; WoWSims provenance `e4ef929e5479` as declared by that translated APL.
- Original custom **v1.0 archived Draft**: `roles/Hunter/Archive/APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt`, SHA-256 `8b552b6dd6fc9f0c4221e75242ef147c840242b3c03c3e2a75d46aedfe039eba`.
- Independent **v1.1 Draft** (not preferred): `roles/Hunter/Current/APL_Hunter_BeastMastery_v1.1_Draft.txt`, SHA-256 `a9d752c5e6cdc11fc369fcb6627b73686cc52b5139ed2df4c6628db6c7826d96`, catalogue `preferred_apl=null`.
- No reported-working or Approved BM revision exists. No APL bytes/hashes/statuses, pet or form integration were modified.

## Exactly what is modelled

`tests/native/aplforever_hunter_bm_progress_v090_spec.lua` uses the released native `Forever.helpers.hunter_world.BeastMasteryTurret` and actual `Game.harness.loop` **accepted/refused** actions. The pinned source world has level 60, exported BM Turret talents/gear, a living main pet, 12-yard position, a single near-invulnerable enemy, natural Mana regeneration and an initial **3,330 Mana**. Each independent comparison uses **seed 30417, 40 seconds** with Major Cooldowns OFF or ON. The tested source world does **not** measure Hawk damage, real DPS, human movement, dynamic adds or tank survival.

| Profile and Major toggle | Real accepted presses | Accepted ranged/Hawk actions | Accepted offensive Major actions | Final true Mana | Raw combat refusals |
| --- | ---: | ---: | ---: | ---: | --- |
| Shipped / OFF | 17 | 12 | 0 | 437.47 | 0 |
| Shipped / ON | 20 | 12 | 2 (Bestial Wrath + Rapid Fire) | 667.47 | 1 microscopic `casting` edge, details below |
| Archived v1.0 / OFF | 13 | 8 | 0 | 1,701.97 | 0 |
| Archived v1.0 / ON | 19 | 11 | 2 (Bestial Wrath + Rapid Fire) | 1,398.47 | 0 |
| Draft v1.1 / OFF | 13 | 8 | 0 | 1,701.97 | 0 |
| Draft v1.1 / ON | 19 | 11 | 2 (Bestial Wrath + Rapid Fire) | 1,398.47 | 0 |

**Interpretation:** All three profiles selected genuinely source-castable ranged/Hawk actions and obeyed Major OFF in this **one world**; Bestial Wrath was accepted for shipped and v1.1 when enabled. v1.0 and v1.1 have identical results with a living pet here; the separately tested pet-recovery v1.1 coverage matters only when the main pet is absent/dead. More accepted casts or Mana spent **does not imply more DPS**, better shot clipping, ideal cooldown timing or higher practical performance: Summon Hawk damage is not modelled and source health is unmeasured. Nor do these results justify importing shipped priorities into our original custom architecture.

## Failed-first source regression and diagnosed boundary

1. [First public native run 44483955757](https://github.com/tkbiccay/APLForever-Open/actions/runs/44483955757) failed **1 of 6** strictly: shipped Major ON had `run.refused.casting=1`. Every other case passed. A real source-world refusal was reported, not suppressed.
2. [Diagnostic run 44484351445](https://github.com/tkbiccay/APLForever-Open/actions/runs/44484351445) instrumented real `W.press`. The refusal was **shipped Bestial Wrath (off GCD)** at logged time 8.6, precise `castUntil=8.6000000000000014`, precise `now=8.5999999999999996`, overhang **1.7763568394003e-15 s**; `gcdUntil=8.1`, true Mana **2888.66** versus spell cost **206**. This is a source-loop cast-time rounding boundary with adequate resources and expired GCD. The first universal `not offGcd` exception test correctly remained red, because this registered action is actually off-GCD.
3. Source-pinned, **single-action/single-boundary** exception in commit `1158b4549de724c66da5412bc50aa1a0c64e9283` accepts only one microscopic shipped/Major-ON Bestial Wrath refused press if Mana and GCD support it; logs its actual refusal. Any other spell, genuine early cast, extra refusal or larger overhang **fails**. It does not claim a zero-refusal shipped run. The focused six-case step **PASS** was observed on [native run 44484603066](https://github.com/tkbiccay/APLForever-Open/actions/runs/44484603066). The run's broader source-native gate must be inspected separately before recording an overall PASS.

This is a verified application of the cross-role **WORLD-002** precision-instrumentation method, but **not** a blanket cast-refusal exemption or a live-gameplay diagnosis. The source model, not the actual game client's inputs, produced the refusal.

## Unresolved decisions; keep cost low

- **P0 later BM native gate:** three genuinely state-advanced post-upkeep/low-Mana recommendations (not three polls of one icon) and the entire reachable final tail. Include non-boss short combat and intended waits, 5–8-yard dead zone, movement, 1/2/3/5+ target modes only where source-world observations are faithful. Never silently pass an unentered scenario.
- **Pet recovery:** source icon-only [PR #6](https://github.com/tkbiccay/APLForever-Open/pull/6) is a separate gate; true Call/Revive cast plus pet arrival still not demonstrated. If released harness cannot faithfully reproduce it, require targeted `/hek snap` in real client.
- **Ability/toggle classification:** BM v1.1 nests generic `use_items` inside the Major list; independence from Potions and Minor controls is **not proven**. Verify exact named items and native `Require Toggle` before creating a new full standalone revision. Major/Minor/Defensives/Interrupts/Potions must not be conflated.
- **Architecture hypothesis:** default v0.9.0 Turret has an HHA window (Hawk/Hawk/Arcane), while custom v1.1 uses a `pet.hawk.count<2` check and independent shot order. Evaluate actual repeats, waits and spell availability with a small targeted source-native test before changing a complete APL; no DPS simulator needed.
- **Guardian co-priority:** source-v0.9.0 release gates for reported-working Guardian and v1.2 Barkskin Draft already exist. Do not duplicate them for this Hunter-only question or promote Maul changes without the separate blocked positive reserve proof.

**Decision:** Preserve exact drafts, default comparator and all 32 protected APL SHA-256 values. No promotion or claimed numerical performance gain. Prefer the next *single targeted headless decision* to designing a simulator or mass-updating roles.

## Continuation 8c — 19 November 2026: naturally low Mana and the six-yard source range gap

**Pinned native source:** Hekili Forever v0.9.0 `8f95f2ea0a45428554c1e938ed7357b870030514`. **Exact test** `tests/native/aplforever_hunter_bm_progress_v090_spec.lua` on [PR #8](https://github.com/tkbiccay/APLForever-Open/pull/8). No APL/Catalogue/historical hash changed. This is source-native **Simulated** evidence only.

**Natural resource tail:** 175 seconds, one 12yd near-invulnerable target, 3330 Mana, level-60 Turret build, CD OFF, seed 30417, source FSR/regeneration/Auto Shots (no synthetic Mana drain). The actual three event-advanced low-Mana frames and zero refusals were shown in [focused 9/9 run 44487886345](https://github.com/tkbiccay/APLForever-Open/actions/runs/44487886345) (the *whole* workflow was subsequently cancelled on an intentional next commit; do not call that entire job PASS).

| Comparator | First Mana <=200 | Minimum true Mana | Three source-event checkpoints / actual wait | Raw refusals |
| --- | ---: | ---: | --- | ---: |
| Shipped Turret | 50.8s | 3.51 | 50.8/51.8/52.8s, Arcane Shot wait 3.6→2.75→1.75s | 0 |
| Archived custom v1.0 | 82.0s | 3.33 | 82.0/82.8/83.8s, accepted Sting then Hawk wait 4.97→3.97s | 0 |
| Draft custom v1.1 | 82.0s | 3.33 | Same observed accepted Sting and Hawk wait as v1.0 | 0 |

Each sampled low-Mana frame saw **real new world events**, not mere UI polls. The final stricter assertion restricts any falsely repeated *immediately ready* first icon to the **three actual sample ticks**, not an eventual accepted cast later in the fight; the target of this check is DEMO-006-like repeated fallbacks. Natural zero-Mana conditions are now better covered; not an exhaustive level 1–60/facing/target-swap final-tail certification. The shipped priority's earlier Mana exhaustion does **not** establish comparative DPS.

**Source-true six-yard dead zone (5–8 yards):** Range registration in released `hunter_world.lua`: Serpent Sting/Arcane/Aimed/Multi Shot **8–35yd**, melee strikes **0–5yd**, Summon Hawk **0–35yd**. At exact **6yd**, level60/22s, Major OFF, [failed-first run 44488313535](https://github.com/tkbiccay/APLForever-Open/actions/runs/44488313535) recorded:
- Shipped BM Turret: **109 true `range` refusals**, the first three shown recommendations all `serpent_sting`, zero Serpent Sting accepted. This is a **significant failure in the pinned shipped reference**, not a failure in either custom import.
- Custom v1.0 and v1.1: **zero refused actions**, with a safe `NO_ACTION` tail instead of invalid ranged/melee presses.
- The published source fixture starts automatic ranged attacks in its Turret world even when moved to six yards; **never** claim correct Auto Shot suppression or true damage output from this fixture. The activated Serpent Sting out-of-range refusal is genuinely enforced by the source world's press range checker.

The red result was deliberately retained. The fixture now treats shipped's **exact repeated out-of-range behaviour as an explicit negative comparator** while requiring zero refused actions for both customs. It also includes **a complete in-memory v1.1** that relaxes only Summon Hawk's unnecessary `target.outside8` guard, retaining `action.summon_hawk.in_range` and `pet.hawk.count<2`. The [subsequent focused native gate](https://github.com/tkbiccay/APLForever-Open/actions/runs/44488734153) **passed**, requiring at least **one source-accepted Summon Hawk at 6yd**, zero refusals and no invalid 8–35yd shots. The full job/current-final-doc head requires separate confirmation. **No new APL has been created or selected**: this demonstrates castability of a novel coverage improvement, not live Hawk effectiveness or an optimised DPS gain.

**One more release-protection issue before a production v1.2 Candidate:** `scripts/build_native_manifest.py::select_revision` selects the **latest compatible** revision if `preferred_apl=null`. For BM that is currently v1.1. Simply adding a catalogued v1.2 Candidate would change the selected native manifest by version number, potentially violating the user's no-auto-promotion rule. Test an explicit Current/working vs Candidate distinction before registering a BM v1.2 file; do not silently update the hash/catalogue.

**Next smallest decision:** preserve source-negative comparator and custom safe tail; test whether the Hawk gap variant remains castable at normal 12yd and across natural low Mana, then decide whether to make a standalone **Draft Candidate** behind a verified explicit-selection policy. Guardian (Feral Tank) remains equal priority; Maul reserve positive proof is still blocked. No numerical DPS sim needed.
