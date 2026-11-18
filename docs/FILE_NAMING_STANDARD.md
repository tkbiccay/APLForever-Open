# APL naming and file standard

## Canonical APL identity: `<Class>_<Spec>`

**Every in-game Hekili APL profile and every newly created APL file uses exactly `<Class>_<Spec>` as its identity.** The class and spec are each one PascalCase token with no embedded spaces or underscores; multiword specs are concatenated.

Examples: `Druid_Guardian`, `Druid_Feral`, `Hunter_BeastMastery`, `Hunter_Marksmanship`, `Hunter_Survival`, `Paladin_Retribution`, `Warlock_Demonology`, `Warrior_Protection`.

**The combat role is separate metadata** in `catalogue/roles.json`, never part of the APL name. `Druid_Guardian` is Tank; `Druid_Feral` is DPS. Forever's Guardian/Feral addon taxonomy is mapped in catalogue metadata, not embedded in an APL name. Our 28 current roles have unique class/spec pairs.

When importing into Hekili Forever, use the exact `apl_name` catalogue value as the profile name where the game UI permits it. The APL text does not itself prove what the user named the imported profile.

## Repository paths and lifecycle folders

APLs are stored once under **`roles/<Class>/<Current|Candidates|Checkpoints|Archive>/`**, with specialisation retained in the filename. See the [role folder guide](ROLE_APL_LAYOUT.md) for precise classification, current-vs-approved distinctions, placeholders, rollback and evidence-preserving movement. Direct flat `roles/APL_*.txt` paths are no longer canonical.

## Canonical file patterns for new work

- `APL_<Class>_<Spec>_v<Major>.<Minor>_<Status>.txt` — full APL code only
- `Research_<Class>_<Spec>_v<Major>.<Minor>.md`
- `Tests_<Class>_<Spec>_v<Major>.<Minor>.md`
- `Changelog_<Class>_<Spec>.md`
- `Limitations_<Class>_<Spec>.md`

Example: `APL_Hunter_Survival_v1.1_Draft.txt` belongs to the Survival DPS role; the role lives in catalogue metadata. The same revision must match associated Research and Tests files.

Allowed statuses: `Default`, `Draft`, `StaticValidated`, `PendingInGame`, `InGameValidated`, `Approved`, `ReportedWorking`, `NeedsRetest`, `Retired`. `Unknown` is only a catalogue-level status.

## Historical and protected files

Existing historical files with `<Class>_<Spec>_<Role>` in their filename are **immutable grandfathered revisions** (they can be in Current, Checkpoints or Archive depending on actual evidence). Each has `legacy_filename: true` in its revision metadata and is still verified by exact-byte SHA-256 and Git rollback checks. Do not rename, delete, overwrite, silently rehash or make them preferred without their normal evidence gates.

**New revisions must use the two-token `Class_Spec` identity.** This changes only the naming convention, not preserved historical APL contents. A path relocation must retain exact filenames, SHA-256 and Git blobs, update catalogue and all reachable links/import references, and be validated as a one-to-one move. Legacy `relocated_from` records the immediate prior path and does **not** confer approval.

Global files remain `Catalogue_All_Roles.md`, `Limitations_Global.md`, `Research_Global_<Topic>_YYYY-MM-DD.md` and `Tests_Global_<Topic>_YYYY-MM-DD.md`.

## Regression incident and test names

A regression is always associated with the canonical `<Class>_<Spec>` identity, rather than a legacy ticket prefix or an APL revision.

- `docs/Regression_<Class>_<Spec>_<Symptom>_YYYY-MM-DD.md` — descriptive incident record, e.g. `docs/Regression_Warlock_Demonology_RepeatedLifeTap_2026-11-08.md`.
- `tests/test_<class>_<spec>_<descriptive_issue>.py` — Python source-level regression guard, e.g. `tests/test_warlock_demonology_repeated_life_tap.py`.
- Other role-specific tests should continue using `Tests_<Class>_<Spec>_v<Major>.<Minor>.md`; do not substitute the incident date for APL revision.
- Preserve any pre-standard incident code (such as historical `DEMO-006`) **only as a legacy alias in the incident record and Git history**. Do not use that code as the primary heading, path, test class or role identifier.
- Do not rename immutable APL rollback files to make them appear new. Historical `migrated_from` values are provenance, **not** APL names to normalise retroactively.

Incident status, APL lifecycle status and validation evidence remain separate. Renaming an incident document or test does not mean the live regression is resolved.

## Invariants

Canonical name ≠ role, lifecycle approval or build support. Avoid `final`, `latest`, `new` and other ambiguous suffixes. Keep roles and limitations in the catalogue and docs rather than inflating the APL name. APL `.txt` files contain **only complete importable APL code**, not documentation. Tests must reject unsupported names, fake approvals and unregistered files.
