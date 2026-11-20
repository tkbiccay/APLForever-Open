# Guardian/Feral Tank — independent Roar upkeep (v1.4 Draft)

**20 November 2026.** Hekili Forever official **v0.10.0** `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`; standalone full APL `roles/Druid/Candidates/APL_Druid_Guardian_v1.4_Draft.txt` SHA-256 `03cc2ef5df2ed18228e8437adf9218ea59f9e2e816243978bee9c68aa501c464`. Draft PR #22 and discussion #21. **Not selected or approved.**

## Why and supporting sources
The maintainer explicitly prefers rotation decisions in APL rather than manual addon toggle/micromanagement. Demoralising Roar is a Bear Form 10-Rage, GCD, 30-second Attack Power debuff with optional raid-maintenance setting in [v0.10.0 Druid source](https://github.com/zmsl/hekili/blob/v0.10.0/src/Hekili_Druid/Druid.lua). [Forever Wowhead tank rotation](https://www.wowhead.com/forever/guide/classes/druid/feral/rotation-cooldowns-pve-tank) and [Method Forever tank guide](https://www.method.gg/wow-forever/class-guides/feral-tank-druid/rotation-and-playstyle) both recommend maintaining an Attack Power reduction when worthwhile. [Wowhead levelling guide](https://www.wowhead.com/forever/guide/classes/druid/feral/tank-leveling-tips) emphasises multi-target tanking use. These sources do **not** validate the chosen 4/5/12-second thresholds.

The [current-source condition availability](https://github.com/zmsl/hekili/blob/v0.10.0/docs/wiki/APL-Conditions-On-Forever.md) verifies `group`, `tanking`, `solo`, `target.is_boss`, `time`, `rage.lo`, `debuff`, with limits. In dungeon/raid boss instances `target.is_boss` may be false, `target.within5` is estimated/true when range unknown, `active_enemies` often 1 without nameplates. Combat time-to-die, player HP and incoming damage are **not** truly observed; avoid inventing defensive emergencies.

## Original APL-first decision
Only **one** full APL line differs from protected v1.3: Roar's rule no longer reads `settings.maintain_demoralizing_roar`. APL controls Roar autonomously if known, near target, not already debuffed and conservative Rage bound >= cost+10, in combat:
- **Grouped & tanking** after >=5 s; `group&tanking` source signal (positive live behaviour still unproven).
- **Source-identified boss** after >=4 s, including a solo world boss when visible (dungeon boss flag can falsely be absent).
- **Solo & tanking** after >=12 s, preserving instant levelling/ordinary kill resources.
Timing and +10 reserve are design hypotheses, not simulated optimal DPS/TPS; priorities should not fire unsafe/unaffordable Roar. Debuff check suppresses repeated upkeep where tracked.

**Intentionally retained:** `toggle.defensives` for optional Barkskin use and `toggle.cooldowns` for optional Elune's Light. They are **explicit player off-switches for discretionary cooldowns**, never prerequisites for routine damage/mitigation Roar. In future a fully automatic defensive policy would require separate proof; hidden HP means the APL cannot safely replace manual emergency decisions merely by ignoring OFF switches. All other abilities, priority and final Maul fallback remain byte-for-byte as v1.3.

## Default / rollback / candidates
- Published WoWSims-derived shipped default: raid maintenance setting, kept as research benchmark; its simulator default is not the player's addon default.
- Protected preferred and last-reported-working **v1.0**: SHA `f386e158a5e262e309dac7d0fd2929fb8e16e02b1378d71b5956c1bf6b99a786`, Reported Working / Needs Retest.
- **v1.2 Draft** SHA `da358b7c04b47732966c47a91b7f6f5d32410f9077aabe2aac39252139a47b76`: both Roar and Barkskin gated behind Defensives ON.
- **v1.3 Draft** SHA `200d7109ffcc345c41b05312a49b658b9a456a6f17fb56ea952f84d1d57079e0`: Roar still has optional addon maintenance-setting dependency, native focused v0.10.0 18/18 PASS; preserved comparator.
- **v1.4 Draft** new setting-free Roar, all original files and last working unchanged. Candidate only; no claimed throughput/survival gain.

## Evidence gate
Source-native exact-head comparison and normal/boss solo settings-independent tests in `tests/native/aplforever_guardian_barkskin_v086_spec.lua`. Historical low-level/three-press/final fallback test extended in `aplforever_guardian_highkit_tail_v090_spec.lua`. Tests may be red until validated. Real **group+tanking** positive remains blocked in harness; only a short live example or source-faithful threat fixture can establish it. Never promote from green synthetic boss tests alone.
