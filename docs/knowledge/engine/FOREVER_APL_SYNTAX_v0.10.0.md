# Hekili Forever APL syntax — source-pinned practical reference

**20 November 2026; official Hekili Forever v0.10.0**, published upstream commit `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`. APLForever's *development-time* reference, **not a shared APL runtime dependency**. For latest status on new releases check `docs/knowledge/engine/current-release.json` and re-read source changes. Never claim a documented expression is an actual positive source-world or in-game cast without a focused test.

Primary official references:
- [Forever differences from SimC and Retail Hekili](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Forever-Differences.md)
- [Forever conditions: Read / Estimated / Limited / Fixed](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Conditions-On-Forever.md)
- [Expression reference](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Expression-Reference.md)
- [Syntax reference (operators, variables, call/run)](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Syntax-Reference.md)
- [APL line options](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Line-Options.md)
- [Rotation windows and sequences](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Windows.md)
- [Toggles / Require Toggle](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/Toggles.md)
- [Pack settings (registered values, not custom code)](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/Pack-Settings.md)

## Truly Forever-specific additions or changed semantics

| Syntax | Meaning | Priority / traps |
| --- | --- | --- |
| `mana.lo`, `rage.lo`, `energy.lo`, `<resource>.hi`, `<resource>.pct_lo` | Low/high bounds around Forever Belief's hidden-resource estimate; percent only for low end | High. For affordable costs use `<resource>.lo>=action.<key>.cost`; lower bound is still only belief, not an infallible live observation. `<resource>.pct_hi` **does not exist**. |
| `energy.lo>=N` (and `<resource>.pct_lo>=N`) | Special comparison can forecast a wait until resource is available | High. Reverse `<=` is checked at each time step; avoid unnecessary resource pooling. |
| `window.<name>.up`, `.down`, `.remains`, `.elapsed`, `.step`, `.next.<ability>` | Engine or user-APL declared temporal/stepped rotation window | High for a *verified* registered name, or a window declared in the same APL. Extra sequence state `window.<name>.done` is documented for completed plain sequences. |
| `actions.windows+=/window,name=burst,duration=12` | Declare a window locally in the **reserved** windows list | High only with a demonstrated multi-step benefit. Options: `duration` (or `combat`), `refresh`, `max_refresh`, `max_duration`, `reset_on_target_change`. No `if=` on declaration. |
| `actions+=/open_window,name=burst,if=...`, `close_window` | Mutate APL window for this evaluation, potentially restart list walk | Experimental. A condition that remains true may repeatedly open/refresh; contradictory open+close can cause restart warnings. These lines take **only** `name` and `if`. |
| `focus=1` / `focus=2` | Timeline focus tier, 1 highest | Presentation only, **not** ordinary action priority override. |
| `label=<text>`, `label_if=...`, `icon=<texture>`, `icon_if=...` | Conditional recommendation presentation | Presentation only; do not confuse with actual cast timing. |
| `other_target=1` | Only consider an action on a non-current target | Needs actual count and target swap ability. |
| `toggle.movement` | Forever-specific native Movement toggle | Treat as optional off-switch; no button/config dependency for normal rotation. |
| `buff.<aura>.icd_ready`, `.icd_remains` | Estimated proc internal cooldown when registered by the class pack | High only if the class has a verified registered ICD. |
| `target.within5`, `target.outside8`, `target.range8to25` | Forever target-distance brackets inferred from tracked spell ranges | **All may be true when range is unknown**. Need actual `action.<key>.in_range`/cast eligibility where possible. `target.is_boss` may be false for dungeon/raid bosses. |
| `main_hand.<kind>`, `off_hand.<kind>` | Forever recognises weapon kind (e.g. `dagger`, `two_handed`) as well as size | Verified available but check actual player equipment. |
| `actions=` | In Forever, appends, not SimC reset of the current list | Full imports must not rely on reset semantics. |
| `pool_resource,for_next=1,extra_amount=N` | Only functional pooling form, using lower resource bound | Often redundant: automatic resource forecast already waits. Bare `pool_resource` and `pool_resource,wait=N` are accepted but **do nothing**. |

**Source-registered windows at v0.10.0 (do not invent additional ones):** Hunter `hha` (Hawk–Hawk–Arcane), `weave` (melee weaving); Paladin `move1`, `move2` (Retribution movement/opening); Rogue `riposte` (parry). APL-declared window names must not collide with these. Windows work across displays; **sequences only run on Primary and AOE, and the display's Sequences option defaults ON**.

## Supported powerful APL building blocks (not necessarily Forever inventions)

| Syntax family | Role | Notes |
| --- | --- | --- |
| `actions.foo+=/spell`, `call_action_list,name=foo`, `run_action_list,name=foo` | Fully local reusable action lists | `call` resumes caller if no pick; `run` prevents the caller's tail while condition holds. Audit full reachable/final tail. |
| `actions+=/variable,name=pool,value=...`, `variable.pool` | Dynamically compute policy terms | Variable is recomputed in the walk, **not across combat events**; useful in complex standalone logic. |
| `actions+=/variable,name=policy,pure=1,value=...` | Pure expression/alias evaluated at each consumer line | Requires a unique unconditional reachable declaration, no conditional call path, no `if`, `op` except set, or `value_else`. Fails to ordinary-variable mode with warning if constraints violated. |
| `actions+=/sequence,name=opener,mode=continue:spell_a:spell_b` | Due-step ordering with `mode=skip` (default), `wait` or `continue` | `wait` blocks lower actions; `continue` allows fallback. Check actual ability key and fallback transitions. |
| `actions+=/strict_sequence,name=burst,start_on_first=1:spell_a:spell_b` | Strict castable-window sequence; optional `allow_skip=1`, `hold_off_gcd=1`, `step_timeout` | High-risk if a member becomes uncastable, or strict state flickers; source-native + live test. |
| `actions+=/restart_sequence,name=opener,if=window.opener.done` | Restarts a completed plain sequence | Prevent repeated step-1 suggestion; use only after source-backed testing. |
| `action.<key>.known`, `.disabled`, `.ready`, `.cost`, `.in_range` | Level/toggle/readiness/resource/range-aware choice | `known` includes not-disabled per current reference. Under native Require Toggle OFF, a spell may be unusable regardless of APL conditions. |
| `cooldown.<key>.ready` and `.remains` | Cooldown read/forecast | `ready` is actually observed; `remains` estimated in combat. |
| `buff.<key>.up`, `.remains`, `.stack`, `.refreshable` and `debuff.<key>.*` | Maintenance and proc decisions | Hidden combat auras estimated by cast history and optionally corrected by game Cooldown Manager. |
| `prev.1.<key>`, `prev_gcd.1.<key>`, `prev_off_gcd.1.<key>` | Recent player/modelled casts | Useful for openers and repeated fallback; no guess at hidden targets. |
| `talent.<key>.enabled`, `.rank`, `level` | Level 1–60 and build awareness | Registered talents only. |
| `time`, `solo`, `group`, `aggro`, `tanking`, `moving`, `pet.alive` | Source-readable game observations | Group threat may not positively reproduce in source world; actual in-game signal may be limited. |
| `active_enemies`, `spell_targets.<key>`, `cycle_targets=1`, `other_target=1` | Adaptive AoE and target swaps | In dungeons/raids often counts 1; target swaps require spec's Allow Target Swaps toggle and nameplates. |
| `line_cd=N`, `sync=<ability>`, `use_off_gcd=1`, `use_while_casting=1`, `moving=1` | Line timing/eligibility | Check source's GCD/cast and real capability. |
| `strict=1`, `strict_if=<condition>` | Immediate eligibility on list call or `use_items` | **Ignored on ordinary spell lines**. |
| `if=`, `interrupt_if=`, `interrupt_global=1`, `interrupt_immediate=1`, `chain`, `early_chain_if`, `only_cwc=1` | Conditions and verified channel-breaking | Do not add speculative channels/interrupts to classes without observed event. |
| `cancel_action,name=<ability>`, `cancel_buff,buff_name=<aura>`, `use_items`, `wait,sec=N` | Source-supported special actions | Cancel buff only when class pack defines cancellation; item toggles still matter. |
| `toggle.cooldowns`, `toggle.minor_cooldowns`, `toggle.defensives`, `toggle.interrupts`, `toggle.potions`, `toggle.movement`, `toggle.custom1`, `toggle.custom2` | Read existing native user off-switches | `toggle.custom1/2` need player setup to be meaningful; **avoid as required mechanics**. `toggle.essences` is rewritten as minor_cooldowns. |
| `settings.<registered_key>` | Read existing per-spec setting (boolean/number/choice) | **Not custom APL logic**; absent keys are false. Requires upstream registration. Avoid as prerequisite for a functioning normal rotation. |

**Operator support:** `&` AND, `|` OR, `!` NOT, `=`/ `==`, `!=`, `>`, `>=`, `<`, `<=`, `^` XOR, `+`, `-`, `*`, `/`, `%`, parentheses, `min()`, `max()`, `floor()`, `ceil()`, `abs()`; SimC import rewrites `%` to division and `%%` or `//` to remainder. Avoid division by zero.

## Fresh-profile toggle defaults (critical no-checkbox design check)

**Verified source:** [Hekili Forever v0.10.0 Options.lua, default profile lines 320–387](https://github.com/zmsl/hekili/blob/v0.10.0/src/Hekili/Options/Options.lua#L320-L387). `cooldowns=true`, `minor_cooldowns=true`, `defensives=true`, `interrupts=true`, `movement=true`; **`potions=false`, `custom1=false`, `custom2=false`**. Default Display Mode = `automatic`; note mode/count observability limits in instances. Existing user profiles may have different saved values. For our "import/activate and play" target, using a **standard toggled category** with its native ON default is compatible with no checkbox micromanagement; deliberately switching it OFF is still a user opt-out. **Do not** design core maintenance, pets, interrupts or ordinary fillers under Potions or Custom #1/#2 (which are OFF without user setup). Consumables must remain elective due real inventory/cost. Verify exact ability's own native `Require Toggle` on source and preserve safe fallback when player disables it.

## Fixed/hidden-state traps — must not drive supposed automatic policies

- `fight_remains`, `time_to_die`, `target.time_to_die` are **fixed unknown ~3600 s**, not a real time-to-death. `target.time_to_pct_<N>` is fixed unknown ~2520 s.
- `health.pct` is **100 in combat** (the real player HP is hidden); `target.health.pct` is normally 100, or a narrow execute threshold under ability usability, not actual target health.
- `incoming_damage_5s`/other incoming damage and heal fields are **0**; `group_health` and `at_risk` are not reliable combat triage.
- In combat, `target.is_targeting_player` can be false even if the target actually attacks the player in a dungeon; `target.moving` is false while hidden; `target.creature_type` unknown, boss identity incomplete.
- `active_dot` may assume unobserved enemies already have DoTs. Enemy count and cycle-target capability depend on visible nameplates; **AoE might require manual user mode** despite a fully autonomous best-effort APL.
- Engine-side **Require Toggle** is separate from the APL's `if=toggle.*`. Without an enabled native toggle the ability can be considered unusable, even when the APL condition does not read that toggle.

## APLForever policy

Prefer custom original priority architecture, source-visible facts, `resource.lo`, per-ability known/ready/cost/range, safe debuff upkeep and end-of-chain. Add pure variables / windows / sequences only when a targeted default+last-working comparison proves a reliability or output benefit. Avoid mandatory per-spec `settings.*`, custom toggle setup, inaccessible health/TTD and fake ranges. Respect deliberate optional cooldown/interrupt/potion switches and native Requires Toggle. Every supported role needs 3 real state-advanced source-native recommendations plus full Final Fallback / Repeated Recommendation and smallest irreducible live proof. Never present a syntax example as a ready-to-import working spec.
