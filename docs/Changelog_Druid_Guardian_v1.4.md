# Guardian v1.4 change log — 20 November 2026

- **Previous Draft v1.3**: full standalone APL with Roar separated from Defensives but still permits `settings.maintain_demoralizing_roar` for explicit uptime. Focused 18/18 source-native tests passed on v0.10.0.
- **New Draft v1.4**: complete one-file APL. Exactly one functional line changes, replacing explicit maintenance-setting dependency with source-visible group+tanking, boss and long solo fight heuristics. The known/target/debuff/Belief Rage minimum and optional Barkskin/Elune's Light off-switches remain.
- **Why**: maintainer wants self-directed routine decisions, no manual upkeep toggle. Guard against levelling Rage waste and repeated unwanted Roars.
- **Safety**: Original shipped reference, v1.0 Reported Working, archived v1.1 and v1.2/v1.3 candidates remain immutable and restorable. No preferred selection/engine modifications. Source-native and gameplay evidence separately recorded in `Tests_Druid_Guardian_v1.4.md`.
- **Learning**: APL can eliminate dependence on settings when source-observable conditions exist, but hidden TTD, tank threat and health mean in-game proof and optional player off-switches still matter. No repeated research for other roles until analogous mechanics are proven.
