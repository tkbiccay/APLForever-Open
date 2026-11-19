# APLForever

**Proudly AI-developed and human-maintained, open-source Action Priority Lists (APLs) for World of Warcraft: Forever and Hekili Forever.**

A fun, independent passion project: people and AI collaborating to explore better, safer gameplay recommendations. We share what works, what fails, and what we still don't know. No inflated DPS claims or pretence that AI-generated code is automatically correct.

> **Project status (19 November 2026):** `main` is our single canonical working location. [Hunter BM v1.2 Draft Candidate](roles/Hunter/Candidates/APL_Hunter_BeastMastery_v1.2_Draft.txt), [Hunter BM v1.1 Current Draft](roles/Hunter/Current/APL_Hunter_BeastMastery_v1.1_Draft.txt), the [Guardian reported-working rollback](roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt), and the [source-pinned Hunter/Druid reference](knowledge/README.md) are all present on `main`. PRs #6, #8 and #9 merged after green CI; merge **never** means a Candidate was Approved. Positive high-Rage Maul remains blocked. The old private repository is read-only.

## Project fun facts

**First documented APL work:** 7 November 2026 · **Public repository created:** 18 November 2026. This is a proudly **AI-developed, human-maintained** fun project.

**Opening public GitHub scoreboard (19 November 2026):**

- **16 commits** on public main
- **15,144 text lines changed** (11,196 in APLs, source, tests and workflows)
- **3 pull requests merged**
- **0 issues closed** (excluding pull requests)
- **32 APL revisions** across **28 intended roles** (23 Supported, five Blocked)
- **0 Approved roles** — we do not confuse drafting with in-game validation

The counts are a dated snapshot from before the fun-facts tracker was merged. Text additions plus deletions **include the initial clean-history migration**, so these are not unique newly authored lines and do not include the old private repository.


**[See the latest live fun-facts run and Markdown snapshot](https://github.com/tkbiccay/APLForever-Open/actions/workflows/project-fun-facts.yml).** Read-only automated updates every Monday, plus manual runs; no bot commit spam or protected-main bypass.

Our actual goals are [custom standalone APLs, reliable headless testing, cross-spec lessons and owner-led AI collaboration](docs/PROJECT_PRIORITIES.md). GitHub numbers are just a bit of fun.

## Research once → Preserve → Reuse

Our source-pinned [class mechanics knowledge base](knowledge/README.md) records verified spell/talent registration, multi-role classifications, source-native toggle/Belief limitations, and explicit unknowns. The pilot includes [Hunter Beast Mastery](docs/reference/Hunter_BeastMastery.md) and [Druid Guardian](docs/reference/Druid_Guardian.md) source-linked pages. Class facts are stored once, generated for quick browsing and checked against the exact tagged Hekili Forever source in GitHub Actions.

**Every** research/testing/bugfix/CI task checks prior evidence, preserves a reproducible lesson, and transfers only what's verified for the next spec. It must never create shared APL runtime dependencies, replace the last-working rollback, or use green CI as an in-game approval.

## Mission

Develop one complete, independently importable and reliably castable APL for each supported Hekili Forever class/spec/role. Cover levelling 1–60 and appropriate PvE situations without inventing combat state the addon cannot observe.

Our joint top priorities are **Druid Guardian/Feral Tank and Hunter Beast Mastery (equal priority) → Druid Feral DPS → remaining supported roles**. We favour safe, stable recommendations, correct user toggle handling and fully audited final/repeated fallbacks. The shipped Hekili priority is a research benchmark, not a design ceiling. New APL designs are encouraged when justified by tests.

See our [project priorities](docs/PROJECT_PRIORITIES.md) and [AI-first working model and efficient validation strategy](docs/AI_FIRST_WORKING_MODEL.md) for how the maintainer, ChatGPT, Codex and community work together.

## Where to work (main first)

**Always start with** [the main branch](https://github.com/tkbiccay/APLForever-Open/tree/main) and the [main-first development guide](docs/WORKING_FROM_MAIN.md). The [catalogue](catalogue/roles.json) decides what is selected and validated — not the newest revision number or a PR branch name.

| Location on main | Meaning |
| --- | --- |
| [Current](roles/Hunter/Current/) | Selected development/test import, **not necessarily Approved** |
| [Candidates](roles/Hunter/Candidates/) | Full new standalone experimental APLs ready for targeted testing |
| [Checkpoints](roles/Druid/Checkpoints/) | Immutable fallback snapshots where available; a last-working APL can still be Current |
| [Archive](roles/Hunter/Archive/) | Historical APLs preserved for comparison and rollback |
| [Knowledge](knowledge/) | Research once → Preserve → Reuse, source-pinned mechanics and limits |
| [Tests](tests/) | Headless regression tests and pinned source evidence |

**Workflow:** make a short-lived review/CI branch → check hashes, import and relevant source-native tests → merge safe work (including **unselected Draft Candidates**) into protected `main` → delete the merged branch. Promoting a Candidate into `Current` or `Approved` is an entirely separate, explicit evidence-backed action. Never do routine development on historical merged branches.

## Development and approval

- **Current** means the selected test/import revision, **not automatically Approved**.
- **Candidates** are experimental; **Checkpoints** hold known-working rollback bytes; **Archive** preserves historic evidence.
- Protect full APL files and SHA-256 hashes. Preserve the default comparator and the last-working baseline.
- Prefer version-pinned source-native import/compile and state-advanced accepted/refused casts; use game testing where the engine cannot reproduce live conditions.
- Compare candidates against both shipped default and last-working behaviour, including low-resource and repeated-fallback cases.
- Do **not** auto-promote a candidate based on CI, damage simulation or consensus. Real in-game validation and explicit maintainer approval remain mandatory.
- Every APL must work as **one standalone file**; cross-role shared development tests are allowed, shared custom runtime dependencies are not.
- Numerical WoWSims/Raidbots-style performance modelling is optional and never substitutes for native Hekili validation.

## Repository ownership and provenance

**Canonical active project:** https://github.com/tkbiccay/APLForever-Open

**Sole official maintainer:** [@tkbiccay](https://github.com/tkbiccay). Community forks, issues and proposed pull requests are welcome. The owner alone decides which changes enter the official repository.

**Historic private source:** maintained separately by the owner for reference and disaster recovery; **not** an active development or automated-publication upstream. No private branches, PRs, Actions logs, tokens or Git history should be copied into this public repository. Any historical APL code selected for import must first pass a current-file privacy/licence scan and exact-byte check.

This independent project is **not affiliated with or endorsed by Blizzard, Hekili Forever or WoWSims**. Upstream projects: [Hekili Forever](https://github.com/zmsl/hekili) and [WoWSims Forever](https://github.com/wowsims/forever). Respect their licences and original authorship.

## Licence

APLForever-authored original code and documentation are licensed under **GNU GPL version 3 only**; see [LICENSE](LICENSE). Third-party material retains its applicable copyright and licence notices. GPLv3 permits forks and modifications; it does **not** grant write access to the official repository.

## Current launch phase

**Initial library import:** 32 full historical APL revisions, 28-role catalogue, independent SHA-256 checks, and reviewed Python/native test fixtures were migrated as a clean-history snapshot in [PR #1](https://github.com/tkbiccay/APLForever-Open/pull/1). This preserves historic statuses and rollbacks. Public v0.9.0 independent native gates have passed, but the strict high-Rage positive Maul experiment remains blocked in [issue #3](https://github.com/tkbiccay/APLForever-Open/issues/3); no in-game approval is implied. See [public migration/provenance](docs/IMPORT_PROVENANCE.md) and [Codex continuation](docs/CODEX_CONTINUATION.md).

