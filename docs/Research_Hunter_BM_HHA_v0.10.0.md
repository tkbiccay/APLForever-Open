# Hunter BM v0.10.0 experimental HHA engine-capability comparator

**20 November 2026 — DRAFT / SOURCE TEST EXPERIMENT ONLY; not a new game APL**. Equal first priority: Hunter BM and Guardian/Feral Tank. Do not edit selected/current/last-working or the complete BM v1.2 Candidate.

## Research / hypothesis

Released [Hekili Forever v0.10.0 Hunter.lua](https://github.com/zmsl/hekili/blob/v0.10.0/src/Hekili_Hunter/Hunter.lua) lines 1362–1375 registers a looped native window `hha`, available with `window.hha.next.summon_hawk` and `window.hha.next.arcane_shot`, opened when `combat>0`. The three steps are Summon Hawk, Summon Hawk, Arcane Shot. The [official windows reference](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Windows.md) confirms that custom APLs can read registered windows; `settings.*` is not needed.

**Do not equate a strict HHA sequence with optimal damage.** Published Hunter class registration: Hawk 0–35 yd and up to two modelled living guardians; Arcane Shot 8–35 yd and category CD shared with Hawk. Existing BM v1.2 uses the **source-accepted Hawk range alone**. At 6 yd (5–8 dead zone) a hard HHA chain can stop on Arcane's unavailable cast while Hawk remains legal. Native range brackets may be unknown in other gameplay modes; `action.<key>.in_range` is preferable.

## One cheap native experiment, no new APL

`experiments/native/aplforever_bm_hha_v010_spec.lua` imports the **complete** BM v1.2 from the current protected catalogue file into the released v0.10.0 engine and compares an **in-memory** alternative modifying exactly two named lines (Hawk and Arcane conditions only) to use native `window.hha.next`. No new APL bytes or catalogue revisions are created. It advances the real source-native world on the same seed at 12 yd and at 6 yd with Major Cooldowns OFF, logging actual pressed actions, cost/availability refusals, number of Hawks/Arcane Shots, errors and tail behaviour. The focused [workflow](../../.github/workflows/bm-hha-v010-experiment.yml) pins upstream commit `3c2cf3e32472cc807b1ba29d992fc13a273da8ee` and only runs this experiment + immutable validation.

**Acceptance before any candidate:**
- Non-vacuous real source-accepted casts and no errors/refusals on both distances.
- HHA at legal 12 yd must actually recommend and cast Hawk and Arcane. Differences measured; no claims about DPS without DPS simulation/live performance.
- At 6 yd, no Arcane or other illegal 8yd spell. If HHA freezes the loop on its Arcane step and yields fewer safe Hawk casts than the existing priority, the pure HHA-gated design is **Rejected / Source-Native Regression**. Do **not** silence, skip or call that benefit.
- Maintain main pet recovery, low-Mana fallback, level 1–60 unlocks, cooldown OFF/ON and user-mode/engine restriction gates on any later independent full APL candidate.
- If an experimental option fails at import/compile, record true warning and source/fixture cause; do not promote.
- If HHA is useful only in bounded range, consider a **carefully tested hybrid** that preserves independent 6yd Hawk support, not a setting, new addon checkbox or forced global sequence.

## Native outcome — 20 November 2026, released v0.10.0

**Focused CI PASS:** [run 44702212894](https://github.com/tkbiccay/APLForever-Open/actions/runs/44702212894), `2 successes / 0 failures / 0 errors / 0 pending`, seed **30417**, source-world combat **42s**, Major OFF. The two profiles here were compared by accepted **cast counts**, not numerical DPS:

| Distance | Full v1.2 Candidate | In-memory pure HHA gate | Outcome |
| --- | --- | --- | --- |
| 12 yards | 13 accepted; Hawk **4**, Arcane **3**; 0 refusals | 13 accepted; Hawk **5**, Arcane **2**; 0 refusals | Different priority, **no total accepted-cast gain**, no DPS proof |
| 6 yards | 7 accepted; Hawk **5**, Arcane **0**; 0 refusals | 4 accepted; Hawk **2**, Arcane **0**; 0 refusals | **HHA gets stuck after its two Hawks at an uncastable Arcane step**; accepted actions and upkeep degrade |

The source-world's automatically advanced events also fell from **489 to 285** at 6yd for the HHA-gated profile, and its last observed accepted-icon samples were empty. This is consistent with a blocked HHA window, not a usable third step. The source-world's synthetic ranged Auto Shot at 6yd remains an acknowledged fixture limitation; the above *on-demand Hawk/Arcane cast* range checks are still source-grounded.

**Architecture decision: REJECT pure unconditional HHA gating.** A focused native suite being green means its checks were executed successfully, **not** that its tested hypothesis won. Keep v1.2 byte-for-byte. A *bounded hybrid* may later be investigated, but **only** if it preserves 6yd accepted Hawk behaviour, avoids repeated-fallback refusal or no-action tails, and proves meaningful benefit at legal ranged distances against default **and** existing v1.2. Do not add a new setting or manual toggle to work around an APL design mistake.

The shipped Turret's specific six-yard refusal remains a separate historical *negative comparator*; do not claim this experiment fixes its engine or proves in-game damage/uptime. Guardian and BM remain equal first priority.

## Follow-up range-aware hybrid (source-native tested; benefit INCONCLUSIVE)

Source-supported input `action.arcane_shot.in_range` can distinguish whether to follow the registered HHA window or use the source-accepted independent Hawk cap. The third in-memory variant, `hha-range-hybrid`, keeps native HHA coordination at legal ranged distances but permits an independent Hawk when Arcane Shot is **observed out of range**. Both versions still require `action.summon_hawk.in_range` and `pet.hawk.count<2`, and use exactly the same full imported v1.2 source plus only two condition substitutions. No `settings.*` or user checkbox is added.

**Hypothesis:** retain the baseline's repeated legal Hawks across the six-yard dead zone without losing normal-range HHA's sequencing; test actual source-accepted Hawk/Arcane and refusals at both distances before considering any code. `action.<spell>.in_range` is a client range check but does not guarantee the same accuracy under all instanced/hidden conditions, so an observed source-world result is not the full gameplay gate.

The full 3-profile focused [v0.10.0 native run 44702973404](https://github.com/tkbiccay/APLForever-Open/actions/runs/44702973404) **PASSED 2/2 checks**; no refused casts, source errors or raises in any tested scenario. In matched seed 30417, 42s, Major OFF:

| Source-world distance | Baseline v1.2 | Pure HHA gate | Range-aware hybrid | Decision |
| --- | --- | --- | --- | --- |
| **12 yd** | 13 accepted, Hawk 4, Arcane 3 | 13 accepted, Hawk 5, Arcane 2 | **13 accepted, Hawk 5, Arcane 2** | Hybrid behaves as HHA when Arcane is in range; **no accepted-count gain**, damage not measured |
| **6 yd** | 7 accepted, Hawk 5, Arcane 0 | **4 accepted, Hawk 2**, stalls after 2 Hawk casts | **7 accepted, Hawk 5, Arcane 0** | Hybrid preserves baseline's real source-accepted six-yard upkeep and tail |

**Decision: hybrid is Source-Native Supported for these narrow ranges, but `Experimental / Not Promoted` overall.** There is no demonstrated DPS/output improvement or evidence for raid/group, AoE, Major ON, long resource-exhaustion, different gear/talents, other distances, pet recovery or live Auto Shot timing. Preserve v1.2 exactly and defer further hybrid refinement until targeted gameplay or damage evidence establishes meaningful upside. If advanced syntax creates only an equivalent recommendation with more complexity, default to simpler last-working/candidate architecture.

## Evidence and costs

No test results before the CI finishes; tests only establish world-cast correctness and a comparative trace. Known benchmark defect: shipped Turret repeatedly recommends 8–35yd Serpent Sting at 6yd, yielding 109 real range refusals on pinned v0.9.0; **our baseline must not inherit this**. Synthetic Auto Shot at 6yd is not reliable for white-attack clipping.

Next after this opportunity: inspect registered `window.weave` and the real Auto Shot/next swing timing signals; only build a movement/weave Candidate if source range and pacing can be modelled safely, without relying on manual movement toggles or imagined range.
