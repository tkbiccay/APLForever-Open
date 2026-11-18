# v0.8.2 testing baselines

[Download the verified ZIP artifact]([private historical reference; not publicly accessible]). The bundle was built at APLForever commit `8633e7d` after native verification. [Repository validation]([private historical reference; not publicly accessible])

These 23 independent profiles are available for cautious testing. Every selection retains its catalogue status. In-game validation and approval are separate gates. No APL changes are included.

The release pin is `cce44f491020662045943f638af2b88673d1c60b`. The [original v0.8.2 run]([private historical reference; not publicly accessible]) passed native import, compilation and three successful combat presses for all 25 selected revisions, including each file below. That exercise does not establish final fallback safety, all unlock ranges or comparative performance.

Download the bundle from the successful native Actions run, or run `python scripts/build_testing_bundle.py --output APLForever_Testing_Baselines_v0.8.2.zip` from the repository root. Extract it before importing. Back up the current profile, paste the complete selected text into Hekili's priority importer, use the canonical name shown below, and select the profile for that specialization. Restore the backed-up profile or available working copy if behavior regresses.

Guardian and Demonology use their reported-working baseline. For Demonology verify `settings.assigned_curse`; the old Life Tap incident remains pending live retest. Retribution v1.2 requires manual Blessing upkeep. Elemental's Clearcasting and Mana floors remain a specific test risk. Maintain the previous profile as rollback for every role without a recorded working revision. Include build, level, talents, toggles and /hek snap when reporting a problem.

| Import name | Role | Testing revision | Catalogue status | Exact SHA-256 | Rollback | First in-game checkpoint |
|---|---|---|---|---|---|---|
| `Druid_Balance` | DPS | [v1.0](../roles/Druid/Current/APL_Druid_Balance_DPS_v1.0_Draft.txt) | Draft | `1cf83328f343e20a8efc93ed06645e862979e8d2f8bfce79acdcfcbedc55c1c2` | Restore prior profile | Eclipse and low Mana |
| `Druid_Feral` | DPS | [v1.0](../roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt) | Draft | `f2f72d0621c8e709c7df8f2ccff248ce0af604a1c02e115a5ad725cf93d288f1` | Restore prior profile | Form changes and Energy |
| `Druid_Guardian` | Tank | [v1.0](../roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt) | ReportedWorking | `f386e158a5e262e309dac7d0fd2929fb8e16e02b1378d71b5956c1bf6b99a786` | [Same revision](../roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt) | Defensives OFF and queued Maul |
| `Hunter_BeastMastery` | DPS | [v1.0](../roles/Hunter/Archive/APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt) | Draft | `8b552b6dd6fc9f0c4221e75242ef147c840242b3c03c3e2a75d46aedfe039eba` | Restore prior profile | Pet and ranged dead zone |
| `Hunter_Marksmanship` | DPS | [v1.0](../roles/Hunter/Current/APL_Hunter_Marksmanship_DPS_v1.0_Draft.txt) | Draft | `43c78f4517f260e54d59cb2bac06f7464bdc78306d1df6a2977b4366c335bc9a` | Restore prior profile | Auto Shot timing and range |
| `Hunter_Survival` | DPS | [v1.0](../roles/Hunter/Current/APL_Hunter_Survival_DPS_v1.0_Draft.txt) | Draft | `e58fe21c311c90d49c7cac8424f369ff08199d5c6cb35adbab2a03374ae7b12c` | Restore prior profile | Melee weaving and range |
| `Mage_Arcane` | DPS | [v1.0](../roles/Mage/Current/APL_Mage_Arcane_v1.0_Draft.txt) | Draft | `d89600259308d74e56dc96decd2af9a27c60d561d90fe2cca1a2ed15b359a036` | Restore prior profile | Clearcasting and low Mana |
| `Mage_Fire` | DPS | [v1.0](../roles/Mage/Current/APL_Mage_Fire_v1.0_Draft.txt) | Draft | `500a40752f3f3c1ec125262ce243996c1fb69b3da8a91af5c59ca6c3d165982a` | Restore prior profile | Instant procs and movement |
| `Mage_Frost` | DPS | [v1.0](../roles/Mage/Current/APL_Mage_Frost_v1.0_Draft.txt) | Draft | `f05a17a34b9d13238d6594e27f4fa7994cf2ce9eae5c4e5916ecc7dc0decbd22` | Restore prior profile | Fingers of Frost and movement |
| `Paladin_Protection` | Tank | [v1.0](../roles/Paladin/Current/APL_Paladin_Protection_Tank_v1.0_Draft.txt) | Draft | `8f1ba35a46634b615ce42d3983a6ace740da499bd96cb91b5470a850159a9690` | Restore prior profile | Exorcism eligibility and defensives |
| `Paladin_Retribution` | DPS | [v1.2](../roles/Paladin/Current/APL_Paladin_Retribution_v1.2_Draft.txt) | Draft | `d5a05302c341bbbcb7a69157a40d0a4ae2df8504ce40838e03407515e4e4731b` | Restore prior profile | Manual Blessing, seals and low Mana |
| `Priest_Shadow` | DPS | [v1.0](../roles/Priest/Current/APL_Priest_Shadow_v1.0_Draft.txt) | Draft | `66ee308453ae07c1e2c77b5f82e414e61abbd5f2099d21a252448174be7eec79` | Restore prior profile | Mind Flay and wand fallback |
| `Rogue_Assassination` | DPS | [v1.0](../roles/Rogue/Current/APL_Rogue_Assassination_v1.0_Draft.txt) | Draft | `f817fe4ab906e82c3244a886457216822824c2598cd53cbf619610b4709ee4e0` | Restore prior profile | Stealth opener and Energy |
| `Rogue_Combat` | DPS | [v1.0](../roles/Rogue/Current/APL_Rogue_Combat_v1.0_Draft.txt) | Draft | `ff69f6d4baa3e74d054f8e96595993b5bd931e283e0b7a81cf1dd95a03b13218` | Restore prior profile | Energy and cooldown reset |
| `Rogue_Subtlety` | DPS | [v1.0](../roles/Rogue/Current/APL_Rogue_Subtlety_v1.0_Draft.txt) | Draft | `3d5fa90ecfd4a9d1f57fa8c73f6cb6f72a7bf8dff48577285125af16433ff77e` | Restore prior profile | Stealth and finisher fallback |
| `Shaman_Elemental` | DPS | [v1.0](../roles/Shaman/Current/APL_Shaman_Elemental_v1.0_Draft.txt) | Draft | `fd19fe1d83d996be6b3d65a47ef374957e21deb154722a61e31f4cadacebe915` | Restore prior profile | Clearcasting and free Chain Lightning |
| `Shaman_Enhancement` | DPS | [v1.0](../roles/Shaman/Current/APL_Shaman_Enhancement_v1.0_Draft.txt) | Draft | `76c3ed75a4b01ebe18980104261bcd5589b48924fcaef87a3ed356f00de6ab35` | Restore prior profile | Totems, imbues and queues |
| `Warlock_Affliction` | DPS | [v1.0](../roles/Warlock/Current/APL_Warlock_Affliction_DPS_v1.0_Draft.txt) | Draft | `65c664533b6918db6e0b1b4bd2c1e360edf56c2bcd647511c63dbd3cd4437c6d` | Restore prior profile | DoT upkeep and health-cost recovery |
| `Warlock_Demonology` | DPS | [v1.0](../roles/Warlock/Current/APL_Warlock_Demonology_DPS_v1.0_ReportedWorking.txt) | ReportedWorking | `067ae757344a71f4a0d02f0a18e2f36745ceb8c0015761970948381aba8e7bf7` | [Same revision](../roles/Warlock/Current/APL_Warlock_Demonology_DPS_v1.0_ReportedWorking.txt) | DEMO-006 after both DoTs |
| `Warlock_Destruction` | DPS | [v1.0](../roles/Warlock/Current/APL_Warlock_Destruction_DPS_v1.0_Draft.txt) | Draft | `560235675b9882a40a4fee90fdc729f4f55536222c8277a4ffc5649b68bb6ac0` | Restore prior profile | Resource and proc fallback |
| `Warrior_Arms` | DPS | [v1.0](../roles/Warrior/Current/APL_Warrior_Arms_DPS_v1.0_StaticValidated.txt) | StaticValidated | `3bb923e9b071a3d9432471731ce609a3e8852741364ce4334d136e4509335f2c` | Restore prior profile | Stance and swing queue |
| `Warrior_Fury` | DPS | [v1.0](../roles/Warrior/Current/APL_Warrior_Fury_DPS_v1.0_Draft.txt) | Draft | `bff9e4ecfac234f58d7057f47c1c1c4ef047f8d98f9018c506530d143e5d5b23` | Restore prior profile | Interrupt visibility and queued attacks |
| `Warrior_Protection` | Tank | [v1.0](../roles/Warrior/Current/APL_Warrior_Protection_Tank_v1.0_PendingInGame.txt) | PendingInGame | `e97acd14bdebf1fdc6d8c5b482814471cad7065bef30b4f14f48b07c4f6468e0` | Restore prior profile | Low-Rage tail and unused Revenge expiry |

The Retribution manifest records v1.1 as the historical rollback reference for v1.2. That archived revision has a known unsupported Blessing import and is unsuitable as a testing rollback. Restore your previous in-game profile instead.

## Blocked healer roles

Druid Restoration, Paladin Holy, Priest Discipline, Priest Holy and Shaman Restoration have no supported testing profile. The current scope lacks a verified primary healing and friendly-target recommendation path for these roles. See [role scope](SPEC_ROLE_SCOPE.md). The ZIP manifest includes all existing revision references and per-role catalogue limitations.

## Elemental Clearcasting P0

**Static:** v0.8.2 registers Clearcasting 16246 as a one-charge aura; the pinned Shaman world resolver prices Chain Lightning at zero with this aura. The imported v1.0 APL has independent percentage guards at 35% in the single-target Clearcasting entry and 30% in the AoE entry. Those guards would exclude otherwise eligible free Chain Lightning below the thresholds. This identifies a branch restriction, but does not show that removing it improves the full combat decision.

**Simulated, inconclusive attribution:** A matched level-60 single-target setup on seed 30417 used 20% starting world Mana, major and defensive toggles OFF, and an explicit world aura seed for Clearcasting and Flame Shock. At 3.2 seconds, the custom fixture held one charge and priced Chain Lightning at zero, but actual Mana was 1046.68 while the engine belief was 5478.13. The seeded Flame Shock did not prevent the engine from publishing Flame Shock first. Both packs pressed Flame Shock at 4.2, and the world charge then disappeared. The resolver priced Chain Lightning at 445.5 afterwards. The custom world had a Mana debit on the shock, whereas shipped did not in that poll. This run did not align observed upkeep and Mana belief with world truth, so the absence of Chain Lightning cannot be attributed to the 35% guard alone. No Chain Lightning cast or charge consumption by Chain Lightning was observed. [Native evidence]([private historical reference; not publicly accessible])

The custom pack accepted Lightning Bolt from `final_fallback:1` at 5.8, 7.8 and 9.8 seconds, with post-poll Mana 713.668, 567.928 and 422.188, and no world refusals. This is an observed filler sequence. Forced unaffordable Lightning Bolt, the Earth Shock tail, AoE and low-level scenarios remain **Not Run**. No candidate revision was created. The smallest follow-up is to seed the registered proc only after the engine observes real Flame Shock upkeep and its Mana lower bound falls below the threshold, then compare that decision with the shipped pack.

