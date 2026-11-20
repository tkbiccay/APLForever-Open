# APLForever-Open — proudly AI-developed, human-maintained

**We build this because it is fun.** This is a transparent, open-source hobby experiment in how far careful AI-assisted engineering can improve reliable World of Warcraft: Forever APL recommendations. We aim for excellent gameplay, not marketing claims, unnecessary infrastructure or endless AI-generated code churn.

**Canonical working repository:** https://github.com/tkbiccay/APLForever-Open (GPL-3.0-only for original work). Historical private `tkbiccay/APLForever` is read-only reference. The project is independent of Blizzard, Hekili Forever, WoWSims and OpenAI, none of whom endorse these APLs.

## Who does what

- **Human maintainer @tkbiccay:** sole official ownership, final gameplay judgement, merges, releases, in-game verification and Approved status.
- **ChatGPT + maintainer:** lead priorities, original APL designs, source research, mechanical reasoning, regression triage, available headless validation and public evidence. AI assistance is welcomed and credited, but outputs are not automatically correct.
- **Codex (when explicitly delegated):** bounded specialist code/test/CI implementation. Stop and return evidence after the assigned task. No autonomous backlog, private-repo development or automatic merge.
- **Community:** issues, critiques, reproducible gameplay evidence, forks and proposed PRs welcome. Credit authors and respect third-party licences.

## Active gameplay priorities — equal first tier

1. **Druid Guardian / Feral Tank**: protect v1.0 Reported Working / Needs Retest; independently assess Barkskin/Roar/mitigation, Rage/queue limits and repeated final fallback against source v0.9.0, the default and last working.
2. **Hunter Beast Mastery**: co-equal priority; v1.1 is a *Draft file under Current* but `preferred_apl: null` in catalogue; **no proven selected APL**. Research default Turret pack in released engine, pet summon/revive and state, resources, levelling unlocks, movement/range/melee weave, Major/Minor/Defensives/Interrupts/Potions toggles and repeated low-mana/pet-upkeep tails. Compare both v1.0/v1.1 Drafts, without assigning a preferred or approved status from file placement.
3. **Feral DPS**, then other 23 supported roles by live impact and resolved risk. Critical cross-spec safety defects and release compatibility can pre-empt order.

These are work allocation priorities, **not guaranteed superiority claims**.

## Smarter evidence and credit strategy

**Three layers, use the least expensive layer that answers the question:**

| Layer | When | Acceptance |
|---|---|---|
| Fast static / catalogue / privacy integrity | Every PR, always | No broken hashes, secrets, schema, rollback or syntax |
| Targeted released-source native checks | One role/engine hypothesis; source release, shared engine changes or pre-promotion | Imported/castable; accepted/refused state progression; correct toggles, unlocks, resources and 3-state final/repeated fallback |
| In-game evidence | Hidden HP/Rage, pets or auras, movement, threat/mitigation, timing and anything source harness cannot faithfully prove | Player captures actual behaviour, compares default and last-working, and explicitly approves or rejects |

Run broad multi-role native gates for upstream releases, source-shared changes or justified critical regression, **not** on every prose edit. Reuse cached pins, learned fixture limits and existing tests. Avoid unnecessary CI reruns, repeated research, duplicate branches and speculative DPS sims.

**Strict vs experimental coverage:** A required regression failing is a FAIL; preserve rollback and stop promotion. A novel positive counterfactual which cannot enter its preconditions is *BLOCKED / Not Demonstrated*. Keep its strict assertion and negative traces in a separately labelled experimental run, without weakening it or falsely treating it as a PASS. Its lack of proof cannot justify adopting that candidate. Independent release-compatibility checks may be independently reported as passed **within their explicit scope**, but no one may claim all outstanding scenarios passed.

**No phantom gains:** Source compilation, cast progression, default agreement or a simulated damage result cannot establish gameplay optimality. Record sample size, noise, engine limits and actual test scope. Include final fallback and three consecutive state-advanced recommendations game-wide. APL architecture is freely custom; shipped default is a comparator, not a ceiling. Use no invented spells, secret reads, fabricated Rage or positive scenarios.

## Ability intent, real toggles and standalone architecture (19 November 2026)

**20 November cross-role autonomy amendment:** no checkbox or per-spec option should be required to make a new role APL's **ordinary** rotation work. Its routine upkeep, pet/form/resource/debuff policies belong in its own APL; optional player OFF switches and the engine's native Require Toggle limitations remain real and must not be bypassed or misrepresented. Existing settings-bearing Guardian/Demonology rollbacks are preserved, not compliant by declaration. See [APL Autonomy Standard](APL_AUTONOMY_STANDARD.md). Audit new `settings.*` uses via `scripts/audit_apl_controls.py`; review `toggle.*` uses semantically, not with a blanket ban. Successful static scans cannot prove castability or game-side activation.

Treat **ability role** and **addon registration toggle** as distinct facts. Research the exact released class/race/item registration before deciding that a spell belongs in the APL's `general_rotation`, `major_cooldowns`, `minor_cooldowns`, `defensives`, `interrupts`, `potions` or utility/upkeep. List names are conceptual and **not automatically verified import syntax**. One full standalone import may contain its own internal lists; no second APL or external helper is required.

- **General rotation:** ordinary builders, spenders, DoTs/debuffs, target-adaptive fillers, resource-safe waits, forms/pets and upkeep even if some have a short cooldown. Do **not** hide regular throughput behind a cooldown toggle merely because it has a cooldown.
- **Major Cooldowns:** deliberate significant throughput/burst or racial cooldowns, only while enabled and safe. In released `v0.9.0` Hunter.lua, `bestial_wrath` (19574) and `rapid_fire` (3045) are registered `toggle = "cooldowns"`; released Orc Blood Fury, Troll Berserking and Night Elf Elune's Light are likewise registered Major. BM v1.1's complete `major_cooldowns` sublist is also reached only via `toggle.cooldowns`. Do not assume this list's timing, spacing or use-items classification is optimal merely because the toggle works.
- **Minor Cooldowns:** only genuinely suitable, independently source-verified tactical abilities. The addon supports `minor_cooldowns`, but absence of a justified minor ability means an **empty/not applicable** category, not an invented action or arbitrary recategorisation of a Major. Test user off-switch and optional auto-enable behaviour.
- **Defensives:** player-activated mitigation/survival and approved maintenance policies; `toggle.defensives` must be respected. v0.9.0 Druid `barkskin` (22812) is natively assigned `defensives`. `demoralizing_roar` (99) is **not** natively toggle-assigned: the original Guardian v1.0 uses a separate setting, whereas v1.2 explicitly guards its Roar branch with `toggle.defensives`. This is a design choice that needs real threat/Rage cost and gameplay testing, not an established improvement.
- **Interrupts / control / dispels:** do not call every stun, purge or trap an interrupt. Include only when the spell, actual enemy-cast visibility, timing and `toggle.interrupts` are verified. Otherwise document a manual utility action / limitation; never spam an unobservable cast.
- **Potions and items:** `potions` is an independent native toggle. A generic `use_items` action is not evidence that a particular potion, trinket or health consumable was correctly classified. Verify items, item-triggered warnings, role and toggles in the **released** engine before moving them into separated branches. Do not consume automatically on speculative player health or without an independent use rule.
- **Upkeep and safe tail:** own-pet call/revive is recovery/upkeep, not throughput cooldown; Summon Hawk is a separate temporary guardian, not the main pet. The final reachable action/wait after unaffordable and toggles-OFF branches, plus **three real state-advanced** recommendations, is a cross-role P0 gate.

**One toggle mechanism, one responsibility:** the engine's `Require Toggle` may make a registered action unusable when OFF, while APL `if=toggle.*` conditions independently gate branches. Verify both; avoid accidental double dependencies where a Major toggle suppresses a Minor, Defensive, Interrupt or Potion sublist. Do not rely on a player option to make a custom APL safe if a verified APL guard is possible. Distinguish native defaults from player overrides.

**Pinned native references:** [v0.9.0 Hunter.lua](https://github.com/zmsl/hekili/blob/v0.9.0/src/Hekili_Hunter/Hunter.lua), [v0.9.0 Druid.lua](https://github.com/zmsl/hekili/blob/v0.9.0/src/Hekili_Druid/Druid.lua), [race registrations](https://github.com/zmsl/hekili/tree/v0.9.0/src/Hekili_Shared/Races), and released [Toggles](https://github.com/zmsl/hekili/blob/v0.9.0/docs/wiki/Toggles.md) / [Abilities and Items](https://github.com/zmsl/hekili/blob/v0.9.0/docs/wiki/Abilities-And-Items.md). Pin: `8f95f2ea0a45428554c1e938ed7357b870030514`. The source is **Confirmed** for registrations; the performance and safety of our APL policy remain **Unverified** without targeted tests.

### Optional simulation research — deferred, reusable by role

Use the **native engine for correctness** before considering numerical output. When an unresolved decision materially warrants a **faithful Forever-specific sim** (not a Retail/Raidbots profile passed off as Forever), use a versioned reproducible model:

| Shared scenario | Role-specific acceptance |
| --- | --- |
| One high-pressure raid boss (1 target) | DPS: uptime/damage and threat safety; Tank: mitigation, survival, threat; Healer: credible incoming injury/triage only |
| Boss plus one add (2), stable 3-target pack | Priority target, target swap, resource, threat and castability; healing demand is not implied by number of enemies |
| Five-plus targets, waves/spawns and boss-plus-adds | Adaptive AoE, survival, cooldown holding/placement and target lifetimes; not a generic permanent five-boss encounter |
| Low-level solo, elites and short packs | Correct unlocks, changing resources and final fallback; levelling is immersion-first |

**SimulationCraft / Raidbots** provide *scenario-design vocabulary*, not a mechanically compatible Forever oracle. **Ask Mr. Robot** illustrates why healers require damage-event and overheal assumptions; **WoWSims Forever** is the relevant game's primary mechanics/sim reference. Separate tank and healer experiments must identify their own reliable incoming damage, heal/triage, threat and mitigation data before numerical claims. Transfer **scenario definitions, harness checks and measured lessons** across matching roles, never automatically transfer combat priorities. Numerical DPS/TPS/HPS sims are **nice to have after validated APLs**, not a development milestone or CI requirement.

## Public communication and fun

Share small milestones, interesting discoveries, failed experiments, labelled drafts and open technical limitations. Write plainly in UK English; it is fine to say *AI helped us build this* — we are proud of that. Honour upstream contributors and GPLv3 obligations. Be friendly, curious and transparent. Do not pretend human-only authorship or imply that all content was generated autonomously by AI.

**Success** means the addon gives more reliably useful, castable and stable recommendations in real play. It is not the number of commits, test cases, simulations, automation runs or APL complexity.
