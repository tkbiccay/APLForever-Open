# Accuracy-first APL design under Forever's hidden combat state

**15 November 2026; source-pinned to official Hekili Forever v0.8.3** `74ec5150cf7e03174a7456af40216430c87b4881`; protected v0.8.2 comparator `cce44f491020662045943f638af2b88673d1c60b`. [Official wiki reference](official-wiki-v083.md) and [version update policy](wiki-update-policy.md). Applicability must be checked against the *currently tested* addon release.

## Objective and non-negotiable boundary

Maximise useful, correct, responsive **castable** recommendations within the current observer and evaluator, not apparent clairvoyance. A prediction is a hypothesis that the next observation may correct. The APL cannot read truly hidden current power, target health, fight length, private target auras or other unavailable WoW APIs. Do not invent a key or a bypass. Avoid increasing APL complexity without clear correctness, reliability, coverage or measurable gains.

## Prefer strong evidence before weak estimates

| Source | Strength and APL use | Cautions |
| --- | --- | --- |
| Known ability, cooldown, registered cost, user toggles, `action.<key>.in_range`, directly observed client usability | Check to avoid plainly unavailable recommendations; choose mechanics-proven reactive and priority lines first | A `.ready` forecast is still modelled, and a talent/stance may affect castability |
| Player-cast success, state transitions, recently observed reactive events | Use to confirm a recent ability, a cooldown/category lock, and re-evaluate on the next GCD | `prev.*` is forecast-aware; do not conflate predicted casts with observed ones |
| Registered CDM aura actually on an active bar; class-kit aura read | Prefer observed expiration/stack information for upkeep and proc lines | CDM only reads registered/bar-present values; aura `remains` may still be estimated |
| Belief power bounds `rage.lo`, `mana.pct_lo`, `energy.lo`, with `action.<key>.cost` | Safety-first affordability: `<resource>.lo>=action.<key>.cost` *when an extra guard is necessary*; catch free/proc-modified costs | The engine already schedules a line's resource cost/wait; a redundant fixed threshold may introduce avoidable delay |
| Range bracket `target.withinN` / `outsideN` / `rangeAtoB` | Steering hint only; combine with registered ability-specific range and availability if branch routing depends on range | If distance is unknown, **all bracket comparisons may be true** |
| `active_enemies`, cached debuffs, future procs, inferred regen and swing timings | Use when visible context or native testing supports predictions; use manual AoE modes appropriately | Nameplate counts can undercount and aura timers/cost regeneration may diverge from reality |
| `target.health.pct`, `fight_remains` / time-to-die | Do not gate critical damage/execute logic on unknown values | Target health may remain 100%; time-to-die may always be 3600. Use verified ability usability for execute windows instead |

## Practical design patterns to test

1. **Immediate reactive before expensive upkeep** when a 5-second proc (e.g. Revenge) is *observed* available, resource is sufficient, and the window can expire. Do not gate on speculative damage, TTD or an invented proc time. Ensure a stale `.ready` never survives a real expiry or disabled talent.
2. **Resource-conserving, not resource-paralysed.** For fillers/low-level levels, rely on the current engine's action cost/wait. Add `rage.lo` reserves for critical defensive or a near-ready spender only when a matched test proves benefit. Avoid constant percentage thresholds on an ability reduced to zero cost by a proc.
3. **Multi-action sequences and next-swing queueing.** Track real `buff.heroic_strike.up` / `buff.cleave.up`, cost/reserve and active cooldowns before issuing another queued next swing. The forecast needs state-advanced verification, not only a one-frame snapshot.
4. **Upkeep with uncertainty.** Prefer `up` / source-supported `refreshable` rather than sub-second `remains` to avoid flicker. Reapply a debuff only after the engine has believable evidence that it is missing or expiring; verify low-level debuff-stack handling and missed/avoided applications.
5. **Cooldown and defensive categories.** Explicit `toggle.cooldowns`, `toggle.minor_cooldowns` and `toggle.defensives`; avoid actions that a user has switched off. Some ability-level toggle requirements are enforced by Hekili itself and must be respected.
6. **Safe resource-starved endings.** Audit the *full reachable chain*, including post-upkeep and the final action. When no affordable cast exists, a legitimate wait/no-action is better than a repeated unusable or health-harming filler (DEMO-006). Require three decisions after **world state changes**; three identical polls do not count.
7. **Do not mistake display focus for action priority.** `focus=1` and `focus=2` affect Timeline presentation; list order and eligibility determine primary recommendations. Avoid line-order tricks based on undocumented display behaviour.

## Test matrix for promoting any new APL

A new revision is *proposed*, never silently substituted:
- **Matched comparator:** same addon version, build/talents/gear, scenario, seeds, latency, toggles, range and targets. Include shipped default and *exact* last-working version if present.
- **Normal and adversarial resource ranges:** 0/exact cost/just below/above, uncertain belief bounds, resource gain and depletion, free-cast cost modification, stale proc and newly observed proc.
- **Urgent state transitions:** cooldown opens/closes, reactive window expiring with insufficient resources, defensive OFF, repeated next-swing, one→multiple attackers and target resets, in-range/unknown/out-of-range.
- **After-upkeep repeated-fallback gate:** minimum 3 successful *state-advanced* decisions (or a documented justified wait), zero critical refusals and repeated inappropriate suggestions.
- **Reliability metrics:** unsupported/unknown actions, refused casts and reason, ready-while-short, held-while-ready, idle GCDs, stuck/no-action, flicker/minute, CPU/latency, threat/mitigation or survivability, and output where model is credible.
- **One change at a time:** compare behaviour after changed condition, keep verified rollback SHA, and stop when the observed issue is solved or engine limitation is documented. No gains claim within noise; use at least three matched seed sets when comparisons are noisy.
- **In-game gate:** player confirms the actual client's usability and behaviour through `/hekili snap`, including selected active pack, warnings/import log and several consecutive recommendations. Headless replay scores **cannot** approve a profile.

## Current Warrior Protection application

`Warrior_Protection` v1.0 has no claimed Approved status or reported-working rollback. The v0.8.3 test sprint `tests/native/aplforever_warrior_belief_spec.lua` examines Rage source/bounds vs truth, Sunder reapplication, natural Revenge expiry, next-swing/final progression and low Rage under several source-supported world configurations. **Until logs are reviewed, these are observations, not confirmed regressions or a revision trigger.** Protect v1.0's exact SHA-256 `e97acd14bdebf1fdc6d8c5b482814471cad7065bef30b4f14f48b07c4f6468e0`.

When a defect is confirmed, try the smallest source-verified APL change first; propose a complete `APL_Warrior_Protection_v1.1_Draft.txt` only after native compilation and fair world comparison. Otherwise retain the original and document what remained untested.

## Negative experiment: redundant `action.revenge.ready` guard

**15 November 2026, Source-native / Simulated; not in-game.** The [archived experimental PR #43]([private historical reference; not publicly accessible]), [native CI 43726119961]([private historical reference; not publicly accessible]), tested adding `if=action.revenge.ready` in-memory to all three Revenge lines of protected Warrior Protection v1.0. This is a *registered/documented* expression, but its forecast semantics did not supply a useful independent gating signal in these cases.

Three matched level-14 situations (low Rage with two attackers, no-white-swing starvation, moderate Rage) showed **exactly the same** accepted actions, actual Revenge casts, world refusals and late positive-wait Revenge icon counts with and without that guard: respectively 3 casts / 2 late polls, 0 / 3, and 1 / 0. Both variants had zero refused casts and errors. The experimental suite passed 71 native and 86 upstream checks. **Do not create a new APL revision for this guard.** A visible "ready" expression does not necessarily force an immediate, real-world readiness test when the engine forecasts future actions; the ability's castability is already enforced by the underlying engine. This result is limited to the three tested world scenarios and is not proof that the source model's expiry estimates are correct in-game.

**Reusable lesson:** before adding an extra `action.<key>.ready` or conservative threshold, isolate whether it changes the *first displayed icon*, accepted presses, refused casts, lost reactive windows, and time-to-act on the same state-advanced fixtures. If a change is inert, remove it; if it suppresses valid casts, reject it; if results are inconclusive, preserve the working baseline and inspect engine estimates rather than inventing more conditions.
