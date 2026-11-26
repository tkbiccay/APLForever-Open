# Breadth #29 — Combat Rogue solo Slice and Dice opportunity cost
26 November 2026 | [PR #109](https://github.com/tkbiccay/APLForever-Open/pull/109) | released Forever v0.11.0 86b739cbc4e6afbcbc693c3790ee81197fc6234b.

## Evidence and decision
[Final measured head native 6/6 PASS](https://github.com/tkbiccay/APLForever-Open/actions/runs/45725059121), job 139592687550, commit 86be8cbd54cc208ec04b2a1a92afcbcaa27efcd7; 25/25 returned workflows green, [repository validator](https://github.com/tkbiccay/APLForever-Open/actions/runs/45725059072). Earlier head 844da845bf7f40967e4384049ddbd75a5e851568 [native PASS](https://github.com/tkbiccay/APLForever-Open/actions/runs/45705804828). Final instrumentation records actual initial and first active press Energy and accepted post-stop actions. Evidence-only reconciliation commit requires its own exact-head CI. No new candidate, no preferred pointer, no APL bytes changed.

Three seeds 30417/30437/30461, 20/95 seconds, four whole profiles = 24 source worlds. Level 60 Combat source kit, 4yd, 1e9 target HP, configured/actual initial Energy 100; first active press shipped 85 at t3.2, all customs 70 at t3.4, Sinister Strike. Cooldowns/minor/defensives/interrupts/movement OFF. Shipped pinned pack versus Current v1.0 ff69f6d4baa3e74d054f8e96595993b5bd931e283e0b7a81cf1dd95a03b13218 and unselected v1.1 97f4b0a3514fa9c31b0710b97e85e283d78b31d76a69392f5aa0bc0f246748ca; experimental in-memory single guard adds solo eligibility at >=3 CP (boss/2+ guard retained). Exact candidate/Current files not changed. No reported working or preferred alternative in catalogue.

| Duration | Profile | Active accepted | SnD casts | SnD CP spent | SnD Energy cost | Buff seconds | Eviscerate attempts |
|---|---|---:|---:|---:|---:|---:|---:|
|20s|Shipped|12–13|1|1|25|3.2–3.8|1|
|20s|Current/v1.1|12–13|0|0|0|0|2–4|
|20s|Experimental|12–13|1|3|25|17.6–18.6|1–3|
|95s|Shipped|55–59|4–5|9–13|100–125|73.9–76.75|4|
|95s|Current/v1.1|57|0|0|0|0|12–14|
|95s|Experimental|53–60|3–4|9–12|75–100|65.25–66.65|7–10|

All 24 worlds zero raw refusals, all accepted experimental SnD casts granted/extended true aura and consumed real CP; 9–11/48–56 subsequent accepted non-SnD actions at 20/95s. Eviscerate counts displaced by 1 each short world and 3/4/5 across sustained matched seeds. Landed/consumed Eviscerates: experimental 1 each short, 6/6/7 sustained; existing customs 2 each short and 10 each sustained. Experimental first SnD t4.4–5.4 vs shipped t19.2–19.8. Zero raw refusal does not mean zero phase artefacts: accepted after-stop Stealth in two worlds each Current/v1.1, four experimental, none shipped. Excluded from active accepted count; retained in raw trace. No claim of safety across other starts; #28 terminal Garrote remains unresolved.

## Mechanism and limitations
Pinned [rogue_world.lua](https://github.com/zmsl/hekili/blob/86b739cbc4e6afbcbc693c3790ee81197fc6234b/tests/Forever/helpers/rogue_world.lua#L150) applies true SnD aura for (6+3*cp)*(1+0.15*Improved SnD rank); [behaviours.lua](https://github.com/zmsl/hekili/blob/86b739cbc4e6afbcbc693c3790ee81197fc6234b/tests/Game/harness/behaviours.lua#L56) uses fixed p.haste. All logged main/off swing speeds 2.6/1.8s; counts differ slightly with parry/RNG, not demonstrated buff-driven haste. No calibrated damage, actual short kill, dynamic attack speed, true client refresh/facing or levels 1–60 proof. The source-native tradeoff is real opportunity cost, not evidence that SnD reduces DPS. Reuse dated #25 guide research in [lesson 24](knowledge/CROSS_SPEC_LESSONS.md) (Forever Wowhead/Icy Veins/Mobalytics and WoWSims-derived pack); no fresh independent guide or published-release lookup in this reconciliation of unchanged source tests.

**Decision:** retain existing v1.1 unselected and protected Current unchanged. Do not publish experimental APL as superior. Compare real short/long solo pulls and attack cadence in game when available, log /hek snap and actual combat-end behaviour. Transfer method to other upkeep buffs only after independent effect-model verification. Next #30 Feral real point-cost versus finisher choice. #29 provisional until protected merge and required verification.
