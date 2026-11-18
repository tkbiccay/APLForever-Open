# Changelog — Druid Feral DPS

## v1.1 — 16 November 2026 — Draft Candidate (not Current)

- Original, complete single-file Feral DPS priority; preserves all internal Cat, Bear and caster action lists, precombat, major/minor CDs, defensives and final fallbacks without another APL/runtime helper.
- Added a guarded **Shred** priority when the target focuses somebody else and Shredding Attacks rank >=2 or Clearcasting is available; existing **Claw** remains the independent fallback when the positional proxy is unsuitable.
- Clearcasting proc list now prefers source-known Shred in the same conditions, otherwise uses source-known Claw. Added Rake known-action guard and relaxed Rip upkeep requirement from >=5CP to >=4CP (supported Forever advice, **actual Rip cast remains untested due source combo-state mismatch**).
- [PR #65]([private historical reference; not publicly accessible]) verifies 20 candidate Shreds in the source target-on-other variant and 17 Claws with the target on the player; zero refused casts, all native regression workflows pass. **No measured DPS gain, 1–60 coverage, in-game positional proof or Approval.**
- **Original Current v1.0 SHA256 `f2f72d0621c8e709c7df8f2ccff248ce0af604a1c02e115a5ad725cf93d288f1` preserved; no prior Reported Working version or Checkpoint.**

## v1.0 — preserved original Current Draft

Archived import historically migrated as `roles/Druid/Current/APL_Druid_Feral_DPS_v1.0_Draft.txt` (not an Approved or reported-working profile). [PR #64]([private historical reference; not publicly accessible]) source-native first comparator confirmed no Shred but accepted Claw/Rake; no in-game observation attached.

See [Research](Research_Druid_Feral_v1.1.md), [Tests](Tests_Druid_Feral_v1.1.md) and [Limitations](Limitations_Druid_Feral.md).
