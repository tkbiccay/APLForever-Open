# Governance

**Sole official maintainer:** [@tkbiccay](https://github.com/tkbiccay).

The official public repository is `tkbiccay/APLForever-Open`. The separate historical private `APLForever` repository is a **read-only reference/archive**. Do not push new development, open development PRs or run active pipelines there. Historical private PR branches and CI logs are **not** the public project's history.

Community members can fork GPLv3-licensed material and submit issues/PRs; only the owner decides official merges, releases, APL selection and approval. Public contributions do not confer write, admin or maintain permissions.

**APL states:** Candidate / Draft / Static Validated / Pending In-Game Validation / In-Game Validated / Approved, with Reported Working / Needs Retest, Blocked and Retired where evidence warrants. `Current` is the selected import/test version, not proof of Approved. The last-working and shipped baselines remain protected, and no CI can grant gameplay approval.

**One-maintainer merge policy:** protect `main` against direct push, force-push and deletion; require a PR and successful automated tests, but **zero required human reviewers** (a sole PR author cannot approve their own PR). No routine bypass. Review installed apps and collaborators, not just CODEOWNERS. Enforce these through actual GitHub Rulesets; this text is not technical protection.

Changes to the original private repository are outside this project's development workflow. If reference evidence is needed, read it without modifying its files, branches, issues or settings.

[Publication and integrity policy](PUBLIC_MIGRATION.md) | [Contributing](CONTRIBUTING.md)
