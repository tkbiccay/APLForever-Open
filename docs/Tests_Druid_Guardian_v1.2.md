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

### v0.9.0 Guardian v1.2 full-chain extension — 19 November 2026

- **Hypothesis / coverage gap:** Source-native v0.9.0 `aplforever_guardian_highkit_tail_v090_spec.lua` historically compared shipped, **reported-working v1.0**, archived Draft v1.1, but did not import **complete v1.2 Draft Candidate** into the natural low-Rage/repeated-fallback and unlock tests. The separate Barkskin fixture above had already tested v1.2 with source-registered spell ID 22812 and Defensives toggles, so this is a *new reachable-chain regression gate*, not re-research of Barkskin or a new APL.
- **Patch and pin:** [Public PR #12](https://github.com/tkbiccay/APLForever-Open/pull/12), released Hekili Forever **v0.9.0** `8f95f2ea0a45428554c1e938ed7357b870030514`. Include v1.2 by its existing source-native manifest entry, assert exact `Candidates` path and immutable catalogue SHA `da358b7c04b47732966c47a91b7f6f5d32410f9077aabe2aac39252139a47b76`. **No revision bytes, catalogue or preferred/reference fields changed.**
- **Same tests, independent candidate:** level 60, 2 and 3 naturally attacking enemies with real Rage/belief observations and repeated first-icon checks; level 24/25/29/30/31/34 source trainer/talent unlocks and repeated recommendation checks; caster-mode levels 1/3/4/6/9 with source Wrath/Moonfire Mana costs; each must have real accepted presses, event progression and **zero source-world refusals/errors/raises**. Source-world L1–9 uses the released Balance caster closure and a non-realistic 4,000 Mana pool; import/guard proof only, not true low-level DPS or Mana economy.
- **Strict known limitation retained:** high-Rage Maul reorder's mandatory positive queue/strike from natural true/believed Rage remains *Blocked* in the separate strict experiment. The newly included v1.2 does not receive an unearned queue/survival/damage PASS. Defensives are OFF for natural-tail tests, so these test **core action and final fallback stability**, not new Barkskin mitigation efficacy.
- **Validation status:** Source-native new tests **Pending exact GitHub Actions result** at authoring; do not equate the earlier v1.1/v1.0 PASS or Barkskin PASS with v1.2 full-tail proof. See the matching PR's final workflow conclusion and capture failures without weakening assertions. If it passes, retain `v1.0 Reported Working / Needs Retest` as selected, and `v1.2 Draft` unselected. No APL promotion or live-gameplay proof.
