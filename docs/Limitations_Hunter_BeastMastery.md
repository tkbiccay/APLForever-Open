# Limitations — Hunter Beast Mastery

**19 November 2026 | pinned release v0.9.0**

- **Draft only:** neither Current v1.1 nor Candidate v1.2 is a proven working/preferred/Approved APL. No honest live-player comparison or DPS claim yet.
- **Summon Hawk:** source Belief models two 18-second guardians but does **not directly observe spawned Hawk entities**, confirm their damage or guarantee their real duration. The source-world 0–35yd range and accepted cast are not confirmation of 6yd gameplay DPS.
- **Main pet:** source headless first-icon test can offer Call/Revive but cannot model real accepted recovery and pet appearance; retain user-triggered `/hek snap` checkpoint.
- **Mana:** source true costs and 5s regen model only bounded level-60 fixture; 1–60 rank boundary and extreme resources not exhaustively validated.
- **Six-yard dead zone:** source Turret scenario moves the target but white Auto Shot scripting still behaves as a ranged Turret; cannot infer real Auto Shot clipping/suppression. Only spell presses/refusals and the modelled guardian cap are verified.
- **Toggles:** source cooldowns toggle is verified under released native tests, not complete game-facing interrupt, potion, defensive, movement, item or trinket coverage. Do not invent unsupported selectors.
- **Lone Wolf, swaps and melee:** v1.2 reuses Current source-reviewed guards; practical off-switch, facing/terrain and swing timing need actual gameplay evidence.
- **Fallback checkpoint:** limited three real state-advanced post-low-Mana samples, not all possible fallback branches or repeated recommendation behaviours.
- **Rollbacks:** original v1.0 and v1.1 untouched; no human-reported working BM rollback exists. Guardian v1.0 remains separate reported-working reference.

See [v1.2 research](Research_Hunter_BeastMastery_v1.2.md) and [v1.2 native test ledger](Tests_Hunter_BeastMastery_v1.2.md). Reuse confirmed mechanics; never convert an unknown into a made-up guarantee.


## 20 November 2026 — v0.11.0 BM pet-health and source-native decision

**Confirmed engine limitation — not a player-tested bug.** In published Hekili Forever **v0.11.0** at `86b739cbc4e6afbcbc693c3790ee81197fc6234b`, [`src/Hekili/Game/State/Families/Player.lua`](https://github.com/zmsl/hekili/blob/v0.11.0/src/Hekili/Game/State/Families/Player.lua) implements `VS.Health(unit, now)`: `player` uses the player belief, `target` uses target health, and **every other unit (including `pet`) returns `otherHealth` with default fraction 1.0**. [`src/Hekili/Game/State/Families/Pets.lua`](https://github.com/zmsl/hekili/blob/v0.11.0/src/Hekili/Game/State/Families/Pets.lua) separately observes **pet existence, death and power**, not health. The [v0.11.0 Hunter class registration](https://github.com/zmsl/hekili/blob/v0.11.0/src/Hekili_Hunter/Hunter.lua) provides `mend_pet` as a **5-second channeled Mana-consuming spell**, but does not expose a true pet-health trigger.

**APL decision:** Do **not** append `mend_pet,if=pet.health.pct<...` or a periodic blind heal to BM. The first guard uses an unobserved fixed value and would be dead; the second can waste a channel and Mana or interrupt damage. Mark **Mend Pet manual / Engine Limitation** until the current released APL engine truly exposes a safe pet-health or equivalent verified eligibility observation. This is a deliberate, documented boundary of *fully standalone where the engine permits* — not a manual checkbox prerequisite for routine DPS or pet recovery. Do not misstate `pet_out` (alive main pet) or `pet.hawk.count` (modelled guardians) as pet health.

**Current-source scoped evidence:** [v0.11.0 source-native Guardian/BM run 44777104862](https://github.com/tkbiccay/APLForever-Open/actions/runs/44777104862) **PASS** for its exact P0 cases. [Required repository validation 44777104555](https://github.com/tkbiccay/APLForever-Open/actions/runs/44777104555) **PASS** after separately pinning historical v0.10.0 evidence. This is not a BM live gameplay result or full 23-role release approval. BM v1.1/v1.2 stay unchanged, `preferred_apl=null`.

**Minimal real-client gate:** On a safe level-appropriate enemy, after backing up the existing active pack, import the complete [BM v1.2 Draft](../roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.2_Draft.txt) separately. Observe (a) absent pet → actual successful Call Pet → living pet and three subsequent actual recommendation/cast transitions; (b) naturally dead pet → Revive Pet → actual living pet and next three transitions, only if safe/available; (c) at ~6–8 yd, source-legal Hawk without repeatedly refused 8-yard shots. Record installed addon build, level, gear/talents, options, expected/actual, and `/hek snap` on a bad icon. Do not manufacture pet deaths, claim simulation shows pet arrival or publicise unredacted personal diagnostic content. On a material regression restore the prior active pack; no Draft promotion.

**Cross-role transfer:** Hunter Marksmanship/Survival and other pet-reliant roles may reuse this source-state limitation as a **test/research rule** after confirming applicability. No shared runtime code, invented health proxy or bulk APL rewrite.
