# Tests — Guardian v1.3 Roar upkeep, 19 November 2026

**Current status: Draft / tests submitted, outcomes pending exact-head CI.** Source version **Hekili Forever v0.10.0** `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`, plus retained v0.9.0 source-native regression comparator. v1.3 SHA-256 `200d7109ffcc345c41b05312a49b658b9a456a6f17fb56ea952f84d1d57079e0`.

### Real test inputs / checks

- `.github/workflows/guardian-v010-roar.yml` checks exact upstream SHA, 35 catalogue revisions, protected v1.0 and v1.2, unselected v1.3 and manifest selection. Runs **published-source** `tests/native/aplforever_guardian_barkskin_v086_spec.lua`: shipped, v1.0, v1.1, v1.2 and v1.3 with native actual accepted casts/Rage/debuff, Defensives ON/OFF, registered Barkskin level-43/44 boundary. Explicit maintenance ON under Defensives OFF must Roar for v1.3 but not v1.2; in the solo fixture maintenance OFF must not Roar for v1.3. No swallowed source `H.errors`, raises or refused presses.
- Retained `.github/workflows/native-v090-compat.yml` includes the new Draft in old Guardian 1–9 pre-Bear, 24/25, 30/31, 34 Lacerate unlocks, three real swing/final fallback state advances, natural low/high Rage negative cases and historical tests.
- Source-world settings **sim** may default maintenance ON: new OFF/ON cases explicitly set `maintain_demoralizing_roar` and invoke source's settings change. Do not confuse this with the player's in-game default OFF.
- Original world models no actual tank damage mitigation or incoming Rage from hostile attacks. Source-backfilled Barkskin is registered class action/level/aura but not unmodified stock spellbook, and no health-based defensive triage is claimed.

### Honest gaps and stop conditions

| Checkpoint | State before latest CI |
| --- | --- |
| Complete v1.3 SHA/import, rollout protection | Submitted, pending CI |
| Solo maintenance OFF, Defensives OFF and ON | Source test added, pending CI |
| Explicit Roar maintenance ON while Defensives OFF | Source test added, pending CI |
| Barkskin ON/OFF and L43/L44 | Existing source tests extended, pending CI |
| Natural Rage / full final fallback / three state advances | Existing historical suite extended, pending CI |
| Grouped active-tank **positive** on released client | **Not Demonstrated**; source loop does not faithfully expose group+threat status |
| Five-second/10-Rage optimality, range bracket, debuff across swaps | Unverified; targeted gameplay proof required |
| Maul positive high-Rage reserve | **Blocked**, [issue #3](https://github.com/tkbiccay/APLForever-Open/issues/3) |
| Full 23-role v0.10.0 compatibility | **Partial/Red**, separate [Draft #13](https://github.com/tkbiccay/APLForever-Open/pull/13) |
| Gameplay/user-approved preference | **Not Run / Not Approved** |

**Promotion gate:** Only source-clean castability **plus** observed group tanking and solo recommendation safety, compared to shipped/v1.0/v1.2; exact v1.0 rollback remains selected until explicit maintainer action. A failed or blocked positive is not a passed test.
