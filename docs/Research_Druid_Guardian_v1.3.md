# Research — Druid Guardian/Feral Tank v1.3 Roar upkeep Draft

**19 November 2026 | Full standalone unselected Candidate | Hekili Forever v0.10.0** (published SHA `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`). Candidate SHA-256 `200d7109ffcc345c41b05312a49b658b9a456a6f17fb56ea952f84d1d57079e0`. [Design issue #21](https://github.com/tkbiccay/APLForever-Open/issues/21).

## Hypothesis and real input

Maintainer **reported** the Demoralising Roar recommendation appearing when **Defensives ON**. This is consistent with v1.2 but the active in-game pack and accepted press remain unidentified. Treat it as a design opportunity, **not** a demonstrated casting bug. The aim is to separate regular tank debuff upkeep from reactive defensive cooldown toggles, whilst avoiding GCD/10-Rage waste on ordinary solo enemies.

## Source and comparator pins

- [Official v0.10.0 Druid.lua](https://github.com/zmsl/hekili/blob/3c2cf3e32472cc807b1ba29d992fc13a273da8ee/src/Hekili_Druid/Druid.lua): `demoralizing_roar` ID 99, Bear Form, GCD, 10 Rage, applies a 30-second debuff. Shipped `maintain_demoralizing_roar` setting exists and defaults **OFF in-game**, ON in the native **sim scenario** to model raid-boss maintenance. Its description says fast open-world kills seldom justify it.
- [Official v0.10.0 APL conditions](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Conditions-On-Forever.md): `group`, `tanking`, `time` are readable; `target.within5` is an estimate that may match an unknown/unbracketed range. `target.is_boss` is not reliable for concealed dungeon bosses; enemy counts can be 1 without plates or in instances. No hidden health, incoming damage, `fight_remains`, boss identity or enemy count is presumed.
- [Source Guardian world](https://github.com/zmsl/hekili/blob/v0.10.0/tests/Forever/helpers/druid_loop_world.lua) implements actual debuff application with authentic combat Rage. It does **not** model actual mitigation, and cannot independently prove a visible group+tanking live state. The published source-trace in [P0 comparison](Tests_P0_Guardian_Hunter_v0.10.0.md) is the comparison for Barkskin and Roar.
- Other guides (Wowhead, Icy Veins, Maxroll, Mobalytics and WoWSims) remain broader spec-research references, **not asserted to validate this conditional auto-upkeep policy**. No unverified Retail/Classic mechanic is used.

## Full APL deltas from v1.2 (not an import diff)

Only two whole-file source lines changed in independent `roles/Druid/Candidates/APL_Druid_Guardian_Tank_v1.3_Draft.txt`: the mitigation list is called under Bear Form regardless of the generic Defensives toggle; its single Roar eligibility requires known ability, existing near-target/absent-debuff checks, and **either**:

1. Existing native `settings.maintain_demoralizing_roar` opt-in and at least the verified Roar cost; **or**
2. `group&tanking&combat>0&time>=5` and the Roar cost **plus 10 Rage** in Belief's conservative lower bound.

The five-second and ten-extra-Rage policies are hypotheses to limit GCD/opportunity waste, **not empirically optimal numbers**. In open-world solo with setting OFF, Roar should not be recommended. Defensives ON controls Barkskin only; Roar may appear with Defensives OFF when the maintenance conditions deliberately permit it. The existing addon setting, rather than a new project option, is the explicit manual override.

## Protected comparisons and decision

- **v1.0 Reported Working / Needs Retest** — exact protected preferred/rollback `f386e158a5e262e309dac7d0fd2929fb8e16e02b1378d71b5956c1bf6b99a786`, separate maintenance setting; no bytes changed.
- **v1.2 Draft** — exact `da358b7c04b47732966c47a91b7f6f5d32410f9077aabe2aac39252139a47b76`, Roar tied to Defensives and Barkskin under same toggle; unselected and unchanged.
- **Shipped default v0.10.0** — raid maintenance setting is benchmark and behavioural reference; not a constraint on the independent APL design.
- **v1.3 Draft** — not selected, not Approved. Must pass strict source import, known/rage, OFF/ON/setting, three source-advanced end-of-chain, and matched cast/refusal cases. Grouped active-tank **positive** and whether target.within5 misfires in unbracketed live range require faithful source signal or in-game `/hek snap`; do not manufacture a pass.
