> **PUBLIC MIGRATION NOTE (18 November 2026):** The results below are preserved **historical private-reference research**, not rerun/approved results from APLForever-Open. Public CI validates exact file integrity only until a separately pinned current-release native suite executes. Latest published Hekili is v0.9.0, commit `8f95f2ea0a45428554c1e938ed7357b870030514`; public native compatibility remains **Not Run**. Status/rollbacks unchanged.

# APLForever — measured progress and remaining proof

**18 Nov 2026 owner priority update:** numerical WoWSims reference/trace work is **historical optional R&D**, **not the next milestone**. **First** design/refine custom standalone APLs and validate their actual Hekili Forever/Belief engine behaviour, safety, cast progression and repeated fallbacks; **then** consider sims only if a concrete safe-APL comparison merits them. The simulation bridge is deferred. Role priority: Guardian/Feral Tank → Feral DPS → remaining roles. [Source/methodology/role tests](SIMULATION_POLICY.md). This change does **not** promote any APL or erase previously passing/failed evidence.

**Last checked: 18 November 2026.** Source of truth: [catalogue](../../catalogue/roles.json), [tests](../), [release ledger](engine/RELEASE_LEDGER.md), live main and [continuation handover](CONTINUATION_HANDOVER.md). This scorecard is a **dated summary**, not a new authoritative APL selector; re-check current pins before reusing it.

## Snapshot and what the numbers mean

| Metric | Verified state |
| --- | --- |
| Latest published and source-tested Hekili Forever | **v0.8.6**, tagged 17 Nov 2026, source commit `2e9cb6a78d9088007e9acd9cce3eeb0e91463cc5` |
| Whole v0.8.6 code-head native run | **843/843 tests green**, [run 44182255034]([private historical reference; not publicly accessible]) |
| Final PR #84 workflow lanes | **All five green**, including [v0.8.6]([private historical reference; not publicly accessible]), [v0.8.5]([private historical reference; not publicly accessible]), [v0.8.3]([private historical reference; not publicly accessible]), [native preflight]([private historical reference; not publicly accessible]) and [repository integrity]([private historical reference; not publicly accessible]) |
| Intended spec/role coverage | **28 roles:** 23 `Supported` by catalogue gate, 5 healer roles `Blocked` |
| Tracked full importable historical revisions | **32** with protected SHA-256 / separate lifecycle; not 31 Approved roles |
| Catalogue validation statuses | **19 Draft, 2 NeedsRetest, 1 StaticValidated, 1 PendingInGame, 5 Unknown** |
| Last reported-working selections | **2 NeedsRetest**, Guardian/Feral Tank and Demonology Warlock; **0 Approved** |
| Automatic production promotion | **None.** Current is a testing selection, not automatic approval |

## New capability: actual native WoWSims damage simulation

**Implemented and green on 18 November 2026.** [Druid 1/2/5-target full results](../Tests_WoWSims_Druid_DPS_Reference.md), immutable official **wowsims/forever@b83fe9df5fcd04d08061514332105ad9b769971d**, [green Go CI 44270769552]([private historical reference; not publicly accessible]), **18 native seed-batch runs × 60 iterations = 1,080 actual simulated 180-second combats**. The source-native Go engine applies real spell damage/armor, talents, proc/attack timings, gear and target damage — no extrapolated per-ability constant.

| Native WoWSims adaptive reference (Tauren L60, no external buffs) | Patchwerk 1 target | Cleave 2 targets | AoE 5 targets |
| --- | ---: | ---: | ---: |
| **Feral Cat total DPS** | **419.19** | **419.67** | **419.19** |
| **Feral Bear total DPS** | **264.27** | **252.18** | **289.98** |

Feral Bear additionally had no deaths and recorded threat/incoming damage under fixed **2,200 HPS** source healing, **one designated primary raid attacker** across all target counts, with the others still fully damageable. Without healing, Bear died in **100%** of 180s worlds; five *incoming* boss-level attackers killed Bear in **86%** despite 5,000 HPS. These false tank-DPS baselines were preserved as failures and corrected by holding incoming pressure constant. Feral Cat's flat 1/2/5-target total DPS is a native WoWSims `adaptive` result, **not proof that our Feral Hekili APLs have no AoE potential**. Per-seed metrics and variance are preserved in the [GitHub Actions artifact]([private historical reference; not publicly accessible]).

**Crucial status:** this is a genuine damage simulator for **WoWSims' own Feral Cat/Bear adaptive APL**, **not a custom APL performance comparison**. The custom Hekili Forever shipped/Current/Candidate APLs still need a verified semantic translation or action-trace bridge into the Go simulator, explicitly reconciling resource beliefs, forms, cooldowns and FULL fallback chains. No new APL Approved or promoted, no custom-DPS uplift claimed. [Bridge requirements](../Research_WoWSims_Damage_Matrix.md).

## Confirmed source-native improvements (not gameplay DPS claims)

1. **Warrior Fury, Movement OFF/ON:** the unchanged Current v1.0 and shipped APL each accepted Charge and Intercept at valid 12 yards when Movement OFF. New [full standalone Fury v1.2 Draft](../../roles/Warrior/Candidates/APL_Warrior_Fury_v1.2_Draft.txt) accepted **0** mobility casts OFF and **1 of each** at 12 yards ON, with **0** out-of-range accepts at 3 or 30 yards. It remains **Candidate, not selected or Approved**. The released test harness resets Movement OFF in non-replay runs; the dedicated test explicitly restores the requested state after this **test-only** reset. Reported 8–25yd range is an independent but unofficial Forever spellbook fixture and needs the real client.
2. **Warrior Fury, actual Rage cost:** the archived v1.1 failed with **4 source-refused Bloodthirst attempts** (30 Rage cost, truth 28.5345 or 29.5865) including **three consecutive 0.2-second repeat refusals**. v1.2 added **+5 Rage headroom to exactly the single-target and AoE Bloodthirst guards**, and recorded **0 actual source cost refusals in 18 matched natural level-1–60 cases**; its three-hostile-swing repeated-ready checkpoint also had **0** failures. Source casts across those matched worlds: Current v1.0 **253**, archived v1.1 **242**, v1.2 **244**, shipped **338**; **not a DPS comparison**. [Full test ledger](../Tests_Warrior_Fury_v1.2.md).
3. **Guardian/Feral Tank, player control:** independent [v1.1 Draft](../../roles/Druid/Candidates/APL_Druid_Guardian_v1.1_Draft.txt) conditioned Demoralising Roar on Defensives ON. The source-v0.8.2 comparison observed **0** mitigation Roar slots with candidate Defensives OFF (vs historical Roar behaviour in the reported-working Current), and actual Roar casts under ON. Reported-working [v1.0 Current](../../roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt) remains protected / NeedsRetest. [Guardian source evidence](../GUARDIAN_P0_REGRESSION.md).
4. **Feral DPS, builder reachability:** independent [v1.1 Draft](../../roles/Druid/Candidates/APL_Druid_Feral_v1.1_Draft.txt) produced **20 accepted Shreds** when the source target was not targeting the player, versus **0** for Current v1.0, while retaining **17 accepted Claws** in the other matched world where the target focused the player. No refused casts in that six-world comparison. **Target-of-target is not verified behind-position** and no DPS superiority or finisher correctness was established. [Feral source evidence](../Tests_Druid_Feral_v1.1.md).
5. **Guardian pre-Bear fallback vs shipped:** in a bounded 15-world source study at levels **1,3,4,6,9**, both imported custom versions accepted real Mana-cost Wrath/Moonfire sequences whereas the shipped pack accepted **0 combat actions** in the adapted caster fixture. **Level-60 Mana/Spirit were borrowed**, so no realistic low-level endurance or gameplay dominance was proven. [Guardian evidence](../GUARDIAN_P0_REGRESSION.md).
6. **Warrior Protection and Arms:** natural-level, defensives ON/OFF, Revenge, stance/rage, real-nameplate target counting and final-fallback source-gates added. Prevents unwarranted regressions; none of these results alone establishes higher threat, damage or survival. [Warrior Protection tests](../Tests_Warrior_Protection_v1.0.md) and [Arms tests](../Tests_Warrior_Arms_v1.0.md).

## Test coverage improvements distinct from an APL upgrade

- **843 current-release tests** include **24 Protection**, **48 Fury valid-range toggle**, **72 Fury natural-resource**, **2 Arms guard**, **16 Arms nameplate**, **28 Arms natural**, **103 native import/progression**, **93 Feral**, and **457 upstream regression** checks. Multiple release lanes prevent inadvertent v0.8.6-only assumptions.
- Known-bad experiments are **kept**, not rewritten into false green passes: **DEMO-006** repetitive Life Tap, **Guardian PR #70** hidden-Rage exact-cost artificial warm start, **Feral PR #74** invalid forced-CP/Predatory Discipline Bite setup, **Fury v1.1** real cost refusals, and **Arms Lv60 Whirlwind** unexplained post-decision source windows.
- Protect all original Current and real reported-working checkpoints; maintain separate Candidates/Archive, catalogue hashes, source/gear/talent pins, tests and handover. **A green import or simulation is not approval**.

## Biggest blockers and next tests

**Priority 1: Guardian/Feral Tank.** The source exact-cost artificial warm-start failed across shipped and both customs because hidden Rage estimation diverged; source oracle-positive controls cleared. This is **not proved a live defect** and re-running the same artificial test is low-value. When gameplay validation is available, capture `/hek snap` just after a genuine paid Maul swing with low Rage, then observe the next **three real recommendations/presses**, Roar with Defensives ON/OFF and whether there is any repeated unaffordable action. No downgrade of v1.0 merely due to headless discrepancy.

**Priority 2: Feral DPS.** v1.1 source Shred/Claw reachability is supported; **Rip/Predatory Discipline Bite and Shifting Power correctness remain blocked**. The v0.8.6 Feral headless world still maps Ferocious Bite to `drain = ENERGY`, while the v0.8.6 Druid class code preserves excess Energy for Predatory Discipline. Real `/hek snap` at 5 CP, sufficient Energy and known Rip remaining is needed for the correct finisher decision, or a separately reconciled native source model; avoid re-running [closed red PR #74]([private historical reference; not publicly accessible]) unchanged.

**Approval gap:** Zero approved APLs, no controlled repeatable in-game DPS/survival evidence. Promotion requires no critical refused/repeated actions, valid FULL fallback chain, and fair comparisons to **shipped default AND exact last-working**, then real gameplay proof. Until then, source-validated improvements stay in independent standalone Candidates.

**Next efficient work:** stop when source-native proof is blocked by actual client hidden state; reuse the exact lessons and only request the minimal gameplay checkpoint required, not speculative APL churn.


### 18 November additional proof: native WoWSims APL row tracing

[PR #87]([private historical reference; not publicly accessible]) / [source-native action-row trace run 44273147680]([private historical reference; not publicly accessible]) verified a separate **30-second, one-seed Cat/Bear action-hook probe** at the same pinned WoWSims source. Cat: **136** attributed priority/group rows at **73** distinct timestamps; Bear: **202** at **100**. The original JSON-line source trace was archived under GitHub Actions artifact `wowsims-forever-druid-apl-row-trace-b83fe9d` (ID **14413865805**). Source action hooks fire *before* action implementation, and group rows can repeat: **these are not cast confirmations or imported Hekili APLs**. The prior reference DPS matrix and 0-Approved status are unchanged; a later v1.2 Guardian Draft adds one tracked revision. A **future optional** bridge would require actual postcast effects/acceptance and Hekili decision parity; **deferred** unless a specific APL optimisation decision needs it. Prioritise native Hekili APL faults, not fake direct DPS translation. [Source-method and limits](../Research_WoWSims_Damage_Matrix.md).

## 18 November — Guardian v1.2 Barkskin APL-first Draft

[PR #89]([private historical reference; not publicly accessible]) registered a **32nd full APL revision**: Guardian v1.2 Draft, while preserving v1.0 Reported Working Current and byte-identical v1.1 Archive. The first 10-test v0.8.6 native counterfactual proves the new guarded known/ready Barkskin source cast (1 actual accept/aura with Defensives ON, zero OFF, no pre-44), while retaining two Roar presses ON; **16→14 accepted actions** in one 38-second source fight is a trade-off, not performance proof. The source fixture had to be extended to recognise registered Barkskin; this is not a tank mitigation/survival simulation. Latest complete candidate import/CI and live approval remain separate, pending gates. [Research](../Research_Druid_Guardian_v1.2.md) and [test ledger](../Tests_Druid_Guardian_v1.2.md). Numeric sims stay deferred.
