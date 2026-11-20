# Limitations — Warrior Protection v1.1

- Source `aggro` may be hidden or differently reported in actual instances; avoids the unreliable client pseudo-role `tanking` dependency, but client aggro itself must be observed live.
- Shield Block is known at level16 in source; below unlock, the existing legacy low-level APL's `actions.early`/stance/fallback remains untouched. Level1–15 full live coverage unverified.
- Actual incoming block chance, two-charge use, Revenge proc timing and Rage gain are source-modelled, not measured in game; do not convert count differences into DPS, threat or survivability claims.
- Stances, 1H+shield requirement, source Belief Rage lower bound, cooldown gating and optional user-native Require Toggle still govern castability; a user's native deliberate off-switch cannot be overridden.
- No complete 1–60, facing/range, off-tank, boss or endgame raid proof; no Approved. Exact Current PendingInGame v1.0 is checkpoint; new Draft is not auto-selected.
