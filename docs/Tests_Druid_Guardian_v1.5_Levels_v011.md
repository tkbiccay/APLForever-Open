# Guardian v1.5 — level-bound source-native castability (20 November 2026)

**Status: 5 positive Bear-level scenarios, one pre-Bear BLOCKED.** Exact published [Hekili Forever v0.11.0](https://github.com/zmsl/hekili/releases/tag/v0.11.0) source commit `86b739cbc4e6afbcbc693c3790ee81197fc6234b`; full stored custom **v1.5 unselected Draft** SHA256 `75de4388516e3e70cd77f292901c1205f1176dc3561ac9b54dac8fef6c2abcc2`. [Native workflow 44824089560](https://github.com/tkbiccay/APLForever-Open/actions/runs/44824089560) **6 test cases passed their stated assertions, 0 test errors**; five cases prove actual source-accepted Bear actions, one expressly detects absent pre-Bear fixture coverage. Repository hash/CI gate must remain separately green. **Not in-game validated/Approved.**

All three profiles use the same released source-native 36-second `Game.harness.loop`, seed 30417, level/rank filtering, source-budgeted talents, genuine normal hostile attacks and resource events. Default = shipped WoWSims-derived Guardian; working = exact reported-working v1.0; candidate = whole original standalone v1.5. Native cooldowns, defensives and movement OFF. No fake Rage/HP/TTD/queued strike or DPS/TPS.

| Source level | Shipped accepted | v1.0 working accepted | v1.5 candidate accepted | Candidate refusals | Distinct proof / limitation |
| --- | ---: | ---: | ---: | ---: | --- |
| 9 (pre-Bear) | 0 | 2 | 2 | 0 | **BLOCKED:** no combat presses/first-three; stock Guardian world excludes Wrath/Moonfire and Mana. A targeted source-spellbook-only extension also failed: resource/world model incomplete. Unlearned Bear/Maul not cast. |
| 10 (Bear unlock) | 6 | 6 | 8 | 0 | 8 actual Maul queues, 7 eventual legal strikes; no unlearned Lacerate/Primal Bite |
| 20 (early Bear) | 12 | 9 | 9 | 0 | 8 actual Maul queues, 7 eventual legal strikes; no unlearned Lacerate/Primal Bite |
| 31 (modelled high-kit) | 16 | 16 | 16 | 0 | Source fixture reports Lacerate and Primal Bite both known; positive core actions; do NOT infer exact live unlock level |
| 34 (modelled high-kit) | 17 | 14 | 12 | 0 | Source-accepted Primal Bite/Lacerate chain, no repeated refusal |
| 60 (endgame kit) | 17 | 14 | 12 | 0 | Source-accepted Primal Bite/Lacerate chain; high-Rage Maul still unproven |

The v1.5 world accepted three or more actions and progressed three actual combat actions in **each Bear case 10, 20, 31, 34 and 60**. The test checks complete import/compilation, actual learned-action eligibility, legal casts/refusals, world events, and first-five accepted actions. Accepted action counts do **not** imply superior damage, threat, survival or less idle GCD time. It is not a full all-level, ST/AoE or default advantage proof.

## Failed-first and fixture diagnostic

[Initial red run 44823592196](https://github.com/tkbiccay/APLForever-Open/actions/runs/44823592196): level 9 yielded zero combat actions, with only two accepted non-combat working/candidate presses; five other levels passed. A level-9 add-on of the **published, registered** Wrath/Moonfire IDs via `ws.content.kit` still produced no legal caster combat because the Guardian fixture has no secondary Mana/caster world; [red diagnostic 44823856892](https://github.com/tkbiccay/APLForever-Open/actions/runs/44823856892) must **not** be reinterpreted as an APL fault or a success. Final strict test records level 9 `GUARDIAN_LEVEL_BLOCKED ... positive-combat=NOT_PROVEN` and does not pretend to execute a three-cast caster chain. Do not force Mana or alter the production APL merely to make a green fixture. A source-faithful pre-Bear world and real-game level 1–9 observation are separate work.

## Final fallback / repeated recommendations

The candidate produced **8 source-accepted Maul queues and 7 actual strikes** at both levels 10 and 20; source `W.truth` was checked for the correct known Maul rank, not just repeated icons. At levels 31/34/60, accepted Primal Bite/Lacerate action progress had zero refused presses, while the positive **high-Rage** Maul reserve was not reached (see [v0.11 Maul order negative experiment](Research_Guardian_MaulOrder_v0.11.0.md)). The last queued Maul may remain pending at the observation boundary; it is not automatically a repeated-inappropriate suggestion. A real client can still regress through flickering, facing, rage belief or threat display and must be tested.

## Selection, limitations and next

Do **not** promote v1.5 from this test. Keep [Guardian v1.0 Reported Working/Needs Retest](../roles/Druid/Current/APL_Druid_Guardian_Tank_v1.0_ReportedWorking.txt) preferred and last-working; full [v1.5 Draft](../roles/Druid/Candidates/APL_Druid_Guardian_v1.5_Draft.txt) unselected. Exact source-native test [file](../experiments/native/aplforever_guardian_unlock_v011_spec.lua) and [workflow](../.github/workflows/guardian-v011-unlock-fallback.yml) remain reproducible. Test group aggro, Demoralising Roar, toggled Barkskin, genuine high-Rage Maul, low-level pre-Bear caster, in-game next-three and failed final fallback with `/hek snap`; repair the fixture only after sourcing the actual legitimate low-level Mana/ranks. 
