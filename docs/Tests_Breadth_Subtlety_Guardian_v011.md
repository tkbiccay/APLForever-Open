# Tests — Subtlety Ghostly Garrote and Guardian carried Rage, breadth #18–19

**23 November 2026. Source-native only, not gameplay Approved.** Published stable Hekili Forever v0.11.0, exact upstream SHA **86b739cbc4e6afbcbc693c3790ee81197fc6234b**. [PR #103](https://github.com/tkbiccay/APLForever-Open/pull/103), [full 8/8 native PASS 45283562352](https://github.com/tkbiccay/APLForever-Open/actions/runs/45283562352). The [first 4/8 RED 45283067377](https://github.com/tkbiccay/APLForever-Open/actions/runs/45283067377) was an incorrectly shared test assertion for a new Guardian-only action list which historical Current lacks. That assertion was fixed **without changing any APL**. Original Rogue red was real and remains captured.

## Pinned complete benchmark, scope and method

2 matched seeds **30417/30437** × source TRUE initial 0/100 Energy (Subtlety) or 0/50 carried-in Rage (Guardian) × 3 complete published shipped/exact protected Current/whole tested candidate profiles = **24 source-world combat loops across 8 cases**, 105–115s Rogue and 85s Guardian. All native Major/Minor/Defensives/Interrupts/Movement OFF. True W.press accepted/refused action/reason, emitted proc aura application/expiry, actual queued/paid Maul, source true resource, separately engine lower-band maximum and 3+ real follow-ons measured. Source simulated talents/gear, unmeasured damage, no actual PvE DPS/health/threat or client proof. Shipped default is comparator only, never custom APL architecture ceiling.

## #18 Rogue Subtlety — 576 repeated uncastable Garrotes, full unselected v1.1 correction

Exact Current full v1.0 SHA256 **3d5fa90ecfd4a9d1f57fa8c73f6cb6f72a7bf8dff48577285125af16433ff77e**. Starting TRUE 0 Energy, protected Current repeatedly suggested Garrote in combat under stale spell-inferred Stealth. The **576 genuine refusals per seed** were **requires:not stealthed**, not Energy cost: first declined at t=3.0s with **true Energy50, Garrote cost30**. Only **two total actions accepted**. The source client intentionally has IsStealthed unavailable while engine tracks casts. Normal 100-Energy runs did not show the fault, making this a full final/repeated recommendation FAIL.

New complete **unselected Subtlety v1.1 Draft**, SHA256 **4270209e134f25882bd35a1c17a355087df8e5174d982b23c366182c4d5add4a**, at roles/Rogue/Candidates/APL_Rogue_Subtlety_v1.1_Draft.txt. Entire v1.0 unchanged EXCEPT the opener Garrote's regular Stealth branch requires out-of-combat; **Vanish and Ghostly Strike next-Garrote** branches remain enabled. Source actually applies the ghostly_strike_next aura, permits Garrote without Stealth and consumes the aura. Compare every accepted cast, not merely import.

| Seed | Starting true Energy | Shipped accepted/refused | Current accepted/refused | Full v1.1 accepted/refused | Real v1.1 Ghostly strikes → Garrotes | Ghostly next buff applies/removals |
|---|---:|---|---|---|---|---|
|30417|0|66/0|**2/576**|**63/0**|2→1|2/2|
|30417|100|62/0|60/0|60/0|3→2|4/4|
|30437|0|72/0|**2/576**|**57/0**|6→3|6/6|
|30437|100|62/0|65/0|65/0|1→1|2/2|

The 100-Energy Current and Candidate acceptance counts match exactly, and the full candidate accepts 57/63 source actions with 0 refusals at zero-Energy start. This is a strong source-native castability/stability improvement, **not a measured DPS gain or real client Stealth guarantee**. Verify in-game Stealth, Vanish, seven-second proc window, poisons, weapons, movement/facing, level 1–60 ranks, three subsequent actions and actual source-adjacent target changes before any selection. Secondary Forever-only context: [Forever change notes](https://theforeverera.com/en/changes/?class=rogue) and [Forever Rogue change DB](https://wowfdb.com/classes/rogue/changes/) confirm Ghostly Strike's special follow-up; source native mechanics take precedence. No Classic/Retail copied priorities.

## #19 P0 Druid Guardian — 50 source-true carried Rage does not overcome Maul belief gate

Prior native source trials explored naturally earned Rage with 2–6 attackers but did not prove positive high-kit Maul. This **new distinct starting-state experiment** uses an actual modelled **50 carried-in true Rage**, compared with 0, without manually granting Rage later or changing costs/class kit. 3 naturally attacking mobs at 4yd, exact full shipped vs **Reported Working / Needs Retest** Current v1.0 vs protected complete unselected v1.6, 85s. Real W.truth Maul queue, next-swing strike and paid Rage measured separately. Source player Rage is hidden to the belief and is **NOT assumed equal** to its inferred lower band.

| Seed | Initial true Rage | Shipped Maul queue/strike | Protected v1.0 queue/strike | Full v1.6 queue/strike | v1.6 max true / belief lower bound | v1.6 core accepted / refused |
|---|---:|---|---|---|---|---|
|30417|0|2/2|0/0|**0/0**|30.750 / **24.869**|18 / 0|
|30417|**50**|2/2|0/0|**0/0**|**50.000 / 22.989**|25 / 0|
|30437|0|4/3|0/0|**0/0**|36.250 / **31.387**|24 / 0|
|30437|**50**|1/0|0/0|**0/0**|**50.000 / 20.874**|25 / 0|

**Genuine negative result, not a Maul success:** across all v1.6 worlds, the engine's inferred Rage lower bound never reached its 35-Rage Maul guard, **even starting with real 50 Rage**. Thus v1.6 neither queued nor struck Maul (0), but did accept 18–25 actual core attacks with **zero refused**. Shipped source queued Maul 1–4 times and actually struck 0–3 based on seed. This raises an important possible **held-while-ready** and throughput concern, but source action counts cannot rank damage, survivability or threat. Do not blindly relax the 35 reserve: Primal Bite, Lacerate, Rage stability and repeated queue/refusal safety may suffer. The exact source belief drift cause is **unconfirmed**. User-reported working v1.0 remains protected and is NOT Approved; no Guardian APL changed or automatically selected.

## Full final fallback, regressions and decision

**Rogue:** zero-Energy source start reveals 576 repeated not-stealthed refusals in full Current. Complete v1.1 0 real refused, actual ghost-aura-supported Garrote and 57/63 successful actions; this does not cover all 1–60/poison/stealth/vanish/client conditions.

**Guardian:** at true 0 and 50 Rage, both exact protected v1.0 and unselected v1.6 do not Maul; v1.6 still advances its core combat, with zero refusals. It remains **Blocked for positive high-kit Maul** in this source fixture. Need client snapshot at naturally accumulated high Rage, eligible true Maul/Rage belief and next three legal attacks; do not fabricate source Rage gains or bypass unsupported API. Real next-swing timing, boss threat, movement, procs, trinkets and tank mitigation not established.

**Status:** #18 positive source-validated Rogue bug correction; #19 independent Guardian carried-Rage *negative limitation*. Count them as **19/50 only after final exact-head complete CI, protected main merge and postmerge integrity**. All original APLs, catalogue preferred selections and working rollbacks remain protected. New Rogue v1.1 remains **unselected Draft**, 0 roles gameplay Approved. Saturday in-game: Rogue low Energy after stealth at level with Ghostly Strike, actual next-Garrote and three subsequent accepted actions with /hek snap if stuck; Guardian safe high-Rage bear with Maul known, test real queue vs full current v1.0 and collect /hek snap without forcing unsafe pulls.
