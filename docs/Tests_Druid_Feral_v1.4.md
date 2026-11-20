# Feral DPS v1.4 — bounded v0.11 native tests

**Build:** Hekili Forever v0.11.0 `86b739cbc4e6afbcbc693c3790ee81197fc6234b`. **Candidate:** full standalone [v1.4 Draft](../roles/Druid/Candidates/APL_Druid_Feral_v1.4_Draft.txt), SHA-256 `3ccb818012c29e5972ee4788b2613631103b028755cf5f9a34767ffaaeca85b4`. **Preferred unchanged:** Current v1.0 Draft; no last-working/Approved Feral baseline.

| Test and comparison | Source-native result | Caveat |
| --- | --- | --- |
| Initial Travel, 4yd, stationary 38s, combat observed | shipped 22 accepted/1 Cat/16 attacks; v1.3 **0/0/0**; in-memory hypothesis **16/1/14**, 0 refused | [3/3 initial experiment](https://github.com/tkbiccay/APLForever-Open/actions/runs/44820389529); real user intent unknown |
| Native normal Cat, stationary 30s | protected v1.3 and guarded in-memory both **12 accepted, 11 attacks, 0 Cat shifts, 0 refusals** | [4/4 movement-gated run](https://github.com/tkbiccay/APLForever-Open/actions/runs/44820645910) |
| Initial Travel, moving player mock speed=7, 20s | source observed **101 moving combat ticks**, both protected and guarded in-memory **0 Cat / 0 attacks / 0 refused** | source-facade mock installed before engine load; live movement not run |
| Exact stored v1.4 vs in-memory hypothesis, all scenarios | **Pending rerun of v0.11 source-native workflow** after addition of stored candidate and catalogue hash | Never infer from an earlier successful experiment |
| Guardian/BM regression, full 1–60, real pet/aggro, live movement, DPS | **Not Run** | No automatic cross-role/global claims |

**Final fallback / repeated recommendation:** Original v1.3 in Travel Form produced a **non-progressing zero-action tail** rather than an uncastable repeated icon. The stationary-in-combat alternative emitted one source-accepted Cat shift and continued with legal attacks; moving negative emitted zero Cat shifts on purpose to protect escape intent. In-game player-control regression can overrule source-native action counts. The [native experiment](../experiments/native/aplforever_feral_travel_form_v011_spec.lua) is independently runnable in [PR #52](https://github.com/tkbiccay/APLForever-Open/pull/52).

**Rollback:** Never replace [Current v1.0](../roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt) or existing v1.3 without human game evidence. Record /hek snap at first conflict, actual addon build, mobility and next-three actions.
