# Tests — Druid Guardian v1.2 proactive Barkskin Draft

**18 November 2026 | Source-native focused study, not gameplay approval**

### Source and acceptance

- Hekili Forever released **v0.8.6** `2e9cb6a78d9088007e9acd9cce3eeb0e91463cc5`; full independent v1.0/v1.1 and shipped comparator preserved; v1.2 exact full one-file candidate. [PR #89]([private historical reference; not publicly accessible]).
- High-value hypothesis: Hekili can recommend a source-registered level-44 Barkskin under **Defensives ON**, never recommend it OFF, preserve Roar, and avoid fictitious `health.pct` triggers. The source Druid loop lacks Barkskin in its map, so the test **explicitly adds only the registered spell/learn/aura effect** to a test-only world. This does **not** add game-secret health or assert real damage mitigation.
- Genuine 2 attacking enemies (not necessarily two boss-strength attacks), 38 s, seed 30417, no direct resource oracle, real source casts/waits/GCD/auras, and no fabricated positive hit/heal data. Level 43/44 trainer boundary. Strict zero refusals/errors/raises, non-vacuous accepted combat actions, real Barkskin aura for every accepted Barkskin, guarded ON at >=44, OFF and L43 never. Separate byte-exact v1.2 vs in-memory v1.1+branch parity test.
- No 1–60 full suite, actual player-health observability, survival/missed-attack reductions, target swaps, threat or final post-upkeep stress proof is implied.

### First genuine source-native evidence — PASS

Original first test (before registering a new candidate) passed **10 tests, 0 failures/errors** in [source-v0.8.6 run 44295610762]([private historical reference; not publicly accessible]), which later became cancelled **after the passing targeted step** as branch updates restarted CI; retain exact recorded results without treating that whole run as green.

| Source profile and condition | Accepted Barkskin / registered aura | Accepted Roar | Total accepted actions |
| --- | --- | ---: | ---: |
| Shipped L60 OFF / ON | 0 / 0 | 2 / 2 | 18 / 18 |
| v1.0 Reported Working L60 OFF / ON | 0 / 0 | 2 / 2 | 16 / 16 |
| v1.1 archived Draft L60 OFF / ON | 0 / 0 | 0 / 2 | 16 / 16 |
| v1.1 **test-only** Barkskin-branch L60 OFF / ON | 0 / **1** (ON aura **1**) | 0 / 2 | 16 / **14** |
| v1.1 test-only L43 ON / L44 ON | **0 / 1** (L44 aura **1**) | 2 / 2 | 16 / 14 |

**Important interpretation:** The test-only mitigation branch added an actual source-accepted defensive and retained Roar upkeep, but its one GCD affected the action sequence (14 rather than 16 accepted in 38s). The source world assigns **no real damage-reduction model** for Barkskin; **no survival, DPS or threat superiority** demonstrated. Shipped health condition failed under this hidden-health fixture; do not equate this with every real client state.

### Production-immutable gate

The final branch adds source-hash-catalogued v1.2 and requires the focused native suite to compare the **real imported v1.2** against the **same in-memory experimental branch**. It separately checks all active internal APL lists, exact v1.1 delta, v1.0 rollback hash, level-44 known gating and Defensives OFF/ON. Existing v0.8.2/v0.8.3/v0.8.5 baselines continue to select version-compatible revisions; historical v1.1 test comparisons point to its byte-identical Archive path. The repository's Python unit tests and validator are mandatory, together with the pinned v0.8.6 native lane. **Consult latest [PR #89]([private historical reference; not publicly accessible]) checks for final state; do not infer from this first 10-test proof that full final CI or in-game approval completed.**

**Status:** v1.2 **Draft Candidate only**; v1.0 **Reported Working / Needs Retest** remains preferred; archived v1.1 unchanged bytes. Next proof, only when ordinary gameplay is available: real Barkskin first icon with Defensives ON at level >=44 and OFF absence, Roar upkeep, exact cooldown timing and three post-upkeep recommendations, then whether early Barkskin is actually useful under real incoming tank damage. Negative result → rollback/protect, no automatic promotion.
