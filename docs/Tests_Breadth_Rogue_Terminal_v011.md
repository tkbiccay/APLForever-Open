# Breadth #28 — Combat Rogue actual stop event / raw Garrote refusal
25 November 2026 | [PR #108](https://github.com/tkbiccay/APLForever-Open/pull/108) | source v0.11.0 86b739cbc4e6afbcbc693c3790ee81197fc6234b. [Native first-head 6/6 PASS](https://github.com/tkbiccay/APLForever-Open/actions/runs/45584530560), job 139102638458, 8cf31a5601b59adf4502b2da41e7e14b9b320d7c. All 25 returned workflows passed at that head. New explicit initial-resource-truth instrumentation added after this result; fresh final-head CI required. No APL changes or promotions.

## Method and pins
Full shipped default (pinned release pack), protected Combat Current v1.0 (ff69f6d4baa3e74d054f8e96595993b5bd931e283e0b7a81cf1dd95a03b13218), and saved unselected v1.1 (97f4b0a3514fa9c31b0710b97e85e283d78b31d76a69392f5aa0bc0f246748ca). Catalogue preferred/last-working null; no reported-working alternative. Source level-60 pack, 4yd, 1e9 target HP, Major/Minor/Defensives/Interrupts/Movement OFF. Seeds 30437/30417; 94.8/95/95.2s stop shifts and 20/95s full-pool controls; 18 complete worlds. Configured 25%/100% initial pool is NOT guaranteed Energy at pull: first Current refusal in configured-25% cases was at t3 with **true Energy 90**. Subsequent instrumentation asserts world initial power0 against configured pool and logs first attempt Energy/time. Do not claim true low-Energy-at-press validation or suppress the earlier raw observations.

## Actual observed counts (first tested head)
| Seed / duration / configured pool | Shipped active accepted / raw refuses | Current active accepted / active refuses / after-stop refuses | Candidate active accepted / active refuses / after-stop refuses |
|---|---|---|---|
|30437 / 94.8s / 25%|54/0|0/474/1|56/0/0|
|30437 / 95s / 25%|54/0|0/475/1|56/0/1|
|30437 / 95.2s / 25%|54/0|0/476/1|57/0/0|
|30417 / 95s / 25%|49/0|0/475/1|59/0/0|
|30437 / 95s / 100%|59/0|57/0/0|57/0/0|
|30437 / 20s / 100%|13/0|13/0/0|13/0/0|

Candidate's historical raw Garrote refusal reproduced at t98.000, actual stop=98, stopped=true, recommendation icon Garrote, reason requires:not stealthed, no actual stealth/vanish/ghostly aura, true Energy 72, CP2. Shift stop by ±0.2s and candidate refusal is absent; Current continues active refused tail in all configured-25% worlds. Zero accepted actions after stop for all profiles. Candidate 55–58 genuine later offensive accepted actions in configured-25% worlds; Current zero. No raw rejection dropped: count equals native rr.refused sum. Full pool parity Current/candidate, shipped slightly higher sustained accepted actions. Not DPS.

## Source classification and boundaries
[scenarios.lua](https://github.com/zmsl/hekili/blob/86b739cbc4e6afbcbc693c3790ee81197fc6234b/tests/Game/harness/scenarios.lua#L325) emits stop and sets stopped before final press. [observer.lua](https://github.com/zmsl/hekili/blob/86b739cbc4e6afbcbc693c3790ee81197fc6234b/tests/Game/harness/observer.lua#L572) makes combat false and sends PLAYER_REGEN_ENABLED. [loop.lua](https://github.com/zmsl/hekili/blob/86b739cbc4e6afbcbc693c3790ee81197fc6234b/tests/Game/harness/loop.lua#L593) advances world then cycles recommendation, and uses t>=pull as its inCombat accounting criterion even at stop. [rogue_world.lua](https://github.com/zmsl/hekili/blob/86b739cbc4e6afbcbc693c3790ee81197fc6234b/tests/Forever/helpers/rogue_world.lua#L132) requires real stealth/vanish/ghostly aura to accept Garrote.
**Confirmed fixture boundary classification**, not proof of the exact stale belief mechanism or real client equivalence. The one candidate terminal refusal is retained as unresolved, not waived. Real post-combat stealth, UI flicker, poison, target swaps, levels 1–60, DPS and ordinary short-mob kill remain unverified. No new APL syntax or design; reuse #25 Forever research, [prior report](Tests_Breadth_Frost_FoF_Rogue_Combo_v011.md); no fresh guide audit required for unchanged mechanics instrumentation. CurseForge file listing confirms v0.11.0 latest as of review; GitHub latest endpoint unavailable.

## Final fallback and decision
Current fails repeated uncastable Garrote during active combat in configured-25% controls. Candidate is significantly safer in this scoped native setting but still unselected Draft/Needs Retest; no formal approval and no preferred pointer change. Keep exact Current/rollback bytes. Next test natural live post-fight and next pull with /hek snap if incorrect. Independently evaluate solo Slice and Dice tradeoff (#29) only using observable effects, and rotate to P0 Guardian/BM and Feral. No count for #28 until final exact-head green, owner-reviewed protected merge and required verification.
