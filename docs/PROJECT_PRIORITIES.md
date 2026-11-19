# APLForever-Open — priorities, success criteria and project ethos

**Started:** 7 November 2026 (first documented custom-APL project work). **Public GitHub home:** 18 November 2026. **Proudly AI-developed, human-maintained.** This is a fun GPLv3 hobby project, not a company product, a high-commit scoreboard or a promise of theoretical maximum DPS.

## What we are building, in priority order

### 1. One original, optimised, fully standalone APL per supported role

Aim for all **28 intended roles**, subject to the current Hekili Forever support gate (**23 Supported, five Blocked as at this note**). Every applicable role should eventually have one evidence-approved preferred APL that actually works in Forever's engine, not just a valid text file or a copy of the shipped priority.

APL-first means verified precombat, 1–60 level/rank/talent guards, forms/pets/stances, resource handling, single- and multi-target logic where observable, cooldowns, defensives, interrupts, items and user off-switches, plus the **entire reachable chain and safe final/repeated fallback**. No invented WoW API state, fake gains, or shared custom runtime dependency. Default WoWSims-derived APLs are research references and comparators **not architectural ceilings**: investigate alternative original priority orders without changing reported-working files on a hunch.

**Current equal top priority:** Druid Guardian/Feral Tank **and** Hunter Beast Mastery. Feral DPS follows. Critical source compatibility or a repeatable safety bug can jump the queue. The catalogue, not an evocative folder name, defines status; Hunter BM v1.1 in Current remains Draft with no preferred APL.

### 2. Headless proof that protects actual gameplay

The test system is a means to better recommendations, not its own endless project. Pin the current released Hekili Forever source, translated spell data, Belief limits, talents, gear, toggles and accepted/refused cast state. Test **default versus last-working versus candidate** in matched scenarios: opener, three presses, low-level unlocks, extreme and uncertain resources, CD switches, pet or form, ST/cleave/AoE, follow-on fallbacks and repeat-inappropriate suggestions.

Cheap static/hash/syntax checks always run first. Focused native tests answer targeted mechanics. Broader suites belong to actual source releases, shared-engine changes and pre-promotion regressions. Only player observations can settle behaviour the engine/harness cannot faithfully observe. A native PASS is **not** In-Game Validated or Approved; significant live regression overrides a simulation score. On uncertainty, retain last-working and log the gap. A blocked experimental positive test is not silently passed or allowed to conceal unrelated verified coverage.

### 3. Research once, learn across specs, transfer with proof

When we diagnose and resolve a defect, preserve the symptom, actual root cause, exact before/after and a regression fixture. Search other roles for the **same verified failure pattern**, then test those roles with their own independent APL mechanics. Reuse lessons and scripts; never make APL A depend on APL B at runtime. DEMO-006 post-upkeep Life Tap and repeated final fallbacks remain explicit cross-role safety checkpoints.

Maintain lean Research_, Tests_, Changelog_, Limitations_ and catalogue records with published version pins, conflicts, results, noise, negative tests, rollback IDs and the next narrow decision.

### 4. Human direction, genuinely useful AI assistance

The sole maintainer and ChatGPT lead priorities, source research, original design, triage, available validation and decisions. **Call Codex only for a specifically delegated, bounded engineering task** that benefits from its strengths; it reports evidence and stops. No autonomous code churn, surprise sprints or automatic APL promotions. We openly credit AI development and human validation, do not pretend AI is infallible, and welcome reproducible community criticism and GPLv3 contributions.

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
