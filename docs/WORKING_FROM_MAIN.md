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

## GitHub branch housekeeping (one-time and ongoing)

With repository owner access:

- Open [Settings → General](https://github.com/tkbiccay/APLForever-Open/settings) → **Pull Requests** → tick **Automatically delete head branches** (the current repository setting was **disabled on 19 Nov 2026**). This uses GitHub's own cleanup; **do not add a bot or bypass the main ruleset**.
- Open [Branches](https://github.com/tkbiccay/APLForever-Open/branches) and filter **Merged**. Delete **only** the head branches of PRs confirmed merged; never `main`, never an unmerged experimental branch.
- Historical PRs and squash-merge commits remain searchable even after branch deletion. This is safe **only when all wanted bytes are on main and CI is green**; review any branch that has non-merged changes before deleting it.
- After deleting prior merged branch refs, the normal steady state is **one visible permanent branch: `main`**. A single PR branch can exist while new work is being validated.

**Current project priorities:** Guardian/Feral Tank and Hunter BM equally first; then Feral DPS. Research once → Preserve → Reuse, and keep full standalone role APLs.
