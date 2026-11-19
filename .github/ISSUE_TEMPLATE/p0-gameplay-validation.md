---
name: "APLForever P0 in-game recommendation check"
about: "Short real-client Guardian/Hunter BM validation and Hekili snapshot if the recommendation is wrong"
title: "[In-game P0] Role / Revision / Observed behaviour"
labels: []
assignees: []
---

**Instructions:** [Read the minimal v0.10.0 Guardian/Hunter calibration guide](https://github.com/tkbiccay/APLForever-Open/blob/main/docs/Tests_P0_Guardian_Hunter_v0.10.0.md). There are no target dummies in Forever; use a safe level-appropriate open-world enemy.

### Reproducible setup
- Guardian/Feral Tank or Hunter Beast Mastery:
- Installed Forever version (do not assume):
- APL full filename and SHA-256:
- Active pack: shipped / Current / separate Candidate:
- Level, relevant talents/trained abilities, gear:
- Toggle states (Major / Minor / Defensives / Interrupts / Potions / AoE):
- Cooldown Manager enabled/tracked auras if known:

### What actually happened
- Safe enemy and scenario (1 target / 2–3 / Hawk 6–8 yd / pet absent / alive / dead):
- First recommendation:
- **Three real state-advanced events** (actual press -> accepted/refused -> next icon):
  1.
  2.
  3.
- Unexpected repeat, flicker, early defensive, unavailable action, or NONE:
- What did you expect instead, and why?
- Guardian: Roar Off/On; Barkskin only if trained (level 44+); observed target distance?
- Hunter: real main-pet arrival after Call/Revive; Hawk counts are not main-pet arrival.

### Diagnostics and safe outcome
- Full /hek snap text file captured WHILE the bad recommendation appeared (or reason not available):
- Optional screenshot / warnings / Lua error:
- Did you restore the previous working pack? Yes / No / Not needed.
- [ ] No problem observed in this bounded session (NOT Approved)
- [ ] Reproduced a bad recommendation
- [ ] Engine/client visibility limitation suspected
- [ ] Not applicable due to character level or scenario
- [ ] Needs targeted further evidence

Do not use pre-pull snapshots to prove a later combat error. Do not claim numerical DPS or survival gains from this brief check.
