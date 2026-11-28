# APL repository lifecycle

Effective 28 November 2026, per owner decision. The repository is organised by class, with three active lifecycle folders.

| Folder | Purpose |
| --- | --- |
| Current | Exactly one protected development rollback per Supported role. Not necessarily Approved or reported working. |
| Candidates | Active standalone, independently hashed Draft alternatives newer than the protected rollback. |
| Archive | Older, superseded, rejected or abandoned revisions and past defaults; historical research, exact regression comparators and recovery only. |

The protected rollback is explicitly recorded in `catalogue/roles.json` as `protected_rollback_apl`. Default v1.0; Feral DPS v1.6 is the owner-designated exception. `preferred_apl`, `last_working_apl`, `last_approved_apl` and status remain distinct from engineering rollback. `native_test_apl`, when present, preserves an exact historical source-native comparator independently of folder placement; it is not a new preferred profile. Historical test runs and their filenames remain evidence, not current recommendations.

## Promotion and housekeeping

1. Develop new full standalone Drafts in Candidates, never overwrite existing APL bytes.
2. Compare against Current, last-working and shipped default under matched conditions. Green headless CI is not gameplay approval.
3. After owner approval/designation, move the replacement to Current; archive the previous Current and superseded candidates. Archive all versions below the new protected rollback. Keep any demonstrably useful newer active Candidate only when explicitly justified.
4. Update catalogue paths, rollback registry, regression fixtures, path-keyed allowlists, docs and workflow references atomically. Preserve exact Git blobs, SHA-256, previous test comparators and status. Never delete historical APLs. No new Checkpoints folder is needed; existing empty placeholders can be removed without affecting APL content.
5. Continue development from the new protected baseline. No implicit promotion based on latest_revision or folder label.

The initial 28 November migration proposes 23 Current, 26 Candidates and 10 Archive APLs (59 total), with 11 path-only moves. See [protected rollback registry](knowledge/PROTECTED_ROLLBACKS.md), [catalogue](../catalogue/roles.json) and the [validator](../scripts/validate_repository.py). Historical initial-layout documentation remains available in Git history.
