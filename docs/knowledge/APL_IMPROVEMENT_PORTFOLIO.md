# All-role APL improvement portfolio

28 November 2026. Owner objective: continue after 50/50 breadth milestone until each Supported role has measured improvement against exact Current/working and released shipped comparator, or a justified retain decision after testing worthwhile alternatives. Existing finite 1000-hourly-slot automation. No forced edits or approval from CI. Record changed behaviour and shortcomings; first icons are not casts; compiler and migration replay do not count. Initial triage, not exhaustive historical evidence audit.

| Role | Baseline revision / SHA prefix | Latest revision | Improvement review |
|---|---|---|---|
| Druid_Balance | v1.0 1cf83328f343 | v1.0 | Retain v1.0 after #33: 60 worlds, late Insect eliminated but one medium fight regressed; no consistent gain; revisit estimate confidence and AoE |
| Druid_Feral | v1.6 701838368217 (owner-selected engineering baseline; v1.0 historical Current) | v1.6 Draft | v1.5 measured Barkskin merged #116; owner-requested v1.6 merged #122, icons10/10 + combat10/10 (40 worlds), 9–14 follow-ons, raw0; live gate pending |
| Druid_Guardian | v1.0 f386e158a5e2 | v1.6 | P0 #114 measured v1.6; #124 solo stealth 11/12 initial, missing off-form Mana hypothesis under retest; live gate pending |
| Hunter_BeastMastery | v1.1 a9d752c5e6cd | v1.4 | P0 scoped v0.12.1 native candidate evidence #114; live gate pending |
| Hunter_Marksmanship | v1.0 43c78f4517f2 | v1.1 | Audit existing candidate measured benefit; improve or retain |
| Hunter_Survival | v1.0 e58fe21c311c | v1.1 | Audit existing candidate measured benefit; improve or retain |
| Mage_Arcane | v1.0 d89600259308 | v1.1 Draft | Measured explicit Fire Blast range guard: 1488→0 strict test-oracle refuses, 0→64 offensive, near parity; stored 13/13 and merged #119 |
| Mage_Fire | v1.0 500a40752f3f | v1.1 | Audit existing candidate measured benefit; improve or retain |
| Mage_Frost | v1.0 f05a17a34b9d | v1.0 | Retain v1.0 after #34: 45 worlds, low-Mana Cone eliminated but costs/progression mixed; merged #118, seek independent improvement |
| Paladin_Protection | v1.0 8f1ba35a4663 | v1.1 | Audit existing candidate measured benefit; improve or retain |
| Paladin_Retribution | v1.2 d5a05302c341 | v1.3 Draft | Measured emergency shield at known critical solo health, 30 worlds, native 10/10; merged #120, 30/30 CI and 10/10 native |
| Priest_Shadow | v1.0 66ee308453ae | v1.0 | #121 merged 19/19 native, 54 worlds, all matched outcomes identical; effective toggle auto-enable verified; retain Current |
| Rogue_Assassination | v1.0 f817fe4ab906 | v1.1 | Audit existing candidate measured benefit; improve or retain |
| Rogue_Combat | v1.0 ff69f6d4baa3 | v1.1 | Audit existing candidate measured benefit; improve or retain |
| Rogue_Subtlety | v1.0 3d5fa90ecfd4 | v1.1 | Audit existing candidate measured benefit; improve or retain |
| Shaman_Elemental | v1.0 fd19fe1d83d9 | v1.0 | #123 measured 36 worlds: free low-Mana CL 1→21, all costs unchanged, three pairs fewer completions; retain, merged #123 (28/28 CI, 13/13 native) |
| Shaman_Enhancement | v1.0 76c3ed75a4b0 | v1.1 | Audit existing candidate measured benefit; improve or retain |
| Warlock_Affliction | v1.0 65c664533b69 | v1.0 | Priority gap: no separate Candidate file; audit existing whole APL and test worthwhile alternative |
| Warlock_Demonology | v1.0 067ae757344a | v1.0 | Priority gap: no separate Candidate file; audit existing whole APL and test worthwhile alternative |
| Warlock_Destruction | v1.0 560235675b98 | v1.0 | Priority gap: no separate Candidate file; audit existing whole APL and test worthwhile alternative |
| Warrior_Arms | v1.0 3bb923e9b071 | v1.2 | Measured v1.2 health safety, 17/17 native, merged #115; boss HP cost/live unproved |
| Warrior_Fury | v1.0 bff9e4ecfac2 | v1.3 | Audit existing candidate measured benefit; improve or retain |
| Warrior_Protection | v1.0 e97acd14bdeb | v1.1 | Audit existing candidate measured benefit; improve or retain |

Exact hashes and paths in [catalogue](../../catalogue/roles.json). 23 Supported; five healers blocked pending verified group-triage. Nine roles without separate Candidate files: DEMO-006/Demonology, Balance, Arcane, Frost, Retribution, Shadow, Elemental, Affliction, Destruction. Rotate by risk; preserve DEMO rollback, keep co-P0 Guardian/BM and P1 Feral. No 23/23 improvement count inferred from candidate existence. Reconcile historical proof as part of substantive changes.


**28 November owner decision:** Feral v1.6 is the explicit engineering comparison baseline for subsequent development; v1.5 SHA 79385bc5f160890b546559f062c5d76c60275112c592ed20d0ab02d429b8a7d7 is immediate rollback. Physical Current and catalogue preferred remain v1.0 until a separate lifecycle/live decision. No new revision, working status or approval. All 58 existing hashes preserved. [Cross-spec applicability](lessons/CROSS_APL_TRANSFER.md) required for material findings.
