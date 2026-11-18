# Research — Druid Feral DPS v1.1 standalone Candidate

**16 November 2026. Grade: Source Confirmed / Source-Native Supported for Shred/Claw; Experimental for Rip and Mana conversion; Needs In-Game Validation.** No current Feral DPS version is Approved or reported working.

## Pin, selection and rollback

- Hekili Forever released **v0.8.5**, source SHA `a0a06583f458cca7a2ceaebb0b2ba0c4c783b946` from [zmsl/hekili](https://github.com/zmsl/hekili), tested in pinned CI.
- Source default [`Feral (wowsims.com).simc`](https://github.com/zmsl/hekili/blob/a0a06583f458cca7a2ceaebb0b2ba0c4c783b946/src/Hekili_Druid/APLs/Feral%20(wowsims.com).simc), WoWSims Forever data originally at `e5a9cd2a2dfc`. Used as **comparator only**, not a design constraint.
- Preserved exact [Current v1.0 Draft](../roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt), SHA-256 `f2f72d0621c8e709c7df8f2ccff248ce0af604a1c02e115a5ad725cf93d288f1`; **no ReportedWorking/Approved checkpoint**.
- One [Candidate v1.1 Draft](../roles/Druid/Candidates/APL_Druid_Feral_v1.1_Draft.txt), SHA-256 `f611e4510a52ca125103eed9f3d1d4fc99a0b656b161cdc88134f0e72b6e52f7`. Catalogue `preferred_apl` explicitly selects the original Current v1.0 **for import/testing only**, `last_working_apl=null`, `latest_revision=v1.1`. Neither version is production-approved.

## Independent Forever research reviewed

- [Method — Feral DPS Rotation & Playstyle, 4 November 2026](https://www.method.gg/wow-forever/class-guides/feral-dps-druid/rotation-and-playstyle): Shred behind target, Claw fallback, four-CP Rip comparable AP scaling, Rake upkeep, careful Ferocious Bite and Shifting Power energy windows.
- [Icy Veins — Feral DPS/Tank Rotation, 4 November 2026](https://www.icy-veins.com/wow-forever/feral-druid-melee-dps-and-tank-pve-rotation-cooldowns-abilities) and [levelling](https://www.icy-veins.com/wow-forever/feral-druid-leveling/): notes pure Cat versus hybrid priorities (notably 5CP Raid Rip versus 4CP on sufficiently long-lived levelling mobs), Shred only when positioned behind, Claw in front, Shifting Power ~50 Energy.
- [Mobalytics — Feral Druid DPS Guide, updated 11 November 2026](https://mobalytics.gg/wow-forever/classes/feral-druid-guide): no Cat before 20, Rake unlock 24, Bear 10–20, Bear useful against larger packs; Mana scarcity makes involuntary swapping expensive.
- [Wowhead Forever — Feral talents and PvE rotation, 4/11 November 2026](https://www.wowhead.com/forever/guide/classes/druid/feral/talent-builds-pve-dps): support for separate pure Cat versus hybrid builds; various user comments are not validated proof. Maxroll-specific **Forever** guide was not verifiable from search/robots and is **not substituted with Retail**. No unverified site-wide conclusion was transferred.
- **Authoritative implementation:** [pinned Druid.lua](https://github.com/zmsl/hekili/blob/a0a06583f458cca7a2ceaebb0b2ba0c4c783b946/src/Hekili_Druid/Druid.lua) registers Shred (60 Energy minus 6 per Shredding Attacks rank), Rip (30 Energy, requires combo points), Rake, Shifting Power (55% base Mana, 40 Energy, 8s cooldown) and independent Cat/Bear forms. Source Feral world damage/position outputs are expressly **unmeasured**.

**Conflicts and applicability:** Icy Veins favours five CP for ideal endgame Rip while Method and Icy levelling describe four CP as workable; v1.1 makes *at least four* eligible but no native cast or live damage advantage is established. A target focused on another character is only an imperfect **behind-position proxy**; the simulator has no real facing sensor. Mobalytics highlights Bear packs; this custom DPS APL retains Bear handling **when manually in Bear**, but does not autonomously switch Cat→Bear on packs without reliable intent/Mana/survival evidence.

## Actual APL architecture and one-file contract

v1.1 is a complete single-file custom priority with the original precombat, Cat, Bear, caster, upkeep, finish, procs, major/minor cooldown, defensive and safe final fallback lists **defined entirely inside the same file**. It adds four bounded source-backed changes: Shred before Claw when the target does not focus the player *and* Shredding Attacks 2+ or Clearcasting is present; Shred on Clearcasting with Claw fallback; source-known Rake unlock guard; 4+CP Rip upkeep branch. Every call_action_list target is internal; **no other class/spec/APL/library file is needed at runtime**. Existing major/minor/defensive toggles remain deliberate player off-switches.

The v1.0 baseline had **zero Shreds** in the native target-on-other scenario, while untouched shipped used 17 Shreds. v1.1 accepted **20 Shreds** in that case and accepted 17 Claws when the target focused the player, with no world refusals (six-profile [PR #65]([private historical reference; not publicly accessible])). This shows *reachability and castability in the source world*, **not higher real-world DPS**.

## Crucial unconfirmed resource visibility

In all six source-native comparisons the world reached **5 true combo points**, yet sampled engine `State.combo_points.current` was **0 at actual 4/5 truth windows** (observed maximum 2 in the run). The test attempted `H.ctl.power[4]`, but that field was **nil** at the checkpoints; a printed `maxClientCP=0` came from `tonumber(nil) or 0` and **does not prove that real UnitPower or in-game combo points were zero**. The source observer is configured to emit plain combo-point events, but the exact disparity among source truth, observer/control accessor and engine state remains **unresolved**. Zero Rip/Bite presses in **all** three profiles may be due to this gap, not automatically a wrong Rip branch.

Likewise Shifting Power was *known* but `action.shifting_power.ready=false` in sampled windows, despite source-world Mana staying at 2674. **Why is not confirmed** (real player talent/known state, simulator secondary-resource model, readiness/observation or engine could matter). We must not fabricate Mana/points, conflate nil with zero or bypass unsupported combat APIs. The same root-cause classification should be reused as a *method* on other resource users, never as a copied runtime APL workaround.

## Decision

**v1.1 Draft Candidate only.** Current remains v1.0 Draft; no Checkpoint and no approval. Prioritise source-correct combo/secondary-Mana observation and a minimal real Shred-behind/Claw-front + finisher/energy live `/hek snap` when appropriate, before designing more finishers or touching protected role status. See [tests](Tests_Druid_Feral_v1.1.md) and [limitations](Limitations_Druid_Feral.md).

## 17 November source-fixture correction — supersedes earlier unknown native blocker

[Merged PR #66]([private historical reference; not publicly accessible]) traced a verified **headless fixture** issue: `pairs(content.OBSERVE)` ignores `plainPower`, `powerTokens` and `powerMax` inherited through `__index` in the previous test overlay. All six old source worlds earned true CP without corresponding power-4 client events; their zero Rip/Bite/Shifting Power observations cannot diagnose gameplay. Explicitly copying the pinned Feral source's own observer fields restored numeric CP observation and accepted Rip (6–8/world) plus Shifting Power (five/world), with no refused casts across all six scenarios. [Corrected source-native v0.8.5 CI]([private historical reference; not publicly accessible]) green; full details in [tests](Tests_Druid_Feral_v1.1.md). This is source-native **castability** evidence, not output superiority, behind-position proof or full 1–60 gameplay safety.

**Decision unchanged:** v1.0 Draft Current selected only for testing; standalone v1.1 Draft remains in Candidates; no reported-working Checkpoint or Approved APL. No APL source changed. The explicit old **unknown cause** above is retained as historical uncertainty, now resolved **for the test fixture**, not asserted to resolve every possible in-game condition.


## 18 November v0.8.6 targeted source reconciliation — no replacement candidate

**Source inspection only; no new native experiment or claim of corrected Feral Bite.** Official released v0.8.6 is zmsl/hekili at commit `2e9cb6a78d9088007e9acd9cce3eeb0e91463cc5`. Compared exact tagged files `v0.8.5` → `v0.8.6`:

- `tests/Forever/helpers/druid_loop_world.lua`: **entire file text unchanged**. It still defines `ferocious_bite = { effect = hit("ferocious_bite"), points = "all", drain = ENERGY }`, regardless of Predatory Discipline. `C.OBSERVE.plainPower = { [POINTS] = "always" }` also remains unchanged and is **not itself proof that the first-icon model sees source ComboPoints at decision time**.
- `tests/Game/State/helpers/fake_api.lua`: **entire file text unchanged**. `GetComboPoints(_, target)` continues to read `ctl.comboPoints[target]`, falling back to `UnitPower("player", 4)` when absent; the actual 5CP API/evaluator-time status must still be traced in a properly aligned test.
- `src/Hekili_Druid/Druid.lua`: overall file changed for unrelated v0.8.6 updates, but registered ComboPoints resource and **Predatory Discipline's extra-Bite-Energy preservation conditional** remain text-identical in the inspected source sections. Thus the source class's talent mechanic and the headless world's unconditional Bite drain remain **unreconciled**.

**Result / next efficient gate:** the existing [closed PR #74]([private historical reference; not publicly accessible]) artificially seeded early CP/Energy, did not create any eligible 5CP Bite decision, and observed many refused cost attempts. The released v0.8.6 fixture has NOT fixed that source/ground-truth mismatch. Do not repeat the same faulty setup or declare v1.1 Bite proven. Existing 93 Feral tests [v0.8.6 843-suite]([private historical reference; not publicly accessible]) remain valid for their covered progressions, not Predatory Discipline finisher fidelity. Either reconcile native **actual/evaluator/client observed** ComboPoints, Energy, Rip and Bite drain at one genuine source decision, or seek the bounded actual in-game `/hek snap` at 5CP, Rip >=6s and sufficient real Energy. Protect v1.0 Draft Current and v1.1 Draft Candidate; no APL changes or promotion. [Measurable cross-role progress](knowledge/PROGRESS_SCORECARD.md).
