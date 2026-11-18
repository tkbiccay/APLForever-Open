# APLForever — specialisation, combat role and hybrid build policy

## Core rule: one primary role, not one exclusive talent tree or attack range

Every `<Class>_<Spec>` APL must optimise the **declared WoW Forever specialisation and combat role** (DPS, Tank or Healer) recorded in `catalogue/roles.json`. The combat role determines our success and safety criteria; it does **not** forbid cross-tree talents, hybrid damage styles, a mixture of melee/ranged abilities, a supporting form, or legitimate off-tree class utility.

**Hybrid builds are explicitly allowed and encouraged to be researched.** WoW Forever is not Retail: talent allocations across trees and multiple combat styles may be intended, competitive or optimal. The source-supported Forever Hunter melee-weave packs are concrete evidence. Rejecting all hybrid rotations as "impure" would introduce a design regression.

Distinguish three concepts:

1. **Cross-tree talent build:** A build invests in two or three talent trees to improve the chosen DPS, Tank or Healer role. This is normal and eligible for an APL.
2. **Same-role hybrid rotation:** For example, Hunter ranged/melee weaving, a Mage Frostfire damage build, or a DPS spec combining talents from different trees. These are eligible when spells, talent gates, range, timing and engine reads are verified.
3. **Conflicting primary roles:** One unqualified APL that alternates full tanking, healing and DPS assignments without reliable group context. Do **not** automate such role switching or displace required tank mitigation/healer safety. Supporting utility, emergency defence, mana management, and bounded levelling exceptions can still be appropriate.

Our objective remains **one preferred, validated, context-adaptive APL per supported role**, optimised across **levels 1–60**, including level-60 open-world, dungeons and raid PvE. Maintain one profile by default; do not duplicate every spec into separate Levelling and Endgame APLs. A level-60 character can still be doing quests and exploration, and level alone cannot establish raid intent. Detect proven talent, level, fight/boss, range, cooldown and resource conditions inside the APL where reliable; allow legitimate cross-tree build variants. Different designs may be tested as revisioned candidates, not as automatically maintained parallel production APLs. Create a separate content-specific profile only after reproducible in-game evidence establishes a material benefit that a safe single adaptive priority cannot achieve; document the engine blocker, exact user choice, fair baseline, rollback, extra test cost and explicit exception approval. If styles require unobservable player choices, document the setup and compare fairly instead of inventing state.

## Concrete Forever examples

- **Hunter Marksmanship:** Ranged-only and ranged/melee-weaving builds exist. The addon ships a translated Marksmanship weave pack. A verified weave is a Marksmanship **DPS** build, not a second combat role.
- **Hunter Survival:** Full melee and ranged/melee-weave playstyles both exist. The addon ships separate Survival and Survival Melee reference packs. A ranged branch in a Survival APL is **not automatically a design defect**. Whether and when to recommend it depends on intended build, range, swing clock, mana, talents and actual Hekili support.
- **Hunter Beast Mastery:** A pet/ranged DPS priority may have a legitimate melee-weave variant. Evaluate its benefit and practical stability; don't reject it solely for using Raptor Strike, and don't require it merely because a WoWSims pack includes it.
- **Mage Fire/Frostfire:** Cross-school talents and Frostfire Bolt can form a coherent Fire-role DPS build; Frostfire is a build style, not an extra catalogue role. Validate current Forever mechanics and addon action keys.
- **Druid Feral DPS:** Cat is the core damage form. A short pre-Cat levelling fallback and situational defensive Bear shift may be legitimate; a continuous Bear tank priority displacing Cat DPS is not justified without a verified same-role scenario. Judge each branch by purpose, not its label.
- **Druid Guardian Tank / Paladin Protection Tank:** Damage and off-tree talents can improve threat and survival; do not remove them just because they resemble a DPS action. Tank safety and threat remain primary.
- **Paladin Retribution DPS:** Holy Shock, seals and other tree choices can support damage builds if learned, registered and castable. Do not mark a candidate invalid just because a talent originates in the Holy tree.
- **Healers:** Damage weaving and supporting utility can be part of a valid healer rotation *only once* target triage and relevant combat state have been independently verified. The five intended healer roles remain Blocked; do not relabel Priest Smite DPS as a healer.

## Evidence and engine limits

A real build in the **game** is not necessarily a safe, observable build in the **addon**.

- Read the current Hekili Forever class kit, shipped default/variants, talents, cooldown categories and engine limitations **before** adding any hybrid branches.
- Verify that each recommended spell/action and expression is actually registered. For example, some guide-recommended Hunter actions were absent from the pinned Hekili Hunter kit; source absence prevents a ready-to-import recommendation.
- Hekili can suggest casts but cannot perform movement, facing, or manual target switches. Hunter weave timing must be judged against both melee/ranged swings, Auto Shot clipping, 5–8-yard dead-zone, Raptor Strike next-swing queue, actual range and player intentions.
- Prefer reliable talent/level/range conditions. **Do not invent detection** of a chosen weave mode, weapon setup, encounter, live target DoTs, ally health or group role. Keep optional branches off when their required state cannot be safely inferred.
- Respect Cooldowns, Defensives, Minor Cooldowns, items and other deliberate player off-switches. Minimise per-spec settings, but do not force unreliable automation.
- Test complexity, safe castability, output, survival, stability and fallback. A simpler ranged-only or full-melee design can win fair tests; hybrid complexity is **permitted, not automatically superior**.

## Mandatory design and promotion review

1. Confirm exact `class`, `spec`, primary `role`, `apl_name` and Forever taxonomy.
2. Identify talent-tree mix, intended build/style, verified actions, items, forms, cooldowns and range requirements.
3. Classify each sublist as core rotation, same-role hybrid, low-level unlock, utility, defensive, resource recovery, or unsupported/off-role branch. **Do not reject solely by cross-tree origin or melee/ranged mixture.**
4. Audit reachability of *every* branch and final fallback. Test unlearned spells, low/uncertain resources, off-switches and consecutive recommendations; repeated inappropriate suggestions FAIL.
5. Compare shipped default **and** last-working APL, including any supplied default weave/full-melee alternatives, at matched builds, latency, talents, gear and settings. Don't declare improvements within noise.
6. Run appropriate actual in-game checks; use `/hek snap` to investigate incorrect recommendations. No static test or simulation alone promotes a role.
7. Preserve byte-identical historical APLs, catalogue metadata, SHA-256 and rollback; never silently rewrite a previously working version.
8. Maintain one validated preferred APL per supported role, selecting the architecture that wins on practical reliability and output, whether hybrid or single-style.

## Historical v1.0 designs: review required, not presumed invalid

Four archived drafts were flagged on 14 November 2026 because they contain multiple styles. That alone is **not a failure**:

- `Druid_Feral`: verify whether Bear/caster branches are bounded levelling/defensive support or unsafe ongoing tank/caster priorities.
- `Hunter_BeastMastery`: review melee portions as possible legitimate BM weave; test with pet/ranged output and source-supported talents.
- `Hunter_Marksmanship`: compare ranged-only versus a mechanically verified ranged/melee weave; do not automatically remove the melee branch.
- `Hunter_Survival`: compare full-melee, ranged/weave and other documented Survival variants; do not automatically remove the ranged branch.
- `Paladin_Retribution`: Holy Shock talent references do not automatically make the APL an invalid Holy-role hybrid; review the actual damage/castability and talent conditions.

Their existing revision texts and hashes remain immutable. Their status remains Draft until the normal review and real-world evidence gates are passed; removing a mistaken blanket purity flag is **not approval**.

## Forever-specific evidence underpinning this correction (14 November 2026)

- Hekili Forever source at `zmsl/hekili@246abf322ed53e3b7ab796ea7089c72329f3eb9d`: `src/Hekili_Hunter/APLs/Marksmanship (wowsims.com).simc`, `Survival (wowsims.com).simc`, `Survival Melee (wowsims.com).simc`, and the Hunter class kit; translated from WoWSims Forever `e5a9cd2a2dfc`.
- Wowhead: https://www.wowhead.com/forever/guide/classes/hunter/survival/talent-builds-pve-dps (Survival 0/20/31 ranged/melee weaving talent build).
- Method: https://www.method.gg/wow-forever/class-guides/survival-hunter/talents and https://www.method.gg/wow-forever/class-guides/survival-hunter/rotation-and-playstyle (full melee vs weaving).
- Mobalytics: https://mobalytics.gg/wow-forever/classes/marksmanship-hunter-guide-progress and https://mobalytics.gg/wow-forever/classes/survival-hunter-guide (ranged and melee weave options).
- Historical or simulation comparisons are hypotheses until confirmed against the current game build and actual player gameplay.

## Responsibility and credit economy

ChatGPT: verify actual Forever mechanics and builds, design alternatives, assess safe APL feasibility and record comparative evidence. Codex: only focused engineering or local tests that add value beyond direct GitHub editing. User: in-game import, `/hek snap` and final approval. Neither tool nor person declares a build superior from theory or static checks alone.
