# Enhancement v1.1 — standalone solo Windfury APL research

**24 Nov 2026. Experimental unselected Draft / Needs Retest; no Approved or recommended import.**

## Pins, independent mechanics and complete comparators

Published Hekili Forever v0.11.0, exact source [zmsl/hekili@86b739cbc4e6afbcbc693c3790ee81197fc6234b](https://github.com/zmsl/hekili/tree/86b739cbc4e6afbcbc693c3790ee81197fc6234b). Published class file src/Hekili_Shaman/Shaman.lua and true source World tests/Forever/helpers/shaman_world.lua. Default Enhancement (wowsims.com) and exact full protected Current v1.0 benchmarked with native player W.press, W.truth Maelstrom aura/cast cost, actual Windfury Totem and physical bonus strikes. **Default-first research, default NOT design ceiling**.

- Original protected Current v1.0 Draft: roles/Shaman/Current/APL_Shaman_Enhancement_v1.0_Draft.txt SHA256 **76c3ed75a4b01ebe18980104261bcd5589b48924fcaef87a3ed356f00de6ab35**, **preferred=null, last_working=null**.
- New unselected complete v1.1: roles/Shaman/Candidates/APL_Shaman_Enhancement_v1.1_Draft.txt SHA256 **0eb349e19c49e5839eb85a4a0acd4ddfe4a5f448a778693331a0c6d907ce694d**. One extra general action before grouped support totems: Windfury Totem known, no air totem, already combat, 1–2 targets/non-boss, **mana.pct_lo>=20**. All original pet/weapon, support, fire AoE, procs, CDs, final fallback and native off-switches retained. No settings.xx or mandatory per-spec user checkbox.
- [Blizzard Forever 11–14 Nov hotfix chronology](https://eu.forums.blizzard.com/en/wow/t/wow-forever-hotfixes-november-23-2026/639885): Windfury Weapon and Totem can be used together, five Maelstrom stacks give instant zero-Mana Bolt. [Forever DB changes, checked 22 Nov](https://wowfdb.com/classes/shaman/changes/). Independently checked [Icy Veins Enhancement Forever rotation](https://www.icy-veins.com/wow-forever/enhancement-shaman-melee-dps-pve-rotation-cooldowns-abilities), [Icy Veins Forever levelling](https://www.icy-veins.com/wow-forever/enhancement-shaman-leveling), [Mobalytics Forever Enhancement](https://mobalytics.gg/wow-forever/classes/enhancement-shaman-guide). Old Icy Veins deep-dive no-stacking info is OBSOLETE after hotfixes. Maxroll-specific Forever coverage unavailable/robots; no substituted Retail or SoD.
- WoWSims/source Enhancement preset is level60 with a two-handed 3.6s weapon, Maelstrom talent5/5. Released World omits actual weapon-imbue state and client damage/health. This is a PUBLISHED SOURCE mechanical test, not actual player/gear proof.

## Hypothesis, experiment, results and noise

**Hypothesis:** solo routine Windfury Totem may yield extra source-modelled swings without depending on user toggles while maintaining safe Maelstrom Bolt and Mana reserve. Prespecified failures: native cost/refused action; damaging low-Mana fallback; recurrent totem casts; no real bonus strikes in sustained fight; 20-second single-target spent Mana with little/no resulting strike. Ret test under same PR is separate portfolio unit #22.

[Full dated Tests_ report](Tests_Breadth_Ret_Echo_Enh_Maelstrom_v011.md) and [source-native 12/12 CI](https://github.com/tkbiccay/APLForever-Open/actions/runs/45347446688). Two seeds (30417, 30437), each at 100%/25%/**5%** TRUE starting Mana, whole shipped/Current/whole v1.1 in 135s stationary single-target = 18 source Worlds; additional 2 seeds × 20s true source solo × three profiles = 6 Worlds; true 24 worlds for this role. No injected procs, gain or artificial spell outcome.

| Resource / duration | Shipped reference | Current v1.0 | v1.1 unselected | Decision |
|---|---|---|---|---|
| 135s, 100% Mana | 9–11 bonus WF hits, 1 totem | 0 WF hits, 0 totems, 5–7 instant free Bolts | **9–10 WF hits**, pays **250 Mana once**, 4–5 free Bolts | Source positive but less instant Bolt count; DPS unknown |
| 135s, 25% Mana | 10–17 WF hits, 1 totem | 0 hits, 4–5 free Bolts | **2–8 hits**, pays 250 once, retains 4–5 free Bolts | Conditional source effect; unknown benefit |
| 135s, **5%** Mana | Source comparator only | No solo totem | **0 WF totems / 0 WF Mana**, five zero-cost instant Bolts, **zero refuses** | Conservative reserve holds; no forced low-Mana upkeep |
| **20s** outdoor solo full Mana | 0–2 extra WF hits depending seed | 0 WF and no cost | **0–1 WF hits for full 250 Mana/one GCD**, 0 refusals | **NEGATIVE short-pull cost; do NOT promote** |

Source bonus hits are literal model event counts, not measured DPS or comparable damage in actual WoW; source Windfury cost is 250, short fight model cannot follow mobile player moving beyond totem radius. No player-level/health/target death/time-to-die or real tooltip rank proof. Both seeds agree on the short-pull risk class; no significance or quantitative performance superiority invented.

## Root cause and design disposition

**Verified source symptom:** protected original only calls support totems on target.is_boss or active_enemies>=3, therefore ordinary single-target source does not place Windfury Totem; shipped does. The v1.1 extra action restores a source-measured bonus effect with no refused source actions at >=25% initial Mana, and honouring conservative lo at 5%. **New negative:** dropping the 250-Mana stationary totem every short solo fight can be wasteful even when accepted, so the broad universal solo condition **FAILS the practical levelling-efficiency gate**. **Root-cause uncertainty:** safe fight duration/roaming/nearby chaining and actual melee bonus DPS are not observed by the current native fixture. Invented target.time_to_die or health guards forbidden.

**Decision:** retain exact original, catalogue v1.1 as **UNSELECTED Draft / Needs Retest** for further research only, no working-baseline replacement or Approved. Consider an entirely independent design with a source-supported indicator for sustained/grouped combat; first verify visibility, then matched short/long source and real Saturday observations. Protect all original bytes, 53rd revision only a research archive. No new addon setting or false universal toggle.
