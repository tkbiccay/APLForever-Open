# Tests — Druid Feral DPS v1.3 (20 November 2026)

**Test level:** Source-native / Controlled client threat. Published `zmsl/hekili@v0.10.0` `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`; source simulator, seed 30417, level 60, 38s, two controlled attackers, 4D published world, exact full v1.2 versus in-memory alternatives and full v1.3. Test location `experiments/native/aplforever_feral_aggro_defensive_v010_spec.lua`. Full run [44736361462](https://github.com/tkbiccay/APLForever-Open/actions/runs/44736361462) **7 successes, 0 failures, 0 errors** for in-memory equivalent; the final entire-byte-candidate equivalence and actual full v1.3 native re-import [run 44737792288](https://github.com/tkbiccay/APLForever-Open/actions/runs/44737792288) **PASSED 7/7, 0 failures/errors**. All full v1.3 source bytes must remain SHA-256 protected.

| Profile and client state | Accepted Barkskin | Refused world actions | Assessment |
| --- | ---: | ---: | --- |
| Entire v1.2; Feral DAMAGER, group threat true, Defensives ON | 0 | 0 | Negative comparator: `tanking` unreachable |
| Role-free aggro, group threat true, Defensives ON | 1 | **1 GCD refusal** | **REJECT** |
| Aggro with `line_cd=2`; same | 1 | **1 GCD refusal** | **REJECT** |
| Proposed full v1.3 / matching in-memory `gcd.remains<=0`; same | **1** | **0** | Positive source-accepted cast and Barkskin aura |
| Proposed, threat true, **Defensives OFF** | 0 | 0 | User opt-out respected |
| Proposed, **no observed threat**, Defensives ON | 0 | 0 | No unnecessary cast |
| Proposed, **solo single target** with threat, Defensives ON | 0 | 0 | No unnecessary solo cast |

No source errors/raises on the matched tests. Other ordinary attacks remain accepted. Actual hostile threat, 1–60 ability unlock boundaries (especially Barkskin level 44), defensive value, movement/range, different seeds, group/AoE visibility in dungeons and raids, player HP, output, and real client repeat recommendations are **NOT RUN / Unverified**. Positive Barkskin ability and aura were added to the test-only published Feral world because its fixed stock spellbook excludes them; no game cast was faked. First three live recommendations and **Final Fallback / Repeated Recommendation** remain required before promotion.

**Acceptance status:** `Draft / source-native scoped, pending broader in-game proof`; no Selected / In-Game Validated / Approved claim. **Rollback:** old Current v1.0 Draft, prior complete v1.2 Candidate retained; no reported-working version available.
