# Changelog — Druid Guardian v1.3 (19 November 2026)

**Before:** v1.2 Draft uses Defensives to gate both routine Demoralising Roar debuff upkeep and Barkskin. Its solo/tank distinction is not explicit. Protected v1.0 has existing Guardian `maintain_demoralizing_roar` setting and remains Reported Working / Needs Retest.

**After (unselected complete v1.3 Draft):** two source lines changed: call mitigation in Bear Form separately from Defensives; Roar when explicit upkeep option ON or proven grouped tanking signal after five seconds and conservative extra Rage. Barkskin remains a Defensives-only cooldown; every other standalone action/list/fallback remains byte-for-byte as v1.2.

**Hypothesis:** less wasted Roar in solo play and better group tank maintenance regardless of Defensives OFF. **Proof:** source-native tests newly submitted; no claimed DPS/TPS/survival improvement. See `Tests_Druid_Guardian_v1.3.md`.

**Safety:** exact protected v1.0/v1.1/v1.2 hash files, preferred choice, rollback and upstream source are unchanged; v1.3 is a separate Draft. Main merge (if green) must not imply player selection, approval or automatic external addon maintenance.
