# Tests — Hunter Beast Mastery DPS v1.1 (Hekili Forever v0.8.5)

**16 November 2026. Status: Draft / source-native tested in bounded scenarios. No in-game validation or Approved promotion.**

## Exact pins and revisions

- Source `zmsl/hekili@a0a06583f458cca7a2ceaebb0b2ba0c4c783b946` (released v0.8.5).
- Candidate `roles/Hunter/Current/APL_Hunter_BeastMastery_v1.1_Draft.txt` SHA-256 `a9d752c5e6cdc11fc369fcb6627b73686cc52b5139ed2df4c6628db6c7826d96`.
- Exact preserved prior `roles/Hunter/Archive/APL_Hunter_BeastMastery_DPS_v1.0_Draft.txt` SHA-256 `8b552b6dd6fc9f0c4221e75242ef147c840242b3c03c3e2a75d46aedfe039eba`.
- Default comparator: unchanged pinned Hekili v0.8.5 `Beast Mastery (wowsims.com)`; there is no known reported-working BM custom version. PR [#58]([private historical reference; not publicly accessible]) provides the initial **test-only** hypothesis, PR [#59]([private historical reference; not publicly accessible]) imports actual revision v1.1.

## Executed and passed

| Gate | Exact result |
| --- | --- |
| Repo Python/metadata/integrity | [CI 43883066660]([private historical reference; not publicly accessible]) passed; 28 catalogue SHA-256 values verified |
| Protected v0.8.2 native | [CI 43883066573]([private historical reference; not publicly accessible]) passed, **55** native checks; selects original BM v1.0 (20 actions) |
| Protected v0.8.3 native | [CI 43883066618]([private historical reference; not publicly accessible]) passed, **126 + 86 + 101** checks; selects original BM v1.0 |
| Current v0.8.5 native | [CI 43883066720]([private historical reference; not publicly accessible]) passed, **13 + 126 + 116 + 101 + 183** checks; selects **BM v1.1** (24 actions) |
| Protected testing ZIP | Generated successfully in v0.8.2 workflow; Python test verifies BM v1.0 selected, no v1.1 member |
| Release-version selection | Unit-tested v0.8.2/3→BM v1.0 and v0.8.5→BM v1.1; all 28 hashes verified; invalid release format rejected |
| Call/Revive client-state first icons | Source-native matched original v1.0, shipped and actual v1.1; missing/dead pet selects source-known Call/Revive, while original suggests an Aspect. Living, unusable and Lone Wolf guards avoid inappropriate pet recovery icons |

The initial PR #59 CI attempt failed **before native tests** on a test-tooling mistake: treating two-part APL revision `v1.0` as a three-part addon release version, plus an out-of-date generated role catalogue view. Corrected both on the same branch, without weakening assertions; all four CI workflows subsequently passed at head `44261511354a3c9e719cdf0aab38d6023b36d43a`. This was **not an APL or upstream engine regression**.

## Coverage boundary and required next check

- Reused upstream Hunter headless world still has no accepted Call Pet/Revive Pet world action or pet-recovery transition. Passing an imported icon does **not** prove cast completion, real usability or the next pet-state recommendation.
- The three-pull BM source world tests the source kit it knows; it does not have the new main-pet Call/Revive action in its legacy kit and cannot prove world recovery.
- **Not Run:** true Call/Revive accepted casts, repeat-icon safety across actual pet arrival/revival, known/unknown pet actions at early levels, exact resource cost across ranks, Lone Wolf in-game, Bestial Wrath toggle/cast under real pet, target/range/movement changes and exhaustive final/low-level fallback chain.
- **Minimal game checkpoint:** on v0.8.5 with exact v1.1 imported as `Hunter_BeastMastery`, note level, talents, pet state and cooldown toggles. When pet absent or dead and spell usable, record `/hek snap`, first icon, accepted Call/Revive and subsequent **three state-advanced** recommendations/waits as the pet appears; verify no inappropriate repeated Call/Revive and Bestial Wrath only with living pet. Record evidence before any promotion.

**Decision:** Keep v1.1 Draft, v1.0 immutable rollback, no preferred or approval status. Neither importer/CI success nor test-world equality prove damage superiority.
