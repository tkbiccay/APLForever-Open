# Research — Hunter Beast Mastery DPS v1.1 (16 November 2026)

**Status:** Draft; source-native tested on **Hekili Forever v0.8.5**, not preferred, in-game validated or Approved. **Exact source pin:** [zmsl/hekili v0.8.5](https://github.com/zmsl/hekili/tree/a0a06583f458cca7a2ceaebb0b2ba0c4c783b946) commit `a0a06583f458cca7a2ceaebb0b2ba0c4c783b946`. Earlier source-native pins v0.8.2 `cce44f491020662045943f638af2b88673d1c60b` and v0.8.3 `74ec5150cf7e03174a7456af40216430c87b4881` do **not** register these new pet actions.

## Source-backed hypothesis and original design

- Existing exact [BM v1.0 archived Draft](../roles/Hunter/Archive/APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt) SHA-256 `8b552b6dd6fc9f0c4221e75242ef147c840242b3c03c3e2a75d46aedfe039eba` does not offer main companion Call Pet or Revive Pet. This is a **coverage omission**, not proof of failed gameplay.
- New [Hunter class registration](https://github.com/zmsl/hekili/blob/a0a06583f458cca7a2ceaebb0b2ba0c4c783b946/src/Hekili_Hunter/Hunter.lua#L1200-L1242) defines `call_pet` (883), `revive_pet` (982), learned/usable checks, and talent-scaled revival cast/Mana cost. `pet_out` explicitly queries a **living main pet** through UnitExists/UnitIsDead (lines 364–370). The registered `bestial_wrath` action itself refuses usage without a living pet (lines 662–679). `pet.hawk.count` is separate and refers to temporary Summon Hawk guardians.
- The [v0.8.5 shipped BM reference](https://github.com/zmsl/hekili/blob/a0a06583f458cca7a2ceaebb0b2ba0c4c783b946/src/Hekili_Hunter/APLs/Beast%20Mastery%20(wowsims.com).simc) uses `!pet_out&!pet.dead&!talent.lone_wolf.enabled` for Call Pet and `pet.dead` for Revive Pet in precombat and default. This is **mechanic evidence and comparator only**, not a requirement to adopt its broader rotational architecture.
- Source-native [Hunter pet experiment PR #58]([private historical reference; not publicly accessible]) observed baseline Aspect first with no/dead pet, versus Call/Revive first for shipped and an in-memory custom variant. Living, unusable and Lone Wolf states avoided inappropriate pet actions. These are **published icon decisions**, not accepted world casts.

The original BM custom ST/AoE/range/melee/major-cooldown structure remains intact. v1.1 adds precisely two actions at the start of **each** of precombat and default, and changes Bestial Wrath's `pet.up` condition to the explicit `pet_out` main companion state. This is a small, independent **pet readiness architecture fix** using the newly released source, not a rebuild of shipped priority. Other Hunter specs remain unchanged.

## Comparators, evidence and limitations

- **v1.0 Draft:** exact rollback, does not suggest Call Pet/Revive Pet under previously modelled missing/dead states.
- **v1.1 Draft:** source-backed pet actions in both lists and main-pet Bestial Wrath criterion; native import/compilation and first-icon comparisons passed ([PR #59]([private historical reference; not publicly accessible])).
- **Shipped v0.8.5:** offers Call/Revive under the same source-known guards; unmodified control in matched source-native tests. No proven higher or lower actual DPS.
- **Last reported-working/Approved:** none for Hunter BM. Never describe v1.0 as in-game working or auto-replace its rollback.

**Evidence quality:** source registration Confirmed; conditioned test icons Source-Native/Simulated; actual Call/Revive accepted cast, pet arrival/dead-to-alive transition, Lone Wolf game behaviour, low-level unlocks, repeated icons during loading, real Bestial Wrath readiness, range/target facing and full 1–60 final fallback **Not Run / Needs In-Game Validation**. The inherited default list may legitimately wait without a filler at some ranges/unlocks; full final/repeated fallback certification is not established. Do not invent a guard, auras, cast outcomes or DPS gains.

**Guide sweep:** this is a targeted v0.8.5 engine integration building on the prior BM v1.0 design and source-native test corpus. General Wowhead, Icy Veins, Maxroll and Mobalytics coverage was not independently re-established as **Forever v0.8.5** specific; no Retail/Classic/SoD mechanics have been imported to justify the change.

**Next gate:** obtain faithful source-native accepted pet press/state transition only if the current world supports it without fabricated pet mechanics; otherwise a minimal real-client `/hek snap` during missing/dead pet and after arrival, with talent/level/client usability and subsequent recommendations. Approval is separate and remains blocked.
