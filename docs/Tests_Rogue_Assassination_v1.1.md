# Tests — Rogue Assassination v1.1 (published Forever v0.11.0)

**23 November 2026.** Source `86b739cbc4e6afbcbc693c3790ee81197fc6234b`. [Full stored-candidate 4/4 PASS, run 45143611408](https://github.com/tkbiccay/APLForever-Open/actions/runs/45143611408); earlier independent in-memory [4/4 PASS, 45143006494](https://github.com/tkbiccay/APLForever-Open/actions/runs/45143006494). Duplicated automation [PR #88](https://github.com/tkbiccay/APLForever-Open/pull/88) closed: its [red run 45142895645](https://github.com/tkbiccay/APLForever-Open/actions/runs/45142895645) diagnosed a **faulty test driver** counting only `rr.presses` indices rather than `rr.combat` for shipped; it independently reproduced same low-Energy refusal. Original negative evidence retained, **not waived**.

| Seed | Initial Energy | Shipped accepted/refused | Protected Current v1.0 accepted/refused | Stored v1.1 Draft accepted/refused | Stored v1.1 subsequent accepted combat events |
| --- | ---: | --- | --- | --- | ---: |
| 30417 | 100 | 38 / 0 | 45 / 0 | **45 / 0** | 40 |
| 30437 | 100 | 34 / 0 | 44 / 0 | **44 / 0** | 39 |
| 30417 | 25 | 45 / 0 | **2 / 501** (`requires:not stealthed`) | **57 / 0** | 54 |
| 30437 | 25 | 47 / 0 | **2 / 501** (`requires:not stealthed`) | **52 / 0** | 49 |

**Test method:** two matched seeds x normal/25 Energy, 75s/100s combat, complete shipped + actual immutable Current + imported stored v1.1 Candidate, **12 full profile source-world executions**, source native import/activate and `LoadScripts/ReviewPacks`, all active action lists and 0 import warnings. Guarded file must be BYTE-IDENTICAL to protected Current except the one verified `actions.opener=garrote` guard. The test explicitly asserts the 501 original failures and zero source castability refusals, major cooldown OFF, exact full-energy non-regression and at least 3 real subsequent accepted actions, not displayed icon count. Low Energy's first actual rejected Garrote had 75 Energy and cost 50; not an affordability violation.

**Final fallback / repeated recommendation:** original Current never reached Mutilate/Sinister Strike final fallback after its Stealth belief broke; 501 Garrote rejections constitute FAIL. Candidate progresses into lawful builders/finishers, with 54/49 subsequent source-accepted combat casts and zero refused in this 60-level fixture. The single duplicated workflow's failed shipped assertion was harness counting error and is independently diagnosed; production condition is testable separate from it.

**Gaps:** real game Stealth/target/position changes and Vanish transitions, poisons/charges, Combo Point truth across swaps, boss/AoE Slice and Dice choice and numeric DPS, 1–60 unlocks, tooltip/range, flicker and live cooldowns; no claim of full validation. Saturday client test: in a harmless naturally low Energy opener compare actual icon to cast, then three subsequent legal actions; if stuck, capture `/hek snap` and rollback to the original v1.0 if that was player's reliable reference. Original v1.0 is not reported in-game working. Source-only Draft, never Approved.
