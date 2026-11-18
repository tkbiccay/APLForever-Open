# Issue #30 cast progression results


## Guardian blocker resolved

The strict gate now passes **25/25 revisions** on the same 25-second seed 30417 after the test adapter calls the pinned engine's `ReviewPacks()`. All 14 previously failing revisions passed on rerun. The APLs and gate are identical. [Native CI 43649439995]([private historical reference; not publicly accessible]) verified 27 catalogue hashes and reported 29 successes, zero failures and zero errors. The earlier tables record the historical runs.

### Diagnosis

`UI/UI.lua` implements `ReviewPacks()`, which rebuilds active list and action caches. `Engine/Sim/Core.lua` checks `IsListActive` before walking a list. The test adapter replaced the stock lists after the headless boot and called `LoadScripts()` only. For both custom Guardian revisions, CI measured six inactive lists before the refresh: `cooldowns, damage, keep_up, mitigation, prebear, rage_dump`. The adapter now refreshes the cache through the upstream method and asserts every imported list is active. No engine or simulation changes were needed.

The [original 25-second comparison]([private historical reference; not publicly accessible]) placed the custom Roar on the final poll at world time 28.0, along with the world's stop event. It could not show a post-Roar stop. The [40-second diagnostic]([private historical reference; not publicly accessible]) showed both imports had no output at pull and still no output at 40.2 with 100 actual and estimated Rage, bear form, a living target and an expired GCD. Auto-attacks and Rage gains were present. The upstream pack continued casting in the same fixture. These observations isolate the original blockage to test initialization once combined with the cache check and successful rerun.

### Corrected Guardian comparison

Independent worlds used the same level-60 fixture, settings, seed and 25-second window. The untouched pack had 15 default entries and seven combat attempts. Both imports had seven default entries and five successful combat attempts each. None had a world refusal. After the swing at 3.8, both imports published and cast Roar. The end-of-tick world showed 1.25 Rage, bear form, the Roar debuff and a GCD through 5.3. At 4.0 the engine still published three records, with `damage:2` Primal Bite first and a four-second wait. At 6.2 a player swing raised actual Rage to 12.5 while Bite remained published with a 2.46-second wait. The driver attempts a press only when its first icon satisfies the upstream readiness threshold. Neither imported revision showed a post-Roar publication stop in this run.

| Role | Revision file | Combat attempts | First three accepted combat presses |
|---|---|---:|---|
| Warrior_Protection | APL_Warrior_Protection_Tank_v1.0_PendingInGame.txt | 8 | defensive_stance, blood_fury, shield_block |
| Druid_Guardian | APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt | 5 | demoralizing_roar, primal_bite, lacerate |
| Druid_Guardian | APL_Druid_Guardian_v1.1_Draft.txt | 5 | demoralizing_roar, primal_bite, lacerate |
| Warlock_Demonology | APL_Warlock_Demonology_DPS_v1.0_ReportedWorking.txt | 15 | searing_pain, bane_of_agony, immolate |
| Warlock_Demonology | APL_Warlock_Demonology_DPS_v0.8_Default.txt | 15 | curse_of_the_elements, bane_of_doom, searing_pain |
| Druid_Balance | APL_Druid_Balance_DPS_v1.0_Draft.txt | 10 | insect_swarm, moonfire, starfire |
| Druid_Feral | APL_Druid_Feral_DPS_v1.0_Draft.txt | 17 | shifting_power, claw, claw |
| Hunter_BeastMastery | APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt | 10 | rapid_fire, serpent_sting, summon_hawk |
| Hunter_Marksmanship | APL_Hunter_Marksmanship_DPS_v1.0_Draft.txt | 11 | rapid_fire, sniper_shot, serpent_sting |
| Hunter_Survival | APL_Hunter_Survival_DPS_v1.0_Draft.txt | 9 | strider_kick, summon_hawk, summon_hawk |
| Mage_Arcane | APL_Mage_Arcane_v1.0_Draft.txt | 13 | fire_blast, arcane_blast, arcane_missiles |
| Mage_Fire | APL_Mage_Fire_v1.0_Draft.txt | 12 | scorch, scorch, scorch |
| Mage_Frost | APL_Mage_Frost_v1.0_Draft.txt | 10 | frostbolt, frostbolt, frostbolt |
| Paladin_Protection | APL_Paladin_Protection_Tank_v1.0_Draft.txt | 15 | holy_shield, holy_strike, holy_shock |
| Paladin_Retribution | APL_Paladin_Retribution_v1.2_Draft.txt | 12 | holy_strike, exorcism, consecration |
| Priest_Shadow | APL_Priest_Shadow_v1.0_Draft.txt | 12 | inner_focus, devouring_plague, mind_flay |
| Rogue_Assassination | APL_Rogue_Assassination_v1.0_Draft.txt | 14 | eviscerate, sinister_strike, sinister_strike |
| Rogue_Combat | APL_Rogue_Combat_v1.0_Draft.txt | 16 | sinister_strike, eviscerate, sinister_strike |
| Rogue_Subtlety | APL_Rogue_Subtlety_v1.0_Draft.txt | 16 | ghostly_strike, eviscerate, hemorrhage |
| Shaman_Elemental | APL_Shaman_Elemental_v1.0_Draft.txt | 13 | flame_shock, lightning_bolt, lightning_bolt |
| Shaman_Enhancement | APL_Shaman_Enhancement_v1.0_Draft.txt | 14 | stormstrike, lightning_shield, earth_shock |
| Warlock_Affliction | APL_Warlock_Affliction_DPS_v1.0_Draft.txt | 9 | amplify_curse, bane_of_agony, corruption |
| Warlock_Destruction | APL_Warlock_Destruction_DPS_v1.0_Draft.txt | 14 | corruption, conflagrate, shadowburn |
| Warrior_Arms | APL_Warrior_Arms_DPS_v1.0_StaticValidated.txt | 4 | battle_shout, mortal_strike, spearing_strike |
| Warrior_Fury | APL_Warrior_Fury_DPS_v1.0_Draft.txt | 5 | berserker_stance, intercept, battle_shout |

Dedicated final fallback, Defensives OFF and queued Maul checks remain Not Run. The next Guardian regression should use the corrected independent worlds and the upstream Maul queue setup from `tests/Forever/loop_druid_spec.lua`, then verify the first action decisions through swing consumption.


## Diagnostic rerun

[Native run 43648455174]([private historical reference; not publicly accessible]) emitted all 25 fixtures and progression records before the gate. [Repository run 43648455202]([private historical reference; not publicly accessible]) passed. `PROGRESS_FIXTURE` contains the upstream pack and character inputs. `PROGRESS_DIAG` records the first published record and the world snapshot at the end of that tick, observed first-icon counts, first resolver result per attempted action, combat attempts, refusal totals and successful casts. Published ticks include precombat and can repeat an icon while the driver waits. The first world snapshot can already include that tick's cast effects.

| Role | Revision | Published ticks | Combat attempts | Successful combat casts | World refusals |
|---|---|---:|---:|---:|---|
| Warrior_Protection | v1.0 | 14 | 3 | 3 | None |
| Druid_Guardian | v1.0 | 2 | 1 | 1 | None |
| Druid_Guardian | v1.1 | 2 | 1 | 1 | None |
| Warlock_Demonology | v1.0 | 140 | 16 | 15 | {casting=1} |
| Warlock_Demonology | v0.8 | 140 | 15 | 15 | None |
| Druid_Balance | v1.0 | 1 | 1 | 1 | None |
| Druid_Feral | v1.0 | 1 | 1 | 1 | None |
| Hunter_BeastMastery | v1.0 | 140 | 9 | 9 | None |
| Hunter_Marksmanship | v1.0 | 10 | 1 | 1 | None |
| Hunter_Survival | v1.0 | 10 | 1 | 1 | None |
| Mage_Arcane | v1.0 | 140 | 13 | 13 | None |
| Mage_Fire | v1.0 | 140 | 12 | 12 | None |
| Mage_Frost | v1.0 | 10 | 1 | 1 | None |
| Paladin_Protection | v1.0 | 140 | 12 | 12 | None |
| Paladin_Retribution | v1.2 | 2 | 1 | 1 | None |
| Priest_Shadow | v1.0 | 140 | 10 | 10 | None |
| Rogue_Assassination | v1.0 | 1 | 1 | 1 | None |
| Rogue_Combat | v1.0 | 1 | 1 | 1 | None |
| Rogue_Subtlety | v1.0 | 1 | 1 | 1 | None |
| Shaman_Elemental | v1.0 | 103 | 3 | 3 | None |
| Shaman_Enhancement | v1.0 | 140 | 14 | 14 | None |
| Warlock_Affliction | v1.0 | 1 | 1 | 1 | None |
| Warlock_Destruction | v1.0 | 1 | 1 | 1 | None |
| Warrior_Arms | v1.0 | 125 | 4 | 4 | None |
| Warrior_Fury | v1.0 | 1 | 1 | 1 | None |

### Confirmed failure mode

All 14 failed revisions produced exactly one successful combat press, with zero world refusals. Each published at least one first icon, and each attempted action resolved through the stock fixture. No attempted action hit an unmapped-key error. The immediate gate failure is a shortage of published combat actions after the initial press. This run does not establish why the engine stopped publishing or whether an APL defect is involved.

| Failed fixtures | Last observed combat cast | Next source check |
|---|---|---|
| Guardian v1.0 and v1.1 | Demoralizing Roar | Compare bear-form and rage eligibility after Roar, including queued Maul. |
| Balance | Wrath | Inspect the post-cast target and caster eligibility before evaluating the next Wrath. |
| Feral | Rake | Inspect cat form, energy and the next eligible builder after Rake. |
| Marksmanship | Sniper Shot | Inspect ranged attack eligibility and the target after the shot. |
| Survival | Raptor Strike | Follow the next-swing queue through consumption, then check melee eligibility. |
| Frost | Frostbolt | Check cast completion and the next eligible Frostbolt. |
| Retribution v1.2 | Seal of Command | Inspect whether the seal registers and whether Judgement or the low-mana tail is eligible. |
| Assassination, Combat and Subtlety | Stealth | Check the observed stealth state and opener eligibility in each fixture. |
| Affliction | Shadow Bolt | Check cast completion and DoT eligibility on the next update. |
| Destruction | Immolate | Check the observed DoT and next filler eligibility. |
| Fury | Battle Shout | Check stance, available Rage and whether the drive receives the subsequent swing events. |

The narrow next experiment is to compare imported Guardian v1.0 and v1.1 against the same source-owned Guardian pack after the first Roar. Capture the next engine update's eligibility decisions and source world state before extending that setup to queued Maul. This rerun did not exercise the dedicated P0 regression scenarios.

The [native run]([private historical reference; not publicly accessible]) uses pinned Hekili Forever `246abf322ed53e3b7ab796ea7089c72329f3eb9d`. The [repository run]([private historical reference; not publicly accessible]) passed unit tests and integrity validation. See the native log for exact input hashes.

Hekili preallocates twelve recommendation tables in `src/Hekili/Engine/Output.lua`. Only slots through `output.count` are published. An empty slot beyond that count carries no recommendation and cannot be interpreted as a wait or a white swing. The importer smoke test already uses this count on main.

Each progression test installs the exact imported lists into the upstream fixture pack and uses the source `loop.run` and world press driver with seed 30417 for 25 seconds. A pass requires three successful combat presses and no engine errors. Failure means that the fixture did not satisfy this gate. It does not isolate an APL defect from fixture conditions or action coverage.

| Role | Revision | Native import | Simulated progression | First three successful combat presses | Final fallback | In-game |
|---|---|---|---|---|---|---|
| Warrior_Protection | v1.0 | Pass | Pass | defensive_stance, battle_shout, revenge | Not Run | Not Run |
| Druid_Guardian | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Druid_Guardian | v1.1 | Pass | Fail | See native log | Not Run | Not Run |
| Warlock_Demonology | v1.0 | Pass | Pass | immolate, corruption, searing_pain | Not Run | Not Run |
| Warlock_Demonology | v0.8 | Pass | Pass | curse_of_the_elements, bane_of_doom, searing_pain | Not Run | Not Run |
| Druid_Balance | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Druid_Feral | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Hunter_BeastMastery | v1.0 | Pass | Pass | serpent_sting, summon_hawk, aimed_shot | Not Run | Not Run |
| Hunter_Marksmanship | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Hunter_Survival | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Mage_Arcane | v1.0 | Pass | Pass | fire_blast, arcane_blast, arcane_missiles | Not Run | Not Run |
| Mage_Fire | v1.0 | Pass | Pass | scorch, scorch, scorch | Not Run | Not Run |
| Mage_Frost | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Paladin_Protection | v1.0 | Pass | Pass | holy_shield, holy_strike, holy_shock | Not Run | Not Run |
| Paladin_Retribution | v1.2 | Pass | Fail | See native log | Not Run | Not Run |
| Priest_Shadow | v1.0 | Pass | Pass | mind_flay, mind_blast, mind_flay | Not Run | Not Run |
| Rogue_Assassination | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Rogue_Combat | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Rogue_Subtlety | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Shaman_Elemental | v1.0 | Pass | Pass | flame_shock, chain_lightning, lightning_bolt | Not Run | Not Run |
| Shaman_Enhancement | v1.0 | Pass | Pass | stormstrike, lightning_shield, earth_shock | Not Run | Not Run |
| Warlock_Affliction | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Warlock_Destruction | v1.0 | Pass | Fail | See native log | Not Run | Not Run |
| Warrior_Arms | v1.0 | Pass | Pass | battle_shout, mortal_strike, spearing_strike | Not Run | Not Run |
| Warrior_Fury | v1.0 | Pass | Fail | See native log | Not Run | Not Run |

Scenario checks for Life Tap after DoTs, Sunder stacks and Revenge unlock, Guardian Roar/Maul and Defensives OFF, Elemental Clearcasting at low mana, Ret seals and the low-mana tail are **Not Run**. The general progression run also does not cover the requested talent, level, range, target, resource, cooldown or swing matrices.

Investigate the failed fixtures by recording the published action, its resolver result and the precise press refusal before changing any APL. For in-game comparison, record the exact revision, level, talents, toggles, target and resources. Use `/hek snap` after upkeep and capture three successive first-icon decisions alongside the casts actually accepted by the client.

