# Feral DPS v0.10.0 — observed threat and Barkskin architectural experiment

**20 November 2026. Status: Experimental — not a new APL or approved performance change.** Guardian Tank and Hunter BM are equal P0; Feral DPS is next. Work is a single focused source-native comparison in [Draft PR #25](https://github.com/tkbiccay/APLForever-Open/pull/25). Protect all complete APL hashes and their exact revisions. No selected APL or rollback is changed.

## Exact source and reason for the hypothesis

- [Forever v0.10.0 release](https://github.com/zmsl/hekili/releases/tag/v0.10.0), immutable commit `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`. No Retail/Classic/SoD assumed.
- [Druid.lua class registration](https://github.com/zmsl/hekili/blob/v0.10.0/src/Hekili_Druid/Druid.lua#L911-L927): `barkskin` id **22812**, 60-second cooldown, **spell GCD**, **Defensives** required toggle, registered Barkskin aura; learn level 44 (source-backed in existing Guardian tests). Never mark `use_off_gcd=1` for this ability.
- [Engine State.lua](https://github.com/zmsl/hekili/blob/v0.10.0/src/Hekili/Engine/Sim/State.lua#L2399-L2428): `aggro` is `UnitThreatSituation("player")>1`; `tanking` is **`role.tank and aggro`**. The published Feral test client reports **DAMAGER**, so selected Feral DPS APL `tanking` is false even when source client reports high threat. Real client threat and role need live calibration.
- [Forever health conditions](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Conditions-On-Forever.md): player's `health.pct` is effectively 100 in combat, therefore original full Feral v1.0's three low-health defensive branches cannot work. The existing unselected **Feral v1.2** removes those conditions and was source-validated for ordinary progression, but its single `tanking`-gated Barkskin path had never made a real positive cast in the stock Feral world (which omits Barkskin).
- [Line options](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Line-Options.md) describes `line_cd` as a per-entry post-cast cooldown; [expression reference](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Expression-Reference.md) permits `gcd.remains<=0`. Both still require a **real no-refusal test**, and are not inherently fixes.

## Test-only designs (complete Feral v1.2 imported every time)

The [single A/B source-native test](https://github.com/tkbiccay/APLForever-Open/blob/experiment/feral-aggro-defensive-v010-20261120/experiments/native/aplforever_feral_aggro_defensive_v010_spec.lua) substitutes only the complete v1.2's Barkskin condition **in memory**. The released engine and fake client's source API `UnitThreatSituation` are *not altered*; this fixture supplies a controlled client threat answer before class load, because `State.lua` captures the function then. The test adds known source-registered Barkskin **only** to the stock Feral development-world spellbook and maps its actual published buff-aura effect (the world otherwise lacks it). It retains natural world actions/Rage/Energy/casts and only asserts native accepted Barkskin/auras, refusals and counts. **Threat is controlled, not independently observed from game; no damage reduction, HP, or survival is modelled.**

Profiles:
1. Complete unmodified Feral v1.2 with `tanking` condition.
2. Same complete APL, `tanking` replaced by native `aggro` and `(group|active_enemies>=2)` at melee range; original Defensives, ability-known/ready and aura guards retained.
3. Same aggro experiment with `line_cd=2` to test whether post-cast rate limiting solves any double suggestion.
4. Same aggro experiment with documented `gcd.remains<=0` explicit availability check.

All matched source-world runs use seed **30417**, 38s, group = 2 or solo, high observed threat or none, Defensives ON or intentionally OFF, no fake HP, no extra user checkbox, complete precombat/Cat/Bear/caster/final fallback lists.

## Measured source-world results so far (do not erase failed experiments)

[First diagnostic run 44735722170](https://github.com/tkbiccay/APLForever-Open/actions/runs/44735722170):

| Case | Native Barkskin cast | Refused presses | Result |
| --- | ---: | ---: | --- |
| v1.2; DAMAGER-role, high group threat, Defensives ON | 0 | 0 | Confirms original `tanking` branch is unreachable on this client role |
| In-memory aggro branch; same threat and toggles | **1**, with actual aura applied | **1 GCD refusal** | **REJECT** as safe replacement despite positive cast |
| Aggro branch; Defensives OFF | 0 | 0 | User off-switch respected |
| Aggro branch; no observed threat | 0 | 0 | No unnecessary defensive |
| Aggro branch; solo single target | 0 | 0 | No unnecessary solo defensive |

[Second run 44736036375](https://github.com/tkbiccay/APLForever-Open/actions/runs/44736036375) confirmed that adding `line_cd=2` **does not fix** the duplicate recommendation: 1 source-accepted Barkskin, 1 refused action (`gcd`), applied aura. All negative controls still produced 0 Barkskin / 0 refusals. `line_cd` is a **post-cast** refractory and therefore may not protect an attempt that occurs before the first successful cast. This is consistent with the first two recommended icons both being Barkskin, but the timing mechanism is not conclusively established.

**Decision gate:** the further `gcd.remains<=0` controlled variant must produce **one accepted Barkskin, one registered aura and ZERO refusals** while preserving all ON/OFF/group/solo controls. If it does not, **STOP** rather than add speculative syntax or waive the refusal. A source-native conditional cast alone is not optimisation; it needs an actual safe cast chain and gameplay value before a full new Candidate can be justified. A green comparator test that *expects* a rejected design's exact failure remains a **negative test**, never a positive promotion result.

## Rollback, limits and next step

Protected **Feral v1.0 Current Draft**, **Feral v1.1 historical Draft** and **Feral v1.2 complete Candidate** remain byte-for-byte unchanged. No changes to preferred selection or catalogue, no new v1.3 until sound evidence exists. Original v1.0 is **not** a confirmed gameplay-working rollback; do not mark it Approved. The selected all-role v0.10.0 gate remains **Partial / failed** for its in-combat health warnings, and Warrior Arms' separate phase-insensitive precombat warning needs precise treatment rather than global suppression. Headless cannot measure live player mitigation, real WoW role/aggro visibility or real game client damage.
