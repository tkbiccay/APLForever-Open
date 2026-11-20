# Tests — Guardian v1.5

**Source:** Hekili Forever v0.10.0 `3c2cf3e32472cc807b1ba29d992fc13a273da8ee`. **Unselected Draft**, exact APL SHA256 `75de4388516e3e70cd77f292901c1205f1176dc3561ac9b54dac8fef6c2abcc2`. Controlled native test `experiments/native/aplforever_guardian_aggro_gate_v010_spec.lua` imports the **full stored file**, asserting byte-equality against independently tested in-memory architecture; no fake player HP, mitigation or DPS. Published source-world real Rage and accepted actions; controlled client role/threat at source load; seed30417.

| Role | Client aggro | Group | v1.4 Roar | Earlier role-free Roar | New v1.5 Roar |
| --- | --- | --- | ---: | ---: | ---: |
| DAMAGER | False | Yes | 0 | **1 wasted** | 0 |
| DAMAGER | True | Yes | 0 | — | **1** |
| TANK | True | Yes | **1** | — | **1** |
| TANK | False | Yes | 0 | — | 0 |
| DAMAGER | True | No, 9s | — | — | 0 |

Original [in-memory experiment 44756795738](https://github.com/tkbiccay/APLForever-Open/actions/runs/44756795738) passed **5/5**, zero refused/engine errors. New stored-file test additionally demands **three accepted non-Roar actions after the first Roar**, no repeated inappropriate recommendation. Historical v0.9.0 broad lane, focused v0.10.0 Guardian and catalogue/rollback checks remain separate. **Pending new CI result until independently inspected.**

**Unrun:** actual client's pseudo-specialisation role, group threat observability, native debuff visibility, low levels/unlocks, high-Rage Maul, AoE, risk-specific defensive policy, DPS, TPS, mitigation and actual next three in-game icons. A failed real client test means reselect the exact v1.0 Reported Working/Needs Retest APL and log `/hek snap`; never silently promote a Draft.
