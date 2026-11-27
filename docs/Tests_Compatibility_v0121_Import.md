# v0.12.1 compatibility — strict initial import/compile gate
26 November 2026. [Release tracking #112](https://github.com/tkbiccay/APLForever-Open/issues/112). New stable v0.12.1 published 25 November [CurseForge](https://www.curseforge.com/wow/addons/hekili-forever/files/9818487); exact tag SHA a4ca044512d7aacfdebca85cef617b1127115962. v0.12.0 [release notes](https://www.curseforge.com/wow/addons/hekili-forever/files/9817154) carry the substantive changes. Verified pinned [condition documentation](https://github.com/zmsl/hekili/blob/a4ca044512d7aacfdebca85cef617b1127115962/docs/wiki/APL-Conditions-On-Forever.md): player health readings may be absent, 100 fallback, health.known first; TTD unknown 3600, estimated current target only; resource.known read vs estimated. Healer triage remains unavailable per other-party health default full. No new spell kit or APL design claimed.

## Measured result — PASS (import/compile only)

[Native run 45908071181](https://github.com/tkbiccay/APLForever-Open/actions/runs/45908071181), job 140209545129, exact measured head f892fe4bd1e4f3be92b19a077b966c2e0aa17576. Both returned workflows green, [repository validator](https://github.com/tkbiccay/APLForever-Open/actions/runs/45908071082). 23 roles, 31 manifest-selected exact revisions, 31 clean, zero compiler/importer rejects/inactive lists, all 53 catalogue hashes checked. No old Feral/Arms exemptions. New-release player-health compiler support removes the historical four compiler errors but does not make those predicates safe.

| File / line | Action | Review |
|---|---|---|
| Feral Current v1.0 / 52 | Barkskin | health.pct<=65, no initial health.known guard |
| Feral Current v1.0 / 53 | Frenzied Regeneration | health.pct<=45, no guard |
| Feral Current v1.0 / 54 | Nature's Grasp | health.pct<=45, no guard |
| Arms Current v1.0 / 2 | precombat Bloodrage | health.pct>=95, no guard; unknown=100 can satisfy condition |

Guard review is a conservative syntax scan of selected manifest rows, not an exhaustive 53-revision runtime audit. Prioritise Arms health-cost false-positive under unknown readings, then Feral guarded defensives; verify new source semantics through actual health observation/press tests before candidate creation. Generic trinket warnings logged in native CI; investigate verified item support on a separate risk-scoped task, not blanket insertion. Source docs say other group members read full; healer roles remain blocked. Do not change existing APLs or promote from compilation.

## Reconciliation and next task

#111 merged 11a4b18d3ec03ffa912368ce07f65845105ffd85 after 27/27 final CI and [9/9 native](https://github.com/tkbiccay/APLForever-Open/actions/runs/45907879523). 30 merged historical breadth units, 53 protected revisions, 0 Approved. Preserve historical v0.11.0 release pin and test results. Reconcile current-release.json, release ledger and canonical handover on this branch against current main. Evidence head requires fresh CI. Next independent actual combat regressions Guardian Tank and Hunter BM equally, then Feral and Arms health guard, remaining #31–50. No import-only breadth credit. No current-release combat, live gameplay or output claim.
