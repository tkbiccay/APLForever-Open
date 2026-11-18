# APLForever-Open — canonical continuation handover

**As at 18 November 2026. This file belongs to the public canonical repository.** All new development, PRs, issues, CI, source-native tests and releases happen in **tkbiccay/APLForever-Open**. The historical private `tkbiccay/APLForever` is **read-only reference**, NOT a development branch, sync target, or source of ongoing truth. No model or contributor is authorised to write to the private archive.

## Migration and validation state
- Source reference snapshot: historical private commit `3d236b46e9eeb4f58f8caac94c02a457bcda99fa`; it is a provenance label **not a Git parent, external dependency or public proof**.
- Public clean-history import: 28 intended roles (23 historically Supported and five Blocked healer roles), **32 complete historic APL revisions** with exact catalogue SHA-256 and independently matched Git blobs, `catalogue/roles.json`, and independent validator. This is a **status-preserving migration**, NOT role approval.
- Last reported-working rollbacks: **Druid Guardian v1.0** and **Warlock Demonology v1.0** = Reported Working / Needs Retest, not Approved. Druid Feral DPS v1.0 = Draft current selection; v1.1 Draft separate candidate. Guardian v1.1 archive, v1.2 Candidate Draft with experimental Barkskin; do not silently promote any.
- Public GitHub-hosted `validate` passed on migration PR #1 head `22000c73d60333e06e3a5b34ef63a5a36625b559`: [run](https://github.com/tkbiccay/APLForever-Open/actions/runs/44396287007), including repository + byte-hash integrity. This does **NOT** test Hekili source-native accepted casts, gameplay, numeric performance or all restored native suites. Subsequent PR commits require their own fresh checks.
- Actual `main` GitHub ruleset **Protect main**, ID `27584181`, Active, PR required/0 human reviews, real `validate` required, no bypass, no deletion or force push. Verify live on every new session.

## Latest released addon compatibility
- Hekili Forever official latest checked published release: **v0.9.0** (18 Nov 2026), exact tag commit `8f95f2ea0a45428554c1e938ed7357b870030514` from https://github.com/zmsl/hekili/releases/tag/v0.9.0 and Git refs. **No native-v0.9.0 compatibility PASS has been obtained on the new public repository yet.**
- Historical v0.8.6 native tests are research references only, not automatically green on v0.9.0; the new release changes Feral Bite/refunds, Bear priorities, resource forecasts, Hunter BM/MM pack selection and custom SimC sequence support. See `docs/knowledge/engine/v090-release-review.md`.
- Do not import the old private repo's pending PR #90 as a completed/publicly tested change. Its Feral v1.2 is a reference-only unpromoted Draft that must be separately proposed, pinned and retested in this repository.

## Standing methodology
**APL-first, actual released Hekili/Belief engine-first.** Fully original standalone priorities permitted: shipped default is comparator, never architecture constraint. Protect all actions, internal lists, forms/pets, Major/Minor Cooldowns, Defensives, Interrupts, Potions, resources, precombat, ST/AoE, level unlocks and final fallbacks; never invent observations or spell data.

Whole reachable-chain repeated fallback after DoTs/upkeep and unaffordable skills is P0. DEMO-006 Warlock Life Tap repetition is a *reported symptom, not established root cause*. Compare the shipped default AND last-working APL under matched source/talents/settings with state-advanced accepted/refused casts. Use source-native and targeted loops first; performance sims are optional and **deferred** until a specific decision merits them. Real gameplay `/hek snap` and explicit maintainer approval remain necessary before Approved.

**Priorities:** 1 Druid Guardian/Feral Tank → 2 Druid Feral DPS → rest of 23 supported roles, unless confirmed critical cross-spec safety or released-engine compatibility pre-empts.

## Start here
1. Read `README.md`, `AGENTS.md`, `docs/CODEX_CONTINUATION.md`, `catalogue/roles.json`, this handover, source/role-specific tests and `docs/knowledge/lessons/CROSS_APL_TRANSFER.md`.
2. Verify **live** public main/ruleset, open PRs/issues, CI, hashes and published upstream tag. Never rely on a previous private CI URL for a public PASS.
3. Complete source-native v0.9.0 import/progression with stable 1–60 resources, toggles and repeated fallback; log actual failures and differentiate fixture vs APL vs engine. Stop if source runtime cannot reproduce a live case.
4. Guardian v1.0 rollback vs v1.2 candidate/default, then Feral v1.0 selected vs v1.1 draft/default. Consider historical Feral v1.2 from private reference only as an unselected new candidate with independent public proof.
5. Log smallest reproducible next decision in the relevant role Research_/Tests_/Changelog_/Limitations_ + public issue/PR. Update this file only when substantive status/plan changes.

**Never:** write to old private repo, copy private Git history/Actions logs/private links, allow CI to mark Approved, share custom runtime dependencies across APLs, run untrusted public PR code on a personal runner, publish raw snapshot secrets, or weaken a failing validator to get green.

## Public issue #3 / PR #2 fixture correction

The failed-first public run 44402011522 remains evidence. The released v0.9.0 Guardian header spends 21 Feral points before talent 1328617. The native dominant-tree level cut therefore learns talent Lacerate at level 31, while trained rank 2 remains level 34. The v0.9.0 fixture checks L30 negative and L31 positive for shipped and both historical custom profiles. The original v0.8.5 spec and its expectations are preserved byte-for-byte.

The two-attacker v0.9.0 reorder trace never reached its Maul reserve (max truth 30.75, belief floor 26). Existing two-attacker natural low-Rage safety worlds remain strict. The separate in-memory unchanged-guard reorder uses three source-world attackers for positive queue, later strike, nonzero payment and zero unqueue assertions. This is test-only reachability evidence, not a recommended priority reorder or performance claim. Focused tests precede broad native checks in public run https://github.com/tkbiccay/APLForever-Open/actions/runs/44407953920. Full release acceptance must use the completed workflow result. No APL, Current selection, hash or rollback changes were made.