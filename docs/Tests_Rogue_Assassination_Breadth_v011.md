# Rogue Assassination — published v0.11.0 low-Energy transfer investigation

**23 November 2026; Draft PR #88; evidence PENDING.** Source: `zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b`. Full protected Current `roles/Rogue/Current/APL_Rogue_Assassination_v1.0_Draft.txt` remains unchanged; shipped source profile is first comparator. No stored Candidate or selection is created.

**Falsifiable hypothesis:** the Combat v1.0 low-Energy Garrote refusal observed in PR #83 transfers to Assassination because both complete Current APLs contain the same opener guard. An in-memory **single-predicate** guard requiring precombat stealth or the existing Vanish/Ghostly Strike exceptions may avoid a repeatedly unaffordable opener while preserving three legal subsequent actions.

**Native scenarios:** two seeds 30417/30437; normal 100 Energy/75s and 25 Energy/100s; source world `Forever.helpers.rogue_world.Assassination`, source-world mob health 1e9, cooldowns/minor/defensives OFF. Import every full Current list, assert no compiler errors, count actual accepted combat presses rather than simulation ticks, report refused reasons, Garrote, Shank, Mutilate, Sinister Strike, Eviscerate, Major OFF. Full shipped vs Current vs **test-only in-memory** guard. Exact-head CI must pass before any merger.

**Failure gate:** a missing native Assassination fixture, changed guard, no genuine three accepted follow-ons, source-refused guarded actions, or Major OFF breach means investigate; do not claim transferable fix. If the original Current has no refusals at low Energy, record a **negative cross-spec result** and remove the untrue expected-positive assertion. This source fixture cannot prove stealth timing, poisons, actual target health, real-client energy regen, damage, 1–60 unlocks or gameplay safety.

**Cross-spec decision after logs:** classify whether the cause is APL opener eligibility, engine/Belief state, learn/rank data, fixture or intended mechanics; only then consider a complete unselected Assassination Draft and separate Subtlety transfer test. Zero Approved, immutable rollback untouched.
