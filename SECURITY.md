# Security

Report sensitive vulnerabilities privately through GitHub's private vulnerability reporting (if enabled) rather than filing a public issue. Do **not** post API tokens, runner registration tokens, private GitHub history, unredacted `/hek snap`, real account identifiers or personal data.

APLForever-Open runs public pull-request tests using **GitHub-hosted ephemeral runners** with least-privilege `GITHUB_TOKEN` (read-only unless separately justified). **Never execute untrusted public fork code using a home/Hyper-V/self-hosted persistent runner, private secrets, `pull_request_target` write tokens or privileged workflow-run code paths.**

If a credential is leaked, revoke/rotate it immediately; deleting a file or Git commit does not undo public disclosure.

WoW Forever/Hekili addon behaviour is externally maintained; testing an APL is not a security or combat-performance guarantee. No fixed response SLA is promised.
