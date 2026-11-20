# Tests — Guardian v1.5

**Source:** Hekili Forever v0.10.0 `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`. **Unselected Draft**, exact APL SHA256 `75de4388516e3e70cd77f292901c1205f1176dc3561ac9b54dac8fef6c2abcc2`. Controlled native test `experiments/native/aplforever_guardian_aggro_gate_v010_spec.lua` imports the **full stored file**, asserting byte-equality against independently tested in-memory architecture; no fake player HP, mitigation or DPS. Published source-world real Rage and accepted actions; controlled client role/threat at source load; seed30417.

| Role | Client aggro | Group | v1.4 Roar | Earlier role-free Roar | New v1.5 Roar |
| --- | --- | --- | ---: | ---: | ---: |
| DAMAGER | False | Yes | 0 | **1 wasted** | 0 |
| DAMAGER | True | Yes | 0 | — | **1** |
| TANK | True | Yes | **1** | — | **1** |
| TANK | False | Yes | 0 | — | 0 |
| DAMAGER | True | No, 9s | — | — | 0 |

Original [in-memory experiment 44756795738](https://github.com/tkbiccay/APLForever-Open/actions/runs/44756795738) passed **5/5**, zero refused/engine errors. New stored-file test additionally demands **three accepted non-Roar actions after the first Roar**, no repeated inappropriate recommendation. Historical v0.9.0 broad lane, focused v0.10.0 Guardian and catalogue/rollback checks remain separate. **Full stored-source candidate now PASS:** [v0.10.0 run 44759624040](https://github.com/tkbiccay/APLForever-Open/actions/runs/44759624040) passed its source-native tests (4 existing role-free and **5/5 full v1.5** cases), 0 refusals/errors. Complete v1.5 file bytes matched the independent in-memory design.

**Final Fallback / Repeated Recommendation checkpoint:** published `loop.run` provides the true per-tick `run.pressed` accepted-action history (not a `combatCasts` field). On both TANK and DAMAGER client-role controlled grouped-aggro cases, the first accepted Roar at combat tick **34** was followed by three distinct source-accepted actions: **Primal Bite → Lacerate → Primal Bite**. No immediate repeated Roar and no refused action. The rejected role-free/no-aggro case also had legal subsequent actions but still wasted Roar because the trigger was wrong. This does not prove repeated fallback in actual game or under resource extremes.

**Unrun:** actual client's pseudo-specialisation role, group threat observability, native debuff visibility, low levels/unlocks, high-Rage Maul, AoE, risk-specific defensive policy, DPS, TPS, mitigation and actual next three in-game icons. A failed real client test means reselect the exact v1.0 Reported Working/Needs Retest APL and log `/hek snap`; never silently promote a Draft.
