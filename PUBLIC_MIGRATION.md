# One-time private reference → public development migration

**Authoritative repository going forward: `tkbiccay/APLForever-Open`.**

The historical private `tkbiccay/APLForever` is **reference-only**: do not develop there, write commits, merge old PRs, publish its history, or keep it as a sync/mirror source. The new public repository must work independently.

## Current progress and remaining gate

Clean-history public bootstrap and protected `main` are verified. **PR #1 stages 32 exact-blob historic APL revisions, catalogue and Python/native developer tests** with selected research; private Git history/PRs/Actions logs have not been transferred. A successful public integrity `validate` is **not** a Hekili v0.9.0 source-native acceptance or gameplay approval. The import remains *reviewable* until PR #1 is green and merged. See `docs/IMPORT_PROVENANCE.md` and `docs/knowledge/CONTINUATION_HANDOVER.md`.

### Migration

1. Export a **snapshot of reviewed tracked files only**, from the historical repository's known commit, WITHOUT copying its `.git` directory, tags, old branches, private Actions logs, issues, PR discussions or artefacts. Prefer an isolated `git archive` or an explicit file manifest.
2. **Before importing into public Git history**, run an independent privacy scan against every chosen file, manually review suspected credentials, names, private references, proprietary sources and third-party licence notices. The known legacy `tests/test_public_release_audit.py` contains synthetic secrets deliberately; do not grant broad `tests/` exclusions. A scanner matching fake fixture tokens needs a narrowly documented human triage and preferably a syntax-safe redacted fixture.
3. Import original FULL APL bytes unchanged from the chosen historical commit, check each archived/Current/Candidate/Checkpoint file against its catalogue SHA-256. Preserve reported-working rollbacks (especially Druid Guardian and Warlock Demonology), archived failed experiments and regression knowledge. Never silently change protected APL content or make a Draft into an Approved.
4. Import curated catalogue, tests, scripts, source-pinned wiki references and class evidence only after cleaning **public copy** links. Retain the old source SHA (commit **as provenance**, not as a Git parent) in the public handover. Historical private PR hyperlinks cannot serve as public test evidence; preserve redacted evidence summaries and rerun source-native tests in new public Actions.
5. Run `py -3.12 -m unittest discover -s tests -v`, `py -3.12 scripts/validate_repository.py`, targeted public source-native test suites for the released Hekili tag, and full fallback/repeated-recommendation gates. The old Windows `git check-attr` expectation needs investigation; never weaken byte integrity to make CI green.
6. Merge a **single scoped migration PR** only when green. Verify public `main` protection and only-one-maintainer rights. Update this document with dates, selected source SHA, new public commit, SHA evidence, upstream pin and actual CI URLs.

### Public CI policy

- `validate` is the fast required PR check; GitHub-hosted ephemeral Linux runner, read-only `GITHUB_TOKEN`.
- Native currently-released engine test lane for meaningful APL/engine changes; archived release pins manually on demand.
- Preserve test failures and source-native rollback; no CI auto-approval; no commit-history sync with the private archive.
- APL development and new issue/PR tracking happen **only here**.

### Remaining owner settings

The repository's `main` ruleset **must** be set in GitHub Settings → Rules → Rulesets to Active, exact branch `main`; require pull request (zero mandatory approving reviewers, sole owner), deny force-push and deletion, require the *actual green* `validate` job once available, no routine bypass. CODEOWNERS does not enforce it. Limit collaborators/apps; read-only default Actions token; approval for external fork PR workflows. Do not use personal Hyper-V/self-hosted persistent hardware for public fork PRs.
