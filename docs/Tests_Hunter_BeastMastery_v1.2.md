# Tests — Hunter Beast Mastery v1.2 Draft: independent Hawk range and source guardian model

**19 November 2026 | Simulated source-native test | NOT In-Game Validated**

## Test contract

- Pinned Hekili Forever **v0.9.0**, exact 8f95f2ea0a45428554c1e938ed7357b870030514; all original shipped/archived/current APLs and their hashes preserved. New v1.2 is a separate complete imported file with `preferred_apl=null`.
- Compare **shipped BM Turret, archived custom v1.0, Current Draft v1.1 and unselected Candidate v1.2**. Test actual source casts/refusals, error/raises, Major toggle ON/OFF, normal **12 yards**, one seeded native world, a natural **175-second low-Mana tail**, and the exact **6-yard dead zone**. No synthetic resource drains or fake accepted casts.
- The released v0.9.0 source reports `summon_hawk` **0–35yd** and `serpent_sting`, `arcane_shot`, `aimed_shot`, `multi_shot` **8–35yd**; melee strikes end at **5yd**. The six-yard fixture is **not** faithful for automatic white ranged shot suppression, so exclude that claim.
- **New model check:** `H.Hekili.Class.pets.hawk` must have `cap=2`, `slot>=6`. The actual released `VS.Guardian` belief must reach **two simultaneous modelled Hawk slots** in a state-advanced test, and no accepted new Summon Hawk press may occur while both slots are modelled active. That is **source Belief**, not live pet observation.
- The shipped Turret's failed-first **109 repeated `range` refusals** at six yards ([run 44488313535](https://github.com/tkbiccay/APLForever-Open/actions/runs/44488313535)) are retained as a **negative comparator**, never counted as acceptable player behaviour. Every custom APL remains required to have **zero real refused casts** in tested cases. The known single shipped off-GCD floating-point `casting` edge elsewhere is separately instrumented, not a blanket waiver.
- Source-normal 12yd and natural Mana tests must not regress vs the two existing standalone Drafts; a changed valid cast sequence can be studied but is not proof of output. Post-upkeep/repeated first-icon safety remains mandatory; no claim of full 1–60 proof.

## Actual evidence to date

- [Run 44488734153](https://github.com/tkbiccay/APLForever-Open/actions/runs/44488734153): **focused 13/13** source tests PASSED a *complete in-memory v1.1 only* guard variant at six yards, recording **three accepted Summon Hawk casts** with zero refusals. The whole workflow was later cancelled after further PR commits, so do not report its total workflow result as PASS.
- [Run 44496062631](https://github.com/tkbiccay/APLForever-Open/actions/runs/44496062631): public repository validation **PASS** for the actual separately catalogued v1.2, 33 SHA records and corrected lifecycle folder semantics.
- [Run 44496062850](https://github.com/tkbiccay/APLForever-Open/actions/runs/44496062850): the **focused source-native Hunter step PASSED** for exact imported v1.2 including the **two-slot Hawk Belief positive gate**; the broader 23-role workflow must finish separately before any full-suite PASS claim. Inspect final logs for exact candidate cast/timing counts; they are not pre-assumed.
- The earlier 175-second natural v1.1 comparator (seed 30417) first crossed 200 real Mana at **82.0s**, minimum 3.33, with **zero refusals** in its validated native loop. Candidate outcomes from the latest code should be measured, not guessed.

## Decision

**Draft Candidate / Pending further verification**, not preferred, working, in-game validated or Approved. No numeric DPS comparison performed; no demonstrated live Hawk cap or damage. Roll back any suspect recommendations to byte-exact Current v1.1 (development comparator), while Guardian Feral Tank's reported-working v1.0 remains protected independently. Reuse the tested **native-range-versus-APL-guard check** across specs only after verifying their separate ranged, melee and movement conditions.
