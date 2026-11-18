# Role APL folders — find the right file

**Effective 16 November 2026.** GitHub `roles/` is organised by **class first**, then the revision's actual lifecycle. Specialisations are kept in the *filenames*, not nested into separate subfolders. The source of truth for support, current testing selection, preferred and rollback is always [catalogue/roles.json](../catalogue/roles.json), not a directory label.

```text
roles/
  Druid/
    Current/
    Candidates/
    Checkpoints/
    Archive/
  Hunter/
    Current/
    Candidates/
    Checkpoints/
    Archive/
  Mage/ Paladin/ Priest/ Rogue/ Shaman/ Warlock/ Warrior/
    (the same four folders)
```

| Folder | What belongs here | What it **does not** mean |
| --- | --- | --- |
| **Current** | The **selected** APL for each supported specialisation: the catalogue's preferred file when one exists, otherwise its latest source-compatible testing revision. This is the normal location to import from, **subject to its actual validation status**. | Not necessarily the newest, Approved, proven safe for everyday use or even reported working; a Draft under Current is still a Draft. |
| **Candidates** | A **new alternative under investigation** that could replace the selected Current after fair tests and, if appropriate, player validation. | Not the default for gameplay and never entitled to displace an existing Checkpoint solely because it is newer or passes CI. |
| **Checkpoints** | **Protected rollback(s)** with genuine reported-working or approved evidence, usually the previous Current after promotion. Retain the last-known-working copy while newer candidates are evaluated. | Not a disposable interim copy: a new Candidate or Current must **never automatically overwrite, remove or replace** a working Checkpoint. Historical Drafts are not proven checkpoints. |
| **Archive** | Superseded/old drafts, past defaults and research comparators that aren't selected or designated last-known-working. | **Normally do not import for regular play**, but never delete: exact bytes, source SHA-256 and Git history are protected, and an archived draft may be an unverified recovery comparator when no true Checkpoint exists. |

There are nine class directories with every category visible; empty categories have a `.gitkeep` placeholder until an actual APL is placed there. As of this initial migration: **23 Current, one Candidate, four Archive, zero Checkpoints** (Guardian and Demonology reported-working v1.0 are still their selected Current versions). All **28** revisions were moved with unchanged Git **blob SHA** and catalogue SHA-256. Nothing was copied or modified in its APL text.

**Examples**

- [Hunter — Current](../roles/Hunter/Current/): `APL_Hunter_BeastMastery_v1.1_Draft.txt`. Latest testable **Draft**, **not Approved**.
- [Hunter — Archive](../roles/Hunter/Archive/): historical BM v1.0 Draft, the exact rollback/research comparator.
- [Druid — Current](../roles/Druid/Current/): Guardian v1.0 **ReportedWorking / NeedsRetest**, alongside other current Druid specs.
- [Druid — Candidates](../roles/Druid/Candidates/): independent Guardian v1.1 Draft, **not** a replacement of v1.0.
- [Warlock — Current](../roles/Warlock/Current/): Demonology v1.0 **ReportedWorking / NeedsRetest**.
- [Warlock — Archive](../roles/Warlock/Archive/): shipped Demonology v0.8 comparator.

## Selecting, evolving and reverting

1. Open [catalogue/roles.json](../catalogue/roles.json) or [generated role overview](../Catalogue_All_Roles.md). **Use the exact `apl_name`** for in-game imports. Check source-version compatibility, status, `preferred_apl`, `last_working_apl` and `latest_revision`. The newest file is not necessarily the right/approved one.
2. For a new test-ready revision, use a **new immutable APL file** with [canonical filename](FILE_NAMING_STANDARD.md), exact byte hash, research, tests, source minimum if applicable and rollback metadata. Never edit an existing APL in place.
3. **If the current preferred version must remain active**, the new unselected revision goes to **Candidates**. For a supported role lacking a preferred APL, the latest revision is the **Current testing selection** but still retains its Draft status until validated.
4. On evidence-backed promotion/replacement: move the new selected revision to **Current**, and move the displaced prior selected revision to **Checkpoints only if genuinely working/approved**, otherwise **Archive**. **Preserve any earlier last-known-working Checkpoint unchanged** until another equally proven safe replacement is deliberately designated; promotion is never automatic Checkpoint deletion. Change path references atomically in the catalogue and native tests; preserve blob equality, SHA-256, `rollback_reference`, source-version selection and exact previous version in Git history. Do not create duplicates across folders.
5. **Rollback** selects the catalogue's last-known-working import if one exists; otherwise the prior experimental copy explicitly labelled as unverified. A Git checkpoint / old commit always preserves the previous state. A successful import or simulated DPS gain alone never proves a working checkpoint.
6. Run Python repository validation plus protected v0.8.2/v0.8.3 and newest released source-native CI **for any changed APL path**, then minimal in-game checks as required. Use [handover](knowledge/CONTINUATION_HANDOVER.md) to avoid redundant work.

**Migration provenance:** each existing catalogue revision has a `relocated_from` pointing to its former flat `roles/APL_*.txt` path. The [repository validator](../scripts/validate_repository.py) enforces class/folder placement, verifies all revision hashes and checks *previous baseline Git blobs* against the relocated source. This is a one-time **path-only migration**, not an APL redesign or permission to rewrite protected history. For future moves record the immediate prior path in `relocated_from` (Git history preserves earlier moves) and revalidate unchanged bytes.

Relevant governance: [naming standard](FILE_NAMING_STANDARD.md), [validation policy](VALIDATION_POLICY.md), [continuation handover](knowledge/CONTINUATION_HANDOVER.md).
