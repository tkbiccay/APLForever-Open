# APLForever

**Proudly AI-developed and human-maintained, open-source Action Priority Lists (APLs) for World of Warcraft: Forever and Hekili Forever.**

A fun, independent passion project: people and AI collaborating to explore better, safer gameplay recommendations. We share what works, what fails, and what we still don't know. No inflated DPS claims or pretence that AI-generated code is automatically correct.

> **Project status:** Public baseline imported; active source-native v0.9.0 compatibility work in PR #2. The historical private repository is an **archive/reference only**; all new development, issues, pull requests, source-native validation and official releases happen **here**. No APL is Approved simply because it appears in this repository.

## Mission

Develop one complete, independently importable and reliably castable APL for each supported Hekili Forever class/spec/role. Cover levelling 1–60 and appropriate PvE situations without inventing combat state the addon cannot observe.

Our joint top priorities are **Druid Guardian/Feral Tank and Hunter Beast Mastery (equal priority) → Druid Feral DPS → remaining supported roles**. We favour safe, stable recommendations, correct user toggle handling and fully audited final/repeated fallbacks. The shipped Hekili priority is a research benchmark, not a design ceiling. New APL designs are encouraged when justified by tests.

See our [AI-first working model and efficient validation strategy](docs/AI_FIRST_WORKING_MODEL.md) for how the maintainer, ChatGPT, Codex and community work together.

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

