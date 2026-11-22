# Warlock Affliction — published Forever v0.11.0 combat/fallback breadth

**22 November 2026; BREADTH role-specific source-native.** Source `zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b` (published Forever v0.11.0). Protected Current v1.0 Draft `roles/Warlock/Current/APL_Warlock_Affliction_DPS_v1.0_Draft.txt` vs shipped WoWSims-derived APL, full source importer/active lists. [PR #81](https://github.com/tkbiccay/APLForever-Open/pull/81); [native CI run 45085850377](https://github.com/tkbiccay/APLForever-Open/actions/runs/45085850377): **6 successes / 0 failures**, two seeds, three scenarios, **12 full-profile released-source executions**; no new APL or catalogue selections.

## Measured source-world results

| Seed | Scenario | Shipped accepted / refused | Protected Current accepted / refused | Current next-three after first DoT |
| --- | --- | --- | --- | --- |
| 30417 | 25yd normal Mana, 65s | 23 / 1 | **19 / 0** | siphon_life, wrack, shadow_bolt |
| 30437 | 25yd normal Mana, 65s | 21 / 0 | **18 / 0** | siphon_life, wrack, wrack |
| 30417 | 25yd at 25% starting Mana, 90s | 33 / 1 | **15 / 0** | searing_pain ×3 |
| 30437 | 25yd at 25% starting Mana, 90s | 33 / 1 | **15 / 0** | searing_pain ×3 |
| 30417 | diagnostic 60yd, 28s | 11 / 0 | **8 / 0** | siphon_life, wrack, shadow_bolt |
| 30437 | diagnostic 60yd, 28s | 11 / 0 | **8 / 0** | siphon_life, wrack, wrack |

- In both normal 25yd seeds Current applied its source-accepted DoTs and followed with **at least three genuine later accepted actions**, zero refusal/errors/raises. No inference of DPS, actual DoT damage, optimal uptime or real castability at other levels.
- At 25% starting Mana Current accepted **15 actions**, with **0 Life Taps**, **0 Shadow Bolts/0 Wracks** in both seeds, finishing at **202 source Mana**. Shipped accepted 33 with **eight accepted Life Taps**, finishing at 1733/1777 Mana, but it had **one refused action per seed**. This is a **distinct resource-conversion/final-fallback architecture difference**, not proof shipped is safer or better. Source-world Life Tap emits a Mana gain, **does not model player health loss** (dangerous real-game effect). Do NOT copy unconditional Life Tap into protected Current. The absence of this ability in Current APL is directly visible in its complete file; no health/cost proof for an automated version exists yet.
- **Published source-world range limitation independently recurred:** at `WORLD.distance=60` both complete profiles source-accepted offensive casts (shipped 10, Current 7 per seed). The class helper describes range but native source `C.usable` does not explicitly reject on distance; actual client range and observed displayed icons remain **Unverified**. This is *not* a justification to delete `in_range` guards or claim that real-world casts at 60 yards are valid.
- **Final Fallback / Repeated Recommendation checkpoint:** no actual source-refused Current actions in all six worlds, including low Mana after DoTs. At low Mana repeated `searing_pain` was accepted, **not** DEMO-006-style unaffordable Life Tap spam; no readiness/prediction flicker measurement is claimed. The test checks three distinct later accepted *events*, not three distinct spell names; identical legal filler casts are not an automatic failure.

## Cross-spec transfer

**Symptom**: source-warlock distance model lacks effective 60yd rejection for these tested abilities. **Classification**: supported **source fixture/observability limit**, independently matching Priest Shadow #80; test before applying to other caster fixtures. **Lead**: resource-conversion after DoTs may affect Affliction/Demonology/Destruction, but require independent tested health-aware criteria and real client checks. The earlier protected Demo DEMO-006 report is a separate historic observation and is **not reproduced** here. See [cross-spec lessons](knowledge/CROSS_SPEC_LESSONS.md).

## Decision / next test

Current v1.0 remains Draft, no imported new Candidate, no blanket promotion. Next use a **different class** under portfolio breadth, e.g. Shaman Elemental, to compare hidden-Mana/clearcasting fallback and range fidelity at actually modelled source distance; then return to Warlock with real supported Life Tap safety evidence, or an unselected complete alternative only after a safe positive and negative castability gate exists. Live Saturday ask only if gameplay already encounters naturally relevant low Mana or range issue; do not deliberately spend Warlock health into danger.
