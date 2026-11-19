# Changelog — Hunter Beast Mastery

## 19 November 2026 — v1.2 Draft Candidate, source-pinned

- Original custom v1.1 **preserved byte-for-byte**. Created a fully standalone, unselected v1.2 to use **Summon Hawk's own registered 0–35-yard range** rather than requiring `target.outside8`; retained `pet.hawk.count<2` and all other shot/melee cooldown, pet and final priority conditions unchanged.
- Protected Current/Archive version selection and rollback: fixed both the native source manifest and the layout validator against **automatic newest Draft promotion** when `preferred_apl=null`. New unit regression tests for real v1.2, historical v0.8.2 and explicit preferences.
- Candidate SHA-256: `6abe7e0ff17ff3bfadf9dd8fe234399457127c3535272447b355120f2f5325cd`. All 32 earlier protected APL SHA values unchanged, BM remains unselected.
- First source-native targeted PASS includes guardian Belief's two-slot cap; full suite / gameplay / output proof separately gated. Research [here](Research_Hunter_BeastMastery_v1.2.md); detailed tests [here](Tests_Hunter_BeastMastery_v1.2.md); working branch [PR #8](https://github.com/tkbiccay/APLForever-Open/pull/8).
