# Changelog — Druid Guardian/Feral Tank

## 18 November 2026 — independent v1.2 Draft Candidate (NOT selected)

- **Previous:** v1.0 full APL Reported Working / Needs Retest remains exact Current and last-working; v1.1 complete Draft moved byte-identically from Candidates to Archive (Git source/provenance checked). Both full APLs preserved.
- **New:** v1.2 Draft Candidate adds only (1) an internal `defensive_cooldowns` call after mitigation and before upkeep, and (2) a known/ready/on/melee/Bear-only Barkskin condition. Uses verified released-v0.8.6 syntax; no shared APL runtime, no inferred player health. Full remaining fallback chain unchanged.
- **Why:** shipped Barkskin requires simulated `health.pct<=60`, which is unreliable when Forever player HP is secret; custom v1.1 entirely lacks Barkskin. Improve source-action coverage while respecting Defensives OFF rather than copying hidden HP gates.
- **First proof:** [PR #89]([private historical reference; not publicly accessible]) source-v0.8.6 test-only 10-world probe accepted one Barkskin and applied its aura with ON at levels 44/60, none when OFF or level43, retained two Roars ON. Source refusals/errors zero. **Accepted player actions fell from 16 to 14** in the 38-second ON comparison; no tank-survival or output advantage has been proved. Full candidate validation must use the latest PR CI.
- **Decision:** Candidate stays Draft; source-native import is not In-Game Validated. No production Current/last-working change, no Approved role, no WoWSims numeric DPS/DTPS simulation. Exact rollback remains v1.0. Evaluate real tank damage/CD waste and three state-advanced recommendations only when a necessary `/hek snap` can verify the policy.
