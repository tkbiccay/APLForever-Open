# Hunter — BeastMastery pilot mechanics reference

**Forever source:** v0.9.0 · exact commit `8f95f2ea0a45428554c1e938ed7357b870030514` · client data build `1.60.1.70338`.

**Development knowledge only.** Engine registration fields are source-pinned; classifications and proposed APL lanes are reviewed interpretations, not automatically supported toggles or in-game validation.

**Scope:** 14 reviewed abilities; all 50 registered class talents from three trees. Pilot role: `Hunter_BeastMastery`. Missing ability entries mean **not yet reviewed**, never an assertion of absence.

## Reviewed abilities

| Ability/source | Classifications | Native toggle / suggested lane | GCD · CD · resource | Range evidence | Notes and limitations |
| --- | --- | --- | --- | --- | --- |
| [`rapid_fire`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L696) | offensive, major_cooldown, buff | `cooldowns` / **MajorCooldowns** | off · dynamic/unknown · mana (source spend 100) | not checked | Native cooldowns toggle. Rapid Killing alters the base 300s cooldown; source models this dynamically. |
| [`bestial_wrath`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L718) | offensive, major_cooldown, pet_management | `cooldowns` / **MajorCooldowns** | off · 120s · mana (source spend 0.12) | not checked | Requires the pet to be out; 12% base Mana; native cooldowns toggle. Off-GCD. |
| [`serpent_sting`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L738) | offensive, dot, debuff, ranged | `not declared` / **General** | spell · 0s · mana | 8–35yd *source world only* | Published source world uses 8–35 yd; 6yd out-of-range loop is a verified regression in the shipped Turret reference. |
| [`arcane_shot`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L759) | offensive, ranged | `not declared` / **General** | spell · dynamic/unknown · mana (source spend 0.11) | 8–35yd *source world only* | Shares cooldown with Summon Hawk. Improved Arcane Shot alters its cooldown. |
| [`summon_hawk`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L784) | offensive, summoning, pet_management | `not declared` / **General** | spell · 6s · mana (source spend 0.11) | 0–35yd *source world only* | Source registers a 0–35 yd range in the world; source pack models guardians capped at two for 18s but world damage and live count fidelity are incomplete. |
| [`aimed_shot`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L802) | offensive, ranged | `not declared` / **General** | spell · 6s · mana | 8–35yd *source world only* | Shares cooldown with Multi-Shot. Cast duration and cost are dynamic. |
| [`multi_shot`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L824) | offensive, ranged, aoe | `not declared` / **General** | spell · 6s · mana | 8–35yd *source world only* | Shares cooldown with Aimed Shot. Ranged cast and cost are dynamic. |
| [`concussive_shot`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1053) | utility, control, slow, ranged | `not declared` / **Utility** | spell · 12s · mana (source spend 0.08) | not checked | Has a registered 12-second cooldown; range still needs exact independent source-world and in-game checks. |
| [`intimidation`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1080) | utility, control, stun, pet_management | `not declared` / **Utility** | spell · 60s · mana (source spend 0.08) | not checked | A pet-delivered stun; pet cast/landing and interrupt semantics must be independently verified. |
| [`disengage`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1122) | utility, movement | `not declared` / **Utility** | spell · 5s · mana | not checked | Registered 5-second cooldown in this Forever class pack; do not import Retail movement assumptions. |
| [`feign_death`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1136) | defensive, utility, threat | `not declared` / **Utility** | off · 30s · mana (source spend 80) | not checked | Off-GCD with a registered 30-second cooldown; threat/drop mechanics and use in live combat need verification. |
| [`mend_pet`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1239) | healing, pet_management, utility | `not declared` / **Utility** | spell · 0s · mana | not checked | Five-second channel; Improved Mend Pet modifies the cost. No source-native pet triage proof. |
| [`call_pet`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1263) | summoning, pet_management, utility | `not declared` / **Utility** | spell · 0s · none declared | not checked | Registration uses plain client usability, but source forecast does not make the pet appear; no accepted-cast pet transition proven. |
| [`revive_pet`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1275) | healing, pet_management, utility | `not declared` / **Utility** | spell · 0s · mana | not checked | Base Mana cost and cast time modified by Improved Revive Pet; the source does not model full pet arrival on cast completion. |

Native toggle = actual registered class pack field. Suggested APL lane = intended design classification **only**. No native toggle does not imply that a user-facing mode is automatically obeyed. Source-world range does not prove the live client's range or Auto Shot fidelity.

## All registered class talents

| Talent/source | Tree | Rank 1 spell ID | Max ranks | Mechanical review |
| --- | --- | ---: | ---: | --- |
| [`deadly_aspects`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1308) | Beast Mastery | 19552 | 5 | Registered only — effects not yet reviewed |
| [`endurance_training`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1309) | Beast Mastery | 19583 | 5 | Registered only — effects not yet reviewed |
| [`focused_fire`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1310) | Beast Mastery | 1223755 | 2 | Registered only — effects not yet reviewed |
| [`improved_aspect_of_the_monkey`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1311) | Beast Mastery | 19549 | 3 | Registered only — effects not yet reviewed |
| [`improved_revive_pet`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1312) | Beast Mastery | 24443 | 2 | Source registration reduces Revive Pet cast by 3s and base Mana cost by 20% per rank. |
| [`pathfinding`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1313) | Beast Mastery | 19559 | 2 | Registered only — effects not yet reviewed |
| [`bestial_swiftness`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1314) | Beast Mastery | 19596 | 1 | Registered only — effects not yet reviewed |
| [`unleashed_fury`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1315) | Beast Mastery | 19616 | 5 | Registered only — effects not yet reviewed |
| [`improved_mend_pet`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1316) | Beast Mastery | 19572 | 2 | Registered only — effects not yet reviewed |
| [`ferocity`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1317) | Beast Mastery | 19598 | 5 | Registered only — effects not yet reviewed |
| [`summon_hawk`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1318) | Beast Mastery | 1293241 | 1 | Talent rank 1 registers Summon Hawk; the action's spell ranks/cap are separate mechanics. |
| [`spirit_bond`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1319) | Beast Mastery | 19578 | 2 | Registered only — effects not yet reviewed |
| [`intimidation`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1320) | Beast Mastery | 19577 | 1 | Registered only — effects not yet reviewed |
| [`bestial_discipline`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1321) | Beast Mastery | 19590 | 2 | Registered only — effects not yet reviewed |
| [`frenzy`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1322) | Beast Mastery | 19621 | 5 | Registered only — effects not yet reviewed |
| [`bestial_wrath`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1323) | Beast Mastery | 19574 | 1 | Talent ability; source requires a living, out pet to activate. |
| [`hawk_eye`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1325) | Marksmanship | 19498 | 3 | Registered only — effects not yet reviewed |
| [`improved_concussive_shot`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1326) | Marksmanship | 19407 | 5 | Registered only — effects not yet reviewed |
| [`lethal_attacks`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1327) | Marksmanship | 19426 | 5 | Registered only — effects not yet reviewed |
| [`improved_stings`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1328) | Marksmanship | 1310661 | 3 | Registered only — effects not yet reviewed |
| [`efficiency`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1329) | Marksmanship | 19416 | 5 | Registered only — effects not yet reviewed |
| [`careful_aim`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1330) | Marksmanship | 1223984 | 5 | Registered only — effects not yet reviewed |
| [`rapid_killing`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1331) | Marksmanship | 415405 | 2 | Rapid Fire cooldown model is 300s less 60s per rank. |
| [`improved_arcane_shot`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1332) | Marksmanship | 19454 | 5 | Arcane Shot cooldown is 6s less 0.3s per rank in the class pack. |
| [`lone_wolf`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1333) | Marksmanship | 415370 | 1 | Source guards pet recovery against Lone Wolf; this is a cross-tree interaction. |
| [`trueshot_aura`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1334) | Marksmanship | 1299346 | 1 | Registered only — effects not yet reviewed |
| [`mortal_shots`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1335) | Marksmanship | 19485 | 5 | Registered only — effects not yet reviewed |
| [`rapid_recuperation`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1336) | Marksmanship | 1223987 | 2 | Registered only — effects not yet reviewed |
| [`barrage`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1337) | Marksmanship | 19461 | 3 | Registered only — effects not yet reviewed |
| [`scatter_shot`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1338) | Marksmanship | 19503 | 1 | Registered only — effects not yet reviewed |
| [`ranged_weapon_specialization`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1339) | Marksmanship | 19507 | 5 | Registered only — effects not yet reviewed |
| [`sniper_shot`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1340) | Marksmanship | 1310687 | 1 | Registered only — effects not yet reviewed |
| [`improved_tracking`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1342) | Survival | 24293 | 5 | Registered only — effects not yet reviewed |
| [`deflection`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1343) | Survival | 19295 | 5 | Registered only — effects not yet reviewed |
| [`entrapment`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1344) | Survival | 19184 | 5 | Registered only — effects not yet reviewed |
| [`savage_strikes`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1345) | Survival | 19159 | 2 | Registered only — effects not yet reviewed |
| [`survivalist`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1346) | Survival | 19255 | 5 | Registered only — effects not yet reviewed |
| [`improved_wing_clip`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1347) | Survival | 19228 | 3 | Registered only — effects not yet reviewed |
| [`clever_traps`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1348) | Survival | 19239 | 2 | Registered only — effects not yet reviewed |
| [`surefooted`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1349) | Survival | 19290 | 3 | Registered only — effects not yet reviewed |
| [`deterrence`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1350) | Survival | 19263 | 1 | Registered only — effects not yet reviewed |
| [`survival_tactics`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1351) | Survival | 19376 | 2 | Registered only — effects not yet reviewed |
| [`predators_edge`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1352) | Survival | 1310627 | 5 | Registered only — effects not yet reviewed |
| [`counterattack`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1353) | Survival | 19306 | 1 | Registered only — effects not yet reviewed |
| [`resourcefulness`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1354) | Survival | 440529 | 2 | Registered only — effects not yet reviewed |
| [`expose_prey`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1355) | Survival | 1310532 | 2 | Registered only — effects not yet reviewed |
| [`survivalists_discipline`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1356) | Survival | 1310496 | 2 | Registered only — effects not yet reviewed |
| [`strider_kick`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1357) | Survival | 1317257 | 1 | Registered only — effects not yet reviewed |
| [`lightning_reflexes`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1358) | Survival | 19168 | 5 | Registered only — effects not yet reviewed |
| [`lacerating_strikes`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Hunter/Hunter.lua#L1359) | Survival | 1310533 | 1 | Registered only — effects not yet reviewed |

## Safe reuse

- Canonical data: class JSON; this Markdown is generated. Do not edit manually.
- Check native source, engine observations, level/rank and latest release before transferring mechanics to another spec.
- On upstream release changes: diff, review and explicitly re-pin; never overwrite v0.9.0 facts or copy Retail/Classic/SoD assumptions.
- Regenerate: python scripts/build_mechanics_reference.py --write. Validate: --check; optional pinned checkout: --source-root ../upstream/hekili.
- Research once → Preserve evidence (including failed tests) → Reuse after role-specific verification. No APL approval from this page.
