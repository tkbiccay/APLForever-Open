# Hekili Forever v0.9.0 — open-source compatibility gate

**Latest verified official published tag:** v0.9.0, published 2026-11-18 13:10 UTC, resolved source commit `8f95f2ea0a45428554c1e938ed7357b870030514`.

**Sources:** https://github.com/zmsl/hekili/releases/tag/v0.9.0 ; https://github.com/zmsl/hekili/tree/v0.9.0/docs/wiki ; https://github.com/zmsl/hekili/compare/v0.8.6...v0.9.0

## Source-release claims (not custom-APL proof)
- Feral shipped/default priorities updated from WoWSims; changed Predatory Discipline/Ferocious Bite refunds and counted two Idols. The default keeps single-target behaviour with two/three enemies, leaving player bleed-spreading decisions.
- Guardian default now includes new Bear-built priority and 2/3-target Swipe decision, and Timeline Maul ordering follows Lacerate/Roar upkeep.
- Hunter BM/MM old weave pack variants retired in favour of Turret; source-native test fixtures need real current pack names. Mana cost and timing changes impact Hunter.
- More accurate source Mana/Energy/Rage forecasting, and SimC sequences/custom priority windows support. Verify reserved `actions.windows` name against each actual imported APL before adding custom sequences.
- Other class updates exist; do not assume these are exhaustive without tagged source diff.

## Required APLForever native gate (NOT YET RUN)
- Verify exact released engine import/compile for all source-compatible catalogued revisions (23 supported, others Blocked); preserve 32 SHA-256 historical hashes.
- Source-advance accepted/refused casts, natural resources/belief, known ranks/unlocks, ST/AoE, generic fallbacks and repeated three-decision progression. Include DEMO-006 regression.
- Guardian v1.0 Reported Working vs v1.2 Candidate vs published shipped comparator: defensive ON/OFF Roar/Barkskin, Maul queue and 2/3-target Swipes where eligible.
- Feral DPS v1.0 vs v1.1 Draft vs shipped: Shred/Claw and CP/Rip/Bite states; don't repeat old invalid forced-CP oracle. Old v0.8.6 Feral source fixture unconditionally drained extra Bite Energy; v0.9.0 source has a Predatory Discipline-sensitive refund update, **not yet proof of an accepted custom Bite**.
- Separate fixture/test engine faults from actual APL defects; negative simulation ≠ failure in live game. No in-game approval from CI.

Historical older green v0.8.6 evidence from read-only private reference may inform hypotheses but **does not count as a new public v0.9.0 PASS**. Keep actual action trace, settings, source SHA, and risk-proportionate test results in public docs/PR.
