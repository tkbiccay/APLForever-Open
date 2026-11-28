# APLForever-Open — priorities, success criteria and project ethos

**Started:** 7 November 2026 (first documented custom-APL project work). **Public GitHub home:** 18 November 2026. **Proudly AI-developed, human-maintained.** This is a fun GPLv3 hobby project, not a company product, a high-commit scoreboard or a promise of theoretical maximum DPS.

## What we are building, in priority order

### 1. One original, optimised, fully standalone APL per supported role

Aim for all **28 intended roles**, subject to the current Hekili Forever support gate (**23 Supported, five Blocked as at this note**). Every applicable role should eventually have one evidence-approved preferred APL that actually works in Forever's engine, not just a valid text file or a copy of the shipped priority.

APL-first means verified precombat, 1–60 level/rank/talent guards, forms/pets/stances, resource handling, single- and multi-target logic where observable, cooldowns, defensives, interrupts, items and user off-switches, plus the **entire reachable chain and safe final/repeated fallback**.

**No-checkbox autonomy is mandatory game-wide:** the complete APL must make routine decisions with stock/default addon settings, not require a user to activate per-spec maintenance/curse/poison/seal/form/pet options. See [the explicit APL Autonomy Standard](APL_AUTONOMY_STANDARD.md) and [all-revision audit](../scripts/audit_apl_controls.py). Optional Major/Minor/Defensives/Interrupts/Potions/Movement toggles remain **deliberate user off-switches**, subject to upstream's native Require Toggle gating; an APL cannot override an engine-disabled spell. Existing reported-working/settings-dependent APLs are protected debt to replace only after independent source-native and live evidence. Never convert everything en masse merely to achieve a static-zero-dependency report. No invented WoW API state, fake gains, or shared custom runtime dependency. Default WoWSims-derived APLs are research references and comparators **not architectural ceilings**: investigate alternative original priority orders without changing reported-working files on a hunch.

**Current equal top priority:** Druid Guardian/Feral Tank **and** Hunter Beast Mastery. Feral DPS follows. Critical source compatibility or a repeatable safety bug can jump the queue. The catalogue, not an evocative folder name, defines status; Hunter BM v1.1 in Current remains Draft with no preferred APL.

**Portfolio-first learning phase (22 November 2026):** P0 means urgent *when actionable*, not that the other Supported roles wait indefinitely. Until all 23 Supported roles have at least one meaningful pinned-current-release **native combat + final fallback** assessment, allocate approximately **three of every four independently substantiated new role-specific development units** to the least-served roles outside Guardian/BM/Feral; reserve the remainder for P0/P1 and allow any critical safety/release regression to pre-empt the target. Count **actual verified research, tests and independent full Candidate designs**, not hourly slots, imported-only passes, commits or check reruns. Rotate classes as practical; classify each finding as APL, source/engine/Belief, API/UI, test fixture/data, game mechanics or unknown, and test any purported cross-spec resolution independently. [Live 23-role coverage and next evidence](knowledge/ROLE_COVERAGE.md). This temporary breadth target complements rather than abolishes Guardian/BM equal P0, preserved player favourites, protected rollback and gameplay approval gate.

### External Hekili Forever releases are our compatibility target

We **do not own, control or maintain Hekili Forever**. Upstream `zmsl/hekili` independently publishes its addon, mechanics and API. We maintain only **our custom APLs**, research/tests and proofs. The goal is for our APLs to stay compatible with the **latest actually published stable release**; no forced redesign when source-native behaviour remains correct, but immediately log and diagnose a release-breaking fault. Never rely on unreleased upstream commits, ask upstream to change for our APL to work, or invent an unsupported engine read.

A lightweight [daily watcher](../.github/workflows/monitor-forever-release.yml) opens a review issue for a newly published upstream tag, with **no automatic changes to APLs or CI status**. After review, pin the exact commit in [current-release.json](knowledge/engine/current-release.json) and record each role's **source-native compatibility** separately from **in-game validation and approval** in the [release ledger](knowledge/engine/RELEASE_LEDGER.md). Use the existing source-native risk-based gates and protect exact defaults, Current, last-working and all Candidates. Release issues do not displace the equal Guardian/Hunter P0 development priorities except for real compatibility or safety regressions.

### 2. Headless proof that protects actual gameplay

The test system is a means to better recommendations, not its own endless project. Pin the current released Hekili Forever source, translated spell data, Belief limits, talents, gear, toggles and accepted/refused cast state. Test **default versus last-working versus candidate** in matched scenarios: opener, three presses, low-level unlocks, extreme and uncertain resources, CD switches, pet or form, ST/cleave/AoE, follow-on fallbacks and repeat-inappropriate suggestions.

Cheap static/hash/syntax checks always run first. Focused native tests answer targeted mechanics. Broader suites belong to actual source releases, shared-engine changes and pre-promotion regressions. Only player observations can settle behaviour the engine/harness cannot faithfully observe. A native PASS is **not** In-Game Validated or Approved; significant live regression overrides a simulation score. On uncertainty, retain last-working and log the gap. A blocked experimental positive test is not silently passed or allowed to conceal unrelated verified coverage.

### 3. Research once, learn across specs, transfer with proof

When we diagnose and resolve a defect, preserve the symptom, actual root cause, exact before/after and a regression fixture. Search other roles for the **same verified failure pattern**, then test those roles with their own independent APL mechanics. Reuse lessons and scripts; never make APL A depend on APL B at runtime. DEMO-006 post-upkeep Life Tap and repeated final fallbacks remain explicit cross-role safety checkpoints.

Maintain lean Research_, Tests_, Changelog_, Limitations_ and catalogue records with published version pins, conflicts, results, noise, negative tests, rollback IDs and the next narrow decision.

**Cross-Spec Research Multiplier (28 November):** Every material finding must be screened against all supported roles and applicable action families. Record exact baselines, scope, reasons, source and evidence in the existing transfer index; independently validate receiving-role adaptations before implementation/promotion. Negative findings transfer too. A scan is not an improvement; one root cause can justify many independent tests, not indiscriminate identical APL edits. The owner-selected Feral v1.6 engineering baseline is recorded in the portfolio, separate from player-facing selection and approval.

### 4. Human direction, genuinely useful AI assistance

The sole maintainer and ChatGPT lead priorities, source research, original design, triage, available validation and decisions. **Call Codex only for a specifically delegated, bounded engineering task** that benefits from its strengths; it reports evidence and stops. No autonomous code churn outside a maintainer-authorised AI Sprint, no surprise unrequested sprints or automatic gameplay APL promotions. We openly credit AI development and human validation, do not pretend AI is infallible, and welcome reproducible community criticism and GPLv3 contributions.

### AI Sprint — maintainer-authorised autonomous development (20 November 2026)

When the maintainer explicitly says **"AI Sprint"**, ChatGPT has permission during that conversation to research, invent complete standalone candidates, run scoped CI, investigate failures, manage feature PRs and **merge passing non-promotional Draft work without routine approval pauses**. This permission does not authorise overwriting original working APLs, selecting a different preferred/production APL or labelling a role Approved without repeatable real-game proof. Respect native player off-switches and any actual safety/engine limitations.

**Evidence not iteration count:** each autonomous action should resolve a source-grounded hypothesis, demonstrate a meaningful castability/safety improvement, or record negative proof. Protect every prior APL checksum and working rollback; keep source pins, original defaults and failed experiments reproducible; no invented gain, pet health, threat or cast. Abort changes on real regression and don't waive tests to force a merge. Only delegate specifically bounded work to Codex when it adds value, rather than generating churn.

An AI Sprint is active work in the current conversation, **not** a claim of unattended background work or a guaranteed timed hour after the response ends. The maintainer may interrupt, redirect or end it at any point. On a true game-only uncertainty, record the smallest useful in-game check and stop speculative candidate polish.
### 5. Rollbacks, integrity, scope and a sustainable hobby

Immutable Current/Checkpoint/Archive/Candidate history, SHA-256 checks, protected public main, owner-only merges, attribution, security/privacy screening and safe public GitHub-hosted CI protect the work. Old private APLForever is **read-only reference** with no automatic mirroring or future development. Never run untrusted public fork PRs on a private home/Hyper-V machine.

Spend time and AI/API/Actions credits only when they answer a worthwhile question. Prefer small, source-faithful decisions over premature DPS modelling, unverified complex branching or vanity automation. Publish honest failures and explain why an experiment is blocked.

## Universal efficiency: Research once → Preserve → Reuse

Apply to **everything we develop**: class ability/talent knowledge, range/toggles, code, CI, headless fixtures, bug/root-cause diagnosis, APL architecture, release reviews and documentation. Before spending credits or repeating a failed approach, check the single source of truth and existing source-pin/evidence. Save only the verified mechanics, limitations, rejected assumptions, failure traces and reproducible lessons. Reuse a proven concept or method only with role/source-specific proof and a guarded regression.

For the current equal-priority Hunter BM and Guardian pilot, class-level source facts and the exact source-registered 50 Hunter / 52 Druid talents live in [knowledge/classes](../knowledge/README.md); generated [BM](reference/Hunter_BeastMastery.md) and [Guardian](reference/Druid_Guardian.md) references avoid copying class metadata across specs. Native toggle and recommended APL intent are never conflated. Pin Hekili Forever release sources; unknown facts must stay unknown and source-world ranges do not establish live-client DPS or range safety. Knowledge is **not** an APL runtime dependency. Use targeted source verification rather than creating a permanent huge test infrastructure.

## What we celebrate

**Real progress:** more supported roles with complete, source-castable standalone APLs; safe fallback coverage; verified lessons reused across specs; maintained in-game approved rollbacks; fewer repeat bugs and less player micromanagement.

**Fun facts:** public commits, changed text lines, merged PRs, closed issues, role counts, historical APL revisions, forks and stars. They are for celebration, **not measures of correctness or reasons to create unnecessary commits**. See the [weekly read-only fun-facts workflow](https://github.com/tkbiccay/APLForever-Open/actions/workflows/project-fun-facts.yml). It writes a run summary and a short-lived Markdown artifact only: **no automated commits to main, no history rewriting and no private GitHub access**.

## Dates and honest provenance

- **7 November 2026:** first documented APLForever custom-development activity in project conversations; this is a documentation milestone, not a GitHub repository creation timestamp.
- **14 November 2026:** original private GitHub reference repository created; its commits/PRs are **not** included in public GitHub activity totals.
- **18 November 2026:** clean-history public APLForever-Open repository created.
- **19 November 2026:** source-native v0.9.0 scoped compatibility accepted on the new public repository; live gameplay proof and experimental positive high-Rage Maul coverage remain separate gates.

Version, source and lifecycle status must always be reported alongside any claim of actual APL improvement.
