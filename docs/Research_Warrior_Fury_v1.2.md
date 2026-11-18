# Warrior Fury v1.2 — source-native Rage reliability research

**17 November 2026. Status: Draft Candidate; not selected, not Approved.**

## Verified baseline and sources

- Released **Hekili Forever v0.8.6**, exact upstream commit **2e9cb6a78d9088007e9acd9cce3eeb0e91463cc5** (zmsl/hekili); inspect the tagged Warrior.lua, tests/Forever/helpers/warrior_world.lua, tests/Game/harness/loop.lua, and tests/Game/harness/world.lua. Shipped comparison is **Fury (wowsims.com)** from this release, not a Retail/Classic/SoD proxy.
- Protected selected Current: roles/Warrior/Current/APL_Warrior_Fury_DPS_v1.0_Draft.txt; SHA256 bff9e4ecfac234f58d7057f47c1c1c4ef047f8d98f9018c506530d143e5d5b23. Exact byte, **Draft, NOT proven working**.
- Source-verified failed revision archived: roles/Warrior/Archive/APL_Warrior_Fury_v1.1_Draft.txt; SHA256 4c18938e392f8b4e785fda079b11a2f8e3dd41b850fe8e2e149ad1d8c264a2ff. Its Movement guards work, but its L60 two-attacker Bloodthirst Rage gate source-refused four times.
- New **complete standalone 6,293-byte v1.2**: roles/Warrior/Candidates/APL_Warrior_Fury_v1.2_Draft.txt; SHA256 **7280a021e796bfe97112e3b091e34e234348ead476305ef6a57856524ddf84d3**. Exact full v1.1 copy except two Bloodthirst lines in AoE and ST now require **rage.lo >= action.bloodthirst.cost + 5**. All three precombat/engage Movement guards, existing priority, item handling, defensives, cooldowns, stances, and **entire final fallback** remain unchanged. The running APL needs no shared role-level runtime file.

Forever-specific guides checked for broader rotation context only: [Wowhead Fury overview](https://www.wowhead.com/forever/guide/classes/warrior/fury/overview-pve-dps), [Icy Veins Fury guide](https://www.icy-veins.com/wow-forever/fury-warrior-melee-dps-pve-guide/), [Mobalytics Fury 1–60 guide](https://mobalytics.gg/wow-forever/classes/fury-warrior-guide-1-60-talents-rotations-and-more-ludideo), and tagged WoWSims translation. **Maxroll Forever Fury coverage could not be verified**, so no Retail substitution.

## Observed root causes versus hypotheses

1. **MOVE-017 verified:** unchanged v1.0 and shipped each source-accepted Charge and Intercept at legitimate **12yd** while Movement OFF. Source-native 8–25yd Charge/Intercept bounds are from independent, unofficial Forever spellbook exports (questing.wiki and The Overcity), applied explicitly to the fake client and true world only. The actual player's spellbook remains untested.
2. **MOVE-018 source harness cause confirmed:** earlier false OFF-safe/ON-blocked candidate readings arose because tagged tests/Game/harness/loop.lua forces movement.value=(R~=nil) for every driver. Thus non-replay worlds overwrite requested Movement ON. Our dedicated fixture re-applies ON/OFF after this **test-only** reset. This is not a production addon Movement bug.
3. **RAGE-019 observed:** archived v1.1 first-icon Bloodthirst was source-refused at t=22.2, 22.4, 22.6 sec with true Rage 28.5345, and at 37.8 sec with Rage 29.5865, against actual Bloodthirst cost 30. Three adjacent 0.2-second unsuccessful recommendations create a *repeated refused action* fault even though the three-hostile-swing fallback counter remained zero. Post-decision VirtualState low Rage approximately 25 is not an evaluator-time oracle. **Exact forecast/cast mismatch cause remains unconfirmed.**
4. **Targeted candidate v1.2 hypothesis:** add only **5 Rage** Bloodthirst headroom in both AoE and ST rather than blindly rewriting priority or trusting exact hidden Rage. This clears the matched seed but is **not proof that any unknown real-game forecast error will stay within 5 Rage**. Complexity budget: no extra branches or settings.

## Constraints and remaining uncertainty

Native worlds use a real Fury dual-wield class/trainer/talent cut, but low levels inherit high-level one-hand gear. Enemy counts and damage do not prove in-game multi-target Whirlwind output; Bloodrage health cost is not modelled. Source shows actual accepted casts and next-swing spending but not player client positioning, threat, target health secrecy or real in-game cooldown display. A true Movement toggle UI on Warrior (NewClass lacks Druid's movement=true opt-in), correct in-game 8–25yd range, player resource accuracy and /hek snap still need evidence.

**Decision:** v1.2 stays **Draft**, Current stays v1.0, no Approved/ReportedWorking/CheckPoint claim. See [v1.2 tests](Tests_Warrior_Fury_v1.2.md) and [v1.0/v1.1 baseline](Tests_Warrior_Fury_v1.0.md). In-game reliability and a fair default plus Current comparison are required before promotion.
