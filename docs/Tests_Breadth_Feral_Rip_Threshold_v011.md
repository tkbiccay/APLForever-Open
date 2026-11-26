# Breadth #30 — Feral Rip four versus five combo points
26 November 2026 | [PR #111](https://github.com/tkbiccay/APLForever-Open/pull/111) | **historical** released source v0.11.0 86b739cbc4e6afbcbc693c3790ee81197fc6234b. Latest stable v0.12.1 published 25 Nov; exact tag a4ca044512d7aacfdebca85cef617b1127115962. [Release compatibility triage #112](https://github.com/tkbiccay/APLForever-Open/issues/112); do not transfer outcomes without risk-based latest-release verification.

## Method and evidence
[Native 9/9 PASS](https://github.com/tkbiccay/APLForever-Open/actions/runs/45907551286), job 140207821750, exact measured head 368793c3d1993dda555d3d3507a1071db05d367d, 25/25 workflows green, [integrity validator](https://github.com/tkbiccay/APLForever-Open/actions/runs/45907551155). Evidence-only reconciliation requires its own CI. 36 full worlds: three seeds 30417/30437/30461, 20s targeted proxy and 95s both targettarget contexts, four whole profiles (pinned shipped, exact Current v1.0 f2f72d0621c8e709c7df8f2ccff248ce0af604a1c02e115a5ad725cf93d288f1, unselected v1.4 3ccb818012c29e5972ee4788b2613631103b028755cf5f9a34767ffaaeca85b4, same v1.4 with one in-memory >=4 to >=5 Rip threshold). Native level-60 Feral, 4yd, target HP 1e9, full initial Energy100, first press varied by profile/seed, optional cooldowns/minor/defensives/movement/interrupts OFF. No APL bytes, selections or statuses changed. Current retains three known old-release health compiler errors; not clean. Shipped in this fixture accepted Shifting Power despite minor toggle OFF in some seeds; not proof of live toggle cause. All 36 worlds zero raw refusals, invalid finisher transitions and Bite casts.

| Context | Profile | Active accepted | Landed Rip | Rip attempts at 4 / 5 CP | Aura seconds | First attempted Rip time (world clock) |
|---|---|---:|---:|---|---:|---:|
|20s targeted proxy|Shipped|13–15|1–2|1 / 0–1|12–14.6|7.2|
|20s targeted proxy|Current|7–10|1|0 / 1–2|9.6–11.6|11.4–13|
|20s targeted proxy|v1.4 four|7–9|1|1 / 0|12|8.8|
|20s targeted proxy|v1.4 five|7–10|1|0 / 1–2|9.6–11.6|11.4–13|
|95s targeted proxy|Shipped|47–49|6–7|4–5 / 3–5|72–80.8|7.2|
|95s targeted proxy|Current|36–41|5–6|0 / 6–8|54.4–62.6|11.4–13|
|95s targeted proxy|v1.4 four|30–40|6|5–8 / 0–1|61–71.8|8.8|
|95s targeted proxy|v1.4 five|36–41|5–6|0 / 6–8|54.4–62.6|11.4–13|
|95s non-targeted proxy|Shipped|44–55|7|3–5 / 2–5|76.6–79.8|5.2–7.4|
|95s non-targeted proxy|Current|36–41|5–6|0 / 6–8|54.4–62.6|11.4–13|
|95s non-targeted proxy|v1.4 four|32–38|5–6|6–8 / 0|60–71.4|7.4–10.4|
|95s non-targeted proxy|v1.4 five|33–37|5|0 / 5–7|52.6–58.4|13–13.8|

At 20s four-point Rip followed by 4–5 legal accepted non-Rip actions versus 2–4 for five; sustained four 22–30, five 22–31. All four/five CP cap <=5, no builder at cap, valid true landed point spend and avoided point retention. Shipped 0–3 cap builder attempts; no claim those lose effective CP without separate effect proof. Targeted contexts v1.4 four uses Claw, zero Shred; non-targeted proxy uses 15–21 Shreds, zero Claw. Actual target targeted player during accepted actions in **both** contexts; this is an observer answer experiment, not actual facing/aggro. All Rip first-attempt times include pull t3; not elapsed combat time. Four reached more aura seconds in each matched sustained context range but no calibrated damage. No proof Bite is optimal/available under these settings, no all-mode coverage.

## Source and decision
Pinned [druid_loop_world.lua](https://github.com/zmsl/hekili/blob/86b739cbc4e6afbcbc693c3790ee81197fc6234b/tests/Forever/helpers/druid_loop_world.lua) maps Rip to a landed debuff and points=all, aura duration not scaled by spent CP in this fixture, no periodic bleed ticks; [observer.lua](https://github.com/zmsl/hekili/blob/86b739cbc4e6afbcbc693c3790ee81197fc6234b/tests/Game/harness/observer.lua) notTargeted affects UnitIsUnit targettarget answer only. Reused #26 source/guides for same mechanics; no new external guide conclusions. Do not call the five-point alternative worse DPS. Keep existing unselected v1.4 and protected Current, no new release or promotion. New release [v0.12.0 notes](https://www.curseforge.com/wow/addons/hekili-forever/files/9817154) changes actual health readings, TTD, missed Rake/Rip and combo refresh; [v0.12.1](https://www.curseforge.com/wow/addons/hekili-forever/files/9818487) translations. P0 compatibility triage before new mechanical APL decisions, preserve v0.11 evidence. Transfer lesson: distinguish observer proxy from world truth; compare real CP effect, not only recommendation count. #30 provisional until exact-head CI and protected merge; no live Approved.
