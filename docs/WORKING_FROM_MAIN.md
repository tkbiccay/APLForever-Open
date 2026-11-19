# APLForever — work from main, keep history safe

**Canonical repository:** [tkbiccay/APLForever-Open](https://github.com/tkbiccay/APLForever-Open/tree/main). **Permanent branch:** `main` only. This is the home for our working APL files, source-pinned knowledge, tests, catalogue and honest records. The old private repo is historical read-only. The protected-main PR requirement stays enabled; *short-lived branches* are CI/review transport, not separate source-of-truth copies.

## Find the correct file quickly

| Need | On-main location |
| --- | --- |
| Canonical role statuses, selections and SHA-256 | [catalogue/roles.json](../catalogue/roles.json) |
| Current import/test reference | `roles/<Class>/Current/` — confirm `preferred_apl`, validation status and actual working evidence |
| Brand-new independently importable APL | `roles/<Class>/Candidates/` — always **Draft**, initially **unselected**, new revision and hash |
| Protected fallback | `roles/<Class>/Checkpoints/` where applicable, or the exact **reported-working Current** — never relocate existing hashes casually |
| History / archived comparators | `roles/<Class>/Archive/` |
| Exact Forever talents, abilities and toggles | [knowledge/](../knowledge/) and [generated source references](reference/) |
| Native headless tests | [tests/native/](../tests/native/) and [CI workflows](../.github/workflows/) |
| Research/Tests/Changelog/Limitations per role | [docs/](./) and [handover](knowledge/CONTINUATION_HANDOVER.md) |
| Original goals, safety and priorities | [AGENTS.md](../AGENTS.md), [PROJECT_PRIORITIES.md](PROJECT_PRIORITIES.md) |

**Example now on `main` (19 November 2026):** Hunter BM `v1.1 Draft` is in `Current`, and the separately hashed, unselected `v1.2 Draft` is in `Candidates`; BM `preferred_apl=null`. Druid Guardian v1.0 in `Current` is **Reported Working / Needs Retest** and remains a protected rollback. The 32 historical protected APL hashes are intact; v1.2 adds a separate 33rd record.

## One lean change at a time

1. **Research once:** check main catalogue, pinned knowledge, shipped/default, existing last-working, tests and previous negative findings. Define one useful hypothesis, acceptance criteria and rollback.
2. **Preserve:** create a unique **complete standalone** new Draft in `roles/<Class>/Candidates/` with a new revision, catalogue SHA-256, source pin, test constraints and unchanged rollback. Never modify historical APL bytes or select the Candidate implicitly.
3. **Validate:** use one short-lived PR branch from current main. Run `python scripts/validate_repository.py`, Python tests and relevant current-release native accepted/refused casts with final/repeated fallback and toggle checks. Do the expensive all-role gate only for actual cross-role/shared-engine changes, release upgrades or promotion-risk regressions. Failed tests stay visible.
4. **Merge into main:** once the applicable tests pass and no working APL is regressed, the sole maintainer merges the changes. **This is publication of a Draft Candidate, NOT its selection for regular gameplay or approval.** The native manifest should continue testing `Current` by default; test new Candidates independently.
5. **Tidy:** delete the merged short-lived GitHub branch; leave its PR, commits and CI accessible as permanent evidence. Update handover only for substantive outcomes and move to the next decision.

**Approval is a separate gate:** verified in-game gameplay evidence, no significant safety/regression failures, a fair default + last-working comparison and explicit maintainer acceptance. When in doubt, keep `Current` unchanged. Never merge known failing critical code just to tidy branches.

## Automated branch housekeeping

[Safely clean merged PR branches](../.github/workflows/safe-merged-branch-cleanup.yml) runs on **every push to protected `main`**, plus weekly and manually from the [Actions page](https://github.com/tkbiccay/APLForever-Open/actions/workflows/safe-merged-branch-cleanup.yml). Its first merged-main push also performs the one-time historical branch reconciliation. **No further manual clicks or personal access token are required** if GitHub honours the workflow's declared token permissions.

Before deletion, it verifies **a merged PR from this same repository**, its **exact matching final head SHA**, **no still-open PR** using the branch, and **no branch protection**. It re-reads the live branch and raw Git ref before deletion. It refuses `main`, forks, unmerged work, changed heads, unusual ref names and API failures. It never checks out untrusted PR code or alters `roles/`, catalogue selection, releases, hashes or approval status.

This is a narrowly scoped, in-repository GitHub Actions alternative because the connected GitHub integration cannot enable the platform's native **Automatically delete head branches** setting. You can enable that GitHub setting later if you prefer; the workflow is idempotent. The script has a **read-only default**: `python3 scripts/cleanup_merged_branches.py` previews eligible branches when provided a GitHub token, and only the trusted main workflow invokes `--apply`.

**Current project priorities:** Guardian/Feral Tank and Hunter BM equally first; then Feral DPS. Research once → Preserve → Reuse, and keep full standalone role APLs.
