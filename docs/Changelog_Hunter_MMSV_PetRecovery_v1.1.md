# Changelog — Hunter Marksmanship and Survival independent v1.1 Drafts

20 Nov 2026, separate *complete standalone* candidate files. Neither Current v1.0 file nor any reported-working import changed.

- Hunter Marksmanship v1.1 `roles/Hunter/Candidates/APL_Hunter_Marksmanship_v1.1_Draft.txt`, SHA256 `fa434dbcfaf802ff1fbfc2d5f667b67aa840dc4603825018aeb2026aad8be007`.
- Hunter Survival v1.1 `roles/Hunter/Candidates/APL_Hunter_Survival_v1.1_Draft.txt`, SHA256 `34e47115c07fff0234ce03520d480ad3d035753cec38e1968d6557671b2df43f`.

Each candidate independently prepends `call_pet` and `revive_pet` to precombat and default with registered source-readable `pet_out`, `pet.dead`, and `!talent.lone_wolf.enabled`, preserving all existing spells, AoE, stance, major/toggle off-switches, items, last reachable rotation and fallbacks. This is class-level pet control without a new setting checkbox, not a shared module. Original v1.0 full imports remain rollback; no preferred or Approved promotion. Prior test-only pinned source 8/8 passed [44813605413](https://github.com/tkbiccay/APLForever-Open/actions/runs/44813605413). Exact stored file native tests pending.
