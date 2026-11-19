# APLForever-Open — canonical continuation handover

**As at 19 November 2026. This file belongs to the public canonical repository.** All new development, PRs, issues, CI, source-native tests and releases happen in **tkbiccay/APLForever-Open**. The historical private `tkbiccay/APLForever` is **read-only reference**, NOT a development branch, sync target, or source of ongoing truth. No model or contributor is authorised to write to the private archive.

## Migration and validation state
- Source reference snapshot: historical private commit `3d236b46e9eeb4f58f8caac94c02a457bcda99fa`; it is a provenance label **not a Git parent, external dependency or public proof**.
- Public clean-history import: 28 intended roles (23 historically Supported and five Blocked healer roles), **32 complete historic APL revisions** with exact catalogue SHA-256 and independently matched Git blobs, `catalogue/roles.json`, and independent validator. This is a **status-preserving migration**, NOT role approval.
- Last reported-working rollbacks: **Druid Guardian v1.0** and **Warlock Demonology v1.0** = Reported Working / Needs Retest, not Approved. Druid Feral DPS v1.0 = Draft current selection; v1.1 Draft separate candidate. Guardian v1.1 archive, v1.2 Candidate Draft with experimental Barkskin; do not silently promote any.
- Public GitHub-hosted `validate` passed on migration PR #1 head `22000c73d60333e06e3a5b34ef63a5a36625b559`: [run](https://github.com/tkbiccay/APLForever-Open/actions/runs/44396287007), including repository + byte-hash integrity. This does **NOT** test Hekili source-native accepted casts, gameplay, numeric performance or all restored native suites. Subsequent PR commits require their own fresh checks.
- Actual `main` GitHub ruleset **Protect main**, ID `27584181`, Active, PR required/0 human reviews, real `validate` required, no bypass, no deletion or force push. Verify live on every new session.

## Latest released addon compatibility
- Hekili Forever official latest checked published release: **v0.9.0** (18 Nov 2026), exact tag commit `8f95f2ea0a45428554c1e938ed7357b870030514` from https://github.com/zmsl/hekili/releases/tag/v0.9.0 and Git refs. **The scoped public source-native v0.9.0 compatibility gate PASSED at commit 07fd763 in run 44413198025; this does not validate the separate, blocked positive Maul experiment or in-game performance.**
- Historical v0.8.6 native tests are research references only, not automatically green on v0.9.0; the new release changes Feral Bite/refunds, Bear priorities, resource forecasts, Hunter BM/MM pack selection and custom SimC sequence support. See `docs/knowledge/engine/v090-release-review.md`.
- Do not import the old private repo's pending PR #90 as a completed/publicly tested change. Its Feral v1.2 is a reference-only unpromoted Draft that must be separately proposed, pinned and retested in this repository.

## Standing methodology
**APL-first, actual released Hekili/Belief engine-first.** Fully original standalone priorities permitted: shipped default is comparator, never architecture constraint. Protect all actions, internal lists, forms/pets, Major/Minor Cooldowns, Defensives, Interrupts, Potions, resources, precombat, ST/AoE, level unlocks and final fallbacks; never invent observations or spell data.

Whole reachable-chain repeated fallback after DoTs/upkeep and unaffordable skills is P0. DEMO-006 Warlock Life Tap repetition is a *reported symptom, not established root cause*. Compare the shipped default AND last-working APL under matched source/talents/settings with state-advanced accepted/refused casts. Use source-native and targeted loops first; performance sims are optional and **deferred** until a specific decision merits them. Real gameplay `/hek snap` and explicit maintainer approval remain necessary before Approved.

**Priorities:** Equal first tier **Druid Guardian/Feral Tank AND Hunter Beast Mastery** → Druid Feral DPS → other supported roles, with critical regressions pre-empting. Hunter BM v1.1 exists under Current but its catalogue preferred_apl is **null**, not Approved or selected.

## Start here
1. Read `README.md`, `AGENTS.md`, `docs/CODEX_CONTINUATION.md`, `catalogue/roles.json`, this handover, source/role-specific tests and `docs/knowledge/lessons/CROSS_APL_TRANSFER.md`.
2. Verify **live** public main/ruleset, open PRs/issues, CI, hashes and published upstream tag. Never rely on a previous private CI URL for a public PASS.
3. Use the **passed, narrowly scoped v0.9.0 public native baseline** without claiming exhaustive 1–60, in-game, full fallback or a positive Maul reorder. Review each role's actual source/fixture coverage and expand targeted tests only for a concrete decision.
4. Pursue Guardian v1.0 rollback versus v1.2 candidate/default **alongside Hunter BM v1.0 and v1.1 Drafts versus the shipped v0.9.0 Turret pack**. Pet cast/recovery state is unproven in the native harness. Feral DPS comparisons follow. Consider historical Feral v1.2 private reference only as an unselected candidate.
5. Log smallest reproducible next decision in the relevant role Research_/Tests_/Changelog_/Limitations_ + public issue/PR. Update this file only when substantive status/plan changes.

**Never:** write to old private repo, copy private Git history/Actions logs/private links, allow CI to mark Approved, share custom runtime dependencies across APLs, run untrusted public PR code on a personal runner, publish raw snapshot secrets, or weaken a failing validator to get green.

## Public issue #3 / PR #2 fixture correction

The failed-first public run 44402011522 remains evidence. The released v0.9.0 Guardian header spends 21 Feral points before talent 1328617. The native dominant-tree level cut therefore learns talent Lacerate at level 31, while trained rank 2 remains level 34. The v0.9.0 fixture checks L30 negative and L31 positive for shipped and both historical custom profiles. The original v0.8.5 spec and its expectations are preserved byte-for-byte.

The two-attacker v0.9.0 reorder trace never reached its Maul reserve (max truth 30.75, belief floor 26). Existing two-attacker natural low-Rage safety worlds remain strict. The three-attacker test-only unchanged-guard reorder also FAILED its positive queue assertion: actual max Rage 30.75, observed belief floor 24.869, zero reserve-guard hits, zero Maul queues/strikes. The fixture supplies no verified incoming-damage Rage callback, so adding attackers is not proof of reserve reachability. This remains Blocked/Not Demonstrated, not source-native validation of a Maul reorder. Focused tests precede broad native checks in public run https://github.com/tkbiccay/APLForever-Open/actions/runs/44407953920. Public current-release native scoped acceptance is PASS at [run 44413198025](https://github.com/tkbiccay/APLForever-Open/actions/runs/44413198025): matched SHA, 32 APL hash manifest, Hunter Turret fixture, 23-profile import/progression, Guardian L30/L31 and mitigation/low-Rage checks, Feral natural-resource tests and current released-source tests. Historical failed native runs are retained. The Maul positive experiment is preserved separately in a manually triggered strict workflow and issue #3. No APL, Current selection, hash or rollback changes were made.

## Co-priority and operating model — 19 November 2026

- [PR #4](https://github.com/tkbiccay/APLForever-Open/pull/4) merged the proudly AI-developed/human-maintained hobby-project identity and lean source-native risk-based strategy. [AI-first policy](../../AI_FIRST_WORKING_MODEL.md): ChatGPT + maintainer lead investigation/architecture/validation, Codex only on explicitly delegated bounded engineering; no autonomous development or default-forcing.
- **Guardian and Hunter Beast Mastery are equal-priority** workstreams. [Hunter BM issue #5](https://github.com/tkbiccay/APLForever-Open/issues/5) records required v0.9.0 Turret baseline, pet transitions, low-level/low-mana final tail and toggle/facing tests. Hunter v1.1 remains a Draft file in Current; catalogue preferred_apl=null.
- Keep the strict high-Rage positive Maul assertion for experiment [issue #3](https://github.com/tkbiccay/APLForever-Open/issues/3), **not as a swallowed success**. Targeted native baseline scopes may be independently reported PASS only for executed, applicable gates; a new proposed Maul architecture still lacks mandatory positive proof.
- Preserve private archive read-only, all 32 APL bytes/hashes, reported-working Guardian/Demonology and null Hunter BM selection. The next substantive work is independent Guardian and Hunter BM targeted audits, not an expensive across-all-roles simulator.
