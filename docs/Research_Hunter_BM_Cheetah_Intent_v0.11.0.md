# Hunter BM Cheetah → Hawk source hypothesis — 20 Nov 2026

**Scope:** exact full BM v1.3 from protected main, source-native v0.11.0 `86b739cbc4e6afbcbc693c3790ee81197fc6234b`. This is an in-memory A/B **research experiment**, not a new APL or status selection.

**Original candidate combat issue:** both full v1.3 precombat and combat `aspect_of_the_hawk` actions require `!buff.aspect_of_the_cheetah.up`. When a player pulls with travel Cheetah up, the combat rule cannot switch to ranged-damage Aspect of the Hawk. Cheetah's registered Dazed aura can punish being hit. However deliberately fleeing with Cheetah is legitimate user intent; forcing Hawk while moving can be undesirable.

**Proposed in-memory condition ONLY for default list:** require Hawk absent; switch if neither Cheetah nor Beast is up, *or* actually in combat while stationary (`combat>0&!moving`). Preserve original precombat/travel guard and all other actions. It must not overwrite a moving combat escape. No shared APL file, invented API reads or pet HP. Source [Hunter.lua](https://github.com/zmsl/hekili/blob/v0.11.0/src/Hekili_Hunter/Hunter.lua) registers Cheetah (spell 5118, 3600s aura), Hawk, exclusive aspects and Dazed (15571); released [fake_api.lua](https://github.com/zmsl/hekili/blob/v0.11.0/tests/Game/State/helpers/fake_api.lua) provides client aura, combat and movement events. **Caveat:** actual aura state in dungeons may be hidden/estimated and headless fake client state is not an in-game player's intention.

**Decision gate:** exact v1.3 and test-only full-source one-line variant must import, client-source Cheetah aura must be confirmed **before** claiming any recommendation, default must abstain and variant should suggest Hawk while stationary in combat but preserve Cheetah while moving/in precombat. Green means only a source-observable static-client opportunity; actual cast/priority progression, deliberately fleeing, melee/target range, resource cost and real game still need proof before a stored v1.4. Red identifies unsupported aura or movement semantics and blocks promotion. No new APL or catalogue changes here.

**Initial state:** Unrun, cannot claim improvement.
