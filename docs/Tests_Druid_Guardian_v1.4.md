# Guardian v1.4 — Tests & evidence ledger

**20 November 2026; status: Draft / source-native checks submitted, not yet gameplay validated.** Latest official source: [Hekili Forever v0.10.0](https://github.com/zmsl/hekili/releases/tag/v0.10.0), pinned commit `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`. Candidate SHA `03cc2ef5df2ed18228e8437adf9218ea59f9e2e816243978bee9c68aa501c464`. Source and tests run on public GitHub-hosted runner.

| Check | Test design / evidence status |
| --- | --- |
| Whole source & unchanged working rollback | Catalogue hash and strict `validate_repository.py`; v1.0 remains preferred and exact |
| v1.0 / shipped / v1.2 / v1.3 / v1.4 | Matched L60 official source combat/conditions; source-accepted Roar/Barkskin, no refusals |
| No manual maintenance dependency | v1.4 boss case with native maintain setting OFF **and** ON: equivalent accepted Roar; Defensives OFF and Barkskin absent |
| Short normal-target solo | World source target level = player level, 9 s, actual natural Rage and hostile swings; no Roar with maintain setting either ON or OFF |
| Barkskin manual OFF/ON | v1.0–v1.4 existing source coverage; source-registered Barkskin level-43/44 boundary; no claimed hidden-health trigger |
| Fallback/unlocks/resources | Existing historical v0.9.0 natural low Rage, level 1–9 caster, 24/25, 30/31, 34 unlock, 3 state-advanced recommendations; source-only |
| Group+tanking positive, all modes | **Not demonstrated by real source-world group/threat fixture**; live `/hek snap` required |
| Long solo ordinary / recognised bosses | Natural source truth and target flags to verify; exact 4/5/12 sec and Rage reserve not optimised |
| Target within5 unknown-range, multi-target count | **Engine limitation**, no false castability promise |
| Actual survival/threat/DPS gains | **Not measured**, no phantom percentages |
| Positive high-Rage Maul queue | **Blocked** and separately tracked issue #3 |
| Full v0.10.0 cross-role gate | **Partial**; unrelated Feral combat-health/Arms warnings, PR #13 |

A failed native test fails the candidate and must be diagnosed, not muted. Clean test import does not certify live mechanics. Current preferred remains v1.0 until user observed/approved in-game.

## NEW 20 November 2026 — Role-gate regression and autonomous alternative, source-native only

**Published source pin:** Hekili Forever v0.10.0 `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`. The engine reads `tanking = role.tank and aggro` ([State.lua L2428](https://github.com/zmsl/hekili/blob/v0.10.0/src/Hekili/Engine/Sim/State.lua#L2428)); role comes from **client GetSpecializationInfo role** ([Activation.lua L122–132](https://github.com/zmsl/hekili/blob/v0.10.0/src/Hekili/Engine/Schema/Spec/Activation.lua#L122-L132)) instead of the selected Guardian priority. [Native diagnostic 44711863340](https://github.com/tkbiccay/APLForever-Open/actions/runs/44711863340) proved both published Feral and Guardian fake clients report DAMAGER and `tanking=false`. This does **not** establish the real game's client role.

**Test-only complete-source candidate:** [`experiments/native/aplforever_guardian_rolefree_roar_v010_spec.lua`](https://github.com/tkbiccay/APLForever-Open/blob/candidate/guardian-roar-upkeep-v13-20261119/experiments/native/aplforever_guardian_rolefree_roar_v010_spec.lua) imports the entire original v1.4 and alters **only** the Roar timing expression in memory, removing `tanking` while keeping all debuff, 4yd source-world range, real resource-low-bound +10 Rage reserve, cooldown, fallback and native toggle conditions. **No APL or catalogue revision was created or selected**.

Exact [native run 44713464837](https://github.com/tkbiccay/APLForever-Open/actions/runs/44713464837) PASSED **4/4 cases**, source-world seed **30417**, 0 refusals/errors. At 38s on a controlled group-members=2, enemy level 60 (normal, not world boss), two-attackers/4yd world with genuine published Rage/combat events:

| Comparator | **Game defaults** Roar / all accepted | **Simulation defaults** Roar / all accepted |
| --- | --- | --- |
| Shipped Guardian | **0 / 18** | **2 / 18** |
| v1.0 Reported Working | **0 / 13** | **2 / 15** |
| v1.4 Draft | **0 / 13** | **0 / 13** |
| In-memory role-independent timing | **1 / 17** | **1 / 17** |

Game/sim discrepancy is expected: official Druid.lua registers `settings.maintain_demoralizing_roar` default **false** but `sim=true`; the shipped and v1.0 comparators therefore use a **different policy** in the harness by default. This is why **game-default comparisons are mandatory for our no-checkbox requirement**. Source-world group membership is a *controlled client setting*, not observed actual party threat, and accepted-action counts do **not** establish threat, damage, Roar usefulness or survival.

**Solo controls:** 9-second normal mob: v1.4 and role-independent version each accepted six non-Roar actions and no Roar. 35-second solo: each accepted 11 actions and no Roar; the experimental version's lower Rage estimate stayed **≤15** during its sampled long-solo window, below the verified **20 Rage (10 cost + 10 reserve)**. This is a correct conservative abstention, not proof of a broken branch. No source refused casts.

**Status:** Guardian v1.4 is still an **unselected Draft**, the independent role-free variant an **unselected in-memory Experiment**. Preserve the exact v1.0 Reported Working/Needs Retest APL and **all previous hashes**. The hypothesis is promising for grouped non-boss uptime on a DAMAGER-role client, but **there is no demonstrated superiority** against the shipped priority or practical tanking. Do not create a promoted replacement or infer that the actual game presents the same pseudo-spec role. Minimal in-game group/tanking role/snapshot is still the decisive gate. The previous v0.9.0 full historical source-native workflow remains green; full v0.10.0 all-role status is still Partial on distinct Feral/Arms findings.
