# Guardian Maul queue

**Confirmed, simulated component.** At pinned Hekili Forever `246abf322ed53e3b7ab796ea7089c72329f3eb9d`, 14 Rage failed with `cost`. At 15 and 35 Rage, the queue left Rage unchanged and the landed strike cleared the queue and carried a cost of 15. See `tests/Forever/helpers/druid_loop_world.lua`, `tests/Game/harness/world.lua` and `behaviours.lua`.

Keep queue acceptance, strike execution and hit outcome distinct. Clearcasting can change swing pricing in the resolver. Verify the aura and expenditure independently. This method can inform Warrior research. Guardian's actual costs and eligibility require class-specific checks and in-game validation. [PR #34 evidence]([private historical reference; not publicly accessible])

**Confirmed, simulated imported selection.** The pinned level-10 fixture in `tests/Forever/wowsims_druid_spec.lua` knows Bear Form and Maul while Primal Bite and Lacerate are unknown. Guardian v1.1 reached `rage_dump:1` with a published Rage floor of 19 and actual Rage of 22.5. Queueing spent nothing. The next matched swing landed at a cost of 14 and cleared the queue. Later low-resource recommendations carried a wait and incurred no premature press. Keep the forecast floor, current belief and actual pre-press resource separate. The same observation method can be reused across roles; unlocks and prices are class- and build-specific. Clearcasting and high-kit reachability remain unverified. [Low-kit CI]([private historical reference; not publicly accessible])

