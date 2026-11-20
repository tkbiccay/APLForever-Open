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

## Evidence and costs

No test results before the CI finishes; tests only establish world-cast correctness and a comparative trace. Known benchmark defect: shipped Turret repeatedly recommends 8–35yd Serpent Sting at 6yd, yielding 109 real range refusals on pinned v0.9.0; **our baseline must not inherit this**. Synthetic Auto Shot at 6yd is not reliable for white-attack clipping.

Next after this opportunity: inspect registered `window.weave` and the real Auto Shot/next swing timing signals; only build a movement/weave Candidate if source range and pacing can be modelled safely, without relying on manual movement toggles or imagined range.
