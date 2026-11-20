# Guardian v1.4 limitations — 20 November 2026

- `target.is_boss` may read false for dungeon/raid bosses. The `group&tanking` alternative is from available APL condition documentation but has no independently demonstrated positive in a true player-group source world. Need in-game tanking trace before approval; do not invent source success.
- `tanking` in real Forever may be false/lagged in some encounters; solo long-fight and group eligibility can fail closed. APL cannot know role assignment, main-tank intent, player/enemy combat health, true incoming damage or remaining fight time.
- `target.within5` and AoE counts rely on estimated/limited info; unknown range may read true. Out-of-range rejected cast or repeated inappropriate recommendations are regression failures.
- 4/5/12 seconds and reserve `rage.lo >= cost+10` are proposed conservative heuristics, not optimality proof; short raids/long solo fights may favour another point.
- Barkskin/Elune's Light still use intentional **Defensives/Major Cooldowns** controls; routine Roar does not require any maintenance toggle. Turning those optional off-switches OFF suppresses those discretionary cooldowns. Full automation of reactive defensives cannot be accurately done with hidden health; do not blindly ignore player off-switches.
- Official Hekili Forever v0.10.0 all-role compatibility remains Partial/Needs Retest; high-kit Maul positive queue remains Blocked. No PvP, full 1–60, real pet/form, damage output, survival or threat measurements follow from this APL experiment. Preserve v1.0 rollback.
