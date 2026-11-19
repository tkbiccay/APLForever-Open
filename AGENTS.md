# APLForever-Open — canonical development instructions

**This public repository is now the only active development and delivery destination.** The old private `tkbiccay/APLForever` is strictly a **read-only historical reference**, NOT an upstream to push to, auto-mirror, mutate, track new issues against or run modern CI in. Never modify the private repository or link to private CI as the public proof of a test.

## Goal and priority

The concise operating contract is [docs/PROJECT_PRIORITIES.md](docs/PROJECT_PRIORITIES.md): **(1) fully standalone original APLs per supported role; (2) truthful, efficient native/headless validation; (3) verified cross-spec resolution transfer; (4) human/ChatGPT leadership with Codex ONLY on explicitly delegated bounded tasks; (5) immutable rollback/approval protection and a friendly openly AI-developed hobby ethos.** GitHub fun facts are separate from actual APL correctness and may not drive artificial commits.


Build ONE self-contained, adaptive, safe, castable Hekili Forever APL per supported spec/role. Joint first priorities: **Druid Guardian/Feral Tank (catalogue Druid_Guardian) AND Hunter Beast Mastery (catalogue Hunter_BeastMastery), equal priority → Druid Feral DPS → remaining roles**, unless a critical cross-spec safety or current-release compatibility regression pre-empts them. Maintain levels 1–60 and viable ST/AoE, levelling/world/dungeon/raid scenarios without inventing data.

Shipped WoWSims-derived/default rotations are research references and test comparators **not architectural ceilings**. Consider original priorities, talent/level guards, pet/form/stance/cooldown/defensive/utility options and safe end-of-chain fallbacks, only when the current released engine actually supports the required actions and observations. Respect player Major/Minor Cooldowns, Defensives, Interrupts and Potions toggles; verify named items and helper states.

## Universal efficiency rule: Research once → Preserve → Reuse

This rule applies to **all work**, not just recurring APL bugs: spell/talent discovery, user toggles, engine/API/Belief constraints, fixture design, regression triage, CI architecture, security, docs and release review. **Before new work, query existing verified knowledge and previous failed attempts; after new evidence, record the minimum reusable source-pinned fact, scope, outcome, uncertainty and next decision; before reusing, validate applicability.** Preserve positive AND negative evidence and exact hashes/rollback. Never repeat research or build a new abstraction solely to appear productive. Avoid churn, bulk sweeps, gratuitous AI/Codex calls or duplicated documentation.

Canonical source facts: [class mechanics JSON and generated reference](knowledge/README.md). This material is **development-time only**; no imported APL depends on a cross-role knowledge file or common custom runtime logic. Separately label native toggle vs suggested APL lane and verified mechanical fact vs interpretation/unknown. The source pin and validator cannot establish in-game behaviour or approve an APL.

## Main-first development and branch lifecycle

**Canonical working location is protected `main`**, not a growing set of permanent feature branches. Keep verified source/knowledge/docs and **all catalogue-declared standalone Draft Candidates on main** in `roles/<Class>/Candidates/`. `Current` is the explicitly selected development/test or player reference; `Checkpoints` retains approved/reported-working rollback snapshots where applicable; `Archive` is history. Always check catalogue status, `preferred_apl`, `last_working_apl` and hashes. **`latest_revision` does not select a Candidate.** Merge-to-main or green CI does **not** promote the Candidate.

For each bounded change: start from the latest `main`, create **one short-lived PR branch**, preserve exact old files, run cheap validator plus relevant pinned source-native tests, merge to protected `main` when reliable, and **delete the merged branch**. Branch cleanup is GitHub UI/Settings because not every connector exposes ref deletion. Never delete an unmerged/unreviewed branch or bypass the `main` PR protection to save clicks. Enable GitHub's native **Automatically delete head branches** setting; do not build a custom deletion bot or accumulate permanent "development" branches. Read the [one-page navigation and workflow](docs/WORKING_FROM_MAIN.md) before creating another branch.

## Evidence and approvals

1. Verify latest tagged **Hekili Forever** release/commit and source documentation; validate version-specific syntax, IDs, real resources, observation/Belief limitations, shipped kit and defaults. Check credible Forever-relevant independent guides; don't import Retail/Classic/SoD or synthetic oracle claims as live truth.
2. Preserve **exact selected, last-working, approved and shipped comparator bytes** plus SHA-256 and rollback. APLs are complete standalone import files; internal lists must be defined inside the same file; no other APLs/custom runtime helpers required.
3. Audit **every reachable action list** and **final/repeated fallback**, including low level, low/unknown resources, DoTs/upkeep expiry, ST/AoE, CD toggle OFF/ON, facing/movement, ready-but-unaffordable and unaffordable repeat suggestions. Particular regression: **DEMO-006** post-DoT Life Tap repetition; symptom reported, root cause unconfirmed.
4. Test with actual released Hekili native import/compile/Belief/accepted-refused cast progression. Compare **shipped default and last-working** under matched settings; use headless tests first and ask for irreducibly in-game `/hek snap` evidence. Replay and WoWSims numbers don't prove in-game reliability or approval.
5. Log source pins, assumptions, failed tests, noise/variance, unchanged regressions, lesson transfer and next minimal test. Inconclusive comparisons protect last-working. Do not auto-promote Current/Candidate from CI.

**Testing priority:** native correctness, responsiveness, fallback repeat safety > unproven numerical sims. Use a lean risk-based test pyramid: fast integrity checks for every PR, focused released-source regression checks for changed mechanics, broad cross-role gates only for releases/shared-engine changes, and live validation only where simulation cannot faithfully reproduce observed behaviour. An unreachable optional positive experimental scenario is BLOCKED, never secretly waived or counted as passed; isolate it from unrelated baseline acceptance while preserving its strict test and evidence. Keep both co-priority roles progressing without speculative parallel churn. ChatGPT and the human maintainer lead decisions; Codex works only on explicitly delegated bounded engineering tasks. See [AI-first working model](docs/AI_FIRST_WORKING_MODEL.md).

 Optional WoWSims DPS simulation needs a concrete decision and faithful model, not a bridge by default.

## Lifecycle and maintainership

Catalogue is canonical after migration. `roles/<Class>/{Current,Candidates,Checkpoints,Archive}/` and original APL SHA-256 are protected. No overwrite of historical APLs; new candidates get new filenames. Roles: 28 intended; 23 supported / five healer roles previously blocked pending verified engine triage support (re-check upon migration). Never claim historical private results are independently rerun in public.

Only **@tkbiccay** can make official merges, statuses, releases. No contributor or agent gets blanket permission to change protected `main`; use small PRs with green real CI and explicit owner review, not mandatory second human approval. Reuse previously verified source observations/fixtures and report unsupported conditions honestly. `GPL-3.0-only` for original work; protect licences for any reused third-party source.

## Current development checkpoints

**Public baseline merged through PR #1:** 32 immutable APL revisions and independent tests are now on protected main. PR #2 **merged** pinned v0.9.0 scoped source-native compatibility; [final reconciled public run 44469961206](https://github.com/tkbiccay/APLForever-Open/actions/runs/44469961206) **PASSED** its independent native gates. The separate strict positive Maul experimental test remains BLOCKED under issue #3: no verified natural Rage reserve was reached; it cannot support a Maul reorder. No role becomes Approved from source-native CI. Treat Guardian and Hunter BM as co-priorities after a properly scoped source gate. BM v1.1 Draft remains in Current and **v1.2 Draft now resides in main/Candidates**, but its catalogue `preferred_apl` is deliberately null. Do not silently set a preferred or Approved status. PRs #6, #8 and #9 merged into main after their respective checks; the sole live working tree is main. See `docs/CODEX_CONTINUATION.md` and `docs/AI_FIRST_WORKING_MODEL.md`.


## Project history and fun facts

First documented APLForever work: **7 November 2026**. Public APLForever-Open created **18 November 2026**, with clean separate Git history. The read-only [fun-facts workflow](.github/workflows/project-fun-facts.yml) runs weekly/on demand and produces a job summary/artifact; never let stats generation push to protected `main`, touch private source history or become a reason for unnecessary PRs. Source of truth for finished APLs is still catalogue/roles.json and executed tests, **not** commit or line counts.

## Provider-neutral handover: ChatGPT, Claude, Grok, Codex or another connected agent

**Every new session can restart from public GitHub without old chat context.** The repository—not a model's memory, a historical private repo or an unstated GitHub Project board—is the source of truth. No AI provider has special authority to promote an APL. Use this deterministic restart sequence:

1. Connect to and verify access to `tkbiccay/APLForever-Open`; read **this AGENTS.md**, `README.md`, `docs/knowledge/CONTINUATION_HANDOVER.md`, `docs/PROJECT_PRIORITIES.md`, `docs/AI_FIRST_WORKING_MODEL.md`, `catalogue/roles.json` and `docs/knowledge/lessons/CROSS_APL_TRANSFER.md`. Consult `docs/CODEX_CONTINUATION.md` only for bounded implementation tasks; its label does not give Codex ownership.
2. Query **live** protected `main` head/ruleset, open PRs/issues, Actions job steps/results, exact APL SHA-256 and newest **published** `zmsl/hekili` release/tag commit. GitHub checks may be red, pending or older than the newest PR commit. Don't equate an older green run with the current head.
3. Pick the smallest **unsettled** first-tier decision: Guardian/Feral Tank **and** Hunter BM co-equal; Feral DPS next. Read the existing role's entire APL, shipped reference, current-source registration and exact tests **before** proposing a new revision. Preserve both default comparator and last-working rollback, even where catalogue `preferred_apl` is null.
4. Reuse verified source pins, tests and cross-role lessons. Classify each relevant ability as rotation/upkeep, Major, Minor, Defensive, Interrupt, Potion/item or manual utility **and** independently verify its native toggle and APL guards. See `docs/AI_FIRST_WORKING_MODEL.md`. Never assume a numerical sim, a first icon or a synthetic resource oracle proves an actual cast.
5. Make bounded source-backed changes on a feature branch with a Draft PR. Run fast public validation, only the needed released-source headless scenarios, and retain failed-first evidence. State what tests were **Not Run / Blocked / In-Game Only**. No speculative mass revisions, silent promotions or automatic merge.
6. Before ending substantive work, update `docs/knowledge/CONTINUATION_HANDOVER.md` **on that PR branch**, with exact PR/commit/CI link, verified outcome, protected SHA/status, suspected versus confirmed root cause, smallest next step, cross-spec applicability and any owner-only gameplay request. The handover must stand alone without this chat.
7. A human maintainer decides actual import testing, Approved state and official merges/releases. Community contributions remain welcome; **never** edit the historical private archive or bypass main protection.

Development objective: **one safe, castable, original, standalone Forever APL per supported role**. Optional DPS/Tank/Healer sims wait until a specific verified APL decision needs them; cross-role reuse is at the test/research-method level, not a shared runtime APL dependency.
