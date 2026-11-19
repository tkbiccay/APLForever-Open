# Druid — Guardian pilot mechanics reference

**Forever source:** v0.9.0 · exact commit `8f95f2ea0a45428554c1e938ed7357b870030514` · client data build `1.60.1.70338`.

**Development knowledge only.** Engine registration fields are source-pinned; classifications and proposed APL lanes are reviewed interpretations, not automatically supported toggles or in-game validation.

**Scope:** 13 reviewed abilities; all 52 registered class talents from three trees. Pilot role: `Druid_Guardian`. Missing ability entries mean **not yet reviewed**, never an assertion of absence.

## Reviewed abilities

| Ability/source | Classifications | Native toggle / suggested lane | GCD · CD · resource | Range evidence | Notes and limitations |
| --- | --- | --- | --- | --- | --- |
| [`barkskin`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L907) | defensive, mitigation, buff | `defensives` / **Defensives** | spell · 60s · none declared | not checked | Native defensive toggle, 60s cooldown; cast is GCD=spell in v0.9.0, not automatically off-GCD. |
| [`bash`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L926) | utility, control, stun | `not declared` / **Utility** | spell · dynamic/unknown · rage (source spend 10) | not checked | Bear-only stun, 10 Rage. Brutal Impact reduces its cooldown by 15s per rank. |
| [`bear_form`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L952) | utility, form, defensive | `not declared` / **General** | spell · 0s · mana | not checked | Bear Form includes Dire Bear rank. Form changes alter usable actions; GCD=spell. |
| [`demoralizing_roar`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L1123) | defensive, debuff, threat | `not declared` / **General** | spell · 0s · rage (source spend 10) | not checked | Defensive purpose but the class ability has NO native defensives toggle. The APL must explicitly handle intended control. Costs 10 Rage. |
| [`enrage`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L1149) | resource, utility | `not declared` / **General** | off · 60s · none declared | not checked | Off-GCD Bear-only Rage generation with 60s cooldown; no native cooldown/defensive toggle declared. |
| [`frenzied_regeneration`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L1307) | defensive, healing, mitigation | `defensives` / **Defensives** | spell · 180s · none declared | not checked | Native defensive toggle, 180s cooldown. Source cannot model its full Rage health-drain against hidden health. |
| [`growl`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L1352) | utility, taunt, threat | `not declared` / **Utility** | off · 8s · none declared | not checked | Bear-only 8-second cooldown and off-GCD. Engine models debuff, not proof of target threat behaviour. |
| [`lacerate`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L1498) | offensive, debuff, dot, threat | `not declared` / **General** | spell · 0s · rage | not checked | Requires Feral tree talent Lacerate rank1 and Bear Form; source cost is max(0,15 - Improved Shred rank). Level boundary remains important. |
| [`maul`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L1552) | offensive, threat, melee | `not declared` / **General** | off · 0s · rage | not checked | Off-GCD queued next melee swing, resource reserve and time-to-swing essential; high-Rage positive proof still blocked. |
| [`swipe_bear`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L1985) | offensive, aoe, threat, melee | `not declared` / **General** | spell · 0s · rage | not checked | This class pack's exact action key is swipe_bear, not swipe. Costs Rage, requires Bear Form; manual/observable target-count rules apply. |
| [`primal_bite`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L1712) | offensive, melee, threat | `not declared` / **General** | spell · dynamic/unknown · rage | not checked | Forever Bear ability. Berserk removes the normally 6s cooldown while active, with dynamic 20 minus Ferocity cost. |
| [`challenging_roar`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L1042) | utility, taunt, threat, aoe | `not declared` / **Utility** | spell · 600s · rage (source spend 15) | not checked | Bear-only, 600-second cooldown, 15 Rage. Explicit situational threat logic required. |
| [`feral_charge`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L1234) | utility, movement, control | `not declared` / **Utility** | off · 15s · rage | not checked | Bear-only and off-GCD with 15s cooldown; actual range, facing and hostile movement safety require verification. |

Native toggle = actual registered class pack field. Suggested APL lane = intended design classification **only**. No native toggle does not imply that a user-facing mode is automatically obeyed. Source-world range does not prove the live client's range or Auto Shot fidelity.

## All registered class talents

| Talent/source | Tree | Rank 1 spell ID | Max ranks | Mechanical review |
| --- | --- | ---: | ---: | --- |
| [`improved_wrath`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L363) | Balance | 16814 | 5 | Registered only — effects not yet reviewed |
| [`genesis`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L364) | Balance | 1223081 | 5 | Registered only — effects not yet reviewed |
| [`moonglow`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L365) | Balance | 16845 | 3 | Registered only — effects not yet reviewed |
| [`improved_moonfire`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L366) | Balance | 16821 | 2 | Registered only — effects not yet reviewed |
| [`natures_majesty`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L367) | Balance | 1223082 | 2 | Registered only — effects not yet reviewed |
| [`natures_reach`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L368) | Balance | 16819 | 2 | Registered only — effects not yet reviewed |
| [`improved_entangling_roots`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L369) | Balance | 16918 | 3 | Registered only — effects not yet reviewed |
| [`natures_splendor`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L370) | Balance | 1223083 | 1 | Registered only — effects not yet reviewed |
| [`insect_swarm`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L371) | Balance | 5570 | 1 | Registered only — effects not yet reviewed |
| [`vengeance`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L372) | Balance | 16909 | 5 | Registered only — effects not yet reviewed |
| [`improved_starfire`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L373) | Balance | 16850 | 5 | Registered only — effects not yet reviewed |
| [`improved_natures_grasp`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L374) | Balance | 17245 | 2 | Registered only — effects not yet reviewed |
| [`natures_grace`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L375) | Balance | 16880 | 1 | Registered only — effects not yet reviewed |
| [`eclipse`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L376) | Balance | 408248 | 3 | Registered only — effects not yet reviewed |
| [`moonfury`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L377) | Balance | 16896 | 5 | Registered only — effects not yet reviewed |
| [`moonkin_form`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L378) | Balance | 24858 | 1 | Registered only — effects not yet reviewed |
| [`ferocity`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L380) | Feral Combat | 16934 | 5 | Class pack reduces Maul, Swipe Bear and Primal Bite costs by talent rank. |
| [`furor`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L381) | Feral Combat | 17056 | 5 | Registered only — effects not yet reviewed |
| [`feline_swiftness`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L382) | Feral Combat | 17002 | 2 | Registered only — effects not yet reviewed |
| [`feral_instinct`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L383) | Feral Combat | 16947 | 3 | Registered only — effects not yet reviewed |
| [`brutal_impact`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L384) | Feral Combat | 16940 | 2 | Class pack reduces Bash cooldown by 15s per rank. |
| [`thick_hide`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L385) | Feral Combat | 16929 | 3 | Guardian selector chooses Guardian with Feral dominance and Thick Hide 3/3; not a blanket level unlock. |
| [`improved_shred`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L386) | Feral Combat | 16966 | 3 | Class pack applies -1 Rage cost per rank to Lacerate. |
| [`savage_fury`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L387) | Feral Combat | 16998 | 2 | Registered only — effects not yet reviewed |
| [`feral_charge`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L388) | Feral Combat | 1238122 | 1 | Feral Charge is a registered Feral Combat talent; still verify level/rank availability. |
| [`sharpened_claws`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L389) | Feral Combat | 16942 | 2 | Registered only — effects not yet reviewed |
| [`predatory_strikes`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L390) | Feral Combat | 16972 | 3 | Registered only — effects not yet reviewed |
| [`lacerate`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L391) | Feral Combat | 1328617 | 1 | Talent rank1 spell 1328617; its learned rank boundary and later spell ranks require separate tests. |
| [`predatory_discipline`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L392) | Feral Combat | 1328613 | 1 | Registered only — effects not yet reviewed |
| [`primal_fury`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L393) | Feral Combat | 16958 | 2 | Registered only — effects not yet reviewed |
| [`leader_of_the_pack`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L394) | Feral Combat | 17007 | 1 | Registered only — effects not yet reviewed |
| [`natural_instinct`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L395) | Feral Combat | 1223242 | 2 | Registered only — effects not yet reviewed |
| [`rend_and_tear`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L396) | Feral Combat | 1223246 | 5 | Registered only — effects not yet reviewed |
| [`natural_reaction`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L397) | Feral Combat | 417051 | 5 | Registered only — effects not yet reviewed |
| [`primal_bite`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L398) | Feral Combat | 407995 | 1 | Talent gates the Forever Bear Primal Bite ability. |
| [`shifting_power`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L399) | Feral Combat | 1322605 | 1 | Registered only — effects not yet reviewed |
| [`natures_focus`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L401) | Restoration | 17063 | 5 | Registered only — effects not yet reviewed |
| [`heart_of_the_wild`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L402) | Restoration | 17003 | 5 | Registered only — effects not yet reviewed |
| [`improved_healing_touch`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L403) | Restoration | 17069 | 5 | Registered only — effects not yet reviewed |
| [`reflection`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L404) | Restoration | 17106 | 3 | Registered only — effects not yet reviewed |
| [`natural_shapeshifter`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L405) | Restoration | 16833 | 3 | Registered only — effects not yet reviewed |
| [`subtlety`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L406) | Restoration | 17118 | 3 | Registered only — effects not yet reviewed |
| [`gift_of_nature`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L407) | Restoration | 17104 | 5 | Registered only — effects not yet reviewed |
| [`bloom`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L408) | Restoration | 1328621 | 1 | Registered only — effects not yet reviewed |
| [`tranquil_spirit`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L409) | Restoration | 24968 | 5 | Registered only — effects not yet reviewed |
| [`improved_rejuvenation`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L410) | Restoration | 17111 | 3 | Registered only — effects not yet reviewed |
| [`swiftmend`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L411) | Restoration | 18562 | 1 | Registered only — effects not yet reviewed |
| [`natures_swiftness`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L412) | Restoration | 17116 | 1 | Registered only — effects not yet reviewed |
| [`living_spirit`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L413) | Restoration | 1309631 | 3 | Registered only — effects not yet reviewed |
| [`improved_tranquility`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L414) | Restoration | 17123 | 2 | Registered only — effects not yet reviewed |
| [`improved_regrowth`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L415) | Restoration | 17074 | 5 | Registered only — effects not yet reviewed |
| [`wild_growth`](https://github.com/zmsl/hekili/blob/8f95f2ea0a45428554c1e938ed7357b870030514/src/Hekili_Druid/Druid.lua#L416) | Restoration | 408120 | 1 | Registered only — effects not yet reviewed |

## Safe reuse

- Canonical data: class JSON; this Markdown is generated. Do not edit manually.
- Check native source, engine observations, level/rank and latest release before transferring mechanics to another spec.
- On upstream release changes: diff, review and explicitly re-pin; never overwrite v0.9.0 facts or copy Retail/Classic/SoD assumptions.
- Regenerate: python scripts/build_mechanics_reference.py --write. Validate: --check; optional pinned checkout: --source-root ../upstream/hekili.
- Research once → Preserve evidence (including failed tests) → Reuse after role-specific verification. No APL approval from this page.
